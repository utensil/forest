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
    <a class="slug" href="https://github.com/search?q=repo%3Autensil%2Fforest+path%3A**%2F{../f:addr}*">
        <xsl:text>[source]</xsl:text>
    </a>
 </xsl:template>

</xsl:stylesheet>