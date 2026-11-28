@echo off
chcp 65001 >nul
rem Coswars (Launch Coswars / Lancer Coswars) : ouvre le jeu en plein écran dans Google Chrome (sinon Microsoft Edge).
rem Le jeu est installé dans %LOCALAPPDATA%\Coswars et se met à jour tout seul depuis le site ; la progression y est gardée.
setlocal
set "ICI=%~dp0"
set "BASE=%LOCALAPPDATA%\Coswars"
set "NAV="
for %%P in ("%ProgramFiles%\Google\Chrome\Application\chrome.exe" "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe") do (
  if not defined NAV if exist "%%~P" set "NAV=%%~P"
)
if not defined NAV (
  echo Coswars needs Google Chrome or Microsoft Edge. Install Chrome from google.com/chrome, then run "Launch Coswars" again.
  echo Coswars a besoin de Google Chrome ou de Microsoft Edge. Installez Chrome depuis google.com/chrome, puis relancez « Lancer Coswars ».
  echo Coswars necesita Google Chrome o Microsoft Edge. Instale Chrome desde google.com/chrome y vuelva a abrir "Launch Coswars".
  pause
  exit /b 1
)
if not exist "%BASE%" mkdir "%BASE%"
rem 16/11 : ce lanceur marche où qu'il soit (copié sur le Bureau, sorti de son dossier) : il prend le script de mise à jour
rem gardé dans %BASE% (toujours le plus récent), sinon celui posé à côté de lui, sinon il le télécharge sur le site
set "MAJ=%BASE%\maj-windows.ps1"
if not exist "%MAJ%" if exist "%ICI%maj-windows.ps1" copy /y "%ICI%maj-windows.ps1" "%MAJ%" >nul
if not exist "%MAJ%" powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; foreach($b in 'https://guillaumerouretravail-creator.github.io/coswars/','https://coswars.com/jeu/'){try{Invoke-WebRequest -UseBasicParsing -TimeoutSec 20 -Uri ($b+'maj/maj-windows.ps1') -OutFile $env:MAJ; break}catch{}}"
set "SRCJ=%ICI%jeu"
if not exist "%SRCJ%\index.html" set "SRCJ=%BASE%\jeu"
rem installe le jeu, puis le met à jour depuis le site s'il existe une version plus récente (sans internet : copie déjà installée)
if exist "%MAJ%" powershell -NoProfile -ExecutionPolicy Bypass -File "%MAJ%" -Src "%SRCJ%" -Dst "%BASE%\jeu"
if not exist "%BASE%\jeu\index.html" if exist "%ICI%jeu\index.html" robocopy "%ICI%jeu" "%BASE%\jeu" /MIR /NFL /NDL /NJH /NJS /NP >nul
set "URL=file:///%BASE:\=/%/jeu/index.html"
start "" "%NAV%" --user-data-dir="%BASE%\profil" --kiosk --app="%URL%" --allow-file-access-from-files --use-fake-ui-for-media-stream --autoplay-policy=no-user-gesture-required --no-first-run --no-default-browser-check --disable-session-crashed-bubble --disable-translate --overscroll-history-navigation=0
