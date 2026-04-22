#!/bin/bash

################################################################################
# ARCH PIMP MY SYSTEM - ULTIMATE GAMING & STREAMING SETUP
# Ziel: Gaming-Optimierung auf Arch-Basis
# Fokus: AMD Ryzen 9700X + Radeon 7800 XT
# Mainener: @Knilix
# V1.00-Arch
# ! ! ! Only TEST ! ! ! 
################################################################################

if [ "$EUID" -ne 0 ]; then
  echo "FEHLER: Bitte starte das Script mit sudo!"
  exit 1
fi

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo "~$REAL_USER")

echo "Starte Arch-System-Optimierung (Stand 04/2026)..."

# 1. Pacman Optimierung
if ! grep -q "ParallelDownloads" /etc/pacman.conf; then
  sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
  sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
fi

pacman -Syu --noconfirm

# 2. AUR Helper (Yay) installieren, falls nicht vorhanden
if ! command -v yay &> /dev/null; then
  echo "Installiere yay..."
  pacman -S --needed --noconfirm base-devel git
  sudo -u "$REAL_USER" bash -c "cd /tmp && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm"
fi

# 3. Multimedia & Codecs (AMD GPU Fokus)
pacman -S --needed --noconfirm \
    libva-mesa-driver mesa-vdpau libva-utils vdpauinfo \
    ffmpeg obs-studio lib32-libva-mesa-driver lib32-mesa-vdpau

# 4. Gaming Essentials & 32-Bit
pacman -S --needed --noconfirm \
    steam discord mangohud goverlay gamemode gamescope \
    lutris wine-staging winetricks giflib lib32-giflib lib32-libpng \
    lib32-libldap lib32-gnutls lib32-v4l-utils lib32-libgpg-error \
    lib32-sqlite lib32-libpulse lib32-alsa-plugins \
    vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader

# 5. Power Management (AMD P-State & EPP)
pacman -S --needed --noconfirm power-profiles-daemon
systemctl enable --now power-profiles-daemon

# 6. PipeWire Low Latency
pacman -S --needed --noconfirm pipewire pipewire-pulse pipewire-alsa pipewire-jack
mkdir -p "$USER_HOME/.config/pipewire/pipewire.conf.d"
cat <<'EOF' > "$USER_HOME/.config/pipewire/pipewire.conf.d/99-lowlatency.conf"
context.properties = {
    default.clock.rate = 48000
    default.clock.quantum = 512
    default.clock.min-quantum = 32
}
EOF

# 7. Configs (GameMode & MangoHud)
mkdir -p "$USER_HOME/.config/MangoHud"
cat <<'EOF' > "$USER_HOME/.config/gamemode.ini"
[general]
renice=10
[cpu]
governor=performance
[gpu]
apply_gpu_optimisations=accept-responsibility
gpu_device=0
amd_performance_level=high
EOF

cat <<'EOF' > "$USER_HOME/.config/MangoHud/MangoHud.conf"
fps
frametime
gpu_stats
gpu_temp
cpu_stats
ram
vram
vulkan_driver
wine
position=top-left
toggle_hud=F12
EOF

# Rechte korrigieren
chown -R "$REAL_USER":"$REAL_USER" "$USER_HOME/.config/pipewire"
chown -R "$REAL_USER":"$REAL_USER" "$USER_HOME/.config/MangoHud"
chown "$REAL_USER":"$REAL_USER" "$USER_HOME/.config/gamemode.ini"

# 8. System Tweaks (Optimiert für 2026 / 9700X)
tee /etc/sysctl.d/90-boost.conf <<'EOF'
kernel.nmi_watchdog=0
vm.swappiness=10
vm.dirty_background_bytes=134217728
vm.dirty_bytes=268435456
fs.inotify.max_user_watches=524288
vm.max_map_count=2147483642
kernel.split_lock_mitigate=0
EOF
sysctl --system

# 9. Flatpaks & AUR Tools
pacman -S --needed --noconfirm flatpak
sudo -u "$REAL_USER" yay -S --noconfirm \
    proton-ge-custom-bin \
    termius \
    notepadnext-bin

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
    net.davidotek.pupgui2 \
    com.heroicgameslauncher.hgl \
    com.usebottles.bottles

echo "----------------------------------------------------------------------"
echo "Arch Setup abgeschlossen! Reboot empfohlen."
echo "----------------------------------------------------------------------"
