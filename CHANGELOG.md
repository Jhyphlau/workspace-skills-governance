# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/2.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.1] - 2026-09-29

### Changed

- State where release artifacts are collected: a dedicated `released-repos/`
  area beside the canonical body pool, a container whose members are each an
  independent Git root governed at its own root, holding no Git history or
  Skill activation of its own.

## [1.2.0] - 2026-09-28

### Added

- Adaptation levels in the governance model: every registered Skill is classified
  as `verbatim`, `light`, `heavy`, `derived`, or `local`, each with an upgrade
  strategy — clean replace, rebase the local delta with review, manual merge
  first, or no upstream update. This lets an upgrade run tell at a glance which
  Skills can be replaced safely and which carry local adaptations that need care.
- A Release artifact classification in the boundary decision matrix: a curated,
  generalized derivative for external consumers is governed at its own root and
  kept out of every workbench's Skill scope; local-specific content is
  generalized before introduction, and the disposition plus source anchor is
  recorded.
- Guidance to run an update survey before upgrading, so each Skill's adaptation
  level is known before any replacement.

## [1.1.0] - 2026-09-28

### Added

- First public release: a governance methodology plus a read-only audit script
  for managing a shared pool of agent Skills across user, workspace, workbench,
  and project scopes.
- A three-axis model that keeps provenance, activation, and runtime discovery
  independent, so a file on disk is never mistaken for an active or loaded Skill.
- An evidence-level model (structural / runtime / external) and a closeout
  contract that keep strong structural results from masquerading as runtime or
  upstream proof.
- A version-replacement workflow with preview, plan hash, automatic backup, and
  rollback for upgrading or rolling back a canonical Skill version.
- `scripts/audit-workspace-skills.ps1`, a read-only inventory tool that maps Git
  roots, agent entrypoints, bodies, registry records, Profiles/Manifests,
  consumers, and junction metadata for a scope.

[unreleased]: https://github.com/Jhyphlau/workspace-skills-governance/compare/v1.2.1...HEAD
[1.2.1]: https://github.com/Jhyphlau/workspace-skills-governance/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/Jhyphlau/workspace-skills-governance/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/Jhyphlau/workspace-skills-governance/releases/tag/v1.1.0
