<SCRIPT LANGUAGE="VBSCRIPT" RUNAT="SERVER">

sub DebugPrint(strRequest)
	DebugTime
	DebugRequestForm
	DebugRequest strRequest
	DebugSessionVar
End sub

Sub DebugRequestForm()
	Dim x, IlYEnA

	IlYEnA = False

	Response.Write "<font color=red size=2><u>Request.Form</u><br>" & VbCrlf
	For Each x In Request.Form
		Response.Write x & " = &quot;" & Request.Form(x) & "&quot;<BR>" & VbCrlf
		IlYEnA = True
	Next

	if not IlYEnA then Response.Write "No Forms"

	Response.Write "<hr></Font>" & VbCrlf
End Sub

Sub DebugRequest(strRequest)

	Dim posDeb, posFin, strChamp
	
	Response.Write "<font color=red size=2><u>Request</u><br>" & VbCrlf

	if strRequest = "" then
		Response.Write "No Request" & VbCrlf
	else
		posDeb = 1
		posFin = InStr(posDeb, strRequest, ",")

		while posFin <> 0
			strChamp = Mid(strRequest, posDeb, posFin - posDeb)
			Response.Write strChamp & " = " & Request(strChamp) & "<br>" & VbCrlf

			posDeb = posFin + 1
			if posDeb > Len(strRequest) then
				posFin = 0
			else
				posFin = InStr(posDeb, strRequest, ",")
			end if
		wend
	end if

	Response.Write "<hr></Font>" & VbCrlf
End Sub

Sub DebugSessionVar()
	Response.Write "<font color=blue size=2><u>Session Variables</u><br>" & VbCrlf
	Response.Write "User = " & Session( "User" ) & "<br>" & VbCrlf
	Response.Write "Droits = " & Session( "Droits" ) & "<br>" & VbCrlf
	Response.Write "LoginOK = " & Session( "LoginOK" ) & "<br><br>" & VbCrlf

	Response.Write "IDContinent = " & Session( "IDContinent" ) & "<br>" & VbCrlf
	Response.Write "IDZone = " & Session( "IDZone" ) & "<br>" & VbCrlf
	Response.Write "IDPays = " & Session( "IDPays" ) & "<br>" & VbCrlf
	Response.Write "IDConsulat = " & Session( "IDConsulat" ) & "<br>" & VbCrlf
	Response.Write "Annee = " & Session( "Annee" ) & "<br>" & VbCrlf
	Response.Write "Mois = " & Session( "Mois" ) & "<br><br>" & VbCrlf

	Response.Write "Action = " & Session( "Action" ) & "<br>" & VbCrlf
	Response.Write "IDFDP = " & Session( "IDFDP" ) & "<br>" & VbCrlf
	Response.Write "IDItem = " & Session( "IDItem" ) & "<br>" & VbCrlf
	Response.Write "ParamPrev = " & Session( "ParamPrev" ) & "<br>" & VbCrlf
	Response.Write "ParamCurr = " & Session( "ParamCurr" ) & "<br><br>" & VbCrlf

	Response.Write "ChapitreDeplies = " & Session( "ChapitreDeplies" ) & "<br>" & VbCrlf
	Response.Write "<hr></font>" & VbCrlf
End Sub 

Sub DebugTime()
	Response.write "<font color=green size=2><u>Clock</u><br>"
	Response.write "Date & Time = " & Now() 
	Response.write "<hr></font>" 
End Sub

</SCRIPT>

<%
dim strRequest

if Session("LoginOK") then
%>
