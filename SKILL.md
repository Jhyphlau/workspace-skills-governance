---
name: workspace-skills-governance
description: Use when governing Skill inventory, installation, updates, lightweight task acceptance, old-baseline cleanup, deduplication, activation, deactivation, relocation, or verification across user, workspace, workbench, and project scopes.
metadata:
  version: "1.3.0"
  owner: "Johnny"
  review_cadence: "quarterly, and after any governance-flow or control-plane change"
---

# Workspace Skills Governance

Treat content provenance, activation, and Agent discovery as separate facts. Preserve project Git boundaries and protected user state.

1. **Discover.** Start at the requested scope or its own Git root and read active rules. For a targeted task, inspect only the affected Skill, exact bodies, relevant governance records and consumers; do not require a full inventory. For a workspace inventory request, run this skill's own [`scripts/audit-workspace-skills.ps1`](scripts/audit-workspace-skills.ps1) (bundled in this skill's `scripts/` directory, not the governance root's) with explicit roots where its scope fits. Locate the existing control plane; do not scan protected projects or legacy artifacts for context.
2. **Classify.** Read [governance-model.md](references/governance-model.md). Classify every affected root as workspace, workbench, project repository, dependency/mirror, or protected review state. Make each independent Git repository self-contained; record uncertain boundaries for decision.
3. **Separate the axes.** Record editable source provenance, canonical body identity, declared activation, physical consumers, and runtime discovery independently. A source mirror is not a canonical body; a body is not active without an activation record; structural presence is not runtime proof.
4. **Preview, decide, apply.** Use the discovered control plane for every mutation. Preview its exact plan, obtain decisions for destructive or ambiguous boundary changes, then apply through that same tool. The audit script remains read-only. When no control plane exists, retain the warning and stop at inventory plus a proposed contract instead of creating governance state.
   For upstream upgrades, use `upgrade-skill.ps1`'s declaration and source-identity gates; package comparison diagnoses changes, not permission. Do not bypass the orchestrator with manual import/replacement. For that workflow, or an approved local-source update or rollback, read [version replacement](references/version-replacement.md).
   For lightweight acceptance, read [verification.md](references/verification.md) and complete one minimal real task using only the designated Skill. For old-baseline cleanup, reuse valid task evidence and follow [version replacement](references/version-replacement.md#retire-an-unused-old-baseline): choose a proven stable body, preview one exact old package, and end its rollback purpose only with deletion authorization. Passing acceptance is not deletion permission; no scoring system, automatic latest selection or full-library GC.
5. **Verify and close out.** Read [verification.md](references/verification.md). Re-run structural checks, collect runtime and external evidence separately, test recovery where change risk requires it, and report the required closeout fields with unresolved or protected state explicit.
