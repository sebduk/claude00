<%@ LANGUAGE="VBSCRIPT" %>

<%	'QUERY FROM HEADER OR FROM FOOTER
if request("MyQuery") <> EMPTY and Request("MyDSN") <> EMPTY and (Request("MyText") <> EMPTY or Request("MyTitle") <> EMPTY) then

	'DECLARE AND OPEN OBJECTS
	Set conConnexion = Server.CreateObject("ADODB.Connection")
	conConnexion.Open Request("MyDSN")
	Set rs = Server.CreateObject("ADODB.Recordset")

	'DESIGN QUERY
	strSQL = LTrim(Request("MyQuery"))

	rs.Open strSQL, conConnexion
	
	if not rs.EOF then
%>
<html>
<head>
<link rel=stylesheet type=text/css href=/queryman/style.css>
</head>
<body>
<center>

<form action=Send2.asp method=post>
<Table border=1>
 <tr valign=top>
<%
for i = 0 to rs.fields.count - 1
	response.write "<td><b>" & rs(i).name & "</td>" & VbCrlf
next

	response.write "<td><b>Message</b></td><td>&nbsp;</td></tr>" & VbCrlf

		j=1
		while not rs.EOF
			response.write "<tr valign=top>" & VbCrlf
			
			for i = 0 to rs.fields.count - 1
				if UCase(rs(i).Name) = "EMAIL" Then
					response.write "<td><input type=text size=30 name=Email" & j & " value=""" & rs(i) & """>"
					if InStr(rs(i), " ") > 0 then Response.Write "<br><font color=red>Space in Email or Multiple Emails</font>"
					if InStr(rs(i), ",") > 0 then Response.Write "<br><font color=red>Comma in Email or Multiple Emails</font>"
					if InStr(rs(i), ";") > 0 then Response.Write "<br><font color=red>Semicolon in Email or Multiple Emails</font>"
					if isnull(rs(i)) or Trim(rs(i))="" then Response.Write "<br><font color=red>Empty Email</font>"
					response.write "</td>" & VbCrlf
				else
					response.write "<td>" & rs(i) & "</td>" & VbCrlf
				end if
			next
			
			strText = Request("MyText")	& " "
			Pos1 = Instr(strText, "[")
			while Pos1 <> 0
				Pos2 = Instr(Pos1,strText, "]")
				
				strText = Left(strText, Pos1 - 1) & rs(Mid(strText,Pos1 + 1, Pos2 - Pos1 - 1)) & Mid(strText, Pos2 + 1)
				
				Pos1 = Instr(Pos1,strText, "[")
			wend			
			response.write "<td><input type=text name=Title" & j & " value=""" & Request("MyTitle") & """><br>"
			response.write "<textarea cols=20 rows=5 name=Text" & j & ">" & strText & "</textarea></td>" & VbCrlf
			response.write "<td><input type=checkbox name=X" & j & " checked></td>" & VbCrlf
	
			rs.MoveNext
			j=j+1
			response.write "</tr>" & VbCrlf
		wend
%>
</Table>

<input type=submit value=Submit>
</form>

</center>
</body>
</html>
<%
	end if

	'CLOSE AND RELEASE OBJECTS
	Set rs = Nothing
	conConnexion.close
	Set conConnexion = Nothing
else
%>

<html>
<head>
<link rel=stylesheet type=text/css href=/queryman/style.css>
</head>
<body>
<center>
<br><br><br>
Hello <%=Request.ServerVariables("REMOTE_ADDR")%><br>
</center>
</body>
</html>

<%
end if
%>
