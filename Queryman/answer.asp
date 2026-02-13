<%@ LANGUAGE="VBSCRIPT" %>

<!-- #INCLUDE VIRTUAL="/Queryman/Admin/inclDAOHead.asp" -->

<%
if Session("QueryOK") = "safe" then
		'QUERY FROM HEADER OR FROM FOOTER
	if request("MyQuery") <> EMPTY or Request("MyTable") <> EMPTY then

		'DESIGN QUERY
		if request("MyQuery") <> EMPTY then
			strSQL = LTrim(Request("MyQuery"))
		else
			strSQL = "SELECT * FROM [" & Request("MyTable") & "]"
		end if

		TestSQL = ucase(strSQL)
		if Left(TestSQL, 7) = "HTTP://" then
			Response.Redirect strSQL
		elseif Left(TestSQL, 7) = "STRUCT " then
		%>
		<!--#include VIRTUAL="/QueryMan/answerStruct.asp" -->
		<%
		elseif Left(TestSQL, 5) = "SORT " then
		%>
		<!--#include VIRTUAL="/QueryMan/answerSort.asp" -->
		<%
		elseif (Left(TestSQL, 7) = "SELECT " AND InStr(TestSQL, " INTO ")=0) OR Left(TestSQL, 10) = "TRANSFORM " then
		%>
		<!--#include VIRTUAL="/QueryMan/answerView.asp" -->
		<%
		else
		%>
		<!--#include VIRTUAL="/QueryMan/answerDo.asp" -->
		<%
		end if

		'CLOSE AND RELEASE OBJECTS
	else
		%>
		<html>
		<head>
		<link rel=stylesheet type=text/css href=style.css>
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
end if
%>

<!-- #INCLUDE VIRTUAL="/Queryman/Admin/inclDAOFoot.asp" -->
