@ECHO OFF
SETLOCAL
>nul 2>&1 chcp 1252
pushd "%~dp0"

SET /A _errNo=0
SET "_pkgId=JohnMacFarlane.Pandoc"
SET "_verb=install"

IF EXIST "github-markdown.html" GOTO end_htmlcheck
  ECHO ERROR:  The template "github-markdown.html" not found in "%CD%".
  SET /A _errNo=1
  GOTO exitPgm
:end_htmlcheck

::Detect installation by matching the exact ID in winget's installed list;
::findstr sets ERRORLEVEL 0 when the Id is present, 1 when it is absent
ECHO Installing/upgrading pandoc . . .
winget list --exact --id %_pkgId% --source winget --scope machine --accept-source-agreements --disable-interactivity | findstr /I /C:"%_pkgId%" >nul
IF NOT ERRORLEVEL 1 SET "_verb=upgrade"
winget %_verb% --exact --id %_pkgId% --source winget --scope machine --accept-source-agreements --accept-package-agreements --silent

:Get latest version of CSS
ECHO Fetching latest CSS . . .
>nul 2>&1 del github-markdown.css.tmp
curl --silent --output github-markdown.css.tmp https://raw.githubusercontent.com/sindresorhus/github-markdown-css/main/github-markdown.css
IF EXIST github-markdown.css.tmp move /Y github-markdown.css.tmp github-markdown.css

:Installing GitHub CSS and template
ECHO Installing CSS and template for use with pandoc . . .
>nul 2>&1 md "%APPDATA%\pandoc"
>nul 2>&1 md "%APPDATA%\pandoc\templates"
copy /Y github-markdown.css "%APPDATA%\pandoc\*"
copy /Y github-markdown-print.html "%APPDATA%\pandoc\*"
copy /Y github-markdown.html "%APPDATA%\pandoc\templates\*"

:Testing markdown to GFM HTML . . .
ECHO Testing conversion of markdown to GFM HTML . . .
>nul 2>&1 md "temp"
CD temp
>nul 2>&1 copy /Y "..\README.md"
>nul 2>&1 del "README.html"
ECHO   Example usage: pandoc --from gfm --to html5 --standalone --embed-resources --mathjax --template github-markdown.html --css "%%APPDATA%%\pandoc\github-markdown.css" --syntax-highlighting tango --metadata title="Pandoc - README" --output README.html README.md
pandoc --from gfm --to html5 --standalone --embed-resources --mathjax --template github-markdown.html --css "%APPDATA%\pandoc\github-markdown.css" --syntax-highlighting tango --metadata title="Pandoc - README" --output README.html README.md
IF NOT EXIST README.html ECHO ERROR: README.html not created; pandoc setup failed.&SET /A _errNo=2
IF EXIST README.html ".\README.html"
ECHO   Giving browser time to load document . . . 
timeout /T 5
ECHO   Cleaning up test conversion . . . 
CD ..
>nul 2>&1 RD /S /Q temp

:exitPgm
popd
ENDLOCAL&EXIT /B %_errNo%
