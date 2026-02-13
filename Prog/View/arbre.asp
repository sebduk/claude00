<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->
<!--#include VIRTUAL="/Include/label.asp"-->

<%
if Session(strUpload & "IsUser") <> true then
	Response.Redirect "/login.asp"
else
%>

<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
	Dim lngID, lngIDC, intPos, intPosMax, strNomPersonne, strNomCouple, i
	Dim ParamTable, hasChildren

	ParamTable = "<table border=0 cellpadding=5 cellspacing=0 align=center>"

	Public lngStructID()
	Redim lngStructID(22)
	Public lngStructIDC()
	Redim lngStructIDC(22)
	Public lngStructP()
	Redim lngStructP(22)
	Public lngStructN()
	Redim lngStructN(22)
	Public lngStructDN()
	Redim lngStructDN(22)
	Public lngStructDD()
	Redim lngStructDD(22)

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

	'Level -1 
	'Set 11, 12, 13 and 14
	if lngStructID(21)<>empty then SetStructureUP 21, 11, 12
	if lngStructID(22)<>empty then SetStructureUP 22, 13, 14

	'Level -2 
	'Set 1, 2, 3, 4, 5, 6, 7 and 8
	if lngStructID(11)<>empty then SetStructureUP 11, 1, 2
	if lngStructID(12)<>empty then SetStructureUP 12, 3, 4
	if lngStructID(13)<>empty then SetStructureUP 13, 5, 6
	if lngStructID(14)<>empty then SetStructureUP 14, 7, 8



	if lngIDC<>"a" then 'If IDPerso has a Spouse

		Response.Write ParamTable

		Response.Write "<tr valign=bottom>" 'Level -2
		for i = 1 to 8
			if i/2 = int(i/2) then
				Response.Write "<td width=""12%"">"
			else
				Response.Write "<td align=right width=""13%"">"
			end if

			if lngStructID(i)<>empty then
				Response.Write "<a href=frame.asp?IDPerso=" & lngStructID(i) & " target=main>" & replace(lngStructP(i) & " " & lngStructN(i), " ", "&nbsp;") & "</a><br>"
				Response.Write "(<a href=bio.asp?ID=" & lngStructID(i) & " target=main>" & lngStructDN(i) & "-" & lngStructDD(i) & "</a>)"
			else
				Response.Write "?&nbsp;?<br>(?-?)"
			end if
			Response.Write "</td>"
		next
		Response.Write "</tr>"

		Response.Write "<tr>" 'Level -1
		for i = 11 to 14
			if i/2 = int(i/2) then
				Response.Write "<td colspan=2 width=""25%"">"
			else
				Response.Write "<td colspan=2 align=right width=""25%"">"
			end if

			if lngStructID(i)<>empty then
				Response.Write "<hr size=1 noshade>"
				Response.Write "<a href=frame.asp?IDPerso=" & lngStructID(i) & " target=main>" & replace(server.HTMLEncode(lngStructP(i) & " " & lngStructN(i)), " ", "&nbsp;") & "</a><br>"
				Response.Write "(<a href=bio.asp?ID=" & lngStructID(i) & " target=main>" & lngStructDN(i) & "-" & lngStructDD(i) & "</a>)"
			else
				Response.Write "<hr size=1 noshade>"
				Response.Write "?&nbsp;?<br>(?-?)"
			end if
			Response.Write "</td>"
		next
		Response.Write "</tr>"

		Response.Write "<tr>" 'Level 0
		for i = 21 to 22
			if i/2 = int(i/2) then
				Response.Write "<td colspan=4>"
			else
				Response.Write "<td colspan=4 align=right>"
			end if

			if lngStructID(i)<>empty then
				Response.Write "<hr size=1 noshade>"
				Response.Write "<b><a href=frame.asp?IDPerso=" & lngStructID(i) & " target=main>" & replace(server.HTMLEncode(lngStructP(i) & " " & lngStructN(i)), " ", "&nbsp;") & "</a><br>"
				Response.Write "(<a href=bio.asp?ID=" & lngStructID(i) & " target=main>" & lngStructDN(i) & "-" & lngStructDD(i) & "</a>)</b>"
			else
				Response.Write "<hr size=1 noshade>"
				Response.Write "?&nbsp;?<br>(?-?)"
			end if
			Response.Write "</td>"
		next
		Response.Write "</tr>"

		Response.Write "<tr>" 'Level +
		Response.Write "<td colspan=8 align=center>"
		Response.Write "<hr size=1 noshade>"

		SetStructureDOWN lngIDC, hasChildren

		Response.Write "</td>"
		Response.Write "</tr>"


		Response.Write "</table>"

		Response.Write "<br><br><br><br><br>"

		'Mariages multiples
		if intPosMax > 2 then
			Response.Write ""
			for i = 1 to intPosMax - 1
				if i <> intPos then
					Response.Write ".<a href=frame.asp?IDPerso=" & lngID & "&pos=" & i & " target=main>" & strCouple & " " & i & "</a>"
				else
					Response.Write ".<b>" & strCouple & " " & i & "</b>"
				end if
			next
			Response.Write ".<br><br>"
		end if


	'	Response.Write strNomPersonne & "<br><br>"
	'	Response.Write strFullAscendance & ":<br>"
	'	Response.Write "[<a href=arbre.asc.h.asp?IDPerso=" & lngID & " target=_blank>" & strHorizontalVersion & "</a>]<br>"
	'	Response.Write "[<a href=arbre.asc.v.asp?IDPerso=" & lngID & " target=_blank>" & strVerticalVersion & "</a>]<br>"
	'	Response.Write "[<a href=arbre.asc.tab.asp?IDPerso=" & lngID & " target=_blank>" & strTableVersion & "</a>]<br>"
	'	Response.Write "[<a href=arbre.asc.excel.asp?IDPerso=" & lngID & " target=_blank>" & strExcelVersion & "</a>]<br>"
	'	Response.Write "<br>"

	'	if hasChildren then
	'		Response.Write strFullDescendance & ":<br>"
	'		Response.Write "[<a href=arbre.desc.h.asp?IDPerso=" & lngID & " target=_blank>" & strHorizontalVersion & "</a>]<br>"
	'		Response.Write "[<a href=arbre.desc.v.asp?IDPerso=" & lngID & " target=_blank>" & strVerticalVersion & "</a>]<br>"
	'		Response.Write "[<a href=arbre.desc.tab.asp?IDPerso=" & lngID & " target=_blank>" & strTableVersion & "</a>]<br>"
	'		Response.Write "[<a href=arbre.desc.excel.asp?IDPerso=" & lngID & " target=_blank>" & strExcelVersion & "</a>]<br><br>"
	'	end if
		
	'	Response.Write "<i>" & strFullVersionWarning & "</i><br>"

	else 'if IDPerso has no Spouse

		Response.Write ParamTable

		Response.Write "<tr valign=bottom>" 'Level -2
		for i = 1 to 4
			if i/2 = int(i/2) then
				Response.Write "<td width=""25%"">"
			else
				Response.Write "<td align=right width=""25%"">"
			end if

			if lngStructID(i)<>empty then
				Response.Write "<a href=frame.asp?IDPerso=" & lngStructID(i) & " target=main>" & replace(server.HTMLEncode(lngStructP(i) & " " & lngStructN(i)), " ", "&nbsp;") & "</a><br>"
				Response.Write "(<a href=bio.asp?ID=" & lngStructID(i) & " target=main>" & lngStructDN(i) & "-" & lngStructDD(i) & "</a>)"
			else
				Response.Write "?&nbsp;?<br>(?-?)"
			end if
			Response.Write "</td>"
		next
		Response.Write "</tr>"

		Response.Write "<tr>" 'Level -1
		for i = 11 to 12
			if i/2 = int(i/2) then
				Response.Write "<td colspan=2 width=""50%"">"
			else
				Response.Write "<td colspan=2 align=right width=""50%"">"
			end if

			if lngStructID(i)<>empty then
				Response.Write "<hr size=1 noshade>"
				Response.Write "<a href=frame.asp?IDPerso=" & lngStructID(i) & " target=main>" & replace(server.HTMLEncode(lngStructP(i) & " " & lngStructN(i)), " ", "&nbsp;") & "</a><br>"
				Response.Write "(<a href=bio.asp?ID=" & lngStructID(i) & " target=main>" & lngStructDN(i) & "-" & lngStructDD(i) & "</a>)"
			else
				Response.Write "<hr size=1 noshade>"
				Response.Write "?&nbsp;?<br>(?-?)"
			end if
			Response.Write "</td>"
		next
		Response.Write "</tr>"

		Response.Write "<tr>" 'Level 0
		Response.Write "<td colspan=4 align=center>"

		i = 21
		Response.Write "<hr size=1 noshade>"
		Response.Write "<b><a href=frame.asp?IDPerso=" & lngStructID(i) & " target=main>" & replace(server.HTMLEncode(lngStructP(i) & " " & lngStructN(i)), " ", "&nbsp;") & "</a><br>"
		Response.Write "(<a href=bio.asp?ID=" & lngStructID(i) & " target=main>" & lngStructDN(i) & "-" & lngStructDD(i) & "</a>)</b>"

		Response.Write "</td>"
		Response.Write "</tr>"

		Response.Write "</table>"

	'	Response.Write "<br><br><br><br><br>"
	'	Response.Write strNomPersonne & "<br><br>"
	'	Response.Write strFullAscendance & ":<br>"
	'	Response.Write "[<a href=arbre.asc.h.asp?IDPerso=" & lngID & " target=_blank>" & strHorizontalVersion & "</a>]<br>"
	'	Response.Write "[<a href=arbre.asc.v.asp?IDPerso=" & lngID & " target=_blank>" & strVerticalVersion & "</a>]<br>"
	'	Response.Write "[<a href=arbre.asc.tab.asp?IDPerso=" & lngID & " target=_blank>" & strTableVersion & "</a>]<br>"
	'	Response.Write "[<a href=arbre.asc.excel.asp?IDPerso=" & lngID & " target=_blank>" & strExcelVersion & "</a>]<br>"
	'	Response.Write "<br><i>" & strFullVersionWarning & "</i><br>"

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
			 "SELECT 'a' as DtCouple, 'a' AS IDC, Personne.IDPersonne AS MID, Personne.IDCouple AS MIDC, Personne.Prenom AS MP, Personne.Nom AS MN, Personne.DtNaiss AS MDN, Personne.DtDec AS MDD, Personne.IDPersonne AS FID, Personne.IDCouple AS FIDC, Personne.Prenom AS FP, Personne.Nom AS FN, Personne.DtNaiss AS FDN, Personne.DtDec AS FDD " & _
			 "FROM Personne " & _
			 "WHERE IDPersonne=" & intX
	rs0.Open strSQL, conConnexion, 2, 3
	''a' to set these lines behind the possible couples in the UNION (both fields contain numerical values

