#!/usr/bin/env bash
# Réplica de la configuración de Hyprland del MacBook Pro T2 (Arch + kernel linux-t2, repo [arch-mact2]).
# Estilo macOS sin efectos (bajo consumo): waybar con popups propios, Spotlight (fuzzel), Finder (Nautilus),
# suspensión arreglada para T2, autologin + hyprlock, sonido de carga, notas rápidas a Obsidian.
#
#   ./setup.sh capture   copia la configuración actual del equipo a este proyecto (home/ y system/)
#   ./setup.sh install   instala paquetes y aplica la configuración guardada (pide sudo para lo de sistema)
#
# Requisitos previos de install: Arch con linux-t2 arrancando, firmware WiFi/BT de Apple en /lib/firmware/brcm,
# usuario con sudo. Google Chrome y Claude Code vienen del AUR y no se instalan aquí.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

# Rutas relativas a $HOME
HOME_FILES=(
  .config/hypr/hyprland.lua .config/hypr/hypridle.conf .config/hypr/hyprlock.conf
  .config/waybar/config.jsonc .config/waybar/style.css
  .config/fuzzel/fuzzel.ini .config/mako/config .config/kitty/kitty.conf
  .config/gtk-3.0/settings.ini .config/gtk-4.0/settings.ini .config/gtk-4.0/gtk.css
  .config/chrome-flags.conf
  .local/bin/barpopup.py .local/bin/bright-slider .local/bin/wifi-popup .local/bin/bt-popup
  .local/bin/battery-popup .local/bin/cal-popup .local/bin/apple-menu .local/bin/idea-popup
  .local/bin/sleep-screen .local/bin/resume-screen .local/bin/charger-chime .local/bin/discord
  .local/bin/shot-area .local/bin/ui-mem
  .local/share/sounds/charger.wav .local/share/wallpapers/spiderman.jpg
  .local/share/applications/discord.desktop
)
# Rutas absolutas del sistema
SYSTEM_FILES=(
  /etc/greetd/config.toml /etc/greetd/hyprland.lua /etc/greetd/regreet.toml /etc/greetd/regreet.css
  /usr/share/backgrounds/spiderman.jpg
  /etc/udev/rules.d/90-no-wakeup.rules
  /usr/lib/systemd/system-sleep/no-wifi-wakeup
  /etc/NetworkManager/conf.d/wifi_backend.conf
)
PACKAGES=(
  hyprland hypridle hyprlock hyprpolkitagent xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  greetd greetd-regreet waybar fuzzel mako kitty swaybg nautilus
  python-gobject gtk3 gtk-layer-shell libnotify grim slurp wl-clipboard brightnessctl playerctl
  pipewire-pulse wireplumber apple-t2-audio-config networkmanager iwd bluez bluez-utils
  power-profiles-daemon pacman-contrib t2fanrd intel-media-driver fastfetch
  adwaita-fonts noto-fonts noto-fonts-emoji ttf-jetbrains-mono-nerd
  discord obsidian
)

capture() {
  for f in "${HOME_FILES[@]}"; do
    mkdir -p "home/$(dirname "$f")"
    cp -p "$HOME/$f" "home/$f"
  done
  for f in "${SYSTEM_FILES[@]}"; do
    mkdir -p "system$(dirname "$f")"
    cp -p "$f" "system$f"
  done
  echo "Capturados ${#HOME_FILES[@]} archivos de usuario y ${#SYSTEM_FILES[@]} de sistema."
}

install_all() {
  sudo -v
  echo "== Paquetes"
  sudo pacman -S --needed "${PACKAGES[@]}"

  echo "== Archivos de usuario (lo que ya exista se guarda como .bak)"
  for f in "${HOME_FILES[@]}"; do
    [ -e "$HOME/$f" ] && ! cmp -s "home/$f" "$HOME/$f" && cp -p "$HOME/$f" "$HOME/$f.bak"
    mkdir -p "$HOME/$(dirname "$f")"
    cp -p "home/$f" "$HOME/$f"
  done

  echo "== Archivos de sistema"
  for f in "${SYSTEM_FILES[@]}"; do
    sudo install -Dm"$(stat -c %a "system$f")" "system$f" "$f"
  done

  echo "== GRUB: parámetros T2, menú oculto (Shift al arrancar para verlo)"
  sudo sed -i 's/^#\?GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="intel_iommu=on iommu=pt pcie_ports=compat pm_async=off"/;
               s/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/; s/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' /etc/default/grub
  sudo grub-mkconfig -o /boot/grub/grub.cfg

  echo "== Sistema: hora, idioma, servicios"
  sudo timedatectl set-timezone Europe/Madrid
  sudo timedatectl set-ntp true
  sudo localectl set-locale LANG=es_ES.UTF-8
  sudo localectl set-keymap es
  sudo systemctl enable greetd NetworkManager iwd t2fanrd fstrim.timer power-profiles-daemon paccache.timer bluetooth
  sudo systemctl disable NetworkManager-wait-online sshd 2>/dev/null || true

  echo "== Escritorio: tema, Nautilus sin indexador"
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark
  gsettings set org.gnome.desktop.wm.preferences button-layout 'close:'
  gsettings set org.gnome.nautilus.icon-view default-zoom-level 'small-plus'
  gsettings set org.gnome.nautilus.preferences fts-enabled false
  systemctl --user mask localsearch-3.service localsearch-control-3.service localsearch-writeback-3.service
  xdg-mime default org.gnome.Nautilus.desktop inode/directory

  echo "Listo. Reinicia el equipo."
}

case "${1:-}" in
  capture) capture ;;
  install) install_all ;;
  *) sed -n '2,10p' "$0" | sed 's/^# \?//'; exit 1 ;;
esac
