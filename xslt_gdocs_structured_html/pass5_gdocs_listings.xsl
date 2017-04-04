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
This XSLT transforms lists of Google Docs HTML to nested lists.
Pass1 transformation is precondition for this pass.
Before and after this transformation the Google Docs HTML is no valid HTML anymore!

Input example:
  <nohtml:list level="1">
    Heading1
  </nohtml:list>
  <nohtml:list level="2">
    Heading2
  </nohtml:list>

Output:
  <ol>
    <li>Heading1
    <ol>
      <li>Heading2</li>
    </ol>
    </li>
  </ol>

-->

<xsl:key name="kListGroup" match="nohtml:list"
  use="generate-id(preceding-sibling::node()[not(self::nohtml:list)][1])" />

<xsl:template match="node()|@*">
  <xsl:copy>
    <xsl:apply-templates select="node()[1]|@*"/>
  </xsl:copy>
  <xsl:apply-templates select="following-sibling::node()[1]"/>
</xsl:template>

<!-- remove style attribute -->
<xsl:template match="nohtml:list/@style"/>

<!-- remove start-value attribute from nohtml:list -->
<xsl:template match="nohtml:list/@start-value"/>

<!-- remove level attribute -->
<xsl:template match="nohtml:list/@level"/>

<xsl:template match="nohtml:list[preceding-sibling::node()[1][not(self::nohtml:list)] or not(preceding-sibling::node()[1])]">
  <xsl:variable name="ancestor_header_id">
    <xsl:value-of select="generate-id(ancestor::nohtml:h[1])"/>
  </xsl:variable>
  <!-- TODO: tables needs also more testings -->
  <ol>
    <!-- add start variable. Note: key (...) looks the same as on apply-templates below. -->
    <xsl:variable name="start">
      <xsl:value-of select="key('kListGroup', generate-id(preceding-sibling::node()[1]))
               [not(@level) or @level = 1]
               [generate-id(ancestor::nohtml:h[1]) = $ancestor_header_id][self::nohtml:list][1]/@start-value"/>
    </xsl:variable>
    <xsl:if test="$start != ''">
      <xsl:attribute name="start">
        <xsl:value-of select="$start"/>
      </xsl:attribute>
    </xsl:if>
    <!-- process list items -->
    <xsl:apply-templates mode="listgroup_pass5"
      select="key('kListGroup', generate-id(preceding-sibling::node()[1]))
               [not(@level) or @level = 1]
               [generate-id(ancestor::nohtml:h[1]) = $ancestor_header_id]"/>
  </ol>
  <xsl:apply-templates select="following-sibling::node()[not(self::nohtml:list)][1]"/>
</xsl:template>

<xsl:template match="nohtml:list" mode="listgroup_pass5">
  <li>
    <xsl:apply-templates select="@*"/>
    <xsl:copy-of select="node()"/> <!-- use copy-of because apply-templates gives wrong result -->
    <!-- <xsl:value-of select="." /> -->

    <xsl:variable name="vNext"
      select="following-sibling::nohtml:list[not(@level > current()/@level)][1]
          |following-sibling::node()[not(self::nohtml:list)][1]"/>

    <xsl:variable name="vNextLevel"
      select="following-sibling::nohtml:list
            [@level = current()/@level +1]
             [generate-id(following-sibling::nohtml:list
                 [not(@level > current()/@level)][1]
                |
                following-sibling::node()[not(self::nohtml:list)][1]
                   )
             =
              generate-id($vNext)
             ]
            " />
    <xsl:if test="$vNextLevel">
      <ol>
        <!-- add start value -->
        <xsl:if test="$vNextLevel[1]/@startvalue">
          <xsl:attribute name="start">
            <xsl:value-of select="$vNextLevel[1]/@startvalue"/>
          </xsl:attribute>
        </xsl:if>
        <!-- process list items -->
        <xsl:apply-templates select="$vNextLevel" mode="listgroup_pass5"/>
      </ol>
    </xsl:if>
  </li>
</xsl:template>

</xsl:stylesheet>
