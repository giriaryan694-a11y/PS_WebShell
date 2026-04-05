# ================================================
# PS_WebShell.ps1 - CloudShell Style + History + Logs
# Made By Aryan Giri
# ================================================

# ================== CONFIGURATION ==================

$Username = "admin"          # ← Change username
$Password = "admin123"        # ← Change password

$AllowedIPs = @(
    "*"                      # Allow all IPs (default)
    # "192.168.1.100"        # ← Add specific IPs here if needed
)

$Port = 8080

# ================================================

Add-Type -AssemblyName System.Web

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
    Write-Host $Message -ForegroundColor $Color
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")   # Changed to localhost (fixes most access denied issues)

try {
    $listener.Start()

    Write-Log "PS_WebShell Started Successfully" "Green"
    Write-Log "Username     : $Username" "Yellow"
    Write-Log "Password     : $Password" "Yellow"
    Write-Log "Listening on : http://localhost:$Port" "Cyan"
    Write-Log "Allowed IPs  : $($AllowedIPs -join ', ')" "Cyan"
    Write-Log "==================================================" "Cyan"
    Write-Log "Press Ctrl+C to stop" "Red"

    $sessions = @{}   # sessionId => current directory

    function Test-IPAllowed {
        param([string]$ClientIP)
        if ($AllowedIPs -contains "*") { return $true }
        return $AllowedIPs -contains $ClientIP
    }

    function Show-LoginPage {
        return @"
<!DOCTYPE html>
<html>
<head>
    <title>PS_WebShell</title>
    <style>
        body { background:#0c0c0c; font-family:'Courier New',monospace; display:flex; justify-content:center; align-items:center; height:100vh; margin:0; }
        .login { background:#1e1e1e; padding:40px; border:1px solid #00ff00; border-radius:8px; width:360px; text-align:center; }
        h2 { color:#00ff00; }
        input { width:100%; padding:12px; margin:10px 0; background:#0c0c0c; border:1px solid #00ff00; color:#00ff00; font-size:14px; }
        input[type=submit] { background:#00ff00; color:#0c0c0c; font-weight:bold; cursor:pointer; }
        .footer { margin-top:20px; color:#666; font-size:12px; }
    </style>
</head>
<body>
    <div class="login">
        <h2>PS_WebShell</h2>
        <form method="post" action="/auth">
            <input type="text" name="user" placeholder="Username" required>
            <input type="password" name="pass" placeholder="Password" required>
            <input type="submit" value="Login">
        </form>
        <div class="footer">Made By Aryan Giri</div>
    </div>
</body>
</html>
"@
    }

    function Show-Terminal {
        return @"
<!DOCTYPE html>
<html>
<head>
    <title>PS_WebShell</title>
    <style>
        * { margin:0; padding:0; box-sizing:border-box; }
        body { background:#0c0c0c; color:#00ff00; font-family:'Courier New', monospace; height:100vh; overflow:hidden; display:flex; flex-direction:column; }
        .header { background:#1e1e1e; padding:8px 15px; border-bottom:2px solid #00aa00; display:flex; justify-content:space-between; align-items:center; font-size:14px; }
        .output { flex:1; overflow-y:auto; padding:15px; font-size:14px; line-height:1.5; white-space:pre-wrap; word-break:break-all; }
        .input-line { display:flex; padding:10px 15px; background:#0c0c0c; border-top:2px solid #00aa00; }
        .prompt { color:#00ff00; font-weight:bold; margin-right:8px; user-select:none; }
        #cmd { flex:1; background:transparent; border:none; color:#00ff00; font-family:inherit; font-size:14px; outline:none; }
        .btn { background:#222; color:#00ff00; border:1px solid #00ff00; padding:4px 12px; margin-left:8px; cursor:pointer; font-size:13px; }
        .btn:hover { background:#00ff00; color:#0c0c0c; }
        .error { color:#ff5555; }
    </style>
</head>
<body>
    <div class="header">
        <span>PS_WebShell • $env:COMPUTERNAME</span>
        <span>Made By Aryan Giri</span>
        <button class="btn" onclick="clearOutput()">Clear</button>
        <button class="btn" onclick="logout()">Logout</button>
    </div>
    <div class="output" id="output"></div>
    <div class="input-line">
        <span class="prompt" id="prompt">PS C:\></span>
        <input type="text" id="cmd" autocomplete="off" autofocus>
    </div>

    <script>
        let sessionId = document.cookie.split('; ').find(r => r.startsWith('PS_WS_SESSION='))?.split('=')[1] || '';
        let history = [];
        let historyIndex = -1;

        const output = document.getElementById('output');
        const cmdInput = document.getElementById('cmd');
        const promptEl = document.getElementById('prompt');

        function addLine(text, isError = false) {
            const div = document.createElement('div');
            if (isError) div.classList.add('error');
            div.textContent = text;
            output.appendChild(div);
            output.scrollTop = output.scrollHeight;
        }

        async function runCommand() {
            const cmd = cmdInput.value.trim();
            if (!cmd) return;

            addLine('PS> ' + cmd);
            history.unshift(cmd);           // Add to history (newest first)
            historyIndex = -1;
            cmdInput.value = '';

            try {
                const res = await fetch('/execute', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                    body: 'cmd=' + encodeURIComponent(cmd) + '&session=' + sessionId
                });

                const result = await res.text();
                if (result) addLine(result);

                const dirRes = await fetch('/getdir');
                const newDir = await dirRes.text();
                promptEl.textContent = 'PS ' + newDir + '>';
            } catch (e) {
                addLine('ERROR: ' + e.message, true);
            }
            cmdInput.focus();
        }

        // Command History with Up / Down Arrows
        cmdInput.addEventListener('keydown', function(e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                runCommand();
            } 
            else if (e.key === 'ArrowUp') {
                e.preventDefault();
                if (history.length > 0) {
                    historyIndex = Math.min(historyIndex + 1, history.length - 1);
                    cmdInput.value = history[historyIndex];
                }
            } 
            else if (e.key === 'ArrowDown') {
                e.preventDefault();
                if (historyIndex > 0) {
                    historyIndex--;
                    cmdInput.value = history[historyIndex];
                } else {
                    historyIndex = -1;
                    cmdInput.value = '';
                }
            }
        });

        function clearOutput() { output.innerHTML = ''; }
        function logout() {
            document.cookie = 'PS_WS_SESSION=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/';
            location.href = '/';
        }

        window.onload = () => {
            fetch('/getdir').then(r => r.text()).then(dir => {
                promptEl.textContent = 'PS ' + dir + '>';
                addLine('=== PS_WebShell Ready (with Command History) ===');
                addLine('↑ Up Arrow = previous command');
                addLine('↓ Down Arrow = next command');
                addLine('---------------------------------------------------');
            }).catch(() => addLine('Failed to connect.', true));
            cmdInput.focus();
        };
    </script>
</body>
</html>
"@
    }

    # ====================== Main Listener Loop ======================
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $req = $context.Request
        $res = $context.Response

        $clientIP = $req.RemoteEndPoint.Address.ToString()
        $url = $req.RawUrl
        $cookie = $req.Cookies["PS_WS_SESSION"]

        if (-not (Test-IPAllowed $clientIP)) {
            Write-Log "ACCESS BLOCKED from $clientIP" "Red"
            $res.StatusCode = 403
            $html = "<h3 style='color:#ff4444;background:#0c0c0c;padding:50px'>Access Denied from IP: $clientIP</h3>"
            $buf = [Text.Encoding]::UTF8.GetBytes($html)
            $res.ContentType = "text/html"
            $res.ContentLength64 = $buf.Length
            $res.OutputStream.Write($buf, 0, $buf.Length)
            $res.Close()
            continue
        }

        # ... (the rest of the routes - Login, Auth, Terminal, Execute, GetDir - are the same as previous version)

        if ($url -eq "/" -and $req.HttpMethod -eq "GET") {
            Write-Log "Login page accessed from $clientIP" "Cyan"
            $html = Show-LoginPage
            $buf = [Text.Encoding]::UTF8.GetBytes($html)
            $res.ContentType = "text/html"
            $res.ContentLength64 = $buf.Length
            $res.OutputStream.Write($buf, 0, $buf.Length)
            $res.Close()
            continue
        }

        if ($url -eq "/auth" -and $req.HttpMethod -eq "POST") {
            $reader = New-Object IO.StreamReader($req.InputStream)
            $body = $reader.ReadToEnd()
            $reader.Close()

            $params = @{}
            $body -split '&' | ForEach-Object {
                $kv = $_ -split '='
                if ($kv.Count -eq 2) {
                    $params[[System.Web.HttpUtility]::UrlDecode($kv[0])] = [System.Web.HttpUtility]::UrlDecode($kv[1])
                }
            }

            if ($params["user"] -eq $Username -and $params["pass"] -eq $Password) {
                $sessionId = [Guid]::NewGuid().ToString()
                $sessions[$sessionId] = (Get-Location).Path

                $cookieObj = New-Object System.Net.Cookie("PS_WS_SESSION", $sessionId)
                $cookieObj.Path = "/"
                $res.Cookies.Add($cookieObj)

                $res.StatusCode = 302
                $res.Headers.Add("Location", "/terminal")
                Write-Log "LOGIN SUCCESS from $clientIP | Session: $sessionId" "Green"
            } else {
                $html = "<h3 style='color:#ff4444;background:#0c0c0c;padding:50px;font-family:monospace'>Login Failed!<br><a href='/' style='color:#00ff00'>Try Again</a></h3>"
                $buf = [Text.Encoding]::UTF8.GetBytes($html)
                $res.ContentType = "text/html"
                $res.ContentLength64 = $buf.Length
                $res.OutputStream.Write($buf, 0, $buf.Length)
                Write-Log "LOGIN FAILED from $clientIP" "Red"
            }
            $res.Close()
            continue
        }

        if ($url -eq "/terminal") {
            if (-not $cookie -or -not $sessions.ContainsKey($cookie.Value)) {
                $res.StatusCode = 302
                $res.Headers.Add("Location", "/")
                $res.Close()
                continue
            }
            Write-Log "Terminal opened from $clientIP" "Cyan"
            $html = Show-Terminal
            $buf = [Text.Encoding]::UTF8.GetBytes($html)
            $res.ContentType = "text/html"
            $res.ContentLength64 = $buf.Length
            $res.OutputStream.Write($buf, 0, $buf.Length)
            $res.Close()
            continue
        }

        if ($url -eq "/execute" -and $req.HttpMethod -eq "POST") {
            if (-not $cookie -or -not $sessions.ContainsKey($cookie.Value)) {
                $res.StatusCode = 401
                $res.Close()
                continue
            }

            $reader = New-Object IO.StreamReader($req.InputStream)
            $body = $reader.ReadToEnd()
            $reader.Close()

            $params = @{}
            $body -split '&' | ForEach-Object {
                $kv = $_ -split '='
                if ($kv.Count -eq 2) {
                    $params[[System.Web.HttpUtility]::UrlDecode($kv[0])] = [System.Web.HttpUtility]::UrlDecode($kv[1])
                }
            }

            $cmd = $params["cmd"]
            $sessionId = if ($params["session"]) { $params["session"] } else { $cookie.Value }
            $currentDir = $sessions[$sessionId]

            try {
                Set-Location $currentDir -ErrorAction Stop
                $result = Invoke-Expression $cmd 2>&1 | Out-String
                $sessions[$sessionId] = (Get-Location).Path

                if ([string]::IsNullOrWhiteSpace($result)) { $result = "(no output)`n" }

                $buf = [Text.Encoding]::UTF8.GetBytes($result)
                $res.ContentType = "text/plain"
                $res.ContentLength64 = $buf.Length
                $res.OutputStream.Write($buf, 0, $buf.Length)

                Write-Log "EXECUTED from $clientIP → $cmd" "White"
            } catch {
                $err = "ERROR: $($_.Exception.Message)`n"
                $buf = [Text.Encoding]::UTF8.GetBytes($err)
                $res.ContentType = "text/plain"
                $res.ContentLength64 = $buf.Length
                $res.OutputStream.Write($buf, 0, $buf.Length)
                Write-Log "COMMAND ERROR from $clientIP → $cmd" "Red"
            }
            $res.Close()
            continue
        }

        if ($url -eq "/getdir") {
            if (-not $cookie -or -not $sessions.ContainsKey($cookie.Value)) {
                $res.StatusCode = 401
                $res.Close()
                continue
            }
            $dir = $sessions[$cookie.Value]
            $buf = [Text.Encoding]::UTF8.GetBytes($dir)
            $res.ContentType = "text/plain"
            $res.ContentLength64 = $buf.Length
            $res.OutputStream.Write($buf, 0, $buf.Length)
            $res.Close()
            continue
        }

        $res.StatusCode = 404
        $res.Close()
    }
}
catch {
    Write-Log "Server stopped or error occurred: $($_.Exception.Message)" "Yellow"
}
finally {
    if ($listener -and $listener.IsListening) {
        $listener.Stop()
    }
    Write-Log "PS_WebShell has been stopped cleanly." "Red"
}
