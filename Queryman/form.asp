<%@ LANGUAGE="VBSCRIPT" %>

<HTML>
<head>
<link rel=stylesheet type=text/css href=/QueryMan/style.css>
</head>
<BODY>
Your Are : <%=Request.ServerVariables("REMOTE_ADDR")%><br>
<center>

<!-- #INCLUDE VIRTUAL="/QueryMan/Admin/inclDAOHead.asp" -->

<%
if Request("MyQuery") <> Empty and Request("MyQuery") <> "" then

	if Request("ACT") <> Empty and Request("ACT") <> "" then
		Response.Write "<font color=red>Action = " & Request("ACT") & "</font><br>"

		strSQL = Trim(Request("MyQuery"))
		Set rs = Server.CreateObject("ADODB.Recordset")

		rs.Open strSQL, conn, 2, 2


		Select Case Request("ACT")
			Case "ADD"
Response.Write "<table border=1 cellpadding=0 cellspacing=0>" & VbCrlf
				rs.addNew
				for each x in Request.Form
					On Error Resume Next
						if Request(x) <> "" then 
Response.Write "<tr><td>" & x & "</td><td>= """ & rs(x) & """</td><td>"
							rs(x) = Request(x)
Response.Write "<td>New = </td><td>= """ & Request(x) & """</td><td>-> """ & rs(x) & """</td></tr>" & VbCrlf
						end if
					On Error Goto 0
				next
				rs.update
Response.Write "</table>" & VbCrlf

			Case "Copy"
				strOld = rs(0)
				rs.addNew
				for each x in Request.Form
					On Error Resume Next
						if rs(x).name <> rs(0).name and Request(x) <> "" then 
							rs(x) = Request(x)
						end if
					On Error Goto 0
				next
				rs.update
				strNew = rs(0)
				strSQL = Replace(strSQL, strOld, strNew)

				Response.Write "<a href=""form.asp?MyQuery=" & strSQL & """>Goto to new</a><br>"
				

			Case "Update"
Response.Write "<table border=1 cellpadding=0 cellspacing=0>" & VbCrlf
				rs.MoveFirst
				do while not rs.EOF
					if UCase(rs(0)) = UCase(Request(rs(0).Name)) then Exit Do
					rs.MoveNext
				loop

				for each x in Request.Form
					On Error Resume Next
						if Cstr(Request(x)) <> CStr(rs(x)) and rs(x).name <> rs(0).name then 
