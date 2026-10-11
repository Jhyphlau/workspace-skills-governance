"""Package integrity tests for workspace-skills-governance."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class PackageIntegrityTests(unittest.TestCase):
    def test_manifest_required_fields(self) -> None:
        manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8-sig"))
        for field in ("name", "version", "owner", "updated_at", "status", "maturity_tier"):
            self.assertIn(field, manifest)
        self.assertEqual(manifest["name"], "workspace-skills-governance")

    def test_skill_frontmatter_has_name_and_description(self) -> None:
        text = (ROOT / "SKILL.md").read_text(encoding="utf-8")
        self.assertTrue(text.startswith("---\n"))
        frontmatter = text.split("---\n", 2)[1]
        self.assertRegex(frontmatter, r"(?m)^name:\s*workspace-skills-governance\s*$")
        self.assertRegex(frontmatter, r"(?m)^description:\s*\S")
        version = re.search(r'(?m)^\s*version:\s*"?([\d.]+)"?\s*$', frontmatter)
        manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8-sig"))
        self.assertIsNotNone(version)
        self.assertEqual(version.group(1), manifest["version"])

    def test_bundled_resources_exist(self) -> None:
        for relative in (
            "scripts/audit-workspace-skills.ps1",
            "references/governance-model.md",
            "references/verification.md",
            "references/version-replacement.md",
            "agents/interface.yaml",
            "evals/trigger_cases.json",
            "LICENSE",
        ):
            self.assertTrue((ROOT / relative).is_file(), relative)


if __name__ == "__main__":
    unittest.main()
