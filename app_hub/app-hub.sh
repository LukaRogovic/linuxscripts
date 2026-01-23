#!/bin/bash

#===============================================================================
# APP HUB - CURATED APPLICATION HUB FOR LINUX
# Interactive terminal application for installing & managing apps on Linux
# Supports: APT, DNF, Pacman, Flatpak, Snap with user source selection
# Version: 2.0
# Author: Luka Rogovic <luka032[at]gmail.com>
# GitHub: https://github.com/LukaRogovic/linuxscripts
# Licence: Open source as God wanted it
#===============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Distro type
DISTRO_TYPE=""  # debian, redhat, arch, unknown
DISTRO_NAME=""

# Package manager availability
HAS_APT=false
HAS_DNF=false
HAS_PACMAN=false
HAS_FLATPAK=false
HAS_SNAP=false

# Selected apps for installation (stores "id:source")
declare -A SELECTED_APPS

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------

cmd_exists() {
    command -v "$1" &> /dev/null
}

clear_screen() {
    clear
}

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO_NAME="$NAME"
        
        case "$ID" in
            ubuntu|debian|linuxmint|pop|zorin|elementary|kali|mx)
                DISTRO_TYPE="debian"
                ;;
            fedora|rhel|centos|rocky|alma|nobara)
                DISTRO_TYPE="redhat"
                ;;
            arch|manjaro|endeavouros|garuda|artix)
                DISTRO_TYPE="arch"
                ;;
            opensuse*)
                DISTRO_TYPE="suse"
                ;;
            *)
                # Try to detect by ID_LIKE
                case "$ID_LIKE" in
                    *debian*|*ubuntu*)
                        DISTRO_TYPE="debian"
                        ;;
                    *rhel*|*fedora*)
                        DISTRO_TYPE="redhat"
                        ;;
                    *arch*)
                        DISTRO_TYPE="arch"
                        ;;
                    *)
                        DISTRO_TYPE="unknown"
                        ;;
                esac
                ;;
        esac
    else
        DISTRO_TYPE="unknown"
        DISTRO_NAME="Unknown"
    fi
}

detect_package_managers() {
    cmd_exists apt && HAS_APT=true
    cmd_exists dnf && HAS_DNF=true
    cmd_exists pacman && HAS_PACMAN=true
    cmd_exists flatpak && HAS_FLATPAK=true
    cmd_exists snap && HAS_SNAP=true
}

# Get the native package manager name
get_native_pm() {
    case "$DISTRO_TYPE" in
        debian) echo "apt" ;;
        redhat) echo "dnf" ;;
        arch) echo "pacman" ;;
        *) echo "unknown" ;;
    esac
}

is_installed_apt() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

is_installed_dnf() {
    rpm -q "$1" &>/dev/null
}

is_installed_pacman() {
    pacman -Q "$1" &>/dev/null
}

is_installed_flatpak() {
    $HAS_FLATPAK && flatpak list 2>/dev/null | grep -qi "$1"
}

is_installed_snap() {
    $HAS_SNAP && snap list 2>/dev/null | grep -q "^$1 "
}

print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    printf "${BOLD}${BLUE}┃${NC}  ${WHITE}%-72s${NC}${BOLD}${BLUE}┃${NC}\n" "$1"
    echo -e "${BOLD}${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
}

print_section() {
    echo -e "\n${CYAN}═══ $1 ═══${NC}"
}

print_success() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "  ${RED}✗${NC} $1"
}

print_info() {
    echo -e "  ${YELLOW}○${NC} $1"
}

press_any_key() {
    echo ""
    echo -e "${DIM}Press any key to continue...${NC}"
    read -n 1 -s -r
}

#-------------------------------------------------------------------------------
# Application Database
# Format: "ID|Name|Description|APT_pkg|DNF_pkg|Pacman_pkg|Flatpak_id|Snap_pkg|Setup_cmd"
#-------------------------------------------------------------------------------

declare -a BROWSERS=(
    "firefox|Firefox|Privacy-focused open-source browser|firefox|firefox|firefox|org.mozilla.firefox|firefox|"
    "chrome|Google Chrome|Popular browser by Google|google-chrome-stable|google-chrome-stable|google-chrome|com.google.Chrome||setup_chrome"
    "brave|Brave|Privacy browser with ad blocking|brave-browser|brave-browser|brave-bin|com.brave.Browser|brave|setup_brave"
    "chromium|Chromium|Open-source browser|chromium-browser|chromium|chromium|org.chromium.Chromium|chromium|"
    "edge|Microsoft Edge|Microsoft's Chromium browser|microsoft-edge-stable|microsoft-edge-stable|microsoft-edge-stable-bin|com.microsoft.Edge||setup_edge"
    "vivaldi|Vivaldi|Feature-rich customizable browser|vivaldi-stable|vivaldi-stable|vivaldi|com.vivaldi.Vivaldi||setup_vivaldi"
    "opera|Opera|Browser with built-in VPN|opera-stable|opera-stable|opera|com.opera.Opera||"
    "librewolf|LibreWolf|Privacy-hardened Firefox fork|||librewolf-bin|io.gitlab.librewolf-community||"
    "tor-browser|Tor Browser|Anonymous browsing|||tor-browser|com.github.nickvergessen.TorBrowser||"
    "epiphany|GNOME Web|Simple GNOME browser|epiphany-browser|epiphany|epiphany|org.gnome.Epiphany||"
    "falkon|Falkon|KDE lightweight browser|falkon|falkon|falkon|org.kde.falkon||"
    "midori|Midori|Lightweight browser|midori|midori|midori|||"
    "min|Min|Minimal browser|||min|com.minbrowser.Min||"
    "waterfox|Waterfox|Firefox fork|waterfox|waterfox|waterfox-bin|net.waterfox.waterfox||"
    "zen-browser|Zen Browser|Privacy Firefox fork|||zen-browser-bin|io.github.nickvergessen.zen-browser||"
    "floorp|Floorp|Customizable Firefox fork|||floorp-bin|one.ablaze.floorp||"
)

declare -a EDITORS=(
    "vscode|VS Code|Popular code editor by Microsoft|code|code|visual-studio-code-bin|com.visualstudio.code|code|setup_vscode"
    "vscodium|VSCodium|VS Code without telemetry|codium|codium|vscodium-bin|com.vscodium.codium||"
    "sublime|Sublime Text|Fast lightweight editor|sublime-text|sublime-text|sublime-text-4|com.sublimetext.three|sublime-text|setup_sublime"
    "vim|Vim|Classic terminal editor|vim|vim|vim|||"
    "neovim|Neovim|Modern Vim fork|neovim|neovim|neovim||nvim|"
    "gedit|Gedit|Simple GNOME editor|gedit|gedit|gedit|org.gnome.gedit||"
    "kate|Kate|KDE advanced editor|kate|kate|kate|org.kde.kate||"
    "geany|Geany|Lightweight IDE|geany|geany|geany|org.geany.Geany||"
    "notepadqq|Notepadqq|Notepad++ alternative|notepadqq||notepadqq|com.notepadqq.Notepadqq||"
    "emacs|Emacs|Extensible text editor|emacs|emacs|emacs|||"
    "atom|Pulsar|Community-led Atom fork|||pulsar-bin|dev.pulsar_edit.Pulsar||"
    "brackets|Brackets|Web development editor|||brackets-bin|io.brackets.Brackets||"
    "bluefish|Bluefish|Web developer editor|bluefish|bluefish|bluefish|||"
    "cudatext|CudaText|Cross-platform editor|||cudatext-bin|io.github.nickvergessen.cudatext||"
    "micro|Micro|Modern terminal editor|micro|micro|micro|||"
    "nano|Nano|Simple terminal editor|nano|nano|nano|||"
    "helix|Helix|Modal terminal editor|||helix|com.helix_editor.Helix||"
    "lapce|Lapce|Fast Rust-based editor|||lapce|dev.lapce.lapce||"
    "zed|Zed|High-performance editor|||zed|dev.zed.Zed||"
    "jetbrains-toolbox|JetBrains Toolbox|Manage JetBrains IDEs|||jetbrains-toolbox|com.jetbrains.Toolbox||"
    "intellij|IntelliJ IDEA CE|Java IDE|||intellij-idea-community-edition|com.jetbrains.IntelliJ-IDEA-Community||"
    "pycharm|PyCharm CE|Python IDE|||pycharm-community-edition|com.jetbrains.PyCharm-Community||"
    "android-studio|Android Studio|Android development|||android-studio|com.google.AndroidStudio||"
    "eclipse|Eclipse|Java IDE|eclipse|eclipse-jee|eclipse-java|org.eclipse.Java||"
    "netbeans|NetBeans|Java IDE|netbeans|netbeans|netbeans|org.apache.netbeans||"
    "codeblocks|Code::Blocks|C/C++ IDE|codeblocks|codeblocks|codeblocks|org.codeblocks.codeblocks||"
    "gnome-builder|GNOME Builder|GNOME IDE|gnome-builder|gnome-builder|gnome-builder|org.gnome.Builder||"
    "kdevelop|KDevelop|KDE IDE|kdevelop|kdevelop|kdevelop|org.kde.kdevelop||"
    "arduino-ide|Arduino IDE|Arduino development|||arduino-ide-bin|cc.arduino.IDE2||"
)

declare -a MEDIA=(
    # Video Players
    "vlc|VLC|Universal media player|vlc|vlc|vlc|org.videolan.VLC|vlc|"
    "mpv|MPV|Minimalist video player|mpv|mpv|mpv|io.mpv.Mpv||"
    "celluloid|Celluloid|GTK frontend for MPV|celluloid|celluloid|celluloid|io.github.celluloid_player.Celluloid||"
    "smplayer|SMPlayer|MPlayer frontend|smplayer|smplayer|smplayer|info.smplayer.SMPlayer||"
    "haruna|Haruna|KDE video player|||haruna|org.kde.haruna||"
    "totem|GNOME Videos|GNOME video player|totem|totem|totem|org.gnome.Totem||"
    # Image Editors
    "gimp|GIMP|Image editor|gimp|gimp|gimp|org.gimp.GIMP|gimp|"
    "krita|Krita|Digital painting|krita|krita|krita|org.kde.krita||"
    "inkscape|Inkscape|Vector graphics|inkscape|inkscape|inkscape|org.inkscape.Inkscape||"
    "darktable|Darktable|Photo workflow|darktable|darktable|darktable|org.darktable.Darktable||"
    "rawtherapee|RawTherapee|RAW photo processor|rawtherapee|rawtherapee|rawtherapee|com.rawtherapee.RawTherapee||"
    "digikam|digiKam|Photo management|digikam|digikam|digikam|org.kde.digikam||"
    "shotwell|Shotwell|Photo manager|shotwell|shotwell|shotwell|org.gnome.Shotwell||"
    "pinta|Pinta|Simple image editor|pinta|pinta|pinta|com.github.PintaProject.Pinta||"
    "photopea|Photopea|Online Photoshop alternative||||photopea|"
    "drawing|Drawing|Simple drawing app|drawing|drawing|drawing|com.github.maoschanz.drawing||"
    # Audio Editors & Players
    "audacity|Audacity|Audio editor|audacity|audacity|audacity|org.audacityteam.Audacity||"
    "ardour|Ardour|Digital audio workstation|ardour|ardour|ardour|org.ardour.Ardour||"
    "lmms|LMMS|Music production|lmms|lmms|lmms|io.lmms.LMMS||"
    "musescore|MuseScore|Music notation|musescore|musescore|musescore|org.musescore.MuseScore||"
    "spotify|Spotify|Music streaming||||com.spotify.Client|spotify|"
    "rhythmbox|Rhythmbox|Music player|rhythmbox|rhythmbox|rhythmbox|org.gnome.Rhythmbox3||"
    "clementine|Clementine|Music player|clementine|clementine|clementine|org.clementine_player.Clementine||"
    "strawberry|Strawberry|Music player|||strawberry|org.strawberrymusicplayer.strawberry||"
    "elisa|Elisa|KDE music player|elisa|elisa|elisa|org.kde.elisa||"
    "lollypop|Lollypop|GNOME music player|lollypop|lollypop|lollypop|org.gnome.Lollypop||"
    "amberol|Amberol|Simple music player|||amberol|io.bassi.Amberol||"
    "tidal-hifi|Tidal Hi-Fi|Tidal client|||tidal-hifi-bin|com.mastermindzh.tidal-hifi||"
    "nuclear|Nuclear|Free streaming player|||nuclear|org.js.nuclear.Nuclear||"
    # Video Editors
    "obs|OBS Studio|Screen recording & streaming|obs-studio|obs-studio|obs-studio|com.obsproject.Studio||"
    "kdenlive|Kdenlive|Video editor|kdenlive|kdenlive|kdenlive|org.kde.kdenlive||"
    "shotcut|Shotcut|Video editor|||shotcut|org.shotcut.Shotcut||"
    "openshot|OpenShot|Easy video editor|openshot-qt|openshot|openshot|org.openshot.OpenShot||"
    "pitivi|Pitivi|GNOME video editor|pitivi|pitivi|pitivi|org.pitivi.Pitivi||"
    "davinci-resolve|DaVinci Resolve|Professional video editor|||davinci-resolve|com.blackmagicdesign.DaVinciResolve||"
    "handbrake|HandBrake|Video transcoder|handbrake|HandBrake|handbrake|fr.handbrake.ghb||"
    "ffmpeg|FFmpeg|Media converter|ffmpeg|ffmpeg|ffmpeg|||"
    # 3D & Animation
    "blender|Blender|3D creation suite|blender|blender|blender|org.blender.Blender||"
    "freecad|FreeCAD|3D CAD modeler|freecad|freecad|freecad|org.freecadweb.FreeCAD||"
    "openscad|OpenSCAD|Programmable CAD|openscad|openscad|openscad|org.openscad.OpenSCAD||"
    # Screen Recording
    "simplescreenrecorder|SimpleScreenRecorder|Screen recorder|simplescreenrecorder|simplescreenrecorder|simplescreenrecorder|||"
    "peek|Peek|GIF recorder|peek|peek|peek|com.uploadedlobster.peek||"
    "kazam|Kazam|Screen recorder|kazam|kazam|kazam|||"
    "kooha|Kooha|Simple screen recorder|||kooha|io.github.seadve.Kooha||"
    # Podcast & Streaming
    "gpodder|gPodder|Podcast client|gpodder|gpodder|gpodder|org.gpodder.gpodder||"
    "vocal|Vocal|Podcast app|||vocal|com.github.needleandthread.vocal||"
    "shortwave|Shortwave|Internet radio|||shortwave|de.haeckerfelix.Shortwave||"
)

