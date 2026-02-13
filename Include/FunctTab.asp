<SCRIPT LANGUAGE="VBSCRIPT" RUNAT="SERVER">

'################################################
'# Gère la présentation, Ajout, Màj, Suppr des tables attachées
'################################################
	Sub GereTab(strTitre, strEntete, strSQL, strValDef, numLign, strPageOrigine)

	Dim strColName(), intColSize(), varValDef(), strAction

	Parse strEntete, strColName, intColSize, strValDef, varValDef

	if strSQL <> "" and strEntete <> "" then

		if numLign = EMPTY then numLign = 1
		strAction = Request("AFAIRE")

		Select Case strAction
			Case "ADD"
				AddItem strSQL, varValDef	

			Case "UPDATE"
				UpdateItem strSQL, varValDef

			Case "DELETE"
				DelItem strSQL	
		End Select

		PresTab strTitre, strEntete, strSQL, strValDef, numLign, strPageOrigine, strColName, intColSize

	end if

End Sub



'################################################
'# Présente les tables attachées                #
'################################################
Sub PresTab(strTitre, strEntete, strSQL, strValDef, numLign, strPageOrigine, strColName(), intColSize())

	dim rsTab, CouleurEntete, CouleurLignes, CouleurNeutre, CouleurAjout
	dim i
	dim bolLign, cptLign, lngFirstRec
	dim strIdPays, intAnnee, lngIdStructMono


	CouleurEntete = "bgcolor=#990000"
	CouleurLignes = "bgcolor=#ffffc0"
	CouleurNeutre = "bgcolor=#ffffff"
	CouleurAjout  = "bgcolor=#990000"


'Ouvre le RS
'-----------
'Response.Write strSQL
'Response.End
	Set rsTab = Server.CreateObject("ADODB.Recordset")
	rsTab.Open strSQL, conConnexion, 2, 2


'Positionner sur le Prem Record
'------------------------------
	if numLign < 1 then numLign = 1

	i = 1
	while CInt(i) < CInt(numLign) AND Not rsTab.EOF
		rsTab.MoveNext
		i = i + 1
	wend
	if rsTab.EOF then numLign = i


'Entete du tableau
'-----------------
	TabTop strTitre, strColName, CouleurEntete
	bolLign = True
	cptLign = 1
	lngFirstRec = numLign


'Lignes du tableau avec Update et Delete
'---------------------------------------
	while not rsTab.EOF AND cptLign <= Application("intTabLigMax") 
		
		Response.Write "<form action=""" & strPageOrigine & """ method=post name=""UpDate" & cptLign & """>" & vbCrlf
		Response.Write "<input type=hidden name=""AFAIRE"" value=""UPDATE"">" & vbCrlf
		
		if bolLign then
			Response.Write "<tr valign=top align=center " & CouleurNeutre & ">" & vbCrlf
		else
			Response.Write "<tr valign=top align=center " & CouleurLignes & ">" & vbCrlf
		end if

		Response.Write "<td align=right>" & numLign & "</td>" & VbCrlf

		for i = 1 to UBound(strColName)		
			if i = 1 then
				if strColName(i) = "" then
					Response.Write "<input type=hidden name=""ID"" value=""" & rsTab(i-1) & """>" & vbCrlf
				else
					Response.Write "<td><input type=text size=" & intColSize(i) & " name=""ID"" value=""" & rsTab(i-1) & """></td>" & VbCrlf
				end if
			elseif strColName(i) = "" then
				Response.Write "<input type=hidden name=""" & rsTab(i-1).Name & """ value=""" & rsTab(i-1) & """>" & vbCrlf
			elseif intColSize(i) = 0 then
				Response.Write "<td><textarea cols=50 rows=10 name=""" & rsTab(i-1).Name & """>" & rsTab(i-1) & "</textarea></td>" & VbCrlf 
			else
				Response.Write "<td><input type=text size=" & intColSize(i) & " name=""" & rsTab(i-1).Name & """ value=""" & rsTab(i-1) & """></td>" & VbCrlf
			end if
		next
		
		Response.Write "<input type=hidden name=""TITRE"" value=""" & strTitre & """>" & VbCrlf
		Response.Write "<input type=hidden name=""VALDEF"" value=""" & strValDef & """>" & VbCrlf
		Response.Write "<input type=hidden name=""FIRSTREC"" value=""" & lngFirstRec & """>" & VbCrlf
		Response.Write "<input type=hidden name=""SQL"" value=""" & strSQL & """>" & VbCrlf
		Response.Write "<input type=hidden name=""ENTETE"" value=""" & strEntete & """>" & VbCrlf
		Response.Write "<td><input type=image src=""" & Application("strImagePath") & "/btnUpdate.gif"" border=0></td></form>" & VbCrlf

		Response.Write "<form action=""" & strPageOrigine & """ method=post name=""Delete" & cptLign & """>" & vbCrlf
		Response.Write "<input type=hidden name=""AFAIRE"" value=""DELETE"">" & vbCrlf
		Response.Write "<input type=hidden name=""TITRE"" value=""" & strTitre & """>" & VbCrlf
		Response.Write "<input type=hidden name=""VALDEF"" value=""" & strValDef & """>" & VbCrlf
		Response.Write "<input type=hidden name=""FIRSTREC"" value=""" & lngFirstRec & """>" & VbCrlf
		Response.Write "<input type=hidden name=""SQL"" value=""" & strSQL & """>" & VbCrlf
		Response.Write "<input type=hidden name=""ENTETE"" value=""" & strEntete & """>" & VbCrlf
		Response.Write "<input type=hidden name=""ID"" value=""" & rsTab(0) & """>" & vbCrlf
		Response.Write "<td><input type=image src=""" & Application("strImagePath") & "/btnDel.gif"" border=0></td></form>" & VbCrlf

		Response.Write "</tr>" & VbCrlf & VbCrlf

		rsTab.MoveNext
		cptLign = cptLign + 1
		numLign = numLign + 1
		bolLign = Not bolLign
	wend


