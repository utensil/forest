<?xml version="1.0"?>
<!-- SPDX-License-Identifier: CC0-1.0 -->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:beamer="http://ctan.org/pkg/beamer"
    xmlns:indenting="jonmsterling:indenting"
    xmlns:f="http://www.jonmsterling.com/jms-005P.xml"
>

    <!-- The following is based on
    https://git.sr.ht/~jonsterling/forester-base-theme/tree/main/item/tree.xsl -->
    <!-- All modifications should mark with comments: uts-begin/uts-end -->
    <xsl:template match="/">
        <html>
            <head>
                <meta name="viewport" content="width=device-width" />
                <!-- <style> :root { background-color: #262626 !important; }</style> -->
                <link rel="stylesheet" href="style.css" />
                <link rel="stylesheet" href="katex.min.css" />
                <!-- uts-begin -->
                <link rel="stylesheet" href="uts-style.css" />
                <!-- uts-end -->
                <script type="text/javascript">
                    <xsl:if test="/f:tree/f:frontmatter/f:source-path">
                        <xsl:text>window.sourcePath = '</xsl:text>
                        <xsl:value-of select="/f:tree/f:frontmatter/f:source-path" />
                        <xsl:text>'</xsl:text>
                    </xsl:if>
                </script>
                <script type="module" src="forester.js"></script>
                <title>
                    <xsl:value-of select="/f:tree/f:frontmatter/f:title" />
                </title>
                <!-- <script
                src="https://cdn.jsdelivr.net/gh/iconfu/svg-inject@v1.2.3/dist/svg-inject.min.js"></script> -->
                <script src="uts-forester.js"></script>
                <script src="uts-ondemand.js"></script>
                <!-- <script type="module" src="shiki.js"></script>
        <script type="module" src="glsl.js"></script> -->
            </head>
            <body>
                <ninja-keys placeholder="Start typing a note title or ID"></ninja-keys>

                <header class="header">
                    <nav class="nav">
                        <div class="logo">
                            <xsl:if test="not(/f:tree[@root = 'true'])">
                                <a href="index.xml" title="Home">
                                    <xsl:text>« Home</xsl:text>
                                </a>
                            </xsl:if>
                            <span class="logo-switches">
                                <button id="theme-toggle" title="Theme (light/dark)">
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
                        <xsl:apply-templates select="f:tree" />
                    </article>
                    <xsl:if
                        test="f:tree/f:mainmatter/f:tree[not(@toc='false')] and not(/f:tree/f:frontmatter/f:meta[@name = 'toc']/.='false')">
                        <nav id="toc">
                            <div class="block">
                                <h1>Table of Contents</h1>
                                <xsl:apply-templates select="f:tree/f:mainmatter" mode="toc" />
                            </div>
                        </nav>
                    </xsl:if>
                </div>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
