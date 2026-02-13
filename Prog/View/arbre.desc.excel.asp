<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->


<%
Dim lngID, lngIDC, i, j, strSvrName
Dim ParamTable
Public tabArbre()
Dim intCurCol
Public intMaxCol
Public intCurRow
Public intMaxRow

Redim tabArbre(40, 0)

if Request("IDPerso") = Empty then
	lngID = 1
else
	lngID = Request("IDPerso")
end if

SetStructure lngID

strSvrName = Request.ServerVariables("SERVER_NAME")
Response.AddHeader "content-disposition","inline; attachment; filename=" & chr(34) & strSvrName & ".xls" & chr(34)
Response.ContentType = "application/vnd.ms-excel"%>ID;PWXL;N;E
P;PGeneral
P;P0
P;P0.00
P;P#,##0
P;P#,##0.00
P;P#,##0;;\-#,##0
P;P#,##0;;[Red]\-#,##0
P;P#,##0.00;;\-#,##0.00
P;P#,##0.00;;[Red]\-#,##0.00
P;P"$"#,##0;;\-"$"#,##0
P;P"$"#,##0;;[Red]\-"$"#,##0
P;P"$"#,##0.00;;\-"$"#,##0.00
P;P"$"#,##0.00;;[Red]\-"$"#,##0.00
P;P0%
P;P0.00%
P;P0.00E+00
P;P##0.0E+0
P;P#" "?/?
P;P#" "??/??
P;Pdd/mm/yy
P;Pdd\-mmm\-yy
P;Pdd\-mmm
P;Pmmm\-yy
P;Ph:mm\ AM/PM
P;Ph:mm:ss\ AM/PM
P;Phh:mm
P;Phh:mm:ss
P;Pdd/mm/yy\ hh:mm
P;Pmm:ss
P;Pmm:ss.0
P;P@
P;P[h]:mm:ss
P;P_-"$"* #,##0_-;;\-"$"* #,##0_-;;_-"$"* "-"_-;;_-@_-
P;P_-* #,##0_-;;\-* #,##0_-;;_-* "-"_-;;_-@_-
P;P_-"$"* #,##0.00_-;;\-"$"* #,##0.00_-;;_-"$"* "-"??_-;;_-@_-
P;P_-* #,##0.00_-;;\-* #,##0.00_-;;_-* "-"??_-;;_-@_-
P;P"Yes";;"Yes";;"No"
P;P"True";;"True";;"False"
P;P"On";;"On";;"Off"
P;FArial;M200
P;FArial;M200
P;FArial;M200
P;FArial;M200
P;EVerdana;M160;L9
P;EArial;M160
F;P0;DG0G8;SM6;M225
B;Y268;X12;D0 1 267 11
O;L;D;V0;K47;G100 0.001
F;W1 1 1
F;W2 2 20
F;W3 3 1
F;W4 4 20
F;W5 5 1
F;W6 6 20
F;W7 7 1
F;W8 8 20
F;W9 9 1
F;W10 10 20
F;W11 11 1
F;W12 12 20
F;W13 13 1
F;W14 14 20
F;W15 15 1
F;W16 16 20
F;W17 17 1
F;W18 18 20
F;W19 19 1
F;W20 20 20
F;W21 21 1
<%
for i = 1 to intMaxRow
	for j = 1 to intMaxCol
		if tabArbre(j, i) <> "" then
			Response.Write "C;Y" & i & ";X" & j * 2 & ";K""" & tabArbre(j, i) & """" & vbCrlf
		end if
	next
next
Response.Write "E" & vbCrlf
%>

<!--#include VIRTUAL="/Include/DAOFooter.asp"-->
<!--#include VIRTUAL="/Include/FunctDesc.asp"-->