declare -a COMMUNICATION=(
    # Chat & Messaging
    "discord|Discord|Gaming chat platform|discord|discord|discord|com.discordapp.Discord|discord|"
    "telegram|Telegram|Secure messaging|telegram-desktop|telegram-desktop|telegram-desktop|org.telegram.desktop|telegram-desktop|"
    "signal|Signal|Private messenger|signal-desktop|signal-desktop|signal-desktop|org.signal.Signal||"
    "element|Element|Matrix client|element-desktop|element|element-desktop|im.riot.Riot|element-desktop|"
    "whatsapp|WhatsApp|WhatsApp desktop||||whatsdesk|"
    "viber|Viber|Messaging app|||viber|com.viber.Viber||"
    "wire|Wire|Secure messenger|||wire-desktop|com.wire.WireDesktop||"
    "session|Session|Private messenger|||session-desktop-bin|network.loki.Session||"
    "keybase|Keybase|Encrypted chat|keybase|keybase|keybase|io.keybase.Client||"
    "revolt|Revolt|Discord alternative|||revolt-desktop|chat.revolt.RevoltDesktop||"
    "guilded|Guilded|Gaming chat|||guilded|com.guilded.Guilded||"
    "hexchat|HexChat|IRC client|hexchat|hexchat|hexchat|io.github.Hexchat||"
    "pidgin|Pidgin|Multi-protocol chat|pidgin|pidgin|pidgin|im.pidgin.Pidgin||"
    "dino|Dino|XMPP client|dino-im|dino|dino|im.dino.Dino||"
    "gajim|Gajim|XMPP client|gajim|gajim|gajim|org.gajim.Gajim||"
    # Video Conferencing
    "zoom|Zoom|Video conferencing|zoom|zoom|zoom|us.zoom.Zoom|zoom-client|"
    "teams|Microsoft Teams|Business communication|teams|teams-for-linux|teams|com.microsoft.Teams||"
    "skype|Skype|Video calling|skypeforlinux|skypeforlinux|skypeforlinux-bin|com.skype.Client|skype|"
    "webex|Webex|Cisco video meetings|||webex|com.cisco.webex.Meetings||"
    "jitsi|Jitsi Meet|Open-source video calls|||jitsi-meet|org.jitsi.jitsi-meet||"
    "linphone|Linphone|SIP video calls|linphone|linphone|linphone|com.belledonnecommunications.linphone||"
    # Team Communication
    "slack|Slack|Team communication|slack-desktop|slack|slack-desktop|com.slack.Slack|slack|"
    "mattermost|Mattermost|Team messaging|mattermost-desktop|mattermost-desktop|mattermost-desktop|com.mattermost.Desktop||"
    "rocketchat|Rocket.Chat|Team chat|||rocketchat-desktop|chat.rocket.RocketChat||"
    "zulip|Zulip|Team chat|zulip|zulip|zulip-desktop|org.zulip.Zulip||"
    "ferdium|Ferdium|All-in-one messenger|||ferdium-bin|org.ferdium.Ferdium||"
    # Email Clients
    "thunderbird|Thunderbird|Email client|thunderbird|thunderbird|thunderbird|org.mozilla.Thunderbird||"
    "evolution|Evolution|GNOME email client|evolution|evolution|evolution|org.gnome.Evolution||"
    "geary|Geary|Simple email client|geary|geary|geary|org.gnome.Geary||"
    "kmail|KMail|KDE email client|kmail|kmail|kmail|org.kde.kmail2||"
    "mailspring|Mailspring|Modern email client|||mailspring|com.getmailspring.Mailspring||"
    "betterbird|Betterbird|Enhanced Thunderbird|||betterbird-bin|eu.betterbird.Betterbird||"
    "protonmail-bridge|ProtonMail Bridge|ProtonMail desktop|||protonmail-bridge|ch.protonmail.protonmail-bridge||"
    # Social Media
    "tweetdeck|Tweetdeck|Twitter client||||tweetdeck-electron|"
    "cawbird|Cawbird|Twitter client|||cawbird|uk.co.ibboard.cawbird||"
    "tuba|Tuba|Mastodon client|||tuba|dev.geopjr.Tuba||"
    "tokodon|Tokodon|KDE Mastodon client|||tokodon|org.kde.tokodon||"
)

declare -a UTILITIES=(
    # System Backup & Recovery
    "timeshift|Timeshift|System backup|timeshift|timeshift|timeshift|||"
    "deja-dup|Deja Dup|Simple backups|deja-dup|deja-dup|deja-dup|org.gnome.DejaDup||"
    "vorta|Vorta|Borg backup GUI|||vorta|com.borgbase.Vorta||"
    "backintime|Back In Time|Backup tool|backintime|backintime|backintime|net.launchpad.backintime||"
    "rescuezilla|Rescuezilla|Disk imaging|||rescuezilla|||"
    # System Monitoring
    "htop|htop|Process viewer|htop|htop|htop|||"
    "btop|btop|Resource monitor|btop|btop|btop|||"
    "neofetch|Neofetch|System info|neofetch|neofetch|neofetch|||"
    "fastfetch|Fastfetch|Fast system info|fastfetch|fastfetch|fastfetch|||"
    "stacer|Stacer|System optimizer|stacer|stacer|stacer|com.oguzhaninan.Stacer||"
    "gnome-system-monitor|System Monitor|GNOME monitor|gnome-system-monitor|gnome-system-monitor|gnome-system-monitor|||"
    "ksysguard|KSysGuard|KDE monitor|ksysguard|ksysguard|ksysguard|||"
    "mission-center|Mission Center|Modern system monitor|||mission-center|io.missioncenter.MissionCenter||"
    "resources|Resources|System monitor|||resources|net.nokyan.Resources||"
    "cpu-x|CPU-X|CPU info|cpu-x|cpu-x|cpu-x|io.github.thetumultuousunicornofdarkness.cpu-x||"
    "hardinfo|HardInfo|System profiler|hardinfo|hardinfo|hardinfo|||"
    # System Cleaning
    "bleachbit|BleachBit|System cleaner|bleachbit|bleachbit|bleachbit|org.bleachbit.BleachBit||"
    "sweeper|Sweeper|KDE cleaner|sweeper|sweeper|sweeper|||"
    # Disk Management
    "gparted|GParted|Partition editor|gparted|gparted|gparted|org.gnome.GParted||"
    "gnome-disks|GNOME Disks|Disk utility|gnome-disk-utility|gnome-disk-utility|gnome-disk-utility|||"
    "kde-partition-manager|KDE Partition Manager|KDE partitioner|partitionmanager|kde-partitionmanager|partitionmanager|org.kde.partitionmanager||"
    "baobab|Disk Usage Analyzer|Disk usage|baobab|baobab|baobab|org.gnome.baobab||"
    "filelight|Filelight|KDE disk usage|filelight|filelight|filelight|org.kde.filelight||"
    "ncdu|ncdu|Terminal disk usage|ncdu|ncdu|ncdu|||"
    # Screenshot Tools
    "flameshot|Flameshot|Screenshot tool|flameshot|flameshot|flameshot|org.flameshot.Flameshot||"
    "shutter|Shutter|Screenshot editor|shutter|shutter|shutter|||"
    "gnome-screenshot|GNOME Screenshot|Simple screenshots|gnome-screenshot|gnome-screenshot|gnome-screenshot|||"
    "spectacle|Spectacle|KDE screenshots|spectacle|spectacle|spectacle|org.kde.spectacle||"
    "ksnip|Ksnip|Annotation tool|ksnip|ksnip|ksnip|org.ksnip.ksnip||"
    # Remote Desktop & File Transfer
    "remmina|Remmina|Remote desktop|remmina|remmina|remmina|org.remmina.Remmina||"
    "anydesk|AnyDesk|Remote desktop|||anydesk-bin|com.anydesk.Anydesk||"
    "rustdesk|RustDesk|Open remote desktop|||rustdesk-bin|com.rustdesk.RustDesk||"
    "filezilla|FileZilla|FTP client|filezilla|filezilla|filezilla|org.filezillaproject.Filezilla||"
    "warpinator|Warpinator|LAN file sharing|warpinator|warpinator|warpinator|org.x.Warpinator||"
    "localsend|LocalSend|Cross-platform sharing|||localsend-bin|org.localsend.localsend_app||"
    # Password Managers
    "bitwarden|Bitwarden|Password manager|bitwarden|bitwarden|bitwarden|com.bitwarden.desktop|bitwarden|"
    "keepassxc|KeePassXC|Password manager|keepassxc|keepassxc|keepassxc|org.keepassxc.KeePassXC||"
    "1password|1Password|Password manager|||1password|com.onepassword.OnePassword||"
    "secrets|GNOME Secrets|Password manager|||secrets|org.gnome.World.Secrets||"
    "authpass|AuthPass|Password manager|||authpass-bin|design.codeux.authpass||"
    # Download & Torrent
    "qbittorrent|qBittorrent|Torrent client|qbittorrent|qbittorrent|qbittorrent|org.qbittorrent.qBittorrent||"
    "transmission|Transmission|Simple torrent|transmission-gtk|transmission-gtk|transmission-gtk|com.transmissionbt.Transmission||"
    "deluge|Deluge|Torrent client|deluge|deluge|deluge|org.deluge_torrent.deluge||"
    "fragments|Fragments|GNOME torrent|||fragments|de.haeckerfelix.Fragments||"
    "persepolis|Persepolis|Download manager|persepolis|persepolis|persepolis|com.github.persepolisdm.persepolis||"
    "uget|uGet|Download manager|uget|uget|uget|||"
    "jdownloader|JDownloader|Download manager|||jdownloader2|org.jdownloader.JDownloader||"
    # File Sync
    "syncthing|Syncthing|File sync|syncthing|syncthing|syncthing|me.kozec.syncthingtk||"
    "dropbox|Dropbox|Cloud storage|||dropbox|com.dropbox.Client||"
    "nextcloud|Nextcloud|Self-hosted cloud|nextcloud-desktop-client|nextcloud-client|nextcloud-client|com.nextcloud.desktopclient.nextcloud||"
    "insync|Insync|Google Drive sync|||insync|com.insynchq.insync||"
    "megasync|MEGAsync|MEGA cloud|megasync|megasync|megasync|nz.mega.MEGAsync||"
    "rclone|Rclone|Cloud sync CLI|rclone|rclone|rclone|||"
    # File Managers
    "nautilus|Nautilus|GNOME files|nautilus|nautilus|nautilus|org.gnome.Nautilus||"
    "dolphin|Dolphin|KDE files|dolphin|dolphin|dolphin|org.kde.dolphin||"
    "nemo|Nemo|Cinnamon files|nemo|nemo|nemo|||"
    "thunar|Thunar|Xfce files|thunar|thunar|thunar|||"
    "pcmanfm|PCManFM|Lightweight files|pcmanfm|pcmanfm|pcmanfm|||"
    "ranger|Ranger|Terminal file manager|ranger|ranger|ranger|||"
    "mc|Midnight Commander|Terminal file manager|mc|mc|mc|||"
    "doublecmd|Double Commander|Twin-panel manager|doublecmd-qt|doublecmd|doublecmd-qt|org.doublecmd.DoubleCommander||"
    # Archive Managers
    "file-roller|File Roller|GNOME archiver|file-roller|file-roller|file-roller|org.gnome.FileRoller||"
    "ark|Ark|KDE archiver|ark|ark|ark|org.kde.ark||"
    "p7zip|7-Zip|Archive tool|p7zip-full|p7zip|p7zip|||"
    "unrar|UnRAR|RAR extractor|unrar|unrar|unrar|||"
    # Clipboard Managers
    "copyq|CopyQ|Clipboard manager|copyq|copyq|copyq|com.github.hluk.copyq||"
    "gpaste|GPaste|GNOME clipboard|gpaste|gpaste|gpaste|org.gnome.GPaste||"
    "parcellite|Parcellite|Clipboard manager|parcellite|parcellite|parcellite|||"
    # VPN Clients
    "protonvpn|ProtonVPN|VPN client|||protonvpn|com.protonvpn.www||"
    "mullvad|Mullvad VPN|VPN client|||mullvad-vpn-bin|net.mullvad.MullvadVPN||"
    "openvpn|OpenVPN|VPN client|openvpn|openvpn|openvpn|||"
    "wireguard|WireGuard|VPN protocol|wireguard-tools|wireguard-tools|wireguard-tools|||"
    # Virtualization
    "virtualbox|VirtualBox|Virtual machines|virtualbox|VirtualBox|virtualbox|org.virtualbox.VirtualBox||"
    "virt-manager|Virt Manager|QEMU/KVM manager|virt-manager|virt-manager|virt-manager|||"
    "gnome-boxes|GNOME Boxes|Simple VMs|gnome-boxes|gnome-boxes|gnome-boxes|org.gnome.Boxes||"
    # Miscellaneous
    "dconf-editor|Dconf Editor|Settings editor|dconf-editor|dconf-editor|dconf-editor|ca.desrt.dconf-editor||"
    "font-manager|Font Manager|Font tool|font-manager|font-manager|font-manager|org.gnome.FontManager||"
    "cpu-energy-meter|PowerTOP|Power management|powertop|powertop|powertop|||"
    "solaar|Solaar|Logitech manager|solaar|solaar|solaar|io.github.pwr_solaar.solaar||"
    "piper|Piper|Gaming mouse config|piper|piper|piper|org.freedesktop.Piper||"
    "input-remapper|Input Remapper|Key remapping|||input-remapper|io.github.sezanzeb.input_remapper||"
)

