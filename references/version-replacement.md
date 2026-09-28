# Replace an active version

The workspace control plane owns execution; this Skill supplies the workflow. Inspect the discovered script for `replace-body` support before using these commands. If unavailable, report that limitation rather than manually editing junctions or registry.

Before upgrading, run an update survey and read each Skill's adaptation level (see [governance-model.md](governance-model.md#adaptation-levels-升级分诊)). `verbatim` and `light` Skills follow this flow; `heavy` Skills need their local adaptations merged onto the new upstream first; `derived` / `local` Skills are not upstream-update targets.

1. Review the source revision, local adaptations and dependency/behavior changes. Import only the selected Skill directory using `import-repo -Source <directory> -Apply`. The import source must be a clean export of the target revision, not a live mirror working tree: `import-repo` copies the whole directory and its fingerprint does not exclude `.git`/`node_modules`, so for a Git mirror export with `git archive <commit>[:<subdir>] | tar -x -C <clean-dir>` (tracked files only) and import that. Confirm the imported body and source contents match, including resources: the legacy import fingerprint does not hash every resource byte. Source updates and imports alone do not deploy anything.
2. Inspect each affected repository from its own Git root and preserve its state. For this explicitly authorized cross-scope operation, execute the owning workspace's control script from its governance root. The command covers every existing active consumer of one logical name, not all Skills and not newly discovered projects. It preserves Profiles/Manifests and indirect Agent adapters. It has no `-Project` subset mode.
3. Preview with the exact imported body path:

   ```powershell
   pwsh -NoProfile -File <workspace>\scripts\manage-skills.ps1 -Command replace-body -Name <skill-name> -Source <absolute-body-path>
   ```

   `<workspace>` is the governance root that owns the discovered control-plane script (this repo's own layout uses `D:\claudecode`). If `pwsh` is not installed, the same commands run under Windows PowerShell 5.1 as `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ...`; `-ExecutionPolicy Bypass` is required there.

   Review old/new paths and every consumer. Apply the same arguments plus `-Apply -ExpectedPlanHash <plan-hash-from-preview>`. The hash binds the registry and both body contents; a stale plan requires a fresh preview and review. For another workspace/user, pass its explicit `-WorkspaceRoot` and `-UserRoot` on both calls.
4. Save the emitted recovery location. Run control-plane `verify` and `test-skill-profile.ps1 -Suite quick`. Report source revision, deployed body and actual Agent discovery separately. A running Agent may retain already-loaded instructions; runtime validation needs a fresh session.

## Recovery and limits

The tool retains old bodies and writes `registry.before.json` plus `replacement.json` under the workspace migration-backups directory before switching. On a caught failure before registry commit, it attempts to restore changed junctions without overwriting concurrent registry edits; any recovery error is reported with the backup path. Stop on recovery errors and inspect the recorded exact targets.

For a deliberate rollback after a successful upgrade, preview the same command with `-Source` set to the recorded old body, then apply with the new preview hash. This restores the version for the current active consumer set; compare that set to the saved plan first. It does not restore source Git history or roll back intervening Profile/Manifest changes.

Junctions switch sequentially under the workspace writer lock. The registry is committed last. This is caught-error recovery, not an atomic multi-directory filesystem operation: concurrent readers can see a short mixed-version interval. Do not invoke affected Skills during replacement. Forced termination, power loss and out-of-band filesystem edits are not automatically recovered. After interruption, inspect the saved plan and live targets before any retry; do not restore the whole registry snapshot over later work.
