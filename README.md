# hyprland-t2

A macOS-style Hyprland setup for a MacBook Pro with the T2 chip (MacBookPro15,4) running Arch Linux with the `linux-t2` kernel.
It is built to use as little power as possible: no blur or shadows, and nothing runs in the background unless it has to.

## What's included

- **macOS-style top bar (waybar):** system menu with the Arch logo, window title in the centre and clock on the right.
  Each icon opens its own popup: volume, screen and keyboard brightness, Wi-Fi, Bluetooth, battery with power mode, and calendar.
- **Spotlight** (fuzzel) on Cmd+Space. It closes with the same shortcut or a click outside.
- **Finder** (Nautilus) on Cmd+E. It runs without the `localsearch` indexer; closing the last window stops Nautilus and gvfs.
- **Quick notes** on Cmd+N: whatever you type is appended to `~/Obsidian/Ideas/Inbox.md`.
- **Login:** greetd logs straight into the session and hyprlock asks for the password. Type it and press Enter.
- **Suspend fixed for the T2:** no phantom wake-ups, and the screen comes back only once the keyboard responds.
- **Chime when the charger is plugged in.**
- **Xwayland on demand:** Hyprland's always-on Xwayland is off. A systemd socket starts `xwayland-satellite` when an X11 app connects, and it stops itself after 5 minutes without X11 windows.
- **Notifications** (mako) and macOS-style GTK4 apps.
- **Spiral tiling (dwindle).** Focus follows clicks, not the mouse, and borders are 1 px.

## Usage

```bash
./setup.sh capture   # copy the machine's current config into home/ and system/
./setup.sh install   # install packages and apply the config (asks for sudo)
```

`capture` stores your home folder and username as `@HOME@` and `@USER@`.
`install` replaces them with those of the user running it, so it works with any username.

Before running `install` you need:
- Arch booting `linux-t2` (`[arch-mact2]` repo).
- Apple's Wi-Fi and Bluetooth firmware in `/lib/firmware/brcm`.
- A user with sudo.

Google Chrome and Claude Code come from the AUR and are not installed by the script.

To keep the repo up to date after changing something on the machine:

```bash
./setup.sh capture && git add -A && git commit -m "..." && git push
```

## Layout

| Path | Contents |
|---|---|
| `home/.config/hypr/` | `hyprland.lua` (main config, in Lua), `hypridle.conf`, `hyprlock.conf` |
| `home/.config/waybar/` | Bar and styles |
| `home/.local/bin/barpopup.py` | Shared base for every popup: layer-shell window, styles and toggle list |
| `home/.local/bin/*-popup`, `bright-slider`, `system-menu` | The bar popups |
| `home/.local/bin/sleep-screen`, `resume-screen` | Turn the screen off on suspend and back on once the T2 keyboard returns |
| `home/.local/bin/charger-chime` | Charger chime. Waits for udev events instead of polling |
| `home/.local/bin/xwayland-ondemand`, `home/.config/systemd/user/xwayland-ondemand.*` | X11 display `:0` on demand (socket activation) and idle shutdown |
| `home/.local/bin/discord` | Discord launcher (the official one hangs without zenity) on Wayland with GPU video |
| `system/etc/greetd/` | Autologin with lock, and ReGreet as the login screen |
| `system/etc/udev/rules.d/90-no-wakeup.rules`, `system/usr/lib/systemd/system-sleep/no-wifi-wakeup` | Suspend fix |

## Shortcuts

| Shortcut | Action |
|---|---|
| Cmd+Space | Spotlight (open and close) |
| Cmd+E | Finder (Nautilus) |
| Cmd+N | Quick note |
| Cmd+Enter | Terminal (kitty) |
| Cmd+B | Chrome |
| Cmd+Q | Close window |
| Cmd+F | Fullscreen |
| Cmd+L | Lock |
| Cmd+Shift+S | Screenshot of an area (saved to `~/Pictures/Screenshots` and copied to the clipboard) |
| Cmd+1…9 / Cmd+Shift+1…9 | Go to a workspace / move the window to that workspace |
| Cmd+Ctrl+↑↓ / ←→ | Screen / keyboard brightness (the Touch Bar is broken) |
| Cmd+Alt+↑↓ / M | Volume / mute |
| Shift at boot | GRUB menu (Esc lives on the Touch Bar) |

## T2 quirks

- **Esc and F keys:** they don't exist because the Touch Bar is broken. That's why everything closes with the shortcut that opened it or a click outside.
- **Brightness:** `brightnessctl` always takes `-d acpi_video0`. Without it, it changes the Touch Bar.
- **Suspend:** the Wi-Fi (`brcmfmac`) gets its wake-up permission back on every cycle. A systemd-sleep script removes it right before suspending.
- **Keyboard on resume:** the T2 reconnects it about 0.5 s after waking. `resume-screen` waits for it before turning the screen on.
- **Touch ID:** doesn't work on Linux, because the T2's Secure Enclave controls the sensor.

## License

[MIT](LICENSE)