declare -a DEVELOPMENT=(
    # Version Control
    "git|Git|Version control|git|git|git|||"
    "gh|GitHub CLI|GitHub command line|gh|gh|github-cli|||setup_gh_cli"
    "gitlab-cli|GitLab CLI|GitLab command line|||glab|io.gitlab.Glab||"
    "gitg|Gitg|Git GUI|gitg|gitg|gitg|org.gnome.gitg||"
    "gittyup|Gittyup|Git client|||gittyup|com.github.Murmele.Gittyup||"
    "gitkraken|GitKraken|Git GUI|||gitkraken|com.axosoft.GitKraken||"
    "sublime-merge|Sublime Merge|Git client|||sublime-merge|com.sublimemerge.App||"
    "lazygit|Lazygit|Terminal Git UI|lazygit|lazygit|lazygit|||"
    "tig|Tig|Terminal Git viewer|tig|tig|tig|||"
    # Containers & Orchestration
    "docker|Docker|Container platform|docker.io|docker|docker|||setup_docker"
    "podman|Podman|Rootless containers|podman|podman|podman|||"
    "docker-compose|Docker Compose|Container orchestration|docker-compose|docker-compose|docker-compose|||"
    "kubectl|Kubectl|Kubernetes CLI|kubectl|kubectl|kubectl|||"
    "minikube|Minikube|Local Kubernetes|minikube|minikube|minikube|||"
    "k9s|K9s|Kubernetes TUI|||k9s|io.k9s|||"
    "helm|Helm|Kubernetes packages|||helm|||"
    "podman-desktop|Podman Desktop|Container GUI|||podman-desktop|io.podman_desktop.PodmanDesktop||"
    # Programming Languages
    "nodejs|Node.js|JavaScript runtime|nodejs|nodejs|nodejs|||setup_nodejs"
    "python3-pip|Python Pip|Python package manager|python3-pip|python3-pip|python-pip|||"
    "python3-venv|Python Venv|Virtual environments|python3-venv|python3-virtualenv|python-virtualenv|||"
    "rustup|Rustup|Rust toolchain|||rustup|org.rustup|||"
    "golang|Go|Go language|golang|golang|go|||"
    "openjdk|OpenJDK|Java JDK|default-jdk|java-latest-openjdk|jdk-openjdk|||"
    "ruby|Ruby|Ruby language|ruby|ruby|ruby|||"
    "php|PHP|PHP language|php|php|php|||"
    "dotnet|.NET SDK|.NET development|dotnet-sdk-8.0|dotnet|dotnet-sdk|||"
    "lua|Lua|Lua language|lua5.4|lua|lua|||"
    "perl|Perl|Perl language|perl|perl|perl|||"
    # Build Tools
    "build-essential|Build Tools|Compilers & make|build-essential||base-devel|||setup_buildtools"
    "cmake|CMake|Build system|cmake|cmake|cmake|||"
    "meson|Meson|Build system|meson|meson|meson|||"
    "ninja|Ninja|Build tool|ninja-build|ninja-build|ninja|||"
    "clang|Clang|C/C++ compiler|clang|clang|clang|||"
    "gcc|GCC|GNU compiler|gcc|gcc|gcc|||"
    "make|Make|Build automation|make|make|make|||"
    # CLI Tools
    "curl|cURL|URL transfer tool|curl|curl|curl|||"
    "wget|Wget|File downloader|wget|wget|wget|||"
    "jq|jq|JSON processor|jq|jq|jq|||"
    "yq|yq|YAML processor|||yq|io.github.go_yq|||"
    "httpie|HTTPie|HTTP client|httpie|httpie|httpie|||"
    "tree|Tree|Directory listing|tree|tree|tree|||"
    "ripgrep|Ripgrep|Fast grep|ripgrep|ripgrep|ripgrep|||"
    "fd|fd|Fast find|fd-find|fd-find|fd|||"
    "fzf|fzf|Fuzzy finder|fzf|fzf|fzf|||"
    "bat|Bat|Better cat|bat|bat|bat|||"
    "exa|Exa|Better ls|exa|exa|exa|||"
    "eza|Eza|Modern ls|eza|eza|eza|||"
    "tldr|TLDR|Simplified man pages|tldr|tldr|tldr|||"
    "tmux|Tmux|Terminal multiplexer|tmux|tmux|tmux|||"
    "screen|Screen|Terminal multiplexer|screen|screen|screen|||"
    "zsh|Zsh|Z shell|zsh|zsh|zsh|||"
    "fish|Fish|Friendly shell|fish|fish|fish|||"
    "starship|Starship|Shell prompt|||starship|io.starship.Starship||"
    # Database Tools
    "postman|Postman|API testing||||com.getpostman.Postman||"
    "insomnia|Insomnia|API client|||insomnia|rest.insomnia.Insomnia||"
    "hoppscotch|Hoppscotch|API testing|||hoppscotch|io.hoppscotch.Hoppscotch||"
    "dbeaver|DBeaver|Database tool|||dbeaver|io.dbeaver.DBeaverCommunity||"
    "beekeeper|Beekeeper Studio|Database GUI|||beekeeper-studio-bin|io.beekeeperstudio.Studio||"
    "mongodb-compass|MongoDB Compass|MongoDB GUI|||mongodb-compass|com.mongodb.Compass||"
    "pgadmin4|pgAdmin|PostgreSQL admin|pgadmin4|pgadmin4|pgadmin4|||"
    "mysql-workbench|MySQL Workbench|MySQL GUI|mysql-workbench|mysql-workbench|mysql-workbench|||"
    "redis-insight|RedisInsight|Redis GUI|||redisinsight|com.redis.RedisInsight||"
    # Network Tools
    "wireshark|Wireshark|Network analyzer|wireshark|wireshark|wireshark|org.wireshark.Wireshark||"
    "nmap|Nmap|Port scanner|nmap|nmap|nmap|||"
    "netcat|Netcat|Network utility|netcat-openbsd|nmap-ncat|gnu-netcat|||"
    "tcpdump|Tcpdump|Packet capture|tcpdump|tcpdump|tcpdump|||"
    "mtr|MTR|Network diagnostics|mtr|mtr|mtr|||"
    # DevOps Tools
    "terraform|Terraform|Infrastructure as code|||terraform|io.terraform|||"
    "ansible|Ansible|Automation tool|ansible|ansible|ansible|||"
    "vagrant|Vagrant|VM management|vagrant|vagrant|vagrant|||"
    # Text Processing
    "sed|Sed|Stream editor|sed|sed|sed|||"
    "awk|AWK|Text processing|gawk|gawk|gawk|||"
    "grep|Grep|Pattern matching|grep|grep|grep|||"
    # Documentation
    "pandoc|Pandoc|Document converter|pandoc|pandoc|pandoc|||"
    "hugo|Hugo|Static site generator|hugo|hugo|hugo|||"
    "mkdocs|MkDocs|Documentation generator|mkdocs|mkdocs|mkdocs|||"
    # Miscellaneous Dev Tools
    "meld|Meld|Diff tool|meld|meld|meld|org.gnome.meld||"
    "diffuse|Diffuse|Diff viewer|diffuse|diffuse|diffuse|||"
    "shellcheck|ShellCheck|Shell linter|shellcheck|ShellCheck|shellcheck|||"
    "shfmt|Shfmt|Shell formatter|||shfmt|||"
    "direnv|Direnv|Environment manager|direnv|direnv|direnv|||"
    "asdf|asdf|Version manager|||asdf-vm|||"
)

declare -a GAMING=(
    # Game Launchers & Stores
    "steam|Steam|Gaming platform|steam|steam|steam|com.valvesoftware.Steam||"
    "lutris|Lutris|Game manager|lutris|lutris|lutris|net.lutris.Lutris||"
    "heroic|Heroic Games|Epic/GOG launcher|||heroic-games-launcher-bin|com.heroicgameslauncher.hgl||"
    "bottles|Bottles|Wine manager|||bottles|com.usebottles.bottles||"
    "minigalaxy|Minigalaxy|GOG client|minigalaxy|minigalaxy|minigalaxy|io.github.sharkwouter.Minigalaxy||"
    "itch|itch.io|Indie game store|||itch|io.itch.itch||"
    "gamehub|GameHub|Game library|||gamehub|com.github.tkashkin.gamehub||"
    "pegasus|Pegasus|Game frontend|||pegasus-fe|org.pegasus_frontend.Pegasus||"
    # Compatibility Layers
    "wine|Wine|Windows compatibility|wine|wine|wine|||"
    "winetricks|Winetricks|Wine helper|winetricks|winetricks|winetricks|||"
    "proton-ge|Proton GE|Custom Proton|||proton-ge-custom-bin|||"
    "protonup-qt|ProtonUp-Qt|Proton manager|||protonup-qt|net.davidotek.pupgui2||"
    # Emulators
    "retroarch|RetroArch|Multi-system emulator|retroarch|retroarch|retroarch|org.libretro.RetroArch||"
    "dolphin-emu|Dolphin|GameCube/Wii emulator|dolphin-emu|dolphin-emu|dolphin-emu|org.DolphinEmu.dolphin-emu||"
    "pcsx2|PCSX2|PS2 emulator|||pcsx2|net.pcsx2.PCSX2||"
    "rpcs3|RPCS3|PS3 emulator|||rpcs3-bin|net.rpcs3.RPCS3||"
    "yuzu|Yuzu|Switch emulator|||yuzu|org.yuzu_emu.yuzu||"
    "ryujinx|Ryujinx|Switch emulator|||ryujinx|org.ryujinx.Ryujinx||"
    "cemu|Cemu|Wii U emulator|||cemu|info.cemu.Cemu||"
    "ppsspp|PPSSPP|PSP emulator|ppsspp|ppsspp|ppsspp|org.ppsspp.PPSSPP||"
    "desmume|DeSmuME|DS emulator|desmume|desmume|desmume|org.desmume.DeSmuME||"
    "mgba|mGBA|GBA emulator|mgba|mgba|mgba|io.mgba.mGBA||"
    "citra|Citra|3DS emulator|||citra-bin|org.citra_emu.citra||"
    "xemu|xemu|Xbox emulator|||xemu|app.xemu.xemu||"
    # Game Tools
    "mangohud|MangoHud|FPS overlay|mangohud|mangohud|mangohud|org.freedesktop.Platform.VulkanLayer.MangoHud||"
    "goverlay|GOverlay|MangoHud config|||goverlay-bin|io.github.benjamimgois.goverlay||"
    "gamemode|GameMode|Performance optimizer|gamemode|gamemode|gamemode|||"
    "vkbasalt|vkBasalt|Post-processing|||vkbasalt|||"
    "corectrl|CoreCtrl|GPU control|||corectrl|org.corectrl.CoreCtrl||"
    "openrgb|OpenRGB|RGB control|||openrgb|org.openrgb.OpenRGB||"
    # Controllers
    "antimicro|AntiMicroX|Gamepad mapper|||antimicrox|io.github.antimicrox.antimicrox||"
    "sc-controller|SC Controller|Steam controller|||sc-controller|com.github.Ryochan7.sc-controller||"
    "oversteer|Oversteer|Racing wheel setup|||oversteer|org.oversteer.Oversteer||"
    # Streaming
    "obs-vkcapture|OBS VkCapture|Game capture|||obs-vkcapture|||"
    "sunshine|Sunshine|Game streaming|||sunshine|dev.lizardbyte.Sunshine||"
    "moonlight|Moonlight|NVIDIA streaming|||moonlight-qt|com.moonlight_stream.Moonlight||"
    # Game Development
    "godot|Godot|Game engine|godot3|godot|godot|org.godotengine.Godot||"
    "unity-hub|Unity Hub|Unity engine|||unityhub|com.unity.UnityHub||"
    "unreal-engine|Unreal Engine|Epic engine|||unreal-engine|||"
)

