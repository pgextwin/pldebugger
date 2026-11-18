[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PgRoot,
    [Parameter(Mandatory = $true)][int]$PgPort,
    [Parameter(Mandatory = $true)][int]$PostgreSqlMajor
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$data = Join-Path $env:RUNNER_TEMP "pldebugger-$PostgreSqlMajor-data"
$log = Join-Path $env:RUNNER_TEMP "pldebugger-$PostgreSqlMajor.log"
& "$PgRoot/bin/initdb.exe" -D $data -U postgres -A trust --encoding=UTF8 --no-locale
if ($LASTEXITCODE -ne 0) { throw 'initdb failed.' }

$started = $false
try {
    & "$PgRoot/bin/pg_ctl.exe" -D $data -l $log -o "-p $PgPort -c listen_addresses=127.0.0.1 -c shared_preload_libraries=plugin_debugger" start
    if ($LASTEXITCODE -ne 0) { throw 'plugin_debugger shared preload startup failed.' }
    $started = $true

    $sql = @'
CREATE EXTENSION pldbgapi;
SELECT extversion FROM pg_extension WHERE extname = 'pldbgapi';
SELECT serverversionnum = current_setting('server_version_num')::integer
       AND serverprocessid = pg_backend_pid()
       AND proxyapiver > 0
FROM pldbg_get_proxy_info();
'@
    $result = @(& "$PgRoot/bin/psql.exe" -h 127.0.0.1 -p $PgPort -U postgres -d postgres -X -qAt -v ON_ERROR_STOP=1 -c $sql)
    if ($LASTEXITCODE -ne 0 -or ($result -join ',') -cne '1.1,t') {
        throw "pldbgapi SQL smoke failed. Expected 1.1,t, got $($result -join ',')."
    }
    Write-Host "pldbgapi version: $($result[0]); native proxy response valid: $($result[1])"
    Write-Host "PASS: pldebugger PG$PostgreSqlMajor functional smoke test"
} finally {
    if (Test-Path $log) { Get-Content $log -Tail 80 }
    if ($started) { & "$PgRoot/bin/pg_ctl.exe" -D $data -m immediate stop }
}
