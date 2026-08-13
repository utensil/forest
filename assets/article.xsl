<?xml version="1.0"?>
<!-- SPDX-License-Identifier: CC0-1.0 -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:f="http://www.forester-notes.org"
  xmlns:html="http://www.w3.org/1999/xhtml">

  <xsl:output method="text" encoding="utf-8" indent="yes" doctype-public="" doctype-system="" />

  <xsl:include href="latex.xsl" />

  <!-- AGENT-NOTE: A resource may recur through expansion; emit its hash once. -->
  <xsl:key name="resource-by-hash" match="f:resource" use="@hash" />
  
  <xsl:template match="/">
    <xsl:text>\input{an_article}</xsl:text>

    <xsl:apply-templates select="/f:tree/f:frontmatter" mode="top" />

    <xsl:text>\begin{document}</xsl:text>

    <xsl:for-each select="//f:resource[
      generate-id() = generate-id(key('resource-by-hash', @hash)[1])
    ]">
      <xsl:text>&#xa;</xsl:text>
      <xsl:text>\begin{filecontents*}[overwrite]{</xsl:text>
      <xsl:value-of select="@hash" />
      <xsl:text>.tex}</xsl:text>
      <xsl:text>&#xa;</xsl:text>
      <xsl:text>\documentclass[class=article,crop]{standalone}</xsl:text>
      <xsl:text>&#xa;</xsl:text>
      <xsl:value-of select="f:resource-source[@type='latex' and @part='preamble']" />
      <xsl:text>&#xa;</xsl:text>
      <xsl:text>\begin{document}</xsl:text>
      <xsl:value-of select="f:resource-source[@type='latex' and @part='body']" />
      <xsl:text>\end{document}</xsl:text>
      <xsl:text>&#xa;</xsl:text>
      <xsl:text>\end{filecontents*}</xsl:text>
      <xsl:text>&#xa;</xsl:text>
    </xsl:for-each>

    <xsl:text>&#xa;</xsl:text>
    <xsl:text>\begin{filecontents*}[overwrite]{\jobname.bib}</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="/f:tree/f:backmatter//f:tree[f:frontmatter/f:taxon[text()='Reference']]" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>\end{filecontents*}</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    
    <xsl:text>\maketitle</xsl:text>
    <xsl:apply-templates select="/f:tree/f:mainmatter" />
    <xsl:if test="count(/f:tree/f:backmatter//f:tree[f:frontmatter/f:taxon[text()='Reference']])>0">
      <!-- https://www.bibtex.com/s/bibliography-style-acmart-acm-reference-format/ -->
      <xsl:text>\bibliographystyle{ACM-Reference-Format}</xsl:text>
      <!-- https://www.bibtex.com/s/bibliography-style-misc-amsalpha/ -->
      <!-- <xsl:text>\bibliographystyle{amsalpha}</xsl:text> -->
      <xsl:text>\bibliography{\jobname.bib}</xsl:text>
    </xsl:if>
    <xsl:text>\printindex</xsl:text>
    <xsl:text>\end{document}</xsl:text>
  </xsl:template>

  <xsl:template match="/f:tree/f:mainmatter/f:tree[not(f:frontmatter/f:taxon) and not(@numbered='false')]/f:frontmatter/f:title">
    <xsl:text>\section{</xsl:text>
    <xsl:call-template name="section-title" />
    <xsl:text>}\forestsetformulasection{section}</xsl:text>
  </xsl:template>

  <xsl:template match="/f:tree/f:mainmatter/f:tree/f:mainmatter/f:tree[not(f:frontmatter/f:taxon) and not(@numbered='false')]/f:frontmatter/f:title">
    <xsl:text>\subsection{</xsl:text>
    <xsl:call-template name="section-title" />
    <xsl:text>}\forestsetformulasection{subsection}</xsl:text>
  </xsl:template>

  <xsl:template match="/f:tree/f:mainmatter/f:tree/f:mainmatter/f:tree/f:mainmatter/f:tree[not(f:frontmatter/f:taxon) and not(@numbered='false')]/f:frontmatter/f:title">
    <xsl:text>\subsubsection{</xsl:text>
    <xsl:call-template name="section-title" />
    <xsl:text>}\forestsetformulasection{subsubsection}</xsl:text>
  </xsl:template>

  <xsl:template match="/f:tree/f:mainmatter/f:tree/f:mainmatter/f:tree/f:mainmatter/f:tree/f:mainmatter/f:tree[not(f:frontmatter/f:taxon) and not(@numbered='false')]/f:frontmatter/f:title">
    <xsl:text>\subsubsubsection{</xsl:text>
    <xsl:call-template name="section-title" />
    <xsl:text>}\forestsetformulasection{paragraph}</xsl:text>
  </xsl:template>

  <xsl:template match="/f:tree/f:mainmatter/f:tree[not(f:frontmatter/f:taxon) and (@numbered='false')]/f:frontmatter/f:title">
    <xsl:text>\section*{</xsl:text>
    <xsl:call-template name="section-title" />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="/f:tree/f:mainmatter/f:tree/f:mainmatter/f:tree[not(f:frontmatter/f:taxon) and (@numbered='false')]/f:frontmatter/f:title">
    <xsl:text>\subsection*{</xsl:text>
    <xsl:call-template name="section-title" />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="/f:tree/f:mainmatter/f:tree/f:mainmatter/f:tree/f:mainmatter/f:tree[not(f:frontmatter/f:taxon) and (@numbered='false')]/f:frontmatter/f:title">
    <xsl:text>\subsubsection*{</xsl:text>
    <xsl:call-template name="section-title" />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="/f:tree/f:mainmatter/f:tree/f:mainmatter/f:tree/f:mainmatter/f:tree/f:mainmatter/f:tree[not(f:frontmatter/f:taxon) and (@numbered='false')]/f:frontmatter/f:title">
    <xsl:text>\subsubsubsection*{</xsl:text>
    <xsl:call-template name="section-title" />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <!-- AGENT-NOTE: Untyped note trees still carry Lean metadata and need a PDF-visible marker row. -->
  <xsl:template name="section-title">
    <xsl:apply-templates />
    <xsl:call-template name="lean-marker-metadata">
      <xsl:with-param name="frontmatter" select=".." />
      <xsl:with-param name="continuation" select="true()" />
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
