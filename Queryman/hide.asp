<%@ LANGUAGE="VBSCRIPT" %>

<%
if Session("QueryOK") = "safe" then
	%>
	<frameset Rows="200,*,60" frameborder=0 border=1>
	<frame src="query.asp" name="query">
	<frame src="answer.asp" name="answer">
	<frame src="tables.asp" name="tables">
	</frameset>
	<%	
else
	if Request("User") <> empty and Request("Password") <> empty then
		Dim conn, rs, strConn
		strConn = "PROVIDER=Microsoft.Jet.OLEDB.4.0;DATA SOURCE=" & server.mappath("/data/user.mdb") & ";"
		Set conn= Server.CreateObject("ADODB.Connection")
		conn.Open strConn
		Set rs = Server.CreateObject("ADODB.Recordset")

		strSQL = "SELECT * FROM [QueryUser] " & _
				 "WHERE UserIsOnline=TRUE AND UserLogin='" & Request("User") & "' AND UserPassword='" & Request("Password") & "';"
		rs.Open strSQL, conn	

		if not rs.EOF then
			Session("QueryDB") = "/data/user.mdb"
			Session("QueryOK") = "safe"
			%>
			<frameset Rows="200,*,60" frameborder=0 border=1>
			<frame src="query.asp" name="query">
			<frame src="answer.asp" name="answer">
			<frame src="tables.asp" name="tables">
			</frameset>
			<%	
		end if

		rs.Close
		conn.Close
		
		set rs = nothing
		set conn = nothing

	else
		Session("QueryOK") = empty
		%>
<!-- #INCLUDE VIRTUAL="/Queryman/Admin/inclMD5.asp" -->
		<html>
		<head>
		<link rel=stylesheet type=text/css href=/queryman/style.css>
		</head>
		<body bgcolor=#333333>
		<center>
		<br><br><br><br><br>
		<form action=hide.asp method=post name=LogForm onSubmit=document.LogForm.Password.value=CodeMe(document.LogForm.Pass.value);document.LogForm.Pass.value='';>
		<input type=hidden name=Password>
		<table border=1 cellpadding=0 cellspacing=0 bordercolor=red bgcolor=white><tr><td>
		<table border=0>
		 <tr><td><b>User</b></td><td><input type=text name=User class=box></td></tr>
		 <tr><td><b>Password</b></td><td><input type=password name=Pass class=box></td></tr>
		 <tr><td></td><td align=center><input type=submit value="OK" class=button></td></tr>
		</table>
		</td></tr></table>
		</form>
		</center>
		</body>
		<script language="JavaScript">
		document.LogForm.User.focus();
		</script>
		</html>
		<%
	end if
end if
%>


