#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = []
# ///
"""Regression tests for prefix-specific tree template selection."""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

SERIES_ARCHITECTURE = {
    "ftip": ("ftip-macros", "macros"),
    "fcap": ("fcap-macros", "spin-macros"),
    "fgap": ("fgap-macros", "lean-macros"),
}
MACRO_IMPORT = re.compile(r"^\\import\{(?:macros|[^{}]+-macros)\}$", re.MULTILINE)
EXPORT = re.compile(r"^\\export\{([^{}]+)\}$", re.MULTILINE)


class NewTemplateTests(unittest.TestCase):
    def run_new(self, prefix: str) -> tuple[str, str, str]:
        with tempfile.TemporaryDirectory() as temporary:
            sandbox = Path(temporary)
            templates = sandbox / "templates"
            trees = sandbox / "trees"
            fake_bin = sandbox / "bin"
            templates.mkdir()
            trees.mkdir()
            fake_bin.mkdir()

            for template in (ROOT / "templates").glob("*.tree"):
                shutil.copyfile(template, templates / template.name)

            opam_log = sandbox / "opam.log"
            fake_opam = fake_bin / "opam"
            fake_opam.write_text(
                '#!/bin/sh\nprintf \'%s\\n\' "$*" > "$FAKE_OPAM_LOG"\nprintf \'trees/generated.tree\\n\'\n',
                encoding="utf-8",
            )
            fake_opam.chmod(0o755)

            environment = os.environ.copy()
            environment["PATH"] = f"{fake_bin}{os.pathsep}{environment['PATH']}"
            environment["FAKE_OPAM_LOG"] = str(opam_log)
            result = subprocess.run(
                [str(ROOT / "new.sh"), prefix],
                cwd=sandbox,
                env=environment,
                check=True,
                capture_output=True,
                text=True,
            )

            generated = (trees / "generated.tree").read_text(encoding="utf-8")
            invocation = opam_log.read_text(encoding="utf-8").strip()
            return result.stdout.strip(), generated, invocation

    def test_series_prefixes_select_dedicated_templates(self) -> None:
        for prefix in SERIES_ARCHITECTURE:
            with self.subTest(prefix=prefix):
                filename, generated, invocation = self.run_new(prefix)
                expected = (ROOT / "templates" / f"{prefix}.tree").read_text(
                    encoding="utf-8"
                )
                self.assertEqual("trees/generated.tree", filename)
                self.assertEqual(expected, generated)
                self.assertEqual(
                    f"exec -- forester new --dest=trees --prefix={prefix}",
                    invocation,
                )

    def test_unknown_prefix_uses_ag_fallback(self) -> None:
        filename, generated, invocation = self.run_new("unknown")
        self.assertEqual("trees/generated.tree", filename)
        self.assertEqual((ROOT / "templates/ag.tree").read_text(encoding="utf-8"), generated)
        self.assertEqual("exec -- forester new --dest=trees --prefix=unknown", invocation)

    def test_series_notes_import_only_their_facade(self) -> None:
        for prefix, (facade, _) in SERIES_ARCHITECTURE.items():
            for note in sorted((ROOT / "trees").glob(f"{prefix}-*.tree")):
                if note.name == f"{facade}.tree":
                    continue
                with self.subTest(note=note.name):
                    imports = MACRO_IMPORT.findall(note.read_text(encoding="utf-8"))
                    self.assertEqual([f"\\import{{{facade}}}"], imports)

    def test_series_facades_export_their_parent(self) -> None:
        for prefix, (facade, parent) in SERIES_ARCHITECTURE.items():
            with self.subTest(prefix=prefix):
                source = (ROOT / "trees" / f"{facade}.tree").read_text(
                    encoding="utf-8"
                )
                self.assertEqual([parent], EXPORT.findall(source))


if __name__ == "__main__":
    unittest.main()
