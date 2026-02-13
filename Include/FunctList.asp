<SCRIPT LANGUAGE="VBSCRIPT" RUNAT="SERVER">

Function PrintIndent(strKey)
	Dim i, Reponse 

	For i = 2 to Len(strKey)
		Reponse = Reponse & "."
	Next

	PrintIndent = Reponse

End Function


Sub SurDeplie(pClefTri, pID, pType, pNomChamp, pTrait, estTerm, estPrem, strPresentation)

	response.Write "<tr>" & VbCrlf
	response.Write "<td valign=top width=30>" & PrintIndent(pClefTri) & "<a href=saisMonoHier.asp?IDList=" & pID & ">"
	response.Write Application("Moins") & "</a></td>" & VbCrlf
	
	response.Write "<td valign=top><font face=helvetica size=1>"
	if strPresentation <> "" then
		response.Write "<" & strPresentation & ">" & pNomChamp & "</" & strPresentation & ">"
	else
		response.Write pNomChamp
	end if
	response.Write "</font></td>" & VbCrlf
	
	response.Write "<td>"

	if estTerm and isnull(pTrait) then
		pTrait = EtatChampsFils(pClefTri)
	end if

	Select Case UCase(pTrait)
		Case "NEW"
			if estPrem then
				response.Write "<A HREF=saisMonoItem.asp?IDITEM=" & pID & " target=mono>"
			else
				response.Write "<A HREF=saisMonoFrame.asp?IDITEM=" & pID & " target=mono>"
			end if
			response.Write Application("Vert") & "</A>"

		Case "WORK"
			if estPrem then
				response.Write "<A HREF=saisMonoItem.asp?IDITEM=" & pID & " target=mono>"
			else
				response.Write "<A HREF=saisMonoFrame.asp?IDITEM=" & pID & " target=mono>"
			end if
			response.Write Application("Orange") & "</A>"

		Case "VALID"
			if estPrem then
				response.Write "<A HREF=saisMonoItem.asp?IDITEM=" & pID & " target=mono>"
			else
				response.Write "<A HREF=saisMonoFrame.asp?IDITEM=" & pID & " target=mono>"
			end if
			response.Write Application("Rouge") & "</A>"

	End Select
		
	response.Write "</td>" & VbCrlf & "</tr>" & VbCrlf & VbCrlf

End Sub


Sub SurPasDeplie(pClefTri, pID, pType, pNomChamp, pTrait, estTerm, estPrem, strPresentation)
	
	If estTerm Then
		response.Write "<tr valign=top>" & VbCrlf 
		response.Write "<td width=30>" & PrintIndent(pClefTri) & Application("Gris") & "</td>" & VbCrlf
		response.Write "<td><font face=helvetica size=1>"

		response.Write pNomChamp & "</font></td>" & VbCrlf & "<td>"
		
		if isnull(pTrait) then
			pTrait = EtatChampsFils(pClefTri)
		end if

		Select Case ucase(pTrait)
			Case "NEW"
				if estPrem then
					response.Write "<A HREF=saisMonoItem.asp?IDITEM=" & pID & " target=mono>"
				else
					response.Write "<A HREF=saisMonoFrame.asp?IDITEM=" & pID & " target=mono>" 
				end if
				response.Write Application("Vert") & "</A>"

			Case "WORK"
				if estPrem then
					response.Write "<A HREF=saisMonoItem.asp?IDITEM=" & pID & " target=mono>"
				else
					response.Write "<A HREF=saisMonoFrame.asp?IDITEM=" & pID & " target=mono>"
				end if
				response.Write Application("Orange") & "</A>"

			Case "VALID"
				if estPrem then
					response.Write "<A HREF=saisMonoItem.asp?IDITEM=" & pID & " target=mono>"
				else
					response.Write "<A HREF=saisMonoFrame.asp?IDITEM=" & pID & " target=mono>" 
				end if
				response.Write Application("Rouge") & "</A>"
		End Select

		response.Write "</td>" & VbCrlf & "</tr>" & VbCrlf & VbCrlf

	Else

		response.Write "<tr>" & VbCrlf & "<td width=30>" & PrintIndent( pClefTri )
		response.Write "<a href=saisMonoHier.asp?IDList=" & pID & ">" &  Application("Plus")
		response.Write "</a></td>" & VbCrlf & "<td valign=top><font face=helvetica size=1>"

		response.Write pNomChamp & "</font></td>" & VbCrlf & "<td>"
		
		Select Case ucase(pTrait)
			Case "ISNEW"
				if estPrem then
					response.Write "<A HREF=saisMonoItem.asp?IDITEM=" & pID & " target=mono>"
				else
					response.Write "<A HREF=saisMonoFrame.asp?IDITEM=" & pID & " target=mono>"
				end if
				response.Write Application("Vert") & "</A>"

			Case "WORK"
				if estPrem then
					response.Write "<A HREF=saisMonoItem.asp?IDITEM=" & pID & " target=mono>"
				else
					response.Write "<A HREF=saisMonoFrame.asp?IDITEM=" & pID & " target=mono>"
				end if
				response.Write Application("Orange") & "</A>"

			Case "VALID"
				if estPrem then
					response.Write "<A HREF=saisMonoItem.asp?IDITEM=" & pID & " target=mono>"
				else
					response.Write "<A HREF=saisMonoFrame.asp?IDITEM=" & pID & " target=mono>"
				end if
				response.Write Application("Rouge") & "</A>"
		End Select

		response.Write "</td>" & VbCrlf & "</tr>" & VbCrlf & VbCrlf

	End If

End Sub


Function EtatChampsFils(strCodeTri)

	Dim rsEtat, intCptNew, intCptWork, intCptValid

	Set rsEtat = Server.CreateObject("ADODB.Recordset")

	strSQL = "SELECT Mono.Trait, StructMono.EstBreak " & _
			 "FROM Mono INNER JOIN StructMono ON Mono.IdStructMono = StructMono.IDStructMono " & _
			 "WHERE Mono.Annee=" & Session("Annee") & " AND Mono.IdPays='" & Session("IDPays") & "' AND StructMono.CodeTri Like '" & strCodeTri & "%' AND StructMono.CodeTri<>'" & strCodeTri & "' " & _
			 "ORDER BY Mono.Trait"
	rsEtat.Open strSQL, conConnexion, 2, 2

	intCptNew = 0
	intCptWork = 0
	intCptValid = 0

	do while not rsEtat.EOF
		if rsEtat("EstBreak") then Exit Do
		
		Select Case UCase(rsEtat("Trait"))
			Case "NEW"
				intCptNew = intCptNew + 1
			Case "WORK"
				intCptWork = intCptWork + 1
			Case "VALID"
				intCptValid = intCptValid + 1
		End Select

		rsEtat.MoveNext
	loop
	rsEtat.Close
	Set rsEtat = Nothing

	
	if intCptNew + intCptWork + intCptValid = 0 then
		EtatChampsFils = ""
	
	elseif intCptNew + intCptWork = 0 then
		EtatChampsFils = "Valid"
	
	elseif intCptWork + intCptValid = 0 then
		EtatChampsFils = "New"
	
	else
		EtatChampsFils = "Work"
	end if

End Function

</SCRIPT>
