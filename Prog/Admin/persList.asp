<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
if Session(strUpload & "IsAdmin") = true then
	Response.Write "<b>People</b><br><br>"

	Response.Write "<b><a href=persPage.asp target=right>Add a Person</a><br>"
	Response.Write "<a href=persWizard.asp target=right>People Wizard</a></b><br>"
	Response.Write "<a href=persHelp.asp target=right>Online Help</a><br><br>"

	Response.Write "<a href=persList.asp>Reload All</a><br>"
	Response.Write "&gt;<a href=persList.asp>Alphabetically</a><br>"
	Response.Write "&gt;<a href=persList.asp?Reload=chrono>Chronologically</a><br>"
	Response.Write "&gt;<a href=persList.asp?Reload=last>Last Updated</a><br>"
	Response.Write "<a href=persList.asp?Reload=withpar>With Parents</a><br>"
	Response.Write "<a href=persList.asp?Reload=nopar>W/o Parents</a><br>"
	Response.Write "<a href=persList.asp?Reload=errors>Errors</a><br><br>"

	select case Request("Reload")
		case "errors"
			strSQL = "SELECT * FROM Personne " & _
					 "WHERE (IdCouple=0 AND NOT TriCouple IS NULL) " & _
					 "OR (IdCouple<>0 AND (TriCouple IS NULL OR TriCouple=0)) " & _
					 "ORDER BY Nom, Prenom, DtNaiss;"
		case "nopar"
			strSQL = "SELECT * FROM Personne " & _
					 "WHERE IdCouple=0 AND TriCouple IS NULL " & _
					 "ORDER BY Nom, Prenom, DtNaiss;"
		case "withpar"
			strSQL = "SELECT * FROM Personne " & _
					 "WHERE IdCouple<>0 "  & _
					 "ORDER BY Nom, Prenom, DtNaiss;"
		case "chrono"
			strSQL = "SELECT * FROM Personne " & _
					 "ORDER BY DtNaiss, Nom, Prenom;"
		case "last"
			strSQL = "SELECT * FROM Personne " & _
					 "ORDER BY LastUpdateWhen DESC, IDPersonne DESC;"
		case else
			strSQL = "SELECT * FROM Personne " & _
					 "ORDER BY Nom, Prenom, DtNaiss;"
	end select
	rs0.Open strSQL, conConnexion, 2, 3

	while not rs0.EOF
		Response.Write "<a href=persPage.asp?IDPersonne=" & rs0("IDPersonne") & " target=right>" & rs0("Nom") & " " & rs0("Prenom") & " (" & rs0("DtNaiss") & "-" & rs0("DtDec") & ")</a><br>"
		rs0.MoveNext
	wend
	rs0.Close

	Response.Write "<br><b><a href=persPage.asp target=right>Add a Person</a></b><br>"
	Response.Write "<a href=persHelp.asp target=right>Online Help</a>"
end if
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->
<!--#include VIRTUAL="/Include/DAOFooter.asp"-->
