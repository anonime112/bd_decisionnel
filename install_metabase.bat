@echo off
setlocal
set "INSTALL_DIR=%LOCALAPPDATA%\Metabase"
set "JAR=%INSTALL_DIR%\metabase.jar"
set "SOURCE=%~dp0metabase.jar"
if not defined METABASE_VERSION set "METABASE_VERSION=latest"

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

if exist "%JAR%" (
  echo Metabase est deja installe: %JAR%
  exit /b 0
)

if exist "%SOURCE%" (
  echo Copie du JAR existant hors du projet...
  copy /Y "%SOURCE%" "%JAR%" >nul
  if errorlevel 1 exit /b 1
  echo JAR installe: %JAR%
  echo L'original pourra etre supprime apres l'arret de Metabase.
  exit /b 0
)

echo Telechargement de Metabase %METABASE_VERSION%...
set "METABASE_INSTALL_JAR=%JAR%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri ('https://downloads.metabase.com/' + $env:METABASE_VERSION + '/metabase.jar') -OutFile $env:METABASE_INSTALL_JAR"
if errorlevel 1 (
  echo Echec du telechargement. Verifiez votre connexion Internet et relancez ce script.
  exit /b 1
)

if not exist "%JAR%" (
  echo Le telechargement n'a pas produit le fichier attendu: %JAR%
  exit /b 1
)

echo JAR installe: %JAR%
endlocal