<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->

<%
dim strSvrName
strSvrName = Request.ServerVariables("SERVER_NAME")
Response.AddHeader "content-disposition","inline; attachment; filename=" & chr(34) & strSvrName & ".xls" & chr(34)
Response.ContentType = "application/vnd.ms-excel"%>ID;PWXL;N;E
P;PGeneral
P;P0
P;P0.00
P;P#,##0
P;P#,##0.00
P;P#,##0;;\-#,##0
P;P#,##0;;[Red]\-#,##0
P;P#,##0.00;;\-#,##0.00
P;P#,##0.00;;[Red]\-#,##0.00
P;P"$"#,##0;;\-"$"#,##0
P;P"$"#,##0;;[Red]\-"$"#,##0
P;P"$"#,##0.00;;\-"$"#,##0.00
P;P"$"#,##0.00;;[Red]\-"$"#,##0.00
P;P0%
P;P0.00%
P;P0.00E+00
P;P##0.0E+0
P;P#" "?/?
P;P#" "??/??
P;Pdd/mm/yy
P;Pdd\-mmm\-yy
P;Pdd\-mmm
P;Pmmm\-yy
P;Ph:mm\ AM/PM
P;Ph:mm:ss\ AM/PM
P;Phh:mm
P;Phh:mm:ss
P;Pdd/mm/yy\ hh:mm
P;Pmm:ss
P;Pmm:ss.0
P;P@
P;P[h]:mm:ss
P;P_-"$"* #,##0_-;;\-"$"* #,##0_-;;_-"$"* "-"_-;;_-@_-
P;P_-* #,##0_-;;\-* #,##0_-;;_-* "-"_-;;_-@_-
P;P_-"$"* #,##0.00_-;;\-"$"* #,##0.00_-;;_-"$"* "-"??_-;;_-@_-
P;P_-* #,##0.00_-;;\-* #,##0.00_-;;_-* "-"??_-;;_-@_-
P;P"Yes";;"Yes";;"No"
P;P"True";;"True";;"False"
P;P"On";;"On";;"Off"
P;FArial;M200
P;FArial;M200
P;FArial;M200
P;FArial;M200
P;EVerdana;M160;L9
P;EArial;M160
F;P0;DG0G8;SM6;M225
B;Y268;X12;D0 1 267 11
O;L;D;V0;K47;G100 0.001
F;W1 1 1
F;W2 2 20
F;W3 3 1
F;W4 4 20
F;W5 5 1
F;W6 6 20
F;W7 7 1
F;W8 8 20
F;W9 9 1
F;W10 10 20
F;W11 11 1
F;W12 12 20
F;W13 13 1
F;W14 14 20
F;W15 15 1
F;W16 16 20
F;W17 17 1
F;W18 18 20
F;W19 19 1
F;W20 20 20
<%
dim lngID, i, j, intWork, intWork2, intCols, intRows, intTop, intBot
dim ParamTable
public tabID(), tabNom(), tabDate(), tabArbre()

redim tabID(1)

if Request("IDPerso") = Empty then
	tabID(1) = 1
else
	tabID(1) = Request("IDPerso")
end if

strSQL = "SELECT * FROM Personne WHERE IDPersonne=" & tabID(1)
rs0.Open strSQL, conConnexion

if not rs0.EOF then

	redim tabNom(1)
	tabNom(1) = rs0("Prenom") & " " & rs0("Nom")
	redim tabDate(1)
	tabDate(1) = "(" & rs0("DtNaiss") & "-" & rs0("DtDec") & ")"

	SetStructureUP 

	intRows = 0
	intCols = 0
	intWork = Ubound(tabID) - 1
	while intWork > 1
		intWork = intWork / 2
		if intRows = 0 then intRows = intWork
		intCols = intCols + 1
	wend
	intCols = intCols - 1
	intRows = intRows - int(intRows / 2)

	redim tabArbre(intCols, intRows * 2)

	for i = 1 to intCols
		intWork = 2^(intCols - i)
		for j = intWork to intWork * 2 - 1
			intWork2 = (j - intWork + 1) * 2^(i-1) - 2^(i-1) + 1
			tabArbre(i, intWork2 * 2 - 1) = tabNom(j)
			tabArbre(i, intWork2 * 2) = tabDate(j)
		next
	next 

	for i = 1 to intRows * 2
		for j = 1 to intCols
			if tabArbre(j, i) <> "" then
				Response.Write "C;Y" & i & ";X" & j * 2 & ";K""" & tabArbre(j, i) & """" & vbCrlf
			end if
		next
	next 

end if

Response.Write "E" & vbCrlf
%>

<!--#include VIRTUAL="/Include/DAOFooter.asp"-->

<%
'*******************************************************************************************************************************
' Sub Routines 
'*******************************************************************************************************************************

Sub SetStructureUP() 'Find Initial Couple/Person's parents

	Dim rsRec, posInStack, flgLastGen, flgNewGen 
	Set rsRec = Server.CreateObject("ADODB.Recordset")

	posInStack = 1
	flgLastGen = true
	flgNewGen = true

	while flgLastGen
		select case UBound(tabID)
			case 3, 7, 15, 31, 63, 127, 255, 511, 1023, 2047, 4095, 8191, 16383
				flgLastGen = flgNewGen
				flgNewGen = false
		end select

		strSQL = "SELECT Personne_1.* " & _
				 "FROM Personne AS Personne_1, Personne INNER JOIN Couple ON Personne.IDCouple = Couple.IDCouple " & _
				 "WHERE (Personne_1.IDPersonne=IDPersMasc OR Personne_1.IDPersonne=IDPersFem) AND Personne.IDPersonne=" & tabID(posInStack) & _
				 " ORDER BY Personne_1.IsMasc;"
		rsRec.Open strSQL, conConnexion
		
		if not rsRec.EOF then
			flgNewGen = true

			redim preserve tabID(UBound(tabID) + 2)
			redim preserve tabNom(UBound(tabNom) + 2)
			redim preserve tabDate(UBound(tabDate) + 2)

			tabID(UBound(tabID) - 1) = rsRec("IDPersonne")
			tabNom(UBound(tabNom) - 1) = rsRec("Prenom") & " " & rsRec("Nom")
			tabDate(UBound(tabDate) - 1) = "(" & rsRec("DtNaiss") & "-" & rsRec("DtDec") & ")"

			rsRec.MoveNext

			tabID(UBound(tabID) - 0) = rsRec("IDPersonne")
			tabNom(UBound(tabNom) - 0) = rsRec("Prenom") & " " & rsRec("Nom")
			tabDate(UBound(tabDate) - 0) = "(" & rsRec("DtNaiss") & "-" & rsRec("DtDec") & ")"
		else
			redim preserve tabID(UBound(tabID) + 2)
			redim preserve tabNom(UBound(tabNom) + 2)
			redim preserve tabDate(UBound(tabDate) + 2)

			tabID(UBound(tabID) - 1) = 0
			tabNom(UBound(tabNom) - 1) = "? ?"
			tabDate(UBound(tabDate) - 1) = "(?-?)"

			tabID(UBound(tabID) - 0) = 0
			tabNom(UBound(tabNom) - 0) = "? ?"
			tabDate(UBound(tabDate) - 0) = "(?-?)"
		end if

		rsRec.Close
		posInStack = posInStack + 1
	wend

End Sub

%>