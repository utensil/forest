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

SERIES_FACADES = {
    "ftip": "ftip-macros",
    "fcap": "fcap-macros",
    "fgap": "fgap-macros",
}
PROVIDER_EXPORTS = {
    "ftip-macros": ["macros"],
    "fgap-macros": ["macros", "lean-macros"],
    "fcap-macros": ["spin-macros"],
    "spin-macros": ["macros", "lean-macros"],
    "lean-macros": [],
}
ADJUDICATED_DEFINITION_OWNERS = {
    "bu": "macros",
    "ii": "macros",
    "placeholder": "macros",
    "optional": "macros",
    "pre": "macros",
    "linebreak": "lean-macros",
    "label": "lean-macros",
    "leanok": "lean-macros",
    "uses": "lean-macros",
}
MACRO_IMPORT = re.compile(r"^\\import\{(?:macros|[^{}]+-macros)\}$", re.MULTILINE)
IMPORT = re.compile(r"^\\import\{([^{}]+)\}$", re.MULTILINE)
EXPORT = re.compile(r"^\\export\{([^{}]+)\}$", re.MULTILINE)
DEFINITION = re.compile(r"^\\def\\([^\s\[{]+)", re.MULTILINE)


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
        for prefix, facade in SERIES_FACADES.items():
            with self.subTest(prefix=prefix):
                filename, generated, invocation = self.run_new(prefix)
                expected = (ROOT / "templates" / f"{prefix}.tree").read_text(
                    encoding="utf-8"
                )
                self.assertEqual(
                    [f"\\import{{{facade}}}"], MACRO_IMPORT.findall(expected)
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
        for prefix, facade in SERIES_FACADES.items():
            for note in sorted((ROOT / "trees").glob(f"{prefix}-*.tree")):
                if note.name == f"{facade}.tree":
                    continue
                with self.subTest(note=note.name):
                    imports = MACRO_IMPORT.findall(note.read_text(encoding="utf-8"))
                    self.assertEqual([f"\\import{{{facade}}}"], imports)

    def test_architecture_providers_have_explicit_exports(self) -> None:
        for provider, expected_exports in PROVIDER_EXPORTS.items():
            with self.subTest(provider=provider):
                source = (ROOT / "trees" / f"{provider}.tree").read_text(
                    encoding="utf-8"
                )
                exports = EXPORT.findall(source)
                self.assertEqual(len(exports), len(set(exports)))
                self.assertEqual(expected_exports, exports)
                self.assertEqual([], IMPORT.findall(source))

    def test_composed_macro_layers_have_unique_definition_ownership(self) -> None:
        definition_owners = {}
        for provider in ("macros", "lean-macros", "spin-macros"):
            source = (ROOT / "trees" / f"{provider}.tree").read_text(
                encoding="utf-8"
            )
            definitions = DEFINITION.findall(source)
            with self.subTest(provider=provider):
                self.assertEqual(len(definitions), len(set(definitions)))
            for definition in definitions:
                self.assertNotIn(definition, definition_owners)
                definition_owners[definition] = provider

        self.assertNotIn("cite", definition_owners)
        for definition, expected_owner in ADJUDICATED_DEFINITION_OWNERS.items():
            with self.subTest(definition=definition):
                self.assertEqual(expected_owner, definition_owners.get(definition))


if __name__ == "__main__":
    unittest.main()
