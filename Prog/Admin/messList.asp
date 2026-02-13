<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
if Session(strUpload & "IsAdmin") = true then
	Response.Write "<b>Message</b><br><br>"

	Response.Write "<b><a href=messPage.asp target=right>Add Message Board</a></b><br>"
	Response.Write "<a href=messHelp.asp target=right>Online Help</a><br><br>"

	strSQL = "SELECT * " & _
			 "FROM Forum " & _
			 "ORDER BY ForumSort, ForumAdmin"
	rs0.Open strSQL, conConnexion, 2, 3

	while not rs0.EOF
		if rs0("ForumIsOnline") = true then
			Response.Write "<a href=messPage.asp?IDForum=" & rs0("IDForum")
			Response.Write " target=right>" & rs0("ForumAdmin") & "</a><br>"
		else
			Response.Write "<i><a href=messPage.asp?IDForum=" & rs0("IDForum")
			Response.Write " target=right>" & rs0("ForumAdmin") & "</a></i><br>"
		end if
		rs0.MoveNext
	wend

	rs0.Close

	Response.Write "<br><b><a href=messPage.asp target=right>Add Message Board</a></b><br>"
	Response.Write "<a href=messHelp.asp target=right>Online Help</a>"


	Response.Write "<br><br><br>"


	Response.Write "<b>With Email</b><br>"

	strSQL = "SELECT * " & _
			 "FROM Personne " & _
			 "WHERE NOT Email IS NULL " & _
			 "ORDER BY Nom, Prenom;"
	rs0.Open strSQL, conConnexion, 2, 3

	while not rs0.EOF
		Response.Write "<a href=messPersPage.asp?IDPersonne=" & rs0("IDPersonne") & " target=right>" & rs0("Nom") & ", " & rs0("Prenom") & "</a><br>"
		rs0.MoveNext
	wend

	rs0.Close


	Response.Write "<br><b>With out Email</b><br>"

	strSQL = "SELECT * " & _
			 "FROM Personne " & _
			 "WHERE Email IS NULL AND DtDec IS NULL " & _
			 "ORDER BY Nom, Prenom;"
	rs0.Open strSQL, conConnexion, 2, 3

	while not rs0.EOF
		Response.Write "<a href=messPersPage.asp?IDPersonne=" & rs0("IDPersonne") & " target=right>" & rs0("Nom") & ", " & rs0("Prenom") & "</a><br>"
		rs0.MoveNext
	wend

	rs0.Close
end if
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->
<!--#include VIRTUAL="/Include/DAOFooter.asp"-->
