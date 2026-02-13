<%@ LANGUAGE="VBSCRIPT" %>

<%
if Session("QueryOK") = "safe" then

	if request("QueryDB") <> empty then session("QueryDB") = request("QueryDB")

'	on error resume next
	Dim conn, rs, strConn
	strConn = "PROVIDER=Microsoft.Jet.OLEDB.4.0;DATA SOURCE=" & server.mappath(session("QueryDB")) & ";"
	Set conn= Server.CreateObject("ADODB.Connection")
	conn.Open strConn
	Set rs = Server.CreateObject("ADODB.Recordset")
'	on error goto 0
	%>
	<html>
	<head>
	<link rel=stylesheet type=text/css href=/queryman/style.css>
	</head>
	<body bgcolor=#888888 link=#aa0000 vlink=#aa0000 alink=#ff0000 topmargin=2 leftmargin=0 rightmargin=0>
	<table border=0 cellpadding=0 cellspacing=0 width=100%>
	 <tr>
	  <form action=tables.asp method=post>
	  <td>
	   <input type=text name=QueryDB size=50 value="<%=Session("QueryDB")%>" class=box>
	   <a href="tables.asp?QueryDB=/Data/user.mdb">User</a> |
	   <a href="tables.asp?QueryDB=/Gene/Data/1-tajan.mdb">Tajan</a> |
	   <a href="tables.asp?QueryDB=/Gene/Data/2-moeskops.mdb">Moeskops</a> |
		 <a href="tables.asp?QueryDB=/Gene/Data/3-dunn.mdb">Dunn</a> |
		 <a href="tables.asp?QueryDB=/Gene/Data/26-ducos.mdb">Ducos</a>
	  </td>
	  </form>
	 </tr>
	 <tr>
	  <td>
	   > <b>Tables</b> |
	<%
'	on error resume next
	strSQL = "SELECT * FROM Tables ORDER BY TableName"
	rs.Open strSQL, conn

	'PRINT TABLE NAMES
	while not rs.EOF
		Response.Write "<a href=""answer.asp?MyTable=" & rs("TableName") & """ target=answer>" & rs("TableName") & "</a>"
		Response.Write "&nbsp;| "
		rs.MoveNext
	wend

''	if Session("QueryDB") = "/Data/user.mdb" then
''		Response.Write "<b>Delete</b> "
''		Response.Write "<a href=""answer.asp?MyQuery=DELETE * FROM LkDomainUser WHERE NOT IdDomain IN (SELECT IDDomain FROM [Domain])"" target=answer>LkDomainUser.IdDomain</a>&nbsp;| "
''		Response.Write "<a href=""answer.asp?MyQuery=DELETE * FROM LkDomainUser WHERE NOT IdUser IN (SELECT IDUser FROM [User])"" target=answer>LkDomainUser.IdUser</a>"
''	end if

	rs.Close
'	on error goto 0
	%>
	  </td>
	 </tr>

	 <tr>
	  <td>
	   > <b>Admin</b> |
	   <a href=/QueryMan/Admin/files.asp target=answer>Files</a> |
	   <a href=/Image/Help/ target=answer>Help</a> |
	   <a href=/QueryMan/Admin/md5.asp target=answer>MD5 calculator</a> |
	   <a href=/QueryMan/Admin/colours.asp target=answer>Colour scheme</a>
	  </td>
	 </tr>

	 <tr>
	  <td><hr size=1></td>
	 </tr>
	 <tr>
	  <td>
		> STRUCT ? (lists Fields in Table ?)<br>
		> SORT ?,?? (To reorder the ? table accounding to ?? field)<br>
		<br>
		> SELECT ? FROM ? GROUP BY ? HAVING ? ORDER BY ?<br>
		> FROM ? INNER/LEFT/RIGHT JOIN ?? ON ?.?=??.??<br>
		> INSERT INTO ? (?, ?) SELECT ?, ? FROM ? WHERE ? ORDER BY ?<br>
		> UPDATE ? SET ? = ? WHERE ?<br>
		> DELETE * FROM ? WHERE ?<br>
		> TRANSFORM ? SELECT ? FROM ? GROUP BY ? PIVOT ?<br>
		> SELECT ? INTO ? FROM ? GROUP BY ?<br>
		<br>
		- Min(), Max(), Sum(), Avg(), Count(), StDev(), Var(), First(), Last()<br>
	  </td>
	 </tr>
	</table>
	</body>
	</html>
	<%
'	on error resume next
	conn.Close
	Set rs = nothing
	Set conn = nothing
'	on error goto 0
end if
%>
