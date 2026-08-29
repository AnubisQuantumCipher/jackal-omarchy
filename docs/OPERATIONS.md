# Operations Runbook

## Operating objective

The panel should answer four different questions without merging them:

1. Is a runtime installed?
2. Does its pinned tree currently pass the core integrity check?
3. Did representative tools execute at their declared classes now?
4. What recent results are available for local recall?

## Routine checks

### Observe paths

```sh
./bin/omarchy-jackal paths
```

This prints the plugin root, runtime locator, optional operator configuration,
and ledger paths. It does not verify them.

### Observe identities

```sh
./bin/omarchy-jackal identity
```

This hashes selected installed files and reports package metadata and file
formats. The output is an observation, not publisher authentication or function
evidence.

### Read the declared inventory

```sh
./bin/omarchy-jackal inventory
```

The inventory comes from the installed runtime. It declares available tools,
profiles, dependencies, status classes, refusal boundaries, and consequence
ceilings. It does not prove a tool executed.

### Probe function

```sh
./bin/omarchy-jackal doctor --json
```

The doctor runs canonical inputs for admitted families and compares each
returned status with the installed inventory declaration. `FUNCTIONAL` applies
only to those probes in that invocation.

### Verify runtime integrity

```sh
./bin/omarchy-jackal verify
```

The command locates the installed Codex JACKAL plugin, runs its plugin identity
verifier, imports its provisioner without writing bytecode, checks the package
pin, validates the complete runtime checksum inventory, executes the runtime
self-test, and validates the inventory again through the core provisioner.

If any required component is unavailable, it returns `REFUSED`. There is no
local weaker checksum fallback.

## Panel interpretation

### `FUNCTIONAL`

All canonical family probes present in the installed inventory returned their
expected declared class, and the Hermes self-test reported an identity match.
This is a fresh functional sample, not universal correctness.

### `DEGRADED`

At least one probe or self-test condition did not match. Inspect the doctor JSON
and the named tool row. Do not treat a partial pass as full function.

### `REFUSED`

An integrity, identity, routing, policy, or parsing boundary refused. Preserve
the reason. Do not edit expectations, pins, or status mappings merely to turn it
green; this interface deliberately has no green success semantics.

### `STALE`

The prior doctor observation exceeded the configured staleness window. Re-probe
before relying on the session-function display.

### `INDETERMINATE`

The current session has insufficient information. This is not a warning-colored
pass.

## Ledger operations

The default paths are:

```text
~/.local/state/jackal/results.jsonl
~/.local/state/jackal/receipts/<digest>.json
```

The wrapper bounds row history and receipt count. Rotation is a convenience
policy, not evidence destruction policy. If formal receipts need regulated
retention, export them to a controlled evidence store and re-verify them there.

Never cite `results.jsonl` as a mathematical source. Use it to identify the tool
and input, then re-run the tool or verify the retained artifact.

## Artifact verification

1. Create operator expectations before importing the artifact.
2. Put a supported receipt or bundle on the clipboard, or select a retained
   receipt row.
3. Press `p`.
4. Read `status`, `raised_by`, reason, subject, and authorized values.
5. Preserve `refused` or `indeterminate` exactly.

A `widget-*` reason means the artifact did not reach a JACKAL front door. A
JACKAL reason means the selected front door examined the request and refused.

## Logs and diagnostics

```sh
omarchy debug --no-sudo --print
qs log -p "$OMARCHY_PATH/shell" --tail 100
omarchy plugin list --json
omarchy-shell shell listPlugins
```

Do not attach raw logs before checking them for usernames, home paths, clipboard
content, artifact inputs, or credentials.

## Troubleshooting

### Plugin is not listed

```sh
omarchy plugin validate "$HOME/.config/omarchy/plugins/khephri.jackal"
omarchy-shell shell rescanPlugins
```

Fix manifest or entry-point errors before enabling.

### Panel opens but shows `NOT INSTALLED`

Inspect the runtime locator with `omarchy-jackal paths`, then follow the core
JACKAL provisioner instructions. The panel does not install runtimes.

### Runtime verification says `core-provisioner-not-found`

Confirm `codex plugin list --json` reports the installed `jackel` plugin and a
local source. Alternatively set an reviewed absolute `provisioner_path` in the
operator configuration.

### Latest results are empty

This is normal unless the optional MCP ledger wrapper is configured. Confirm
the file exists and is readable. Do not fabricate a result from older UI state.

### Latest result is present but blank

Structured results must have an explicitly supported display projection. The
current wrapper projects the HELLGATE eigenvalue and true-ground quartic
enclosure without parsing or recomputing them. Unknown payloads remain blank
rather than guessed.

### Text shimmers while scrolling

Run `tests/presentation.test.py`, confirm the opaque reading plane remains
pixel-aligned with smoothing disabled, and inspect any compositor scaling
change. Do not reintroduce animated textures behind text.

### Verification refuses an apparently valid receipt

Compare the displayed authorized request with the receipt subject. A mismatch
is expected to refuse. Do not copy expected values from the receipt into the
authorization as a workaround.

## Incident response

For suspected compromise:

1. Close the panel and disable the plugin.
2. Preserve the exact repository commit, runtime epoch, locator, and relevant
   logs without publishing secrets.
3. Revoke any exposed credential immediately.
4. Run the core runtime verification from a reviewed source.
5. Report privately under `SECURITY.md`.
6. Do not update mutable upstream state before recording the affected commit.

## Backup and recovery

The Omarchy plugin manager backs up non-Git plugin folders during removal.
Operator expectations and retained receipts require a separate backup policy.
The ledger may be regenerated only by future calls and should not be treated as
an authoritative record.