'Response.Write VbCrlf & "<!--strSQL=" & strSQL & "-->" & VbCrlf

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
			lngStructID(21)  = rs0("MID")
			lngStructIDC(21) = rs0("MIDC")
			lngStructP(21)   = rs0("MP")
			lngStructN(21)   = rs0("MN")
			lngStructDN(21)  = rs0("MDN")
			lngStructDD(21)  = rs0("MDD")
			
			strNomPersonne = lngStructP(21) & " " & lngStructN(21)
			strNomCouple   = lngStructP(21) & " " & lngStructN(21)
		else
			lngStructID(21)  = rs0("MID")
			lngStructIDC(21) = rs0("MIDC")
			lngStructP(21)   = rs0("MP")
			lngStructN(21)   = rs0("MN")
			lngStructDN(21)  = rs0("MDN")
			lngStructDD(21)  = rs0("MDD")

			lngStructID(22)  = rs0("FID")
			lngStructIDC(22) = rs0("FIDC")
			lngStructP(22)   = rs0("FP")
			lngStructN(22)   = rs0("FN")
			lngStructDN(22)  = rs0("FDN")
			lngStructDD(22)  = rs0("FDD")

			if Ucase(intX) = Ucase(lngStructID(21)) then
				strNomPersonne = lngStructP(21) & " " & lngStructN(21)
			else
				strNomPersonne = lngStructP(22) & " " & lngStructN(22)
			end if
			strNomCouple   = lngStructP(21) & " " & lngStructN(21) & " - " & lngStructP(22) & " " & lngStructN(22)
		end if
	end if

	rs0.Close
