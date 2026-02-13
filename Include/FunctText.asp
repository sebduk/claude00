<SCRIPT LANGUAGE="VBSCRIPT" RUNAT="SERVER">

'################################################
'# Remplace les Tags Propriétaires en Tags HTML #
'################################################
Function ReplaceTags(strText)

	Dim MarqDeb1, MarqDeb2, MarqFin1, MarqFin2, Tag
	Dim PosMarqDeb1, PosMarqDeb2, PosMarqFin1, PosMarqFin2
	Dim MarqTab, MarqTabBord, MarqGras, MarqSSL, MarqItal, MarqBlc, MarqLig, MarqExp, MarqInd, MarqPuce
	Dim strTrav1, strTrav2, strTrav2Mid, posDeb

	MarqDeb1 = "~"
	MarqDeb2 = "~"
	MarqFin1 = "~/"
	MarqFin2 = "~"

	MarqTab = "t"
	MarqTabBord = "tx"
	MarqGras = "g"
	MarqSSL = "s"
	MarqItal = "i"
	MarqBlc = "blc"
	MarqLig = "lig"
	MarqExp = "exp"
	MarqInd = "ind"
	MarqPuce = "*"


	strTrav1 = strText
	strTrav2 = ""
	PosDeb = 1
						'*Cherche le premier Début de Tag*
						'*********************************
	PosMarqDeb1 = InStr( PosDeb, strTrav1, MarqDeb1 )

						'*Boucle jusqu'à plus de Tags à traiter*
						'***************************************
	while PosMarqDeb1 <> 0				' AND PosMarqDeb1 <> "" AND not IsNull(PosMarqDeb1)

						'*Cherche le complément du Tag*
						'******************************
		PosMarqDeb2 = InStr( PosMarqDeb1 + 1, strTrav1, MarqDeb2 )

		Tag = Mid( strTrav1, PosMarqDeb1, PosMarqDeb2 - PosMarqDeb1 + 1 ) 

		Select Case Tag
												'Tableau sans bordure
												''''''''''''''''''''''''
			Case MarqDeb1 & MarqTab & MarqDeb2
				PosMarqFin1 = InStr( PosMarqDeb2 + 1, strTrav1, MarqFin1 & MarqTab & MarqFin2)
				PosMarqFin2 = PosMarqFin1 + Len(MarqFin1 & MarqTab & MarqFin2) - 1
				if PosMarqFin1 <> 0 then
					strTrav2 = left( strTrav1, PosMarqDeb1 - 1 ) & "<TABLE border=0><TR valign=top><TD>"
					strTrav2Mid = mid( strTrav1, PosMarqDeb2 + 1, PosMarqFin1 - PosMarqDeb2 - 1 ) 
					strTrav2Mid = replace ( strTrav2Mid, VbTab, "</TD><TD>" )
					strTrav2Mid = replace ( strTrav2Mid, VbCrlf, "</TD></TR><TR valign=top><TD>" )
					strTrav2 = strTrav2 & strTrav2Mid & "</TD></TR></TABLE>" & mid( strTrav1, PosMarqFin2 + 1 )
				else
					strTrav2 = left( strTrav1, PosMarqDeb1 - 1 ) 
					strTrav2 = strTrav2 & mid( strTrav1, PosMarqDeb2 + 1 )
				end if

												'Tableau avec bordure
												''''''''''''''''''''''''
			Case MarqDeb1 & MarqTabBord & MarqDeb2
				PosMarqFin1 = InStr( PosMarqDeb2 + 1, strTrav1, MarqFin1 & MarqTabBord & MarqFin2)
				PosMarqFin2 = PosMarqFin1 + Len(MarqFin1 & MarqTabBord & MarqFin2) - 1
				if PosMarqFin1 <> 0 then
					strTrav2 = left( strTrav1, PosMarqDeb1 - 1 ) & "<TABLE border=1><TR valign=top><TD>"
					strTrav2Mid = mid( strTrav1, PosMarqDeb2 + 1, PosMarqFin1 - PosMarqDeb2 - 1 ) 
					strTrav2Mid = replace ( strTrav2Mid, VbTab, "</TD><TD>" )
					strTrav2Mid = replace ( strTrav2Mid, VbCrlf, "</TD></TR><TR valign=top><TD>" )
					strTrav2 = strTrav2 & strTrav2Mid & "</TD></TR></TABLE>" & mid( strTrav1, PosMarqFin2 + 1 )
				else
					strTrav2 = left( strTrav1, PosMarqDeb1 - 1 ) 
					strTrav2 = strTrav2 & mid( strTrav1, PosMarqDeb2 + 1 )
				end if

												'Gras
												''''''''''''''''''''''''
			Case MarqDeb1 & MarqGras & MarqDeb2
				PosMarqFin1 = InStr( PosMarqDeb2 + 1, strTrav1, MarqFin1 & MarqGras & MarqFin2)
				PosMarqFin2 = PosMarqFin1 + Len(MarqFin1 & MarqGras & MarqFin2) - 1
				if PosMarqFin1 <> 0 then
					strTrav2 = left( strTrav1, PosMarqDeb1 - 1 ) & "<B>"
					strTrav2 = strTrav2 & mid( strTrav1, PosMarqDeb2 + 1, PosMarqFin1 - PosMarqDeb2 - 1 ) & "</B>"
					strTrav2 = strTrav2 & mid( strTrav1, PosMarqFin2 + 1 )
				else
					strTrav2 = left( strTrav1, PosMarqDeb1 - 1 ) 
					strTrav2 = strTrav2 & mid( strTrav1, PosMarqDeb2 + 1 )
				end if

												'Italique
												''''''''''''''''''''''''
			Case MarqDeb1 & MarqItal & MarqDeb2
				PosMarqFin1 = InStr( PosMarqDeb2 + 1, strTrav1, MarqFin1 & MarqItal & MarqFin2)
				PosMarqFin2 = PosMarqFin1 + Len(MarqFin1 & MarqItal & MarqFin2) - 1
				if PosMarqFin1 <> 0 then
					strTrav2 = left( strTrav1, PosMarqDeb1 - 1 ) & "<I>"
					strTrav2 = strTrav2 & mid( strTrav1, PosMarqDeb2 + 1, PosMarqFin1 - PosMarqDeb2 - 1 ) & "</I>"
					strTrav2 = strTrav2 & mid( strTrav1, PosMarqFin2 + 1 )
				else
					strTrav2 = left( strTrav1, PosMarqDeb1 - 1 ) 
					strTrav2 = strTrav2 & mid( strTrav1, PosMarqDeb2 + 1 )
				end if

												'Sousligné
												''''''''''''''''''''''''
			Case MarqDeb1 & MarqSSL & MarqDeb2
				PosMarqFin1 = InStr( PosMarqDeb2 + 1, strTrav1, MarqFin1 & MarqSSL & MarqFin2)
				PosMarqFin2 = PosMarqFin1 + Len(MarqFin1 & MarqSSL & MarqFin2) - 1
				if PosMarqFin1 <> 0 then
					strTrav2 = left( strTrav1, PosMarqDeb1 - 1 ) & "<U>"
					strTrav2 = strTrav2 & mid( strTrav1, PosMarqDeb2 + 1, PosMarqFin1 - PosMarqDeb2 - 1 ) & "</U>"
					strTrav2 = strTrav2 & mid( strTrav1, PosMarqFin2 + 1 )
				else
					strTrav2 = left( strTrav1, PosMarqDeb1 - 1 ) 
					strTrav2 = strTrav2 & mid( strTrav1, PosMarqDeb2 + 1 )
				end if

												'Exposant
												''''''''''''''''''''''''
			Case MarqDeb1 & MarqExp & MarqDeb2
				PosMarqFin1 = InStr( PosMarqDeb2 + 1, strTrav1, MarqFin1 & MarqExp & MarqFin2)
				PosMarqFin2 = PosMarqFin1 + Len(MarqFin1 & MarqExp & MarqFin2) - 1
				if PosMarqFin1 <> 0 then
					strTrav2 = left( strTrav1, PosMarqDeb1 - 1 ) & "<SUP>"
					strTrav2 = strTrav2 & mid( strTrav1, PosMarqDeb2 + 1, PosMarqFin1 - PosMarqDeb2 - 1 ) & "</SUP>"
					strTrav2 = strTrav2 & mid( strTrav1, PosMarqFin2 + 1 )
				else
					strTrav2 = left( strTrav1, PosMarqDeb1 - 1 ) 
					strTrav2 = strTrav2 & mid( strTrav1, PosMarqDeb2 + 1 )
				end if

												'Indice
												''''''''''''''''''''''''
			Case MarqDeb1 & MarqSSL & MarqDeb2
				PosMarqFin1 = InStr( PosMarqDeb2 + 1, strTrav1, MarqFin1 & MarqInd & MarqFin2)
				PosMarqFin2 = PosMarqFin1 + Len(MarqFin1 & MarqInd & MarqFin2) - 1
				if PosMarqFin1 <> 0 then
					strTrav2 = left( strTrav1, PosMarqDeb1 - 1 ) & "<SUB>"
					strTrav2 = strTrav2 & mid( strTrav1, PosMarqDeb2 + 1, PosMarqFin1 - PosMarqDeb2 - 1 ) & "</SUB>"
					strTrav2 = strTrav2 & mid( strTrav1, PosMarqFin2 + 1 )
				else
					strTrav2 = left( strText, PosMarqDeb1 - 1 ) 
					strTrav2 = strTrav2 & mid( strTrav1, PosMarqDeb2 + 1 )
				end if

												'Blanc inséccable
												''''''''''''''''''''''''
			Case MarqDeb1 & MarqBlc & MarqDeb2
				strTrav2 = left( strTrav1, PosMarqDeb1 - 1 ) & "&nbsp;"
				strTrav2 = strTrav2 & mid( strTrav1, PosMarqDeb2 + 1 )

												'Saut de Ligne
												''''''''''''''''''''''''
			Case MarqDeb1 & MarqLig & MarqDeb2
				strTrav2 = left( strTrav1, PosMarqDeb1 - 1 ) & "<BR>"
				strTrav2 = strTrav2 & mid( strTrav1, PosMarqDeb2 + 1 )

												'Puce
												''''''''''''''''''''''''
			Case MarqDeb1 & MarqPuce & MarqDeb2
				strTrav2 = left( strTrav1, PosMarqDeb1 - 1 ) & Application("Puce")
				strTrav2 = strTrav2 & mid( strTrav1, PosMarqDeb2 + 1 )

												'Tag Erroné ou sans Début|Fin
												''''''''''''''''''''''''
			Case Else
				strTrav2 = left( strTrav1, PosMarqDeb1 - 1 ) & mid( strTrav1, PosMarqDeb2 + 1 )

		End Select

		strTrav1 = strTrav2

		strTrav2 = ""
		PosDeb = 1
		PosMarqDeb1 = InStr( PosDeb, strTrav1, MarqDeb1 )
	wend

	if Len(strTrav1) > 0 then
		strTrav1 = Replace(strTrav1, VbCrlf, "<BR>")
		strTrav1 = Replace(strTrav1, VbTab, "<DD>")

		strTrav1 = AccentsEnHTML(strTrav1)
	end if

	ReplaceTags = strTrav1