Response.Write "<tr valign=top><td>" & x & "</td><td>= """ & rs(x) & """</td>"
							if Request(x) = "" then
								rs(x) = Null
							else
								rs(x) = Request(x)
							end if
Response.Write "<td>New</td><td>= """ & Request(x) & """</td><td>-> """ & rs(x) & """</td></tr>" & VbCrlf
						end if
					On Error Goto 0
				next
				rs.update
Response.Write "</table>" & VbCrlf

			Case "Delete"
				rs.MoveFirst
				do while not rs.EOF
					if UCase(rs(0)) = UCase(Request(rs(0).Name)) then Exit Do
					rs.MoveNext
				loop

				rs.Delete
		End Select

		rs.Close
		Set rs = Nothing

		Response.Write "<font color=red>" & Request("ACT") & " : performed OK</font><br>"

	end if

	Set rs = Server.CreateObject("ADODB.Recordset")

	strSQL = Trim(Request("MyQuery"))
	response.write "<font color=Blue><b>" & strSQL & "</b></font><br><br>" & VbCrlf
	response.write "<table border=0 cellpadding=0 cellspacing=0>" & VbCrlf

Response.Write strSQL & "<br>"
	rs.Open strSQL, conn

	if Request("ACT") = "Next" then
		rs.MoveFirst
		do while not rs.EOF
			if UCase(rs(0)) = UCase(Request(rs(0).Name)) then Exit Do
			rs.MoveNext
		loop
		rs.MoveNext
	end if

	if not rs.EOF then
		response.write "<form action=form.asp method=post>" & VbCrlf
		response.write "<input type=hidden name=""" & rs(0).name & """ value=""" & rs(0) & """>" & VbCrlf
		response.write "<input type=hidden name=""MyQuery"" value=""" & strSQL & """>" & VbCrlf
		response.write "<tr><td></td><td align=center><input type=submit name=ACT value=Next class=button><input type=submit name=ACT value=Delete class=button></td></tr>" & VbCrlf
		response.write "</form>" & VbCrlf & VbCrlf
		
		response.write "<form action=""form.asp"" name=""UPDATE"" method=post>" & VbCrlf
		response.write "<tr><td>&nbsp;</td><td align=center><input type=submit name=ACT value=Update class=button><input type=submit name=ACT value=Copy class=button></td></tr>" & VbCrlf
		
		for i = 0 to rs.Fields.Count - 1
			strNom = rs(i).Name
			strContenu = rs(i) & ""
			Response.Write "<tr valign=top>" & VbCrlf
			Response.Write " <td align=right>" & strNom & "&nbsp;</td>" & VbCrlf

			if rs(i).Type = 203 then		'	"Memo" Fields	
				Response.Write " <td><Textarea rows=10 cols=77 name=""" & strNom & """ class=box>" & server.HTMLEncode(strContenu) & "</Textarea></td>" & VbCrlf
			else
				Response.Write " <td><input type=text size=75 name=""" & strNom & """ value=""" & server.HTMLEncode(strContenu) & """ class=box></td>" & VbCrlf '" & rs(i).Type & "
			end if

			Response.Write "</tr>" & VbCrlf & VbCrlf
		next
		
		response.write "<input type=hidden name=""MyQuery"" value=""" & strSQL & """>" & VbCrlf
		response.write "<tr><td>&nbsp;</td><td align=center><input type=submit name=ACT value=Update class=button><input type=submit name=ACT value=Copy class=button></td></tr>" & VbCrlf
		response.write "</form>" & VbCrlf & VbCrlf
		
		response.write "<form action=form.asp method=post>" & VbCrlf
		response.write "<input type=hidden name=""" & rs(0).name & """ value=""" & rs(0) & """>" & VbCrlf
		response.write "<input type=hidden name=""MyQuery"" value=""" & strSQL & """>" & VbCrlf
		response.write "<tr><td></td><td align=center><input type=submit name=ACT value=Next class=button><input type=submit name=ACT value=Delete class=button></td></tr>" & VbCrlf
		response.write "</form>" & VbCrlf

	else

		response.write "<form action=""form.asp"" name=""ADD"" method=post>" & VbCrlf
		response.write "<tr><td>&nbsp;</td><td align=center><input type=submit value=Add class=button></td></tr>" & VbCrlf & VbCrlf
		
		for i = 0 to rs.Fields.Count - 1
			strNom = rs(i).Name
			Response.Write "<tr valign=top>" & VbCrlf
			Response.Write " <td align=right>" & strNom & "&nbsp;</td>" & VbCrlf

			if rs(i).Type = 203 then		'	"Memo" Fields	
				Response.Write " <td><Textarea rows=10 cols=77 name=""" & strNom & """ class=box>" & server.HTMLEncode(strContenu) & "</Textarea></td>" & VbCrlf
			else
				Response.Write " <td><input type=text size=75 name=""" & strNom & """ value=""" & server.HTMLEncode(strContenu) & """ class=box></td>" & VbCrlf
			end if

			Response.Write "</tr>" & VbCrlf & VbCrlf
		next
		
		response.write "<input type=hidden name=""ACT"" value=""ADD"">" & VbCrlf
		response.write "<input type=hidden name=""MyQuery"" value=""" & strSQL & """>" & VbCrlf
		response.write "<tr><td>&nbsp;</td><td align=center><input type=submit value=Add class=button></td></tr>" & VbCrlf
		response.write "</form>" & VbCrlf
	end if

	response.write "</table>" & VbCrlf

	rs.Close
end if
%>

<!-- #INCLUDE VIRTUAL="/Queryman/Admin/inclDAOFoot.asp" -->

</center>

</BODY>
</HTML>
