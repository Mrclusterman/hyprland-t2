# hyprland-t2

Configuración de Hyprland con aspecto de macOS para un MacBook Pro con chip T2 (MacBookPro15,4) en Arch Linux con el kernel `linux-t2`.
Está pensada para gastar lo mínimo: sin desenfoque ni sombras, y nada se queda en segundo plano sin hacer falta.

## Qué incluye

- **Barra superior (waybar) estilo macOS:** menú del sistema con el logo de Arch, título de la ventana en el centro y reloj a la derecha.
  Cada icono abre su propio popup: volumen, brillo de pantalla y de teclado, Wi-Fi, Bluetooth, batería con modo de energía, y calendario.
- **Spotlight** (fuzzel) con Cmd+Espacio. Se cierra con el mismo atajo o haciendo clic fuera.
- **Finder** (Nautilus) con Cmd+E. Va sin el indexador `localsearch`; al cerrar la última ventana se paran Nautilus y gvfs.
- **Notas rápidas** con Cmd+N: lo que escribas se añade a `~/Obsidian/Ideas/Inbox.md`.
- **Inicio de sesión:** greetd entra solo en la sesión y hyprlock pide la contraseña. Basta con escribirla y pulsar Intro.
- **Suspensión arreglada para T2:** sin despertares fantasma, y la pantalla vuelve justo cuando el teclado ya responde.
- **Sonido al enchufar el cargador.**
- **Notificaciones** (mako) y apps GTK4 con estilo macOS.
- **Ventanas en espiral (dwindle).** El foco cambia al hacer clic, no al pasar el ratón, y los bordes son de 1 px.

## Uso

```bash
./setup.sh capture   # copia la configuración actual del equipo a home/ y system/
./setup.sh install   # instala paquetes y aplica la configuración (pide sudo)
```

`capture` guarda tu carpeta personal y tu usuario como `@HOME@` y `@USER@`.
`install` los sustituye por los del usuario que lo ejecute, así que funciona con cualquier nombre de usuario.

Antes de ejecutar `install` necesitas:
- Arch arrancando con `linux-t2` (repo `[arch-mact2]`).
- El firmware de Wi-Fi y Bluetooth de Apple en `/lib/firmware/brcm`.
- Un usuario con sudo.

Google Chrome y Claude Code vienen del AUR y no se instalan con el script.

Para mantener el repo al día después de cambiar algo en el equipo:

```bash
./setup.sh capture && git add -A && git commit -m "..." && git push
```

## Estructura

| Ruta | Contenido |
|---|---|
| `home/.config/hypr/` | `hyprland.lua` (configuración principal en Lua), `hypridle.conf`, `hyprlock.conf` |
| `home/.config/waybar/` | Barra y estilos |
| `home/.local/bin/barpopup.py` | Base común de todos los popups: ventana layer-shell, estilos y lista con interruptor |
| `home/.local/bin/*-popup`, `bright-slider`, `system-menu` | Los popups de la barra |
| `home/.local/bin/sleep-screen`, `resume-screen` | Apagan la pantalla al suspender y la encienden cuando el teclado T2 vuelve |
| `home/.local/bin/charger-chime` | Sonido al enchufar el cargador. Espera los eventos de udev, sin consultar en bucle |
| `home/.local/bin/discord` | Lanzador de Discord (el oficial se queda colgado sin zenity) en Wayland y con vídeo por GPU |
| `system/etc/greetd/` | Autologin con bloqueo y ReGreet como pantalla de acceso |
| `system/etc/udev/rules.d/90-no-wakeup.rules`, `system/usr/lib/systemd/system-sleep/no-wifi-wakeup` | Arreglo de la suspensión |

## Atajos

| Atajo | Acción |
|---|---|
| Cmd+Espacio | Spotlight (abrir y cerrar) |
| Cmd+E | Finder (Nautilus) |
| Cmd+N | Nota rápida |
| Cmd+Intro | Terminal (kitty) |
| Cmd+B | Chrome |
| Cmd+Q | Cerrar ventana |
| Cmd+F | Pantalla completa |
| Cmd+L | Bloquear |
| Cmd+Shift+S | Captura de una zona (se guarda en `~/Pictures/Screenshots` y se copia al portapapeles) |
| Cmd+1…9 / Cmd+Shift+1…9 | Ir a un escritorio / mover la ventana a ese escritorio |
| Cmd+Ctrl+↑↓ / ←→ | Brillo de pantalla / de teclado (la Touch Bar está rota) |
| Cmd+Alt+↑↓ / M | Volumen / silencio |
| Shift al arrancar | Menú de GRUB (Esc está en la Touch Bar) |

## Particularidades del T2

- **Esc y teclas F:** no existen porque la Touch Bar está rota. Por eso los cierres van con el mismo atajo que abre o con un clic fuera.
- **Brillo:** `brightnessctl` siempre lleva `-d acpi_video0`. Sin él actúa sobre la Touch Bar.
- **Suspensión:** el Wi-Fi (`brcmfmac`) se vuelve a dar permiso para despertar el equipo en cada ciclo. Un script de systemd-sleep se lo quita justo antes de suspender.
- **Teclado al despertar:** el T2 lo vuelve a conectar unos 0,5 s después de despertar. `resume-screen` espera a que vuelva para encender la pantalla.
- **Touch ID:** no funciona en Linux, porque el sensor lo controla el Secure Enclave del T2.
