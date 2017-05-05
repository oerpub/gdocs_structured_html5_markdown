<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xh="http://www.w3.org/1999/xhtml"
  xmlns:nohtml="http://nohtml"
  xmlns:exsl="http://exslt.org/common"
  version="1.0"
  extension-element-prefixes="exsl"
  exclude-result-prefixes="exsl xh nohtml">

<xsl:output method="xml" encoding="UTF-8" indent="no"/>

<xsl:strip-space elements="*"/>
<xsl:preserve-space elements="xh:p xh:span xh:li nohtml:list xh:td xh:a"/>

<!--
This XSLT transforms Google Docs HTML tags to CNXML.
Most of the HTML tags are converted to CNXML.
But after this transformation ID attributes are still missing and internal links point
to a <nohtml:bookmark> placeholder which is not a valid CNML tag!
Pass1,2...4 transformation is a precondition for this pass.
-->

<xsl:template match="/">
  <html>
     <xsl:apply-templates select="xh:html"/>
  </html>
</xsl:template>

<!-- HTML -->
<xsl:template match="xh:html">
  <xsl:apply-templates select="xh:head"/>
  <body>
    <xsl:apply-templates select="xh:body"/>
  </body>
</xsl:template>

<!-- Get the title out of the header -->
<xsl:template match="xh:head">
  <!-- if document title is missing, Rhaptos creates error in metadata! -->
  <head>
    <title>
      <xsl:variable name="document_title">
        <xsl:value-of select="normalize-space(xh:title)"/>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="string-length($document_title) &gt; 0">
          <xsl:value-of select="$document_title"/>
        </xsl:when>
        <xsl:otherwise> <!-- create "untitled" as title text -->
          <xsl:text>Untitled</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </title>
  </head>
</xsl:template>

<!-- HTML body -->
<xsl:template match="xh:body">
  <xsl:apply-templates/>
</xsl:template>

<!-- paragraphs -->
<xsl:template match="xh:p">
  <p>
    <xsl:apply-templates/>
  </p>
</xsl:template>

<!-- linebreaks -->
<xsl:template match="xh:br">
  <xsl:choose>
    <xsl:when test="(ancestor::xh:p) or (ancestor::xh:li)">
      <br/>
    </xsl:when>
    <xsl:otherwise>
      <!-- This should not happen! -->
      <p>
        <br/>
      </p>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- XSLT 2.0 replace function for XSLT 1.0 -->
<!-- http://stackoverflow.com/questions/1069092/xslt-replace-function-not-found -->
<xsl:template name="string-replace-all">
  <xsl:param name="text"/>
  <xsl:param name="replace"/>
  <xsl:param name="by"/>
  <xsl:choose>
    <xsl:when test="contains($text,$replace)">
      <xsl:value-of select="substring-before($text,$replace)"/>
      <xsl:value-of select="$by"/>
      <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text" select="substring-after($text,$replace)"/>
        <xsl:with-param name="replace" select="$replace"/>
        <xsl:with-param name="by" select="$by"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$text"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- Call example for string-replace-all
    <xsl:call-template name="string-replace-all">
      <xsl:with-param name="text" select="$FeatureInfo"/>
      <xsl:with-param name="replace" select="Feature="/>
      <xsl:with-param name="by" select="TESTING"/>
    </xsl:call-template>
-->

