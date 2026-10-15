@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
set "RSCRIPT="
for /f "delims=" %%I in ('where Rscript.exe 2^>nul') do if not defined RSCRIPT set "RSCRIPT=%%I"
if not defined RSCRIPT (
 for /d %%D in ("C:\Program Files\R\R-*") do (
  if exist "%%~fD\bin\Rscript.exe" set "RSCRIPT=%%~fD\bin\Rscript.exe"
  if exist "%%~fD\bin\x64\Rscript.exe" set "RSCRIPT=%%~fD\bin\x64\Rscript.exe"
 )
)
if not defined RSCRIPT (
 echo Rscript.exe not found. Please enter full path to Rscript.exe:
 set /p "RSCRIPT=Path: "
)
if not exist "%RSCRIPT%" (echo Cannot find Rscript.exe & pause & exit /b 1)
echo Using "%RSCRIPT%"
"%RSCRIPT%" -e "pkgs <- c('shiny','metafor','readxl'); missing <- pkgs[!vapply(pkgs,requireNamespace,logical(1),quietly=TRUE)]; if(length(missing)) install.packages(missing,repos='https://cloud.r-project.org'); shiny::runApp('.',launch.browser=TRUE)"
if errorlevel 1 (echo R app failed. Please screenshot the error above. & pause)
