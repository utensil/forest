<?xml version="1.0"?>
<!-- SPDX-License-Identifier: CC0-1.0 -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:f="http://www.jonmsterling.com/jms-005P.xml">
  
  <xsl:template match="/f:tree/f:backmatter//f:tree[f:frontmatter/f:taxon[text()='Reference']]">
    <xsl:apply-templates select="f:frontmatter/f:meta[@name='bibtex']" />
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
  
  <!-- use mdframed begin -->
  <xsl:template match="f:tree[f:frontmatter/f:taxon[not(text()='Proof' or (ancestor::f:backmatter))]]">
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
  <!-- use mdframed end -->

  <!-- use tcolorbox begin -->
  <!-- <xsl:template match="f:tree[f:frontmatter/f:taxon[not(text()='Proof' or (ancestor::f:backmatter))]]">
    <xsl:text>\begin{</xsl:text>
    <xsl:apply-templates select="f:frontmatter/f:taxon" />
    <xsl:text>}</xsl:text>
    <xsl:if test="f:frontmatter/f:title">
      <xsl:text>{{\normalfont\color{black}</xsl:text>
      <xsl:apply-templates select="f:frontmatter/f:title" />
      <xsl:text>}}</xsl:text>
    </xsl:if>
    <xsl:text>{</xsl:text>
    <xsl:if test="f:frontmatter/f:addr[not(contains(text(), '#'))]">
      <xsl:value-of select="f:frontmatter/f:addr" />
    </xsl:if>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="f:mainmatter" />
    <xsl:text>}\end{</xsl:text>
    <xsl:apply-templates select="f:frontmatter/f:taxon" />
    <xsl:text>}</xsl:text>
  </xsl:template> -->
  <!-- use tcolorbox end -->
  
  <xsl:template match="f:mainmatter">
    <xsl:apply-templates />
  </xsl:template>
  
  <xsl:template match="f:p">
    <xsl:text>\par{}</xsl:text>
    <!-- <xsl:text>\paragraph{</xsl:text> -->
    <xsl:apply-templates />
    <!-- <xsl:text>}</xsl:text> -->
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
      <xsl:when test="/f:tree/f:backmatter//f:tree/f:frontmatter[f:taxon/text()='Reference' and f:addr/text()=current()/@addr]">
        <xsl:text>{\sloppy\cite</xsl:text>
        <xsl:if test="../@tid">
          <xsl:text>[</xsl:text>
          <xsl:value-of select="../@tid" />
          <xsl:text>]</xsl:text>
        </xsl:if>
        <xsl:text>{</xsl:text>
        <xsl:value-of select="@addr" />
        <xsl:text>}}</xsl:text>
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
  
  <xsl:template match="f:resource">
    <xsl:choose>
        <xsl:when test="not(ancestor::html:table)">
            <!-- https://tex.stackexchange.com/a/630191/75671 -->
            <!-- <xsl:text>\unskip \hspace*{\fill} \break</xsl:text> -->
            <xsl:text>&#xa;&#xa;{\centering</xsl:text>
            <!-- https://tex.stackexchange.com/a/550265/75671 -->
            <!-- https://tex.stackexchange.com/a/308876/75671 -->
            <!-- <xsl:text>\fontsize{14}{14}\selectfont</xsl:text> -->
            <!-- https://latexref.xyz/_005cincludegraphics.html -->
            <!-- <xsl:text>\begin{center}</xsl:text> -->
            <xsl:text>\includestandalone[width=1.0\textwidth]{</xsl:text>
            <xsl:value-of select="@hash" />
            <xsl:text>}</xsl:text>
            <xsl:text>}&#xa;&#xa;</xsl:text>
            <!-- <xsl:text>\end{center}</xsl:text> -->
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>&#xa;&#xa;{\centering</xsl:text>
            <xsl:variable name="colcount" select="count(ancestor::html:table/html:thead/html:tr/html:th)" />
            <xsl:text>\includestandalone[width=</xsl:text>
            <xsl:value-of select="1 div $colcount" />
            <xsl:text>\textwidth]{</xsl:text>
            <xsl:value-of select="@hash" />
            <xsl:text>}</xsl:text>
            <xsl:text>}&#xa;&#xa;</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="f:code">
    <xsl:text>\lstinline|</xsl:text>
    <xsl:apply-templates />
    <xsl:text>|</xsl:text>
  </xsl:template>

  <xsl:template match="html:code[contains(concat(' ', @class, ' '), ' highlight ')]">
    <xsl:text>\begin{lstlisting}[mathescape=true,language=</xsl:text>
    <xsl:value-of select="substring-before(@class, ' ')" />
    <xsl:text>]</xsl:text>
    <xsl:apply-templates />
    <xsl:text>\end{lstlisting}</xsl:text>
  </xsl:template>

    <!-- https://stackoverflow.com/a/9612082/200764 -->
    <xsl:variable name="vLower" select=
    "'abcdefghijklmnopqrstuvwxyz'"/>
    <xsl:variable name="vUpper" select=
    "'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
    <xsl:template name="capitalizeFirstLetter">
        <xsl:param name="pText" select="."/>
        <xsl:value-of select=
        "concat(translate(substring($pText,1,1), $vLower, $vUpper),
                substring($pText, 2)
                )"/>
    </xsl:template>

  <xsl:template match="html:span[@class='newvocab']">
    <xsl:text>\textbf{\color{blue}</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
    <xsl:text>\index{</xsl:text>
        <xsl:call-template name="capitalizeFirstLetter">
            <xsl:with-param name="pText" select="."/>
        </xsl:call-template>
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

  <xsl:template match="html:span[@class='related']">
  </xsl:template>

  <xsl:template match="html:span[@class='todo']">
    <xsl:text>\todo[uts]{</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="html:span[@class='todolist']">
    <xsl:text>\listoftodos</xsl:text>
  </xsl:template>

  <xsl:template match="html:span[@class='optional']">
    <xsl:text>{\color{Grey}</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="html:table">
    <xsl:text>
    \resizebox{\columnwidth}{!}{%&#xa;
    \begin{tabular}{</xsl:text>
    <xsl:for-each select="html:thead/html:tr/html:th">
        <xsl:text> c </xsl:text>
    </xsl:for-each>
    <xsl:text>}</xsl:text>
    <xsl:text>\toprule&#xa;</xsl:text>
    <xsl:for-each select="html:thead/html:tr/html:th">
        <xsl:if test="position() > 1"><xsl:text> &amp; </xsl:text></xsl:if>
        <xsl:apply-templates />
    </xsl:for-each>
    <xsl:text> \\ \midrule&#xa;</xsl:text>
    <xsl:for-each select="html:tbody/html:tr">
        <xsl:for-each select="html:td">
            <xsl:if test="position() > 1"><xsl:text> &amp; </xsl:text></xsl:if>
            <xsl:apply-templates />
        </xsl:for-each>
        <xsl:text> \\&#xa;</xsl:text>
    </xsl:for-each>
    <xsl:text>\bottomrule&#xa;</xsl:text>
    <xsl:text>\end{tabular}</xsl:text>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="html:span[@class='langblock']">
    <xsl:text>{\small \em \color{gray}</xsl:text>
    <xsl:apply-templates />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="html:span[@class='webonly']">
  </xsl:template>

</xsl:stylesheet>