declare -a OFFICE=(
    # Office Suites
    "libreoffice|LibreOffice|Full office suite|libreoffice|libreoffice|libreoffice-fresh|org.libreoffice.LibreOffice||"
    "onlyoffice|OnlyOffice|MS-compatible suite|||onlyoffice-bin|org.onlyoffice.desktopeditors||"
    "wps-office|WPS Office|MS-compatible suite|||wps-office|com.wps.Office||"
    "calligra|Calligra|KDE office suite|calligra|calligra|calligra|org.kde.calligra||"
    "freeoffice|FreeOffice|SoftMaker free suite|||freeoffice|||"
    # Document Viewers
    "evince|Evince|PDF viewer|evince|evince|evince|org.gnome.Evince||"
    "okular|Okular|KDE document viewer|okular|okular|okular|org.kde.okular||"
    "zathura|Zathura|Minimal PDF viewer|zathura|zathura|zathura|||"
    "xreader|Xreader|Document viewer|xreader|xreader|xreader|||"
    "foliate|Foliate|E-book reader|||foliate|com.github.johnfactotum.Foliate||"
    "calibre|Calibre|E-book manager|calibre|calibre|calibre|com.calibre_ebook.calibre||"
    # Note Taking
    "obsidian|Obsidian|Knowledge base|||obsidian|md.obsidian.Obsidian||"
    "joplin|Joplin|Note taking|||joplin-desktop|net.cozic.joplin_desktop||"
    "logseq|Logseq|Knowledge graph|||logseq-desktop-bin|com.logseq.Logseq||"
    "notion|Notion|Productivity app|||notion-app|so.notion.Notion||"
    "simplenote|Simplenote|Simple notes|||simplenote|com.simplenote.Simplenote||"
    "standardnotes|Standard Notes|Encrypted notes|||standardnotes-bin|org.standardnotes.standardnotes||"
    "zettlr|Zettlr|Markdown editor|||zettlr-bin|com.zettlr.Zettlr||"
    "qownnotes|QOwnNotes|Note taking|qownnotes|qownnotes|qownnotes|org.qownnotes.QOwnNotes||"
    "gnome-notes|GNOME Notes|Simple notes|gnome-notes||bijiben|org.gnome.Notes||"
    "xournalpp|Xournal++|Handwriting notes|xournalpp|xournalpp|xournalpp|com.github.xournalpp.xournalpp||"
    "rnote|Rnote|Handwritten notes|||rnote|com.github.flxzt.rnote||"
    # Task Management
    "todoist|Todoist|Task manager||||todoist|"
    "ticktick|TickTick|Task manager|||ticktick|com.ticktick.TickTick||"
    "planner|Planner|Task manager|||planner|com.github.alainm23.planner||"
    "tasks|GNOME To Do|Simple tasks|gnome-todo|gnome-todo|gnome-todo|org.gnome.Todo||"
    "super-productivity|Super Productivity|Time tracker|||super-productivity-bin|com.super_productivity.SuperProductivity||"
    # Calendar
    "gnome-calendar|GNOME Calendar|Calendar app|gnome-calendar|gnome-calendar|gnome-calendar|org.gnome.Calendar||"
    "korganizer|KOrganizer|KDE calendar|korganizer|korganizer|korganizer|org.kde.korganizer||"
    # Mind Mapping
    "freeplane|Freeplane|Mind mapping|freeplane|freeplane|freeplane|org.freeplane.App||"
    "minder|Minder|Mind mapping|||minder|com.github.phase1geo.minder||"
    "xmind|XMind|Mind mapping|||xmind|net.xmind.XMind||"
    "drawio|Draw.io|Diagramming|||drawio-desktop-bin|com.jgraph.drawio.desktop||"
    # LaTeX & Writing
    "texlive|TeX Live|LaTeX distribution|texlive-full|texlive|texlive-most|||"
    "texstudio|TeXstudio|LaTeX editor|texstudio|texstudio|texstudio|org.texstudio.TeXstudio||"
    "kile|Kile|KDE LaTeX editor|kile|kile|kile|org.kde.kile||"
    "lyx|LyX|Document processor|lyx|lyx|lyx|org.lyx.LyX||"
    "manuskript|Manuskript|Writing tool|||manuskript|info.manuskript.Manuskript||"
    "ghostwriter|Ghostwriter|Markdown editor|ghostwriter|ghostwriter|ghostwriter|io.github.wereturtle.ghostwriter||"
    "apostrophe|Apostrophe|Markdown editor|||apostrophe|org.gnome.gitlab.somas.Apostrophe||"
    "marker|Marker|Markdown editor|||marker|com.github.fabiocolacio.marker||"
    # Presentations
    "impressive|Impressive|PDF presenter|impressive|impressive|impressive|||"
    "pdfpc|PDF Presenter|Presentation tool|pdfpc|pdfpc|pdfpc|||"
    # Finance
    "gnucash|GnuCash|Accounting|gnucash|gnucash|gnucash|org.gnucash.GnuCash||"
    "homebank|HomeBank|Personal finance|homebank|homebank|homebank|fr.free.Homebank||"
    "kmymoney|KMyMoney|Finance manager|kmymoney|kmymoney|kmymoney|org.kde.kmymoney||"
    # Calculators
    "gnome-calculator|GNOME Calculator|Calculator|gnome-calculator|gnome-calculator|gnome-calculator|org.gnome.Calculator||"
    "kcalc|KCalc|KDE calculator|kcalc|kcalc|kcalc|org.kde.kcalc||"
    "qalculate|Qalculate|Scientific calculator|qalculate-gtk|qalculate-qt|qalculate-qt|io.github.Qalculate.qalculate-qt||"
    "speedcrunch|SpeedCrunch|Fast calculator|speedcrunch|speedcrunch|speedcrunch|org.speedcrunch.SpeedCrunch||"
    # Scanning & OCR
    "simple-scan|Simple Scan|Scanner|simple-scan|simple-scan|simple-scan|org.gnome.SimpleScan||"
    "skanlite|Skanlite|KDE scanner|skanlite|skanlite|skanlite|org.kde.skanlite||"
    "gscan2pdf|gscan2pdf|OCR scanning|gscan2pdf|gscan2pdf|gscan2pdf|||"
    "ocrmypdf|OCRmyPDF|PDF OCR|ocrmypdf|ocrmypdf|ocrmypdf|||"
    "paperwork|Paperwork|Document manager|||paperwork|work.openpaper.Paperwork||"
)

#-------------------------------------------------------------------------------
# Special Setup Functions (for apps needing repos)
#-------------------------------------------------------------------------------

setup_chrome() {
    case "$DISTRO_TYPE" in
        debian)
            echo -e "  ${YELLOW}Adding Google Chrome repository...${NC}"
            wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
            sudo apt update
            sudo apt install -y google-chrome-stable
            ;;
        redhat)
            echo -e "  ${YELLOW}Adding Google Chrome repository...${NC}"
            sudo dnf install -y fedora-workstation-repositories
            sudo dnf config-manager --set-enabled google-chrome
            sudo dnf install -y google-chrome-stable
            ;;
        arch)
            echo -e "  ${YELLOW}Installing from AUR (requires yay)...${NC}"
            if cmd_exists yay; then
                yay -S --noconfirm google-chrome
            else
                print_error "yay not found. Install yay first or use Flatpak."
                return 1
            fi
            ;;
    esac
}

setup_brave() {
    case "$DISTRO_TYPE" in
        debian)
            echo -e "  ${YELLOW}Adding Brave repository...${NC}"
            sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null
            sudo apt update
            sudo apt install -y brave-browser
            ;;
        redhat)
            echo -e "  ${YELLOW}Adding Brave repository...${NC}"
            sudo dnf install -y dnf-plugins-core
            sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
            sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
            sudo dnf install -y brave-browser
            ;;
        arch)
            if cmd_exists yay; then
                yay -S --noconfirm brave-bin
            else
                print_error "yay not found. Install yay first or use Flatpak."
                return 1
            fi
            ;;
    esac
}

setup_edge() {
    case "$DISTRO_TYPE" in
        debian)
            echo -e "  ${YELLOW}Adding Microsoft Edge repository...${NC}"
            curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
            sudo install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/
            sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list'
            rm microsoft.gpg
            sudo apt update
            sudo apt install -y microsoft-edge-stable
            ;;
        redhat)
            echo -e "  ${YELLOW}Adding Microsoft Edge repository...${NC}"
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
            sudo dnf install -y microsoft-edge-stable
            ;;
        arch)
            if cmd_exists yay; then
                yay -S --noconfirm microsoft-edge-stable-bin
            else
                print_error "yay not found. Install yay first or use Flatpak."
                return 1
            fi
            ;;
    esac
}

setup_vivaldi() {
    case "$DISTRO_TYPE" in
        debian)
            echo -e "  ${YELLOW}Adding Vivaldi repository...${NC}"
            wget -qO- https://repo.vivaldi.com/archive/linux_signing_key.pub | gpg --dearmor | sudo dd of=/usr/share/keyrings/vivaldi-browser.gpg
            echo "deb [signed-by=/usr/share/keyrings/vivaldi-browser.gpg] https://repo.vivaldi.com/archive/deb/ stable main" | sudo tee /etc/apt/sources.list.d/vivaldi-archive.list > /dev/null
            sudo apt update
            sudo apt install -y vivaldi-stable
            ;;
        redhat)
            echo -e "  ${YELLOW}Adding Vivaldi repository...${NC}"
            sudo dnf config-manager --add-repo https://repo.vivaldi.com/archive/vivaldi-fedora.repo
            sudo dnf install -y vivaldi-stable
            ;;
        arch)
            if cmd_exists yay; then
                yay -S --noconfirm vivaldi
            else
                sudo pacman -S --noconfirm vivaldi
            fi
            ;;
    esac
}

setup_vscode() {
    case "$DISTRO_TYPE" in
        debian)
            echo -e "  ${YELLOW}Adding VS Code repository...${NC}"
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            sudo install -D -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/packages.microsoft.gpg
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
            rm packages.microsoft.gpg
            sudo apt update
            sudo apt install -y code
            ;;
        redhat)
            echo -e "  ${YELLOW}Adding VS Code repository...${NC}"
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
            sudo dnf install -y code
            ;;
        arch)
            if cmd_exists yay; then
                yay -S --noconfirm visual-studio-code-bin
            else
                print_error "yay not found. Install yay first or use Flatpak."
                return 1
            fi
            ;;
    esac
}

