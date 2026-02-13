<%
Dim conConnexion, rs02, rs01, rs0, rs1, rs2, rs3, strSQL

Set conConnexion = Server.CreateObject("ADODB.Connection")
conConnexion.Open strConn
Set rs02 = Server.CreateObject("ADODB.Recordset")
Set rs01 = Server.CreateObject("ADODB.Recordset")
Set rs0 = Server.CreateObject("ADODB.Recordset")
Set rs1 = Server.CreateObject("ADODB.Recordset")
Set rs2 = Server.CreateObject("ADODB.Recordset")
Set rs3 = Server.CreateObject("ADODB.Recordset")
%>

