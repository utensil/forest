<?xml version="1.0"?>
<!-- SPDX-License-Identifier: CC0-1.0 -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:beamer="http://ctan.org/pkg/beamer"
                xmlns:indenting="jonmsterling:indenting"
                xmlns:f="http://www.jonmsterling.com/jms-005P.xml"
    >
    
    <!-- <xsl:template name="numbered-taxon">
        <span class="taxon">
            <xsl:apply-templates select="f:taxon" />
            <xsl:if test="count(ancestor::*) > 1 and (not(ancestor-or-self::f:tree[@numbered='false' or @toc='false']) and count(../../f:tree) >= 1) or f:number">
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
                <xsl:text>.&#160;</xsl:text>
            </xsl:if>
        </span>
    </xsl:template> -->

    <!-- Override the addr template -->
    <xsl:template match="f:addr" priority="10">
        <a class="slug" href="{../f:route}">
            <xsl:text>[</xsl:text>
            <xsl:value-of select="." />
            <xsl:text>]</xsl:text>
        </a>
        <!-- uts-begin: Add the source link to the source of the tree, only works for my own forest -->
        <xsl:if test="../f:addr=/f:tree/f:frontmatter/f:addr">
            <xsl:choose>
                <xsl:when test="../f:taxon[text()='Person']">
                <a class="slug-source" href="https://github.com/utensil/forest/blob/main/trees/people/{../f:addr}.tree">
                    <xsl:text>[source]</xsl:text>
                </a>
                </xsl:when>
                <xsl:when test="../f:taxon[text()='Reference']">
                <a class="slug-source" href="https://github.com/utensil/forest/blob/main/trees/refs/{../f:addr}.tree">
                    <xsl:text>[source]</xsl:text>
                </a>
                </xsl:when>
                <xsl:when test="../f:taxon[text()='Proof']">
                <a class="slug-source" href="https://github.com/utensil/forest/blob/main/trees/{../../f:backmatter/f:context/f:tree/f:frontmatter/f:addr}.tree">
                    <xsl:text>[source]</xsl:text>
                </a>
                </xsl:when>
                <xsl:otherwise>
                <a class="slug-source" href="https://github.com/utensil/forest/blob/main/trees/{../f:addr}.tree">
                    <xsl:text>[source]</xsl:text>
                </a>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- uts-end -->
    </xsl:template>

    <!-- uts-begin: Override embeded-tex to be injected SVG to support dark theme, resize etc. -->
    <xsl:template match="f:embedded-tex">
    <center>
        <img src="resources/{@hash}.svg" class="embedded-tex-svg"/>
        <!-- <img src="resources/{@hash}.svg" onload="SVGInject(this)" class="embedded-tex-svg"/> -->
    </center>
    </xsl:template>
    <!-- uts-end -->

    <xsl:template match="f:tree" mode="toc">
    <li>
        <xsl:for-each select="f:frontmatter">
        <a class="bullet">
            <xsl:choose>
            <xsl:when test="f:addr and f:route">
                <xsl:attribute name="href">
                <xsl:value-of select="f:route" />
                </xsl:attribute>
                <xsl:attribute name="title">
                <xsl:value-of select="f:title" />
                <xsl:text>[</xsl:text>
                <xsl:value-of select="f:addr" />
                <xsl:text>]</xsl:text>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="href">
                <xsl:text>#tree-</xsl:text>
                <xsl:value-of select="f:anchor"/>
                </xsl:attribute>
                <xsl:attribute name="title">
                <xsl:value-of select="f:title" />
                </xsl:attribute>
            </xsl:otherwise>
            </xsl:choose>
            <xsl:text>■</xsl:text>
        </a>
        <span class="link local" data-target="#tree-{f:anchor}">
            <!-- uts-begin: Override the toc template to add data-taxon -->
            <span class="taxon" data-taxon="{f:taxon}">
            <xsl:apply-templates select=".." mode="tree-taxon-with-number">
                <xsl:with-param name="suffix">.&#160;</xsl:with-param>
            </xsl:apply-templates>
            </span>
            <!-- uts-end -->
            <xsl:apply-templates select="f:title" />
        </span>
        </xsl:for-each>
        <xsl:apply-templates select="f:mainmatter" mode="toc" />
    </li>
    </xsl:template>
    

</xsl:stylesheet>