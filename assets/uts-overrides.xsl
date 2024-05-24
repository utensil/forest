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
            <xsl:if test="f:taxon or (not(ancestor-or-self::f:tree[@numbered='false' or ../@toc='false']) and count(../../f:tree) >= 1) or f:number">
                <xsl:text>.&#160;</xsl:text>
            </xsl:if>
        </span>
    </xsl:template>
</xsl:stylesheet>