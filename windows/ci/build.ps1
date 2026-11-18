[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PgRoot,
    [Parameter(Mandatory = $true)][string]$UpstreamDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$source = (Resolve-Path $UpstreamDir).Path
$vswhere = Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Microsoft Visual Studio/Installer/vswhere.exe'
$vs = [string](& $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 Microsoft.Component.MSBuild -property installationPath | Select-Object -First 1)
if (-not $vs.Trim()) { throw 'MSVC x64 and MSBuild installation not found.' }
$devCmd = Join-Path $vs.Trim() 'Common7/Tools/VsDevCmd.bat'

# The upstream project expects postgres.lib in a PostgreSQL build tree.
$pgBuild = Join-Path $env:RUNNER_TEMP 'pldebugger-pg-build'
$backend = New-Item -ItemType Directory -Force -Path (Join-Path $pgBuild 'src/backend')
Copy-Item (Join-Path $PgRoot 'lib/postgres.lib') $backend.FullName -Force

# The installed SDK keeps its server and platform headers under include/server.
$buildCmd = Join-Path $env:RUNNER_TEMP 'pldebugger-msbuild.cmd'
@"
@echo off
call "$devCmd" -arch=x64 -host_arch=x64 >nul
if errorlevel 1 exit /b %errorlevel%
set CL=/DWIN32_NO_STATUS /I"$PgRoot\include\server\port\win32_msvc" /I"$PgRoot\include\server\port\win32" /I"$PgRoot\include\server" /I"$PgRoot\include"
set "LIB=$PgRoot\lib;%LIB%"
set "_LINK_=libintl.lib"
msbuild.exe pldebugger.proj /nologo /t:all /p:ARCH=x64 "/p:PGPATH=$pgBuild" "/p:PGBUILDPATH=$pgBuild"
exit /b %errorlevel%
"@ | Set-Content -Path $buildCmd -Encoding ascii

Push-Location $source
try {
    & cmd.exe /d /c $buildCmd
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path 'plugin_debugger.dll' -PathType Leaf)) {
        throw 'Upstream pldebugger MSBuild failed to produce plugin_debugger.dll.'
    }
} finally {
    Pop-Location
}