'Pied du tableau avec Add
'------------------------
	Response.Write VbCrlf & "<form action=""" & strPageOrigine & """ method=post name=""Add"">" & vbCrlf
	Response.Write "<input type=hidden name=""AFAIRE"" value=""ADD"">" & vbCrlf
	Response.Write "<tr valign=top align=center " & CouleurAjout & ">" & vbCrlf
	Response.Write "<td>&nbsp;</td>" & vbCrlf

	for i = 1 to UBound(strColName)		
		if i = 1 then
			if strColName(i) = "" then
				Response.Write "<input type=hidden name=""ID"">" & VbCrlf
			else
				Response.Write "<td><input type=text size=" & intColSize(i) & " name=""ID""></td>" & VbCrlf
			end if
		elseif strColName(i) = "" then
			Response.Write "<input type=hidden name=""" & rsTab(i-1).Name & """>" & VbCrlf
		elseif intColSize(i) = 0 then
			Response.Write "<td><textarea cols=50 rows=10 name=""" & rsTab(i-1).Name & """></textarea></td>" & VbCrlf
		else
			Response.Write "<td><input type=text size=" & intColSize(i) & " name=""" & rsTab(i-1).Name & """></td>" & VbCrlf
		end if
	next
	
	Response.Write "<input type=hidden name=""TITRE"" value=""" & strTitre & """>" & VbCrlf
	Response.Write "<input type=hidden name=""VALDEF"" value=""" & strValDef & """>" & VbCrlf
	Response.Write "<input type=hidden name=""FIRSTREC"" value=""" & lngFirstRec & """>" & VbCrlf
	Response.Write "<input type=hidden name=""SQL"" value=""" & strSQL & """>" & VbCrlf
	Response.Write "<input type=hidden name=""ENTETE"" value=""" & strEntete & """>" & VbCrlf
	Response.Write "<td><input type=image src=""" & Application("strImagePath") & "/btnAdd.gif"" border=0></td></form>" & VbCrlf
	Response.Write "<td>&nbsp;</td>" & VbCrlf
	Response.Write "</tr>" & VbCrlf


'Bas de Tableau et Navigation
'----------------------------
	TabBot strPageOrigine, strTitre, strSQL, strEntete, strValDef, lngFirstRec, rsTab.EOF, CouleurLignes

	rsTab.close
	Set rsTab = Nothing

End Sub



'################################################
'# Cadre et haut du tableau                     #
'################################################
Sub TabTop(strTitre, strColName(), CouleurEntete) 

	Response.Write "<center>" & VbCrlf
	Response.Write "<h3>" & strTitre & "</h3>" & VbCrlf

'Ouvre le cadre du tableau
	Response.Write "<table border=1 bordercolor=#990000 cellpadding=0 cellspacing=0>" & VbCrlf
	Response.Write "<tr>" & VbCrlf
	Response.Write "<td colspan=3>" & VbCrlf & VbCrlf

'Ouvre le tableau
	Response.Write "<table border=0 cellpadding=3 cellspacing=0>" & VbCrlf
	Response.Write "<tr>" & VbCrlf & VbCrlf

'Met les Entetes
	PresTabEntete strColName, CouleurEntete

End Sub



'################################################
'# Bas du tableau et Cadre                      #
'################################################
Sub TabBot(strPageOrigine, strTitre, strSQL, strEntete, strValDef, lngFirstRec, bolIsEOF, CouleurNav) 

'Ferme le tableau
	Response.Write "</table>" & VbCrlf

