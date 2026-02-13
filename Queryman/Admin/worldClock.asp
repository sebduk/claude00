<%@ LANGUAGE="VBSCRIPT" %>

<html>
<head>
<link rel=stylesheet type=text/css href=/queryman/style.css>
</head>
<body>

<%
Dim conn, rs, strConn
strConn = "PROVIDER=Microsoft.Jet.OLEDB.4.0;DATA SOURCE=" & server.mappath(session("QueryDB")) & ";"
Set conn= Server.CreateObject("ADODB.Connection")
conn.Open strConn
Set rs = Server.CreateObject("ADODB.Recordset")

if Request("Present") = "All" then
	strSQL = "SELECT IdTimeZone, TimeZoneName, TimeZoneOffset, TimeZoneIsHeader "
	strSQL = strSQL & "FROM "
	strSQL = strSQL & "(SELECT IdTimeZone, TimeZoneName, TimeZoneOffsetDSTOn AS TimeZoneOffset, TimeZoneIsHeader "
	strSQL = strSQL & "FROM TimeZone "
	strSQL = strSQL & "WHERE TimeZoneIsOnline AND TimeZoneIsDST "
	strSQL = strSQL & "UNION "
	strSQL = strSQL & "SELECT IdTimeZone, TimeZoneName, TimeZoneOffsetDSTOff AS TimeZoneOffset, TimeZoneIsHeader "
	strSQL = strSQL & "FROM TimeZone "
	strSQL = strSQL & "WHERE TimeZoneIsOnline AND NOT TimeZoneIsDST) "
	strSQL = strSQL & "ORDER BY TimeZoneOffset DESC, TimeZoneIsHeader, TimeZoneName"
	rs.Open strSQL, conn

	dim arrWorldClock()
	redim arrWorldClock(4, 0)
	row = 0

	while not rs.EOF
		row = row + 1
		redim preserve arrWorldClock(4, row)

		arrWorldClock(1, row) = rs(0)
		arrWorldClock(2, row) = rs(1)
		if rs(2) >= 0 then
			arrWorldClock(3, row) = "+" & rs(2)
		else
			arrWorldClock(3, row) = rs(2)
		end if
		arrWorldClock(4, row) = rs(3)

		Response.Write arrWorldClock(3, row) & " " & arrWorldClock(2, row) & "<br>"
		rs.MoveNext
	wend
	rs.Close

	application("WorldClock") = arrWorldClock
	Response.Write "<br>application(""WorldClock"") loaded"

elseif Request("Present") = "Header" then
	strSQL = "SELECT IdTimeZone, TimeZoneName, TimeZoneOffset, TimeZoneIsHeader "
	strSQL = strSQL & "FROM "
	strSQL = strSQL & "(SELECT IdTimeZone, TimeZoneName, TimeZoneOffsetDSTOn AS TimeZoneOffset, TimeZoneIsHeader "
	strSQL = strSQL & "FROM TimeZone "
	strSQL = strSQL & "WHERE TimeZoneIsOnline AND TimeZoneIsHeader AND TimeZoneIsDST "
	strSQL = strSQL & "UNION "
	strSQL = strSQL & "SELECT IdTimeZone, TimeZoneName, TimeZoneOffsetDSTOff AS TimeZoneOffset, TimeZoneIsHeader "
	strSQL = strSQL & "FROM TimeZone "
	strSQL = strSQL & "WHERE TimeZoneIsOnline AND TimeZoneIsHeader AND NOT TimeZoneIsDST) "
	strSQL = strSQL & "ORDER BY TimeZoneOffset, TimeZoneIsHeader, TimeZoneName"
'	strSQL = strSQL & "ORDER BY TimeZoneOffset DESC, TimeZoneIsHeader, TimeZoneName"
	rs.Open strSQL, conn

	dim arrWorldClockHead()
	redim arrWorldClockHead(4, 0)
	row = 0

	while not rs.EOF
		row = row + 1
		redim preserve arrWorldClockHead(4, row)

		arrWorldClockHead(1, row) = rs(0)
		arrWorldClockHead(2, row) = rs(1)
		if rs(2) >= 0 then
			arrWorldClockHead(3, row) = "+" & rs(2)
		else
			arrWorldClockHead(3, row) = rs(2)
		end if
		arrWorldClockHead(4, row) = rs(3)

		Response.Write arrWorldClockHead(3, row) & " " & arrWorldClockHead(2, row) & "<br>"
		rs.MoveNext
	wend
	rs.Close

	application("WorldClockHead") = arrWorldClockHead
	Response.Write "<br>application(""WorldClockHead"") loaded"

else
	strSQL = "SELECT IdTimeZone, TimeZoneName, TimeZoneOffset, TimeZoneIsHeader "
	strSQL = strSQL & "FROM "
	strSQL = strSQL & "(SELECT IdTimeZone, TimeZoneName, TimeZoneOffsetDSTOn AS TimeZoneOffset, TimeZoneIsHeader "
	strSQL = strSQL & "FROM TimeZone "
	strSQL = strSQL & "WHERE TimeZoneIsOnline AND TimeZoneIsHeaderOut AND TimeZoneIsDST "
	strSQL = strSQL & "UNION "
	strSQL = strSQL & "SELECT IdTimeZone, TimeZoneName, TimeZoneOffsetDSTOff AS TimeZoneOffset, TimeZoneIsHeader "
	strSQL = strSQL & "FROM TimeZone "
	strSQL = strSQL & "WHERE TimeZoneIsOnline AND TimeZoneIsHeaderOut AND NOT TimeZoneIsDST) "
	strSQL = strSQL & "ORDER BY TimeZoneOffset, TimeZoneIsHeader, TimeZoneName"
'	strSQL = strSQL & "ORDER BY TimeZoneOffset DESC, TimeZoneIsHeader, TimeZoneName"
	rs.Open strSQL, conn

	dim arrWorldClockHeadOut()
	redim arrWorldClockHeadOut(4, 0)
	row = 0

	while not rs.EOF
		row = row + 1
		redim preserve arrWorldClockHeadOut(4, row)

		arrWorldClockHeadOut(1, row) = rs(0)
		arrWorldClockHeadOut(2, row) = rs(1)
		if rs(2) >= 0 then
			arrWorldClockHeadOut(3, row) = "+" & rs(2)
		else
			arrWorldClockHeadOut(3, row) = rs(2)
		end if
		arrWorldClockHeadOut(4, row) = rs(3)

		Response.Write arrWorldClockHeadOut(3, row) & " " & arrWorldClockHeadOut(2, row) & "<br>"
		rs.MoveNext
	wend
	rs.Close

	application("WorldClockHeadOut") = arrWorldClockHeadOut
	Response.Write "<br>application(""WorldClockHeadOut"") loaded"

end if

conn.Close
Set rs = nothing
Set conn = nothing
%>

</body>
</html>
