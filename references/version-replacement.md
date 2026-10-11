# Replace an active version

The workspace control plane owns execution; this Skill supplies the workflow. Inspect the discovered script for `replace-body` support before using these commands. If unavailable, report that limitation rather than manually editing junctions or registry.

## Upstream upgrades: use the orchestrator

Read the [declaration, diagnostic and source rules](governance-model.md#adaptation-levels-升级分诊). Run `upgrade-skill.ps1 -Command classify -Name <skill-name>` (with `-Repo <slug>` when needed). Classification does not authorize mutation. Confirmed declarations keep their body, including light adaptations; undeclared Skills may follow upstream despite recorded-package differences or an unreadable old commit. Invalid declaration input fails closed. The gate checks all active scopes; `-Repo` cannot hide a user consumer or another scope's hold. Never bypass these guards with manual `import-repo` followed by `replace-body` for an upstream upgrade. If the orchestrator is absent, stop at evidence and a proposed operation rather than substituting the lower-level path.

After explicit authorization for the selected target revision:

1. Run `upgrade-skill.ps1 -Command prepare -Name <skill-name> -Commit <target-sha>`. Prepare may fetch and import a clean target package, but does not switch consumers. Review the emitted target SHA, imported body, consumer set and plan hash. Target-only resource additions count as updates even when `SKILL.md` is unchanged. Only equality between the actual current body and the complete target package is unchanged; equality between recorded and target trees is not sufficient.
2. After reviewing and authorizing that exact replacement, run `upgrade-skill.ps1 -Command apply -Name <skill-name> -Commit <same-target-sha> -Apply -ExpectedPlanHash <actual-plan-hash>`, repeating any identity/root arguments. Do not fabricate or reuse a stale hash. Explicit hold, user protection, missing/conflicting source identity, live/foreign sources and stale body records can still refuse an undeclared package. Historical labels and shared anchors do not. The orchestrator exports raw Git blobs and records the deployed commit using skill-specific overrides in every affected registration, leaving group defaults, siblings and mirror HEAD unchanged. Dirty unrelated workspace files do not skip accounting. Accounting failure returns nonzero and reports that the body switched; use the emitted skill-specific retry rather than claiming overall success. `-SkipAnchor` explicitly leaves deployment provenance unchanged. Stop and inspect any partial-result warning.
3. Save recovery evidence and run the structural checks below. Source revision, deployed body and fresh Agent discovery are separate results.

`<workspace>` below means the governance root owning the scripts (here `D:\claudecode`). Use `pwsh -NoProfile -File <script> ...`; where unavailable, use `powershell.exe -NoProfile -ExecutionPolicy Bypass -File <script> ...` (Windows PowerShell 5.1 requires Bypass here).

## Register a frozen upstream reference

A complete plugin or methodology may be retained for reading without importing its Skills. Preview `manage-skills.ps1 -Command register-frozen-source -Name <reference-name> -Source <absolute-mirror-Git-root> -SourcePath <relative-subtree> -Remote <upstream-url> -Ref <source-branch> -Commit <full-SHA>`; after reviewing the exact plan, repeat with `-Apply -ExpectedPlanHash <fresh-hash>`.

This add-only command writes the existing `sources.json.frozenReferences` array with fixed `upgradePolicy: hold`, not the upgrade catalog's `repositories`. It does not create canonical bodies, consumers, junctions, Profile/Manifest activation or deployment source rows. The mirror HEAD and complete subtree raw bytes must match the fixed Git commit; unsafe paths, links, extra files or conflicting registrations refuse. Repeating an identical record does not rewrite the catalog. Routine `verify` also checks these references. Source pinning is not runtime acceptance; adapting, updating, unfreezing or activating the plugin requires a different authorized task. Do not run upstream setup instructions while registering a reading reference.

## Upgrade an inactive inventory package

Use `upgrade-skill.ps1 -StockOnly -CandidateBody <absolute-registered-body> -Name <logical-name>` with the same classify/prepare/apply phases. This mode requires zero active consumers of that name; do not temporarily activate inventory to bypass the requirement. Select the exact package, not a suffix, timestamp or automatic newest baseline.

Source identity must come from that body's inventory provenance, a valid registration whose source-map points to the exact body, or a unique complete-package match at a safe catalog mirror's registered commit. Names alone, ambiguous matches and unavailable evidence cannot establish provenance. Existing reliable identity does not need historical-difference proof. All applicable declaration, hold, user, derived/local and live-source guards still apply; a repository filter must not hide conflicts.

Prepare may fetch and export temporary raw Git blobs, but writes no body or governance record. Review the full target SHA, exact candidate, deterministic target body and plan hash. Apply repeats all arguments with `-Commit <same-full-SHA> -Apply -ExpectedPlanHash <fresh-hash>`; the orchestrator calls `manage-skills -Command import-stock`, not replace-body or deployment source sync. The control plane independently verifies the same source gate and exported package. It stages and verifies bytes before publishing, then commits the body record and its `inventorySources` together in one atomic registry write. `packageDigest` binds every raw resource byte and directory; the legacy fingerprint remains compatible, not an equality test. The hash also binds candidate, target state and governance inputs, never a random temporary export path.

Inventory import does not activate or deploy. Consumers, declarations, Junctions, source-map, registration.skillCommits, sources.json and old packages remain unchanged. Identical bytes may reuse a target and retain multiple genuine source records, never overwrite a different package. Caught failures may clean only this operation's newly created unregistered package; publication and registry commit are not crash-atomic, so inspect any reported staging/unregistered residue after interruption. An unchanged result may still have only proposed provenance; do not claim it was registered. Run structural checks, and keep runtime acceptance and deletion authorization separate.

## Approved local-source update or rollback: control plane

This lower-level flow is for explicitly approved locally authored content or deliberate rollback, not an upstream gate escape.

1. Review the local source changes. For a local update, import only the selected complete Skill directory using `import-repo -Source <clean-directory> -Apply`; omit `.git`, build caches and dependencies, but retain all intended resources, including untracked/ignored authored release files. Confirm imported paths and every resource's contents match: the legacy import fingerprint does not hash every resource byte. For rollback, select the recorded old body instead of re-importing. Source updates and imports alone do not deploy anything.
2. Inspect each affected repository from its own Git root and preserve its state. For this explicitly authorized cross-scope operation, execute the owning workspace's control script from its governance root. The command covers every existing active consumer of one logical name, not all Skills and not newly discovered projects. It preserves Profiles/Manifests and indirect Agent adapters. It has no `-Project` subset mode.
3. Preview with the exact imported body path:

   ```powershell
   pwsh -NoProfile -File <workspace>\scripts\manage-skills.ps1 -Command replace-body -Name <skill-name> -Source <absolute-body-path>
   ```

   `<workspace>` is the governance root that owns the discovered control-plane script (this repo's own layout uses `D:\claudecode`). If `pwsh` is not installed, the same commands run under Windows PowerShell 5.1 as `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ...`; `-ExecutionPolicy Bypass` is required there.

   Review old/new paths and every consumer. Apply the same arguments plus `-Apply -ExpectedPlanHash <plan-hash-from-preview>`. The hash binds the registry and both body contents; a stale plan requires a fresh preview and review. For another workspace/user, pass its explicit `-WorkspaceRoot` and `-UserRoot` on both calls.
4. Save the emitted recovery location. Run control-plane `verify` and `test-skill-profile.ps1 -Suite quick`. Report source revision, deployed body and actual Agent discovery separately. A running Agent may retain already-loaded instructions; runtime validation needs a fresh session.

## Recovery and limits

Replacement retains the old body until task acceptance and a separately authorized retirement; it does not delete automatically. The tool retains old bodies and writes `registry.before.json` plus `replacement.json` under the workspace migration-backups directory before switching. On a caught failure before registry commit, it attempts to restore changed junctions without overwriting concurrent registry edits; any recovery error is reported with the backup path. Stop on recovery errors and inspect the recorded exact targets.

For a deliberate rollback after a successful upgrade, preview the same command with `-Source` set to the recorded old body, then apply with the new preview hash. This restores the version for the current active consumer set; compare that set to the saved plan first. It does not restore source Git history or roll back intervening Profile/Manifest changes.

Junctions switch sequentially under the workspace writer lock. The registry is committed last. This is caught-error recovery, not an atomic multi-directory filesystem operation: concurrent readers can see a short mixed-version interval. Do not invoke affected Skills during replacement. Forced termination, power loss and out-of-band filesystem edits are not automatically recovered. After interruption, inspect the saved plan and live targets before any retry; do not restore the whole registry snapshot over later work.

## Retire an unused old baseline

1. Read [lightweight task acceptance](verification.md#lightweight-task-acceptance). Reuse one passed minimal real task only after confirming its evidence still corresponds to the exact retained package. Do not confuse reading/discovery with acceptance or let an evidence file's existence stand in for judgment. Choose a proven stable baseline; no automatic newest-version choice and no extra mandatory previous version.
2. From the owning governance Git root, preview one exact registered pool child:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File <workspace>\scripts\manage-skills.ps1 -Command retire-body -Name <logical-name> -Source <absolute-old-body> -RetainedSource <absolute-accepted-body> -AcceptanceEvidence <absolute-task-evidence> -WorkspaceRoot <workspace> -UserRoot <user-root>
   ```

   No `-Project`, wildcard or batch deletion. The tool checks distinct registered bodies and matching frontmatter; it rejects any current consumer reference (including inactive/aliases), source-map.currentBody references, reparse packages, relevant physical/registry mismatches and explicit unfinished recovery. With active consumers, retain their unique in-use body. Without active consumers, explicit retained selection allows cleaning a multi-version inventory; remaining fallback ambiguity is reported, not silently resolved or activated. Logical Profile/Manifest names are not exact old-package dependencies and remain unchanged.
3. Review deletion of the complete target package **and ending that target's rollback purpose**, retained body, evidence and invalidated recovery instructions. Inspection is bounded to current governance records and fixed `replacement.json` files directly below migration-backups. Timestamp-named junction entries archived by migration are inspected only as link metadata, never followed; an entry targeting the old package is listed as invalidated. Unknown reparse operation directories are rejected. No protected-project search, Git-history reconstruction or permanent block from historical snapshots. Missing status does not mean unfinished; current convergence does not prove an old transaction succeeded. Malformed required metadata stops the operation.
4. Only after explicit deletion authorization, repeat all arguments with `-Apply -ExpectedPlanHash <fresh-preview-hash>`. The token binds registry bytes, both packages including equal-length resources and empty directories, evidence, source map, relevant physical state and bounded recovery metadata. The tool does not score evidence prose. A change needs a new preview and review.
5. The tool temporarily moves only the selected package to a same-volume operation directory, rechecks, and atomically removes its single registry record. Before commit, caught failures attempt to move back without overwriting an occupied original path or concurrent registry. After commit, rollback ends: purge really deletes the staged package. Purge failure returns nonzero, reports deregistration and residue, and never moves/re-registers a potentially partial package. Inspect the exact emitted location; no automatic GC or retry system is implied. Successful cleanup leaves only small operation metadata, not a permanent full-package archive.

Run structural `verify` after an authorized cleanup. Do not overwrite current registry with historical snapshots. Forced termination/power loss needs manual inspection; caught-error recovery is not crash atomicity. Historical rollback instructions referring to a deleted package are no longer fully executable. A passed task is bounded usability evidence, not a promise of permanent stability or deletion permission.
