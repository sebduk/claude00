<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
if Session(strUpload & "IsAdmin") = true then
	Response.Write "<b>Information</b><br><br>"

	Response.Write "<b><a href=infoPage.asp target=right>Add Information</a></b><br>"
	Response.Write "<a href=infoHelp.asp target=right>Online Help</a><br><br>"

	strSQL = "SELECT * " & _
			 "FROM Info " & _
			 "WHERE InfoIsOnline " & _
			 "ORDER BY InfoLocation"
	rs0.Open strSQL, conConnexion, 2, 3

	while not rs0.EOF
		Response.Write "<a href=infoPage.asp?IDInfo=" & rs0("IDInfo")
		Response.Write " target=right>" & rs0("InfoLocation") & "</a><br>"
		rs0.MoveNext
	wend

	rs0.Close

	Response.Write "<br><b><a href=infoPage.asp target=right>Add Information</a></b><br>"
	Response.Write "<a href=infoHelp.asp target=right>Online Help</a>"
end if
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->
<!--#include VIRTUAL="/Include/DAOFooter.asp"-->
