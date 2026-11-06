@echo off
setlocal
set "MYSQL=C:\xampp\mysql\bin\mysql.exe"

if not exist "%MYSQL%" (
  echo MySQL XAMPP introuvable: %MYSQL%
  echo Modifiez le chemin MYSQL dans run_etl.bat si XAMPP est installe ailleurs.
  exit /b 1
)

"%MYSQL%" --default-character-set=utf8mb4 -u root < "%~dp0bd_decision.sql"
if errorlevel 1 (
  echo Echec de la creation ou de la mise a niveau du schema source.
  exit /b 1
)

if /I "%~1"=="demo" (
  "%MYSQL%" --default-character-set=utf8mb4 -u root < "%~dp0donnees_demo.sql"
  if errorlevel 1 (
    echo Echec du chargement des donnees fictives.
    exit /b 1
  )
)

"%MYSQL%" --default-character-set=utf8mb4 -u root < "%~dp0entrepot_etl.sql"
if errorlevel 1 (
  echo Echec du chargement de l'entrepot.
  exit /b 1
)

if /I "%~1"=="demo" (
  echo ETL termine avec les donnees de demonstration fictives.
) else (
  echo ETL termine sur les donnees deja presentes dans la base source.
  echo Pour un nouveau jeu de demonstration local, utiliser: run_etl.bat demo
)
endlocal
