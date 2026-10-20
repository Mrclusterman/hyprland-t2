-- Hyprland (config en Lua, 0.55+) · MacBook Pro T2 · repo: github.com/Mrclusterman/hyprland-t2
-- Errores de secciones individuales -> ~/.cache/hypr-lua-errors.log

local HOME     = os.getenv("HOME") or ""
local mainMod  = "SUPER"
local terminal = "kitty"
local launcher = "pkill -x fuzzel || fuzzel"  -- mismo atajo abre y cierra (Esc está en la Touch Bar rota)
local BLUR     = false   -- true = desenfoque de ventanas (mas bonito, mas GPU)

local function try(label, fn)
  local ok, err = pcall(fn)
  if not ok then
    local f = io.open(HOME .. "/.cache/hypr-lua-errors.log", "a")
    if f then
      f:write(os.date("%Y-%m-%d %H:%M:%S"), "  ", label, ": ", tostring(err), "\n")
      f:close()
    end
  end
end

local function bind(keys, make_dispatcher, flags)
  try("bind " .. keys, function()
    if flags then hl.bind(keys, make_dispatcher(), flags)
    else hl.bind(keys, make_dispatcher()) end
  end)
end
local function exec(cmd) return function() return hl.dsp.exec_cmd(cmd) end end

---------------- MONITOR ----------------
try("monitor", function()
  hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
  hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1.6 })
end)

---------------- ENTORNO ----------------
try("env", function()
  hl.env("XCURSOR_SIZE", "24")
  hl.env("HYPRCURSOR_SIZE", "24")
  hl.env("QT_QPA_PLATFORM", "wayland;xcb")
  hl.env("XDG_CONFIG_HOME", HOME .. "/.config")  -- sin ella el lanzador de Chrome ignora ~/.config/chrome-flags.conf
  hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")  -- apps Electron en Wayland nativo (nítidas con escala 1.6)
end)

---------------- AUTOSTART --------------
try("autostart", function()
  hl.on("hyprland.start", function()
    -- Autologin de greetd al encender (/etc/greetd/config.toml): bloquear en seguida = solo contraseña + Intro
    if os.getenv("HYPR_AUTOLOCK") == "1" then hl.exec_cmd("hyprlock") end
    hl.exec_cmd("swaybg -i " .. HOME .. "/.local/share/wallpapers/spiderman.jpg -m fill")
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("hypridle")
    hl.exec_cmd(HOME .. "/.local/bin/charger-chime")  -- sonido al enchufar el cargador
    hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
  end)
end)

---------------- ASPECTO ----------------
try("general", function()
  hl.config({
    general = {
      gaps_in = 4,
      gaps_out = 10,
      border_size = 1,
      col = {  -- estilo macOS: borde fino gris, la ventana activa apenas más clara
        active_border   = "rgba(ffffffa6)",
        inactive_border = "rgba(ffffff14)",
      },
      layout = "dwindle",
      resize_on_border = true,
      allow_tearing = false,
    },
  })
end)

try("decoration", function()
  hl.config({
    decoration = {
      rounding = 10,
      active_opacity = 1.0,
      inactive_opacity = 1.0,
      shadow = { enabled = false },
      blur = { enabled = BLUR, size = 3, passes = 1 },
    },
  })
end)

try("layout", function()
  hl.config({ dwindle = { preserve_split = true, force_split = 2 } })  -- 2 = nueva ventana siempre a la derecha/abajo (espiral Fibonacci)
end)

-- Configuración WiFi (clic en el icono de waybar): flotante y centrada
try("window rules", function()
  -- Ignorar peticiones de maximizar (kitty, etc.): si no, la ventana nueva ocupa toda la pantalla
  hl.window_rule({ name = "suppress-maximize-events", match = { class = ".*" }, suppress_event = "maximize" })
  hl.window_rule({ match = { class = "wifi-config" }, float = true, size = "720 520", center = true })
end)

-- Popups de brillo/volumen: sin animación
try("layer rules", function()
  hl.layer_rule({ match = { namespace = "barpopup" }, no_anim = true })
  hl.layer_rule({ match = { namespace = "idea" }, no_anim = true })
end)

