<!--#include VIRTUAL=/Include/CodeHeader.asp-->
<%
strConn = "PROVIDER=Microsoft.Jet.OLEDB.4.0;DATA SOURCE=" & server.mappath("/Data/user.mdb") & ";"
%>
<!--#include VIRTUAL=/Include/DAOHeader.asp-->
<%
Dim strUsedImg

strSQL = "SELECT HelpImage " & _
		 "FROM [Help] " & _
		 "WHERE NOT HelpImage IS NULL"
rs0.Open strSQL, conConnexion, 2, 3
strUsedImg = "|"
while not rs0.eof
	strUsedImg = strUsedImg & rs0("HelpImage") & "|"
	rs0.MoveNext
wend
rs0.Close

Response.Write "<html>"
Response.Write "<head>"
Response.Write "<title>www.see-our-family.com</title>"
Response.Write "<link rel=stylesheet type=text/css href=/style.css>"
Response.Write "</head>"
Response.Write "<body topmargin=0 leftmargin=0 rightmargin=0 bottommargin=0>"

Response.Write "<a href=helpPict.asp><b>Reload</b></a><br>"

if Request("img") <> empty then
	Response.Write Request("img") & "<br>"
	Response.Write "<img src=""" & Request("img") & """ border=1><br><br>"
else
	Dim fso, fsoFolder, fsoItem, fsoFiles, intPos, arrPicts()
	Set fso = CreateObject("Scripting.FileSystemObject")
	Set fsoFolder = fso.GetFolder(server.mappath("/Image/Help/"))
	Set fsoFiles = fsoFolder.Files

	for each fsoItem in fsoFiles
		if right(fsoItem.name, 4) <> ".asp" then
			if inStr(strUsedImg, fsoItem.name) > 0 then
				Response.Write fsoItem.name & " "
				Response.Write "<a href=""helpPict.asp?img=" & fsoItem.name & """>" & _
							   "<i>Used</i></a><br>"
			else
				Response.Write fsoItem.name & "<br>"
				Response.Write "<img src=""" & fsoItem.name & """ border=1><br><br>"
			end if
		end if
	next

	Set fsoFiles = nothing
	Set fso = nothing
end if

Response.Write "<a href=helpPict.asp><b>Reload</b></a><br>"

Response.Write "</body>"
Response.Write "</html>"
%>
<!--#include VIRTUAL=/Include/DAOFooter.asp-->
