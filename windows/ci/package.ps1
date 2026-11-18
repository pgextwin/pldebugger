[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$UpstreamDir,
    [Parameter(Mandatory = $true)][string]$UpstreamRepository,
    [Parameter(Mandatory = $true)][string]$UpstreamRef,
    [Parameter(Mandatory = $true)][string]$UpstreamVersion,
    [Parameter(Mandatory = $true)][int]$PostgreSqlMajor,
    [Parameter(Mandatory = $true)][string]$PostgreSqlMinor,
    [string]$DistDir = 'dist'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Join-Path $PSScriptRoot '../..'
$upstreamSha = (& git -C $UpstreamDir rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Could not resolve upstream checkout commit.' }

$assetName = "pldebugger-$UpstreamRef-pg$PostgreSqlMajor-windows-x64"
$stage = Join-Path $DistDir $assetName
$zipPath = Join-Path $DistDir "$assetName.zip"

New-Item -ItemType Directory -Force -Path (Join-Path $stage 'lib'), (Join-Path $stage 'share/extension') | Out-Null
& (Join-Path $PSScriptRoot 'install.ps1') -PgRoot $stage -UpstreamDir $UpstreamDir
Copy-Item (Join-Path $root 'LICENSE') (Join-Path $stage 'LICENSE') -Force

# Preserve the exact license notice from the pinned upstream Git blob.
& git -C $UpstreamDir -c core.autocrlf=false checkout-index --force -- README-pldebugger.md
if ($LASTEXITCODE -ne 0) { throw 'Could not restore the exact upstream README bytes.' }
Copy-Item (Join-Path $UpstreamDir 'README-pldebugger.md') (Join-Path $stage 'README-pldebugger.md') -Force

@"
pldebugger Windows package

Upstream repository: $UpstreamRepository
Upstream ref:        $UpstreamRef
Upstream commit:     $upstreamSha
pldebugger version:  $UpstreamVersion
SQL default_version: 1.1
PostgreSQL major:    $PostgreSqlMajor
PostgreSQL tested:   $PostgreSqlMinor
Architecture:        Windows x64
Compiler:            MSVC x64
License:             Artistic-2.0; see LICENSE and README-pldebugger.md

Obtain the exact upstream source:
  git clone https://github.com/$UpstreamRepository.git
  git -C pldebugger checkout --detach $upstreamSha

Add plugin_debugger to shared_preload_libraries, restart PostgreSQL,
and run CREATE EXTENSION pldbgapi in the target database.
"@ | Set-Content -Path (Join-Path $stage 'PACKAGE-INFO.txt') -Encoding utf8

Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zipPath -CompressionLevel Optimal -Force
