<?xml version="1.0"?>
<!-- SPDX-License-Identifier: CC0-1.0 -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:f="http://www.jonmsterling.com/jms-005P.xml">
  
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
  
  <xsl:template match="f:tree[not(f:frontmatter/f:taxon)]">
    <xsl:apply-templates select="f:frontmatter/f:title" />
    <xsl:if test="f:frontmatter/f:addr[not(contains(text(), '#'))]">
      <xsl:text>\label{</xsl:text>
      <xsl:value-of select="f:frontmatter/f:addr" />
      <xsl:text>}</xsl:text>
    </xsl:if>
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
  
  <xsl:template match="f:taxon[text()='Remark']">
    <xsl:text>remark</xsl:text>
  </xsl:template>

  <xsl:template match="f:taxon[text()='Notation']">
    <xsl:text>notation</xsl:text>
  </xsl:template> 
  
  <xsl:template match="f:tree[f:frontmatter/f:taxon[text()='Proof']]">
    <xsl:text>\begin{proof}</xsl:text>
    <xsl:apply-templates select="f:mainmatter" />
    <xsl:text>\end{proof}</xsl:text>
  </xsl:template>
  
  <xsl:template match="f:tree[f:frontmatter/f:taxon[not(text()='Proof')]]">
    <xsl:text>\begin{</xsl:text>
    <xsl:apply-templates select="f:frontmatter/f:taxon" />
    <xsl:text>}</xsl:text>
    <xsl:if test="f:frontmatter/f:title">
      <xsl:text>[{</xsl:text>
      <xsl:apply-templates select="f:frontmatter/f:title" />
      <xsl:text>}]</xsl:text>
    </xsl:if>
    <xsl:if test="f:frontmatter/f:addr[not(contains(text(), '#'))]">
      <xsl:text>\label{</xsl:text>
      <xsl:value-of select="f:frontmatter/f:addr" />
      <xsl:text>}</xsl:text>
    </xsl:if>
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
    <xsl:text>\begin{equation}</xsl:text>
    <xsl:apply-templates />
    <xsl:if test="parent::f:mainmatter/parent::f:tree/f:frontmatter/f:taxon[text()='Proof'] and position()=last()">
      <xsl:text>\qedhere</xsl:text>
    </xsl:if>
    <xsl:text>\end{equation}</xsl:text>
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
  
  <!-- <xsl:template match="f:ref[@taxon]">
    <xsl:value-of select="@taxon" />
    <xsl:text>\unskip~</xsl:text>
    <xsl:text>\ref{</xsl:text>
    <xsl:value-of select="@addr" />
    <xsl:text>}</xsl:text>
  </xsl:template>
  
  <xsl:template match="f:ref[not(@taxon)]">
    <xsl:text>\S~\ref{</xsl:text>
    <xsl:value-of select="@addr" />
    <xsl:text>}</xsl:text>
  </xsl:template> -->

  <xsl:template match="f:ref">
    <xsl:choose>
      <xsl:when test="//f:tree/f:frontmatter[f:addr/text()=current()/@addr and not(ancestor::f:backmatter)]">
        <xsl:text>\Cref{</xsl:text>
        <xsl:value-of select="@addr" />
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="@taxon">
            <xsl:value-of select="@taxon" />
            <xsl:text>\unskip~</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>\S~</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>\href{https://utensil.github.io/forest/</xsl:text>
        <xsl:value-of select="@href" />
        <xsl:text>}{[</xsl:text>
        <xsl:value-of select="@addr" />
        <xsl:text>]}</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
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
        <xsl:text>~\cite</xsl:text>
        <xsl:if test="../@tid">
          <xsl:text>[</xsl:text>
          <xsl:value-of select="../@tid" />
          <xsl:text>]</xsl:text>
        </xsl:if>
        <xsl:text>{</xsl:text>
        <xsl:value-of select="@addr" />
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>\href{https://utensil.github.io/forest/</xsl:text>
        <xsl:value-of select="@href" />
        <xsl:text>}{</xsl:text>
        <xsl:apply-templates />
        <xsl:text>}</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="f:link[@type='external']">
    <xsl:text>\href{</xsl:text>
    <xsl:value-of select="@href" />
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
  </xsl:template>
  
  <xsl:template match="f:headline" />
  
  <xsl:template match="f:embedded-tex">
    <!-- https://tex.stackexchange.com/a/630191/75671 -->
    <xsl:text>\unskip \hspace*{\fill} \break</xsl:text>
    <xsl:text>{\centering</xsl:text>
    <!-- https://tex.stackexchange.com/a/550265/75671 -->
    <!-- https://tex.stackexchange.com/a/308876/75671 -->
    <!-- <xsl:text>\fontsize{14}{14}\selectfont</xsl:text> -->
    <!-- https://latexref.xyz/_005cincludegraphics.html -->
    <xsl:text>\includestandalone[width=1.0\textwidth]{</xsl:text>
    <xsl:value-of select="@hash" />
    <xsl:text>}</xsl:text>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="html:code">
    <xsl:text>\begin{lstlisting}[mathescape=true,language=</xsl:text>
    <xsl:value-of select="@class" />
    <xsl:text>]</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{lstlisting}</xsl:text>
  </xsl:template>

  <xsl:template match="html:span[@class='newvocab']">
    <xsl:text>\textbf{\color{blue}</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
    <xsl:text>\index{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="html:span[@class='vocab']">
    <xsl:text>\textbf{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="html:blockquote">
    <xsl:text>\begin{displayquote}</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{displayquote}</xsl:text>
  </xsl:template>

</xsl:stylesheet>