try("misc", function()
  hl.config({
    misc = {
      force_default_wallpaper = 0,
      disable_hyprland_logo = true,
      -- Red de seguridad si la pantalla se queda apagada tras suspender (resume-screen la enciende normalmente)
      key_press_enables_dpms = true,
      mouse_move_enables_dpms = true,
    },
    -- Pantalla completa (vídeo/juegos) directo a la pantalla sin componer: menos GPU y batería
    render = { direct_scanout = 2 },
  })
end)

-- Animaciones cortas y baratas
try("animaciones", function()
  hl.config({ animations = { enabled = true } })
  hl.curve("quick", { type = "bezier", points = { {0.15, 0}, {0.1, 1} } })
  hl.animation({ leaf = "global",     enabled = true, speed = 6,   bezier = "default" })
  hl.animation({ leaf = "windows",    enabled = true, speed = 3,   bezier = "quick", style = "popin 90%" })
  hl.animation({ leaf = "fade",       enabled = true, speed = 3,   bezier = "quick" })
  hl.animation({ leaf = "workspaces", enabled = true, speed = 2.5, bezier = "quick", style = "fade" })
end)

---------------- ENTRADA ----------------
try("input", function()
  hl.config({
    input = {
      kb_layout = "es",
      follow_mouse = 2,  -- el foco cambia solo al hacer clic, no al pasar el ratón
      sensitivity = 0,
      touchpad = {
        natural_scroll       = true,
        tap_to_click         = true,
        clickfinger_behavior = true,  -- 2 dedos = clic derecho, 3 = central (como macOS)
        disable_while_typing = true,
        scroll_factor        = 0.5,   -- scroll más suave; sube/baja a tu gusto
      },
    },
  })
end)

---------------- GESTOS (trackpad) -------
try("gestures", function()
  hl.config({
    gestures = {
      workspace_swipe_create_new        = true,
      workspace_swipe_distance          = 250,  -- recorrido para un cambio completo (por defecto 300)
      workspace_swipe_cancel_ratio      = 0.3,  -- basta con el 30% del recorrido para confirmar
      workspace_swipe_min_speed_to_force = 15,  -- un gesto rápido y corto también cambia
    },
  })
  -- 3 dedos izq/der: cambiar de escritorio (Spaces)
  hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
  -- 3 dedos arriba: escritorio especial "scratchpad" (estilo Mission Control)
  hl.gesture({ fingers = 3, direction = "up", action = "special", workspace_name = "magic" })
  -- 3 dedos abajo: pantalla completa on/off
  hl.gesture({ fingers = 3, direction = "down", action = "fullscreen" })
  -- pellizco con 4 dedos: Spotlight/Launchpad
  hl.gesture({ fingers = 4, direction = "pinchin", action = function() hl.exec_cmd(launcher) end })
end)

---------------- NAUTILUS (Finder) ------
-- Nautilus y gvfs se quedan residentes (~200 MB) tras cerrar la ventana; al cerrar la última se paran.
-- Se reactivan solos al volver a abrir Nautilus o un diálogo de archivos.
try("nautilus quit", function()
  hl.on("window.close", function(w)
    if w and w.class == "org.gnome.Nautilus" then
      hl.exec_cmd("sleep 1; hyprctl clients | grep -q 'class: org.gnome.Nautilus' || "
        .. "{ nautilus -q; systemctl --user stop gvfs-daemon gvfs-udisks2-volume-monitor; }")
    end
  end)
end)

---------------- ATAJOS -----------------
bind(mainMod .. " + Return",        exec(terminal))
bind(mainMod .. " + D",             exec(launcher))
bind(mainMod .. " + space",         exec(launcher))   -- Spotlight
bind(mainMod .. " + B",             exec("google-chrome-stable"))
bind(mainMod .. " + E",             exec("nautilus --new-window"))   -- Finder
bind(mainMod .. " + N",             exec(HOME .. "/.local/bin/idea-popup"))   -- nota rápida -> Obsidian/Ideas/Inbox.md
bind(mainMod .. " + F",             function() return hl.dsp.window.fullscreen() end)
bind(mainMod .. " + S",             function() return hl.dsp.workspace.toggle_special("magic") end)
bind(mainMod .. " + SHIFT + M",     function() return hl.dsp.window.move({ workspace = "special:magic" }) end)
bind(mainMod .. " + J",             function() return hl.dsp.layout("togglesplit") end)
bind(mainMod .. " + L",             exec("hyprlock"))
bind(mainMod .. " + SHIFT + S",     exec(HOME .. "/.local/bin/shot-area"))
bind(mainMod .. " + Q",             function() return hl.dsp.window.close() end)
bind(mainMod .. " + V",             function() return hl.dsp.window.float({ action = "toggle" }) end)
bind(mainMod .. " + SHIFT + E",     function() return hl.dsp.exit() end)

