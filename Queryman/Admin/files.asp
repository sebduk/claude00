<%@ LANGUAGE="VBSCRIPT" %>

<%
if Session("QueryOK") = "safe" then

	strHeader = "Intranet - File Library"
	strBaseFolder = "/"

	'Page header
	''''''''''''''''''''''''''''''''
	Response.Write "<html>" & VbCrlf
	Response.Write "<head>" & VbCrlf
	Response.Write "<title>QueryMan</title>" & VbCrlf
	Response.Write "<link rel=stylesheet type=text/css href=/Queryman/style.css></head>" & VbCrlf
	Response.Write "<body topmargin=0 leftmargin=0 rightmargin=0>" & VbCrlf

	'table
	''''''''''''''''''''''''''''''''
	Response.Write "<table border=0 width=100% height=100% cellspacing=0 cellpadding=0>" & VbCrlf

	'Menu
	''''''''''''''''''''''''''''''''
	Response.Write "<tr>" & VbCrlf
	Response.Write "<td valign=top height=*>"
	''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''


	if request("folder") <> "" then
		strPath = request("folder")
	else
		strPath = strBaseFolder 
	end if
	if left(strPath, len(strBaseFolder)) <> strBaseFolder then strPath = strBaseFolder
	strPath = Replace(strPath, "//", "/")
	
	Dim fso, fsoFolder, fsoItem, fsoSubFolders, fsoFiles
	Set fso = CreateObject("Scripting.FileSystemObject")
	Set fsoFolder = fso.GetFolder(server.mappath(strPath))
	Set fsoFiles = fsoFolder.Files
	Set fsoSubFolders = fsoFolder.SubFolders
	
	Response.Write "<table border=0 width=80% cellpadding=0 cellspacing=5>"

	Response.Write "<tr bgcolor=#999999>"
	Response.Write "<td><b>File</b></td>"
	Response.Write "<td><b>Size</b></td>"
	Response.Write "<td><b>Last Updated</b></td>"
	Response.Write "<td colspan=2>&nbsp;</td>"
	Response.Write "</tr>"

	if strPath <> strBaseFolder then
		Pos = inStrRev(strPath, "/")
		if pos <= 1 then
			strPrevPath = strBaseFolder
		else
			strPrevPath = left(strPath, Pos - 1)
		end if
		Response.Write "<tr>"
		Response.Write "<td>"
		Response.Write "<a href=""files.asp?folder=" & strPrevPath & """>"
		Response.Write "<img src=/Queryman/Icons/folderUp.gif align=absmiddle border=0> " 
		Response.Write "<b>..</b></a></td>"
		Response.Write "<td colspan=4>&nbsp;</td>"
		Response.Write "</tr>"
	end if

	for each fsoItem in fsoSubFolders
		if Request("DEL") = fsoItem.name then
			fsoItem.delete
		else
			Response.Write "<tr>"
			Response.Write "<td>"
			Response.Write "<a href=""files.asp?folder=" & strPath & "/" & fsoItem.name & """>"
			Response.Write "<img src=/Queryman/Icons/folder.gif align=absmiddle border=0> "
			Response.Write "<b>" & fsoItem.name & "</b></td>"
			Response.Write "<td align=right>" & formatnumber(fsoItem.size/1024, 0) & "&nbsp;KB</td>"
			Response.Write "<td>" & replace(fsoItem.DateLastModified, " ", "&nbsp;") & "</td>"
			Response.Write "<td><a href=""javascript:openEdit('Folder', '" & fsoItem.name & "')"">Edit</a></td>"
			Response.Write "<td>&nbsp;</td>"
			Response.Write "</tr>"
		end if
	next
	for each fsoItem in fsoFiles
		if Request("DEL") = fsoItem.name then
			fsoItem.delete
		else
			Response.Write "<tr>"
			Response.Write "<td>"
			Response.Write "<a href=""" & strPath & "/" &  fsoItem.name & """ target=_blank>"
			Response.Write "<img src=/Queryman/Icons/"

			select case Lcase(left(strReverse(fsoItem.name), 3))
				case "cod"
					Response.Write "doc.gif "
				case "fig"
					Response.Write "gif.gif "
				case "mth", "lmt", "psa"
					Response.Write "htm.gif "
				case "gpj"
					Response.Write "jpg.gif "
				case "bdm"
					Response.Write "mdb.gif "
				case "fdp"
					Response.Write "pdf.gif "
				case "tpp"
					Response.Write "ppt.gif "
				case "txt"
					Response.Write "txt.gif "
				case "slx"
					Response.Write "xls.gif "
				case "piz"
					Response.Write "zip.gif "
				case else
					Response.Write "other.gif "
			end select

			Response.Write " align=absmiddle border=0> "
			Response.Write "<b>" & fsoItem.name & "</b></td>"
			Response.Write "<td align=right>" & formatNumber(fsoItem.size/1024, 0) & "&nbsp;KB</td>"
			Response.Write "<td>" & replace(fsoItem.DateLastModified, " ", "&nbsp;") & "</td>"
			Response.Write "<td><a href=""javascript:openEdit('File', '" & fsoItem.name & "')"">Edit</a></td>"
			Response.Write "<td><a href=""javascript:if (confirm('Do you want to delete this file permanently?')) window.location = 'files.asp?DEL=" & fsoItem.name & "&Folder=" & strPath & "'"">Delete</a></td>"
			Response.Write "</tr>"
		end if
	next

	Response.Write "<tr bgcolor=#999999>"
	Response.Write "<td colspan=5 align=center><b><a href=""files.asp?folder=" & strPath & """>Refresh</a> | <a href=""javascript:openUpload()"">Upload files</a> | <a href=""javascript:openEdit('Folder', 'New')"">New folder</a></b></td>"
	Response.Write "</tr>"

	Response.Write "</table>"

	Response.Write "<script language=""Javascript"">"
	Response.Write "function openUpload(){newWindow=window.open( 'filesUp.asp?Folder=" & strPath & "' , """ & session("KOpenWindow") & "Upload"", ""toolbar=0,location=0,directories=0,status=0,menubar=0,scrollbars=1,resizable=0,copyhistory=0,width=500,height=175"");}"
	Response.Write "</script>"
	Response.Write "<script language=""Javascript"">"
	Response.Write "function openEdit(strType, strName){newWindow=window.open( 'filesEdit.asp?Folder=" & strPath & "&Type=' + strType + '&Name=' + strName, """ & session("KOpenWindow") & "Upload"", ""toolbar=0,location=0,directories=0,status=0,menubar=0,scrollbars=1,resizable=0,copyhistory=0,width=500,height=175"");}"
	Response.Write "</script>"


	Response.Write "</td><tr>"
	Response.Write "</table>"


	'page footer
	'''''''''''''''''''''''''''''''
	Response.Write "</body></html>"
	'''''''''''''''''''''''''''''''

else 
	Session("From") = Request.ServerVariables("PATH_INFO")
	Response.Redirect "/login.asp"
end if

%>
