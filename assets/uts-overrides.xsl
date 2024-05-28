<?xml version="1.0"?>
<!-- SPDX-License-Identifier: CC0-1.0 -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:beamer="http://ctan.org/pkg/beamer"
                xmlns:indenting="jonmsterling:indenting"
                xmlns:f="http://www.jonmsterling.com/jms-005P.xml"
    >
    
    <xsl:template name="numbered-taxon">
        <span class="taxon">
            <xsl:apply-templates select="f:taxon" />
            <xsl:if test="(not(ancestor-or-self::f:tree[@numbered='false' or @toc='false']) and count(../../f:tree) >= 1) or f:number">
                <xsl:if test="f:taxon">
                    <xsl:text>&#160;</xsl:text>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="f:number">
                        <xsl:value-of select="f:number" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:number format="1.1" count="f:tree[ancestor::f:tree and not(@toc='false') and not(@numbered='false')]" level="multiple" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <xsl:if test="f:taxon or (not(ancestor-or-self::f:tree[@numbered='false' or ../@toc='false']) and count(../../f:tree) > 1) or f:number">
                <xsl:text>.&#160;</xsl:text>
            </xsl:if>
        </span>
    </xsl:template>

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

</xsl:stylesheet>