End Sub

'*******************************************************************************************************************************

Sub SetStructureUP(intX, intXM, intXF) 'Find Ancestors of Initial Couple/Person
	strSQL = "SELECT Couple.IDCouple AS IDC, Personne.IDPersonne AS MID, Personne.IDCouple AS MIDC, Personne.Prenom AS MP, Personne.Nom AS MN, Personne.DtNaiss AS MDN, Personne.DtDec AS MDD, Personne_1.IDPersonne AS FID, Personne_1.IDCouple AS FIDC, Personne_1.Prenom AS FP, Personne_1.Nom AS FN, Personne_1.DtNaiss AS FDN, Personne_1.DtDec AS FDD " & _
			 "FROM (Couple INNER JOIN Personne ON Couple.IDPersMasc = Personne.IDPersonne) INNER JOIN Personne AS Personne_1 ON Couple.IDPersFem = Personne_1.IDPersonne " & _
			 "WHERE Couple.IDCouple=" & lngStructIDC(intX)
	rs0.Open strSQL, conConnexion, 2, 3

	if not rs0.EOF then
		lngStructID(intXM)  = rs0("MID")
		lngStructIDC(intXM) = rs0("MIDC")
		lngStructP(intXM)   = rs0("MP")
		lngStructN(intXM)   = rs0("MN")
		lngStructDN(intXM)  = rs0("MDN")
		lngStructDD(intXM)  = rs0("MDD")

		lngStructID(intXF)  = rs0("FID")
		lngStructIDC(intXF) = rs0("FIDC")
		lngStructP(intXF)   = rs0("FP")
		lngStructN(intXF)   = rs0("FN")
		lngStructDN(intXF)  = rs0("FDN")
		lngStructDD(intXF)  = rs0("FDD")
	end if

	rs0.Close
