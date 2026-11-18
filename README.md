# pldebugger for Windows

Unofficial Windows x64 packaging for EnterpriseDB's PostgreSQL PL/pgSQL debugger.

Windows CI builds upstream [v1.10](https://github.com/EnterpriseDB/pldebugger/releases/tag/v1.10)
at commit `bf57aa61d5eb131ece767cd7a9db0c167787d1e6` for PostgreSQL 15–18.
It uses the upstream MSBuild project and module definition with the installed
PostgreSQL SDK. The package contains `lib/plugin_debugger.dll` and the
`share/extension/pldbgapi` control and SQL files.

## Installation

Copy the package's `lib` and `share` contents into the corresponding directories
of a PostgreSQL installation with the matching major version. Add
`plugin_debugger` to `shared_preload_libraries` in `postgresql.conf` and restart
PostgreSQL. Run `CREATE EXTENSION pldbgapi;` in each database where the debugger
API is needed. The SQL extension version is `1.1`.

## License and source

The pinned [upstream README](https://github.com/EnterpriseDB/pldebugger/blob/bf57aa61d5eb131ece767cd7a9db0c167787d1e6/README-pldebugger.md#licence)
declares Artistic License 2.0 and copyright © 2004–2024 EnterpriseDB Corporation.
The package includes the upstream README and the full [Artistic License 2.0](LICENSE).

Obtain the exact source with:

```sh
git clone https://github.com/EnterpriseDB/pldebugger.git
git -C pldebugger checkout --detach bf57aa61d5eb131ece767cd7a9db0c167787d1e6
```
