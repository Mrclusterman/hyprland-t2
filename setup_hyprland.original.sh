#!/bin/bash

# Terminar el script si ocurre algún error grave
set -e

echo "🚀 Iniciando configuración de Hyprland para MacBook Pro..."

# 1. Crear directorios de configuración necesarios
mkdir -p ~/.config/hypr
mkdir -p ~/.config/wofi

# 2. Configurar autoinicio de Hyprland en TTY1 (~/.bash_profile)
echo "📄 Configurando el inicio automático en TTY1..."
if ! grep -q "exec start-hyprland" ~/.bash_profile 2>/dev/null; then
    cat << 'EOF' >> ~/.bash_profile

# Iniciar Hyprland automáticamente en TTY1
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec start-hyprland
fi
EOF
fi

# 3. Generar la configuración principal de Hyprland (~/.config/hypr/hyprland.conf)
echo "🎨 Aplicando ajustes de pantalla, trackpad y diseño en Hyprland..."
cat << 'EOF' > ~/.config/hypr/hyprland.conf
# --- TECLADO Y TRACKPAD MACBOOK ---
input {
    kb_layout = es          # Cambia a 'us' si tu teclado físico es americano
    follow_mouse = 1

    touchpad {
        natural_scroll = true
        tap-to-click = true
        clickfinger_behavior = true
    }
}

# --- AUTOINICIO DE SERVICIOS ---
exec-once = waybar
exec-once = mako
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

# --- APARIENCIA Y BORDES ---
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)

    layout = dwindle
}

# --- DECORACIÓN Y EFECTOS ---
decoration {
    rounding = 10

    blur {
        enabled = true
        size = 3
        passes = 1
    }

    drop_shadow = true
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

# --- BINDINGS BÁSICOS ---
$mainMod = SUPER

bind = $mainMod, Q, exec, kitty
bind = $mainMod, C, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, dolphin
bind = $mainMod, V, togglefloating,
bind = $mainMod, D, exec, wofi --show drun
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,

# Mover foco con Super + Flechas
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Mover/Redimensionar ventanas con el trackpad
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow
EOF

# 4. Configurar el menú flotante Wofi (~/.config/wofi/config)
echo "🔍 Configurando el lanzador Wofi..."
cat << 'EOF' > ~/.config/wofi/config
width=400
height=300
location=center
show=drun
prompt=Buscar...
filter_rate=100
allow_markup=true
no_actions=true
halign=fill
orientation=vertical
insensitive=true
EOF

echo "✅ Configuración completada con éxito."

# 5. Auto-eliminación del script
echo "🧹 Eliminando el instalador..."
rm -- "$0"

echo "🎉 ¡Todo listo! Cierra sesión o reinicia para ver los cambios."
