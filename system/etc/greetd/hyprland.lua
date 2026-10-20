-- Hyprland mínimo solo para el greeter (ReGreet). Sin animaciones ni efectos.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1.6 })
hl.env("XCURSOR_SIZE", "24")
hl.config({
  input = {
    kb_layout = "es",
    touchpad = { natural_scroll = true, tap_to_click = true, clickfinger_behavior = true },
  },
  animations = { enabled = false },
  decoration = { shadow = { enabled = false }, blur = { enabled = false } },
  misc = { disable_hyprland_logo = true, disable_splash_rendering = true, force_default_wallpaper = 0 },
  ecosystem = { no_update_news = true, no_donation_nag = true },
})
hl.on("hyprland.start", function()
  hl.exec_cmd("regreet; hyprctl dispatch 'hl.dsp.exit()'")
end)
