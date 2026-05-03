<?xml version="1.0"?>
<!-- SPDX-License-Identifier: CC0-1.0 -->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:beamer="http://ctan.org/pkg/beamer"
    xmlns:indenting="jonmsterling:indenting"
    xmlns:fr="http://www.forester-notes.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
>
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

    <xsl:template match="fr:meta[@name='lean']">
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
    <xsl:template match="fr:display-uri" priority="10">
        <a class="slug" href="{../fr:route}">
            <xsl:text>[</xsl:text>
            <xsl:value-of select="." />
            <xsl:text>]</xsl:text>
        </a>
        <!-- uts-begin -->
        <div class="link-buttons">
            <!-- : Add the source link to the source of the tree, only works for my own forest -->
            <xsl:if test="../fr:display-uri=/fr:tree/fr:frontmatter/fr:display-uri">
                <xsl:choose>
                    <xsl:when test="../fr:taxon[text()='Person']">
                        <a class="link-button link-source" title="source"
                            href="https://github.com/utensil/forest/blob/main/trees/people/{../fr:display-uri}.tree">
                            <xsl:text>✍️</xsl:text>
                            <span>source</span>
                        </a>
                    </xsl:when>
                    <xsl:when test="../fr:taxon[text()='Reference']">
                        <a class="link-button link-source" title="source" target="_blank"
                            href="https://github.com/utensil/forest/blob/main/trees/refs/{../fr:display-uri}.tree">
                            <xsl:text>✍️</xsl:text>
                            <span>source</span>
                        </a>
                    </xsl:when>
                    <xsl:when test="../fr:taxon[text()='Proof']">
                        <a class="link-button link-source" title="source" target="_blank"
                            href="https://github.com/utensil/forest/blob/main/trees/{../../fr:backmatter/fr:context/fr:tree/fr:frontmatter/fr:display-uri}.tree">
                            <xsl:text>✍️</xsl:text>
                            <span>source</span>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <a class="link-button link-source" title="source" target="_blank"
                            href="https://github.com/utensil/forest/blob/main/trees/{../fr:display-uri}.tree">
                            <xsl:text>✍️</xsl:text>
                            <span>source</span>
                        </a>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <xsl:if test="../fr:meta[@name='pdf']">
                <a target="_blank" title="PDF" class="link-button link-pdf" href="{../fr:display-uri}.pdf">
                    📄<span>PDF</span></a>
            </xsl:if>
            <xsl:if test="../fr:meta[@name='lean']">
                <xsl:apply-templates select="../fr:meta[@name='lean']" />
            </xsl:if>
            <xsl:if test="../fr:display-uri=/fr:tree/fr:frontmatter/fr:display-uri and ../fr:meta[@name='multilang']">
                <a id="langblock-toggle" class="link-button" href="javascript:void(0)"
                    title="Show hidden languages">🌎</a>
            </xsl:if>
        </div>
        <!-- uts-end -->
    </xsl:template>

    <!-- uts-begin: Override embeded-tex to be injected SVG to support dark theme, resize etc. -->
    <xsl:template match="fr:embedded-tex">
        <center>
            <img src="resources/{@hash}.svg" class="embedded-tex-svg" />
            <!-- <img src="resources/{@hash}.svg" onload="SVGInject(this)"
            class="embedded-tex-svg"/> -->
        </center>
    </xsl:template>
    <!-- uts-end -->


    <xsl:template match="fr:tree" mode="toc">
        <li>
            <xsl:for-each select="fr:frontmatter">
                <a class="bullet">
                    <xsl:choose>
                        <xsl:when test="fr:display-uri and fr:route">
                            <xsl:attribute name="href">
                                <xsl:value-of select="fr:route" />
                            </xsl:attribute>
                            <xsl:attribute name="title">
                                <xsl:value-of select="fr:title/@text" />
                                <xsl:text>&#160;[</xsl:text>
                                <xsl:value-of select="fr:display-uri" />
                                <xsl:text>]</xsl:text>
                            </xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="href">
                                <xsl:text>#</xsl:text>
                                <xsl:value-of select="generate-id(..)" />
                            </xsl:attribute>
                            <xsl:attribute name="title">
                                <xsl:value-of select="fr:title" />
                            </xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:text>■</xsl:text>
                </a>
                <span class="link local" data-target="#{generate-id(..)}">
                    <!-- uts-begin: Override the toc template to add data-taxon -->
                    <span class="taxon" data-taxon="{fr:taxon}">
                        <xsl:apply-templates select=".." mode="tree-taxon-with-number">
                            <xsl:with-param name="suffix">.&#160;</xsl:with-param>
                        </xsl:apply-templates>
                    </span>
                    <!-- uts-end -->
                  <xsl:apply-templates select="fr:title" />
                </span>
            </xsl:for-each>
            <xsl:apply-templates select="fr:mainmatter" mode="toc" />
        </li>
    </xsl:template>

    <xsl:template match="html:span[@class='todo']">
        <span class="todo">
            <xsl:apply-templates />
        </span>
    </xsl:template>

    <xsl:template match="fr:resource">
        <xsl:apply-templates select="fr:resource-content" />
    </xsl:template>

    <xsl:template match="fr:resource-content">
        <xsl:apply-templates />
    </xsl:template>

    <xsl:template match="fr:img[@src]">
        <figure>
            <img src="{@src}" />
        </figure>
    </xsl:template>

    <xsl:template match="html:span[@class='link-reference-full']/fr:link//text()">
        <a href="{ancestor::fr:link[1]/@href}">
            <span class="link-title">
                <xsl:value-of select="ancestor::fr:link[1]/@title" />
            </span>
            <span class="link-citek">
                <xsl:value-of select="." />
            </span>
        </a>
    </xsl:template>


    <xsl:template match="html:div[@class='typst-root loading']//fr:link[@type='external']">
        <xsl:text>#link("</xsl:text>
        <xsl:value-of select="@href" />
        <xsl:text>", underline(text(black)[</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>]))</xsl:text>
    </xsl:template>

    <xsl:template match="html:div[@class='typst-root loading']//fr:link[@type='local']">
        <xsl:text>#link("</xsl:text>
        <xsl:value-of select="@href" />
        <xsl:text>", underline(stroke: (dash: "dotted"), text(black)[</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>]))</xsl:text>
    </xsl:template>

    <xsl:template
        match="html:div[@class='typst-root loading']//html:span[@class='link-reference']/fr:link">
        <xsl:text>#link("</xsl:text>
        <xsl:value-of select="@href" />
        <xsl:text>", text(rgb("#10731d"))[</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>])</xsl:text>
    </xsl:template>

    <xsl:template match="html:div[@class='typst-root loading']//fr:ref">
        <xsl:text>#link("</xsl:text>
        <xsl:value-of select="@href" />
        <xsl:text>", underline(stroke: (dash: "dotted"), text(black)[§ [</xsl:text>
        <xsl:value-of select="@addr" />
        <xsl:text>]]))</xsl:text>
    </xsl:template>


</xsl:stylesheet>