for _, d in ipairs({ "left", "right", "up", "down" }) do
  bind(mainMod .. " + " .. d, function() return hl.dsp.focus({ direction = d }) end)
  bind(mainMod .. " + SHIFT + " .. d, function() return hl.dsp.window.move({ direction = d }) end)
end

for i = 1, 9 do
  local ws = tostring(i)
  bind(mainMod .. " + " .. ws,             function() return hl.dsp.focus({ workspace = ws }) end)
  bind(mainMod .. " + SHIFT + " .. ws,     function() return hl.dsp.window.move({ workspace = ws }) end)
end

bind(mainMod .. " + mouse_down", function() return hl.dsp.focus({ workspace = "e+1" }) end)
bind(mainMod .. " + mouse_up",   function() return hl.dsp.focus({ workspace = "e-1" }) end)
-- Clic fuera de Spotlight (fuzzel) o del cuadro de ideas = cerrarlo, también sobre la ventana que ya tenía el foco.
-- En Lua, sin lanzar procesos por clic; los clics dentro del cuadro no lo cierran.
local CLOSE_ON_OUTSIDE_CLICK = { launcher = true, idea = true }  -- namespaces de capa
local function close_launcher_on_outside_click()
  local c = hl.get_cursor_pos()
  for _, l in ipairs(hl.get_layers()) do
    if CLOSE_ON_OUTSIDE_CLICK[l.namespace] and l.mapped
        and c and (c.x < l.x or c.x >= l.x + l.w or c.y < l.y or c.y >= l.y + l.h) then
      hl.exec_cmd("kill " .. l.pid)
    end
  end
end
bind("mouse:272", function() return close_launcher_on_outside_click end, { non_consuming = true })
bind(mainMod .. " + mouse:272",  function() return hl.dsp.window.drag() end,   { mouse = true })
bind(mainMod .. " + mouse:273",  function() return hl.dsp.window.resize() end, { mouse = true })

local lr = { locked = true, repeating = true }
bind("XF86AudioRaiseVolume",   exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), lr)
bind("XF86AudioLowerVolume",   exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      lr)
bind("XF86AudioMute",          exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     lr)
bind("XF86MonBrightnessUp",    exec("brightnessctl -d acpi_video0 -e4 -n2 set 5%+"),   lr)
bind("XF86MonBrightnessDown",  exec("brightnessctl -d acpi_video0 -e4 -n2 set 5%-"),   lr)

-- Touch Bar rota: sustitutos de las teclas Fn con el teclado normal
local kbd = "brightnessctl -d apple::kbd_backlight set 10%%%s && pkill -RTMIN+8 waybar"
bind(mainMod .. " + CTRL + up",      exec("brightnessctl -d acpi_video0 -e4 -n2 set 5%+"),   lr)
bind(mainMod .. " + CTRL + down",    exec("brightnessctl -d acpi_video0 -e4 -n2 set 5%-"),   lr)
bind(mainMod .. " + CTRL + right",   exec(kbd:format("+")),                                  lr)
bind(mainMod .. " + CTRL + left",    exec(kbd:format("-")),                                  lr)
bind(mainMod .. " + ALT + up",       exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), lr)
bind(mainMod .. " + ALT + down",     exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      lr)
bind(mainMod .. " + ALT + M",        exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     lr)
bind(mainMod .. " + ALT + space",    exec("playerctl play-pause"), { locked = true })
bind(mainMod .. " + ALT + right",    exec("playerctl next"),       { locked = true })
bind(mainMod .. " + ALT + left",     exec("playerctl previous"),   { locked = true })
bind("XF86AudioPlay",          exec("playerctl play-pause"), { locked = true })
bind("XF86AudioNext",          exec("playerctl next"),       { locked = true })
bind("XF86AudioPrev",          exec("playerctl previous"),   { locked = true })
