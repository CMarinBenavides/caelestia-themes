# 🌲🔺 Caelestia Falls

Un tema de **Gravity Falls** para [Caelestia](https://github.com/caelestia-dots/shell) en Arch Linux + Hyprland.
Con un solo comando cambias entre **Caelestia Falls** y **Caelestia original**.

> `YRVMEVMRWL HGZMULIW`

## Qué incluye

| Momento | Caelestia Falls |
|---|---|
| 🎩 **Arranque (Plymouth)** | El Tío Stan aparece en un destello frente a la Cabaña del Misterio, a pantalla completa, y se queda en el letrero *"MYSTERY HACK"* con un mensaje cifrado: **YRVMEVMRWL HGZMULIW** |
| 👋 **Apagado / reinicio** | El letrero con otro mensaje: **SZHGZ OFVTL HGZMOVB** |
| 🔺 **Al iniciar sesión** | El susurro invertido de Bill Cipher del final de la intro, a volumen bajo |
| 🖥️ **Terminal (fish)** | Título *Caelestia Falls*, un **criptograma del día** (Atbash, César +3 o A1Z26) y Bill Cipher en el color de tu esquema junto a fastfetch |
| 🖼️ **Wallpapers** | ~44 wallpapers de la serie desde Wallhaven, en `Gravity Falls Theme/` dentro de tu carpeta de wallpapers |

Todo sigue los colores de Caelestia: si cambias de wallpaper, Bill y la terminal cambian de color.

## Requisitos

- Arch Linux con [Caelestia](https://github.com/caelestia-dots/caelestia) (shell + CLI) y la shell `fish`.
- **Tu propia copia** del vídeo *Gravity Falls Opening Theme Song* (la intro oficial, ~39 s, 1080p).
  Este repositorio **no incluye** fotogramas, audio ni wallpapers: el instalador los genera o descarga en tu equipo.
- Para la animación de arranque: Plymouth con el hook en `mkinitcpio` y `quiet splash` en la línea del kernel.
  El instalador te avisa si falta algo.

## Instalación

```fish
git clone https://github.com/<tu-usuario>/caelestia-falls
cd caelestia-falls
./install.sh "~/Downloads/Gravity Falls - Opening Theme Song.mp4"
```

El instalador detecta solo en el vídeo el destello del Tío Stan, el corte de escena, la silueta de Bill y el susurro final.

Opciones: `--sin-plymouth` (no toca el arranque) y `--sin-wallpapers` (no descarga fondos).

## Uso

```fish
tema gravity-falls    # activa Caelestia Falls
tema normal           # vuelve a Caelestia original
tema estado           # qué está activo

descifrar             # solución del criptograma de hoy
sonido-inicio         # silencia o reactiva el susurro de Bill (para reuniones)
```

Cambiar de tema regenera la imagen de arranque (pide `sudo` y tarda menos de un minuto).
Si solo quieres cambiar la terminal y los wallpapers: `tema normal --sin-plymouth`.

## Desinstalar

```fish
./uninstall.sh
```

## Créditos

- *Gravity Falls* © Disney, creada por Alex Hirsch. Proyecto de fans sin relación con Disney; no se distribuye material de la serie.
- Wallpapers: sus autores en [Wallhaven](https://wallhaven.cc). Se descargan desde allí al instalar.
- [Caelestia](https://github.com/caelestia-dots) por soramane y colaboradores.

El código de este repositorio está bajo la licencia MIT.

> `HGZM ML VH OL JFV KZIVXV`
