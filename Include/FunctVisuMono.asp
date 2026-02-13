<SCRIPT LANGUAGE="VBSCRIPT" RUNAT="SERVER">

'################################################
'# Recherche dans un Tableau en mémoire une valeur données et renvoi le numéro de rang
'################################################
Function TrouveID(lngID, lngTabID())
	Dim i

	i = 1
	Do While i <= Ubound(lngTabID)
		If lngTabID(i) = lngID Then Exit Do
		i = i + 1
	Loop

	If i <= Ubound(lngTabID) Then
		TrouveID = i
	Else
		TrouveID = 0
	End If

End Function

Function VisuReplaceTags(strTexte)

	if strTexte <> "" then
		VisuReplaceTags = ReplaceTags(strTexte)
	else
		VisuReplaceTags = "<font color=red>Champ vide</font>"
	end if

End Function

'################################################
'# Affiche l'entête des tableaux                #
'################################################
Sub VisuTableau()

	Response.Write "<table border=0 cellpadding=0 cellspacing=0>"
	'Response.Write "<tr><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>"

End Sub

'################################################
'# Affiche une ligne vierge                     #
'################################################
Sub VisuEspace()

	Response.Write "<tr><td colspan=4>&nbsp;</td></tr>"

End Sub

'################################################
'# Affiche les titres selon leur niveau         #
'################################################
Sub VisuTitre(intNiv, strIndex, strTitre, strAncre)

	Select Case intNiv
		Case 1
			Response.Write "<tr valign=top>" & VbCrlf
			Response.Write "<td colspan=4 align=center><h1><b>" & strIndex & "&nbsp;-&nbsp;" & strTitre & "</b></h1></td>" & VbCrlf
			Response.Write "</tr>" &VbCrlf

		Case 2
			Response.Write "<tr valign=top>" & VbCrlf
			Response.Write "<td><a name=""" & strAncre & """><h2><b><i>" & strIndex & ")</i></b>&nbsp;</h2></td>" & VbCrlf
			Response.Write "<td colspan=3><h2><b><i>" & strTitre & "</i></b></h2></td>" & VbCrlf
			Response.Write "</tr>" & VbCrlf

		Case 3
			Response.Write "<tr valign=top>" & VbCrlf
			Response.Write "<td></td>" & VbCrlf
			Response.Write "<td><h3><i>" & strIndex & ")</i>&nbsp;</h3></td>" & VbCrlf
			Response.Write "<td colspan=2><h3><i>" & strTitre & "</i></h3></td>" & VbCrlf
			Response.Write "</tr>" & VbCrlf

		Case 4
			Response.Write "<tr valign=top>" & VbCrlf
			Response.Write "<td colspan=2></td>" & VbCrlf
			Response.Write "<td>" & strIndex & ")&nbsp;</td>" & VbCrlf
			Response.Write "<td>" & strTitre & "<br>&nbsp;</td>" & VbCrlf
			Response.Write "</tr>" & VbCrlf

	End Select

End Sub

'################################################
'# Affiche les corps de texte selon leur niveau #
'################################################
Sub VisuCorps(intNiv, strTexte)

	Select Case intNiv
		Case 1
			Response.Write "<tr valign=top>" & VbCrlf
			Response.Write "<td colspan=4 align=justified>" & strTexte & "</td>" & VbCrlf
			Response.Write "</tr>" &VbCrlf

		Case 2
			Response.Write "<tr valign=top>" & VbCrlf
			Response.Write "<td></td>" & VbCrlf
			Response.Write "<td colspan=3 align=justified>" & strTexte & "</td>" & VbCrlf
			Response.Write "</tr>" &VbCrlf

		Case 3
			Response.Write "<tr valign=top>" & VbCrlf
			Response.Write "<td colspan=2></td>" & VbCrlf
			Response.Write "<td colspan=2 align=justified>" & strTexte & "</td>" & VbCrlf
			Response.Write "</tr>" &VbCrlf

		Case 4
			Response.Write "<tr valign=top>" & VbCrlf
			Response.Write "<td colspan=3></td>" & VbCrlf
			Response.Write "<td align=justified>" & strTexte & "</td>" & VbCrlf
			Response.Write "</tr>" &VbCrlf

	End Select

End Sub

'################################################
'# Affiche les entetes de corps de texte        #
'################################################
Sub VisuETCorps(intNiv)

	Select Case intNiv
		Case 1
			Response.Write "<tr valign=top>" & VbCrlf
			Response.Write "<td colspan=4 align=justified>"

		Case 2
			Response.Write "<tr valign=top>" & VbCrlf
			Response.Write "<td></td>" & VbCrlf
			Response.Write "<td colspan=3 align=justified>"

		Case 3
			Response.Write "<tr valign=top>" & VbCrlf
			Response.Write "<td colspan=2></td>" & VbCrlf
			Response.Write "<td colspan=2 align=justified>"

		Case 4
			Response.Write "<tr valign=top>" & VbCrlf
			Response.Write "<td colspan=3></td>" & VbCrlf
			Response.Write "<td align=justified>"

	End Select

End Sub

'################################################
'# Affiche les pieds corps de texte             #
'################################################
Sub VisuPDCorps()

	Response.Write "</td>" & VbCrlf
	Response.Write "</tr>" &VbCrlf

End Sub


</SCRIPT>
