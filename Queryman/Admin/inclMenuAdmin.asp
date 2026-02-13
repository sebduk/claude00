<%
'Page header
''''''''''''''''''''''''''''''''
Response.Write "<html>" & VbCrlf
Response.Write "<head>" & VbCrlf
Response.Write "<title>QueryMan</title>" & VbCrlf
Response.Write "<link rel=stylesheet type=text/css href=/Queryman/style.css></head>" & VbCrlf
Response.Write "<body topmargin=0 leftmargin=0 rightmargin=0>" & VbCrlf

'table
''''''''''''''''''''''''''''''''
Response.Write "<table border=0 width=100% height=100% cellspacing=0 cellpadding=0>" & VbCrlf

'Menu
''''''''''''''''''''''''''''''''
Response.Write "<tr>" & VbCrlf
Response.Write "<td valign=top width=160 bgcolor=#888888>" & VbCrlf

Response.Write "<br><br>" & VbCrlf
Response.Write "<li><a href=/QueryMan/Admin/newsList.asp>Admin News</a></li>" & VbCrlf
Response.Write "<li><a href=/QueryMan/Admin/startPaginaList.asp>Admin StartPagina</a></li>" & VbCrlf
Response.Write "<li><a href=/QueryMan/Admin/userList.asp>Admin Users</a></li>" & VbCrlf
Response.Write "<li><a href=/QueryMan/Admin/groupList.asp>Admin Groups</a></li>" & VbCrlf
Response.Write "<li><a href=/QueryMan/Admin/projectList.asp>Admin Projects</a></li>" & VbCrlf
Response.Write "<li><a href=/QueryMan/Admin/taskList.asp>Admin Tasks</a></li>" & VbCrlf
Response.Write "<li><a href=/QueryMan/Admin/mailingList.asp>Admin Mailings</a></li>" & VbCrlf
Response.Write "<li><a href=/QueryMan/Admin/pressList.asp>Admin Press</a></li>" & VbCrlf
Response.Write "<li><a href=/QueryMan/Admin/files.asp>Admin Files</a></li>" & VbCrlf

Response.Write "<br><br>" & VbCrlf
Response.Write "<li><a href=/QueryMan/Admin/monitor.asp>Admin Monitor</a></li>" & VbCrlf
Response.Write "<li><a href=/QueryMan/Admin/delete.asp>Admin Delete</a></li>" & VbCrlf

Response.Write "</td>" & VbCrlf
''''''''''''''''''''''''''''''''
%>