<%
if KTitle = "" then KTitle = session("KTitle")

'page header
''''''''''''''''''''''''''''''''''''''''
Response.Write "<html>" & VbCrlf
Response.Write "<head>" & VbCrlf
Response.Write "<title>" & KTitle & "</title>" & VbCrlf
Response.Write "<link rel=stylesheet type=text/css href=/QueryMan/style.css></head>" & VbCrlf
Response.Write "<body topmargin=0 leftmargin=0 rightmargin=0 onLoad=window.focus();>" & VbCrlf
''''''''''''''''''''''''''''''''''''''''
%>