<!-- emphasis (also works for nested emphasis) -->
<xsl:template name="apply-emphasis">
    <xsl:param name="style"/>
    <xsl:param name="child_node"/>
    <xsl:choose>
        <xsl:when test="contains($style, 'vertical-align:super')">
          <sup>
            <xsl:attribute name="style">vertical-align:super</xsl:attribute>
            <xsl:variable name="nosuper">
                <xsl:call-template name="string-replace-all">
                  <xsl:with-param name="text" select="$style"/>
                  <xsl:with-param name="replace" select="'vertical-align:super'"/>
                  <!-- ignore param "by" because we want to remove the "replace" string -->
                </xsl:call-template>
            </xsl:variable>
            <xsl:call-template name="apply-emphasis">
                <xsl:with-param name="style" select="$nosuper"/>
                <xsl:with-param name="child_node" select="$child_node"/>
            </xsl:call-template>
          </sup>
        </xsl:when>
        <xsl:when test="contains($style, 'vertical-align:sub')">
          <sub>
            <xsl:attribute name="style">vertical-align:sub</xsl:attribute>
            <xsl:variable name="nosub">
                <xsl:call-template name="string-replace-all">
                  <xsl:with-param name="text" select="$style"/>
                  <xsl:with-param name="replace" select="'vertical-align:sub'"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:call-template name="apply-emphasis">
                <xsl:with-param name="style" select="$nosub"/>
                <xsl:with-param name="child_node" select="$child_node"/>
            </xsl:call-template>
          </sub>
        </xsl:when>
        <xsl:when test="contains($style, 'font-style:italic')">
          <em>
            <xsl:variable name="noitalic">
                <xsl:call-template name="string-replace-all">
                  <xsl:with-param name="text" select="$style"/>
                  <xsl:with-param name="replace" select="'font-style:italic'"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:call-template name="apply-emphasis">
                <xsl:with-param name="style" select="$noitalic"/>
                <xsl:with-param name="child_node" select="$child_node"/>
            </xsl:call-template>
          </em>
        </xsl:when>
        <xsl:when test="contains($style, 'font-weight:bold')">
          <strong>
            <xsl:variable name="nobold">
                <xsl:call-template name="string-replace-all">
                  <xsl:with-param name="text" select="$style"/>
                  <xsl:with-param name="replace" select="'font-weight:bold'"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:call-template name="apply-emphasis">
                <xsl:with-param name="style" select="$nobold"/>
                <xsl:with-param name="child_node" select="$child_node"/>
            </xsl:call-template>
          </strong>
        </xsl:when>
        <xsl:when test="contains($style, 'font-weight:700')">
          <strong>
            <xsl:variable name="nobold">
                <xsl:call-template name="string-replace-all">
                  <xsl:with-param name="text" select="$style"/>
                  <xsl:with-param name="replace" select="'font-weight:700'"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:call-template name="apply-emphasis">
                <xsl:with-param name="style" select="$nobold"/>
                <xsl:with-param name="child_node" select="$child_node"/>
            </xsl:call-template>
          </strong>
        </xsl:when>
        <xsl:when test="contains($style, 'text-decoration:underline')">
          <span>
            <xsl:attribute name="style">text-decoration:underline</xsl:attribute>
            <xsl:variable name="nounderline">
                <xsl:call-template name="string-replace-all">
                  <xsl:with-param name="text" select="$style"/>
                  <xsl:with-param name="replace" select="'text-decoration:underline'"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:call-template name="apply-emphasis">
                <xsl:with-param name="style" select="$nounderline"/>
                <xsl:with-param name="child_node" select="$child_node"/>
            </xsl:call-template>
          </span>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates select="$child_node"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- span -->
<xsl:template match="xh:span">
  <xsl:choose>
    <!-- Do we have a header? Then do not apply any emphasis to the <title> -->
     <xsl:when test="parent::nohtml:h">
      <xsl:apply-templates/>
    </xsl:when>
    <xsl:when test="node()[self::xh:a]">
      <xsl:apply-templates/>
    </xsl:when>
    <xsl:otherwise>
        <xsl:variable name='span_style'>
          <xsl:value-of select="@style"/>
        </xsl:variable>
        <!-- make a for-each, just in case, because XSLT 1.0 does not support storing treeparts in variables -->
        <xsl:for-each select="child::node()">
          <xsl:call-template name="apply-emphasis">
              <xsl:with-param name="style" select="$span_style"/>
              <xsl:with-param name="child_node" select="current()"/>
          </xsl:call-template>
        </xsl:for-each>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- copy text from specific text-nodes -->
<xsl:template match="xh:p/text()|xh:span/text()|xh:li/text()|xh:td/text()|xh:a/text()">
  <xsl:value-of select="."/>
</xsl:template>

<!-- headers -->
<xsl:template match="nohtml:h">
  <xsl:choose>
    <!-- do not create a section if we are inside tables -->
    <xsl:when test="ancestor::xh:td">
      <xsl:value-of select="@title"/>
      <xsl:apply-templates/>
    </xsl:when>
    <xsl:when test="ancestor::xh:li">
      <para><span style="font-weight:bold"><xsl:apply-templates/></span></para>
    </xsl:when>
    <xsl:otherwise>
      <!-- Check if header is empty, if yes, create no section -->

      <!-- TODO: nohtml:h without title should not happen -->
      <xsl:if test="@title">
        <section>
          <xsl:choose>
            <xsl:when test="@level = 1">
                  <h1>
                    <xsl:value-of select="@title"/>
                  </h1>
                  <xsl:apply-templates/>
            </xsl:when>
            <xsl:when test="@level = 2">
                <h2>
                  <xsl:value-of select="@title"/>
                </h2>
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:when test="@level = 3">
                <h3>
                  <xsl:value-of select="@title"/>
                </h3>
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:when test="@level = 4">
                <h4>
                  <xsl:value-of select="@title"/>
                </h4>
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:when test="@level = 5">
                <h5>
                  <xsl:value-of select="@title"/>
                </h5>
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:when test="@level &gt;=6">
                <h6>
                  <xsl:value-of select="@title"/>
                </h6>
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>
                <!-- should not happen-->
                <xsl:message>Unrecognized header level found!</xsl:message>
                <h6>
                  <xsl:value-of select="@title"/>
                </h6>
                <xsl:apply-templates/>
            </xsl:otherwise>
          </xsl:choose>
        </section>
      </xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- listings -->
<xsl:template match="xh:ol">
  <xsl:if test="xh:li">
    <xsl:apply-templates select="xh:li[1]" mode="walker_pass6">
      <xsl:with-param name="preceding_style" select="'unknown'"/>
    </xsl:apply-templates>
  </xsl:if>
</xsl:template>

<!-- ignore li, instead walk through li's (look at template ol above) -->
<xsl:template match="xh:li"/>

