<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
if Session(strUpload & "IsAdmin") = true then
	Response.Write "<b>Comments</b><br><br>"

	Response.Write "<b><a href=commPage.asp target=right>Add a Comment</a></b><br>"
	Response.Write "<a href=commHelp.asp target=right>Online Help</a><br><br>"

	strSQL = "SELECT * " & _
			 "FROM Commentaire " & _
			 "ORDER BY DtVecu, Titre"
	rs0.Open strSQL, conConnexion, 2, 3

	while not rs0.EOF
		Response.Write "<a href=commPage.asp?IDCommentaire=" & rs0("IDCommentaire")
		Response.Write " target=right>(" & rs0("DtVecu") & ")&nbsp;" & rs0("Titre") & "</a><br>"
		rs0.MoveNext
	wend

	rs0.Close

	Response.Write "<br><b><a href=commPage.asp target=right>Add a Comment</a></b><br>"
	Response.Write "<a href=commHelp.asp target=right>Online Help</a>"
end if
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->
<!--#include VIRTUAL="/Include/DAOFooter.asp"-->
