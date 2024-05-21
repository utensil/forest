<?xml version="1.0"?>
<!-- SPDX-License-Identifier: CC0-1.0 -->
<xsl:stylesheet version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:beamer="http://ctan.org/pkg/beamer"
 xmlns:indenting="jonmsterling:indenting"
 xmlns:f="http://www.jonmsterling.com/jms-005P.xml"
 >

  <xsl:output method="html" encoding="utf-8" indent="yes" doctype-public="" doctype-system="" />

  <!-- base from https://git.sr.ht/~jonsterling/forester-base-theme -->

  <xsl:include href="core.xsl" />
  <xsl:include href="metadata.xsl" />
  <xsl:include href="links.xsl" />
  <xsl:include href="tree.xsl" />

  <!-- Override layout -->
  <xsl:include href="uts-layout.xsl" />

  <!-- From https://git.sr.ht/~jonsterling/forest-assets/tree/main/item/jms-forest.xsl -->

  <xsl:template match="beamer:*"></xsl:template>

  <xsl:template match="indenting:block[ancestor::indenting:block]">
  <div style="margin-left: 1em">
    <xsl:apply-templates />
  </div>
  </xsl:template>

  <xsl:template match="indenting:block[not(ancestor::indenting:block)]">
  <div style="margin-left: 1em; margin-bottom: 1em;">
    <xsl:apply-templates />
  </div>
  </xsl:template>

  <xsl:template match="indenting:row">
  <div style="min-height: 1em;">
    <xsl:apply-templates />
  </div>
  </xsl:template>

 <!-- From https://github.com/CAIMEOX/caimeox.github.io/blob/main/theme/forest.xsl -->

 <!-- Mine -->

  <!-- Override the addr template -->
  <xsl:template match="f:addr" priority="10">
    <a class="slug" href="{../f:route}">
      <xsl:text>[</xsl:text>
      <xsl:value-of select="." />
      <xsl:text>]</xsl:text>
    </a>
    <!-- uts-begin: Add the source link to the source of the tree, only works for my own forest -->
    <xsl:choose>
      <xsl:when test="/f:tree/f:frontmatter/f:taxon[text()='Person']">
        <a class="slug" href="https://github.com/utensil/forest/blob/main/trees/people/{../f:addr}.tree">
          <xsl:text>[source]</xsl:text>
        </a>
      </xsl:when>
      <xsl:when test="/f:tree/f:frontmatter/f:taxon[text()='Reference']">
          <a class="slug" href="https://github.com/utensil/forest/blob/main/trees/refs/{../f:addr}.tree">
            <xsl:text>[source]</xsl:text>
          </a>
      </xsl:when>
      <xsl:otherwise>
        <a class="slug" href="https://github.com/utensil/forest/blob/main/trees/{../f:addr}.tree">
          <xsl:text>[source]</xsl:text>
        </a>
      </xsl:otherwise>
    </xsl:choose>
    <!-- uts-end -->

  </xsl:template>

  <!-- uts-begin: Override embeded-tex to be injected SVG to support dark theme, resize etc. -->
  <xsl:template match="f:embedded-tex">
    <center>
      <img src="resources/{@hash}.svg" onload="SVGInject(this)" class="embedded-tex-svg"/>
    </center>
  </xsl:template>
  <!-- uts-end -->

  <!-- uts-begin: Override to add a taxon class -->
  <xsl:template match="f:tree">
    <section>
      <xsl:attribute name="lang">
        <xsl:choose>
          <xsl:when test="f:frontmatter/f:meta[@name='lang']">
            <xsl:value-of select="f:frontmatter/f:meta[@name='lang']" />
          </xsl:when>
          <xsl:otherwise>en</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>

      <xsl:choose>
        <xsl:when test="@show-metadata = 'false'">
          <xsl:attribute name="class">block hide-metadata</xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="class">block</xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:attribute name="data-taxon">
        <xsl:choose>
          <xsl:when test="f:frontmatter/f:taxon">
            <xsl:value-of select="f:frontmatter/f:taxon" />
          </xsl:when>
          <xsl:otherwise></xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>

      <xsl:choose>
        <xsl:when test="not(@show-heading='false')">
          <details id="{concat('tree-',f:frontmatter/f:anchor)}">
            <xsl:if test="not(@expanded = 'false')">
              <xsl:attribute name="open">open</xsl:attribute>
            </xsl:if>
            <summary>
              <xsl:apply-templates select="f:frontmatter" />
            </summary>
            <xsl:apply-templates select="f:mainmatter" />
            <xsl:apply-templates select="f:frontmatter/f:meta[@name='bibtex']" />
          </details>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="f:mainmatter" />
        </xsl:otherwise>
      </xsl:choose>
    </section>

    <xsl:apply-templates select="f:backmatter" />
  </xsl:template>

  <!-- uts-end -->

</xsl:stylesheet>