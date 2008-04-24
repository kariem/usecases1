<?xml version="1.0"?>
<!--
	XML Stylesheet
	$Id$
-->
<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
	xmlns:uc="urn:use-case"
	xmlns:xhtml="http://www.w3.org/1999/xhtml"
	xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
	exclude-result-prefixes="uc">
	
	<xsl:strip-space elements="*"/>

	<!-- This stylesheet produces HTML in utf-8 -->
	<xsl:output method="html" indent="no"
			doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
			encoding="utf-8"/>

	<xsl:template match="/">
		<html>
			<head>
				<title>Preview</title>
				<link rel="stylesheet" href="style/preview.css"/>
			</head>

			<body>
				<div id="container">
					<xsl:apply-templates select="uc:use-cases"/>
				</div>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="uc:use-cases/uc:title">
		<h1>
			<xsl:apply-templates/>
		</h1>
	</xsl:template>

	<xsl:template match="uc:section/uc:title">
		<xsl:variable name="depth" select="count(ancestor::*)"/>
		<xsl:element name="h{$depth}">
			<xsl:number level="multiple" count="uc:section" format="1.1"/>
			<xsl:text> </xsl:text>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>

	<xsl:template match="uc:uc">
		<xsl:variable name="depth" select="count(ancestor-or-self::*)"/>
		<xsl:element name="h{$depth}">
			<xsl:if test="@xml:id">
				<xsl:element name="a">
					<xsl:attribute name="name">
						<xsl:value-of select="@xml:id"/>
					</xsl:attribute>
				</xsl:element>
			</xsl:if>

			<xsl:number level="multiple" count="uc:section|uc:uc" format="1.1"/>
			<xsl:text> </xsl:text>
			<xsl:value-of select="uc:title"/>
		</xsl:element>
		<dl>
			<dt>Version</dt>
			<dd>
				<xsl:choose>
					<xsl:when test="@version">
						<xsl:apply-templates select="@version"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>1.0</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</dd>

			<dt>Summary</dt>
			<dd>
				<xsl:apply-templates select="uc:desc"/>
			</dd>

			<dt>Primary Actor</dt>
			<dd>
				<xsl:apply-templates select="uc:actor"/>
			</dd>

			<dt>Preconditions</dt>
			<dd>
				<xsl:apply-templates select="uc:pre"/>
			</dd>

			<dt>Use Case Flow</dt>
			<dd>
				<xsl:apply-templates select="uc:flow"/>
			</dd>

			<dt>Postconditions</dt>
			<dd>
				<xsl:apply-templates select="uc:post"/>
			</dd>

			<xsl:if test="uc:non-funct">
				<dt>Non-functional Requirements</dt>
				<dd>
					<xsl:apply-templates select="uc:non-funct"/>
				</dd>
			</xsl:if>

			<xsl:if test="uc:comment">
				<dt>Notes</dt>
				<dd>
					<xsl:apply-templates select="uc:comment"/>
				</dd>
			</xsl:if>
		</dl>
	</xsl:template>

	<xsl:template match="uc:flow">
		<table class="flow">
			<xsl:variable name="steps_custom">
				<xsl:for-each select="uc:step">
					<xsl:copy>
						<!-- copy attributes -->
						<xsl:copy-of select="@*"/>
						<!-- add index -->
						<xsl:attribute name="index">
							<xsl:value-of select="position()"/>
						</xsl:attribute>
						<!-- copy descendants -->
						<xsl:copy-of select="."/>
					</xsl:copy>
				</xsl:for-each>
			</xsl:variable>

			<xsl:variable name="steps" select="exsl:node-set($steps_custom)/uc:step"/>

			<xsl:for-each select="$steps/uc:step">
				<tr>
					<xsl:call-template name="flow.step"/>
				</tr>
			</xsl:for-each>
			<xsl:if test="uc:alternatives">
				<xsl:for-each select="uc:alternatives/uc:alternative">
					<xsl:call-template name="flow.alternative">
						<xsl:with-param name="prefix">
							<xsl:number value="position()" format="A" />
						</xsl:with-param>
						<xsl:with-param name="steps" select="$steps"/>
					</xsl:call-template>
				</xsl:for-each>
			</xsl:if>
		</table>
	</xsl:template>

	<xsl:template name="flow.step">
		<!-- simple parameters, overriding generated information -->
		<xsl:param name="label" select="''" />
		<xsl:param name="content" select="''" />
		<!-- parameters used for content generation -->
		<xsl:param name="start" select="'0'"/>
		<xsl:param name="prefix"/>

		<td class="item">
			<xsl:choose>
				<xsl:when test="$label != ''">
					<xsl:value-of select="$label"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$prefix"/>
					<xsl:value-of select="$start + position()"/>
				</xsl:otherwise>
			</xsl:choose>
		</td>
		<td class="content">
			<xsl:choose>
				<xsl:when test="$content != ''">
					<xsl:value-of select="$content"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="node()"/>
				</xsl:otherwise>
			</xsl:choose>
		</td>
	</xsl:template>

	<xsl:template name="flow.alternative">
		<xsl:param name="prefix" select="''"/>
		<!-- step elements with index, name and content -->
		<xsl:param name="steps" />
		<tr class="alternative">
			<td colspan="2" class="alternative">
				<xsl:text>Alternative Flow </xsl:text>
				<xsl:if test="$prefix != ''">
					<xsl:value-of select="$prefix"/>
				</xsl:if>
				<xsl:if test="uc:description">
					<span class="description">
						<xsl:text>: </xsl:text>
						<xsl:apply-templates select="uc:description"/>
					</span>
				</xsl:if>
			</td>
		</tr>

		<!-- check start position -->
		<xsl:variable name="startpos">
			<xsl:choose>
				<xsl:when test="@start">
					<xsl:call-template name="search_by_name">
						<xsl:with-param name="name" select="@start"/>
						<xsl:with-param name="nodes" select="$steps"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>1</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="start" select="$startpos - 1"/>

		<!-- render steps -->
		<xsl:for-each select="uc:step">
			<tr>
				<xsl:call-template name="flow.step">
					<xsl:with-param name="prefix" select="$prefix"/>
					<xsl:with-param name="start" select="$startpos"/>
				</xsl:call-template>
			</tr>
		</xsl:for-each>

		<!-- check continue position for re-entry to default flow -->
		<xsl:if test="@continue">
			<xsl:variable name="continuepos">
				<xsl:call-template name="search_by_name">
					<xsl:with-param name="name" select="@continue"/>
					<xsl:with-param name="nodes" select="$steps"/>
				</xsl:call-template>
			</xsl:variable>

			<tr>
				<xsl:call-template name="flow.step">
					<xsl:with-param name="label">
						<xsl:value-of select="$prefix"/>
						<xsl:value-of select="$startpos + 1 + count(uc:step)"/>
					</xsl:with-param>
					<xsl:with-param name="content">
						<xsl:text>Continue the use case execution at step </xsl:text>
						<xsl:value-of select="$continuepos - 1"/>
						<xsl:text> of the default flow.</xsl:text>
					</xsl:with-param>
				</xsl:call-template>
			</tr>
		</xsl:if>

	</xsl:template>

	<xsl:template match="uc:include">
		<xsl:variable name="title">
			<xsl:call-template name="ref.title"/>
		</xsl:variable>
		<xsl:text>Execute use case </xsl:text>
		<a href="#{@ref}" title="&lt;include&gt;"><xsl:value-of select="$title"/></a>
		<xsl:text>.</xsl:text>
	</xsl:template>

	<xsl:template match="uc:extend">
		<xsl:variable name="title">
			<xsl:call-template name="ref.title"/>
		</xsl:variable>
		<xsl:text>Extension with use case </xsl:text>
		<a href="#{@ref}" title="&lt;extend&gt;"><xsl:value-of select="$title"/></a>
		<xsl:text>.</xsl:text>
	</xsl:template>


	<xsl:template name="ref.title">
		<xsl:param name="ref" select="@ref"/>
		<xsl:param name="nodes" select="/"/>
		<xsl:for-each select="$nodes//uc:uc[@xml:id = $ref]">
			<xsl:value-of select="uc:title"/>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="search_by_name">
		<xsl:param name="name"/>
		<xsl:param name="nodes"/>

		<xsl:for-each select="$nodes[@name = $name]">
			<xsl:value-of select="@index"/>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="debug_nodes">
		<xsl:param name="nodes"/>
		<xsl:message>
			Node set with <xsl:value-of select="count($nodes)"/> nodes
			<xsl:for-each select="$nodes">
				<xsl:text>&#xA;</xsl:text><xsl:value-of select="name()"/>
				<xsl:for-each select="attribute::*"><xsl:text> </xsl:text><xsl:value-of select="name()"/>="<xsl:value-of select="."/>"</xsl:for-each>
			</xsl:for-each>
		</xsl:message>
	</xsl:template>

	<xsl:template match="uc:pre | uc:post | uc:actor | uc:description ">
		<xsl:apply-templates select="./* | text()"/>
	</xsl:template>

	<xsl:template match="node() | @*">
		<xsl:copy>
			<xsl:apply-templates select="@* | node()"/>
		</xsl:copy>
	</xsl:template>

</xsl:stylesheet>