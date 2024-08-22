<?xml version="1.0"?>
<!-- SPDX-License-Identifier: CC0-1.0 -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:f="http://www.jonmsterling.com/jms-005P.xml">

  <xsl:output method="text" encoding="utf-8" indent="yes" doctype-public="" doctype-system="" />

  <xsl:include href="latex.xsl" />
  
  <xsl:template match="/">
    <xsl:text>\input{a_book}</xsl:text>

    <xsl:apply-templates select="/f:tree/f:frontmatter" mode="top" />

    <xsl:text>\begin{document}</xsl:text>

    <xsl:for-each select="//f:resource[not(ancestor::f:backmatter)]">
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
    
    <xsl:text>\frontmatter\maketitle\tableofcontents\mainmatter</xsl:text>
    <xsl:apply-templates select="/f:tree/f:mainmatter" />
    <xsl:text>\backmatter</xsl:text>
    <xsl:text>\nocite{*}</xsl:text>
    <xsl:text>\bibliographystyle{ACM-Reference-Format}</xsl:text>
    <xsl:text>\bibliography{\jobname.bib}</xsl:text>
    <xsl:text>\printindex</xsl:text>
    <xsl:text>\end{document}</xsl:text>
  </xsl:template>

  <xsl:template match="/f:tree/f:mainmatter/f:tree[not(f:frontmatter/f:taxon)]/f:frontmatter/f:title">
    <xsl:text>\chapter{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="/f:tree/f:mainmatter/f:tree/f:mainmatter/f:tree[not(f:frontmatter/f:taxon)]/f:frontmatter/f:title">
    <xsl:text>\section{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="/f:tree/f:mainmatter/f:tree/f:mainmatter/f:tree/f:mainmatter/f:tree[not(f:frontmatter/f:taxon)]/f:frontmatter/f:title">
    <xsl:text>\subsection{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="/f:tree/f:mainmatter/f:tree/f:mainmatter/f:tree/f:mainmatter/f:tree/f:mainmatter/f:tree[not(f:frontmatter/f:taxon)]/f:frontmatter/f:title">
    <xsl:text>\subsubsection{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
  </xsl:template>

</xsl:stylesheet>