<!-- walk through listings -->
<xsl:template match="xh:li" mode="walker_pass6">
  <xsl:param name="preceding_style" select="'unknown'"/>
  <xsl:variable name="my_style" select="@list-style-type"/>
  <xsl:variable name="next_same_style" select="following-sibling::*[1][self::xh:li][@list-style-type = $my_style]"/>

  <!-- TODO: Is this wrong? Check if next_diff_style only looks for the next different style in current <ol> block -->
  <xsl:variable name="next_diff_style" select="following-sibling::xh:li[@list-style-type != $my_style][1]"/>

  <xsl:choose>
    <xsl:when test="$preceding_style = @list-style-type">
      <li>
        <xsl:apply-templates/>
      </li>
      <xsl:apply-templates select="$next_same_style" mode="walker_pass6">
        <xsl:with-param name="preceding_style" select="$my_style"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:when test="$preceding_style = 'unknown'">
      <xsl:choose>
        <xsl:when test="parent::xh:ol/@start">
          <ol>
              <xsl:attribute name="start">
                <xsl:value-of select="parent::xh:ol/@start"/>
              </xsl:attribute>
              <li>
                <xsl:apply-templates/>
              </li>
              <xsl:apply-templates select="$next_same_style" mode="walker_pass6">
                <xsl:with-param name="preceding_style" select="$my_style"/>
              </xsl:apply-templates>
          </ol>
        </xsl:when>
        <xsl:otherwise>
          <ul>
              <li>
                <xsl:apply-templates/>
              </li>
              <xsl:apply-templates select="$next_same_style" mode="walker_pass6">
                <xsl:with-param name="preceding_style" select="$my_style"/>
              </xsl:apply-templates>
          </ul>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:apply-templates select="$next_diff_style" mode="walker_pass6">
        <xsl:with-param name="preceding_style" select="'unknown'"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
      <xsl:message>This should not happen!</xsl:message>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- table -->
<xsl:template match="xh:table">
  <table>
    <xsl:apply-templates select="xh:tbody"/>
  </table>
</xsl:template>

<!-- table body -->
<xsl:template match="xh:tbody">
  <tbody>
    <xsl:for-each select="xh:tr">
      <tr>
        <xsl:for-each select="xh:td">
          <td>
            <xsl:apply-templates select="*"/>
          </td>
        </xsl:for-each>
      </tr>
    </xsl:for-each>
  </tbody>
</xsl:template>

<!-- links -->
<xsl:template match="xh:a">
  <a>
    <xsl:if test="@name">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="@href">
      <xsl:attribute name="href">
        <xsl:value-of select="@href"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:apply-templates/>
  </a>
</xsl:template>

<!-- images -->
<xsl:template match="xh:img">
  <nohtml:image>
    <xsl:copy-of select="@src|@height|@width|@alt"/>
  </nohtml:image>
</xsl:template>

<!-- remove empty images -->
<xsl:template match="xh:img[not(@src)]"/>

<xsl:template match="xh:sup">
  <sup>
    
  </sup>
</xsl:template>

<!-- links to footnotes -->
<!--<xsl:template match="xh:sup/xh:a">
  <xsl:variable name="reference">
    <xsl:value-of select="substring(@href, 2)"/>
  </xsl:variable>
  <xsl:if test="not(starts-with($reference, 'cmnt'))">
    <footnote>
      <xsl:apply-templates select="//xh:div[xh:p/xh:a[@name = $reference]]/xh:p/xh:span"/>
    </footnote>
  </xsl:if>
</xsl:template>-->

<!-- Look for TeX Formulars from Google Chart Tools -->
<xsl:template match="xh:img[
  (contains(@src, 'cht=tx')
  and contains(@src, 'chart')
  and (contains(@src, '.google.com') or contains(@src, '.googleapis.com')))
  and (contains(@src, '?chl=') or contains(@src, '&amp;chl='))]">

  <nohtml:tex>
    <xsl:attribute name="src">
      <xsl:value-of select="@src"/>
    </xsl:attribute>

    <!-- parse the tex string out -->
    <xsl:variable name="parsedTex1">
      <xsl:value-of select="substring-after(@src, 'chl=')"/>
    </xsl:variable>

    <xsl:variable name="parsedTex2">
      <xsl:choose>
      <xsl:when test="not(contains($parsedTex1, '&amp;'))">
          <xsl:value-of select="$parsedTex1"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="substring-before($parsedTex1, '&amp;')"/>
      </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- Keep in mind: tex is still URL encoded! -->
    <xsl:attribute name="tex">
      <xsl:value-of select="$parsedTex2"/>
    </xsl:attribute>
  </nohtml:tex>
</xsl:template>

<!-- alt leer und title nicht leer -->

<!-- Look for TeX Formulars from gMath and mark them -->
<xsl:template match="xh:img[
  contains(@src, '.googleusercontent.com') and @alt='' and @title!='']">
  <nohtml:gmath/>
</xsl:template>

<!-- underline -->
<!--
<xsl:template match="hr">
  <underline/>
</xsl:template>
-->

<!-- footer div -->
<xsl:template match="xh:div">
  <footer>
    <xsl:apply-templates/>
  </footer>
</xsl:template>

</xsl:stylesheet>
