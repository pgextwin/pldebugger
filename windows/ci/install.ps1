[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PgRoot,
    [Parameter(Mandatory = $true)][string]$UpstreamDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$extensionDir = Join-Path $PgRoot 'share/extension'
foreach ($file in @('pldbgapi.control', 'pldbgapi--1.1.sql', 'pldbgapi--1.0--1.1.sql', 'pldbgapi--unpackaged--1.1.sql')) {
    Copy-Item (Join-Path $UpstreamDir $file) (Join-Path $extensionDir $file) -Force
}
Copy-Item (Join-Path $UpstreamDir 'plugin_debugger.dll') (Join-Path $PgRoot 'lib/plugin_debugger.dll') -Force
