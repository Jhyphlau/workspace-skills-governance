---
name: workspace-skills-governance
description: Use when governing Skill inventory, installation, updates, deduplication, activation, deactivation, relocation, or verification across user, workspace, workbench, and project scopes.
metadata:
  version: "1.2.0"
  owner: "Johnny"
  review_cadence: "quarterly, and after any governance-flow or control-plane change"
---

# Workspace Skills Governance

Treat content provenance, activation, and Agent discovery as separate facts. Preserve project Git boundaries and protected user state.

1. **Discover.** Start at the requested scope or its own Git root. Read active rule files, then run `scripts/audit-workspace-skills.ps1` with explicit workspace and user roots. Locate Git roots, Agent entrypoints, bodies, registry records, Profiles, Manifests, consumers, junction metadata, and any existing control script.
2. **Classify.** Read [governance-model.md](references/governance-model.md). Classify every affected root as workspace, workbench, project repository, dependency/mirror, or protected review state. Make each independent Git repository self-contained; record uncertain boundaries for decision.
3. **Separate the axes.** Record editable source provenance, canonical body identity, declared activation, physical consumers, and runtime discovery independently. A source mirror is not a canonical body; a body is not active without an activation record; structural presence is not runtime proof.
4. **Preview, decide, apply.** Use the discovered control plane for every mutation. Preview its exact plan, obtain decisions for destructive or ambiguous boundary changes, then apply through that same tool. The audit script remains read-only. When no control plane exists, retain the warning and stop at inventory plus a proposed contract instead of creating governance state.
   For an approved upgrade or rollback of an existing canonical version, read [version replacement](references/version-replacement.md).
5. **Verify and close out.** Read [verification.md](references/verification.md). Re-run structural checks, collect runtime and external evidence separately, test recovery where change risk requires it, and report the required closeout fields with unresolved or protected state explicit.
