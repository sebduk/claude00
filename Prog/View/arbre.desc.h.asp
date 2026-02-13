<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->
<center>

<%
Dim lngID, ParamTable

if Request("IDPerso") = Empty then
	lngID = 1
else
	lngID = Request("IDPerso")
end if

ParamTable = "<table border=0 cellpadding=5 cellspacing=0>"


SetStructure lngID


%>

</center>
<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->
<!--#include VIRTUAL="/Include/DAOFooter.asp"-->

<%
'*******************************************************************************************************************************
' Sub Routines 
'*******************************************************************************************************************************

Sub SetStructure(lngID) 'Find Couple/Person
	Response.Write ParamTable
	Response.Write "<tr align=center valign=top>"

	strSQL = "SELECT Couple.IDCouple, Couple.IDCouple AS IDC, Personne.IDPersonne AS MID, Personne.IDCouple AS MIDC, Personne.Prenom AS MP, Personne.Nom AS MN, Personne.DtNaiss AS MDN, Personne.DtDec AS MDD, Personne_1.IDPersonne AS FID, Personne_1.IDCouple AS FIDC, Personne_1.Prenom AS FP, Personne_1.Nom AS FN, Personne_1.DtNaiss AS FDN, Personne_1.DtDec AS FDD " & _
			 "FROM (Couple INNER JOIN Personne ON Couple.IDPersMasc = Personne.IDPersonne) INNER JOIN Personne AS Personne_1 ON Couple.IDPersFem = Personne_1.IDPersonne " & _
			 "WHERE Personne.IDPersonne=" & lngID & " OR Personne_1.IDPersonne=" & lngID & " " & _
			 "ORDER BY Couple.DtCouple"
	rs0.Open strSQL, conConnexion, 2, 3

	while not rs0.EOF
		Response.Write "<td>"
		
		Response.Write ParamTable
		Response.Write "<tr align=center valign=top><td>"

		Response.Write ParamTable
		Response.Write "<tr align=center valign=top>"
		Response.Write "<td width=""50%"">"
		Response.Write replace(server.HTMLEncode(rs0("MP") & " " & rs0("MN")), " ", "&nbsp;") & "<br>"
		Response.Write "(" & rs0("MDN") & "-" & rs0("MDD") & ")" 
		Response.Write "</td>"
		Response.Write "<td width=""50%"">"
		Response.Write replace(server.HTMLEncode(rs0("FP") & " " & rs0("FN")), " ", "&nbsp;") & "<br>"
		Response.Write "(" & rs0("FDN") & "-" & rs0("FDD") & ")" 
		Response.Write "</td>"
		Response.Write "</tr>"
		Response.Write "</table>"

		Response.Write "</td></tr>"
		Response.Write "<tr align=center valign=top><td><hr size=1 noshade>"

		SetStructureDOWN rs0("IDC")

		Response.Write "</td></tr></table>"

		Response.Write "</td>"

		rs0.MoveNext
	wend
	
	Response.Write "</tr></table>"

	rs0.Close
End Sub

'*******************************************************************************************************************************

