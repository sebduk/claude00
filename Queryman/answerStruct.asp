<html>
<head>
<link rel=stylesheet type=text/css href=/queryman/style.css>
</head>
<body>
You Are : <%=Request.ServerVariables("REMOTE_ADDR")%><br>
<center>

<%
'PRINT QUERY
response.write "<b>" & strSQL & "</b><br>"

strSQL = "SELECT * FROM " & Mid(strSQL, 8)
rs.Open strSQL, conn

'REWRITE QUERY
strIDName = rs(0).Name
strSQL = strSQL & " WHERE " & strIDName & "=0"
response.write "<b>" & strSQL & "</b><br><br>"

response.write "<table border=1 cellpadding=0 cellspacing=0><tr>"

for i = 0 to rs.fields.count - 1
	response.write "<td valign=top><b>" & rs(i).name & "</td>" & VbCrlf
next

response.write "</tr></table><br>"

while not rs.EOF
	cptRec = cptRec + 1
	rs.MoveNext
wend

if cptRec > 0 then
	response.write "<b>" & cptRec & " Record(s) Found</b>"
else
	response.write "<b>No Record Found</b>"
end if

rs.close
%>

</center>

</body>
</html>
