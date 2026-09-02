@ECHO OFF
SETLOCAL EnableExtensions
>nul 2>&1 chcp 1252
REM ============================================================================
REM  md2pdf.cmd
REM
REM  Converts a GitHub-Flavored Markdown (.md) file to a standalone, self-
REM  contained PDF document using pandoc and the github-markdown template.
REM
REM  Usage:
REM      md2pdf.cmd -Path "path\to\file.md" [-Title "Document Title"]
REM
REM  Parameters:
REM      -Path   (required) Full or relative path to the source .md file.
REM      -Title  (optional) Title of the document.  When omitted, the
REM              source file's base name (without extension) is used.
REM
REM  Output:
REM      An .pdf file written beside the source, with the .md extension
REM      replaced by .pdf
REM      (e.g. C:\Dir1\Dir2\mymarkdown.md -> C:\Dir1\Dir2\mymarkdown.pdf).
REM
REM  Exit codes:
REM      0  Success.
REM      1  Missing -Path parameter or source file not found.
REM      *  Any other value is passed through from pandoc.
REM
REM  ---------------------------------------------------------------------
REM  TWO THINGS ABOUT THE PANDOC CALL ARE LOAD BEARING.
REM
REM  --to html5 selects the route, not the output.  The .pdf extension on
REM   --output is what makes pandoc produce a PDF; --to html5 is what makes
REM   it get there through HTML and an HTML engine rather than through
REM   LaTeX.  Remove it and pandoc reaches for pdflatex, which fails on the
REM   HTML in --include-in-header with "Missing \begin{document}".
REM
REM  --pdf-engine weasyprint names what pandoc would otherwise pick for
REM   itself.  It already chose weasyprint here; naming it means the render
REM   cannot change because something else appeared on the PATH.
REM
REM  github-markdown-print.html supplies the @page rule the GitHub
REM   stylesheet has none of, and undoes the 980px column and 45px padding
REM   the template uses on screen.  Without it the output is A4 with no page
REM   numbers and about a fifth of each page wasted.
REM ============================================================================

REM Assume a failure
SET "_exitCode=1"

REM Source markdown path, populated from the -Path parameter
SET "_mdPath="

REM PDF document title, populated from the optional -Title parameter
SET "_title="

REM Set CSS Path and URI
SET "_cssPath=%APPDATA%\pandoc\github-markdown.css"
SET "_cssUri=file:///%_cssPath:\=/%"

REM Print overrides, injected into <head> after the template's own styles
SET "_printCss=%APPDATA%\pandoc\github-markdown-print.html"

REM ---------------------------------------------------------------------------
REM Parse named parameters (-Path, -Title) in any order, case-insensitively
REM ---------------------------------------------------------------------------
:parse
if "%~1"=="" goto endparse
if /I "%~1"=="-Path" (
    SET "_mdPath=%~2"
    shift /1
    shift /1
    goto parse
)
if /I "%~1"=="-Title" (
    SET "_title=%~2"
    shift /1
    shift /1
    goto parse
)
REM Ignore any unrecognized token and keep scanning
shift
goto parse
:endparse

REM ---------------------------------------------------------------------------
REM Require the -Path parameter; abort with usage text when it is missing
REM ---------------------------------------------------------------------------
if not defined _mdPath (
    echo ERROR: -Path is required.
    echo Usage: %~nx0 -Path "path\to\file.md" [-Title "Document Title"]
    GOTO exitPgm
)

REM ---------------------------------------------------------------------------
REM Verify the source file exists before invoking pandoc
REM ---------------------------------------------------------------------------
if not exist "%_mdPath%" (
    echo ERROR: File not found: "%_mdPath%"
    GOTO exitPgm
)

REM ---------------------------------------------------------------------------
REM The print overrides are not optional; without them the page is A4 and
REM  the layout is the screen layout.  Say so rather than rendering badly.
REM ---------------------------------------------------------------------------
if not exist "%_printCss%" (
    echo ERROR: Not found: "%_printCss%"
    echo Run pandoc_setup.cmd to install it.
    GOTO exitPgm
)

REM ---------------------------------------------------------------------------
REM Derive the output path by replacing the source extension with .pdf
REM (%%~dpnF expands to drive + path + name with no extension)
REM ---------------------------------------------------------------------------
for %%F in ("%_mdPath%") do SET "_outfile=%%~dpnF.pdf"

REM ---------------------------------------------------------------------------
REM Default the title to the source file's base name when -Title is not given
REM ---------------------------------------------------------------------------
if not defined _title (
    for %%F in ("%_mdPath%") do SET "_title=%%~nF"
)

REM ---------------------------------------------------------------------------
REM Convert the markdown to standalone, self-contained PDF
REM ---------------------------------------------------------------------------
pandoc ^
    --from gfm ^
    --to html5 ^
    --pdf-engine weasyprint ^
    --standalone ^
    --embed-resources ^
    --mathjax ^
    --template github-markdown.html ^
    --css "%_cssUri%" ^
    --include-in-header "%_printCss%" ^
    --syntax-highlighting tango ^
    --metadata title="%_title%" ^
    --output "%_outfile%" ^
    "%_mdPath%"

REM Capture pandoc's exit code immediately, before any later command overwrites it
SET "_exitCode=%ERRORLEVEL%"

REM ---------------------------------------------------------------------------
REM Surface pandoc's result to the caller
REM
REM  The page size is reported because getting it wrong is silent:  a PDF
REM   built without the print overrides opens perfectly well and is A4.
REM   pdfinfo ships with poppler and may not be installed, so its absence
REM   is not an error.
REM ---------------------------------------------------------------------------
if not "%_exitCode%"== "0" (
    echo ERROR: pandoc failed with exit code %_exitCode%.
) else (
    echo Created: "%_outfile%"
    >nul 2>&1 where pdfinfo && for /f "tokens=1,*" %%A in ('pdfinfo "%_outfile%" ^| findstr /B /C:"Pages:" /C:"Page size:"') do echo   %%A %%B
)

:exitPgm
endlocal & exit /b %_exitCode%
