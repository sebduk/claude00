<HTML>
<head>
<link rel=stylesheet type=text/css href=/queryman/style.css>
</head>
<BODY bgcolor=#ffffff>
You Are : <%=Request.ServerVariables("REMOTE_ADDR")%><br>
<center>

<table border=1 cellpadding=0 cellspacing=0>

<%
'PRINT QUERY
response.write "<b>" & strSQL & "</b><br><br>"

rs.Open strSQL, conn

response.write "<tr><td>&nbsp;</td>"

'PRINT COLUMN HEADERS
for i = 0 to rs.fields.count - 1
	response.write "<td valign=top><b>" & rs(i).name & "</td>" & VbCrlf
next

response.write "</tr>"

strSQL = Replace(strSQL, VbCrlf, " ")

PosF1 = InStr(UCase(strSQL), "FROM") + 5
PosF2 = InStr(PosF1, UCase(strSQL), " ")

if PosF2 > 0 then
	strTableName = mid(strSQL, PosF1, PosF2 - PosF1) 
else
	strTableName = mid(strSQL, PosF1) 
end if

if not rs.eof then
	while not rs.eof

response.write "<tr>"

'PRINT TABLE BODY

		
		if rs(0).type = 200 or rs(0).type = 200 then
			strMySQL = "SELECT * FROM " & strTableName & " WHERE " & rs(0).name & "='" & rs(0) & "'"
		else
			strMySQL = "SELECT * FROM " & strTableName & " WHERE " & rs(0).name & "=" & rs(0)
		end if
		
		strMySQL = Replace(strMySQL, " ", "%20")
		strMySQL = Replace(strMySQL, VbCrlf, "%20")
		
		response.write "<td valign=top><a href=form.asp?MyQuery=" & strMySQL & ">Form</a></td>" & VbCrlf
		for i = 0 to rs.fields.count - 1
			strTrav = rs(i)
			if strTrav <> "" then
				strTrav = Replace(strTrav, "True", "<font color=blue>True</font>")
				strTrav = Replace(strTrav, "False", "<font color=red>False</font>")
			else
				strTrav = "<font color=green>Empty Field</font>"
			end if
			response.write "<td valign=top>" & strTrav & "</td>" & VbCrlf
		next

response.write "</tr>"

		rs.MoveNext
	wend
else
	Response.Write "<tr><td align=center colspan=" & rs.fields.count+1 & VbCrlf
	Response.Write "><font color=Green>No Match</font></td></tr>" & VbCrlf
end if

rs.close
%>

</table>

<br>
<br>

</center>

</BODY>
</HTML>
