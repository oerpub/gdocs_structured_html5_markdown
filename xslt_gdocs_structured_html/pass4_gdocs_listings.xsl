<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xh="http://www.w3.org/1999/xhtml"
  xmlns:nohtml="http://nohtml"
  exclude-result-prefixes="xh">

<xsl:output
  method="xml"
  encoding="UTF-8"
  indent="no"/>

<xsl:strip-space elements="*"/>
<xsl:preserve-space elements="xh:p xh:span xh:li nohtml:list xh:td xh:a"/>

<!--
This XSLT adds the level attribute to <lists> and removes margin attribute
Pass1 transformation is precondition for this pass.
Before and after this transformation the Google Docs HTML is no valid HTML anymore!

Input example:
  <nohtml:list margin="10">1</nohtml:list>
  <nohtml:list margin="15">2</nohtml:list>
  <somethingelse/>
  <nohtml:list margin="33">3</nohtml:list>
  <nohtml:list margin="72">4</nohtml:list>
  <nohtml:list margin="15">5</nohtml:list>

Output:
  <nohtml:list level="1">1</nohtml:list>
  <nohtml:list level="2">2</nohtml:list>
  <somethingelse/>
  <nohtml:list level="1">3</nohtml:list>
  <nohtml:list level="2">4</nohtml:list>
  <nohtml:list level="1">5</nohtml:list>

-->

<!-- copy all other nodes -->
<xsl:template match="node()|@*">
  <xsl:copy>
    <xsl:apply-templates select="node()|@*"/>
  </xsl:copy>
</xsl:template>

<!-- find every nohtml:list element which has a preceding non-nohtml:list element -->
<xsl:template match="nohtml:list[not(preceding-sibling::*[1][self::nohtml:list])]">
  <!-- now walk recursive through all lists -->
  <xsl:apply-templates select="self::nohtml:list" mode="recurse_pass4">
    <xsl:with-param name="level1_margin" select="@margin"/>
    <xsl:with-param name="level" select="1"/>
  </xsl:apply-templates>
</xsl:template>

<!-- remove other nohtml:list elements, because they are recursive processed -->
<xsl:template match="nohtml:list"/>

<!-- remove @margin from nohtml:list -->
<xsl:template match="nohtml:list/@margin"/>

<!-- go recursive through all following lists -->
<xsl:template match="nohtml:list" mode="recurse_pass4">
    <xsl:param name="level1_margin" select="0"/>
    <xsl:param name="level" select="1"/>

    <xsl:variable name="nextStep" select="self::nohtml:list/following-sibling::*[1][self::nohtml:list]"/>

    <!-- create current nohtml:list element with its level -->
    <xsl:apply-templates select="self::nohtml:list" mode="create_pass4">
      <xsl:with-param name="level" select="$level"/>
    </xsl:apply-templates>

    <xsl:if test="$nextStep">
      <xsl:choose>
        <!-- new start margin/point for level 1 -->
        <xsl:when test="($nextStep/@margin &lt;= $level1_margin) or ($nextStep/@margin &lt; @margin and $level = 2)">
          <xsl:apply-templates select="$nextStep" mode="recurse_pass4">
            <xsl:with-param name="level1_margin" select="$nextStep/@margin"/>
            <xsl:with-param name="level" select="1"/>
          </xsl:apply-templates>
        </xsl:when>
        <!-- -1 -->
        <xsl:when test="$nextStep/@margin &lt; @margin and $level &gt; 1">
          <xsl:apply-templates select="$nextStep" mode="recurse_pass4">
            <xsl:with-param name="level1_margin" select="$level1_margin"/>
            <xsl:with-param name="level" select="$level - 1"/>
          </xsl:apply-templates>
        </xsl:when>
        <!-- +1 -->
        <xsl:when test="$nextStep/@margin &gt; @margin">
          <xsl:apply-templates select="$nextStep" mode="recurse_pass4">
            <xsl:with-param name="level1_margin" select="$level1_margin"/>
            <xsl:with-param name="level" select="$level + 1"/>
          </xsl:apply-templates>
        </xsl:when>
        <!-- +-0 -->
        <xsl:otherwise>
          <xsl:apply-templates select="$nextStep" mode="recurse_pass4">
            <xsl:with-param name="level1_margin" select="$level1_margin"/>
            <xsl:with-param name="level" select="$level"/>
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
</xsl:template>

<!-- create nohtml:list element with level attribute -->
<xsl:template match="nohtml:list" mode="create_pass4">
  <xsl:param name="level"/>
    <nohtml:list>
      <xsl:attribute name="level">
        <xsl:value-of select="$level"/>
      </xsl:attribute>
      <xsl:apply-templates select="@*"/>
        <xsl:apply-templates/>
    </nohtml:list>
</xsl:template>

</xsl:stylesheet>
