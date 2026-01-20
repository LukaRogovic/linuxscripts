# Linux Inventory

Software inventory tool for Linux systems. Works on all major distributions.

![Linux Inventory Screenshot](systeminvertory.png)

## What it does

Collects and displays:
- OS and kernel information
- Package managers (APT, DNF, Pacman, Snap, Flatpak, pip, npm, etc.)
- Installed packages with sizes
- GUI applications
- Systemd services
- Desktop environment and themes
- Startup applications

## Usage
Give it permission to run
```bash
chmod +x linux-inventory.sh
```
Run the script
```bash
./linux-inventory.sh
```
Or with sudo for full access to information
```bash
sudo ./linux-inventory.sh


## Navigation

| Key | Action |
|-----|--------|
| 1-11 | Select category |
| A | Run all sections |
| S | Save report to file |
| R | Rerun current section |
| M | Return to menu |
| Q | Quit |

## Requirements

- Bash 4.0+
- Linux distribution
