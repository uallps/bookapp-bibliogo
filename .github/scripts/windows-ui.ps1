# Prueba de interfaz en Windows: arranca la app, pulsa los controles y guarda
# capturas y la lista de controles en shots/.
# Los textos son controles Static (se buscan por texto); los botones con estilo
# los dibuja SwiftOpenUI (Direct2D). La ventana se coloca siempre en (0,0) con 900x700.
. "$PSScriptRoot/ui.ps1"
$bin = swift build --product BookApp --show-bin-path

function Count-Text([string]$text) { @(Get-Controls $w | Where-Object { $_.Text -eq $text }).Count }

# Clic en el botón de estado de una fila: el botón pequeño (24 px) a la izquierda del título.
function Click-Status([string]$title) {
    $c = Get-Controls $w | Where-Object { $_.Text -eq $title } | Select-Object -First 1
    if (-not $c) { throw "No hay una fila '$title'" }
    $b = Get-Controls $w | Where-Object { $_.Class -eq "SwiftUICustomButton" -and $_.W -le 32 -and $_.X -lt $c.X } |
        Sort-Object { [math]::Abs(($_.Y + $_.H / 2) - ($c.Y + $c.H / 2)) } | Select-Object -First 1
    if (-not $b) { throw "No hay botón de estado junto a '$title'" }
    Click-At ($b.X + [int]($b.W / 2)) ($b.Y + [int]($b.H / 2))
}

# Clic en una opción de la barra lateral: el texto más a la izquierda con ese nombre
# (el título de la pantalla también puede llamarse igual).
function Click-Sidebar([string]$text) {
    $c = Get-Controls $w | Where-Object { $_.Text -eq $text -or $_.Text -like "* $text" } |
        Sort-Object X | Select-Object -First 1
    if (-not $c) { return $false }
    Click-At ($c.X + [int]($c.W / 2)) ($c.Y + [int]($c.H / 2))
    return $true
}

$app = Start-App "$bin\BookApp.exe" "bookapp"
if ($app.HasExited) { throw "La app se ha cerrado al arrancar" }
$w = Get-AppWindow $app.Id
Snap $w "1-inicio"
if ((Count-Text "Dune") -ne 1) { throw "No se ve la lista de libros" }
if ((Count-Text "Pendiente") -ne 1) { throw "Al empezar debería haber un libro pendiente" }

# Cambiar el estado desde la fila (Pendiente → Leyendo) no abre el detalle.
Click-Status "Dune"; Snap $w "2-dune-leyendo"
if ((Count-Text "Dune") -ne 1) { throw "Al cambiar el estado se ha salido de la lista" }
if ((Count-Text "Pendiente") -ne 0) { throw "Dune debería haber pasado a Leyendo" }

# Detalle: editar el título y volver a la lista.
if (-not (Click-Text $w "Klara y el Sol")) { throw "No está la fila Klara y el Sol" }
Snap $w "3-detalle"
if (-not (Click-Class $w "Edit")) { throw "El detalle no tiene campo de título" }
Send-Text "{END} ilustrado"; Snap $w "4-detalle-editado"
if (-not (Click-Class $w "Edit")) { throw "Al escribir se ha salido del detalle" }
if (-not (Click-Text $w "← Back")) { if (-not (Click-Text $w "Back")) { throw "No hay botón para volver" } }
Snap $w "5-lista-tras-volver"
if ((Count-Text "Klara y el Sol ilustrado") -ne 1) { throw "La lista no muestra el título editado" }

# Ajustes: ocultar los autores y comprobarlo en la lista.
if ((Count-Text "Frank Herbert") -ne 1) { throw "Al empezar debería verse el autor" }
if (-not (Click-Sidebar "Ajustes")) { throw "No está Ajustes en la barra lateral" }
Snap $w "6-ajustes"
if (-not (Click-Text $w "Mostrar autores")) { throw "No está el ajuste de autores" }
Snap $w "7-sin-autores"
if (-not (Click-Sidebar "Biblioteca")) { throw "No está Biblioteca en la barra lateral" }
Snap $w "8-biblioteca-sin-autores"
if ((Count-Text "Frank Herbert") -ne 0) { throw "Con el ajuste apagado no debería verse ningún autor" }

# Al volver a abrir se conservan los libros, su estado y los ajustes.
Stop-Process -Id $app.Id -Force; Start-Sleep -Seconds 2
$app = Start-App "$bin\BookApp.exe" "bookapp2"
if ($app.HasExited) { throw "La app se ha cerrado al volver a abrirla" }
$w = Get-AppWindow $app.Id
Snap $w "9-tras-reiniciar"
if ((Count-Text "Klara y el Sol ilustrado") -ne 1) { throw "No se ha conservado el título editado" }
if ((Count-Text "Pendiente") -ne 0) { throw "No se ha conservado el estado de Dune" }
if ((Count-Text "Frank Herbert") -ne 0) { throw "No se ha conservado el ajuste de autores" }

Stop-Process -Id $app.Id -Force
Write-Host "Prueba de Windows superada"
