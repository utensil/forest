<?xml version="1.0"?>
<!-- SPDX-License-Identifier: CC0-1.0 -->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:beamer="http://ctan.org/pkg/beamer"
    xmlns:indenting="jonmsterling:indenting"
    xmlns:fr="http://www.forester-notes.org"
    xmlns:html="http://www.w3.org/1999/xhtml"
>
    <!-- The following is based on
    https://git.sr.ht/~jonsterling/forester-base-theme/tree/main/item/tree.xsl -->
    <!-- All modifications should mark with comments: uts-begin/uts-end -->
    <xsl:template match="/">
        <html xmlns="http://www.w3.org/1999/xhtml" data-base-url="{/fr:tree/@base-url}">
            <head>
                <meta name="viewport" content="width=device-width" />
                <link rel="stylesheet" href="{/fr:tree/@base-url}style.css" />
                <link rel="stylesheet" href="{/fr:tree/@base-url}katex.min.css" />
                <!-- uts-begin -->
                <link rel="stylesheet" href="{/fr:tree/@base-url}uts-style.css" />
                <!-- uts-end -->
                <script type="text/javascript">
                    <xsl:if test="/fr:tree/fr:frontmatter/fr:source-path">
                        <xsl:text>window.sourcePath = '</xsl:text>
                        <xsl:value-of select="/fr:tree/fr:frontmatter/fr:source-path" />
                        <xsl:text>'</xsl:text>
                    </xsl:if>
                </script>
                <script type="module" src="{/fr:tree/@base-url}forester.js"></script>
                <title>
                    <xsl:value-of select="/fr:tree/fr:frontmatter/fr:title/@text" />
                </title>
                <script src="{/fr:tree/@base-url}uts-forester.js"></script>
                <!-- AGENT-NOTE: Keep this minified loader module-scoped so its helpers cannot overwrite the synchronous preference controls. -->
                <script type="module" src="{/fr:tree/@base-url}uts-ondemand.js"></script>
            </head>
            <body>
                <ninja-keys placeholder="Start typing a note title or ID"></ninja-keys>

                <header class="header">
                    <nav class="nav">
                        <div class="logo">
                            <xsl:if test="not(/fr:tree[@root = 'true'])">
                                <a href="{/fr:tree/@base-url}index.html" title="Home">
                                    <xsl:text>« Home</xsl:text>
                                </a>
                            </xsl:if>
                            <span class="logo-switches">
                                <button id="theme-toggle" title="Theme (auto/light/dark)">
                                    <svg id="moon" xmlns="http://www.w3.org/2000/svg" width="24"
                                        height="18" viewBox="0 0 24 24" fill="none"
                                        stroke="currentcolor" stroke-width="2"
                                        stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z"></path>
                                    </svg>
                                    <svg id="sun" xmlns="http://www.w3.org/2000/svg" width="24"
                                        height="18" viewBox="0 0 24 24" fill="none"
                                        stroke="currentcolor" stroke-width="2"
                                        stroke-linecap="round" stroke-linejoin="round">
                                        <circle cx="12" cy="12" r="5"></circle>
                                        <line x1="12" y1="1" x2="12" y2="3"></line>
                                        <line x1="12" y1="21" x2="12" y2="23"></line>
                                        <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line>
                                        <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line>
                                        <line x1="1" y1="12" x2="3" y2="12"></line>
                                        <line x1="21" y1="12" x2="23" y2="12"></line>
                                        <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line>
                                        <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line>
                                    </svg>
                                    <svg id="auto" xmlns="http://www.w3.org/2000/svg" width="24"
                                        height="18" viewBox="0 0 24 24" fill="none"
                                        stroke="currentcolor" stroke-width="2"
                                        stroke-linecap="round" stroke-linejoin="round">
                                        <defs>
                                            <clipPath id="auto-filled-half">
                                                <rect x="3" y="3" width="9" height="18"></rect>
                                            </clipPath>
                                        </defs>
                                        <circle cx="12" cy="12" r="9" fill="currentcolor" stroke="none"
                                            clip-path="url(#auto-filled-half)"></circle>
                                        <circle cx="12" cy="12" r="9"></circle>
                                    </svg>
                                </button>
                                <button id="light-paper-toggle"
                                    title="Light paper (mix/near-white/sepia)">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="18"
                                        viewBox="0 0 24 24" fill="none" stroke="currentcolor"
                                        stroke-width="2" stroke-linecap="round"
                                        stroke-linejoin="round">
                                        <path d="M12 3a9 9 0 1 0 0 18h1.5a1.5 1.5 0 0 0 0-3H12a2 2 0 0 1-2-2v-1a2 2 0 0 1 2-2h3.5a3.5 3.5 0 0 0 0-7Z"></path>
                                        <circle cx="7.5" cy="10" r="0.6" fill="currentcolor" stroke="none"></circle>
                                        <circle cx="10.5" cy="7" r="0.6" fill="currentcolor" stroke="none"></circle>
                                        <circle cx="14.5" cy="7.5" r="0.6" fill="currentcolor" stroke="none"></circle>
                                    </svg>
                                </button>
                                <button id="font-toggle" title="Font (serif/mono/sans)">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="18"
                                        viewBox="0 0 24 24" fill="currentcolor">
                                        <text x="12" y="20" text-anchor="middle"
                                            font-weight="normal">Aa</text>
                                    </svg>
                                </button>
                                <button id="search">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="18"
                                        viewBox="0 0 24 24" fill="none" stroke="currentcolor"
                                        stroke-width="2" stroke-linecap="round"
                                        stroke-linejoin="round">
                                        <circle cx="11" cy="11" r="8"></circle>
                                        <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                                    </svg>
                                </button>
                            </span>
                        </div>
                    </nav>
                </header>

                <div id="grid-wrapper">
                    <article>
                        <xsl:apply-templates select="fr:tree" />
                    </article>
                    <xsl:if
                        test="fr:tree/fr:mainmatter/fr:tree[not(@toc='false')] and not(/fr:tree/fr:frontmatter/fr:meta[@name = 'toc']/.='false')">
                        <nav id="toc">
                            <div class="block">
                                <h1>Table of Contents</h1>
                                <xsl:apply-templates select="fr:tree/fr:mainmatter" mode="toc" />
                            </div>
                        </nav>
                    </xsl:if>
                </div>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
