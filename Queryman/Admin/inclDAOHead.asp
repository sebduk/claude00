<%
Dim conn, rs, rs2, rs3, rs4, rs5, strConn
strConn = "PROVIDER=Microsoft.Jet.OLEDB.4.0;DATA SOURCE=" & server.mappath(session("QueryDB")) & ";"
Set conn= Server.CreateObject("ADODB.Connection")
conn.Open strConn
Set rs = Server.CreateObject("ADODB.Recordset")
Set rs2 = Server.CreateObject("ADODB.Recordset")
Set rs3 = Server.CreateObject("ADODB.Recordset")
Set rs4 = Server.CreateObject("ADODB.Recordset")
Set rs5 = Server.CreateObject("ADODB.Recordset")
%>