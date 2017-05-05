<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xh="http://www.w3.org/1999/xhtml"
  xmlns:m="http://www.w3.org/1998/Math/MathML"
  xmlns:nohtml="http://nohtml"
  xmlns:exsl="http://exslt.org/common"
  version="1.0"
  extension-element-prefixes="exsl"
  exclude-result-prefixes="exsl xh nohtml">

<xsl:output method="xml" encoding="UTF-8" indent="no"/>

<xsl:strip-space elements="*"/>
<xsl:preserve-space elements="xh:p xh:span xh:li nohtml:list xh:td xh:a"/>

<!--
Post processing of NOHTML
- Convert empty paragraphs to paragraphs with newlines
- Convert nohtml:image to images
- Convert nohtml:tex from Blahtex to embedded MathML

Deprecated:
- Add @IDs to elements (needs rework!)
-->

<!-- Default: copy everything -->
<xsl:template match="@*|node()">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
</xsl:template>

<!-- remove all nesting paras -->
<xsl:template match="xh:p[ancestor::xh:p]">
  <xsl:apply-templates/>
</xsl:template>

<!-- remove all empty tables -->
<xsl:template match="xh:table[not(child::*)]"/>

<!-- convert images to html -->
<xsl:template match="nohtml:image">
  <xsl:choose>
    <xsl:when test="text()">
      <media>
        <xsl:attribute name="alt">
          <xsl:value-of select="@alt"/>
        </xsl:attribute>
        <image>
          <xsl:attribute name="mime-type">
            <xsl:value-of select="@mime-type"/>
          </xsl:attribute>
          <xsl:attribute name="src">
            <xsl:value-of select="."/>
          </xsl:attribute>
          <xsl:if test="@height &gt; 0">
            <xsl:attribute name="height">
              <xsl:value-of select="@height"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:if test="@width &gt; 0">
            <xsl:attribute name="width">
              <xsl:value-of select="@width"/>
            </xsl:attribute>
          </xsl:if>
        </image>
      </media>
    </xsl:when>
    <xsl:otherwise>
      <media>
        <xsl:attribute name="alt">
          <xsl:value-of select="@alt"/>
        </xsl:attribute>
        <image>
          <xsl:attribute name="mime-type">
            <xsl:value-of select="@mime-type"/>
          </xsl:attribute>
          <xsl:attribute name="src">
            <xsl:value-of select="@src"/>
          </xsl:attribute>
          <xsl:if test="@height &gt; 0">
            <xsl:attribute name="height">
              <xsl:value-of select="@height"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:if test="@width &gt; 0">
            <xsl:attribute name="width">
              <xsl:value-of select="@width"/>
            </xsl:attribute>
          </xsl:if>
        </image>
      </media>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- remove empty tex nodes (this should not happen) -->
<xsl:template match="nohtml:tex[not(node())]|nohtml:gmath[not(node())]"/>

<!-- convert blahtex MathMl output to HTML standards-->
<xsl:template match="nohtml:tex[node()]|nohtml:gmath[node()]">
  <xsl:choose>
    <xsl:when test="xh:blahtex/xh:mathml/xh:markup">
      <m:math> <!-- namespace="http://www.w3.org/1998/Math/MathML"> --> <!-- Rhaptos does not want namespaces -->
        <m:semantics>
          <!-- enclose math in mrow when we have more than one child element -->
          <xsl:choose>
            <xsl:when test="count(xh:blahtex/xh:mathml/xh:markup/*) &gt; 1">
	            <m:mrow>
                <xsl:apply-templates select="xh:blahtex/xh:mathml/xh:markup/*" mode="mathml_ns"/>
              </m:mrow>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="xh:blahtex/xh:mathml/xh:markup/*" mode="mathml_ns"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:apply-templates select="xh:blahtex/xh:annotation" mode="mathml_ns"/>
	      </m:semantics>
      </m:math>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text> [MathML Transformation-Error:</xsl:text>
        <xsl:value-of select="xh:blahtex"/>
      <xsl:text>] </xsl:text>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- copy blahtex' MathML and change namespace to the right value -->
<xsl:template match="*" mode="mathml_ns">
  <xsl:element name="m:{local-name()}"> <!-- namespace="http://www.w3.org/1998/Math/MathML"> -->
    <xsl:apply-templates select="@*|node()" mode="mathml_ns"/>
  </xsl:element>
</xsl:template>

<!-- copy blahtex' MathML attributes and text also -->
<xsl:template match="@*|node()[not(self::*)]" mode="mathml_ns">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()" mode="mathml_ns"/>
  </xsl:copy>
</xsl:template>

</xsl:stylesheet>
