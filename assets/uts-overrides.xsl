<?xml version="1.0"?>
<!-- SPDX-License-Identifier: CC0-1.0 -->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:beamer="http://ctan.org/pkg/beamer"
    xmlns:indenting="jonmsterling:indenting"
    xmlns:f="http://www.jonmsterling.com/jms-005P.xml"
    xmlns:html="http://www.w3.org/1999/xhtml"
>

    <!-- <xsl:template name="numbered-taxon">
        <span class="taxon">
            <xsl:apply-templates select="f:taxon" />
            <xsl:if test="count(ancestor::*) > 1 and (not(ancestor-or-self::f:tree[@numbered='false' or
    @toc='false']) and count(../../f:tree) >= 1) or f:number">
                <xsl:if test="f:taxon">
                    <xsl:text>&#160;</xsl:text>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="f:number">
                        <xsl:value-of select="f:number" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:number format="1.1" count="f:tree[ancestor::f:tree and not(@toc='false') and
    not(@numbered='false')]" level="multiple" />
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text>.&#160;</xsl:text>
            </xsl:if>
        </span>
    </xsl:template> -->

    <xsl:template name="splitlean">
        <xsl:param name="pText" select="." />
        <xsl:param name="sep" select="." />
        <xsl:if test="string-length($pText)">
            <xsl:if test="not($pText=.)">
                <!-- <xsl:text>,</xsl:text> -->
            </xsl:if>
            <a target="_blank"
                href="https://leanprover-community.github.io/mathlib4_docs/find/#doc/{substring-before(concat($pText,$sep),$sep)}">
                <!-- <xsl:text>L∃∀N</xsl:text> -->
                <xsl:value-of select="substring-before(concat($pText,$sep),$sep)" />
            </a>
            <xsl:call-template name="splitlean">
                <xsl:with-param name="pText" select="substring-after($pText, $sep)" />
                <xsl:with-param name="sep" select="$sep" />
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template match="f:meta[@name='lean']">
        <span class="meta-lean">
            <div class="meta-lean-list">
                <xsl:call-template name="splitlean">
                    <xsl:with-param name="pText" select="." />
                    <xsl:with-param name="sep" select="','" />
                </xsl:call-template>
            </div>
            <!-- <span class="meta-lean-symbol">✓</span> -->
            <span class="meta-lean-symbol">L∃∀N</span>
        </span>
    </xsl:template>

    <!-- Override the addr template -->
    <xsl:template match="f:addr" priority="10">
        <a class="slug" href="{../f:route}">
            <xsl:text>[</xsl:text>
            <xsl:value-of select="." />
            <xsl:text>]</xsl:text>
        </a>
        <!-- uts-begin -->
        <div class="link-buttons">
            <!-- : Add the source link to the source of the tree, only works for my own forest -->
            <xsl:if test="../f:addr=/f:tree/f:frontmatter/f:addr">
                <xsl:choose>
                    <xsl:when test="../f:taxon[text()='Person']">
                        <a class="link-button link-source" title="source"
                            href="https://github.com/utensil/forest/blob/main/trees/people/{../f:addr}.tree">
                            <xsl:text>✍️</xsl:text>
                            <span>source</span>
                        </a>
                    </xsl:when>
                    <xsl:when test="../f:taxon[text()='Reference']">
                        <a class="link-button link-source" title="source" target="_blank"
                            href="https://github.com/utensil/forest/blob/main/trees/refs/{../f:addr}.tree">
                            <xsl:text>✍️</xsl:text>
                            <span>source</span>
                        </a>
                    </xsl:when>
                    <xsl:when test="../f:taxon[text()='Proof']">
                        <a class="link-button link-source" title="source" target="_blank"
                            href="https://github.com/utensil/forest/blob/main/trees/{../../f:backmatter/f:context/f:tree/f:frontmatter/f:addr}.tree">
                            <xsl:text>✍️</xsl:text>
                            <span>source</span>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <a class="link-button link-source" title="source" target="_blank"
                            href="https://github.com/utensil/forest/blob/main/trees/{../f:addr}.tree">
                            <xsl:text>✍️</xsl:text>
                            <span>source</span>
                        </a>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <xsl:if test="../f:meta[@name='pdf']">
                <a target="_blank" title="PDF" class="link-button link-pdf" href="{../f:addr}.pdf">
                    📄<span>PDF</span></a>
            </xsl:if>
            <xsl:if test="../f:meta[@name='lean']">
                <xsl:apply-templates select="../f:meta[@name='lean']" />
            </xsl:if>
            <xsl:if test="../f:addr=/f:tree/f:frontmatter/f:addr and ../f:meta[@name='multilang']">
                <a id="langblock-toggle" class="link-button" href="javascript:void(0)"
                    title="Show hidden languages">🌎</a>
            </xsl:if>
        </div>
        <!-- uts-end -->
    </xsl:template>

    <!-- uts-begin: Override embeded-tex to be injected SVG to support dark theme, resize etc. -->
    <xsl:template match="f:embedded-tex">
        <center>
            <img src="resources/{@hash}.svg" class="embedded-tex-svg" />
            <!-- <img src="resources/{@hash}.svg" onload="SVGInject(this)"
            class="embedded-tex-svg"/> -->
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
                                <xsl:value-of select="f:anchor" />
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

    <!-- <xsl:template match="html:span[@class='todo']" mode="render">
        <span class="rendered-todo">
            <xsl:apply-templates />
        </span>
    </xsl:template> -->
    <xsl:template match="html:span[@class='todo']">
        <span class="todo">
            <xsl:apply-templates />
        </span>
    </xsl:template>

    <!-- <xsl:template match="html:div[@class='embeded-shader']">
        <xsl:element namespace="http://www.w3.org/1999/xhtml" name="{local-name()}">
        <xsl:apply-templates select="@* | node()" />
        </xsl:element>
    </xsl:template> -->

    <!-- uts-begin: extend mainmatter -->
    <!-- <xsl:template match="f:mainmatter">
        <div class="tree-content">
            <xsl:if test="../*/html:span[@class='todo']">
                <xsl:for-each select="../*/html:span[@class='todo']">
                    <xsl:apply-templates select="." mode="render" />
                </xsl:for-each>
            </xsl:if>
            <xsl:apply-templates />
        </div>
    </xsl:template> -->
    <!-- uts-end -->

    <xsl:template match="f:resource">
        <xsl:apply-templates select="f:resource-content" />
    </xsl:template>

    <xsl:template match="f:resource-content">
        <xsl:apply-templates />
    </xsl:template>

    <xsl:template match="f:img[@src]">
        <figure>
            <img src="{@src}" />
        </figure>
    </xsl:template>

    <xsl:template match="html:span[@class='link-reference-full']/f:link//text()">
        <a href="{ancestor::f:link[1]/@href}">
            <span class="link-title">
                <xsl:value-of select="ancestor::f:link[1]/@title" />
            </span>
            <span class="link-citek">
                <xsl:value-of select="." />
            </span>
        </a>
    </xsl:template>


    <xsl:template match="html:div[@class='typst-root loading']//f:link[@type='external']">
        <xsl:text>#link("</xsl:text>
        <xsl:value-of select="@href" />
        <xsl:text>", underline(text(black)[</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>]))</xsl:text>
    </xsl:template>

    <xsl:template match="html:div[@class='typst-root loading']//f:link[@type='local']">
        <xsl:text>#link("</xsl:text>
        <xsl:value-of select="@href" />
        <xsl:text>", underline(stroke: (dash: "dotted"), text(black)[</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>]))</xsl:text>
    </xsl:template>

    <xsl:template
        match="html:div[@class='typst-root loading']//html:span[@class='link-reference']/f:link">
        <xsl:text>#link("</xsl:text>
        <xsl:value-of select="@href" />
        <xsl:text>", text(rgb("#10731d"))[</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>])</xsl:text>
    </xsl:template>

    <xsl:template match="html:div[@class='typst-root loading']//f:ref">
        <xsl:text>#link("</xsl:text>
        <xsl:value-of select="@href" />
        <xsl:text>", underline(stroke: (dash: "dotted"), text(black)[§ [</xsl:text>
        <xsl:value-of select="@addr" />
        <xsl:text>]]))</xsl:text>
    </xsl:template>

    <!-- A simple hack to make f:tex pass through markdown-it, but not handling more escape cases
    yet -->
    <!-- <xsl:template match="html:div[@class='markdownit grace-loading']//f:tex[@display='block']">
    <xsl:text>\\[</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\\]</xsl:text>
    </xsl:template>
    <xsl:template match="html:div[@class='markdownit grace-loading']//f:tex[not(@display='block')]">
    <xsl:text>\\(</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\\)</xsl:text>
    </xsl:template> -->

</xsl:stylesheet>
