<%@ LANGUAGE="VBSCRIPT" %>

<html>
<head>
<link rel=stylesheet type=text/css href=/Queryman/style.css>
</head>
<body>
Your Are : <%=Request.ServerVariables("REMOTE_ADDR")%><br>
<center>

<%
dim arrCol()
redim arrCol(6)

arrCol(1) = "00"
arrCol(2) = "33"
arrCol(3) = "66"
arrCol(4) = "99"
arrCol(5) = "cc"
arrCol(6) = "ff"


Response.Write "<table>"
Response.Write "<tr>"
Response.Write "<td>"

	Response.Write "<table>"
	for i = 1 to 6
		for j = 1 to 6
			Response.Write "<tr>"
			for k = 1 to 6
				Response.Write "<td bgcolor=#" & arrCol(i) & arrCol(j) & arrCol(k) & ">" 
				Response.Write arrCol(i) & arrCol(j) & arrCol(k) & "</td>"
			next
			Response.Write "</tr>"
		next
	next
	Response.Write "</table>"

Response.Write "</td>"
Response.Write "<td>"

	Response.Write "<table>"
	for i = 1 to 6
		for j = 1 to 6
			Response.Write "<tr>"
			for k = 1 to 6
				Response.Write "<td bgcolor=#" & arrCol(i) & arrCol(k) & arrCol(j) & ">" 
				Response.Write arrCol(i) & arrCol(k) & arrCol(j) & "</td>"
			next
			Response.Write "</tr>"
		next
	next
	Response.Write "</table>"

Response.Write "</td>"
Response.Write "<td>"

	Response.Write "<table>"
	for i = 1 to 6
		for j = 1 to 6
			Response.Write "<tr>"
			for k = 1 to 6
				Response.Write "<td bgcolor=#" & arrCol(j) & arrCol(i) & arrCol(k) & ">" 
				Response.Write arrCol(j) & arrCol(i) & arrCol(k) & "</td>"
			next
			Response.Write "</tr>"
		next
	next
	Response.Write "</table>"

Response.Write "</td>"
Response.Write "</tr>"
Response.Write "<tr>"
Response.Write "<td>"

	Response.Write "<table>"
	for i = 1 to 6
		for j = 1 to 6
			Response.Write "<tr>"
			for k = 1 to 6
				Response.Write "<td bgcolor=#" & arrCol(j) & arrCol(k) & arrCol(i) & ">" 
				Response.Write arrCol(j) & arrCol(k) & arrCol(i) & "</td>"
			next
			Response.Write "</tr>"
		next
	next
	Response.Write "</table>"

Response.Write "</td>"
Response.Write "<td>"

	Response.Write "<table>"
	for i = 1 to 6
		for j = 1 to 6
			Response.Write "<tr>"
			for k = 1 to 6
				Response.Write "<td bgcolor=#" & arrCol(k) & arrCol(i) & arrCol(j) & ">" 
				Response.Write arrCol(k) & arrCol(i) & arrCol(j) & "</td>"
			next
			Response.Write "</tr>"
		next
	next
	Response.Write "</table>"

Response.Write "</td>"
Response.Write "<td>"

	Response.Write "<table>"
	for i = 1 to 6
		for j = 1 to 6
			Response.Write "<tr>"
			for k = 1 to 6
				Response.Write "<td bgcolor=#" & arrCol(k) & arrCol(j) & arrCol(i) & ">" 
				Response.Write arrCol(k) & arrCol(j) & arrCol(i) & "</td>"
			next
			Response.Write "</tr>"
		next
	next
	Response.Write "</table>"

Response.Write "</td>"
Response.Write "</tr>"
Response.Write "</table>"
%>

</center>

</body>
</html>