setup_sublime() {
    case "$DISTRO_TYPE" in
        debian)
            echo -e "  ${YELLOW}Adding Sublime Text repository...${NC}"
            wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/sublimehq-archive.gpg > /dev/null
            echo "deb [signed-by=/usr/share/keyrings/sublimehq-archive.gpg] https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list > /dev/null
            sudo apt update
            sudo apt install -y sublime-text
            ;;
        redhat)
            echo -e "  ${YELLOW}Adding Sublime Text repository...${NC}"
            sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
            sudo dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
            sudo dnf install -y sublime-text
            ;;
        arch)
            if cmd_exists yay; then
                yay -S --noconfirm sublime-text-4
            else
                print_error "yay not found. Install yay first or use Flatpak."
                return 1
            fi
            ;;
    esac
}

setup_docker() {
    case "$DISTRO_TYPE" in
        debian)
            echo -e "  ${YELLOW}Setting up Docker...${NC}"
            sudo apt install -y docker.io docker-compose
            sudo usermod -aG docker "$USER"
            ;;
        redhat)
            echo -e "  ${YELLOW}Setting up Docker...${NC}"
            sudo dnf install -y docker docker-compose
            sudo systemctl enable --now docker
            sudo usermod -aG docker "$USER"
            ;;
        arch)
            echo -e "  ${YELLOW}Setting up Docker...${NC}"
            sudo pacman -S --noconfirm docker docker-compose
            sudo systemctl enable --now docker
            sudo usermod -aG docker "$USER"
            ;;
    esac
    echo -e "  ${GREEN}Note: Log out and back in for Docker group changes${NC}"
}

setup_nodejs() {
    case "$DISTRO_TYPE" in
        debian)
            echo -e "  ${YELLOW}Installing Node.js LTS...${NC}"
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt install -y nodejs
            ;;
        redhat)
            echo -e "  ${YELLOW}Installing Node.js LTS...${NC}"
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
            sudo dnf install -y nodejs
            ;;
        arch)
            sudo pacman -S --noconfirm nodejs npm
            ;;
    esac
}

setup_buildtools() {
    case "$DISTRO_TYPE" in
        debian)
            sudo apt install -y build-essential
            ;;
        redhat)
            sudo dnf groupinstall -y "Development Tools"
            ;;
        arch)
            sudo pacman -S --noconfirm base-devel
            ;;
    esac
}

setup_gh_cli() {
    case "$DISTRO_TYPE" in
        debian)
            echo -e "  ${YELLOW}Adding GitHub CLI repository...${NC}"
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update
            sudo apt install -y gh
            ;;
        redhat)
            sudo dnf install -y gh
            ;;
        arch)
            sudo pacman -S --noconfirm github-cli
            ;;
    esac
}

#-------------------------------------------------------------------------------
# Installation Functions
#-------------------------------------------------------------------------------

install_via_apt() {
    local pkg="$1"
    echo -e "  ${CYAN}Installing via APT: $pkg${NC}"
    sudo apt install -y "$pkg"
}

install_via_dnf() {
    local pkg="$1"
    echo -e "  ${CYAN}Installing via DNF: $pkg${NC}"
    sudo dnf install -y "$pkg"
}

install_via_pacman() {
    local pkg="$1"
    echo -e "  ${CYAN}Installing via Pacman: $pkg${NC}"
    # Check if it's an AUR package (contains -bin, -git, etc. or not in official repos)
    if pacman -Si "$pkg" &>/dev/null; then
        sudo pacman -S --noconfirm "$pkg"
    elif cmd_exists yay; then
        echo -e "  ${YELLOW}Package not in official repos, trying AUR...${NC}"
        yay -S --noconfirm "$pkg"
    else
        print_error "Package not found and yay (AUR helper) not installed"
        return 1
    fi
}

install_via_flatpak() {
    local app_id="$1"
    echo -e "  ${CYAN}Installing via Flatpak: $app_id${NC}"
    flatpak install -y flathub "$app_id"
}

install_via_snap() {
    local pkg="$1"
    echo -e "  ${CYAN}Installing via Snap: $pkg${NC}"
    sudo snap install "$pkg"
}

install_app() {
    local entry="$1"
    local source="$2"
    
    IFS='|' read -r id name desc apt_pkg dnf_pkg pacman_pkg flatpak_id snap_pkg setup_func <<< "$entry"
    
    echo -e "\n${WHITE}Installing: $name${NC} via ${CYAN}$source${NC}"
    echo -e "${DIM}$desc${NC}"
    
    case "$source" in
        apt)
            if [[ -n "$setup_func" ]] && declare -f "$setup_func" > /dev/null; then
                $setup_func
            elif [[ -n "$apt_pkg" ]]; then
                install_via_apt "$apt_pkg"
            else
                print_error "No APT package available"
                return 1
            fi
            ;;
        dnf)
            if [[ -n "$setup_func" ]] && declare -f "$setup_func" > /dev/null; then
                $setup_func
            elif [[ -n "$dnf_pkg" ]]; then
                install_via_dnf "$dnf_pkg"
            else
                print_error "No DNF package available"
                return 1
            fi
            ;;
        pacman)
            if [[ -n "$setup_func" ]] && declare -f "$setup_func" > /dev/null; then
                $setup_func
            elif [[ -n "$pacman_pkg" ]]; then
                install_via_pacman "$pacman_pkg"
            else
                print_error "No Pacman package available"
                return 1
            fi
            ;;
        flatpak)
            if [[ -n "$flatpak_id" ]]; then
                install_via_flatpak "$flatpak_id"
            else
                print_error "No Flatpak package available"
                return 1
            fi
            ;;
        snap)
            if [[ -n "$snap_pkg" ]]; then
                install_via_snap "$snap_pkg"
            else
                print_error "No Snap package available"
                return 1
            fi
            ;;
    esac
}

#-------------------------------------------------------------------------------
# Display Functions
#-------------------------------------------------------------------------------

get_install_status() {
    local entry="$1"
    IFS='|' read -r id name desc apt_pkg dnf_pkg pacman_pkg flatpak_id snap_pkg setup_func <<< "$entry"
    
    # Check native package manager first
    case "$DISTRO_TYPE" in
        debian)
            [[ -n "$apt_pkg" ]] && is_installed_apt "$apt_pkg" && { echo -e "${GREEN}[apt]${NC}"; return; }
            ;;
        redhat)
            [[ -n "$dnf_pkg" ]] && is_installed_dnf "$dnf_pkg" && { echo -e "${GREEN}[dnf]${NC}"; return; }
            ;;
        arch)
            [[ -n "$pacman_pkg" ]] && is_installed_pacman "$pacman_pkg" && { echo -e "${GREEN}[pacman]${NC}"; return; }
            ;;
    esac
    
    # Check flatpak/snap
    [[ -n "$flatpak_id" ]] && is_installed_flatpak "$flatpak_id" && { echo -e "${GREEN}[flatpak]${NC}"; return; }
    [[ -n "$snap_pkg" ]] && is_installed_snap "$snap_pkg" && { echo -e "${GREEN}[snap]${NC}"; return; }
    
    echo -e "${DIM}[not installed]${NC}"
}

get_available_sources() {
    local entry="$1"
    IFS='|' read -r id name desc apt_pkg dnf_pkg pacman_pkg flatpak_id snap_pkg setup_func <<< "$entry"
    
    local sources=""
    
    case "$DISTRO_TYPE" in
        debian)
            if [[ -n "$apt_pkg" || -n "$setup_func" ]] && $HAS_APT; then
                sources+="apt "
            fi
            ;;
        redhat)
            if [[ -n "$dnf_pkg" || -n "$setup_func" ]] && $HAS_DNF; then
                sources+="dnf "
            fi
            ;;
        arch)
            if [[ -n "$pacman_pkg" || -n "$setup_func" ]] && $HAS_PACMAN; then
                sources+="pacman "
            fi
            ;;
    esac
    
    [[ -n "$flatpak_id" ]] && $HAS_FLATPAK && sources+="flatpak "
    [[ -n "$snap_pkg" ]] && $HAS_SNAP && sources+="snap "
    
    echo "$sources"
}

get_source_indicator() {
    local entry="$1"
    local sources=$(get_available_sources "$entry")
    local result=""
    
    for src in $sources; do
        case "$src" in
            apt) result+="${GREEN}apt${NC} " ;;
            dnf) result+="${RED}dnf${NC} " ;;
            pacman) result+="${BLUE}pacman${NC} " ;;
            flatpak) result+="${MAGENTA}flatpak${NC} " ;;
            snap) result+="${YELLOW}snap${NC} " ;;
        esac
    done
    
    echo -e "$result"
}

show_source_selector() {
    local entry="$1"
    local sources=$(get_available_sources "$entry")
    
    IFS='|' read -r id name desc rest <<< "$entry"
    
    # Print menu to /dev/tty so it displays even when function output is captured
    {
        echo ""
        echo -e "  ${WHITE}Select installation source for: ${CYAN}$name${NC}"
        echo -e "  ${DIM}────────────────────────────────────────${NC}"
    } > /dev/tty
    
    local i=1
    local source_array=()
    for src in $sources; do
        source_array+=("$src")
        case "$src" in
            apt) echo -e "  ${WHITE}$i.${NC} ${GREEN}APT${NC} (Debian native)" ;;
            dnf) echo -e "  ${WHITE}$i.${NC} ${RED}DNF${NC} (Red Hat native)" ;;
            pacman) echo -e "  ${WHITE}$i.${NC} ${BLUE}Pacman${NC} (Arch native)" ;;
            flatpak) echo -e "  ${WHITE}$i.${NC} ${MAGENTA}Flatpak${NC} (sandboxed)" ;;
            snap) echo -e "  ${WHITE}$i.${NC} ${YELLOW}Snap${NC} (Canonical)" ;;
        esac > /dev/tty
        ((i++))
    done
    
    {
        echo -e "  ${WHITE}0.${NC} Cancel"
        echo ""
        echo -ne "  ${WHITE}Choose [0-$((i-1))]: ${NC}"
    } > /dev/tty
    
    read -r choice < /dev/tty
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -lt $i ]]; then
        echo "${source_array[$((choice-1))]}"
    else
        echo ""
    fi
}

show_category_menu() {
    local array_name=$1
    local category_name="$2"
    local -n _apps_ref=$array_name
    
    clear_screen
    print_header "$category_name"
    
    local native_pm=$(get_native_pm)
    echo ""
    echo -e "  ${WHITE}Distro:${NC} $DISTRO_NAME ${DIM}($DISTRO_TYPE)${NC}  ${WHITE}Native:${NC} ${GREEN}$native_pm${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────${NC}"
    
    local i=1
    for entry in "${_apps_ref[@]}"; do
        IFS='|' read -r id name desc apt_pkg dnf_pkg pacman_pkg flatpak_id snap_pkg setup_func <<< "$entry"
        
        local status=$(get_install_status "$entry")
        local sources=$(get_source_indicator "$entry")
        local selected_marker=""
        local selected_source=""
        
        if [[ -n "${SELECTED_APPS[$id]}" ]]; then
            selected_source="${SELECTED_APPS[$id]}"
            selected_marker="${GREEN}* [$selected_source]${NC}"
        fi
        
        printf "  ${WHITE}%2d.${NC} %-20s %b %b\n" "$i" "$name" "$status" "$selected_marker"
        printf "      ${DIM}%-40s${NC} %b\n" "$desc" "$sources"
        ((i++))
    done
    
    echo ""
    echo -e "  ${CYAN}────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${WHITE}[1-$((i-1))]${NC} Select app & source  ${WHITE}[A]${NC} Select all (native)  ${WHITE}[N]${NC} Deselect all"
    echo -e "  ${WHITE}[I]${NC} Install selected      ${WHITE}[M]${NC} Main menu            ${WHITE}[Q]${NC} Quit"
    echo -e "  ${CYAN}────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
}

