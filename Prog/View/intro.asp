<!--#include VIRTUAL=/Include/CodeHeader.asp-->
<!--#include VIRTUAL=/Include/DAOHeader.asp-->
<!--#include VIRTUAL=/Include/HTMLHeader.asp-->
<!--#include VIRTUAL=/Include/Label.asp-->

<table border="0" width="80%" align="center"><tr><td>

<%
strSQL = "SELECT * FROM Info WHERE InfoLocation='Intro' AND InfoIsOnline;"
rs0.Open strSQL, conConnexion, 2, 3

if not rs0.EOF and rs0("InfoContent") <> empty then
	Response.Write rs0("InfoContent")
else
	Response.Write "<h1>" & strHeadTitle & "</h1>"
end if

rs0.Close
%>

<br><br><br><br><br>
<br><br><br><br><br>

<%'=strFooter%>

</td></tr></table>

<!--#include VIRTUAL=/Include/HTMLFooter.asp-->
<!--#include VIRTUAL=/Include/DAOFooter.asp-->
