<?xml version="1.0"?>
<!-- SPDX-License-Identifier: CC0-1.0 -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:f="http://www.jonmsterling.com/jms-005P.xml">

  <xsl:output method="text" encoding="utf-8" indent="yes" doctype-public="" doctype-system="" />
  
  <xsl:template match="/">
    <xsl:text>\documentclass[oneside,a4paper]{book}</xsl:text>
    <xsl:text>\usepackage[final]{microtype}</xsl:text>
    <xsl:text>\usepackage{amsthm,mathtools}</xsl:text>
    <!-- <xsl:text>\usepackage[inline]{showlabels}</xsl:text> -->
    <xsl:text>\usepackage{xcolor}</xsl:text>
    <xsl:text>\usepackage[colorlinks=true,linkcolor={blue!30!black}]{hyperref}</xsl:text>
    <xsl:text>\newtheorem{theorem}{Theorem}[chapter]</xsl:text>
    <xsl:text>\newtheorem{lemma}[theorem]{Lemma}</xsl:text>
    <xsl:text>\newtheorem{observation}[theorem]{Observation}</xsl:text>
    <xsl:text>\newtheorem{axiom}[theorem]{Axiom}</xsl:text>
    <xsl:text>\newtheorem{corollary}[theorem]{Corollary}</xsl:text>
    <xsl:text>\theoremstyle{definition}</xsl:text>
    <xsl:text>\newtheorem{definition}[theorem]{Definition}</xsl:text>
    <xsl:text>\newtheorem{construction}[theorem]{Construction}</xsl:text>
    <xsl:text>\newtheorem{example}[theorem]{Example}</xsl:text>
    <xsl:text>\newtheorem{convention}[theorem]{Convention}</xsl:text>
    <xsl:text>\newtheorem{exercise}{Exercise}</xsl:text>
    <xsl:text>\usepackage{newtxmath,newtxtext}</xsl:text>
    <xsl:text>\usepackage[mode=buildmissing]{standalone}</xsl:text>
    <xsl:text>\setcounter{tocdepth}{5}</xsl:text>
    <xsl:text>\setcounter{secnumdepth}{5}</xsl:text>

    <xsl:apply-templates select="/f:tree/f:frontmatter" mode="top" />

    <xsl:text>\begin{document}</xsl:text>

    <xsl:for-each select="//f:embedded-tex[not(ancestor::f:backmatter)]">
      <xsl:text>&#xa;</xsl:text>
      <xsl:text>\begin{filecontents*}[overwrite]{</xsl:text>
      <xsl:value-of select="@hash" />
      <xsl:text>.tex}</xsl:text>
      <xsl:text>&#xa;</xsl:text>
      <xsl:text>\documentclass[crop]{standalone}</xsl:text>
      <xsl:text>&#xa;</xsl:text>
      <xsl:value-of select="f:embedded-tex-preamble" />
      <xsl:text>\usepackage{newtxmath,newtxtext}</xsl:text>
      <xsl:text>&#xa;</xsl:text>
      <xsl:text>\begin{document}</xsl:text>
      <xsl:value-of select="f:embedded-tex-body" />
      <xsl:text>\end{document}</xsl:text>
      <xsl:text>&#xa;</xsl:text>
      <xsl:text>\end{filecontents*}</xsl:text>
      <xsl:text>&#xa;</xsl:text>
    </xsl:for-each>

    <xsl:apply-templates select="/f:tree/f:backmatter/f:references" />
    <xsl:text>\frontmatter\maketitle\tableofcontents\mainmatter</xsl:text>
    <xsl:apply-templates select="/f:tree/f:mainmatter" />
    <xsl:text>\backmatter</xsl:text>
    <xsl:text>\nocite{*}</xsl:text>
    <xsl:text>\bibliographystyle{plain}</xsl:text>
    <xsl:text>\bibliography{\jobname.bib}</xsl:text>
    <xsl:text>\end{document}</xsl:text>
  </xsl:template>

  <xsl:template match="/f:tree/f:backmatter/f:references">
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>\begin{filecontents*}[overwrite]{\jobname.bib}</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="f:tree/f:frontmatter/f:meta[@name='bibtex']" />
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>\end{filecontents*}</xsl:text>
    <xsl:text>&#xa;</xsl:text>
  </xsl:template>

  <xsl:template match="f:frontmatter" mode="top">
    <xsl:text>\title{</xsl:text>
    <xsl:apply-templates select="f:title" />
    <xsl:text>}</xsl:text>
    <xsl:text>\author{</xsl:text>
    <xsl:for-each select="f:authors/f:author">
      <xsl:value-of select="." />
      <xsl:if test="not(position()=last())">
        <xsl:text>\and{}</xsl:text>
      </xsl:if>
    </xsl:for-each>
    <xsl:text>}</xsl:text>
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

  <xsl:template match="f:tree[not(f:frontmatter/f:taxon)]">
    <xsl:apply-templates select="f:frontmatter/f:title" />
    <xsl:text>\label{</xsl:text>
    <xsl:value-of select="f:frontmatter/f:addr" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="f:mainmatter" />
  </xsl:template>

  <xsl:template match="f:taxon[text()='Definition']">
    <xsl:text>definition</xsl:text>
  </xsl:template>

  <xsl:template match="f:taxon[text()='Theorem']">
    <xsl:text>theorem</xsl:text>
  </xsl:template>

  <xsl:template match="f:taxon[text()='Lemma']">
    <xsl:text>lemma</xsl:text>
  </xsl:template>

  <xsl:template match="f:taxon[text()='Construction']">
    <xsl:text>construction</xsl:text>
  </xsl:template>

  <xsl:template match="f:taxon[text()='Observation']">
    <xsl:text>observation</xsl:text>
  </xsl:template>

  <xsl:template match="f:taxon[text()='Convention']">
    <xsl:text>convention</xsl:text>
  </xsl:template>

  <xsl:template match="f:taxon[text()='Corollary']">
    <xsl:text>corollary</xsl:text>
  </xsl:template>

  <xsl:template match="f:taxon[text()='Axiom']">
    <xsl:text>axiom</xsl:text>
  </xsl:template>

  <xsl:template match="f:taxon[text()='Example']">
    <xsl:text>example</xsl:text>
  </xsl:template>

  <xsl:template match="f:taxon[text()='Exercise']">
    <xsl:text>exercise</xsl:text>
  </xsl:template>

  <xsl:template match="f:tree[f:frontmatter/f:taxon[text()='Proof']]">
    <xsl:text>\begin{proof}</xsl:text>
    <xsl:apply-templates select="f:mainmatter" />
    <xsl:text>\end{proof}</xsl:text>
  </xsl:template>

  <xsl:template match="f:tree[f:frontmatter/f:taxon[not(text()='Proof')]]">
    <xsl:text>\begin{</xsl:text>
    <xsl:apply-templates select="f:frontmatter/f:taxon" />
    <xsl:text>}[{</xsl:text>
    <xsl:apply-templates select="f:frontmatter/f:title" />
    <xsl:text>}]</xsl:text>
    <xsl:text>\label{</xsl:text>
    <xsl:value-of select="f:frontmatter/f:addr" />
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="f:mainmatter" />
    <xsl:text>\end{</xsl:text>
    <xsl:apply-templates select="f:frontmatter/f:taxon" />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="f:mainmatter">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="f:p">
    <xsl:text>\par{}</xsl:text>
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="f:strong">
    <xsl:text>\textbf{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="f:em">
    <xsl:text>\emph{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="f:tex[not(@display='block')]">
    <xsl:text>\(</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\)</xsl:text>
  </xsl:template>

  <xsl:template match="f:tex[@display='block']">
    <xsl:text>\[</xsl:text>
    <xsl:apply-templates />
    <xsl:if test="parent::f:mainmatter/parent::f:tree/f:frontmatter/f:taxon[text()='Proof'] and position()=last()">
      <xsl:text>\qedhere</xsl:text>
    </xsl:if>
    <xsl:text>\]</xsl:text>
  </xsl:template>

  <xsl:template match="f:ol">
    <xsl:text>\begin{enumerate}</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{enumerate}</xsl:text>
  </xsl:template>

  <xsl:template match="f:ul">
    <xsl:text>\begin{itemize}</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{itemize}</xsl:text>
  </xsl:template>

  <xsl:template match="f:li">
    <xsl:text>\item{}</xsl:text>
    <xsl:apply-templates />
    <xsl:if test="(parent::f:ol/parent::f:mainmatter/parent::f:tree/f:frontmatter/f:taxon[text()='Proof'] or parent::f:ul/parent::f:mainmatter/parent::f:tree/f:frontmatter/f:taxon[text()='Proof']) and position()=last()">
      <xsl:text>\qedhere</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="f:ref[@taxon]">
    <xsl:value-of select="@taxon" />
    <xsl:text>~</xsl:text>
    <xsl:text>\ref{</xsl:text>
    <xsl:value-of select="@addr" />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="f:ref[not(@taxon)]">
    <xsl:text>\S~\ref{</xsl:text>
    <xsl:value-of select="@addr" />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="f:link[@type='local']">
    <xsl:choose>
      <xsl:when test="//f:tree/f:frontmatter[f:addr/text()=current()/@addr and not(ancestor::f:backmatter)]">
        <xsl:text>\hyperref[</xsl:text>
        <xsl:value-of select="@addr" />
        <xsl:text>]{</xsl:text>
        <xsl:apply-templates />
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:when test="/f:tree/f:backmatter/f:references/f:tree/f:frontmatter[f:addr/text()=current()/@addr]">
        <xsl:apply-templates />
        <xsl:text>~\cite{</xsl:text>
        <xsl:value-of select="@addr" />
        <xsl:text>}</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="f:headline" />

  <xsl:template match="f:embedded-tex">
    <xsl:text>\begin{center}</xsl:text>
    <xsl:text>\includestandalone{</xsl:text>
    <xsl:value-of select="@hash" />
    <xsl:text>}</xsl:text>
    <xsl:text>\end{center}</xsl:text>
  </xsl:template>

</xsl:stylesheet>