End Sub

'*******************************************************************************************************************************

Sub SetStructureDOWN(lngIDC, hasChildren) 'Find Initial Couple/Person's filiation

	Response.Write ParamTable											
	Response.Write "<tr valign=top>"											

	strSQL = "SELECT * FROM Personne WHERE IDCouple=" & lngIDC & " ORDER BY TriCouple"
	rs1.Open strSQL, conConnexion

	hasChildren = false

	while not rs1.EOF 'for each child
		
		hasChildren = true

	'	strSQL = "SELECT Couple.IDCouple, Personne.IDPersonne AS MID, Personne.Prenom AS MP, Personne.Nom AS MN, Personne.DtNaiss AS MDN, Personne.DtDec AS MDD, Personne.IsFamDir AS MFamDir, Personne_1.IDPersonne AS FID, Personne_1.Prenom AS FP, Personne_1.Nom AS FN, Personne_1.DtNaiss AS FDN, Personne_1.DtDec AS FDD, Personne_1.IsFamDir AS FFamDir, Personne.IsMasc " & _
	'			 "FROM (Couple INNER JOIN Personne ON Couple.IDPersMasc = Personne.IDPersonne) INNER JOIN Personne AS Personne_1 ON Couple.IDPersFem = Personne_1.IDPersonne " & _
	'			 "WHERE Couple.IDPersMasc=" & rs1("IDPersonne") & " OR Couple.IDPersFem=" & rs1("IDPersonne") & " " & _
	'			 "UNION " & _
	'			 "SELECT 'a' AS IDCouple, Personne.IDPersonne AS MID, Personne.Prenom AS MP, Personne.Nom AS MN, Personne.DtNaiss AS MDN, Personne.DtDec AS MDD, Personne.IsFamDir AS MFamDir, Personne.IDPersonne AS FID, Personne.Prenom AS FP, Personne.Nom AS FN, Personne.DtNaiss AS FDN, Personne.DtDec AS FDD, Personne.IsFamDir AS FFamDir, Personne.IsMasc " & _
	'			 "FROM Personne " & _
	'			 "WHERE IDPersonne=" & rs1("IDPersonne")
		strSQL = "SELECT Couple.IDCouple, Personne.IDPersonne AS MID, Personne.Prenom AS MP, Personne.Nom AS MN, Personne.DtNaiss AS MDN, Personne.DtDec AS MDD, Personne_1.IDPersonne AS FID, Personne_1.Prenom AS FP, Personne_1.Nom AS FN, Personne_1.DtNaiss AS FDN, Personne_1.DtDec AS FDD, Personne.IsMasc " & _
				 "FROM (Couple INNER JOIN Personne ON Couple.IDPersMasc = Personne.IDPersonne) INNER JOIN Personne AS Personne_1 ON Couple.IDPersFem = Personne_1.IDPersonne " & _
				 "WHERE Couple.IDPersMasc=" & rs1("IDPersonne") & " OR Couple.IDPersFem=" & rs1("IDPersonne") & " " & _
				 "UNION " & _
				 "SELECT 'a' AS IDCouple, Personne.IDPersonne AS MID, Personne.Prenom AS MP, Personne.Nom AS MN, Personne.DtNaiss AS MDN, Personne.DtDec AS MDD, Personne.IDPersonne AS FID, Personne.Prenom AS FP, Personne.Nom AS FN, Personne.DtNaiss AS FDN, Personne.DtDec AS FDD, Personne.IsMasc " & _
				 "FROM Personne " & _
				 "WHERE IDPersonne=" & rs1("IDPersonne")
		rs2.Open strSQL, conConnexion

		if rs2("IDCouple") <> "a" then 'if the Child has a Spouse
			while not rs2.EOF
				if rs2("IDCouple") <> "a" then
			
					Response.Write "<!-- Level +1 w/ Spouse  --><td>" & ParamTable & "<tr>"											
																																			
					Response.Write "<td align=right width=""50%"">" 		
					Response.Write "<a href=frame.asp?IDPerso=" & rs2("MID") & " target=main>" & replace(server.HTMLEncode(rs2("MP") & " " & rs2("MN")), " ", "&nbsp;") & "</a><br>"
					Response.Write "(<a href=bio.asp?ID=" & rs2("MID") & " target=main>" & rs2("MDN") & "-" & rs2("MDD") & "</a>)</td>"			
																																			
					Response.Write "<td width=""50%"">" 		
					Response.Write "<a href=frame.asp?IDPerso=" & rs2("FID") & " target=main>" & replace(server.HTMLEncode(rs2("FP") & " " & rs2("FN")), " ", "&nbsp;") & "</a><br>"
					Response.Write "(<a href=bio.asp?ID=" & rs2("FID") & " target=main>" & rs2("FDN") & "-" & rs2("FDD") & "</a>)</td>"			
																																			
					Response.Write "</tr><tr><td colspan=3 align=center><hr size=1 noshade>"														
					Response.Write ParamTable & "<tr align=center valign=bottom>"													


					strSQL = "SELECT * FROM Personne WHERE IDCouple=" & rs2("IDCouple") & " ORDER BY TriCouple"
					rs3.Open strSQL, conConnexion

					while not rs3.EOF 'for each Grand Child of the Child Couple
						Response.Write "<!-- Level +2 --><td>"
						Response.Write "<a href=frame.asp?IDPerso=" & rs3("IDPersonne") & " target=main>" & replace(server.HTMLEncode(rs3("Prenom") & " " & rs3("Nom")), " ", "&nbsp;") & "</a><br>"
						Response.Write "(<a href=bio.asp?ID=" & rs3("IDPersonne") & " target=main>" & rs3("DtNaiss") & "-" & rs3("DtDec") & "</a>)</td>"			
						rs3.MoveNext
					wend

					Response.Write "</tr></Table></td></tr></table></td>"											
					rs3.Close

				end if
				rs2.MoveNext
			wend

		else 'if the Child has no Spouse

			Response.Write "<!-- Level +1 w/o Spouse --><td>" & ParamTable & "<tr><td align=center>"		
			Response.Write "<a href=frame.asp?IDPerso=" & rs2("MID") & " target=main>" & replace(server.HTMLEncode(rs2("MP") & " " & rs2("MN")), " ", "&nbsp;") & "</a><br>"
			Response.Write "(<a href=bio.asp?ID=" & rs2("MID") & " target=main>" & rs2("MDN") & "-" & rs2("MDD") & "</a>)</td>"			
			Response.Write "</tr></table></td>"									
		end if

		rs2.Close
		rs1.MoveNext
	wend

	Response.Write "</tr></Table>"																							

End Sub
%>
