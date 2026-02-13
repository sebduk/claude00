<HTML>
<head>
<link rel=stylesheet type=text/css href=/queryman/style.css>
</head>
<BODY bgcolor=#ffffff>
You Are : <%=Request.ServerVariables("REMOTE_ADDR")%><br>
<center>

<%
'PRINT QUERY
response.write "<b>" & strSQL & "</b><br>"

strWork = Mid(strSQL, 6)
strTable = Trim(Left(strWork, InStr(1, strWork, ",") - 1))
strSort = Trim(Mid(strWork, InStr(1, strWork, ",") + 1))

'SORT
For each x in Request.Form
	if UCase(Left(x,2)) = "UP"  and UCase(Right(x,2)) = ".X" then

		Pos1 = Instr(1,x, "-")
		Pos2 = Instr(Pos1,x, "_")
		Pos3 = Instr(Pos2,x, "-")
		Pos4 = Instr(Pos3,x, ".")

		lngIDOld = Mid(x, 3, Pos1 - 3)
		intSortOld = Mid(x, Pos1 + 1, Pos2 - Pos1 - 1)
		lngIDNew = Mid(x, Pos2 + 1, Pos3 - Pos2 - 1)
		intSortNew = Mid(x, Pos3 + 1,  Pos4 - Pos3 - 1)
		
		strSQLUpdate = "UPDATE " & strTable & " SET " & strSort & "=" & intSortNew & " WHERE ID=" & lngIDOld
		rs.Open strSQLUpdate, conn
		strSQLUpdate = "UPDATE " & strTable & " SET " & strSort & "=" & intSortOld & " WHERE ID=" & lngIDNew
		rs.Open strSQLUpdate, conn
	end if
next

lngIDOld = Empty
intSortOld = Empty
lngIDNew = Empty
intSortNew = Empty




strSQL2 = "SELECT * FROM " & strTable & " ORDER BY " & strSort
rs.Open strSQL2, conn, 2, 3

'REWRITE QUERY
response.write "<b>" & strSQL2 & "</b><br><br>"

Response.Write "<form method=Post action=answer.asp>"
Response.Write "<input type=hidden name=MyQuery Value=""" & strSQL & """>"
Response.Write "<input type=hidden name=MyDSN Value=""" & Session("MyDSN") & """>"

response.write "<table border=1 cellpadding=0 cellspacing=0><tr>"

for i = 0 to rs.fields.count - 1
	response.write "<td valign=top><b>" & rs(i).name & "</td>"
next

response.write "</tr>"

while not rs.EOF
	cptRec = cptRec + 1
	response.write "<tr>"
	for i = 0 to rs.fields.count - 1
		response.write "<td valign=top>" & rs(i) 
		if UCase(rs(i).name) = UCase(strSort) then

			rs(i) = cptRec * 10
			rs.Update
			
			lngIDOld = lngIDNew
			lngIDNew = rs(0)
			intSortOld = intSortNew
			intSortNew = rs(i)
			
			if lngIDOld <> Empty then
				response.write "</td>"
			end if
		else
			response.write "&nbsp;</td>"
		end if
	next
	response.write "</tr>"

	rs.MoveNext
wend

response.write "</table><br>"
response.write "</form>"

if cptRec > 0 then
	response.write "<b>" & cptRec & " Record(s) Found</b>"
else
	response.write "<b>No Record Found</b>"
end if

rs.close
%>

</center>

</BODY>
</HTML>
