#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = []
# ///
"""Regression tests for the FTIP/FCAP/FGAP objective-format checker."""

from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("check_note_format", ROOT / "check-note-format.py")
assert SPEC and SPEC.loader
CHECKER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = CHECKER
SPEC.loader.exec_module(CHECKER)


class NoteFormatTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.trees = self.root / "trees"
        self.trees.mkdir()

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def write_tree(self, address: str, body: str) -> Path:
        path = self.trees / f"{address}.tree"
        path.write_text(body, encoding="utf-8")
        return path

    def parse(self, address: str, body: str):
        return CHECKER.parse_tree(self.write_tree(address, body), address.split("-", 1)[0])

    def test_construct_style_titles_and_kinds_are_recognized(self) -> None:
        cases = (
            ("card", r"\card{Theorem}{Card title}{\p{Body.}}", "Theorem", "Card title"),
            ("refcard", r"\refcard{Lemma}{Reference card}{source}{\p{Body.}}", "Lemma", "Reference card"),
            (
                "refcardt",
                r"\refcardt{Remark}{Title with \citet{2}{source}}{topic}{source}{\p{Body.}}",
                "Remark",
                r"Title with \citet{2}{source}",
            ),
            ("refdeft", r"\refdeft{Defined object}{topic}{source}{\p{Body.}}", "Definition", "Defined object"),
        )
        for index, (name, source, kind, title) in enumerate(cases):
            with self.subTest(name=name):
                tree = self.parse(f"ftip-X{index:03d}", f"\\tag{{ftip}}\n{source}\n")
                self.assertEqual((kind,), tree.kinds)
                self.assertEqual(title, tree.title)

    def test_nested_subtree_kind_does_not_duplicate_card_kind(self) -> None:
        tree = self.parse(
            "fcap-TEST",
            """\\tag{fcap}
\\taxon{Lemma}
\\title{Outer result}
\\subtree{
\\taxon{Proof}
\\p{Nested proof.}
}
""",
        )
        self.assertEqual(("Lemma",), tree.kinds)
        self.assertEqual("Outer result", tree.title)

    def test_inventory_distinguishes_wrappers_cards_and_constructs(self) -> None:
        root = self.parse(
            "ftip-0001",
            """\\tag{ftip}
\\title{Root}
\\p{Wrapper prose.}
\\transclude{ftip-0002}
\\transclude{ftip-0003}
""",
        )
        wrapper = self.parse("ftip-0002", "\\tag{ftip}\n\\title{Section}\n\\transclude{ftip-0004}\n")
        card = self.parse("ftip-0003", "\\tag{ftip}\n\\card{Remark}{Repeated}{\\p{One.}}\n")
        duplicate = self.parse("ftip-0004", "\\tag{ftip}\n\\taxon{Remark}\n\\title{Repeated}\n")
        inventory = CHECKER.build_inventory(
            {"ftip": {tree.address: tree for tree in (root, wrapper, card, duplicate)}}
        )
        self.assertEqual(["ftip-0001"], inventory["mixed_siblings"]["ftip"])
        self.assertEqual(["ftip-0001"], inventory["wrapper_prose"]["ftip"])
        self.assertEqual([["ftip-0003", "ftip-0004"]], inventory["duplicate_titles"]["ftip"])
        self.assertEqual([], inventory["untyped_terminal"]["ftip"])

    def test_nested_wrapper_prose_is_new_inventory_debt(self) -> None:
        wrapper = self.parse(
            "ftip-0001",
            """\\tag{ftip}
\\title{Root}
\\scope{\\p{Hidden prose.}}
\\transclude{ftip-0002}
""",
        )
        child = self.parse("ftip-0002", "\\tag{ftip}\n\\taxon{Remark}\n\\title{Child}\n")
        inventory = CHECKER.build_inventory(
            {"ftip": {tree.address: tree for tree in (wrapper, child)}}
        )
        self.assertEqual(["ftip-0001"], inventory["wrapper_prose"]["ftip"])

        findings: list[str] = []
        CHECKER._compare_inventory(
            findings, "wrapper_prose", "ftip", inventory["wrapper_prose"]["ftip"], []
        )
        self.assertEqual(["wrapper_prose: ftip: new debt: ftip-0001"], findings)

    def test_allowlist_comparison_rejects_new_and_stale_debt(self) -> None:
        findings: list[str] = []
        CHECKER._compare_inventory(findings, "rule", "ftip", ["kept", "new"], ["kept", "stale"])
        self.assertEqual(
            ["rule: ftip: new debt: new", "rule: ftip: stale allowlist entry: stale"], findings
        )

    def test_header_and_transclusion_spacing_fail_closed(self) -> None:
        tree = self.parse(
            "fgap-TEST",
            """\\import{macros}
\\meta{agent-authored}{true}
\\title{Bad header}
\\meta{pdf}{true}
\\tag{fgap}
\\transclude{fgap-A}
\\transclude{fgap-B}
""",
        )
        findings: list[str] = []
        CHECKER._check_header(tree, findings)
        CHECKER._check_transclusion_spacing(tree, findings)
        self.assertTrue(any(finding.startswith("header-spacing:") for finding in findings))
        self.assertTrue(any(finding.startswith("pdf-metadata:") for finding in findings))
        self.assertTrue(any(finding.startswith("transclusion-spacing:") for finding in findings))

    def test_retired_pages_are_marked_typed_and_outside_the_root_closure(self) -> None:
        root = self.parse(
            "ftip-0001",
            "\\tag{ftip}\n\\title{Root}\n\\transclude{ftip-LIVE}\n",
        )
        live = self.parse("ftip-LIVE", "\\tag{ftip}\n\\taxon{Remark}\n\\title{Live}\n")
        retired = self.parse(
            "ftip-OLD",
            "\\tag{ftip}\n\\tag{retired}\n\\taxon{Reference}\n\\title{Retired}\n",
        )
        findings: list[str] = []
        CHECKER.check_retired_ftip(
            {tree.address: tree for tree in (root, live, retired)}, ["ftip-OLD"], findings
        )
        self.assertEqual([], findings)

        CHECKER.check_retired_ftip(
            {tree.address: tree for tree in (root, live, retired)}, ["ftip-MISSING"], findings := []
        )
        self.assertTrue(any("missing expected page" in finding for finding in findings))
        self.assertTrue(any("untracked retired page" in finding for finding in findings))

    def test_repository_render_support_is_complete(self) -> None:
        findings: list[str] = []
        CHECKER.check_render_support(ROOT, findings)
        self.assertEqual([], findings)

    def test_repository_allowlist_matches_exactly(self) -> None:
        self.assertEqual([], CHECKER.check_repository(ROOT, ROOT / "note-format-allowlist.json"))


if __name__ == "__main__":
    unittest.main()
