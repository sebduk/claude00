<!--#include VIRTUAL="/Include/CodeHeader.asp"-->

<%
if Session(strUpload & "IsUser") <> true then
	Response.Redirect "/login.asp"
else
%>

<html>
<head>
<title><%=strHeadTitle%></title>
</head>

<frameset rows="40,*" border=0 framespacing=0>
	<frame frameborder=0 name=mid src=/Prog/view/arbre.out.asp?IDPerso=<%=Request("IDPerso")%> scrolling=no>
	<frame frameborder=0 name=bot src=/Prog/view/arbre.asp?IDPerso=<%

Response.Write Request("IDPerso")
if Request("pos") <> empty then Response.Write "&pos=" & Request("pos")
%>>

	<noframes>
		<body bgcolor=#666666>
This site would be nicer with Frames.<br>
If your browser does not support them <a href=mailto:sebduk@gmail.com>write to me</a> !<br><br>
Ce site serait plus beau avec des Frames.<br>
Si vous n'avez pas ça <a href=mailto:sebduk@gmail.com>&eacute;crivez-moi</a> !<br><br>
		</body>
	</noframes>

</frameset>

</html>

<%
end if
%>
