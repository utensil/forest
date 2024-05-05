<?xml version="1.0"?>
<!-- SPDX-License-Identifier: CC0-1.0 -->
<xsl:stylesheet version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:beamer="http://ctan.org/pkg/beamer"
 xmlns:indenting="jonmsterling:indenting"
 xmlns:f="http://www.jonmsterling.com/jms-005P.xml"
 >

 <xsl:output method="html" encoding="utf-8" indent="yes" doctype-public="" doctype-system="" />

 <!-- base -->

 <xsl:include href="core.xsl" />
 <xsl:include href="metadata.xsl" />
 <xsl:include href="links.xsl" />
 <xsl:include href="tree.xsl" />

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

 <xsl:template match="f:addr" priority="10">
    <a class="slug" href="{../f:route}">
        <xsl:text>[</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>]</xsl:text>
    </a>
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

 </xsl:template>

</xsl:stylesheet>