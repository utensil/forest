<?xml version="1.0"?>
<!-- SPDX-License-Identifier: CC0-1.0 -->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:beamer="http://ctan.org/pkg/beamer"
    xmlns:indenting="jonmsterling:indenting"
    xmlns:fr="http://www.forester-notes.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
>

    <!-- <xsl:template name="numbered-taxon">
        <span class="taxon">
            <xsl:apply-templates select="fr:taxon" />
            <xsl:if test="count(ancestor::*) > 1 and (not(ancestor-or-selfr::fr:tree[@numbered='false' or
    @toc='false']) and count(../../fr:tree) >= 1) or fr:number">
                <xsl:if test="fr:taxon">
                    <xsl:text>&#160;</xsl:text>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="fr:number">
                        <xsl:value-of select="fr:number" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:number format="1.1" count="fr:tree[ancestor::fr:tree and not(@toc='false') and
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
        <xsl:param name="base" />
        <xsl:param name="short" select="false()" />
        <xsl:if test="string-length($pText)">
            <xsl:variable name="marker" select="normalize-space(substring-before(concat($pText,$sep),$sep))" />
            <xsl:if test="not($pText=.)">
                <!-- <xsl:text>,</xsl:text> -->
            </xsl:if>
            <a target="_blank"
                href="{$base}{$marker}">
                <!-- <xsl:text>L∃∀N</xsl:text> -->
                <xsl:choose>
                    <xsl:when test="$short">
                        <xsl:call-template name="lean-short-name">
                            <xsl:with-param name="name" select="$marker" />
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$marker" />
                    </xsl:otherwise>
                </xsl:choose>
            </a>
            <xsl:call-template name="splitlean">
                <xsl:with-param name="pText" select="substring-after($pText, $sep)" />
                <xsl:with-param name="sep" select="$sep" />
                <xsl:with-param name="base" select="$base" />
                <xsl:with-param name="short" select="$short" />
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template name="lean-short-name">
        <xsl:param name="name" />
        <xsl:choose>
            <xsl:when test="contains($name, '.')">
                <xsl:call-template name="lean-short-name">
                    <xsl:with-param name="name" select="substring-after($name, '.')" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$name" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="fr:meta[@name='lean']">
        <span class="meta-lean" tabindex="0" aria-label="Lean formalization links">
            <div class="meta-lean-list">
                <xsl:call-template name="splitlean">
                    <xsl:with-param name="pText" select="." />
                    <xsl:with-param name="sep" select="','" />
                    <xsl:with-param name="base" select="'https://leanprover-community.github.io/mathlib4_docs/find/#doc/'" />
                </xsl:call-template>
            </div>
            <!-- <span class="meta-lean-symbol">✓</span> -->
            <span class="meta-lean-symbol">L∃∀N</span>
        </span>
    </xsl:template>

    <xsl:template match="fr:meta[@name='lean-tauceti']">
        <span class="meta-lean" tabindex="0" aria-label="Lean formalization links">
            <div class="meta-lean-list">
                <xsl:call-template name="splitlean">
                    <xsl:with-param name="pText" select="." />
                    <xsl:with-param name="sep" select="','" />
                    <xsl:with-param name="base" select="'https://taucetiproject.github.io/TauCeti/docs/find/#doc/'" />
                    <xsl:with-param name="short" select="true()" />
                </xsl:call-template>
            </div>
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
                <a target="_blank" title="PDF" class="link-button link-pdf" href="{/fr:tree/@base-url}{../fr:display-uri}.pdf">
                    📄<span>PDF</span></a>
            </xsl:if>
            <xsl:if test="../fr:meta[@name='lean' or @name='lean-tauceti']">
                <xsl:apply-templates select="../fr:meta[@name='lean' or @name='lean-tauceti']" />
            </xsl:if>
            <xsl:if test="../fr:display-uri=/fr:tree/fr:frontmatter/fr:display-uri and ../fr:meta[@name='multilang']">
                <a id="langblock-toggle" class="link-button" href="javascript:void(0)"
                    title="Show hidden languages">🌎</a>
            </xsl:if>
            <!-- AGENT-NOTE: This provenance mark is intentionally web-only; PDF output stays unchanged. -->
            <xsl:if test="../fr:meta[@name='agent-authored'][not(normalize-space(.)='false')]">
                <span class="agent-authored-watermark" role="note" aria-label="Agent authored"
                    title="Agent authored">
                    <span class="agent-authored-watermark-label" aria-hidden="true">
                        <span>AGENT</span>
                        <span>AUTHORED</span>
                    </span>
                </span>
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
    <!-- <xsl:template match="fr:mainmatter">
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

    <xsl:template match="fr:resource">
        <xsl:apply-templates select="fr:resource-content" />
    </xsl:template>

    <xsl:template match="fr:resource-content">
        <center>
            <xsl:apply-templates />
        </center>
    </xsl:template>

    <!-- uts-begin: add embedded-tex-svg class for dark mode inversion -->
    <xsl:template match="fr:resource-content//html:img">
        <img class="embedded-tex-svg" src="{@src}" />
    </xsl:template>
    <!-- uts-end -->

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

    <!-- A simple hack to make fr:tex pass through markdown-it, but not handling more escape cases
    yet -->
    <!-- <xsl:template match="html:div[@class='markdownit grace-loading']//fr:tex[@display='block']">
    <xsl:text>\\[</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\\]</xsl:text>
    </xsl:template>
    <xsl:template match="html:div[@class='markdownit grace-loading']//fr:tex[not(@display='block')]">
    <xsl:text>\\(</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>\\)</xsl:text>
    </xsl:template> -->

</xsl:stylesheet>
