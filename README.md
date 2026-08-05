# 👻 Ghost Monitor

> **The Ultimate Swiss Army Knife for macOS.**  
> Clean, Optimize, Protect, and Boost your Mac with a single, lightning-fast native application.

![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B-blue?logo=apple)
![Swift 6](https://img.shields.io/badge/Swift-6.0-orange?logo=swift)
![License: BSL 1.1](https://img.shields.io/badge/License-BSL_1.1-purple)
![AI Powered](https://img.shields.io/badge/AI-On--Device-green)
![Build](https://img.shields.io/badge/Build-Passing-brightgreen)

---

## 🌟 Overview

Ghost Monitor replaces over 15+ expensive utility apps with one integrated, pure Swift & SwiftUI native powerhouse. Designed with a high-tech Cyber-Glass aesthetic, Ghost Monitor operates at root level precision while idling at less than 15MB of RAM.

---

## ✨ Features

### 🛡️ Security & Privacy Fortress
* **Hardware Killswitches:** Instantly block Microphone and Camera drivers.
* **Spy-Catcher:** YARA heuristics scan memory for crypto-miners and screen grabbers.
* **Privacy Dashboard:** Scan and revoke granular TCC hardware permissions from any app.
* **Forensic System Wipe:** Securely clear DNS cache and overwrite deleted trash sectors.
* **USB Guard:** Real-time IOKit monitoring alerts you to unknown devices instantly.
* **Network Firewall:** Block apps from phoning home via `socketfilterfw`.

### ⚡ Optimization & Utilities
* **Ghost AI System Assistant:** Local, on-device Natural Language engine to control your Mac with 1-click execution safety.
* **Gaming Booster:** Max out CPU priority via `renice`, suspend Spotlight indexing, and kill non-essential background processes.
* **Advanced Battery:** Enable native 80% charge limit (`pmset optimizebattery`) to preserve battery health.
* **Thermal Guardian:** Real-time SMC temperature monitoring and thermal throttling prevention.
* **PC Cleaner & Uninstaller:** Deep clean caches and eradicate orphaned `.plist` files.
* **Disk Mapper:** Visual sunburst disk space analyzer.
* **NTFS Unlocker:** Mount and write to Windows NTFS drives natively.

### 🧰 Quality of Life
* **Insomnia Mode:** Prevent Mac sleep during long downloads (`caffeinate`).
* **Cross-Drop:** Instant Wi-Fi file transfers to Windows, Android, and Linux via scannable QR code.
* **Clipboard Vault:** Securely store and retrieve your clipboard history.

---

## 🔒 Security & Licensing Model

Ghost Monitor is licensed under the **Business Source License (BSL 1.1)**.

* **Free for Personal Use:** Anyone can inspect, audit, and compile the source code for personal use.
* **Commercial Restrictions:** Reselling, distributing pre-compiled binaries for profit, or rebranding Ghost Monitor is prohibited without an official Pro License.

👉 **Want pre-compiled `.dmg` installers, auto-updates, and priority support?**  
Purchase a **[Pro Edition Lifetime License ($24.99)](http://localhost:3000/#pricing)**.

---

## 🛠️ Building From Source

### Requirements
* macOS 14.0 (Sonoma) or newer
* Xcode 15.0+ or Swift 5.10 / Swift 6 Toolchain

### Quick Start
```bash
# Clone the repository
git clone https://github.com/anassagd432/GhostMonitor.git
cd GhostMonitor

# Build optimized release binary and install to /Applications
./build-release.sh

# Or generate a complete release .dmg installer package
./create-dmg.sh
```

---

## 💻 Tech Stack

* **Language:** Swift 6.0
* **UI Framework:** SwiftUI & AppKit
* **Security Subsystem:** IOKit, AppleScript privilege escalation, Keychain Enclave, `ptrace(PT_DENY_ATTACH)` anti-debugging.
* **AI Engine:** On-device Apple `NaturalLanguage` framework (`NLTagger`).

---

## 📄 License

This project is licensed under the Business Source License 1.1 - see the [LICENSE](LICENSE) file for details.
