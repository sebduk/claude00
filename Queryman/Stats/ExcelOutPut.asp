<%@ LANGUAGE="VBSCRIPT" %>
<% Option Explicit %>
<%
Dim ConnectDB, rs, SQL, i, j

Set ConnectDB = Server.CreateObject("ADODB.Connection")
ConnectDB.Open "DSN=DSM"
Set rs = Server.CreateObject("ADODB.Recordset")

Response.ContentType = "application/vnd.ms-excel"%>ID;PWXL;N;E
P;PGeneral
P;P0
P;P0.00
P;P#,##0
P;P#,##0.00
P;P#,##0_);;\(#,##0\)
P;P#,##0_);;[Red]\(#,##0\)
P;P#,##0.00_);;\(#,##0.00\)
P;P#,##0.00_);;[Red]\(#,##0.00\)
P;P"$"#,##0_);;\("$"#,##0\)
P;P"$"#,##0_);;[Red]\("$"#,##0\)
P;P"$"#,##0.00_);;\("$"#,##0.00\)
P;P"$"#,##0.00_);;[Red]\("$"#,##0.00\)
P;P0%
P;P0.00%
P;P0.00E+00
P;P##0.0E+0
P;P#\ ?/?
P;P#\ ??/??
P;Pm/d/yy
P;Pd\-mmm\-yy
P;Pd\-mmm
P;Pmmm\-yy
P;Ph:mm\ AM/PM
P;Ph:mm:ss\ AM/PM
P;Ph:mm
P;Ph:mm:ss
P;Pm/d/yy\ h:mm
P;Pmm:ss
P;Pmm:ss.0
P;P@
P;P[h]:mm:ss
P;P_("$"* #,##0_);;_("$"* \(#,##0\);;_("$"* "-"_);;_(@_)
P;P_(* #,##0_);;_(* \(#,##0\);;_(* "-"_);;_(@_)
P;P_("$"* #,##0.00_);;_("$"* \(#,##0.00\);;_("$"* "-"??_);;_(@_)
P;P_(* #,##0.00_);;_(* \(#,##0.00\);;_(* "-"??_);;_(@_)
P;FArial;M200
P;FArial;M200
P;FArial;M200
P;FArial;M200
F;P0;DG0G10;M255
B;Y10;X2;D0 0 9 1
O;D;V0;K47;G100 0.001
F;W1 256 11<%
																
SQL = "SELECT * FROM Connect"
rs.Open SQL, ConnectDB											

If Not rs.EOF Then
%>
C;Y1;X1;K"IDConnect"
C;X2;K"ConnectWhen"
C;X3;K"ConnectFrom"
<%
	i=2
	While not rs.EOF
		for j = 1 to 3
			Select Case rs(j-1).type
				case 2, 3, 4, 5   'Number
					Response.Write "C;Y" & i & ";X" & j & ";K" & rs(j-1) & vbCrlf
					
				case 135 'Date
'					if not IsNull(rs(j-1)) then				Solve Date pb and Memo pb -§§§§§§§§§§-
'						Response.Write "F;P20" & vbCrlf
'						Response.Write "C;Y" & i & ";X" & j & ";K" & CDbl(DateSerial(Year(rs(j-1)), Month(rs(j-1)), Day(rs(j-1)))) & vbCrlf
'					end if				
					Response.Write "C;Y" & i & ";X" & j & ";K""" & rs(j-1) & """" & vbCrlf
				case 200 'Text
					Response.Write "C;Y" & i & ";X" & j & ";K""" & rs(j-1) & """" & vbCrlf
					
				case 201 'Memo
					Response.Write "C;Y" & i & ";X" & j & ";K""" & Left(rs(j-1),250) & """" & vbCrlf
					
				case 11 'Boolean
					Response.Write "C;Y" & i & ";X" & j & ";K" & Ucase(rs(j-1)) & vbCrlf
					
				case Else
					Response.Write "C;Y" & i & ";X" & j & ";K""Prob:" & rs(j-1).name & "(" & rs(j-1).Type & ")""" & vbCrlf
			End Select
		next
		i=i+1
		rs.MoveNext
	Wend
End If

rs.Close
Set rs = Nothing

%>E
