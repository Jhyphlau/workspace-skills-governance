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

## Lightweight task acceptance

Discovery or reading is not task completion. Use one minimal real task with a stated success condition, in a clean Agent restricted to the designated Skill. Record the exact body/entrypoint and version, Agent and launch root, explicit reading versus natural discovery, task input, actual output, checks, extra Skills/tools, and result plus limits. Extra Skill loading means isolation did not pass, even if the output did. A verified explicit-read task does not prove automatic triggering, an independent CLI session, all platforms, or permanent stability.

Reuse existing evidence when it still belongs to the current retained package; do not rerun a passed task just to generate paperwork. The Agent must read and judge that correspondence before preview/apply; uncertainty stops cleanup. Keep evidence in the existing operation closeout, not a new persistent acceptance database. Working notes may carry execution evidence, never policy or provenance authority. Prefer a proven stable baseline, not automatically the highest version or newest timestamp.

## Recovery requirements

Before a change that can relocate repositories, replace canonical bodies, deactivate consumers, or alter declarations, record:

- exact resolved source and destination paths;
- Git root, branch/HEAD, status, tracked diff, and untracked inventory where a repository is affected;
- the recovery location the control plane emits before switching (for example `registry.before.json` and `replacement.json` under the migration-backups directory) or the prior canonical body identity — the registry is Git-tracked and the tool writes these backups automatically, so no manual registry/Profile/Manifest/junction snapshot is required;
- the control-plane preview and exact rollback action;
- post-rollback structural checks and any runtime probes needed to prove recovery.

Keep protected review state unchanged until this evidence exists and the required decision is explicit. Preserve recovery artifacts through closeout. After lightweight task acceptance, an unused old baseline may end its rollback purpose through an explicitly authorized retirement plan; acceptance alone does not permit deletion. Retirement only stages the package for precommit caught-error recovery, then actually purges it. Report invalidated historical recovery instructions; do not claim the deleted package can still be rolled back. Postcommit purge failure is a partial result, not grounds to re-register a possibly incomplete package.

## Closeout contract

Return these fields, using `none` or `unverified` instead of omission:

- `status`: `DONE`, `DONE_WITH_CONCERNS`, or `BLOCKED`;
- `protected_state`: dirty, ahead, linked, checkpoint, or deferred items left unchanged;
- `changes`: files and governance objects changed through the control plane;
- `warnings_and_deferred_decisions`: unresolved facts, missing authority, and next owner/action.

Report `discovery` (per-Agent and per-launch-root `verified|unverified|failed`) only when a real probe produced evidence; for this workspace it is currently always `unverified`, so it is not a required slot.

Use `DONE_WITH_CONCERNS` when the requested in-scope work is complete but any relevant evidence remains `unverified` or protected/deferred state remains. Use `BLOCKED` when a required decision, control plane, or recovery prerequisite prevents the requested mutation.
