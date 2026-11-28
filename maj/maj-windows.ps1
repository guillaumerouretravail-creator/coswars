# Coswars (Windows) : mise à jour automatique, lancée par « Lancer Coswars » avant chaque partie.
#   maj-windows.ps1 -Src <jeu du dossier téléchargé> -Dst <jeu installé> [-Watch]
# 0. (16/11) Se met à jour lui-même : la dernière version de ce script est publiée sur le site (maj/maj-windows.ps1) ; si elle
#    diffère, elle est gardée dans %LOCALAPPDATA%\Coswars et c'est elle qui fait le travail. Plus besoin de retélécharger le jeu
#    pour corriger la mise à jour.
# 1. (16/11) Ferme la partie déjà ouverte (Chrome ou Edge avec le profil de Coswars) : sinon le navigateur garde des fichiers du
#    jeu ouverts, leur remplacement échoue et le jeu repart toujours dans l'ancienne version.
# 2. Installe le jeu du dossier téléchargé s'il est plus récent que celui déjà installé.
# 3. Regarde sur le site si une version plus récente existe (liste maj/fichiers.txt publiée par deploy-web.sh) ;
#    si oui, télécharge seulement les fichiers qui ont changé, les vérifie, puis les met en place.
# 4. (16/11) Lance un veilleur caché qui refait l'étape 3 toutes les 2 minutes tant que le jeu est ouvert : le jeu voit la
#    nouvelle version (version.txt) et redémarre tout seul dès qu'on est dans les menus.
# Sans internet, ou si un téléchargement échoue, on garde la copie installée : le jeu se lance quand même.
param([string]$Src, [string]$Dst, [switch]$Watch)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # sinon les téléchargements sont très lents (Windows PowerShell 5.1)
$Base = 'https://guillaumerouretravail-creator.github.io/coswars/'
$Base2 = 'https://coswars.com/jeu/'   # 09/11 : secours (panne de GitHub) ; la liste la plus récente gagne
$Sup = Join-Path $env:LOCALAPPDATA 'Coswars'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
function V($s) { try { [version]$s } catch { [version]'0.0' } }
function VersionOf($d) { $f = Join-Path $d 'version.txt'; if (Test-Path $f) { (Get-Content $f -Raw).Trim() } else { '0.0' } }
function Sha($f) { (Get-FileHash $f -Algorithm SHA1).Hash.ToLower() }
function Say($t) { try { Add-Type -AssemblyName System.Speech; $s = New-Object System.Speech.Synthesis.SpeechSynthesizer; $s.Speak($t) } catch {} }
function Stamp { [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() }
function GameProcs { try { @(Get-CimInstance Win32_Process -Filter "Name='chrome.exe' OR Name='msedge.exe'" | Where-Object { $_.CommandLine -and $_.CommandLine -like '*Coswars\profil*' }) } catch { @() } }

# 0. ce script lui-même
if (-not $env:COSWARS_MAJ_CHAIN) {
  try {
    New-Item -ItemType Directory -Force -Path $Sup | Out-Null
    $new = Join-Path $Sup 'maj-windows.new.ps1'; $mine = Join-Path $Sup 'maj-windows.ps1'; $got = $false
    foreach ($b in @($Base, $Base2)) { try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 6 -Uri ($b + 'maj/maj-windows.ps1?t=' + (Stamp)) -OutFile $new; $got = $true; break } catch {} }
    if ($got -and (Select-String -Path $new -Pattern 'COSWARS-MAJ-FIN' -Quiet) -and ((Sha $new) -ne (Sha $PSCommandPath))) {
      Move-Item $new $mine -Force; $env:COSWARS_MAJ_CHAIN = '1'
      $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $mine, '-Src', $Src, '-Dst', $Dst); if ($Watch) { $a += '-Watch' }
      & powershell @a; exit 0
    }
    Remove-Item $new -Force -ErrorAction SilentlyContinue
  } catch {}
}

