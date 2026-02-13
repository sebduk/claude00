<%

'*******************************************************************************************************************************
'* Pour arbre.desc.excel.asp / arbre.desc.tab.asp
'*******************************************************************************************************************************

Sub SetStructure(lngID) 'Find Couple/Person

	dim intCurCol, intCurRow

	intCurCol = 0
	intMaxCol = 0

	intCurRow = -1
	intMaxRow = 0
	
	strSQL = "SELECT Couple.IDCouple, Personne.IDPersonne AS MID, Personne.IDCouple AS MIDC, Personne.Prenom AS MP, Personne.Nom AS MN, Personne.DtNaiss AS MDN, Personne.DtDec AS MDD, Personne_1.IDPersonne AS FID, Personne_1.IDCouple AS FIDC, Personne_1.Prenom AS FP, Personne_1.Nom AS FN, Personne_1.DtNaiss AS FDN, Personne_1.DtDec AS FDD " & _
			 "FROM (Couple INNER JOIN Personne ON Couple.IDPersMasc = Personne.IDPersonne) INNER JOIN Personne AS Personne_1 ON Couple.IDPersFem = Personne_1.IDPersonne " & _
			 "WHERE Personne.IDPersonne=" & lngID & " OR Personne_1.IDPersonne=" & lngID & " " & _
			 "ORDER BY Couple.DtCouple"
	rs0.Open strSQL, conConnexion, 2, 3

'Response.Write "strSQL:top<br>" & strSQL & "<br><br>"

	while not rs0.EOF

		intCurCol = 1
		intCurRow = intCurRow + 2

		if intMaxCol < intCurCol then intMaxCol = intCurCol
		if intMaxRow < intCurRow + 3 then intMaxRow = intCurRow + 3

		redim preserve tabArbre(40, intMaxRow)

		tabArbre(intCurCol, intCurRow + 0) = rs0("MP") & " " & rs0("MN")	'server.HTMLEncode(rs0("MP") & " " & rs0("MN"))
		tabArbre(intCurCol, intCurRow + 1) = "(" & rs0("MDN") & "-" & rs0("MDD") & ")" 
		tabArbre(intCurCol, intCurRow + 2) = rs0("FP") & " " & rs0("FN")	'server.HTMLEncode(rs0("FP") & " " & rs0("FN"))
		tabArbre(intCurCol, intCurRow + 3) = "(" & rs0("FDN") & "-" & rs0("FDD") & ")" 
		intCurRow = intCurRow + 3
		if intMaxRow < intCurRow then intMaxRow = intCurRow

		SetStructureDOWN rs0("IDCouple"), intCurCol + 1, intCurRow
		
		intCurRow = intMaxRow

		rs0.MoveNext
	wend 
		
	rs0.Close
End Sub

'*******************************************************************************************************************************

Sub SetStructureDOWN(lngIDC, intCurCol, intCurRow) 'Find Initial Couple/Person's filiation
	
	if intMaxCol < intCurCol then intMaxCol = intCurCol

	Dim rsRec1, rsRec2, isFirstChild
	Set rsRec1 = Server.CreateObject("ADODB.Recordset")
	Set rsRec2 = Server.CreateObject("ADODB.Recordset")

	strSQL = "SELECT * FROM Personne WHERE IDCouple=" & lngIDC & " ORDER BY TriCouple"
	rsRec1.Open strSQL, conConnexion

	isFirstChild = true

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
			while not rsRec2.EOF		  'for each Marriage
				if rsRec2("IDCouple") <> "a" then	'skip bachelor card (Low Union)
					
					if isFirstChild then
						intCurRow = intCurRow - 3
						isFirstChild = false
					else
						intCurRow = intCurRow + 2
						if intMaxRow < intCurRow + 3 then intMaxRow = intCurRow + 3
						Redim preserve tabArbre(40, intMaxRow)
					end if
					
					tabArbre(intCurCol, intCurRow + 0) = rsRec2("MP") & " " & rsRec2("MN")	'server.HTMLEncode(rsRec2("MP") & " " & rsRec2("MN"))
					tabArbre(intCurCol, intCurRow + 1) = "(" & rsRec2("MDN") & "-" & rsRec2("MDD") & ")"
					tabArbre(intCurCol, intCurRow + 2) = rsRec2("FP") & " " & rsRec2("FN")	'server.HTMLEncode(rsRec2("FP") & " " & rsRec2("FN"))
					tabArbre(intCurCol, intCurRow + 3) = "(" & rsRec2("FDN") & "-" & rsRec2("FDD") & ")"
					intCurRow = intCurRow + 3	
					if intMaxRow < intCurRow then intMaxRow = intCurRow
					
					SetStructureDOWN rsRec2("IDCouple"), intCurCol + 1, intCurRow

					intCurRow = intMaxRow

				end if
				rsRec2.MoveNext
			wend

		else 'if the Child has no Spouse

			if isFirstChild then
				intCurRow = intCurRow - 3
				isFirstChild = false
			else
				intCurRow = intCurRow + 2
				if intMaxRow < intCurRow + 1 then intMaxRow = intCurRow + 1
				Redim preserve tabArbre(40, intMaxRow)
			end if

			tabArbre(intCurCol, intCurRow + 0) = rsRec2("MP") & " " & rsRec2("MN")	'server.HTMLEncode(rsRec2("MP") & " " & rsRec2("MN"))
			tabArbre(intCurCol, intCurRow + 1) = "(" & rsRec2("MDN") & "-" & rsRec2("MDD") & ")"
			intCurRow = intCurRow + 1	
			if intMaxRow < intCurRow then intMaxRow = intCurRow
													
		end if

		rsRec2.Close
		rsRec1.MoveNext
	wend
	
	rsRec1.Close

End Sub
%>
