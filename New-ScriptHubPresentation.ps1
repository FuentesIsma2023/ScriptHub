$ErrorActionPreference = 'Stop'

$output = Join-Path $PSScriptRoot 'ScriptHub-Presentacion.pptx'
$msoTrue = -1
$msoFalse = 0
$powerPoint = New-Object -ComObject PowerPoint.Application
$powerPoint.Visible = $msoTrue
$presentation = $powerPoint.Presentations.Add()

$ppLayoutTitle = 1
$ppLayoutText = 2
$ppLayoutTitleOnly = 11
$ppSaveAsOpenXML = 24
function Add-Title {
    param($Slide, [string]$Title, [string]$Subtitle = '')
    $Slide.Shapes.Title.TextFrame.TextRange.Text = $Title
    $Slide.Shapes.Title.TextFrame.TextRange.Font.Name = 'Aptos Display'
    $Slide.Shapes.Title.TextFrame.TextRange.Font.Size = 30
    $Slide.Shapes.Title.TextFrame.TextRange.Font.Bold = $msoTrue
    $Slide.Shapes.Title.TextFrame.TextRange.Font.Color.RGB = 0x0F3557
    if ($Subtitle -ne '') {
        $box = $Slide.Shapes.AddTextbox(1, 45, 100, 620, 45)
        $box.TextFrame.TextRange.Text = $Subtitle
        $box.TextFrame.TextRange.Font.Name = 'Aptos'
        $box.TextFrame.TextRange.Font.Size = 16
        $box.TextFrame.TextRange.Font.Color.RGB = 0x5F6368
    }
}

function Add-Bullets {
    param($Slide, [string[]]$Items)
    $body = $Slide.Shapes.Placeholders.Item(2)
    $body.TextFrame.TextRange.Text = ($Items -join "`r")
    $body.TextFrame.TextRange.Font.Name = 'Aptos'
    $body.TextFrame.TextRange.Font.Size = 22
    $body.TextFrame.TextRange.Font.Color.RGB = 0x202124
    foreach ($paragraph in $body.TextFrame.TextRange.Paragraphs()) {
        $paragraph.ParagraphFormat.Bullet.Visible = $msoTrue
    }
}

function Add-Footer {
    param($Slide, [int]$Number)
    $line = $Slide.Shapes.AddShape(1, 0, 505, 720, 2)
    $line.Fill.ForeColor.RGB = 0x0078D4
    $line.Line.Visible = $msoFalse
    $footer = $Slide.Shapes.AddTextbox(1, 45, 515, 620, 20)
    $footer.TextFrame.TextRange.Text = "ScriptHub 4.0  |  $Number"
    $footer.TextFrame.TextRange.Font.Name = 'Aptos'
    $footer.TextFrame.TextRange.Font.Size = 9
    $footer.TextFrame.TextRange.Font.Color.RGB = 0x6B7280
}

function Set-Background {
    param($Slide)
    $Slide.FollowMasterBackground = $msoFalse
    $Slide.Background.Fill.ForeColor.RGB = 0xF5F7FA
}

$slide = $presentation.Slides.Add(1, $ppLayoutTitle)
Set-Background $slide
$slide.Shapes.Title.TextFrame.TextRange.Text = 'ScriptHub'
$slide.Shapes.Title.TextFrame.TextRange.Font.Name = 'Aptos Display'
$slide.Shapes.Title.TextFrame.TextRange.Font.Size = 44
$slide.Shapes.Title.TextFrame.TextRange.Font.Bold = $msoTrue
$slide.Shapes.Title.TextFrame.TextRange.Font.Color.RGB = 0x0F3557
$slide.Shapes.Placeholders.Item(2).TextFrame.TextRange.Text = 'Un HUB centralizado para encontrar, compartir y ejecutar scripts'
$slide.Shapes.Placeholders.Item(2).TextFrame.TextRange.Font.Name = 'Aptos'
$slide.Shapes.Placeholders.Item(2).TextFrame.TextRange.Font.Size = 24
$slide.Shapes.Placeholders.Item(2).TextFrame.TextRange.Font.Color.RGB = 0x0078D4
Add-Footer $slide 1

$slide = $presentation.Slides.Add(2, $ppLayoutText)
Set-Background $slide
Add-Title $slide 'El problema'
Add-Bullets $slide @(
    'Los scripts estan dispersos en chats, correos y carpetas personales.'
    'Encontrar el script correcto consume tiempo.'
    'No siempre conocemos sus dependencias o version de PowerShell.'
    'Se duplican esfuerzos entre equipos.'
)
Add-Footer $slide 2

$slide = $presentation.Slides.Add(3, $ppLayoutText)
Set-Background $slide
Add-Title $slide 'La solucion: ScriptHub'
Add-Bullets $slide @(
    'Catalogo centralizado y organizado de scripts.'
    'Busqueda por nombre, categoria, equipo y version.'
    'Informacion clara sobre dependencias y requisitos.'
    'Un punto comun para compartir conocimiento entre equipos.'
)
Add-Footer $slide 3

$slide = $presentation.Slides.Add(4, $ppLayoutText)
Set-Background $slide
Add-Title $slide 'Como funciona'
Add-Bullets $slide @(
    'Seleccionamos un script del catalogo.'
    'ScriptHub detecta los modulos requeridos.'
    'Muestra si las dependencias estan instaladas.'
    'Completa automaticamente los parametros necesarios.'
    'Ejecuta el script con PowerShell 5.1 o 7 segun corresponda.'
)
Add-Footer $slide 4

$slide = $presentation.Slides.Add(5, $ppLayoutText)
Set-Background $slide
Add-Title $slide 'Beneficios'
Add-Bullets $slide @(
    'Ahorro de tiempo en la busqueda y preparacion.'
    'Menos errores por dependencias faltantes.'
    'Soluciones reutilizables y faciles de mantener.'
    'Colaboracion entre SharePoint, Exchange, Teams, Azure y Entra ID.'
    'Conocimiento compartido que no depende de una sola persona.'
)
Add-Footer $slide 5

$slide = $presentation.Slides.Add(6, $ppLayoutText)
Set-Background $slide
Add-Title $slide 'Siguiente paso'
Add-Bullets $slide @(
    'Cada equipo puede aportar sus scripts validados.'
    'El catalogo se revisa antes de publicarse.'
    'Las entradas deben incluir dependencias, version y advertencias.'
    'Objetivo: convertir ScriptHub en el repositorio comun de automatizacion.'
)
Add-Footer $slide 6

$presentation.SaveAs($output, $ppSaveAsOpenXML)
$presentation.Close()
$powerPoint.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($presentation) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($powerPoint) | Out-Null
Write-Output $output