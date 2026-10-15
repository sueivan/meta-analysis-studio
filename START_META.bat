@echo off
cd /d "%~dp0"
where Rscript >nul 2>nul
if errorlevel 1 (
 echo Rscript not found. Add R bin to PATH or launch START_META_WITH_R_PATH.bat after editing it.
 pause
 exit /b 1
)
Rscript -e "p<-c('shiny','metafor'); missing<-p[!vapply(p,requireNamespace,logical(1),quietly=TRUE)]; if(length(missing))install.packages(missing,repos='https://cloud.r-project.org'); shiny::runApp('.',launch.browser=TRUE,host='127.0.0.1',port=3838)"
pause
