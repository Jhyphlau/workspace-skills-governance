# Governance model

Use this model to classify what exists before choosing any mutation.

## Definitions

- **Body:** the canonical, immutable-by-activation Skill content selected by identity or fingerprint. A body can exist with zero consumers.
- **Source mirror:** an editable authored checkout or upstream clone used as provenance for imports and updates. Editing it does not update a canonical body or activate a Skill.
- **Registry:** the existing control plane's record of canonical bodies, logical identity, and consumers. Read it as evidence; update it only through its owning tool.
- **Profile:** a named, reusable set of logical Skill names for a scope. It declares desired activation, not runtime state and not another Profile's contents.
- **Manifest:** a project-local declaration of Profiles and additional Skills required by that project. It is the normal activation contract for an independent project repository.
- **Junction:** a filesystem activation consumer that points at a canonical body. It is neither source provenance nor a registry, and its presence alone proves only structure.
- **Router:** guidance that selects among already discovered Skills. It holds no governance state and performs no installation, activation, Git, or junction mutation.
- **Workbench:** a scene or aggregation container for related sessions and Profiles. It is not an implicit configuration parent for an independent Git repository beneath it.
- **Project repository:** a Git root with its own delivery lifecycle, rules, dependencies, and Skill contract. Start sessions and verification at this root.
- **Release artifact:** a curated, generalized derivative of a source, published for external consumers on its own versioned release cadence. It is not a workbench member and does not inherit a surrounding workbench's Profiles or Skills; its link to its source is provenance (recorded anchors and a disposition record), not co-location. Release artifacts are collected under `skill-repos/released-repos/` — a container whose members are each an independent Git root governed at its own root — rather than inside a workbench, so the container holds no Git history and activates no Skills of its own.
- **Dependency/mirror:** upstream source retained for reference, vendoring, or contribution. Preserve its Git history; do not treat it as the surrounding workbench's session root or Skill source automatically.
- **Protected review state:** dirty, ahead, detached, linked-worktree, checkpoint-backed, or otherwise unresolved repository state. Inventory it without cleanup, movement, absorption, or activation changes until an explicit decision and recovery evidence exist.

## Three independent axes

| Axis | Question | Evidence |
| --- | --- | --- |
| Provenance | Where is editable source, and which canonical body was imported from it? | source registration, source mirror, body fingerprint, registry body record |
| Activation | Which scope declares and materializes the Skill? | Profile, Manifest, registry consumer, junction metadata |
| Discovery | Did a specific Agent, launched from a specific root, load or invoke it? | runtime probe for that Agent and launch root |

Never infer one axis from another. In particular, editable source is not the canonical body, a canonical body is not necessarily active, and a junction is not runtime discovery evidence.

## Adaptation levels (升级分诊)

Adaptation is independent of the three axes. In this workspace, only exact `status: "confirmed"` entries in the machine block of `docs/skill-adaptations.md` declare intentional adaptation. An unreadable or invalid declaration input closes the upgrade gate; prose and old `skillTextStatus` values cannot substitute for it.

| Classification | Meaning | Upgrade strategy |
| --- | --- | --- |
| `declared` | Intentional adaptation is confirmed. | Keep the deployed body; do not upgrade, even for a small delta. |
| `verbatim` | Undeclared, and every package file matches the recorded import commit. | Eligible to follow upstream; source guards and explicit prepare/apply authorization still apply. |
| `undeclared` | Not declared; recorded-package differences are diagnostic only. | Eligible to follow upstream without historical proof or candidate confirmation. |
| `historical` | Source evidence records a historical revision. | Diagnostic label only; not an upgrade hold. |
| `unavailable` | Current body or source identity cannot be read. | Stop and inspect. An unreadable recorded commit alone only makes the package diagnostic unavailable. |
| `derived` / `local` | A wrapper over a non-Skill upstream, or a locally authored Skill. | Not an upstream-update target; maintain deliberately. |

Declaration decides whether to keep an adaptation; provenance records where deployment came from; package comparison explains changes. `magnitude=light/heavy` is diagnostic size only, never upgrade permission. Compare all package files, not just `SKILL.md`; known UTF-8 text permits CRLF/LF equivalence, unknown/binary files require byte equality. Compare the actual current body to the target, even when recorded and target commits match. A root package covers the whole tracked repository tree; subdirectory packages exclude outside changes. Export raw Git blobs, preserving resources marked `export-ignore` or `export-subst`; renamed sources retain only the deployed frontmatter name.

Explicit hold, invalid policy, active user consumers, live/foreign sources, missing or conflicting source identity and stale body records remain guards across all active scopes. A pin alone is provenance, not an implicit hold. Shared registrations retain their default commit and use `skillCommits[deployed-name]` overrides; siblings keep their own effective commit, independent of mirror HEAD. Without an override, an explicitly held historical pin retains its original provenance meaning; a pin alone never creates a hold. Missing old objects with reliable package paths make diagnostics unavailable, not permission denied. The default survey may contact upstream, fetch mirror objects and write its report; it does not alter governed bodies, activation or registration, and its recommendations are not apply authorization.

## Boundary decision matrix

| Observed root | Classification | Skill contract | Permitted next step |
| --- | --- | --- | --- |
| Root owns the registry, Profiles, body pool, and control script | Workspace | Existing workspace control plane | Preview and apply only through that control script. |
| Scene container groups projects or session Profiles and has no independent delivery lifecycle | Workbench | Workbench-local Manifest/Profile if present | Keep aggregation local; inspect each nested Git root separately. |
| Directory is an independent Git root used for delivery | Project repository | Its own Manifest, or an explicit documented embedded-Skill exception | Start from that Git root; never assume parent workspace/workbench rules, Profiles, or Skills carry across the boundary. |
| Independent Git root is a curated, generalized derivative for external/public consumers on its own release cadence | Release artifact | Its own license/release manifest and provenance anchors back to its source | Govern at its own root and keep it out of every workbench's skill scope; generalize local-specific content before introduction and record the disposition plus the source anchor. |
| Nested Git root is upstream/reference/vendor material, not a session root | Dependency/mirror | Its own upstream dependency policy | Preserve it and exclude it from surrounding activation unless explicitly selected. |
| Repository is dirty, ahead, detached, linked, checkpoint-backed, or ambiguously classified | Protected review state | Existing state only | Produce read-only evidence, recovery requirements, and a user decision before mutation. |
| No registry/control script is discoverable at the target workspace | Unmanaged workspace | None yet | Warn and remain read-only; propose a control-plane contract without creating one. |

Parent-directory proximity never establishes inheritance. Filesystem entrypoint compatibility also never proves that an Agent loaded the parent rules or Skills across an independent Git boundary.
