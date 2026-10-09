# ✨ Caelestia Themes

*[Read in English](README.md)*

Temas de series y películas para [Caelestia](https://github.com/caelestia-dots/shell) en Arch Linux + Hyprland.
Cada tema cambia la **animación de arranque y apagado**, los **sonidos**, el **saludo de la terminal**, los **GIF de Caelestia** y los **wallpapers**,
y con un solo comando cambias entre temas o vuelves a Caelestia original.

```fish
theme list             # temas instalados
theme gravity-falls    # 🌲🔺 Caelestia Falls
theme ngnl-zero        # 🎲♟️ Caelestia Zero
theme default          # ✨ Caelestia original
```

## Temas

### 🌲🔺 Caelestia Falls — *Gravity Falls*

| Momento | |
|---|---|
| 🎩 Arranque | El Tío Stan aparece en un destello frente a la Cabaña del Misterio y se queda en el letrero *"MYSTERY HACK"* con `YRVMEVMRWL HGZMULIW` |
| 👋 Apagado | El letrero con `SZHGZ OFVTL HGZMOVB` |
| 🔺 Al iniciar sesión | El susurro invertido de Bill Cipher del final de la intro |
| 🖥️ Terminal | Título *Caelestia Falls*, un **criptograma del día** (Atbash, César +3 o A1Z26; `decode` para la solución) y la silueta de Bill |
| 🎞️ GIFs | El Tío Stan con sus gafas en el menú de sesión y la banda en la fogata en el reproductor del dashboard |
| 🖼️ Wallpapers | ~44 de Wallhaven |

Vídeo necesario: la intro oficial *Gravity Falls Opening Theme Song* (~39 s).

### 🎲♟️ Caelestia Zero — *No Game No Life Zero*

| Momento | |
|---|---|
| 🎬 Arranque | Una mano en la oscuridad → Riku → el cielo rojo de Disboard, con **【 ゲーム開始 】** · *que empiece el juego* |
| 🔮 Apagado | La cueva de cristales, con **【 ASCHENTE 】** · *lo juro por el pacto* |
| 🔊 Sonidos | 「ゲームを始めよう」 al entrar y 「アッシェンテ」 al apagar o reiniciar |
| 🖥️ Terminal | Título *Caelestia Zero*, **los diez pactos de Disboard** (uno por día) y un rey de ajedrez |
| 🎞️ GIFs | Schwi abriendo los ojos en el menú de sesión y Riku con Schwi en el reproductor del dashboard |
| 🖼️ Wallpapers | Los de Schwi en Wallhaven |

Vídeo necesario: el PV oficial「映画『ノーゲーム・ノーライフ ゼロ』 PV 第2弾」de KADOKAWAanime (~90 s, 1080p).

Todo sigue los colores de Caelestia: al cambiar de wallpaper, el logo y la terminal cambian de color.

## Requisitos

- Arch Linux con [Caelestia](https://github.com/caelestia-dots/caelestia) (shell + CLI) y la shell `fish`.
- **Tu propia copia del vídeo** de cada tema. Este repositorio **no incluye** fotogramas, audio ni wallpapers:
  el instalador los genera en tu equipo a partir del vídeo y descarga los wallpapers al instalar.
- Para las animaciones: Plymouth con el hook en `mkinitcpio` y `quiet splash` en la línea del kernel (el instalador avisa si falta).
- Opcional: [`realesrgan-ncnn-vulkan-bin`](https://aur.archlinux.org/packages/realesrgan-ncnn-vulkan-bin) para mejorar la calidad de las animaciones con IA.

## Instalación

```fish
git clone https://github.com/CMarinBenavides/caelestia-themes
cd caelestia-themes
./install.sh gravity-falls "~/Downloads/Gravity Falls - Opening Theme Song.mp4"
./install.sh ngnl-zero "~/Downloads/NGNL Zero PV2.mp4"
```

Opciones: `--no-plymouth`, `--no-wallpapers`, `--no-activate` y `--reuse` (no vuelve a generar si ya existe).

Cambiar de tema regenera la imagen de arranque (pide `sudo`). Para cambiar solo la terminal y los wallpapers: `theme <nombre> --no-plymouth`.

Otros comandos: `decode` (solución de la frase cifrada) y `theme-sound` (silencia o reactiva los sonidos, ideal para reuniones).
`CAELESTIA_THEMES_NO_AI=1` evita usar Real-ESRGAN y `CAELESTIA_THEMES_VOLUME` (por defecto `0.2`) ajusta el volumen.

## Crear un tema nuevo

Cada tema es una carpeta en `themes/<nombre>/`:

| Archivo | Para qué |
|---|---|
| `theme.conf` | Nombre, emoji, duración esperada del vídeo, FPS, tamaño del logo, modo de las frases (`cipher` o `plain`), carpeta de wallpapers |
| `generate.sh` | Recibe el vídeo y una carpeta, y genera `plymouth/boot-*.png` (y `off-*.png` opcional), `message.png`, `message-goodbye.png`, `logo-mask.png`, `login.ogg`, y opcionalmente `shutdown.ogg`, `session.gif` y `media.gif` (los GIF del menú de sesión y del reproductor de Caelestia; los crea `make_gif`). Puede usar las funciones de `engine/lib.sh` |
| `banner.txt` | Título de la terminal (ASCII) |
| `quotes.txt` | Una frase por línea; una distinta cada día |
| `wallpapers.txt` | IDs de [Wallhaven](https://wallhaven.cc) |

El motor común (`engine/`) se encarga de Plymouth, del saludo de fish, de los sonidos y de los wallpapers.
Los comentarios del código están en español.

## Desinstalar

```fish
./uninstall.sh            # todo
./uninstall.sh ngnl-zero  # solo un tema
```

## Créditos

- *Gravity Falls* © Disney, creada por Alex Hirsch.
- *No Game No Life Zero* © Yuu Kamiya, KADOKAWA / NGNL Zero Production Committee.
- Proyecto de fans sin relación con los propietarios de las obras; no se distribuye material de las series.
- Wallpapers: sus autores en [Wallhaven](https://wallhaven.cc), descargados desde allí al instalar.
- [Caelestia](https://github.com/caelestia-dots) por soramane y colaboradores.

El código de este repositorio está bajo la licencia MIT.
