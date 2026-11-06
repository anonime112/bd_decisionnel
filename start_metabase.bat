@echo off
setlocal
set "JAVA="
if defined JAVA_HOME if exist "%JAVA_HOME%\bin\java.exe" set "JAVA=%JAVA_HOME%\bin\java.exe"
if not defined JAVA (
  where java >nul 2>nul
  if errorlevel 1 (
    echo Java introuvable. Installez Java 21 ou plus recent et configurez JAVA_HOME ou PATH.
    exit /b 1
  )
  set "JAVA=java"
)
set "JAR=%LOCALAPPDATA%\Metabase\metabase.jar"
set "MB_JETTY_HOST=127.0.0.1"
set "MB_JETTY_PORT=3000"
set "MB_DB_FILE=%LOCALAPPDATA%\Metabase\metabase.db"

if not exist "%JAR%" (
  echo JAR Metabase introuvable: %JAR%
  echo Lancez install_metabase.bat pour l'installer hors du depot Git.
  exit /b 1
)

if not exist "%LOCALAPPDATA%\Metabase" mkdir "%LOCALAPPDATA%\Metabase"

echo Demarrage de Metabase sur http://127.0.0.1:%MB_JETTY_PORT%
echo Donnees Metabase: %MB_DB_FILE%
echo Gardez cette fenetre ouverte pendant l'utilisation.
"%JAVA%" -Xms512m -Xmx2g -jar "%JAR%"
endlocal