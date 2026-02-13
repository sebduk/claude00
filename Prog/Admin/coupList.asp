<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
if Session(strUpload & "IsAdmin") = true then
	Response.Write "<b>Couples</b><br><br>"

	Response.Write "<b><a href=coupPage.asp target=right>Add a Couple</a></b><br>"
	Response.Write "<a href=coupHelp.asp target=right>Online Help</a><br><br>"

	strSQL = "SELECT Couple.IDCouple, Couple.DtCouple, Personne.Prenom AS MP, Personne.Nom AS MN, Personne_1.Prenom AS FP, Personne_1.Nom AS FN " & _
			 "FROM (Couple INNER JOIN Personne ON Couple.IDPersMasc = Personne.IDPersonne) INNER JOIN Personne AS Personne_1 ON Couple.IDPersFem = Personne_1.IDPersonne " & _
			 "ORDER BY Personne.Nom, Personne.Prenom, Personne_1.Nom, Personne_1.Prenom, Couple.DtCouple"
	rs0.Open strSQL, conConnexion, 2, 3

	while not rs0.EOF
		Response.Write "<a href=coupPage.asp?IDCouple=" & rs0("IDCouple") & " target=right>"
		Response.Write rs0("MN") & " " & rs0("MP") & " &<br>"
		Response.Write "&nbsp;&nbsp;&nbsp;" & rs0("FN") & " " & rs0("FP") & " (" & rs0("DtCouple") & ")</a><br><br>"
		rs0.MoveNext
	wend
	rs0.Close

	Response.Write "<b><a href=coupPage.asp target=right>Add a Couple</a></b><br>"
	Response.Write "<a href=coupHelp.asp target=right>Online Help</a>"
end if
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->
<!--#include VIRTUAL="/Include/DAOFooter.asp"-->
