<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
Dim lngID, lngIDC, i, j
Dim ParamTable
Public tabArbre()
Public intMaxCol
Public intMaxRow

Redim tabArbre(40, 0)

if Request("IDPerso") = Empty then
	lngID = 1
else
	lngID = Request("IDPerso")
end if

ParamTable = "<table border=1 cellpadding=0 cellspacing=0>"

SetStructure lngID

Response.Write ParamTable
Response.Write "<tr valign=top align=center>"
for j = 1 to intMaxCol
	Response.Write "<td><b>" & j & "</b></td>"
next
Response.Write "</tr>"
for i = 1 to intMaxRow
	Response.Write "<tr valign=top align=center>"
	for j = 1 to intMaxCol
		if tabArbre(j, i) <> "" then
			Response.Write "<td>" & Replace(server.HTMLEncode(tabArbre(j, i)), " ", "&nbsp;")  & "</td>"
		else
			Response.Write "<td>&nbsp;</td>"
		end if
	next
	Response.Write "</tr>"
next
Response.Write "</table>"

%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->
<!--#include VIRTUAL="/Include/DAOFooter.asp"-->
<!--#include VIRTUAL="/Include/FunctDesc.asp"-->
