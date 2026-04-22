#!/bin/bash

################################################################################
# ARCH PIMP MY SYSTEM - THE SORGLOS PACKAGE
# Ziel: Bazzite-Performance auf Pure Arch Basis
# Fokus: AMD Ryzen 9700X + Radeon 7800 XT
# Features: Dual-Kernel Setup (Zen + Mainline), GRUB-Automatik, Scheduler-Fixes
# V1.01-Arch
# ! ! ! Only Test ! ! !
################################################################################

if [ "$EUID" -ne 0 ]; then
  echo "FEHLER: Bitte starte das Script mit sudo!"
  exit 1
fi

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo "~$REAL_USER")

echo "Starte das ultimative Arch-Sorglos-Setup (Stand 04/2026)..."

# 1. GRUB INTELLIGENZ (Sorgt dafür, dass er sich den Zen-Kernel merkt)
if [ -f /etc/default/grub ]; then
  echo "Optimiere GRUB-Einstellungen..."
  sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT=saved/' /etc/default/grub
  if ! grep -q "GRUB_SAVEDEFAULT=true" /etc/default/grub; then
    echo "GRUB_SAVEDEFAULT=true" >> /etc/default/grub
  fi
fi

# 2. PACMAN & MICROCODE
if ! grep -q "ParallelDownloads" /etc/pacman.conf; then
  sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
  sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
fi
pacman -Syu --noconfirm amd-ucode base-devel git flatpak

# 3. AUR HELPER (Yay)
if ! command -v yay &> /dev/null; then
  sudo -u "$REAL_USER" bash -c "cd /tmp && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm"
fi

# 4. KERNEL & PERFORMANCE-SCHEDULER
# Installiert Zen zusätzlich zum Standard-Kernel
pacman -S --needed --noconfirm linux-zen linux-zen-headers
sudo -u "$REAL_USER" yay -S --noconfirm scx-scheds
systemctl enable --now scx_loader

# 5. GRAFIK & GAMING (Optimiert für 7800 XT)
pacman -S --needed --noconfirm \
    vulkan-radeon lib32-vulkan-radeon \
    libva-mesa-driver lib32-libva-mesa-driver \
    mesa-vdpau lib32-mesa-vdpau \
    steam discord mangohud goverlay gamemode gamescope \
    obs-studio obs-vaapi

# 6. POWER & AUDIO
pacman -S --needed --noconfirm power-profiles-daemon pipewire-support
systemctl enable --now power-profiles-daemon

# 7. PIPEWIRE LOW LATENCY
mkdir -p "$USER_HOME/.config/pipewire/pipewire.conf.d"
cat <<'EOF' > "$USER_HOME/.config/pipewire/pipewire.conf.d/99-lowlatency.conf"
context.properties = {
    default.clock.rate = 48000
    default.clock.quantum = 512
    default.clock.min-quantum = 32
}
EOF

# 8. SYSTEM TWEAKS (Bazzite-Level)
tee /etc/sysctl.d/90-gaming-ultimate.conf <<'EOF'
kernel.nmi_watchdog=0
kernel.split_lock_mitigate=0
vm.swappiness=10
vm.max_map_count=2147483642
fs.inotify.max_user_watches=524288
kernel.sched_base_slice_ns=3000000
EOF
sysctl --system

# 9. FLATPAKS
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
    net.davidotek.pupgui2 \
    com.heroicgameslauncher.hgl \
    com.usebottles.bottles \
    com.github.dail8859.NotepadNext

# 10. GRUB FINALE
if command -v grub-mkconfig &> /dev/null; then
  echo "Generiere Boot-Einträge neu..."
  grub-mkconfig -o /boot/grub/grub.cfg
fi

# RECHTE KORREKTUR
chown -R "$REAL_USER":"$REAL_USER" "$USER_HOME/.config/pipewire"

echo "----------------------------------------------------------------------"
echo "Sorglos-Setup abgeschlossen!"
echo "BEIM ERSTEN REBOOT: Wähle 'Advanced Options' -> 'Linux-Zen'."
echo "GRUB wird sich diese Wahl für die Zukunft merken."
echo "----------------------------------------------------------------------"
