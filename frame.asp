<%@ Language=VBScript %>

<%
if Session("FromGlobal") = true then
	Session("FromGlobal") = false

    Response.Write "<html>" & vbCrLf
    Response.Write "<script>" & vbCrLf
    Response.Write "parent.top.location.replace('/');"
    Response.Write vbCrLf & "</script>" & vbCrLf
    Response.Write "</html>" & vbCrLf
else
%>

<html>
<head>
<title>See Our Family</title>
<meta name="keywords" content="See Our Family, Genealogy, Genealogie, Genealogia, Family Tree">
<meta name="title" content="See Our Family, the family genealogy and history site">
<meta name="description" content="The family genealogy and history site">
<meta name="review" content="The family genealogy and history site">
<meta name="author" content="See Our Family. All content & graphics copyright SEBDUK 1998-2006">
<meta name="resource-type" content="document">
<meta name="distribution" content="Global">
<meta name="generator" content="SEBDUK">
<meta name="revisit-after" content="7 days">
<meta name="robots" content="index,follow">
<meta name="author" content="SEBDUK">
<meta name="Copyright" content="SEBDUK">
<meta name="Pragma" content="no_cache">
<meta name="Cache-Content" content="no_cache">
<meta name="Language" content="en">
<meta name="Classification" content="Genealogy">
<meta http-equiv="content-type" content="text/html;charset=iso-8859-1">
<meta http-equiv="Pragma" content="no_cache">
<meta http-equiv="Cache-Content" content="no_cache">
</head>
<frameset rows="100%,*" framespacing=0 border=0>
	<frame src="<%=Session("DomainTarget")%>" frameborder=0 name=nohide>
	<frame src=/hide.asp name=hide frameborder=0 scrolling=no>
</frameset>
</html>

<%
end if
%>