# Linux System Info

Comprehensive system information tool for Linux.

![System Info Screenshot](systeminfo.png)

## What it does

Displays detailed information about:
- OS, kernel, CPU, memory, storage
- GPU/graphics and display
- Network interfaces and connections
- Firewall, WiFi, Bluetooth
- USB and PCI devices
- Audio, desktop environment
- Running processes and services
- Users, virtualization/containers
- Boot info, battery, sensors/thermal

## Usage
Give it permission to run
```bash
chmod +x linux-system-info.sh
```
Run the script
```bash
./linux-system-info.sh
```
Or with sudo for full access to information
```bash
sudo ./linux-system-info.sh
```

## Navigation

| Key | Action |
|-----|--------|
| 1-22 | Select category |
| A | Run all sections |
| S | Save report to file |
| R | Rerun current section |
| M | Return to menu |
| Q | Quit |

## Requirements

- Bash 4.0+
- Linux distribution
- Optional: lm-sensors, mesa-utils for extended info
