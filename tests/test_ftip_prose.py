#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11,<3.12"
# dependencies = []
# ///
"""Regression tests for the bounded FTIP reader-prose checker."""

from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("check_ftip_prose", ROOT / "check-ftip-prose.py")
assert SPEC and SPEC.loader
CHECKER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = CHECKER
SPEC.loader.exec_module(CHECKER)


class FtipProseTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.trees = self.root / "trees"
        self.output = self.root / "output"
        self.trees.mkdir()
        self.output.mkdir()

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def write_tree(self, name: str, body: str) -> Path:
        path = self.trees / f"{name}.tree"
        path.write_text(body, encoding="utf-8")
        return path

    def write_html(self, name: str, body: str) -> Path:
        directory = self.output / name
        directory.mkdir(exist_ok=True)
        path = directory / "index.html"
        path.write_text(f"<html><head><title>FTIP</title></head><body>{body}</body></html>", encoding="utf-8")
        return path

    def rule_ids(self, findings: list[object]) -> set[str]:
        return {finding.rule.rule_id for finding in findings}

    def test_pr173_phrases_and_detached_page_fail(self) -> None:
        self.write_tree("ftip-0001", r"\title{Substantive root}\p{A finite theorem follows.}")
        self.write_tree(
            "ftip-DETACHED",
            r"\title{Source reconstruction}\p{The DGG cards retain their source locators and transfer limits.}",
        )
        ids = self.rule_ids(CHECKER.check_source(self.trees))
        self.assertTrue({"FTIP-CARD", "FTIP-SOURCE-LOCATOR", "FTIP-TRANSFER-LIMIT"} <= ids)

    def test_inline_code_hyphen_unicode_spacing_and_plural_forms_fail(self) -> None:
        path = self.write_tree(
            "ftip-0001",
            "\\p{A \\code{source locator}, source\u2011locators, and source lo\\strong{cators} expose transfer\u00a0limits.}",
        )
        findings = CHECKER.scan_text(path, *CHECKER._source_text(path))
        ids = self.rule_ids(findings)
        self.assertIn("FTIP-SOURCE-LOCATOR", ids)
        self.assertIn("FTIP-TRANSFER-LIMIT", ids)
        self.assertGreaterEqual(sum(f.rule.rule_id == "FTIP-SOURCE-LOCATOR" for f in findings), 3)

    def test_math_macros_urls_comments_metadata_and_model_cards_pass(self) -> None:
        self.write_tree(
            "ftip-0001",
            """% Drafting checklist source locator
\\import{cards}
\\meta{agent-authored}{drafted}
\\tag{transfer-limit}
\\title{Model-card evaluation and cardinal feedback}
\\p{A model card and a system card report transfer learning and a transfer matrix.
The typed signature is a mathematical object. See https://source-locator.example/cards.}
\\p{The quantity #{\\operatorname{transfer}} is symbolic.}
\\refcardt{Theorem}{x}{y}{z}{A substantive result.}
""",
        )
        self.assertEqual([], CHECKER.check_source(self.trees))

    def test_text_inside_math_cannot_hide_authoring_phrase(self) -> None:
        path = self.write_tree("ftip-0001", r"\p{The label #{\text{source locator}} is rejected.}")
        findings = CHECKER.scan_text(path, *CHECKER._source_text(path))
        self.assertIn("FTIP-SOURCE-LOCATOR", self.rule_ids(findings))

    def test_tex_text_commands_cannot_hide_authoring_phrases(self) -> None:
        text_commands = (
            "text",
            "textrm",
            "textsf",
            "texttt",
            "textnormal",
            "textbf",
            "textmd",
            "textit",
            "textup",
            "emph",
            "mbox",
        )
        cases = tuple((command, "source locator", "FTIP-SOURCE-LOCATOR") for command in text_commands)
        cases += (("textit", "transfer limits", "FTIP-TRANSFER-LIMIT"),)
        for command, phrase, expected in cases:
            with self.subTest(command=command):
                self.write_tree("ftip-0001", f"\\p{{#{{\\{command}{{{phrase}}}}}}}")
                self.write_html("ftip-0001", f"<p>\\(\\{command}{{{phrase}}}\\)</p>")
                self.assertIn(expected, self.rule_ids(CHECKER.check_source(self.trees)))
                self.assertIn(expected, self.rule_ids(CHECKER.check_render(self.trees, self.output)))

    def test_nested_math_and_source_inline_markup_rejoin_visible_words(self) -> None:
        self.write_tree(
            "ftip-0001",
            r"\p{#{\text{source lo\textbf{cator}}}, #{\text{source lo}\text{cator}}, and source lo\strong{cator}.}",
        )
        self.write_html(
            "ftip-0001",
            r"<p>\(\text{source lo\textbf{cator}}\), \(\text{source lo}\text{cator}\)</p>",
        )
        source_findings = CHECKER.check_source(self.trees)
        rendered_findings = CHECKER.check_render(self.trees, self.output)
        self.assertEqual(3, sum(f.rule.rule_id == "FTIP-SOURCE-LOCATOR" for f in source_findings))
        self.assertEqual(2, sum(f.rule.rule_id == "FTIP-SOURCE-LOCATOR" for f in rendered_findings))

    def test_math_grouping_braces_do_not_hide_text(self) -> None:
        cases = (
            (r"#{\text{source lo{\textbf{cator}}}}", r"\(\text{source lo{\textbf{cator}}}\)"),
            (r"#{\text{source lo}{\text{cator}}}", r"\(\text{source lo}{\text{cator}}\)"),
            (r"#{\text{source lo{{{\textbf{cator}}}}}}", r"\(\text{source lo{{{\textbf{cator}}}}}\)"),
        )
        for source_math, rendered_math in cases:
            with self.subTest(source_math=source_math):
                self.write_tree("ftip-0001", f"\\p{{{source_math}}}")
                self.write_html("ftip-0001", f"<p>{rendered_math}</p>")
                source_findings = CHECKER.check_source(self.trees)
                rendered_findings = CHECKER.check_render(self.trees, self.output)
                self.assertEqual(1, sum(f.rule.rule_id == "FTIP-SOURCE-LOCATOR" for f in source_findings))
                self.assertEqual(1, sum(f.rule.rule_id == "FTIP-SOURCE-LOCATOR" for f in rendered_findings))

    def test_math_whitespace_between_text_spans_is_zero_width(self) -> None:
        separators = (" ", "\n", "\t", "{ \n\t }")
        for separator in separators:
            with self.subTest(separator=repr(separator)):
                source_math = f"#{{\\text{{source lo}}{separator}\\text{{cator}}}}"
                rendered_math = f"\\(\\text{{source lo}}{separator}\\text{{cator}}\\)"
                self.write_tree("ftip-0001", f"\\p{{{source_math}}}")
                self.write_html("ftip-0001", f"<p>{rendered_math}</p>")
                source_findings = CHECKER.check_source(self.trees)
                rendered_findings = CHECKER.check_render(self.trees, self.output)
                self.assertEqual(1, sum(f.rule.rule_id == "FTIP-SOURCE-LOCATOR" for f in source_findings))
                self.assertEqual(1, sum(f.rule.rule_id == "FTIP-SOURCE-LOCATOR" for f in rendered_findings))

    def test_math_symbols_separate_text_payloads(self) -> None:
        self.write_tree("ftip-0001", r"\p{#{\text{source}\alpha\text{ locator}}}")
        self.write_html("ftip-0001", r"<p>\(\text{source}\alpha\text{ locator}\)</p>")
        self.assertEqual([], CHECKER.check_source(self.trees))
        self.assertEqual([], CHECKER.check_render(self.trees, self.output))

    def test_escaped_literal_math_brace_remains_visible(self) -> None:
        self.write_tree("ftip-0001", r"\p{#{\text{source \{ locator}}}")
        self.write_html("ftip-0001", r"<p>\(\text{source \{ locator}\)</p>")
        self.assertEqual([], CHECKER.check_source(self.trees))
        self.assertEqual([], CHECKER.check_render(self.trees, self.output))

    def test_research_uses_of_process_words_pass(self) -> None:
        self.write_tree(
            "ftip-0001",
            r"\p{A speculative-decoding draft model hands state to a worker. The dependency graph order is topological. A scheduler's ready set contains tasks whose dependencies have completed. A status field records the grader release criterion. The protocol handoff preserves a typed signature.}",
        )
        self.write_html(
            "ftip-0001",
            "<p>A scheduler's ready set contains tasks whose dependencies have completed.</p>",
        )
        self.assertEqual([], CHECKER.check_source(self.trees))
        self.assertEqual([], CHECKER.check_render(self.trees, self.output))

    def test_precise_authoring_compounds_fail(self) -> None:
        cases = {
            "the theorem ledger is complete": "FTIP-LEDGER-NARRATION",
            "this result is ledger-ready": "FTIP-READINESS",
            "a Lean handoff follows": "FTIP-HANDOFF",
            "a machine-checkable statement signature": "FTIP-SIGNATURE-NARRATION",
            "the proof owner is named": "FTIP-OWNER-NARRATION",
            "the formalizer import order": "FTIP-ORDER-NARRATION",
            "the statement record status field": "FTIP-RECORD-NARRATION",
            "use the next lane": "FTIP-LANE",
            "a future card will prove this": "FTIP-CARD-SEQUENCE",
            "the prerequisite card is imported": "FTIP-IMPORT-NARRATION",
            "the formalizer should proceed": "FTIP-FORMALIZER",
            "freeze the statements": "FTIP-FREEZE-NARRATION",
            "translate each signature into theorem statements": "FTIP-LEAN-TRANSLATION",
            "choose a probability library": "FTIP-LEAN-CHOICES",
            "the prose drafting process": "FTIP-DRAFT-NARRATION",
            "the release checklist": "FTIP-CHECKLIST-NARRATION",
            "transclusion maintenance": "FTIP-STRUCTURE-NARRATION",
            "list the backward dependencies": "FTIP-BACKWARD-DEPENDENCIES",
        }
        for index, (phrase, expected) in enumerate(cases.items()):
            with self.subTest(phrase=phrase):
                path = self.write_tree(f"ftip-{index:04d}", f"\\p{{{phrase}.}}")
                self.assertIn(expected, self.rule_ids(CHECKER.scan_text(path, *CHECKER._source_text(path))))

    def test_malformed_source_fails_closed(self) -> None:
        self.write_tree("ftip-0001", r"\title{Broken reader text")
        with self.assertRaises(CHECKER.CheckError):
            CHECKER.check_source(self.trees)

    def test_missing_source_and_render_output_fail_closed(self) -> None:
        with self.assertRaises(CHECKER.CheckError):
            CHECKER.check_source(self.root / "missing")
        self.write_tree("ftip-0001", r"\title{A result}")
        with self.assertRaises(CHECKER.CheckError):
            CHECKER.check_render(self.trees, self.output)

    def test_render_scans_split_words_and_backlink_title(self) -> None:
        self.write_tree("ftip-0001", r"\title{A clean source page}")
        self.write_tree("ftip-0002", r"\title{Another clean source page}")
        self.write_html("ftip-0001", '<nav>Related</nav><a title="source locator">A result</a>')
        self.write_html("ftip-0002", "<p>source lo<em>cators</em></p>")
        findings = CHECKER.check_render(self.trees, self.output)
        self.assertIn("FTIP-SOURCE-LOCATOR", self.rule_ids(findings))

    def test_render_excludes_math_and_required_agent_badge(self) -> None:
        self.write_tree("ftip-0001", r"\title{A clean source page}")
        self.write_html(
            "ftip-0001",
            '<span class="agent-authored-watermark" title="Agent drafted">AGENT DRAFTED</span>'
            "<math><annotation>source locator</annotation></math>"
            r"<p>\(\operatorname{card}(X)\) is cardinal notation. A model card measures transfer learning.</p>",
        )
        self.assertEqual([], CHECKER.check_render(self.trees, self.output))

    def test_render_preserves_visible_math_text(self) -> None:
        self.write_tree("ftip-0001", r"\title{A clean source page}")
        self.write_html("ftip-0001", r"<p>\(\text{source locators}\)</p><math><mtext>transfer limits</mtext></math>")
        ids = self.rule_ids(CHECKER.check_render(self.trees, self.output))
        self.assertIn("FTIP-TRANSFER-LIMIT", ids)
        self.assertIn("FTIP-SOURCE-LOCATOR", ids)

    def test_render_does_not_join_separate_blocks(self) -> None:
        self.write_tree("ftip-0001", r"\title{A clean source page}")
        self.write_html("ftip-0001", "<p>source</p><p>locator</p>")
        self.assertEqual([], CHECKER.check_render(self.trees, self.output))

    def test_render_parse_failure_is_fatal(self) -> None:
        self.write_tree("ftip-0001", r"\title{A clean source page}")
        directory = self.output / "ftip-0001"
        directory.mkdir()
        (directory / "index.html").write_text("<html><body><script>", encoding="utf-8")
        with self.assertRaises(CHECKER.CheckError):
            CHECKER.check_render(self.trees, self.output)


if __name__ == "__main__":
    unittest.main()
