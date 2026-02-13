<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
dim lngID, i, j, intWork, intWork2, intCols, intRows, intTop, intBot
dim ParamTable, flgColRight
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
	tabNom(1) = replace(server.HTMLEncode(rs0("Prenom") & " " & rs0("Nom")), " ", "&nbsp;")
	redim tabDate(1)
	tabDate(1) = "(" & rs0("DtNaiss") & "-" & rs0("DtDec") & ")"

	SetStructureUP 

	intRows = 0
	intCols = 0
	intWork = Ubound(tabID) - 1
	while intWork > 1
		intWork = intWork / 2
		if intCols = 0 then intCols = intWork
		intRows = intRows + 1
	wend
	intRows = intRows - 1
	intCols = intCols - int(intCols / 2)

	redim tabArbre(intRows, intCols * 2)

	for i = 1 to intRows
		intWork = 2^(intRows - i)
		for j = intWork to intWork * 2 - 1
			intWork2 = (j - intWork + 1) * 2^(i-1) - 2^(i-1) + 1
			tabArbre(i, intWork2 * 2 - 1) = tabNom(j)
			tabArbre(i, intWork2 * 2) = tabDate(j)
		next
	next 

	
	intWork = 150 * intCols
	ParamTable = "<table border=0 cellpadding=5 cellspacing=0 width=" & intWork & " align=center>"
	flgColRight = true

	Response.Write ParamTable & VbCrlf
	for i = 1 to intRows
		Response.Write "<tr>" & VbCrlf
		for j = 1 to intCols * 2 step 2
			if tabArbre(i, j) <> "" then
				Response.Write "<td "

				if i = intRows then
					Response.Write "align=center "
				else
					if flgColRight then
						Response.Write "align=right "
						flgColRight = false
					else
						flgColRight = true
					end if				
				end if

				if i = 1 then 
					Response.Write "width=150"
				else
					Response.Write "colspan=" & 2^(i-1)
				end if
				
				Response.Write "><hr size=1 noshade>" & tabArbre(i, j) & "<br>" & tabArbre(i, j + 1) & "</td>" & VbCrlf
			end if
		next
		Response.Write "</tr>" & VbCrlf
	next 
	Response.Write "</table>" & VbCrlf

end if


%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->
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
			tabNom(UBound(tabNom) - 1) = replace(server.HTMLEncode(rsRec("Prenom") & " " & rsRec("Nom")), " ", "&nbsp;")
			tabDate(UBound(tabDate) - 1) = "(" & rsRec("DtNaiss") & "-" & rsRec("DtDec") & ")"

			rsRec.MoveNext

			tabID(UBound(tabID) - 0) = rsRec("IDPersonne")
			tabNom(UBound(tabNom) - 0) = replace(server.HTMLEncode(rsRec("Prenom") & " " & rsRec("Nom")), " ", "&nbsp;")
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