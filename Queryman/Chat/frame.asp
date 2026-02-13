<%@ LANGUAGE="VBSCRIPT" %>

<%
If Request("Refresh") <> Empty then Session("Refresh") = Request("Refresh")
'If Session("Refresh") = 0 then Session("Refresh") = "30"

If Request("Nickname") <> Empty then Session("Nickname") = Request("Nickname")

If Request("Clear") <> Empty Then
	Application("Text") = ""

ElseIf Request("Save") <> Empty Then
	Set conConnexion = Server.CreateObject("ADODB.Connection")
	conConnexion.Open "DSN=RND"
	Set rs = Server.CreateObject("ADODB.Recordset")
	strSQL = "SELECT * FROM Chat WHERE ID=0"
	rs.Open strSQL, conConnexion, 2, 3
	rs.AddNew
	rs("DateSaved") = Now()
	rs("ChatText") = Application("Text")
	rs.Update
	rs.close

ElseIf Request("Line") <> Empty Then
	Application("Text") = Application("Text") & "<hr size=1 noshade>"
	If Request("Text") <> Empty then Application("Text") = Application("Text") & "<b>" & Session("Nickname") & "</b> &gt; " & Request("Text")

ElseIf Request("Time") <> Empty Then
	If Right(Application("Text"), 19) = "<hr size=1 noshade>" then
		Application("Text") = Application("Text") & "<b>" & Session("Nickname") & "</b>&nbsp;<font size=1 color=red>" & Date() & " " & Time() & "</font>&nbsp;&gt;&nbsp;"
	Else
		Application("Text") = Application("Text") & "<br><b>" & Session("Nickname") & "</b>&nbsp;<font size=1 color=red>" & Date() & " " & Time() & "</font>&nbsp;&gt;&nbsp;"
	End If
	If Request("Text") <> Empty then Application("Text") = Application("Text") & Request("Text")

Else
	If Request("Text") <> Empty then
		If Right(Application("Text"), 19) = "<hr size=1 noshade>" then
			Application("Text") = Application("Text") & "<b>" & Session("Nickname") & "</b> &gt; " & Request("Text")
		Else
			Application("Text") = Application("Text") & "<br><b>" & Session("Nickname") & "</b> &gt; " & Request("Text")
		End If
	End If
End If

If Len(Application("Text")) > 2500 then
	strWork = StrReverse(Application("Text"))
	Pos = InStr(2000, strWork, ";tg&")
	Pos = InStr(Pos, strWork, ">b<") + 2
	strWork = Left(strWork, Pos)
	Application("ShowText") = StrReverse(strWork)
Else
	Application("ShowText") = Application("Text")
End If

If Left(Application("Text"), 4) = "<br>" then Application("Text") = Mid(Application("Text"), 5)
%>

<html>
<head><title>QueryMan Chat</title></head>

<frameset Rows="*,50" frameborder=0 border=0>

<frame src="top.asp" name="top">
<frame src="bot.asp" name="bot" scrolling=no>

</frameset>

</html>