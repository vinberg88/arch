<p align="center">
  <a href="https://github.com/vinberg88">
    <img width="518" height="178" alt="Arch Linux" src="https://github.com/user-attachments/assets/a6c4e5aa-1570-4026-9b78-d0b0ef5c51aa" />
  </a>
</p>

---

<h1 align="center">Arch Linux for WSL</h1>

Arch Linux, a lightweight and flexible Linux® distribution
that tries to Keep It Simple. Arch Linux is an independently 
developed, x86-64 general-purpose GNU/Linux distribution that strives
to provide the latest stable versions of most software by following
a rolling-release model. The default installation is a minimal
base system, configured by the user to only add what is purposely required.
Arch Linux uses a "rolling release" system which allows one-time
installation and perpetual software upgrades. It is not generally
necessary to reinstall or upgrade your Arch Linux system from one
"version" to the next. By issuing one command, an Arch system is
kept up-to-date and on the bleeding edge.


We will use paru for setup - fast and better then yay i think =)

<p align="center">
  <a href="https://github.com/vinberg88">
    <img width="731" height="273" alt="paru" src="https://github.com/user-attachments/assets/9ffc9eb5-436f-4853-a6c1-423dc3d5a728" />
  </a>
</p>

<p align="center">
  <img alt="Arch Linux" src="https://img.shields.io/badge/Arch_Linux-Rolling_Release-1793D1?logo=archlinux&logoColor=white">
  <img alt="WSL 2" src="https://img.shields.io/badge/WSL-2-0078D4?logo=windows11&logoColor=white">
  <img alt="Windows 11" src="https://img.shields.io/badge/Windows-11-0078D4?logo=windows11&logoColor=white">
</p>

---

## About Arch Linux

