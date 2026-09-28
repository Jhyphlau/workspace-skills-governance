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
- **Release artifact:** a curated, generalized derivative of a source, published for external consumers on its own versioned release cadence. It is not a workbench member and does not inherit a surrounding workbench's Profiles or Skills; its link to its source is provenance (recorded anchors and a disposition record), not co-location.
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

Each registered Skill also carries an **adaptation level**: how far its deployed body has diverged from its upstream source. This is a separate fact from the three axes — a body can be active (Activation) and still be verbatim, lightly, or heavily adapted relative to upstream. Compute it from your source/provenance registry's matched-or-diverged status plus a divergence-magnitude pass; do not infer it from activation or from structural presence.

| Level | Meaning | Upgrade strategy |
| --- | --- | --- |
| `verbatim` | Body content matches upstream at the recorded commit (`matched` / `matched-historical`). | Clean replace through the control plane (`replace-body`); semi-automatic. |
| `light` | Small local delta (few files / lines changed). | Rebase the local delta onto the new upstream, with review. |
| `heavy` | Large local delta or a redesign. | Merge the local adaptations onto the new upstream manually first; only then run the normal replacement flow. |
| `derived` | Local wrapper over a non-Skill upstream (no canonical upstream `SKILL.md`). | Do not update from upstream automatically; re-derive deliberately. |
| `local` | Locally authored; no upstream. | Not an upstream-update target. |

A `pinned-moved` result (upstream advanced past an intentional historical pin) is expected, not an automatic update; re-pinning is a deliberate decision. A read-only update survey can combine the noise-filtered update status with each Skill's adaptation level and the resulting triage.

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
