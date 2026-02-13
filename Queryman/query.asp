<%@ LANGUAGE="VBSCRIPT" %>

<%
if Session("QueryOK") = "safe" then
	%>
	<html>
	<head>
	<link rel=stylesheet type=text/css href=/queryman/style.css>
	</head>
	<body bgcolor=#888888 topmargin=1 leftmargin=1>
	<center>
	<table border=0>
	 <tr>

	<%
	for i = 1 to 3
	%>
		<form Action=answer.asp target=answer method=post>
		 <td align=center>
		  <textarea cols=36 rows=11 name=MyQuery class=box></textarea><br>
		  <input type=submit value="Submit SQL (<%=i%>)" class=button>
		 </td>
		</form>
	<%
	next
	%>

	<form Action=form.asp target=answer method=post>
	 <td align=center>
	  <textarea cols=36 rows=11 name=MyQuery class=box></textarea><br>
	  <input type=submit value="Submit SQL (Form)" class=button>
	 </td>
	</form>

	 </tr>
	</table>
	</center>
	</body>
	</html>
	<%
end if
%>