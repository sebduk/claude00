<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/Label.asp"-->
<!--#include VIRTUAL="/Include/FunctImg.asp"-->

<%
if Session(strUpload & "IsUser") <> true then
	Response.Redirect "/Gene/login.asp"
else
%>

<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
	Dim fso, fsoFolder, fsoItem, fsoFiles, fsoFile
	Set fso = CreateObject("Scripting.FileSystemObject")
	Set fsoFolder = fso.GetFolder(server.mappath(strDocument))
'	Set fsoFiles = fsoFolder.Files
	dim strFileN, strExtension, flgBgColor

	Response.Write "<br>"
	Response.Write "<table border=0 width=90% cellpadding=0 cellspacing=0 align=center>"
	Response.Write "<tr bgcolor=#cccccc>"
	Response.Write "<td>&nbsp;</td>"
	Response.Write "<td width=50% ><a href=lstDocs.asp?"
	if Request("s") = 1 and Request("o") = "u" then
		Response.Write "s=1&o=d"
	else
		Response.Write "s=1&o=u"
	end if
	Response.Write "><b>" & strFileName & "</b></a></td>"
	Response.Write "<td>&nbsp;</td>"
	Response.Write "<td><a href=lstDocs.asp?"
	if Request("s") = 2 and Request("o") = "u" then
		Response.Write "s=2&o=d"
	else
		Response.Write "s=2&o=u"
	end if
	Response.Write "><b>" & strDate & "</b></a></td>"
	Response.Write "<td>&nbsp;</td>"
'	Response.Write "<td><b>" & strParticipants & "</b></td>"
'	Response.Write "<td>&nbsp;</td>"
	Response.Write "<td align=right><b>" & strSize & "</b></td>"
	Response.Write "<td>&nbsp;</td>"
	Response.Write "<td align=right><b>" & strUploaded & "</b></td>"
	Response.Write "<td>&nbsp;</td>"
	Response.Write "</tr>"

	strSQL = "SELECT * FROM Photo " & _
			 "WHERE Right(NomPhoto, 3)<>'jpg' AND Right(NomPhoto, 3)<>'gif' "
	if Request("s") = 1 and Request("o") = "u" then
		strSQL = strSQL & "ORDER BY NomPhoto, Date"
	elseif Request("s") = 1 and Request("o") = "d" then
		strSQL = strSQL & "ORDER BY NomPhoto DESC, Date"
	elseif Request("s") = 2 and Request("o") = "d" then
		strSQL = strSQL & "ORDER BY Date DESC, NomPhoto"
	else
		strSQL = strSQL & "ORDER BY Date, NomPhoto"
	end if
	rs0.Open strSQL, conConnexion

	flgBgColor = false
	while not rs0.EOF

		Set fsoFile = fsoFolder.Files(rs0("NomPhoto"))

		if flgBgColor then
			Response.Write "<tr valign=top bgcolor=#eeeeee>"
'			flgBgColor = false
		else
			Response.Write "<tr valign=top>"
'			flgBgColor = true
		end if

		strFileN = Left(rs0("NomPhoto"), len(rs0("NomPhoto")) - 4)
'		strFileN = replace(Left(rs0("NomPhoto"), len(rs0("NomPhoto")) - 4), " ", "&nbsp;")
		strExtension = Right(rs0("NomPhoto"), 3)
		Response.Write "<td align=center>"
		select case strExtension
			case "doc", "mdb", "pdf", "ppt", "pps", "txt", "xls", "zip"
				Response.Write "<img src=/Image/Icon/" & strExtension & ".gif>&nbsp;"
			case else
				Response.Write "<img src=/Image/Icon/other.gif>&nbsp;"
		end select
		Response.Write "</td>"

		Response.Write "<td width=150>"
		Response.Write "<a href=""" & strDocument & rs0("NomPhoto") & """><b>"
		Response.Write strFileN
		Response.Write "</b></a></td>"
		Response.Write "<td>&nbsp;</td>"
		Response.Write "<td><b>" & rs0("Date") & "</b></td>"
		Response.Write "<td>&nbsp;</td>"

		Response.Write "<td align=right>" & FormatSize(fsoFile) & "&nbsp;</td>"
		Response.Write "<td>&nbsp;</td>"
		Response.Write "<td align=right>" & FormatDate(fsoFile) & "</td>"
		Response.Write "<td>&nbsp;</td>"

		Response.Write "</tr>"

		if flgBgColor then
			Response.Write "<tr valign=top bgcolor=#eeeeee>"
			flgBgColor = false
		else
			Response.Write "<tr valign=top>"
			flgBgColor = true
		end if
		Response.Write "<td>&nbsp;</td>"
		Response.Write "<td>" & rs0("DescrPhoto") & "</td>"
		Response.Write "<td>&nbsp;</td>"

		strSQL = "SELECT Nom, Prenom, Personne.IDPersonne " & _
				 "FROM LienPhotoPerso INNER JOIN Personne ON LienPhotoPerso.IdPersonne=Personne.IDPersonne " & _
				 "WHERE LienPhotoPerso.IdPhoto=" & rs0("IDPhoto") & " " & _
				 "ORDER BY SortKey, Nom, Prenom, DtNaiss"
		rs1.Open strSQL, conConnexion
		Response.Write "<td colspan=6>"
		if not rs1.EOF then
			Response.Write	"<a href=bio.asp?ID=" & rs1("IDPersonne") & ">" & rs1("Prenom") & _
							"&nbsp;" & rs1("Nom") & "</a>"
			rs1.MoveNext
			while not rs1.EOF
				Response.Write	", <a href=bio.asp?ID=" & rs1("IDPersonne") & ">" & _
								rs1("Prenom") & "&nbsp;" & rs1("Nom") & "</a>"
				rs1.MoveNext
			wend
			Response.Write ".<br>"
		end if
		Response.Write "</td>"
		rs1.Close

		Response.Write "</tr>"

		rs0.MoveNext
	wend

	Response.Write "</table>"

	rs0.Close

	Set fsoFolder = nothing
	Set fsoFile = nothing
'	Set fsoFiles = nothing
	Set fso = nothing
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->

<%
end if
%>

<!--#include VIRTUAL="/Include/DAOFooter.asp"-->

<%
function FormatSize(objFile)
	dim dblSize
	dblSize = objFile.size
	if dblSize < 512 then dblSize = 1024
	FormatSize = formatNumber(dblSize/1024, 0) & "&nbsp;KB"
end function

function FormatDate(objFile)
	dim strDate
	strDate = objFile.DateLastModified
	FormatDate = Format(day(strDate), "00") & "/" & _
				 Format(month(strDate), "00") & "/" & _
				 Format(year(strDate), "0000")
end function
%>