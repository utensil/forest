#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Compile an XML fixture through the PDF renderer and check numbering and links.

Run: uv run tests/pdf_numbering_test.py
Requires bun/xslt3, LuaLaTeX with Forest's TeX packages, and pdftotext.
Artifacts are retained under .agents/scripts/tmp for inspection.
"""

import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


def tree(address, title, taxon="", numbered="", body=""):
    attribute = f' numbered="{numbered}"' if numbered else ""
    taxon_xml = f"<f:taxon>{taxon}</f:taxon>" if taxon else ""
    return (
        f"<f:tree{attribute}><f:frontmatter><f:title>{title}</f:title>"
        f"{taxon_xml}<f:display-uri>{address}</f:display-uri></f:frontmatter>"
        f"<f:mainmatter>{body}</f:mainmatter></f:tree>"
    )


class PdfNumberingTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        scratch = ROOT / ".agents/scripts/tmp"
        scratch.mkdir(parents=True, exist_ok=True)
        cls.build = Path(tempfile.mkdtemp(prefix="pdf-numbering-", dir=scratch))
        print(f"PDF regression artifacts: {cls.build}", flush=True)
        references = (
            '<html:p>References: <f:ref display-uri="guide"/>; '
            '<f:ref display-uri="aside"/>; '
            '<f:link type="local" display-uri="claim">Theorem <f:contextual-number/></f:link>. '
            '<f:link type="local" display-uri="aside">Named aside</f:link>.'
            "</html:p>"
        )
        fixture = (
            '<f:tree xmlns:f="http://www.forester-notes.org" '
            'xmlns:html="http://www.w3.org/1999/xhtml">'
            "<f:frontmatter><f:title>Numbering fixture</f:title></f:frontmatter>"
            "<f:mainmatter>"
            + references
            + tree("guide", "Reader guide", "Remark", "false", "Guide body.")
            + tree(
                "foundations", "Foundations", body=(
                    tree("claim", "First claim", "Theorem", body="Claim body.")
                    + tree("aside", "Later aside", "Remark", "false", "Aside body.")
                    + tree("next", "Next claim", "Proposition", "true", "Next body.")
                    + tree("details", "Details", body=(
                        tree("deep-aside", "Deep aside", "Remark", "false", "Deep body.")
                        + tree("deep-claim", "Deep claim", "Conjecture", body="Deep claim body.")
                    ))
                )
            )
            + tree("last", "Last chapter", body=references)
            + "</f:mainmatter></f:tree>"
        )
        (cls.build / "fixture.xml").write_text(fixture)
        cls.run_tool([
            "bunx", "xslt3", f"-s:{cls.build / 'fixture.xml'}",
            f"-xsl:{ROOT / 'assets/article.xsl'}", f"-o:{cls.build / 'fixture.tex'}",
        ], ROOT)
        cls.tex = (cls.build / "fixture.tex").read_text()
        env = dict(os.environ, TEXINPUTS=f".:{ROOT / 'tex'}:")
        for _ in range(3):
            cls.run_tool([
                "lualatex", "-halt-on-error", "-interaction=nonstopmode", "fixture.tex",
            ], cls.build, env)
        cls.run_tool(["pdftotext", "-layout", "fixture.pdf", "fixture.txt"], cls.build)
        cls.pdf_text = " ".join((cls.build / "fixture.txt").read_text().split())
        cls.aux = (cls.build / "fixture.aux").read_text()
        cls.log = (cls.build / "fixture.log").read_text()

    @classmethod
    def run_tool(cls, command, cwd, env=None):
        result = subprocess.run(command, cwd=cwd, env=env, capture_output=True, text=True)
        with (cls.build / "commands.log").open("a") as log:
            log.write(f"$ {' '.join(map(str, command))}\n{result.stdout}{result.stderr}\n")
        if result.returncode:
            raise RuntimeError(f"{command[0]} failed; see {cls.build / 'commands.log'}")

    def label(self, address):
        match = re.search(
            r"\\newlabel\{" + re.escape(address) + r"\}\{\{([^{}]*)\}\{[^{}]*\}\{[^{}]*\}\{([^{}]*)\}",
            self.aux,
        )
        self.assertIsNotNone(match, f"Missing PDF label: {address}")
        return match.groups()

    def test_structural_counters(self):
        for address, number in {
            "guide": "", "foundations": "1", "claim": "1.1", "aside": "",
            "next": "1.2", "details": "1.3", "deep-aside": "",
            "deep-claim": "1.3.1", "last": "2",
        }.items():
            with self.subTest(address=address):
                self.assertEqual(self.label(address)[0], number)

    def test_visible_headings_and_references(self):
        for heading in (
            "Remark (Reader guide)", "1 Foundations", "Theorem 1.1 (First claim)",
            "Remark (Later aside)", "Proposition 1.2 (Next claim)",
            "Remark (Deep aside)", "Conjecture 1.3.1 (Deep claim)", "2 Last chapter",
        ):
            with self.subTest(heading=heading):
                self.assertIn(heading, self.pdf_text)
        self.assertIn(
            "References: Remark (Reader guide); Remark (Later aside); Theorem 1.1. Named aside.",
            self.pdf_text,
        )
        self.assertNotIn("\\Cref{guide}", self.tex)
        self.assertNotIn("\\Cref{aside}", self.tex)

    def test_distinct_link_destinations(self):
        addresses = ("guide", "foundations", "claim", "aside", "next", "deep-aside", "deep-claim")
        anchors = [self.label(address)[1] for address in addresses]
        self.assertTrue(all(anchors))
        self.assertEqual(len(anchors), len(set(anchors)))
        for warning in ("undefined", "multiply defined", "duplicate destination"):
            self.assertNotIn(warning, self.log.lower())


if __name__ == "__main__":
    unittest.main()
