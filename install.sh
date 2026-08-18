#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║              GROUPME - INSTALLER                         ║
# ║       Self-Hosted Group Chat & Video Calls               ║
# ╚══════════════════════════════════════════════════════════╝
set -e

# ── Colors ─────────────────────────────────────────────────
R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
M='\033[1;35m'
C='\033[1;36m'
W='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# ── Progress bar ───────────────────────────────────────────
progressbar() {
    local current=$1 total=$2 width=30
    local pct=$(( current * 100 / total ))
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))
    printf "\r  ${C}[${G}"
    printf '█%.0s' $(seq 1 $filled 2>/dev/null) || true
    printf "${DIM}"
    printf '░%.0s' $(seq 1 $empty 2>/dev/null) || true
    printf "${NC}${C}] ${W}%3d%%${NC}" "$pct"
}

spin() {
    local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 "$1" 2>/dev/null; do
        printf "\r  ${C}${chars:i++%${#chars}:1}${NC} %s" "$2"
        sleep 0.1
    done
    printf "\r  ${G}✔${NC} %s\n" "$2"
}

# ── Banner ─────────────────────────────────────────────────
clear
echo -e "${M}  ╔═══════════════════════════════════════════╗${NC}"
echo -e "${M}  ║        ${W}★ Stephen's Studio${M} ★               ║${NC}"
echo -e "${M}  ╚═══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${M}"
cat << 'EOF'
    ░██████╗░██████╗░██████╗░██████╗░██████╗░
    ██╔════╝██╔═══██╗██╔══██╗██╔══██╗██╔══██╗
    ╚█████╗░██║   ██║██║  ██║██║  ██║██████╔╝
    ░╚═══██╗██║   ██║██║  ██║██║  ██║██╔═══╝╗
    ██████╔╝╚██████╔╝██████╔╝██████╔╝██║   ║
    ╚═════╝░░╚═════╝░╚═════╝░╚═════╝░╚═╝  ║
EOF
echo -e "${NC}"
echo -e "${W}  ── Self-Hosted Chat, Voice & Video Calls ──${NC}"
echo ""

# ── Menu ───────────────────────────────────────────────────
echo -e "${B}[MENU]${NC} Choose an option:"
echo -e "  ${G}1)${NC} Full Install (recommended)"
echo -e "  ${Y}2)${NC} Install System Packages Only"
echo -e "  ${R}3)${NC} Uninstall"
echo ""
read -p "$(echo -e ${B}'Select [1-3]: '${NC})" CHOICE

case $CHOICE in
    3)
        echo -e "\n${R}╔═══════════════════════════════════════╗${NC}"
        echo -e "${R}║         UNINSTALL GROUPME             ║${NC}"
        echo -e "${R}╚═══════════════════════════════════════╝${NC}"
        read -p "$(echo -e ${R}'Remove media/ and config? [y/N]: '${NC})" CONFIRM
        if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
            rm -rf media/ 2>/dev/null
            echo -e "${G}Media files removed.${NC}"
        fi
        echo -e "${G}Done. System packages were not removed.${NC}"
        exit 0
        ;;
    2)
        INSTALL_SYSTEM=1; INSTALL_APP=0
        ;;
    *)
        INSTALL_SYSTEM=1; INSTALL_APP=1
        ;;
esac

# ── Helper functions ───────────────────────────────────────
step() { echo -e "\n${G}[$1/$TOTAL]${NC} ${W}$2${NC}"; }
ok()   { echo -e "  ${G}✔${NC} $1"; }
warn() { echo -e "  ${Y}⚠${NC} $1"; }

TOTAL=2
STEP=0

# ── Step 1: System packages ────────────────────────────────
STEP=$((STEP+1))
step $STEP "Installing system packages..."
sudo apt-get update -qq 2>/dev/null
for i in $(seq 1 10); do progressbar $i 10; sleep 0.1; done; echo ""
sudo apt-get install -y -qq \
    python3 python3-gi python3-cairo \
    gir1.2-gtk-3.0 wmctrl 2>/dev/null || true
for i in $(seq 1 10); do progressbar $((10+i)) 20; sleep 0.05; done; echo ""
ok "System packages installed"

# ── Step 2: App setup ──────────────────────────────────────
if [[ $INSTALL_APP -eq 1 ]]; then
    STEP=$((STEP+1))
    step $STEP "Setting up app..."
    mkdir -p media
    chmod +x server.py tray.py 2>/dev/null || true
    for i in $(seq 1 5); do progressbar $i 5; sleep 0.1; done; echo ""
    ok "App ready"
fi

# ── Done ───────────────────────────────────────────────────
echo ""
echo -e "${G}╔═══════════════════════════════════════╗${NC}"
echo -e "${G}║       INSTALLATION COMPLETE!          ║${NC}"
echo -e "${G}╚═══════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${W}Start chat server:${NC}"
echo -e "    ${C}python3 server.py${NC}"
echo -e "    ${DIM}Then open http://localhost:8002${NC}"
echo ""
echo -e "  ${W}Start tray launcher (official GroupMe):${NC}"
echo -e "    ${C}python3 tray.py${NC}"
echo -e "    ${DIM}Requires Google Chrome${NC}"
echo ""
echo -e "  ${M}★ Stephen's Studio ★${NC}"
echo ""