handle_category_selection() {
    local array_name=$1
    local category_name="$2"
    local -n _cat_apps=$array_name
    
    while true; do
        show_category_menu "$array_name" "$category_name"
        
        echo -ne "  ${WHITE}Enter choice: ${NC}"
        read -r choice
        
        case $choice in
            [qQ])
                clear_screen
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            [mM])
                return
                ;;
            [aA])
                # Select all in category with native package manager
                local native_pm=$(get_native_pm)
                for entry in "${_cat_apps[@]}"; do
                    IFS='|' read -r id name desc apt_pkg dnf_pkg pacman_pkg flatpak_id snap_pkg setup_func <<< "$entry"
                    local sources=$(get_available_sources "$entry")
                    
                    # Prefer native, then flatpak, then snap
                    if [[ "$sources" == *"$native_pm"* ]]; then
                        SELECTED_APPS[$id]="$native_pm"
                    elif [[ "$sources" == *"flatpak"* ]]; then
                        SELECTED_APPS[$id]="flatpak"
                    elif [[ "$sources" == *"snap"* ]]; then
                        SELECTED_APPS[$id]="snap"
                    fi
                done
                ;;
            [nN])
                # Deselect all in category
                for entry in "${_cat_apps[@]}"; do
                    IFS='|' read -r id rest <<< "$entry"
                    unset SELECTED_APPS[$id]
                done
                ;;
            [iI])
                # Install selected apps from this category
                install_selected_from_category "$array_name"
                press_any_key
                ;;
            *)
                # Check if number selection
                if [[ "$choice" =~ ^[0-9]+$ ]]; then
                    local idx=$((choice - 1))
                    if [[ $idx -ge 0 && $idx -lt ${#_cat_apps[@]} ]]; then
                        local entry="${_cat_apps[$idx]}"
                        IFS='|' read -r id rest <<< "$entry"
                        
                        # Show source selector
                        local selected_source=$(show_source_selector "$entry")
                        
                        if [[ -n "$selected_source" ]]; then
                            SELECTED_APPS[$id]="$selected_source"
                        else
                            unset SELECTED_APPS[$id]
                        fi
                    fi
                fi
                ;;
        esac
    done
}

install_selected_from_category() {
    local array_name=$1
    local -n _inst_apps=$array_name
    local count=0
    
    # Count selected
    for entry in "${_inst_apps[@]}"; do
        IFS='|' read -r id rest <<< "$entry"
        [[ -n "${SELECTED_APPS[$id]}" ]] && ((count++))
    done
    
    if [[ $count -eq 0 ]]; then
        echo -e "\n  ${YELLOW}No apps selected for installation${NC}"
        return
    fi
    
    echo ""
    print_section "Installing $count Selected Application(s)"
    
    # Update package manager cache
    case "$DISTRO_TYPE" in
        debian)
            echo -e "  ${CYAN}Updating package lists...${NC}"
            sudo apt update
            ;;
        redhat)
            echo -e "  ${CYAN}Updating package lists...${NC}"
            sudo dnf check-update || true
            ;;
        arch)
            echo -e "  ${CYAN}Updating package lists...${NC}"
            sudo pacman -Sy
            ;;
    esac
    
    # Install each selected app
    for entry in "${_inst_apps[@]}"; do
        IFS='|' read -r id rest <<< "$entry"
        if [[ -n "${SELECTED_APPS[$id]}" ]]; then
            local source="${SELECTED_APPS[$id]}"
            install_app "$entry" "$source"
            unset SELECTED_APPS[$id]  # Deselect after install
        fi
    done
    
    echo ""
    print_success "Installation complete!"
}

install_all_selected() {
    local count=0
    
    # Count all selected
    for id in "${!SELECTED_APPS[@]}"; do
        [[ -n "${SELECTED_APPS[$id]}" ]] && ((count++))
    done
    
    if [[ $count -eq 0 ]]; then
        echo -e "\n  ${YELLOW}No apps selected for installation${NC}"
        press_any_key
        return
    fi
    
    clear_screen
    print_header "Installing $count Selected Application(s)"
    
    # Update package manager cache
    case "$DISTRO_TYPE" in
        debian)
            echo -e "  ${CYAN}Updating package lists...${NC}"
            sudo apt update
            ;;
        redhat)
            echo -e "  ${CYAN}Updating package lists...${NC}"
            sudo dnf check-update || true
            ;;
        arch)
            echo -e "  ${CYAN}Updating package lists...${NC}"
            sudo pacman -Sy
            ;;
    esac
    
    # Function to find and install by ID
    install_by_id() {
        local target_id="$1"
        local source="$2"
        local all_apps=("${BROWSERS[@]}" "${EDITORS[@]}" "${MEDIA[@]}" "${COMMUNICATION[@]}" "${UTILITIES[@]}" "${DEVELOPMENT[@]}" "${GAMING[@]}" "${OFFICE[@]}")
        
        for entry in "${all_apps[@]}"; do
            IFS='|' read -r id rest <<< "$entry"
            if [[ "$id" == "$target_id" ]]; then
                install_app "$entry" "$source"
                return
            fi
        done
    }
    
    # Install all selected
    for id in "${!SELECTED_APPS[@]}"; do
        if [[ -n "${SELECTED_APPS[$id]}" ]]; then
            local source="${SELECTED_APPS[$id]}"
            install_by_id "$id" "$source"
            unset SELECTED_APPS[$id]
        fi
    done
    
    echo ""
    print_success "All installations complete!"
    press_any_key
}

show_selected_summary() {
    local count=0
    local selected_names=""
    
    local all_apps=("${BROWSERS[@]}" "${EDITORS[@]}" "${MEDIA[@]}" "${COMMUNICATION[@]}" "${UTILITIES[@]}" "${DEVELOPMENT[@]}" "${GAMING[@]}" "${OFFICE[@]}")
    
    for entry in "${all_apps[@]}"; do
        IFS='|' read -r id name rest <<< "$entry"
        if [[ -n "${SELECTED_APPS[$id]}" ]]; then
            ((count++))
            selected_names+="$name(${SELECTED_APPS[$id]}), "
        fi
    done
    
    if [[ $count -gt 0 ]]; then
        selected_names="${selected_names%, }"  # Remove trailing comma
        echo -e "  ${GREEN}Selected ($count):${NC} ${selected_names}"
    else
        echo -e "  ${DIM}No apps selected${NC}"
    fi
}

setup_flatpak() {
    if ! $HAS_FLATPAK; then
        echo -e "\n  ${YELLOW}Flatpak is not installed. Would you like to install it? [y/N]${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            case "$DISTRO_TYPE" in
                debian) sudo apt install -y flatpak ;;
                redhat) sudo dnf install -y flatpak ;;
                arch) sudo pacman -S --noconfirm flatpak ;;
            esac
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
            HAS_FLATPAK=true
            print_success "Flatpak installed! Restart may be required for full functionality."
        fi
    else
        # Ensure flathub is added
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null
        print_info "Flatpak is already installed"
    fi
}

setup_snap() {
    if ! $HAS_SNAP; then
        echo -e "\n  ${YELLOW}Snap is not installed. Would you like to install it? [y/N]${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            case "$DISTRO_TYPE" in
                debian) sudo apt install -y snapd ;;
                redhat) sudo dnf install -y snapd; sudo systemctl enable --now snapd.socket ;;
                arch) 
                    if cmd_exists yay; then
                        yay -S --noconfirm snapd
                    else
                        print_error "Install yay first to install snap from AUR"
                        return
                    fi
                    sudo systemctl enable --now snapd.socket
                    ;;
            esac
            HAS_SNAP=true
            print_success "Snap installed! Restart may be required."
        fi
    else
        print_info "Snap is already installed"
    fi
}

#-------------------------------------------------------------------------------
# Store Search Functions
#-------------------------------------------------------------------------------

search_flatpak_store() {
    if ! $HAS_FLATPAK; then
        echo -e "\n  ${RED}Flatpak is not installed. Install it first with option F.${NC}"
        press_any_key
        return
    fi
    
    clear_screen
    print_header "SEARCH FLATHUB"
    
    echo ""
    echo -ne "  ${WHITE}Enter search term (or 'q' to cancel): ${NC}"
    read -r search_term
    
    [[ "$search_term" == "q" || -z "$search_term" ]] && return
    
    echo ""
    echo -e "  ${CYAN}Searching Flathub for '$search_term'...${NC}"
    echo ""
    
    # Get search results
    local results
    results=$(flatpak search "$search_term" 2>/dev/null)
    
    if [[ -z "$results" ]]; then
        echo -e "  ${YELLOW}No results found for '$search_term'${NC}"
        press_any_key
        return
    fi
    
    # Parse and display results
    echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────${NC}"
    printf "  ${WHITE}%-4s %-30s %-40s${NC}\n" "No." "Name" "Application ID"
    echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────${NC}"
    
    local -a app_ids=()
    local -a app_names=()
    local count=0
    
    while IFS=$'\t' read -r name description app_id version branch remotes; do
        ((count++))
        app_ids+=("$app_id")
        app_names+=("$name")
        printf "  ${GREEN}%-4s${NC} %-30s ${DIM}%-40s${NC}\n" "$count." "${name:0:30}" "${app_id:0:40}"
        
        # Limit to 20 results
        [[ $count -ge 20 ]] && break
    done <<< "$results"
    
    echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${WHITE}[1-$count]${NC} Install app  ${WHITE}[Enter]${NC} Cancel"
    echo ""
    echo -ne "  ${WHITE}Select app to install: ${NC}"
    read -r choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $count ]]; then
        local idx=$((choice - 1))
        local selected_id="${app_ids[$idx]}"
        local selected_name="${app_names[$idx]}"
        
        echo ""
        echo -e "  ${CYAN}Installing ${WHITE}$selected_name${CYAN} ($selected_id)...${NC}"
        echo ""
        flatpak install -y flathub "$selected_id"
        
        if [[ $? -eq 0 ]]; then
            print_success "$selected_name installed successfully!"
        else
            print_error "Installation failed"
        fi
    fi
    
    press_any_key
}

search_snap_store() {
    if ! $HAS_SNAP; then
        echo -e "\n  ${RED}Snap is not installed. Install it first with option S.${NC}"
        press_any_key
        return
    fi
    
    clear_screen
    print_header "SEARCH SNAP STORE"
    
    echo ""
    echo -ne "  ${WHITE}Enter search term (or 'q' to cancel): ${NC}"
    read -r search_term
    
    [[ "$search_term" == "q" || -z "$search_term" ]] && return
    
    echo ""
    echo -e "  ${CYAN}Searching Snap Store for '$search_term'...${NC}"
    echo ""
    
    # Get search results
    local results
    results=$(snap find "$search_term" 2>/dev/null | tail -n +2)  # Skip header line
    
    if [[ -z "$results" ]]; then
        echo -e "  ${YELLOW}No results found for '$search_term'${NC}"
        press_any_key
        return
    fi
    
    # Parse and display results
    echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────${NC}"
    printf "  ${WHITE}%-4s %-25s %-15s %-30s${NC}\n" "No." "Name" "Version" "Publisher"
    echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────${NC}"
    
    local -a snap_names=()
    local count=0
    
    while read -r name version publisher notes summary; do
        ((count++))
        snap_names+=("$name")
        printf "  ${GREEN}%-4s${NC} %-25s ${DIM}%-15s %-30s${NC}\n" "$count." "${name:0:25}" "${version:0:15}" "${publisher:0:30}"
        
        # Limit to 20 results
        [[ $count -ge 20 ]] && break
    done <<< "$results"
    
    echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${WHITE}[1-$count]${NC} Install app  ${WHITE}[Enter]${NC} Cancel"
    echo ""
    echo -ne "  ${WHITE}Select app to install: ${NC}"
    read -r choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $count ]]; then
        local idx=$((choice - 1))
        local selected_name="${snap_names[$idx]}"
        
        echo ""
        echo -e "  ${CYAN}Installing ${WHITE}$selected_name${CYAN}...${NC}"
        echo ""
        sudo snap install "$selected_name"
        
        if [[ $? -eq 0 ]]; then
            print_success "$selected_name installed successfully!"
        else
            print_error "Installation failed"
        fi
    fi
    
    press_any_key
}

browse_stores_menu() {
    while true; do
        clear_screen
        print_header "BROWSE APP STORES"
        
        echo ""
        echo -e "  ${WHITE}Search and install apps directly from online stores${NC}"
        echo ""
        echo -e "  ${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
        
        if $HAS_FLATPAK; then
            echo -e "  ${CYAN}│${NC}  ${WHITE} 1.${NC} ${MAGENTA}Search Flathub${NC}        Browse & install Flatpak apps              ${CYAN}│${NC}"
        else
            echo -e "  ${CYAN}│${NC}  ${WHITE} 1.${NC} ${DIM}Search Flathub${NC}        ${RED}(Flatpak not installed)${NC}                 ${CYAN}│${NC}"
        fi
        
        if $HAS_SNAP; then
            echo -e "  ${CYAN}│${NC}  ${WHITE} 2.${NC} ${YELLOW}Search Snap Store${NC}     Browse & install Snap apps                 ${CYAN}│${NC}"
        else
            echo -e "  ${CYAN}│${NC}  ${WHITE} 2.${NC} ${DIM}Search Snap Store${NC}     ${RED}(Snap not installed)${NC}                    ${CYAN}│${NC}"
        fi
        
        echo -e "  ${CYAN}├─────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} M.${NC} ${GREEN}Main Menu${NC}                                                         ${CYAN}│${NC}"
        echo -e "  ${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -ne "  ${WHITE}Enter choice: ${NC}"
        
        read -r choice
        
        case $choice in
            1) search_flatpak_store ;;
            2) search_snap_store ;;
            m|M) return ;;
            q|Q) clear_screen; echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
            *) ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Uninstaller Functions
#-------------------------------------------------------------------------------

