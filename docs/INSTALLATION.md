# Installation

## Before installation

Review the source. Omarchy shell plugins execute unsandboxed as the current
user. This plugin can read the installed JACKAL runtime declaration, local
ledger and retained receipts; read the configured expectations file; inspect
clipboard content when verification is requested; execute the bundled operator
CLI and router; and write selected text to the clipboard.

It does not require root privileges or a background system service.

## Prerequisites

1. A current Omarchy Quattro installation.
2. The JACKAL Codex plugin and a supported runtime installed according to the
   core JACKAL repository.
3. `/usr/bin/python3`, `/usr/bin/wl-copy`, `/usr/bin/cat`, and the `codex` CLI available locally.

Confirm Omarchy can validate plugins:

```sh
omarchy plugin --help
```

Confirm JACKAL's local plugin is visible to Codex:

```sh
codex plugin list --json
```

## Marketplace-style installation

```sh
omarchy plugin add https://github.com/AnubisQuantumCipher/jackal-omarchy.git --enable
```

Omarchy performs the clone and manifest validation. The plugin ID is
`khephri.jackal` and its default bar section is `right`.

For a commit-pinned review, clone the repository yourself, inspect and check out
the exact commit in detached mode, validate it, then install or link that
reviewed tree through an operator-controlled process. Omarchy's standard plugin
update command follows mutable upstream state; marketplace verification remains
bound to its recorded commit.

## Migration from the development copy

The existing manually copied plugin is not a Git checkout, so `omarchy plugin
update` cannot manage it. Preserve any local edits first:

```sh
cp -a "$HOME/.config/omarchy/plugins/khephri.jackal" \
  "$HOME/.config/omarchy/plugins/khephri.jackal.manual-backup"
omarchy plugin remove khephri.jackal
omarchy plugin add https://github.com/AnubisQuantumCipher/jackal-omarchy.git --enable
```

The removal command also creates a timestamped backup for a non-Git plugin. Do
not delete either backup until the new plugin passes live acceptance.

## Operator configuration

Configuration is optional. To pin non-default local paths:

```sh
mkdir -p "$HOME/.config/jackal-omarchy"
cp config/config.example.json "$HOME/.config/jackal-omarchy/config.json"
```

Supported keys:

| Key | Purpose |
|---|---|
| `anubis_path` | Explicit Anubis compiler path used by runtime probes |
| `provisioner_path` | Explicit path to the core JACKAL `provision_runtime.py` |
| `mcp_launcher` | Explicit path used by the optional ledger wrapper |

Paths are operator policy. The repository does not infer them from a receipt or
download an alternative when they fail.

## Verification expectations

Copy the example only as a template:

```sh
cp config/jackal-expectations.example.json \
  "$HOME/.config/omarchy/jackal-expectations.json"
chmod 600 "$HOME/.config/omarchy/jackal-expectations.json"
```

Replace every placeholder with values authorized independently of the artifact
you intend to inspect. Do not broaden expectations merely to make a refusal
pass.

## Optional ledger

The dropdown functions without a ledger; the latest-results section will be
empty. To enable recall, configure the MCP client to use the repository's
`bin/jackal-mcp-ledger` as the JACKAL stdio command. Set
`JACKAL_MCP_LAUNCHER` to the reviewed core launch script when automatic Codex
source discovery is not desired.

Do not copy ledger rows into an evidence report. Re-run the tool or re-verify a
retained receipt through the front door.

## Acceptance after installation

```sh
omarchy plugin validate "$HOME/.config/omarchy/plugins/khephri.jackal"
omarchy plugin list --json | jq '.[] | select(.id == "khephri.jackal")'
omarchy-shell khephri.jackal open
omarchy-shell khephri.jackal close
"$HOME/.config/omarchy/plugins/khephri.jackal/bin/omarchy-jackal" doctor --json
"$HOME/.config/omarchy/plugins/khephri.jackal/bin/omarchy-jackal" verify
```

Interpret `FUNCTIONAL` only as the fresh canonical probe result described in
`ASSURANCE_MODEL.md`.

## Update

```sh
omarchy plugin update khephri.jackal
```

Review the diff shown by Omarchy before accepting an update. Re-run acceptance
afterward. A marketplace verification badge applies to the exact recorded
commit, not automatically to later upstream commits.

## Remove

```sh
omarchy plugin remove khephri.jackal
```

This removes or backs up the plugin checkout and unloads it from the shell. It
does not remove:

- the JACKAL runtime;
- the Codex JACKAL plugin;
- `~/.config/omarchy/jackal-expectations.json`;
- `~/.config/jackal-omarchy/config.json`;
- `~/.local/state/jackal/results.jsonl`;
- retained receipts.

Those are intentionally separate. Remove them only under the retention and
recovery policy appropriate to their owner.