Sub SetStructureDOWN(lngIDC) 'Find Initial Couple/Person's filiation

	Dim rsRec1, rsRec2
	Set rsRec1 = Server.CreateObject("ADODB.Recordset")
	Set rsRec2 = Server.CreateObject("ADODB.Recordset")

	strSQL = "SELECT * FROM Personne WHERE IDCouple=" & lngIDC & " ORDER BY TriCouple"
	rsRec1.Open strSQL, conConnexion

	Response.Write ParamTable & "<tr valign=top>"											

	while not rsRec1.EOF 'for each child

	'	strSQL = "SELECT Couple.IDCouple, Personne.IDPersonne AS MID, Personne.Prenom AS MP, Personne.Nom AS MN, Personne.DtNaiss AS MDN, Personne.DtDec AS MDD, Personne.IsFamDir AS MFamDir, Personne_1.IDPersonne AS FID, Personne_1.Prenom AS FP, Personne_1.Nom AS FN, Personne_1.DtNaiss AS FDN, Personne_1.DtDec AS FDD, Personne_1.IsFamDir AS FFamDir, Personne.IsMasc " & _
	'			 "FROM (Couple INNER JOIN Personne ON Couple.IDPersMasc = Personne.IDPersonne) INNER JOIN Personne AS Personne_1 ON Couple.IDPersFem = Personne_1.IDPersonne " & _
	'			 "WHERE Couple.IDPersMasc=" & rsRec1("IDPersonne") & " OR Couple.IDPersFem=" & rsRec1("IDPersonne") & " " & _
	'			 "UNION " & _
	'			 "SELECT 'a' AS IDCouple, Personne.IDPersonne AS MID, Personne.Prenom AS MP, Personne.Nom AS MN, Personne.DtNaiss AS MDN, Personne.DtDec AS MDD, Personne.IsFamDir AS MFamDir, Personne.IDPersonne AS FID, Personne.Prenom AS FP, Personne.Nom AS FN, Personne.DtNaiss AS FDN, Personne.DtDec AS FDD, Personne.IsFamDir AS FFamDir, Personne.IsMasc " & _
	'			 "FROM Personne " & _
	'			 "WHERE IDPersonne=" & rsRec1("IDPersonne")
		strSQL = "SELECT Couple.IDCouple, Personne.IDPersonne AS MID, Personne.Prenom AS MP, Personne.Nom AS MN, Personne.DtNaiss AS MDN, Personne.DtDec AS MDD, Personne_1.IDPersonne AS FID, Personne_1.Prenom AS FP, Personne_1.Nom AS FN, Personne_1.DtNaiss AS FDN, Personne_1.DtDec AS FDD, Personne.IsMasc " & _
				 "FROM (Couple INNER JOIN Personne ON Couple.IDPersMasc = Personne.IDPersonne) INNER JOIN Personne AS Personne_1 ON Couple.IDPersFem = Personne_1.IDPersonne " & _
				 "WHERE Couple.IDPersMasc=" & rsRec1("IDPersonne") & " OR Couple.IDPersFem=" & rsRec1("IDPersonne") & " " & _
				 "UNION " & _
				 "SELECT 'a' AS IDCouple, Personne.IDPersonne AS MID, Personne.Prenom AS MP, Personne.Nom AS MN, Personne.DtNaiss AS MDN, Personne.DtDec AS MDD, Personne.IDPersonne AS FID, Personne.Prenom AS FP, Personne.Nom AS FN, Personne.DtNaiss AS FDN, Personne.DtDec AS FDD, Personne.IsMasc " & _
				 "FROM Personne " & _
				 "WHERE IDPersonne=" & rsRec1("IDPersonne")
		rsRec2.Open strSQL, conConnexion

		if rsRec2("IDCouple") <> "a" then 'if the Child has a Spouse
			while not rsRec2.EOF
				if rsRec2("IDCouple") <> "a" then
					Response.Write VbCrlf & "<!-- Level +1 w/ Spouse  -->" & VbCrlf
					Response.Write "<td>" & ParamTable & "<tr>"
																																				
					Response.Write "<td align=right width=""50%"">" 		
					Response.Write replace(server.HTMLEncode(rsRec2("MP") & " " & rsRec2("MN")), " ", "&nbsp;") & "<br>"
					Response.Write "(" & rsRec2("MDN") & "-" & rsRec2("MDD") & ")</td>"			
																																				
					Response.Write "<td width=""50%"">" 		
					Response.Write Replace(server.HTMLEncode(rsRec2("FP") & " " & rsRec2("FN")), " ", "&nbsp;") & "<br>"
					Response.Write "(" & rsRec2("FDN") & "-" & rsRec2("FDD") & ")</td>"			
																																				
					Response.Write "</tr><tr><td colspan=2 align=center><hr size=1 noshade>"														

					SetStructureDOWN rsRec2("IDCouple")

					Response.Write "</td></tr></table></td>"														
				end if
				rsRec2.MoveNext
			wend

		else 'if the Child has no Spouse

			Response.Write VbCrlf & "<!-- Level +1 w/o Spouse -->" & VbCrlf
			Response.Write "<td>" & ParamTable & "<tr><td align=center>"		
			Response.Write replace(server.HTMLEncode(rsRec2("MP") & " " & rsRec2("MN")), " ", "&nbsp;") & "<br>"
			Response.Write "(" & rsRec2("MDN") & "-" & rsRec2("MDD") & ")</td>"			
			Response.Write "</tr></table></td>"									
		end if

		rsRec2.Close
		rsRec1.MoveNext
	wend
	rsRec1.Close

	Response.Write "</tr></table>"											

End Sub
%>