uninstall_native_apps() {
    local search_term=""
    local page=1
    local per_page=20
    local -a all_packages=()
    local -a pkg_names=()
    local -a pkg_sizes=()
    local -a pkg_descs=()
    local total_packages=0
    local total_pages=0
    
    # Initial search prompt
    clear_screen
    print_header "UNINSTALL NATIVE PACKAGES"
    
    echo ""
    echo -ne "  ${WHITE}Search for package (or Enter to list all): ${NC}"
    read -r search_term
    
    echo ""
    echo -e "  ${CYAN}Loading installed packages... (this may take a moment)${NC}"
    
    # Load all packages into arrays
    local packages=""
    
    case "$DISTRO_TYPE" in
        debian)
            if [[ -z "$search_term" ]]; then
                packages=$(dpkg-query -W -f='${Package}\t${Installed-Size}\t${binary:Summary}\n' 2>/dev/null | sort -t$'\t' -k2 -rn)
            else
                packages=$(dpkg-query -W -f='${Package}\t${Installed-Size}\t${binary:Summary}\n' 2>/dev/null | grep -i "$search_term" | sort -t$'\t' -k2 -rn)
            fi
            ;;
        redhat)
            if [[ -z "$search_term" ]]; then
                packages=$(rpm -qa --queryformat '%{NAME}\t%{SIZE}\t%{SUMMARY}\n' 2>/dev/null | sort -t$'\t' -k2 -rn)
            else
                packages=$(rpm -qa --queryformat '%{NAME}\t%{SIZE}\t%{SUMMARY}\n' 2>/dev/null | grep -i "$search_term" | sort -t$'\t' -k2 -rn)
            fi
            ;;
        arch)
            if [[ -z "$search_term" ]]; then
                packages=$(pacman -Qi 2>/dev/null | awk '/^Name/{name=$3} /^Installed Size/{size=$4$5} /^Description/{desc=$0; sub(/Description *: */,"",desc); print name"\t"size"\t"desc}' | sort -t$'\t' -k2 -rh)
            else
                packages=$(pacman -Qi 2>/dev/null | awk '/^Name/{name=$3} /^Installed Size/{size=$4$5} /^Description/{desc=$0; sub(/Description *: */,"",desc); print name"\t"size"\t"desc}' | grep -i "$search_term" | sort -t$'\t' -k2 -rh)
            fi
            ;;
    esac
    
    if [[ -z "$packages" ]]; then
        echo -e "  ${YELLOW}No packages found${NC}"
        press_any_key
        return
    fi
    
    # Parse packages into arrays
    while IFS=$'\t' read -r name size desc; do
        [[ -z "$name" ]] && continue
        pkg_names+=("$name")
        pkg_sizes+=("$size")
        pkg_descs+=("$desc")
    done <<< "$packages"
    
    total_packages=${#pkg_names[@]}
    total_pages=$(( (total_packages + per_page - 1) / per_page ))
    
    # Pagination loop
    while true; do
        clear_screen
        print_header "INSTALLED NATIVE PACKAGES"
        
        local start_idx=$(( (page - 1) * per_page ))
        local end_idx=$(( start_idx + per_page ))
        [[ $end_idx -gt $total_packages ]] && end_idx=$total_packages
        
        echo ""
        if [[ -n "$search_term" ]]; then
            echo -e "  ${WHITE}Search:${NC} '$search_term'  ${WHITE}Total:${NC} $total_packages packages  ${WHITE}Page:${NC} $page/$total_pages"
        else
            echo -e "  ${WHITE}All packages${NC}  ${WHITE}Total:${NC} $total_packages packages  ${WHITE}Page:${NC} $page/$total_pages"
        fi
        echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────${NC}"
        printf "  ${WHITE}%-5s %-30s %-12s %-28s${NC}\n" "No." "Package" "Size" "Description"
        echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────${NC}"
        
        for ((i = start_idx; i < end_idx; i++)); do
            local name="${pkg_names[$i]}"
            local size="${pkg_sizes[$i]}"
            local desc="${pkg_descs[$i]}"
            local display_num=$((i + 1))
            
            # Format size
            local size_fmt="$size"
            if [[ "$size" =~ ^[0-9]+$ ]]; then
                if [[ $size -gt 1048576 ]]; then
                    size_fmt="$((size / 1048576)) MB"
                elif [[ $size -gt 1024 ]]; then
                    size_fmt="$((size / 1024)) KB"
                else
                    size_fmt="$size B"
                fi
            fi
            
            printf "  ${GREEN}%-5s${NC} %-30s ${YELLOW}%-12s${NC} ${DIM}%-28s${NC}\n" "$display_num." "${name:0:30}" "${size_fmt:0:12}" "${desc:0:28}"
        done
        
        echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────${NC}"
        echo ""
        echo -e "  ${WHITE}[N]${NC} Next page  ${WHITE}[P]${NC} Previous page  ${WHITE}[G]${NC} Go to page  ${WHITE}[S]${NC} New search"
        echo -e "  ${WHITE}[number]${NC} Uninstall package  ${WHITE}[M]${NC} Back to menu"
        echo ""
        echo -ne "  ${WHITE}Enter choice: ${NC}"
        read -r choice
        
        case $choice in
            n|N)
                [[ $page -lt $total_pages ]] && ((page++))
                ;;
            p|P)
                [[ $page -gt 1 ]] && ((page--))
                ;;
            g|G)
                echo -ne "  ${WHITE}Go to page (1-$total_pages): ${NC}"
                read -r goto_page
                if [[ "$goto_page" =~ ^[0-9]+$ ]] && [[ $goto_page -ge 1 ]] && [[ $goto_page -le $total_pages ]]; then
                    page=$goto_page
                fi
                ;;
            s|S)
                uninstall_native_apps
                return
                ;;
            m|M)
                return
                ;;
            *)
                # Check if number selection for uninstall
                if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $total_packages ]]; then
                    local idx=$((choice - 1))
                    local pkg="${pkg_names[$idx]}"
                    
                    echo ""
                    echo -e "  ${YELLOW}Are you sure you want to uninstall ${WHITE}$pkg${YELLOW}? [y/N]${NC}"
                    read -r confirm
                    
                    if [[ "$confirm" =~ ^[Yy]$ ]]; then
                        echo ""
                        case "$DISTRO_TYPE" in
                            debian) sudo apt remove -y "$pkg" ;;
                            redhat) sudo dnf remove -y "$pkg" ;;
                            arch) sudo pacman -R --noconfirm "$pkg" ;;
                        esac
                        
                        if [[ $? -eq 0 ]]; then
                            print_success "$pkg uninstalled successfully!"
                            
                            # Offer to purge config files
                            echo ""
                            echo -e "  ${YELLOW}Remove configuration files too (purge)? [y/N]${NC}"
                            read -r purge_confirm
                            if [[ "$purge_confirm" =~ ^[Yy]$ ]]; then
                                case "$DISTRO_TYPE" in
                                    debian) sudo apt purge -y "$pkg" 2>/dev/null ;;
                                    redhat) echo -e "  ${DIM}DNF already removes configs${NC}" ;;
                                    arch) sudo pacman -Rn --noconfirm "$pkg" 2>/dev/null ;;
                                esac
                                print_success "Configuration files removed"
                            fi
                            
                            # Offer to autoremove unused dependencies
                            echo ""
                            echo -e "  ${YELLOW}Remove unused dependencies (autoremove)? [y/N]${NC}"
                            read -r auto_confirm
                            if [[ "$auto_confirm" =~ ^[Yy]$ ]]; then
                                case "$DISTRO_TYPE" in
                                    debian) sudo apt autoremove -y ;;
                                    redhat) sudo dnf autoremove -y ;;
                                    arch) 
                                        orphans=$(pacman -Qdtq 2>/dev/null)
                                        if [[ -n "$orphans" ]]; then
                                            echo "$orphans" | sudo pacman -Rns --noconfirm -
                                        else
                                            echo -e "  ${DIM}No orphan packages found${NC}"
                                        fi
                                        ;;
                                esac
                                print_success "Unused dependencies removed"
                            fi
                            
                            # Remove from arrays
                            unset 'pkg_names[$idx]'
                            unset 'pkg_sizes[$idx]'
                            unset 'pkg_descs[$idx]'
                            # Reindex arrays
                            pkg_names=("${pkg_names[@]}")
                            pkg_sizes=("${pkg_sizes[@]}")
                            pkg_descs=("${pkg_descs[@]}")
                            total_packages=${#pkg_names[@]}
                            total_pages=$(( (total_packages + per_page - 1) / per_page ))
                            [[ $page -gt $total_pages ]] && page=$total_pages
                            [[ $page -lt 1 ]] && page=1
                        else
                            print_error "Failed to uninstall $pkg"
                        fi
                        press_any_key
                    else
                        echo -e "  ${DIM}Cancelled${NC}"
                        sleep 1
                    fi
                fi
                ;;
        esac
    done
}

uninstall_flatpak_apps() {
    if ! $HAS_FLATPAK; then
        echo -e "\n  ${RED}Flatpak is not installed${NC}"
        press_any_key
        return
    fi
    
    clear_screen
    print_header "UNINSTALL FLATPAK APPS"
    
    echo ""
    echo -e "  ${CYAN}Loading installed Flatpak apps...${NC}"
    
    local apps
    apps=$(flatpak list --app --columns=name,application,size 2>/dev/null)
    
    if [[ -z "$apps" ]]; then
        echo -e "  ${YELLOW}No Flatpak apps installed${NC}"
        press_any_key
        return
    fi
    
    echo ""
    echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────${NC}"
    printf "  ${WHITE}%-4s %-30s %-35s %-10s${NC}\n" "No." "Name" "Application ID" "Size"
    echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────${NC}"
    
    local -a app_ids=()
    local -a app_names=()
    local count=0
    
    while IFS=$'\t' read -r name app_id size; do
        [[ -z "$name" ]] && continue
        ((count++))
        app_ids+=("$app_id")
        app_names+=("$name")
        printf "  ${GREEN}%-4s${NC} %-30s ${DIM}%-35s${NC} ${YELLOW}%-10s${NC}\n" "$count." "${name:0:30}" "${app_id:0:35}" "${size:0:10}"
    done <<< "$apps"
    
    echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${WHITE}[1-$count]${NC} Uninstall app  ${WHITE}[M]${NC} Back"
    echo ""
    echo -ne "  ${WHITE}Select app to uninstall: ${NC}"
    read -r choice
    
    [[ "$choice" == "m" || "$choice" == "M" ]] && return
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $count ]]; then
        local idx=$((choice - 1))
        local app_id="${app_ids[$idx]}"
        local name="${app_names[$idx]}"
        
        echo ""
        echo -e "  ${YELLOW}Are you sure you want to uninstall ${WHITE}$name${YELLOW}? [y/N]${NC}"
        read -r confirm
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo ""
            
            # Ask about deleting app data
            echo -e "  ${YELLOW}Also delete app data? [y/N]${NC}"
            read -r delete_data
            
            if [[ "$delete_data" =~ ^[Yy]$ ]]; then
                flatpak uninstall -y --delete-data "$app_id"
            else
                flatpak uninstall -y "$app_id"
            fi
            
            if [[ $? -eq 0 ]]; then
                print_success "$name uninstalled successfully!"
                
                # Offer to remove unused runtimes
                echo ""
                echo -e "  ${YELLOW}Remove unused runtimes and extensions? [y/N]${NC}"
                read -r unused_confirm
                if [[ "$unused_confirm" =~ ^[Yy]$ ]]; then
                    flatpak uninstall -y --unused
                    print_success "Unused runtimes removed"
                fi
            else
                print_error "Failed to uninstall $name"
            fi
        else
            echo -e "  ${DIM}Cancelled${NC}"
        fi
    fi
    
    press_any_key
}

