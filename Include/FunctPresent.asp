<SCRIPT LANGUAGE="VBSCRIPT" RUNAT="SERVER">

Sub ShowLibelle(strName)
	Response.Write "<tr valign=top align=left>" & VbCrlf
	Response.Write "<td colspan=2><b>" & strName & "</b></td>" & VbCrlf
	Response.Write "</tr>" & VbCrlf & VbCrlf
End Sub


Sub ShowInputTxt(lngID, strName, strMemo)
	Dim strTrav

	strTrav = "<input type=text class=nohilite name=M" & lngID & " value=""" & strMemo & """ size=20>"

	Response.Write "<tr valign=top align=left>" & VbCrlf

	if InStr(strName, "<TXT>") > 0 then
		strName = Replace(strName, "<TXT>", strTrav)

		Response.Write "<td colspan=2>" & strName & "</td>" & VbCrlf
	else
		Response.Write "<td>" & strName & "</td><td>" & strTrav & "</td>" & VbCrlf
	end if

	Response.Write "</tr>" & VbCrlf & VbCrlf
End Sub


Sub ShowInputDat(lngID, strName, numNumerique)
	Dim strTrav

	if not IsNull(numNumerique) then numNumerique = FormatDateTime(numNumerique, 0)

	strTrav = "<input type=text class=nohilite name=D" & lngID & " value=""" & numNumerique & """ size=20>"

	Response.Write "<tr valign=top align=left>" & VbCrlf

	if InStr(strName, "<DAT>") > 0 then
		strName = Replace(strName, "<DAT>", strTrav)

		Response.Write "<td colspan=2>" & strName & "</td>" & VbCrlf
	else
		Response.Write "<td>" & strName & "</td><td>" & strTrav & "</td>" & VbCrlf
	end if

	Response.Write "</tr>" & VbCrlf & VbCrlf
End Sub


Sub ShowInputNum(lngID, strName, numNumerique)
	Dim strTrav

	strTrav = "<input type=text name=N" & lngID & " value=""" & numNumerique & """ size=15>"

	Response.Write "<tr valign=top align=left>" & VbCrlf

	if InStr(strName, "<NUM>") > 0 then
		strName = Replace(strName, "<NUM>", strTrav)

		Response.Write "<td colspan=2>" & strName & "</td><td>" & VbCrlf
	else
		Response.Write "<td>" & strName & "</td><td>" & strTrav & "</td>" & VbCrlf
	end if

	Response.Write "</tr>" & VbCrlf & VbCrlf
End Sub


Sub ShowInputBol(lngID, strName, bolBollean)
	Dim strTrav

	if bolBollean then
		strTrav = "<input type=hidden name=B" & lngID & " value=True><input type=Checkbox name=X" & lngID & " Checked Value=""X"">"
	else
		strTrav = "<input type=hidden name=B" & lngID & " value=False><input type=Checkbox name=X" & lngID & " Value=""X"">"
	end if

	Response.Write "<tr valign=top align=left>" & VbCrlf

	if InStr(strName, "<BOL>") > 0 then
		strName = Replace(strName, "<BOL>", strTrav)

		Response.Write "<td colspan=2>" & strName & "</td><td>" & VbCrlf
	else
		Response.Write "<td>" & strName & "</td><td>" & strTrav & "</td>" & VbCrlf
	end if

	Response.Write "</tr>" & VbCrlf & VbCrlf
End Sub


Sub ShowInputMemo(lngID, strName, strMemo)
	Response.Write "<tr valign=top align=left>" & VbCrlf
	Response.Write "<td colspan=2><b>" & strName & "</b><br><textarea name=M" & lngID & " COLS=90 ROWS=20>" & strMemo & "</textarea></td>" & VbCrlf
	Response.Write "</tr>" & VbCrlf & VbCrlf
End Sub


Sub ShowInputMemoShort(lngID, strName, strMemo)
	Response.Write "<tr valign=top align=left>" & VbCrlf
	Response.Write "<td colspan=2><b>" & strName & "</b><br><textarea name=M" & lngID & " COLS=80 ROWS=25>" & strMemo & "</textarea></td>" & VbCrlf
	Response.Write "</tr>" & VbCrlf & VbCrlf
End Sub


Sub ShowInputTab(lngID, strName, strType, strPageOrigine)

	Dim rsParam, strTitre, strEntete, strSQL, strValDef, lngFirstRec

	Set rsParam = Server.CreateObject("ADODB.Recordset")
	strSQL = "SELECT * FROM TablesAdmin WHERE EstAdmin=False AND Type='" & strType & "' AND IdStructMono=" & lngID 
	rsParam.Open strSQL, conConnexion

	if not rsParam.EOF then
		strTitre = rsParam("NomTable")
		strEntete = rsParam("Entete")
		strSQL = rsParam("CodeSQL")
		strValDef = rsParam("ValeurParDef")

		strSQL = Replace(strSQL, "XXX", Session("IDPays"))
		strSQL = Replace(strSQL, "YYY", Session("Annee"))
		strValDef = Replace(strValDef, "XXX", Session("IDPays"))
		strValDef = Replace(strValDef, "YYY", Session("Annee"))

		lngFirstRec = Request("FIRSTREC")

		Select Case strType
			Case "XCROI", "XADR", "XTXME"
				GereTab strTitre, strEntete, strSQL, strValDef, lngFirstRec, strPageOrigine
			Case "XLCVV", "XLCV", "XLVV", "XLV", "XLC"
				ShowInputXFlat strTitre, strEntete, strSQL, strValDef, "XLign"
		End Select
	end if

	rsParam.Close
	Set rsParam = Nothing
End Sub


Sub ShowInputXFlat(strTitre, strEntete, strSQL, strValDef, strTable)
	
	Dim rsPresent, strColName(), intColSize(), varValDef(), i 
	Set rsPresent = Server.CreateObject("ADODB.Recordset")
	rsPresent.Open strSQL, conConnexion

	Response.Write "<tr><td><h2>" & strTitre & "</h2></td></tr>" & VbCrlf

	
	if not rsPresent.EOF then
		Parse strEntete, strColName, intColSize, strValDef, varValDef

		Response.Write "<tr>" & VbCrlf

		for i = 1 to UBound(strColName)
			if strColName(i)<>"" then
				Response.Write "<td align=right><b>" & strColName(i) & "&nbsp;&nbsp;</b></td>" & VbCrlf
			end if
		next
		Response.Write "</tr>" & VbCrlf

		while not rsPresent.EOF
			Response.Write "<tr>" & VbCrlf
			Response.Write "<input type=hidden name=""ID" & strTable & "_" & rsPresent("ID" & strTable) & """ Value=""" & rsPresent("ID" & strTable) & """>" & VbCrlf
			for i = 1 to UBound(strColName)
				if strColName(i)<>"" then
					if intColSize(i)=0 then
						Response.Write "<td align=right>" & rsPresent(i-1) & "&nbsp;:&nbsp;</td>" & VbCrlf
					else
						Response.Write "<td><input type=text name=""" & rsPresent(i-1).Name & "_" & rsPresent("ID" & strTable) & """ Value=""" & rsPresent(i-1) & """ size=""" & intColSize(i) & """></td>" & VbCrlf
						Response.Write "<input type=hidden name=""" & rsPresent(i-1).Name & "_" & rsPresent("ID" & strTable) & "_Hid"" Value=""" & rsPresent(i-1) & """>" & VbCrlf
					end if
				end if
			next
			Response.Write "</tr>" & VbCrlf
			
			rsPresent.MoveNext
		wend
	end if

	Response.Write "<tr><td>&nbsp;<br>&nbsp;<br>&nbsp;</td></tr>" & VbCrlf & VbCrlf

	rsPresent.Close
	Set rsPresent = Nothing
End Sub


Sub ShowBtnSupprTab(lngID)
	Response.Write "<tr valign=top align=left>" & VbCrlf
	Response.Write "<td colspan=2><input type=button value=""Suppr Tab"" onClick=""RemoveTab(document.forms[ 0 ].M" & lngID & ")""</td>" & VbCrlf
	Response.Write "</tr>" & VbCrlf & VbCrlf
End Sub


</SCRIPT>
<SCRIPT Language="javascript">


function RemoveTab( myelement ) {

var i ;
var str = "";

	i = 0 ;

	while( ( j = myelement.value.indexOf("\t", i ) ) != -1 )
	{
			str = str + myelement.value.substring( i, j ) +  " " ;

			i = j + 1 ;
	}

	myelement.value = str + myelement.value.substring( i ) ;
	

}

</SCRIPT>
