#!/bin/bash

################################################################################
# ARCH PIMP MY SYSTEM - THE SORGLOS PACKAGE (AppArmor Edition)
# Ziel: Bazzite-Performance auf Pure Arch Basis
# Fokus: AMD Ryzen 9700X + Radeon 7800 XT
# Security: AppArmor (Fedora-Alternative für Arch)
# V1.10-Arch
# ! ! ! ONLY TEST ! ! !
################################################################################

if [ "$EUID" -ne 0 ]; then
  echo "FEHLER: Bitte starte das Script mit sudo!"
  exit 1
fi

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo "~$REAL_USER")

echo "Starte das ultimative Arch-Sorglos-Setup mit Security (Stand 04/2026)..."

# 1. GRUB INTELLIGENZ & SECURITY FLAGS
if [ -f /etc/default/grub ]; then
  echo "Optimiere GRUB & aktiviere AppArmor..."
  # Merkt sich den letzten Kernel
  sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT=saved/' /etc/default/grub
  if ! grep -q "GRUB_SAVEDEFAULT=true" /etc/default/grub; then
    echo "GRUB_SAVEDEFAULT=true" >> /etc/default/grub
  fi
  # Aktiviert AppArmor im Kernel beim Booten
  if ! grep -q "apparmor=1 lsm=lockdown,yama,apparmor,bpf" /etc/default/grub; then
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="apparmor=1 lsm=lockdown,yama,apparmor,bpf /' /etc/default/grub
  fi
fi

# 2. PACMAN, MICROCODE & SECURITY TOOLS
if ! grep -q "ParallelDownloads" /etc/pacman.conf; then
  sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
  sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
fi
pacman -Syu --noconfirm amd-ucode base-devel git flatpak apparmor audit

# 3. APPARMOR AKTIVIEREN
systemctl enable --now apparmor
systemctl enable --now auditd

# 4. AUR HELPER (Yay)
if ! command -v yay &> /dev/null; then
  sudo -u "$REAL_USER" bash -c "cd /tmp && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm"
fi

# 5. KERNEL & PERFORMANCE-SCHEDULER (Zen-Kernel)
pacman -S --needed --noconfirm linux-zen linux-zen-headers
sudo -u "$REAL_USER" yay -S --noconfirm scx-scheds
systemctl enable --now scx_loader

# 6. GRAFIK & GAMING (AMD RDNA3 Optimiert)
pacman -S --needed --noconfirm \
    vulkan-radeon lib32-vulkan-radeon \
    libva-mesa-driver lib32-libva-mesa-driver \
    mesa-vdpau lib32-mesa-vdpau \
    steam discord mangohud goverlay gamemode gamescope \
    obs-studio obs-vaapi

# 7. POWER & AUDIO (Low Latency)
pacman -S --needed --noconfirm power-profiles-daemon pipewire-support
systemctl enable --now power-profiles-daemon

# 8. PIPEWIRE CONFIG
mkdir -p "$USER_HOME/.config/pipewire/pipewire.conf.d"
cat <<'EOF' > "$USER_HOME/.config/pipewire/pipewire.conf.d/99-lowlatency.conf"
context.properties = {
    default.clock.rate = 48000
    default.clock.quantum = 512
    default.clock.min-quantum = 32
}
EOF

# 9. SYSTEM TWEAKS (Gaming & Performance)
tee /etc/sysctl.d/90-gaming-ultimate.conf <<'EOF'
kernel.nmi_watchdog=0
kernel.split_lock_mitigate=0
vm.swappiness=10
vm.max_map_count=2147483642
fs.inotify.max_user_watches=524288
kernel.sched_base_slice_ns=3000000
EOF
sysctl --system

# 10. FLATPAKS
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
    net.davidotek.pupgui2 \
    com.heroicgameslauncher.hgl \
    com.usebottles.bottles \
    com.github.dail8859.NotepadNext

# 11. GRUB FINALE (Wichtig für AppArmor & Kernel Wahl)
if command -v grub-mkconfig &> /dev/null; then
  echo "Generiere Boot-Einträge neu..."
  grub-mkconfig -o /boot/grub/grub.cfg
fi

# RECHTE KORREKTUR
chown -R "$REAL_USER":"$REAL_USER" "$USER_HOME/.config/pipewire"

echo "----------------------------------------------------------------------"
echo "Sorglos-Secure-Setup abgeschlossen!"
echo "AppArmor ist aktiv. GRUB merkt sich deine Kernel-Wahl."
echo "WICHTIG: Nach dem Reboot prüfen mit: 'aa-status'"
echo "----------------------------------------------------------------------"
