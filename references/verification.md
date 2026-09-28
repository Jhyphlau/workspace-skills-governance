# Verification and closeout

Keep evidence layers separate so a strong structural result cannot silently become a runtime or upstream claim.

## Evidence levels

| Level | Establishes | Minimum evidence | Does not establish |
| --- | --- | --- | --- |
| `structural` | Files, schemas, resolved paths, Git markers, declarations, consumer records, and reparse metadata have the reported shape. | Read-only inventory plus control-plane verification from the exact target root. | Agent discovery, invocation success, remote freshness, or dependency health. |
| `runtime` | A named Agent launched from a named root actually discovers or invokes the expected Skill/rules. | Fresh, bounded probe recording Agent/version, launch root, command or prompt, exit/result, and observed Skill/rule source. | Other Agents, other launch roots, or external source freshness. |
| `external` | A source mirror, package, remote, authentication path, or upstream dependency is reachable and in the reported state. | Named external check with endpoint/source, revision or version, credentials context where safe, and bounded result. | Local activation or Agent discovery. |

Record each level independently as `verified`, `unverified`, or `failed`; never collapse them into one global pass.

## Cross-Agent result vocabulary

- `verified`: the bounded probe completed and directly observed the expected behavior for that Agent and launch root.
- `unverified`: the probe was not run or was inconclusive because the Agent, authentication, network, time budget, or usable output was unavailable. A timeout belongs here unless it directly observes the expected behavior failing.
- `failed`: the probe completed under valid preconditions and directly observed wrong behavior, a violated contract, or a reproducible error attributable to the governed setup.

Report one row per Agent and launch root. Structural compatibility for `.agents/skills` or `.claude/skills` is not a runtime row and never upgrades `unverified` to `verified`.

## Recovery requirements

Before a change that can relocate repositories, replace canonical bodies, deactivate consumers, or alter declarations, record:

- exact resolved source and destination paths;
- Git root, branch/HEAD, status, tracked diff, and untracked inventory where a repository is affected;
- byte or metadata snapshots for registry, Profile, Manifest, and junction state in scope;
- a recoverable backup location or prior canonical body identity;
- the control-plane preview and exact rollback action;
- post-rollback structural checks and any runtime probes needed to prove recovery.

Keep protected review state unchanged until this evidence exists and the required decision is explicit. Preserve recovery artifacts through closeout.

## Closeout contract

Return these fields, using `none` or `unverified` instead of omission:

- `status`: `DONE`, `DONE_WITH_CONCERNS`, or `BLOCKED`;
- `request`: operation and requested scopes;
- `roots_and_classification`: every affected resolved root and boundary class;
- `control_plane`: discovered tool/registry or the read-only missing-control-plane warning;
- `provenance`: source mirrors, source registrations, canonical body identities, and deduplication decisions;
- `activation`: Profiles, Manifests, consumers, junctions, and before/after counts;
- `discovery`: per-Agent and per-launch-root `verified|unverified|failed` results;
- `evidence`: separate structural, runtime, and external results with commands and bounded outcomes;
- `recovery`: snapshots, backup/rollback path, rollback action, and recovery verification;
- `protected_state`: dirty, ahead, linked, checkpoint, or deferred items left unchanged;
- `changes`: files and governance objects changed through the control plane;
- `warnings_and_deferred_decisions`: unresolved facts, missing authority, and next owner/action.

Use `DONE_WITH_CONCERNS` when the requested in-scope work is complete but any relevant evidence remains `unverified` or protected/deferred state remains. Use `BLOCKED` when a required decision, control plane, or recovery prerequisite prevents the requested mutation.