'Ferme le cadre du tableau et Ajouter Btn Nav
	Response.Write "</td>" & VbCrlf 
	Response.Write "</tr>" & VbCrlf & VbCrlf

	Response.Write "<tr " & CouleurNav & ">" & VbCrlf
	Response.Write "<form action=""" & strPageOrigine & """ method=post name=REW>" & VbCrlf
	Response.Write "<td align=right>"
	
	if lngFirstRec =1 then
		Response.Write Application("BtnG_off") & VbCrlf
	else
		Response.Write "<input type=image src=""" & Application("strImagePath") & "/btn_leftarrow_on.gif"" border=0>" & VbCrlf
		Response.Write "<input type=hidden name=""TITRE"" value=""" & strTitre & """>" & VbCrlf
		Response.Write "<input type=hidden name=""VALDEF"" value=""" & strValDef & """>" & VbCrlf
		Response.Write "<input type=hidden name=""FIRSTREC"" value=""" & lngFirstRec - Application("intTabLigMax") & """>" & VbCrlf
		Response.Write "<input type=hidden name=""SQL"" value=""" & strSQL & """>" & VbCrlf
		Response.Write "<input type=hidden name=""ENTETE"" value=""" & strEntete & """>" & VbCrlf
	end if

	Response.Write "</td></form>" & VbCrlf


	Response.Write "<form action=""" & strPageOrigine & """ method=post name=""DIRECT"">" & VbCrlf
	Response.Write "<td align=center>" & VbCrlf

	Response.Write "<input type=hidden name=""TITRE"" value=""" & strTitre & """>" & VbCrlf
	Response.Write "<input type=hidden name=""VALDEF"" value=""" & strValDef & """>" & VbCrlf
	Response.Write "<input type=text size=4 name=""FIRSTREC"" value=""" & lngFirstRec & """ onChange=""document.DIRECT.submit();"">" & VbCrlf
	'Response.Write "<input type=text size=4 name=""FIRSTREC"" value=""" & lngFirstRec & """>" & VbCrlf
	Response.Write "<input type=hidden name=""SQL"" value=""" & strSQL & """>" & VbCrlf
	Response.Write "<input type=hidden name=""ENTETE"" value=""" & strEntete & """>" & VbCrlf

	Response.Write "</td></form>" & VbCrlf


	Response.Write "<form action=""" & strPageOrigine & """ method=post name=FWD>" & VbCrlf
	Response.Write "<td align=left>" & VbCrlf

	if bolIsEOF then
		Response.Write Application("BtnD_off")
	else
		Response.Write "<input type=image src=""" & Application("strImagePath") & "/btn_rightarrow_on.gif"" border=0>" & VbCrlf
		Response.Write "<input type=hidden name=""TITRE"" value=""" & strTitre & """>" & VbCrlf
		Response.Write "<input type=hidden name=""VALDEF"" value=""" & strValDef & """>" & VbCrlf
		Response.Write "<input type=hidden name=""FIRSTREC"" value=""" & lngFirstRec + Application("intTabLigMax") & """>" & VbCrlf
		Response.Write "<input type=hidden name=""SQL"" value=""" & strSQL & """>" & VbCrlf
		Response.Write "<input type=hidden name=""ENTETE"" value=""" & strEntete & """>" & VbCrlf
	end if

	Response.Write "</td></form>" & VbCrlf
	Response.Write "</tr>" & VbCrlf

	Response.Write "</table>" & VbCrlf
	Response.Write "</center>" & VbCrlf

End Sub



'################################################
'# Présente les Entetes de table                #
'################################################
Sub PresTabEntete(strColName(), CouleurEntete) 

	dim i

	Response.Write "<tr valign=top align=center " & CouleurEntete & ">" & VbCrlf
	Response.Write "<td>&nbsp;</td>" & VbCrlf

	For i = 1 to Ubound(strColName)
		if strColName(i) <> "" then
			Response.Write "<td><font color=#ffffff><b>" & strColName(i) & "</b></font></td>" & VbCrlf
		end if
	Next

	Response.Write "<td>&nbsp;</td><td>&nbsp;</td>" & VbCrlf
	Response.Write "</tr>" & VbCrlf & VbCrlf

End Sub



'################################################
'# Parse les champs Entete                      #
'################################################
Sub Parse(strEntete, strColName(), intColSize(), strValDef, varValDef())

	dim posComa, posSlash, posEgal, strTrav

	Redim strColName(0)
	Redim intColSize(0)

	strTrav = strEntete
	posComa = instr(strTrav, ",")

	while posComa > 0
		if posComa = 1 then
			Redim Preserve strColName(Ubound(strColName) + 1)
			strColName(Ubound(strColName)) = ""

			Redim Preserve intColSize(Ubound(intColSize) + 1)
			intColSize(Ubound(intColSize)) = 0
		else
			posSlash = instr(strTrav, "/")

			if posSlash < posComa then
				Redim Preserve strColName(Ubound(strColName) + 1)
				strColName(Ubound(strColName)) = Left(strTrav, (posSlash - 1))

				Redim Preserve intColSize(Ubound(intColSize) + 1)
				intColSize(Ubound(intColSize)) = CInt(Mid(strTrav, (posSlash + 1), (posComa - posSlash - 1)))
			end if
		end if

		if posComa = Len(strTrav) then
			strTrav = " "
		else
			strTrav = mid(strTrav, posComa + 1)
		end if

		posComa = instr(strTrav, ",")
	wend

	Redim varValDef(2, 0)

	strTrav = strValDef
	posComa = instr(strTrav, ",")

	while posComa > 0
		posEgal = instr(strTrav, "=")

		if posEgal < posComa then
			Redim Preserve varValDef(2, Ubound(varValDef, 2) + 1)
			varValDef(1, Ubound(varValDef, 2)) = Left(strTrav, (posEgal - 1))
			varValDef(2, Ubound(varValDef, 2)) = Mid(strTrav, (posEgal + 1), (posComa - posEgal - 1))
		end if

		if posComa = Len(strTrav) then
			strTrav = " "
		else
			strTrav = mid(strTrav, posComa + 1)
		end if

		posComa = instr(strTrav, ",")
	wend
End Sub



'################################################
'# Ajoute un Item                               #
'################################################
Sub AddItem(strSQL, varValDef())

	dim i, j, rsTabAdd, varValeur

	Set rsTabAdd = Server.CreateObject("ADODB.Recordset")
	rsTabAdd.Open strSQL, conConnexion, 2, 2

	rsTabAdd.AddNew

'--- En cas d'ajout sur NumAuto
On Error Resume Next
	rsTabAdd(0) = Request("ID")
On Error Goto 0

	for i = 1 to rsTabAdd.Fields.Count - 1
		varValeur = Request(rsTabAdd(i).name)
		varValeur = Trim(varValeur)

		for j = 1 to UBound(varValDef, 2)
			if UCase(rsTabAdd(i).name) = UCase(varValDef(1, j)) then

				if varValeur = "" or IsNull(varValeur) then 
					varValeur = varValDef(2, j)
				end if
			end if
		next

'--- En cas d'ajout Alpha sur Num
On Error Resume Next
	
	if varValeur<>"" then
		rsTabAdd(i) = varValeur
	end if

	if err = 80020005 then
		rsTabAdd(i) = Null
	end if
On Error Goto 0

	next

	rsTabAdd.Update

	rsTabAdd.Close
	Set rsTabAdd = Nothing

End Sub



'################################################
'# Modifie un Item                              #
'################################################
Sub UpdateItem(strSQL, varValDef())

	dim i, j, rsTabUp, bolTrouve, varValeur

	Set rsTabUp = Server.CreateObject("ADODB.Recordset")
	rsTabUp.Open strSQL, conConnexion, 2, 2

	do while not rsTabUp.EOF
		if CStr(rsTabUp(0)) = CStr(Request("ID")) then Exit Do
		rsTabUp.MoveNext
	loop

	if not rsTabUp.EOF then

'--- En cas d'ajout sur NumAuto
On Error Resume Next
		rsTabUp(0) = Request("ID")
On Error Goto 0

		for i = 1 to rsTabUp.Fields.Count - 1
			varValeur = Request(rsTabUp(i).name)
			varValeur = Trim(varValeur)

			for j = 1 to UBound(varValDef, 2)
				if UCase(rsTabUp(i).name) = UCase(varValDef(1, j)) then
					if varValeur = "" or IsNull(varValeur) then varValeur = varValDef(2, j)
				end if
			next
			if varValeur = "" then varValeur = Null

'--- Autres cas
On Error Resume Next
			rsTabUp(i) = varValeur
On Error Goto 0

		next

		rsTabUp.Update
	end if

	rsTabUp.Close
	Set rsTabUp = Nothing

End Sub



'################################################
'# Supprime un Item                             #
'################################################
Sub DelItem(strSQL)

	dim rsTabDel, bolTrouve

	Set rsTabDel = Server.CreateObject("ADODB.Recordset")
	rsTabDel.Open strSQL, conConnexion, 2, 2

	do while not rsTabDel.EOF
		if CStr(rsTabDel(0)) = CStr(Request("ID")) then Exit Do
		rsTabDel.MoveNext
	loop

	if not rsTabDel.EOF then
		rsTabDel.Delete
	end if

	rsTabDel.Close
	Set rsTabDel = Nothing

End Sub


</SCRIPT>