# 16/11 : ce script se garde toujours dans %LOCALAPPDATA%\Coswars : le lanceur l'y retrouve, même copié sur le Bureau
try { $keep = Join-Path $Sup 'maj-windows.ps1'; if ($PSCommandPath -and ($PSCommandPath -ne $keep)) { New-Item -ItemType Directory -Force -Path $Sup | Out-Null; Copy-Item $PSCommandPath $keep -Force } } catch {}
function Update([bool]$quiet) {
  try {
    $inst = VersionOf $Dst
    function GetList($b) { try { $x = (Invoke-WebRequest -UseBasicParsing -TimeoutSec 6 -Uri ($b + 'maj/fichiers.txt?t=' + (Stamp))).Content
      if ($x -is [byte[]]) { $x = [Text.Encoding]::UTF8.GetString($x) }; $x } catch { $null } }
    function VerOf($x) { (($x -split "`n" | Where-Object { $_ -like "version`t*" } | Select-Object -First 1) -replace "^version`t", '').Trim() }
    $B = $Base; $Alt = $Base2; $L = GetList $Base; $L2 = GetList $Base2
    if ($L2 -and (-not $L -or (V (VerOf $L2)) -gt (V (VerOf $L)))) { $L = $L2; $Alt = $Base; $B = $Base2 }
    if (-not $L) { return }
    $lines = $L -split "`n" | ForEach-Object { $_.TrimEnd("`r") } | Where-Object { $_ }
    $ver = VerOf $L
    if (-not $ver -or (V $ver) -le (V $inst)) { return }
    if (-not $quiet) { Write-Host "Mise à jour de Coswars, version $ver..."; Say "Mise à jour de Coswars, version $ver. Un instant." }
    $tmp = Join-Path $env:TEMP ('coswars-maj-' + [guid]::NewGuid())
    $todo = @()
    foreach ($l in $lines) {
      $c = $l -split "`t"
      if ($c[0] -eq 'version' -or $c.Count -lt 3) { continue }
      $f = Join-Path $Dst ($c[1] -replace '/', '\')
      if ((Test-Path $f) -and ((Sha $f) -eq $c[0])) { continue }
      $t = Join-Path $tmp ($c[1] -replace '/', '\')
      New-Item -ItemType Directory -Force -Path (Split-Path $t) | Out-Null
      $ok = $false
      foreach ($b in @($B, $Alt)) { try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 120 -Uri ($b + $c[2]) -OutFile $t; if ((Sha $t) -eq $c[0]) { $ok = $true; break } } catch {} }
      if (-not $ok) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue; return }
      $todo += , @($t, $f)
    }
    # index.html en dernier : le jeu ne redémarre qu'une fois tous les sons en place ; un fichier encore ouvert est réessayé
    $todo = @($todo | Where-Object { $_[1] -notlike '*\index.html' }) + @($todo | Where-Object { $_[1] -like '*\index.html' })
    foreach ($p in $todo) { New-Item -ItemType Directory -Force -Path (Split-Path $p[1]) | Out-Null
      $done = $false; for ($k = 0; $k -lt 10 -and -not $done; $k++) { try { Move-Item $p[0] $p[1] -Force; $done = $true } catch { Start-Sleep -Milliseconds 500 } }
      if (-not $done) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue; return } }
    Set-Content (Join-Path $Dst 'version.txt') $ver -Encoding ASCII
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  } catch {}
}

if ($Watch) {
  for ($i = 0; $i -lt 60 -and (GameProcs).Count -eq 0; $i++) { Start-Sleep -Seconds 1 }
  while ((GameProcs).Count -gt 0) { Start-Sleep -Seconds 120; if ((GameProcs).Count -eq 0) { break }; Update $true }
  exit 0
}

# 1. partie déjà ouverte : fermée (comme sur Mac), pour pouvoir remplacer les fichiers du jeu
$open = GameProcs
if ($open.Count) { foreach ($p in $open) { try { Stop-Process -Id $p.ProcessId -Force } catch {} }; Start-Sleep -Seconds 2 }
# veilleurs d'une partie précédente
try { Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -like '*maj-windows*-Watch*' -and $_.ProcessId -ne $PID } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force } } catch {}

# 2. jeu du dossier téléchargé plus récent que la copie installée
try {
  $inst = VersionOf $Dst; $app = VersionOf $Src
  if ($Src -and (Test-Path (Join-Path $Src 'index.html')) -and ((Resolve-Path $Src).Path -ne (Resolve-Path $Dst -ErrorAction SilentlyContinue).Path) -and (-not (Test-Path (Join-Path $Dst 'index.html')) -or (V $app) -gt (V $inst))) {
    if (Test-Path $Dst) { Remove-Item $Dst -Recurse -Force }
    New-Item -ItemType Directory -Force -Path (Split-Path $Dst) | Out-Null
    Copy-Item $Src $Dst -Recurse -Force
  }
} catch {}
# 3. version publiée
Update $false
# 5. (16/11) raccourci « Coswars » sur le Bureau, avec l'icône du jeu, comme un vrai jeu : le lanceur et l'icône sont gardés dans
#    %LOCALAPPDATA%\Coswars (repris du site à chaque lancement, sinon du dossier téléchargé) ; le raccourci est créé une fois
#    (s'il est supprimé ensuite, il n'est pas remis)
try {
  $bat = Join-Path $Sup 'Lancer Coswars.bat'; $ico = Join-Path $Sup 'coswars.ico'; $here = if ($Src) { Split-Path $Src } else { $null }
  foreach ($f in @(@('maj/lancer-coswars.bat', $bat, 'Lancer Coswars.bat'), @('maj/coswars.ico', $ico, 'coswars.ico'))) { $ok = $false
    foreach ($b in @($Base, $Base2)) { try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 8 -Uri ($b + $f[0] + '?t=' + (Stamp)) -OutFile ($f[1] + '.new'); Move-Item ($f[1] + '.new') $f[1] -Force; $ok = $true; break } catch {} }
    if (-not $ok -and $here -and (Test-Path (Join-Path $here $f[2])) -and -not (Test-Path $f[1])) { Copy-Item (Join-Path $here $f[2]) $f[1] -Force } }
  $mark = Join-Path $Sup 'raccourci-bureau.txt'
  if ((Test-Path $bat) -and -not (Test-Path $mark)) {
    $desk = [Environment]::GetFolderPath('Desktop'); $w = New-Object -ComObject WScript.Shell; $lnk = $w.CreateShortcut((Join-Path $desk 'Coswars.lnk'))
    $lnk.TargetPath = $bat; $lnk.WorkingDirectory = $Sup; $lnk.WindowStyle = 7; $lnk.Description = 'Coswars'; if (Test-Path $ico) { $lnk.IconLocation = "$ico,0" }; $lnk.Save()
    Set-Content $mark (Get-Date -Format s) -Encoding ASCII }
} catch {}
# 4. veilleur caché
try { Start-Process powershell -WindowStyle Hidden -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"", '-Src', "`"$Src`"", '-Dst', "`"$Dst`"", '-Watch') } catch {}
exit 0
# COSWARS-MAJ-FIN (repère : le script téléchargé est complet)