[Arch Linux](https://archlinux.org/) is an independently developed, x86-64 GNU/Linux distribution focused on simplicity, modern software and user control.

Arch uses a **rolling-release model**, which means there are no traditional major-version upgrades. Install it once, keep the system updated with Pacman, and you continue receiving current packages.

The default Arch installation is intentionally minimal. You decide what gets installed and how the system should be configured.

Arch Linux now provides an **official WSL image**, making it much easier to run a genuine Arch environment directly on Windows.

> **Important:** The official Arch Linux WSL image requires **WSL 2**. WSL 1 is not supported.

---

# Desktop environments on Arch WSL

This repository is not only about installing Arch Linux itself — the main goal is also to show how different **Linux desktop environments can run under WSL 2 on Windows 11**.

Planned and tested desktop guides can include:

| Desktop | Typical session | WSL display |
|---|---|---|
| KDE Plasma 6 | X11 / Wayland depending on setup | X410 / WSLg |
| GNOME | Wayland | WSLg / nested session |
| XFCE | X11 | X410 |
| MATE | X11 | X410 |
| Cinnamon | X11 | X410 |
| LXQt | X11 | X410 |

Each desktop section can contain a screenshot, a short description, the required packages, the start command and a link to a separate full installation guide.

> **Desktop guides will be kept short on this main page.** Full installation instructions, scripts and troubleshooting can live in separate files so the README stays easy to navigate.

## KDE Plasma 6 + X410

<p align="center">
  <a href="https://github.com/vinberg88/arch/blob/main/Arch-KDE6-2026.txt">
<img width="1920" height="1080" alt="Arch-KDE6-2026" src="https://github.com/user-attachments/assets/a7fe5ee9-eef1-48ec-8fb7-c5bd4fcc86c0" />
  </a>
</p>

[Arch KDE6 2026 SETUP](https://github.com/vinberg88/arch/blob/main/Arch-KDE6-2026.txt)

Video via YOUTUBE is Comming - Setup take time =)

KDE Plasma 6 can run as a complete **X11 desktop on X410** while keeping WSLg available for audio.

First make sure the X11 session packages are installed:

```bash
paru -S plasma-x11-session kwin-x11
```

Then install the Arch X410 launcher directly from this repository:

```bash
wget -O install-kde6-x410-arch.sh \
https://raw.githubusercontent.com/vinberg88/arch/main/install-kde6-x410-arch.sh

chmod +x install-kde6-x410-arch.sh
./install-kde6-x410-arch.sh
```

> **IMPORTANT:** Start X410 in Windows 11 before starting KDE.

Check the setup:

```bash
kde6-x410 doctor
```

Start KDE Plasma 6:

```bash
kde6-x410 start
```

If Plasma is already half-started or looks broken:

```bash
kde6-x410 repair
kde6-x410 start
```

Other useful commands:

```bash
kde6-x410 stop
kde6-x410 restart
kde6-x410 log
```

---

## Requirements

Before installing Arch Linux, make sure you have:

- Windows 11 or a supported Windows 10 release
- Hardware virtualization enabled in UEFI/BIOS
- The current Microsoft Store version of WSL
- WSL 2 enabled
- Internet access
- Windows Terminal recommended

Check your WSL installation from **PowerShell**:

```powershell
wsl --version
wsl --status
```

Update WSL:

```powershell
wsl --update
```

Restart WSL if necessary:

```powershell
wsl --shutdown
```

---

# Quick installation

## 1. Check that Arch Linux is available

Open **PowerShell**:

```powershell
wsl --list --online
```

Arch Linux should appear as:

```text
archlinux
```

## 2. Install Arch Linux

Run:

```powershell
wsl --install archlinux
```

WSL downloads and installs the official Arch Linux image.

Start it with:

```powershell
wsl -d archlinux
```

You can also launch Arch Linux from the Windows Start menu or Windows Terminal.

---

# First boot

The official Arch Linux WSL environment initially uses the **root** account.

Before doing anything else, update the system:

```bash
pacman -Syu
```

Install a useful base set of tools:

```bash
pacman -S --needed sudo nano git base-devel curl wget openssh
```

Set a password for root:

```bash
passwd
```

---

# Create a normal user

Replace `username` with the account name you want to use.

```bash
useradd -m -G wheel -s /bin/bash username
passwd username
```

Example:

```bash
useradd -m -G wheel -s /bin/bash adolf
passwd adolf
```

Enable sudo access for members of the `wheel` group:

```bash
EDITOR=nano visudo
```

Find this line:

```text
# %wheel ALL=(ALL:ALL) ALL
```

Remove the `#` so it becomes:

```text
%wheel ALL=(ALL:ALL) ALL
```

Save the file and exit Nano.

Test the new account:

```bash
su - username
sudo pacman -Syu
```

---

# Set the default WSL user

Modern WSL releases can set the default user directly from Windows.

Exit Arch Linux and run this in **PowerShell**:

```powershell
wsl --manage archlinux --set-default-user username
```

Then restart the distribution:

```powershell
wsl --terminate archlinux
wsl -d archlinux
```

You can verify the user inside Arch:

```bash
whoami
id
```

### Alternative method: /etc/wsl.conf

You can also configure the default user inside Arch Linux.

```bash
sudo nano /etc/wsl.conf
```

Add:

```ini
[user]
default=username
```

Then from PowerShell:

```powershell
wsl --terminate archlinux
```

Start Arch again.

---

# systemd

The official Arch Linux WSL image supports **systemd**.

Check it with:

```bash
ps -p 1 -o pid,comm,args
systemctl is-system-running
```

If systemd is already active, no additional configuration is required.

If it is not enabled, edit:

```bash
sudo nano /etc/wsl.conf
```

Add:

```ini
[boot]
systemd=true
```

If you also want to define the default user:

```ini
[boot]
systemd=true

[user]
default=username
```

Apply the change from PowerShell:

```powershell
wsl --shutdown
```

Start Arch again and verify:

```bash
systemctl is-system-running
```

> The official Arch WSL image intentionally masks several systemd units that do not make sense inside WSL. Do not unmask them unless you have a specific reason.

---

# Locale

See available locales:

```bash
grep -E "en_US|sv_SE" /etc/locale.gen
```

Edit the locale list:

```bash
sudo nano /etc/locale.gen
```

For English, uncomment:

```text
en_US.UTF-8 UTF-8
```

Generate the locale:

```bash
sudo locale-gen
```

Set the default:

```bash
echo "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf
```

Check:

```bash
locale
```

---

# Time zone

List available zones:

```bash
timedatectl list-timezones
```

Example for Sweden:

```bash
sudo timedatectl set-timezone Europe/Stockholm
```

Check:

```bash
timedatectl
```

---

# Updating Arch Linux

Arch Linux is a rolling-release distribution.

Keep the complete system updated with:

```bash
sudo pacman -Syu
```

Install a package:

```bash
sudo pacman -S package-name
```

Remove a package and unused dependencies:

```bash
sudo pacman -Rns package-name
```

Search repositories:

```bash
pacman -Ss search-term
```

Show installed packages:

```bash
pacman -Q
```

Clean old cached package versions when needed:

```bash
sudo paccache -r
```

If `paccache` is not installed:

```bash
sudo pacman -S pacman-contrib
```

> Arch Linux does not support partial upgrades. Use `pacman -Syu` to keep the complete system synchronized.

---

# AUR support

The **Arch User Repository (AUR)** contains community-maintained package build scripts.

Install the basic build requirements first:

```bash
sudo pacman -S --needed base-devel git
```

AUR packages are not part of the official Arch repositories. Always inspect a PKGBUILD before building or installing it.

For more information:

- [ArchWiki - Arch User Repository](https://wiki.archlinux.org/title/Arch_User_Repository)
- [AUR](https://aur.archlinux.org/)

---

# Windows integration

WSL provides interoperability between Arch Linux and Windows.

Run a Windows command from Arch:

```bash
explorer.exe .
```

Open the current Linux directory in Windows File Explorer:

```bash
explorer.exe .
```

Run PowerShell from Arch:

```bash
powershell.exe
```

Run a Windows executable:

```bash
notepad.exe
```

Windows drives are normally mounted under:

```text
/mnt/c
/mnt/d
```

Your Arch filesystem can also be reached from Windows through:

```text
\\wsl$\archlinux
```

For Linux development work, storing projects inside the Linux filesystem, for example under `~/projects`, generally provides the best Linux filesystem behavior.

---

# GUI applications with WSLg

Modern WSL includes **WSLg**, which can run Linux graphical applications directly on the Windows desktop.

Install a simple X11 test application:

```bash
sudo pacman -S xterm
```

Run:

```bash
xterm
```

If WSLg is working, the Linux application opens as a normal Windows desktop window.

Useful checks:

```bash
echo "$DISPLAY"
echo "$WAYLAND_DISPLAY"
ls -la /mnt/wslg
```

For Mesa and Vulkan support:

```bash
sudo pacman -S mesa vulkan-icd-loader
```

WSLg also provides Linux audio integration.

---

# Useful WSL commands

Run these from **PowerShell** or Windows Terminal.

List installed distributions:

```powershell
wsl --list --verbose
```

Start Arch:

```powershell
wsl -d archlinux
```

Start Arch as root:

```powershell
wsl -d archlinux -u root
```

Terminate Arch:

```powershell
wsl --terminate archlinux
```

Stop all WSL distributions:

```powershell
wsl --shutdown
```

Update WSL:

```powershell
wsl --update
```

Check WSL status:

```powershell
wsl --status
```

---

# Backup Arch Linux

One of the best WSL features is the ability to export the entire Linux installation.

Shut down Arch first:

```powershell
wsl --terminate archlinux
```

Export it:

```powershell
wsl --export archlinux D:\WSL-Backup\archlinux-backup.tar
```

You now have a portable backup of the distribution.

To restore it under another name:

```powershell
wsl --import Arch-Restore D:\WSL\Arch-Restore D:\WSL-Backup\archlinux-backup.tar --version 2
```

Start the restored system:

```powershell
wsl -d Arch-Restore
```

---

# Troubleshooting

## Arch starts as root

Set the default user:

```powershell
wsl --manage archlinux --set-default-user username
```

Or configure:

```ini
[user]
default=username
```

inside `/etc/wsl.conf`.

---

## Need emergency root access

From PowerShell:

```powershell
wsl -d archlinux -u root
```

---

## Configuration changes are not applied

Completely restart WSL:

```powershell
wsl --shutdown
```

Then start Arch again:

```powershell
wsl -d archlinux
```

---

## systemd user-session problems

If a systemd user session fails to initialize correctly, enabling lingering can help:

```bash
sudo loginctl enable-linger username
```

Restart the distribution afterward.

---

## Docker complains that / is not a shared mount

A temporary fix is:

```bash
sudo mount --make-rshared /
```

If you use Docker extensively inside Arch WSL, see the ArchWiki WSL documentation for the persistent systemd-service solution.

---

# Recommended first setup

For a fresh Arch WSL installation, this is a good minimal starting point:

```bash
sudo pacman -Syu
sudo pacman -S --needed base-devel git curl wget openssh nano vim
```

Useful development packages can then be added as needed instead of installing a large preconfigured environment.

That is one of Arch Linux's biggest strengths: **start small and build exactly the system you want.**

---

# Official documentation

- [Arch Linux](https://archlinux.org/)
- [ArchWiki](https://wiki.archlinux.org/)
- [Install Arch Linux on WSL - ArchWiki](https://wiki.archlinux.org/title/Install_Arch_Linux_on_WSL)
- [Microsoft WSL documentation](https://learn.microsoft.com/windows/wsl/)
- [WSL installation guide](https://learn.microsoft.com/windows/wsl/install)

---

## Notes

This project focuses on **Arch Linux running under WSL 2**.

Some behavior differs from a traditional bare-metal Arch installation because WSL provides the kernel, networking integration, Windows interoperability and graphical integration.

For normal Arch package management and configuration, the ArchWiki remains the primary reference.

---

<p align="center">
  <b>Arch Linux + WSL 2 + Windows 11</b><br>
  Keep it simple. Keep it rolling.
</p>

<p align="center">
  <a href="https://github.com/vinberg88">
    <img width="1195" height="238" alt="arch-bottom" src="https://github.com/user-attachments/assets/eceb0d9e-09b5-4795-b8dc-2f919de45574" />
  </a>
</p>
