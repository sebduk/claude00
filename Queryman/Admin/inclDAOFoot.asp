<%
conn.Close
Set rs = nothing
Set rs2 = nothing
Set rs3 = nothing
Set rs4 = nothing
Set rs5 = nothing
Set conn = nothing

Sub OpenRS(strSQL)
	'Response.Write strSQL & "<br>"
	rs.Open strSQL, conn 
End Sub
Sub OpenFullRS(strSQL)
	rs.Open strSQL, conn, 2, 3 
End Sub

Sub OpenRS2(strSQL)
	rs2.Open strSQL, conn 
End Sub
Sub OpenFullRS2(strSQL)
	rs2.Open strSQL, conn, 2, 3
End Sub

Sub OpenRS3(strSQL)
	rs3.Open strSQL, conn 
End Sub
Sub OpenFullRS3(strSQL)
	rs3.Open strSQL, conn, 2, 3
End Sub

Sub OpenRS4(strSQL)
	rs4.Open strSQL, conn 
End Sub
Sub OpenFullRS4(strSQL)
	rs4.Open strSQL, conn, 2, 3
End Sub

Sub OpenRS5(strSQL)
	rs5.Open strSQL, conn 
End Sub
Sub OpenFullRS5(strSQL)
	rs5.Open strSQL, conn, 2, 3
End Sub

Sub OpenFullRSRecurse(strSQL)
	rsRecurse.Open strSQL, conn, 2, 3 
End Sub
%>