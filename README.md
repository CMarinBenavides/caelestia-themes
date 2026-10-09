# ✨ Caelestia Themes

Temas de series y películas para [Caelestia](https://github.com/caelestia-dots/shell) en Arch Linux + Hyprland.
Cada tema cambia la **animación de arranque y apagado**, los **sonidos**, el **saludo de la terminal** y los **wallpapers**,
y con un solo comando cambias entre temas o vuelves a Caelestia original.

```fish
tema lista            # temas instalados
tema gravity-falls    # 🌲🔺 Caelestia Falls
tema ngnl-zero        # 🎲♟️ Caelestia Zero
tema normal           # ✨ Caelestia original
```

## Temas

### 🌲🔺 Caelestia Falls — *Gravity Falls*

| Momento | |
|---|---|
| 🎩 Arranque | El Tío Stan aparece en un destello frente a la Cabaña del Misterio y se queda en el letrero *"MYSTERY HACK"* con `YRVMEVMRWL HGZMULIW` |
| 👋 Apagado | El letrero con `SZHGZ OFVTL HGZMOVB` |
| 🔺 Al iniciar sesión | El susurro invertido de Bill Cipher del final de la intro |
| 🖥️ Terminal | Título *Caelestia Falls*, un **criptograma del día** (Atbash, César +3 o A1Z26; `descifrar` para la solución) y la silueta de Bill |
| 🖼️ Wallpapers | ~44 de Wallhaven |

Vídeo necesario: la intro oficial *Gravity Falls Opening Theme Song* (~39 s).

### 🎲♟️ Caelestia Zero — *No Game No Life Zero*

| Momento | |
|---|---|
| 🎬 Arranque | Una mano en la oscuridad → Riku → el cielo rojo de Disboard, con **【 ゲーム開始 】** · *que empiece el juego* |
| 🔮 Apagado | La cueva de cristales, con **【 ASCHENTE 】** · *lo juro por el pacto* |
| 🔊 Sonidos | 「ゲームを始めよう」 al entrar y 「アッシェンテ」 al apagar o reiniciar |
| 🖥️ Terminal | Título *Caelestia Zero*, **los diez pactos de Disboard** (uno por día) y un rey de ajedrez |
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

Opciones: `--sin-plymouth`, `--sin-wallpapers`, `--sin-activar` y `--reusar` (no vuelve a generar si ya existe).

Cambiar de tema regenera la imagen de arranque (pide `sudo`). Para cambiar solo la terminal y los wallpapers: `tema <nombre> --sin-plymouth`.

Otros comandos: `descifrar` (solución de la frase cifrada) y `sonido-inicio` (silencia los sonidos, ideal para reuniones).

## Crear un tema nuevo

Cada tema es una carpeta en `themes/<nombre>/`:

| Archivo | Para qué |
|---|---|
| `tema.conf` | Nombre, emoji, duración esperada del vídeo, FPS, tamaño del logo, modo de las frases, carpeta de wallpapers |
| `generar.sh` | Recibe el vídeo y una carpeta, y genera `plymouth/boot-*.png` (y `off-*.png` opcional), `mensaje.png`, `mensaje-adios.png`, `logo-mask.png`, `entrada.ogg` y `apagado.ogg` opcional. Puede usar las funciones de `motor/lib.sh` |
| `banner.txt` | Título de la terminal (ASCII) |
| `frases.txt` | Una frase por línea; una distinta cada día |
| `wallpapers.txt` | IDs de [Wallhaven](https://wallhaven.cc) |

El motor común (`motor/`) se encarga de Plymouth, del saludo de fish, de los sonidos y de los wallpapers.

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
