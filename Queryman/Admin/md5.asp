<%@ Language=VBScript %>

<!-- #INCLUDE VIRTUAL="/Queryman/Admin/inclMD5.asp" -->

<%
if Session("QueryOK") = "safe" then
%>
<html>
<head>
<link rel=stylesheet type=text/css href=/Queryman/style.css>
</head>
<body bgcolor=white link=#aa0000 vlink=#aa0000 alink=#ff0000 topmargin=2 leftmargin=0 rightmargin=0>
<br><br><br><br>
<table border=0 cellpadding=0 cellspacing=0 align=center>
<%
Response.Write "<form name=CalculForm>" & VbCrlf
Response.Write "<tr><td>Enter&nbsp;</td><td><input type=text name=Enter size=50 class=box></td></tr>" & VbCrlf
Response.Write "<tr><td>hex  </td><td><input type=text name=hex size=50 class=box></td></tr>" & VbCrlf
Response.Write "<tr><td>b64> </td><td><input type=text name=b64 size=50 class=box></td></tr>" & VbCrlf
Response.Write "<tr><td>b64  </td><td><input type=text name=str size=50 class=box></td></tr>" & VbCrlf
Response.Write "<tr><td>&nbsp;</td><td><input type=button value=Calculate onClick=Calculate(); class=button></td></tr>" & VbCrlf
Response.Write "</form>" & VbCrlf

Response.Write "<script language=""Javascript"">" & VbCrlf
Response.Write "document.CalculForm.Enter.focus();" & VbCrlf
Response.Write "function Calculate() {" & VbCrlf
Response.Write "document.CalculForm.hex.value=hex_md5(document.CalculForm.Enter.value);" & VbCrlf
Response.Write "document.CalculForm.b64.value=b64_md5(document.CalculForm.Enter.value);" & VbCrlf
Response.Write "document.CalculForm.str.value=str_md5(document.CalculForm.Enter.value);" & VbCrlf
Response.Write "document.CalculForm.Enter.focus();" & VbCrlf
Response.Write "}" & VbCrlf
Response.Write "</script>" & VbCrlf
%>
</table>
</body></html>
<%
end if
%>

