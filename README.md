# 🟢 PS_WebShell – CloudShell Style

A modern, sleek **PowerShell-based WebShell** with a beautiful terminal UI inspired by Azure CloudShell.

---

## 🚀 Overview

**PS_WebShell** brings a browser-based PowerShell terminal experience with a CloudShell-style interface. Designed for **learning, CTFs, and authorized red teaming**, it provides a responsive, session-based shell environment with strong usability features.

---

## ✨ Features

* 🖥️ CloudShell-like terminal (green-on-black UI)
* ⬆️⬇️ Full command history (arrow key navigation)
* 📡 Real-time colored logging in PowerShell console
* 🔐 Session-based authentication (GUID cookies)
* 📂 Directory persistence (`cd` works like native shell)
* 🌐 IP whitelisting support (default: allow all)
* 🛑 Clean shutdown handling
* 📱 Mobile-friendly responsive design
* ⚙️ Easy configuration at the top of the script

---

## 🔑 Default Credentials (IMPORTANT)

**Default Login:**

* Username: `admin`
* Password: `admin123`

⚠️ **Change these immediately before using!**

---

## 🛠️ Configuration

Open `PS_WebShell.ps1` and modify the configuration section:

```powershell
# ================== CONFIGURATION ==================

$Username = "admin"          # ← Change this
$Password = "admin123"       # ← Change this

$AllowedIPs = @(
    "*"                      # Allow all IPs (default)
    # "192.168.1.50"         # Example: restrict to specific IPs
)

$Port = 8080
```

### 🔧 What You Can Customize

* **Credentials** → Change username/password
* **IP Access** → Replace `"*"` with specific IPs
* **Port** → Change from `8080` to any available port

---

## 🔐 Security Implementations

* **Session Management** → Unique GUID-based sessions using cookies
* **IP Whitelisting** → Restrict access to trusted IPs only
* **Command Isolation** → Commands executed via `Invoke-Expression` inside session context
* **Error Handling** → Graceful handling of runtime issues
* **Shutdown Safety** → Clean exit with Ctrl + C

⚠️ **Important Security Note**

This tool is powerful. Do NOT expose it directly to the internet.

Recommended protections:

* Use behind a **VPN** (Recommended: Tailscale for quick private networking)
* Apply **firewall rules**
* Enable **IP restrictions**
* Use **reverse proxy with SSL (HTTPS)** (Recommended: [https://github.com/giriaryan694-a11y/http2https](https://github.com/giriaryan694-a11y/http2https))

---

## ▶️ Usage

1. Save the script as:

```bash
PS_WebShell.ps1
```

2. Open **PowerShell (Administrator recommended)**

3. Run the script:

```powershell
.\PS_WebShell.ps1
```

4. Open your browser:

```
http://localhost:8080
```

5. Login and start using your web-based terminal

---

## 🛑 Stopping the Server

Press:

```
Ctrl + C
```

in the PowerShell window to stop the server.

⚠️ If `Ctrl + C` does not respond (rare cases), simply close the PowerShell or CMD window. This will immediately terminate the WebShell server.

---

## ⚡ Quick Tips

* 🔁 Change port → Edit `$Port`
* 🔒 Restrict to local machine → Use `127.0.0.1`
* ⌨️ Use ↑ arrow → Recall previous commands

---

## ⚖️ Legal & Ethical Disclaimer

> ⚠️ This tool is for **educational and authorized use only**

You MUST NOT use this tool for:

* Illegal activities
* Unauthorized access
* Malicious exploitation

By using this project, you agree:

* You own the system OR have **explicit permission**
* You follow **local laws and ethical guidelines**

The author is **not responsible** for misuse.

---

## ❤️ Author

**Aryan Giri**
Cybersecurity Learner • Red Team Enthusiast

---

## 🔗 Repository

GitHub: [https://github.com/giriaryan694-a11y/PS_WebShell](https://github.com/giriaryan694-a11y/PS_WebShell)

---

---

## 🧪 Red Team Thought

This tool mimics real-world post-exploitation web shells.