End Function

Function AccentsEnHTML(strTexte)
	strTexte = Replace(strTexte, "à", "&agrave;")
	strTexte = Replace(strTexte, "â", "&acirc;")
	strTexte = Replace(strTexte, "ä", "&auml;")

	strTexte = Replace(strTexte, "ae", "&aelig;")

	strTexte = Replace(strTexte, "é", "&eacute;")
	strTexte = Replace(strTexte, "è", "&egrave;")
	strTexte = Replace(strTexte, "ê", "&ecirc;")
	strTexte = Replace(strTexte, "ë", "&euml;")

	strTexte = Replace(strTexte, "oe", "&oelig;")

	strTexte = Replace(strTexte, "î", "&icirc;")
	strTexte = Replace(strTexte, "ï", "&iuml;")

	strTexte = Replace(strTexte, "ô", "&ocirc;")

	strTexte = Replace(strTexte, "ù", "&ugrave;")
	strTexte = Replace(strTexte, "û", "&ucirc;")
	
	AccentsEnHTML = strTexte
End Function

'################################################
'# Découpe les Lignes pour Netscape             #
'################################################
Function LineSlicer(strText, intLength)

	dim strWork, i

	while Len(strText) >= intLength
		i = intLength

		do While i > 0
			if mid(strText, i, 1) = " " then Exit Do
			i = i - 1
		loop
		
		if i > 0 then 
			strWork = strWork & left(strText, i - 1) & vbCrLf
			strText = right(strText, len(strText) - i)
		else
			strWork = strWork & left(strText, intLength) & vbCrLf
			strText = right(strText, len(strText) - intLength)
		end if

	wend

	LineSlicer = strWork

End Function


'################################################
'# Retire les Tabs d'un texte                   #
'################################################
Function RemoveTab(strText)

	if not IsNull(strText) then 
		strText = replace(strText, vbTab, " ")
	end if

	RemoveTab = strText

End Function


'################################################
'# Revoie une indentation                       #
'#  à placer devant un texte                    #
'################################################
Function PrintItemTextIndent(strKey)

	Dim i, Reponse 

	For i = 2 to Len(strKey)
		Reponse = Reponse & "&nbsp;&nbsp;&nbsp;"
	Next

	PrintItemTextIndent = Reponse

End Function


'################################################
'# Après Tiret                                  #
'################################################
Function ApresTiret(strText)

	if InStr(strText, "-") <> 0 then
		ApresTiret = Mid(strText, InStr(strText, "-") + 1)
	else
		ApresTiret = strText
	end if

End Function

</SCRIPT>
