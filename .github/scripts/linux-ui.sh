#!/bin/bash
# Prueba de humo en Linux: pantalla virtual (Xvfb), arranque de la app y capturas en shots/.
# A diferencia del script de TaskApp no pulsa por coordenadas (dependen del diseño de
# la ventana); la prueba con clics está en windows-ui.ps1, que busca los controles por texto.
#   linux-ui.sh            producto base
#   linux-ui.sh Progreso   producto con el trait Progreso
set -u
VARIANT=${1:-base}
OUT=shots/$VARIANT
mkdir -p "$OUT"
export DISPLAY=:99 GDK_BACKEND=x11 GSK_RENDERER=cairo LANG=C.UTF-8 LC_ALL=C.UTF-8
pgrep -x Xvfb >/dev/null || { Xvfb :99 -screen 0 1280x800x24 2>/dev/null & sleep 2; }

TRAITS=()
[ "$VARIANT" != base ] && TRAITS=(--traits "$VARIANT")
swift build --product BookApp "${TRAITS[@]}" || exit 1
BIN="$(swift build --product BookApp "${TRAITS[@]}" --show-bin-path)/BookApp"

# Empezar sin datos guardados: libros y progreso (JSON) y ajustes (UserDefaults).
rm -f ~/Documents/books.json ~/Documents/progress.json ~/.config/BookApp.plist

start() { "$BIN" > "$OUT/app.log" 2>&1 & APP=$!; sleep 5; }
shot()  { import -window root "$OUT/$1.png"; echo "captura: $OUT/$1.png"; }
alive() { kill -0 $APP 2>/dev/null || { echo "La app se ha cerrado"; cat "$OUT/app.log"; exit 1; }; }

start; alive; shot 1-inicio
sleep 2; alive
kill $APP; sleep 1

# Se vuelve a abrir para comprobar que arranca con los datos ya guardados.
start; alive; shot 2-tras-reiniciar
kill $APP