uninstall_snap_apps() {
    if ! $HAS_SNAP; then
        echo -e "\n  ${RED}Snap is not installed${NC}"
        press_any_key
        return
    fi
    
    clear_screen
    print_header "UNINSTALL SNAP APPS"
    
    echo ""
    echo -e "  ${CYAN}Loading installed Snap apps...${NC}"
    
    local apps
    apps=$(snap list 2>/dev/null | tail -n +2)
    
    if [[ -z "$apps" ]]; then
        echo -e "  ${YELLOW}No Snap apps installed${NC}"
        press_any_key
        return
    fi
    
    echo ""
    echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────${NC}"
    printf "  ${WHITE}%-4s %-25s %-15s %-15s %-15s${NC}\n" "No." "Name" "Version" "Rev" "Publisher"
    echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────${NC}"
    
    local -a snap_names=()
    local count=0
    
    while read -r name version rev tracking publisher notes; do
        [[ -z "$name" ]] && continue
        ((count++))
        snap_names+=("$name")
        printf "  ${GREEN}%-4s${NC} %-25s ${DIM}%-15s %-15s${NC} %-15s\n" "$count." "${name:0:25}" "${version:0:15}" "${rev:0:15}" "${publisher:0:15}"
    done <<< "$apps"
    
    echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${WHITE}[1-$count]${NC} Uninstall app  ${WHITE}[M]${NC} Back"
    echo ""
    echo -ne "  ${WHITE}Select app to uninstall: ${NC}"
    read -r choice
    
    [[ "$choice" == "m" || "$choice" == "M" ]] && return
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $count ]]; then
        local idx=$((choice - 1))
        local name="${snap_names[$idx]}"
        
        echo ""
        echo -e "  ${YELLOW}Are you sure you want to uninstall ${WHITE}$name${YELLOW}? [y/N]${NC}"
        read -r confirm
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo ""
            
            # Ask about purging (removes all data and revisions)
            echo -e "  ${YELLOW}Purge all data and snapshots? [y/N]${NC}"
            read -r purge_confirm
            
            if [[ "$purge_confirm" =~ ^[Yy]$ ]]; then
                sudo snap remove --purge "$name"
            else
                sudo snap remove "$name"
            fi
            
            if [[ $? -eq 0 ]]; then
                print_success "$name uninstalled successfully!"
                
                # Check for disabled/old snap revisions
                old_snaps=$(snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}')
                if [[ -n "$old_snaps" ]]; then
                    echo ""
                    echo -e "  ${YELLOW}Remove old disabled snap revisions to free space? [y/N]${NC}"
                    read -r old_confirm
                    if [[ "$old_confirm" =~ ^[Yy]$ ]]; then
                        snap list --all | awk '/disabled/{system("sudo snap remove " $1 " --revision=" $3)}'
                        print_success "Old revisions removed"
                    fi
                fi
            else
                print_error "Failed to uninstall $name"
            fi
        else
            echo -e "  ${DIM}Cancelled${NC}"
        fi
    fi
    
    press_any_key
}

system_cleanup() {
    clear_screen
    print_header "SYSTEM CLEANUP"
    
    echo ""
    echo -e "  ${WHITE}Clean up unused packages, cache, and dependencies${NC}"
    echo ""
    
    # Native package manager cleanup
    print_section "Native Package Manager Cleanup"
    case "$DISTRO_TYPE" in
        debian)
            echo -e "  ${CYAN}Removing unused dependencies...${NC}"
            sudo apt autoremove -y
            echo -e "  ${CYAN}Cleaning package cache...${NC}"
            sudo apt autoclean -y
            echo -e "  ${CYAN}Purging residual configs...${NC}"
            residual=$(dpkg -l | grep '^rc' | awk '{print $2}')
            if [[ -n "$residual" ]]; then
                echo "$residual" | xargs sudo dpkg --purge 2>/dev/null
                print_success "Residual configs purged"
            else
                echo -e "  ${DIM}No residual configs found${NC}"
            fi
            ;;
        redhat)
            echo -e "  ${CYAN}Removing unused dependencies...${NC}"
            sudo dnf autoremove -y
            echo -e "  ${CYAN}Cleaning package cache...${NC}"
            sudo dnf clean all
            ;;
        arch)
            echo -e "  ${CYAN}Removing orphan packages...${NC}"
            orphans=$(pacman -Qdtq 2>/dev/null)
            if [[ -n "$orphans" ]]; then
                echo "$orphans" | sudo pacman -Rns --noconfirm -
                print_success "Orphan packages removed"
            else
                echo -e "  ${DIM}No orphan packages found${NC}"
            fi
            echo -e "  ${CYAN}Cleaning package cache...${NC}"
            sudo pacman -Sc --noconfirm
            ;;
    esac
    print_success "Native cleanup complete"
    
    # Flatpak cleanup
    if $HAS_FLATPAK; then
        print_section "Flatpak Cleanup"
        echo -e "  ${CYAN}Removing unused runtimes and extensions...${NC}"
        flatpak uninstall -y --unused 2>/dev/null
        print_success "Flatpak cleanup complete"
    fi
    
    # Snap cleanup
    if $HAS_SNAP; then
        print_section "Snap Cleanup"
        echo -e "  ${CYAN}Removing disabled snap revisions...${NC}"
        snap list --all 2>/dev/null | awk '/disabled/{system("sudo snap remove " $1 " --revision=" $3)}' 2>/dev/null
        print_success "Snap cleanup complete"
    fi
    
    # Show space recovered summary
    print_section "Cleanup Summary"
    echo -e "  ${GREEN}✓${NC} System cleanup completed!"
    echo ""
    echo -e "  ${WHITE}Disk usage:${NC}"
    df -h / | tail -1 | awk '{print "    Used: " $3 " / " $2 " (" $5 " full)"}'
    
    press_any_key
}

uninstaller_menu() {
    while true; do
        clear_screen
        print_header "UNINSTALL APPLICATIONS"
        
        echo ""
        echo -e "  ${WHITE}Remove installed applications from your system${NC}"
        echo ""
        echo -e "  ${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
        
        local native_pm=$(get_native_pm)
        echo -e "  ${CYAN}│${NC}  ${WHITE} 1.${NC} ${GREEN}Native Packages${NC}       Uninstall $native_pm packages                     ${CYAN}│${NC}"
        
        if $HAS_FLATPAK; then
            echo -e "  ${CYAN}│${NC}  ${WHITE} 2.${NC} ${MAGENTA}Flatpak Apps${NC}          Uninstall Flatpak applications              ${CYAN}│${NC}"
        else
            echo -e "  ${CYAN}│${NC}  ${WHITE} 2.${NC} ${DIM}Flatpak Apps${NC}          ${DIM}(Flatpak not installed)${NC}                  ${CYAN}│${NC}"
        fi
        
        if $HAS_SNAP; then
            echo -e "  ${CYAN}│${NC}  ${WHITE} 3.${NC} ${YELLOW}Snap Apps${NC}             Uninstall Snap applications                 ${CYAN}│${NC}"
        else
            echo -e "  ${CYAN}│${NC}  ${WHITE} 3.${NC} ${DIM}Snap Apps${NC}             ${DIM}(Snap not installed)${NC}                     ${CYAN}│${NC}"
        fi
        
        echo -e "  ${CYAN}├─────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 4.${NC} ${RED}System Cleanup${NC}        Remove cache, orphans & unused packages     ${CYAN}│${NC}"
        echo -e "  ${CYAN}├─────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} M.${NC} ${GREEN}Main Menu${NC}                                                         ${CYAN}│${NC}"
        echo -e "  ${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -ne "  ${WHITE}Enter choice: ${NC}"
        
        read -r choice
        
        case $choice in
            1) uninstall_native_apps ;;
            2) $HAS_FLATPAK && uninstall_flatpak_apps ;;
            3) $HAS_SNAP && uninstall_snap_apps ;;
            4) system_cleanup ;;
            m|M) return ;;
            q|Q) clear_screen; echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
            *) ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Main Menu
#-------------------------------------------------------------------------------

show_main_menu() {
    while true; do
        clear_screen
        
        echo -e "${BOLD}${GREEN}"
        echo "╔════════════════════════════════════════════════════════════════════════════╗"
        echo "║                                                                            ║"
        echo "║          █████╗ ██████╗ ██████╗     ██╗  ██╗██╗   ██╗██████╗               ║"
        echo "║         ██╔══██╗██╔══██╗██╔══██╗    ██║  ██║██║   ██║██╔══██╗              ║"
        echo "║         ███████║██████╔╝██████╔╝    ███████║██║   ██║██████╔╝              ║"
        echo "║         ██╔══██║██╔═══╝ ██╔═══╝     ██╔══██║██║   ██║██╔══██╗              ║"
        echo "║         ██║  ██║██║     ██║         ██║  ██║╚██████╔╝██████╔╝              ║"
        echo "║         ╚═╝  ╚═╝╚═╝     ╚═╝         ╚═╝  ╚═╝ ╚═════╝ ╚═════╝               ║"
        echo "║                                                                            ║"
        echo "║                  YOUR CURATED APPLICATION HUB FOR LINUX                    ║"
        echo "║                   - Luka Rogovic <luka032[at]gmail.com> -                  ║"
        echo "╚════════════════════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        
        # Show distro and package manager status
        echo -e "  ${WHITE}System:${NC} $DISTRO_NAME ${DIM}($DISTRO_TYPE)${NC}"
        echo -e "  ${WHITE}Package Managers:${NC}"
        $HAS_APT && echo -e "    ${GREEN}✓${NC} APT" || echo -e "    ${DIM}○${NC} APT"
        $HAS_DNF && echo -e "    ${GREEN}✓${NC} DNF" || echo -e "    ${DIM}○${NC} DNF"
        $HAS_PACMAN && echo -e "    ${GREEN}✓${NC} Pacman" || echo -e "    ${DIM}○${NC} Pacman"
        $HAS_FLATPAK && echo -e "    ${GREEN}✓${NC} Flatpak" || echo -e "    ${YELLOW}○${NC} Flatpak ${DIM}(install with F)${NC}"
        $HAS_SNAP && echo -e "    ${GREEN}✓${NC} Snap" || echo -e "    ${YELLOW}○${NC} Snap ${DIM}(install with S)${NC}"
        
        echo ""
        show_selected_summary
        echo ""
        
        echo -e "  ${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}Select a category:${NC}                                                     ${CYAN}│${NC}"
        echo -e "  ${CYAN}├─────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 1.${NC} ${GREEN}Browsers${NC}          Firefox, Chrome, Brave, Edge, Vivaldi...         ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 2.${NC} ${GREEN}Editors & IDEs${NC}    VS Code, JetBrains, Vim, Neovim...               ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 3.${NC} ${GREEN}Media & Graphics${NC}  VLC, GIMP, OBS, Kdenlive, Blender...             ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 4.${NC} ${GREEN}Communication${NC}     Discord, Slack, Zoom, Telegram...                ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 5.${NC} ${GREEN}Utilities${NC}         Timeshift, Flameshot, VPN, Backup...             ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 6.${NC} ${GREEN}Development${NC}       Git, Docker, Node.js, Databases...               ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 7.${NC} ${GREEN}Gaming${NC}            Steam, Lutris, Emulators, Wine...                ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 8.${NC} ${GREEN}Office${NC}            LibreOffice, Obsidian, LaTeX...                  ${CYAN}│${NC}"
        echo -e "  ${CYAN}├─────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 9.${NC} ${MAGENTA}Browse Stores${NC}     Search Flathub & Snap Store                      ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 0.${NC} ${RED}Uninstall Apps${NC}    Remove installed applications                    ${CYAN}│${NC}"
        echo -e "  ${CYAN}├─────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} I.${NC} ${YELLOW}Install All Selected${NC}                                               ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} C.${NC} ${YELLOW}Clear All Selections${NC}                                               ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} F.${NC} ${MAGENTA}Setup Flatpak${NC}                                                      ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} S.${NC} ${MAGENTA}Setup Snap${NC}                                                         ${CYAN}│${NC}"
        echo -e "  ${CYAN}├─────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} Q.${NC} ${RED}Quit${NC}                                                               ${CYAN}│${NC}"
        echo -e "  ${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -ne "  ${WHITE}Enter your choice: ${NC}"
        
        read -r choice
        
        case $choice in
            1) handle_category_selection BROWSERS "BROWSERS" ;;
            2) handle_category_selection EDITORS "EDITORS & IDEs" ;;
            3) handle_category_selection MEDIA "MEDIA & GRAPHICS" ;;
            4) handle_category_selection COMMUNICATION "COMMUNICATION" ;;
            5) handle_category_selection UTILITIES "UTILITIES" ;;
            6) handle_category_selection DEVELOPMENT "DEVELOPMENT TOOLS" ;;
            7) handle_category_selection GAMING "GAMING" ;;
            8) handle_category_selection OFFICE "OFFICE & PRODUCTIVITY" ;;
            9) browse_stores_menu ;;
            0) uninstaller_menu ;;
            i|I) install_all_selected ;;
            c|C) 
                SELECTED_APPS=()
                ;;
            f|F)
                setup_flatpak
                press_any_key
                ;;
            s|S)
                setup_snap
                press_any_key
                ;;
            q|Q)
                clear_screen
                echo -e "${GREEN}Thank you for using App Hub!${NC}"
                exit 0
                ;;
            *)
                echo -e "  ${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Main Entry Point
#-------------------------------------------------------------------------------

# Detect distro and package managers
detect_distro
detect_package_managers

# Check for root (not required but recommended for installation)
if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}Note: Running without sudo. You'll be prompted for password during installation.${NC}"
    sleep 1
fi

# Start the main menu
show_main_menu
