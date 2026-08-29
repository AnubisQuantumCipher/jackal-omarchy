# Dependencies

## Runtime dependencies

| Dependency | Purpose | Required by | Network at panel runtime |
|---|---|---|---|
| Omarchy Quattro shell | Plugin lifecycle, bar, panel, IPC | QML surface | No |
| Quickshell and Qt Quick | QML execution and local processes | QML surface | No |
| JACKAL Codex plugin | Mathematical MCP surface and core provisioner | Diagnostics and agent computation | No after installation |
| JACKAL runtime | Tool execution, inventories, checkers, maturity statement | Diagnostics and computation | No |
| `/usr/bin/python3` | Operator CLI, router, optional ledger | Python adapters | No |
| `codex` CLI | Discover installed JACKAL plugin source | Runtime verification and launcher discovery | No |
| `/usr/bin/wl-copy` | User-requested copy actions | Panel | No |
| `/usr/bin/cat` | Bounded local file reads initiated by QML | Panel service | No |
| Anubis compiler | JACKAL evidence/program lanes that declare it | Core runtime | No for local execution |
| Z3 | JACKAL program-evidence lanes that declare it | Core runtime | No for local execution |

The panel does not install packages or invoke a package manager.

## Development dependencies

| Dependency | Purpose |
|---|---|
| Git | Source control and deterministic archive input |
| Node.js | Pure `Model.js` tests |
| Python 3 | Router, operator, ledger, repository, and presentation tests |
| `qmllint` | Static QML analysis when Omarchy imports are installed |
| `sha256sum` | Release manifest and artifact digest |
| GNU tar and gzip | Reproducible release archive |

## External projects and licenses

This repository is MIT licensed. It interfaces with but does not vendor the
JACKAL runtime, Omarchy, Quickshell, Qt, Codex, Anubis, or Z3. Users and
distributors must comply with the licenses of those separately installed
projects.

The root preview and `assets/` images are project-owned product captures and
visualizations included under this repository's license. They do not embed a
third-party screenshot supplied by the marketplace.

## Update boundaries

- Omarchy updates may change the shell plugin API.
- JACKAL runtime epochs may change the inventory or host pin table.
- Codex plugin updates may change the local source location.
- Mutable upstream Git installation means later code may differ from a
  marketplace-reviewed commit.

Compatibility must therefore be revalidated at each update rather than inferred
from an older release badge.
