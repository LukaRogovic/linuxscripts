# Bloatwar

Bloatware detection tool for Debian-based Linux systems (Ubuntu, Mint, Zorin, Pop!_OS, etc).

![Bloatwar Screenshot](bloatwar.png)

## What it does

Scans your system for:
- Pre-installed games and telemetry packages
- Snap and Flatpak packages with disk usage
- Large packages, orphaned packages, residual configs
- Unnecessary services and startup applications
- Cache files and browser data

Detection only - does not remove anything automatically.

## Usage
Give it permission to run
```bash
chmod +x bloatwar.sh
```
Run the script
```bash
./bloatwar.sh
```
Or with sudo for full access to information
```bash
sudo ./bloatwar.sh
```

## Navigation

| Key | Action |
|-----|--------|
| 1-11 | Select scan category |
| A | Run full scan |
| S | Save report to file |
| R | Rerun current section |
| M | Return to menu |
| Q | Quit |

## Requirements

- Bash 4.0+
- Debian-based distribution
