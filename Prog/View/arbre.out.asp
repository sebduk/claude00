<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/label.asp"-->

<%
if Session(strUpload & "IsUser") <> true then
	Response.Redirect "/login.asp"
else
%>

	<html>
	<head>
	<link rel="stylesheet" type="text/css" href="/style.css">
	</head>
	<body topmargin=2>

	<%
	Dim lngID, lngIDC, intPos, intPosMax, strNomPersonne, strNomCouple, i
	Dim hasChildren


	if Request("IDPerso") = Empty then
		lngID = 1
	else
		lngID = Request("IDPerso")
	end if

	if Request("Pos") = Empty then
		intPos = 1
	else
		intPos = Request("Pos")
	end if

	'Level 0 
	'Set 21 and 22
	StartStructure lngID, lngIDC, strNomPersonne, strNomCouple, intPos, intPosMax


	if lngIDC<>"a" then 'If IDPerso has a Spouse
		SetStructureDOWN lngIDC, hasChildren

		Response.Write "<table border=0 cellpadding=0 cellspacing=0><tr><td>"
		Response.Write "<b>" & strNomPersonne & "</b>&nbsp;</td><td>"
		Response.Write strFullAscendance & "&nbsp;</td><td>| "
		Response.Write "<a href=arbre.asp?IDPerso=" & lngID & " target=bot>" & strClassicVersion & "</a> . "
		Response.Write "<a href=arbre.asc.h.asp?IDPerso=" & lngID & " target=bot>" & strHorizontalVersion & "</a> . "
		Response.Write "<a href=arbre.asc.v.asp?IDPerso=" & lngID & " target=bot>" & strVerticalVersion & "</a> . "
		Response.Write "<a href=arbre.asc.tab.asp?IDPerso=" & lngID & " target=bot>" & strTableVersion & "</a> . "
		Response.Write "<a href=arbre.asc.excel.asp?IDPerso=" & lngID & " target=bot>" & strExcelVersion & "</a> "
		Response.Write "</td></tr>"
		
		if hasChildren then
			Response.Write "<tr><td></td><td>"
			Response.Write strFullDescendance & "&nbsp;</td><td>| "
			Response.Write "<a href=arbre.asp?IDPerso=" & lngID & " target=bot>" & strClassicVersion & "</a> . "
			Response.Write "<a href=arbre.desc.h.asp?IDPerso=" & lngID & " target=bot>" & strHorizontalVersion & "</a> . "
			Response.Write "<a href=arbre.desc.v.asp?IDPerso=" & lngID & " target=bot>" & strVerticalVersion & "</a> . "
			Response.Write "<a href=arbre.desc.tab.asp?IDPerso=" & lngID & " target=bot>" & strTableVersion & "</a> . "
			Response.Write "<a href=arbre.desc.excel.asp?IDPerso=" & lngID & " target=bot>" & strExcelVersion & "</a> "
			Response.Write "</td></tr>"
		end if
		Response.Write "</table>"
		'Response.Write "<i>" & strFullVersionWarning & "</i><br>"

	else 'if IDPerso has no Spouse

		Response.Write "<table border=0 cellpadding=0 cellspacing=0><tr><td>"
		Response.Write "<b>" & strNomPersonne & "</b>&nbsp;</td><td>"
		Response.Write strFullAscendance & "&nbsp;</td><td>| "
		Response.Write "<a href=arbre.asp?IDPerso=" & lngID & " target=bot>" & strClassicVersion & "</a> . "
		Response.Write "<a href=arbre.asc.h.asp?IDPerso=" & lngID & " target=bot>" & strHorizontalVersion & "</a> . "
		Response.Write "<a href=arbre.asc.v.asp?IDPerso=" & lngID & " target=bot>" & strVerticalVersion & "</a> . "
		Response.Write "<a href=arbre.asc.tab.asp?IDPerso=" & lngID & " target=bot>" & strTableVersion & "</a> . "
		Response.Write "<a href=arbre.asc.excel.asp?IDPerso=" & lngID & " target=bot>" & strExcelVersion & "</a> "
		Response.Write "</td></tr>"
		Response.Write "</table>"
	'	Response.Write "<i>" & strFullVersionWarning & "</i><br>"

	end if
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->

<%
end if
%>

<!--#include VIRTUAL="/Include/DAOFooter.asp"-->

<%
'*******************************************************************************************************************************
' Sub Routines 
'*******************************************************************************************************************************

Sub StartStructure(intX, lngIDC, strNomPersonne, strNomCouple, intPos, intPosMax) 'Find the Central Couple/Person
	
	dim intCpt
	
	strSQL = "SELECT Couple.DtCouple, Couple.IDCouple AS IDC, Personne.IDPersonne AS MID, Personne.IDCouple AS MIDC, Personne.Prenom AS MP, Personne.Nom AS MN, Personne.DtNaiss AS MDN, Personne.DtDec AS MDD, Personne_1.IDPersonne AS FID, Personne_1.IDCouple AS FIDC, Personne_1.Prenom AS FP, Personne_1.Nom AS FN, Personne_1.DtNaiss AS FDN, Personne_1.DtDec AS FDD " & _
			 "FROM (Couple INNER JOIN Personne ON Couple.IDPersMasc = Personne.IDPersonne) INNER JOIN Personne AS Personne_1 ON Couple.IDPersFem = Personne_1.IDPersonne " & _
			 "WHERE Couple.IDPersMasc=" & intX & " OR Couple.IDPersFem=" & intX & " " & _
			 "UNION " & _
			 "SELECT 'a' AS DtCouple, 'a' AS IDC, Personne.IDPersonne AS MID, Personne.IDCouple AS MIDC, Personne.Prenom AS MP, Personne.Nom AS MN, Personne.DtNaiss AS MDN, Personne.DtDec AS MDD, Personne.IDPersonne AS FID, Personne.IDCouple AS FIDC, Personne.Prenom AS FP, Personne.Nom AS FN, Personne.DtNaiss AS FDN, Personne.DtDec AS FDD " & _
			 "FROM Personne " & _
			 "WHERE IDPersonne=" & intX
	rs0.Open strSQL, conConnexion, 2, 3

	while not rs0.EOF
		intPosMax = intPosMax + 1
		rs0.MoveNext
	wend
	rs0.MoveFirst
	
	intPos = int(intPos)
	intCpt = 1
	while intCpt < intPos and not rs0.EOF
		intCpt = intCpt + 1
		rs0.MoveNext
	wend
	

	if not rs0.EOF then
		lngIDC = rs0("IDC")
		if lngIDC = "a" then
			strNomPersonne = rs0("MP") & " " & rs0("MN")
			strNomCouple   = rs0("MP") & " " & rs0("MN")
		else
			if Ucase(intX) = Ucase(rs0("MID")) then
				strNomPersonne = rs0("MP") & " " & rs0("MN")
			else
				strNomPersonne = rs0("FP") & " " & rs0("FN")
			end if
			strNomCouple   = rs0("MP") & " " & rs0("MN") & " - " & rs0("FP") & " " & rs0("FN")
		end if
	end if

	rs0.Close
End Sub

'*******************************************************************************************************************************

Sub SetStructureDOWN(lngIDC, hasChildren) 'Find if their are children

	strSQL = "SELECT * FROM Personne WHERE IDCouple=" & lngIDC & " ORDER BY TriCouple"
	rs1.Open strSQL, conConnexion

	if not rs1.EOF then 
		hasChildren = true
	else
		hasChildren = false
	end if

End Sub
%>
