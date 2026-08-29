## Outcome

Describe the user-visible result.

## Trust boundary

Which assurance, consequence, runtime, ledger, clipboard, process, or update
boundary changes?

## Verification

List commands executed and observed results. Do not label finite tests as proof
of universal correctness.

## Security and privacy

Describe new files, processes, network access, dependencies, privileges, or
data handling.

## Residual risks and non-claims

State what this change does not establish.

## Checklist

- [ ] Returned status classes and refusal reasons are preserved.
- [ ] No credential, private artifact, authorization, or ledger data is included.
- [ ] Install, update, and removal documentation remains accurate.
- [ ] `./scripts/check.sh` passes.
- [ ] Visible changes include a reviewed screenshot.
