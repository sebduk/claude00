<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%

Dim fso, fsoFolder, fsoItem, fsoSubFolders, fsoFiles
Dim arrFolders(), x

select case Request("todo")
	case "update"
		Set fso = CreateObject("Scripting.FileSystemObject")
		on error resume next
		fso.MoveFolder server.mappath(strImage & Request("old")), _
					   server.mappath(strImage & Request("folder"))
		on error goto 0
		UpdateDB Request("old"), Request("folder")
		set fso = nothing
	case "delete"
		Set fso = CreateObject("Scripting.FileSystemObject")
		Set fsoFolder = fso.GetFolder(server.mappath(strImage))
		Set fsoSubFolders = fso.GetFolder(server.mappath(strImage & Request("Folder")))
		fsoSubFolders.delete
		Set fsoSubFolders = nothing
		Set fsoFolder = nothing
		set fso = nothing
	case "move"
		Set fso = CreateObject("Scripting.FileSystemObject")
		for each x in Request.Form
			if left(x, 2) = "X_" then _
				MoveFile mid(x, 3), Request("folder")
		next
		set fso = nothing
end select

Response.Write "<p><b>"
Response.Write "Manage Folders"
Response.Write "</b></p>"

Response.Write "<form action=photoFolderMan.asp method=post>"

if Request("folder") <> empty and Request("todo") <> "delete" then
	Response.Write "<input type=hidden name=todo value=update>"
	Response.Write "<input type=hidden name=old value=""" & Request("folder") & """>"
	Response.Write "<input type=text name=folder value=""" & Request("folder") & """ size=60 style={width=250pt} class=box>"
	Response.Write "<input type=submit value=update class=box>"
else
	Response.Write "<input type=hidden name=todo value=add>"
	Response.Write "<input type=text name=folder size=60 style={width=250pt} class=box>"
	Response.Write "<input type=submit value=add class=box>"
	if Request("todo") = "delete" then Response.Write "<br><b>Deleted</b>"
end if

Response.Write "</form>"

LoadFoldList
ShowFoldList

'Response.Write "<p><b>PS. In case of problem send your folder names to <a href=mailto:sebduk@gmail.com class=BLink>sebduk@gmail.com</a>, they will be added ASAP.</b></p>"

Response.Write "<p><a href=photoList.asp target=left>&lt;&lt;&lt; Refresh the file list &lt;&lt;&lt;</a></p>"

if Request("folder") <> empty then 
	Response.Write "<form action=photoFolderMan.asp method=post>"
	Response.Write "<input type=hidden name=todo value=move>"
	ShowFiles Request("folder")
	ShowFolderDrop
	Response.Write "<input type=submit value=""move to"" class=box>"
	Response.Write "</form>"
end if

sub LoadFoldList
	Dim fso, fsoFolder, fsoItem, fsoSubFolders, fsoFiles, strID, strTN, strExt
	Set fso = CreateObject("Scripting.FileSystemObject")
	Set fsoFolder = fso.GetFolder(server.mappath(strImage))
	Set fsoSubFolders = fsoFolder.SubFolders
	redim arrFolders(1, 0)
	
	for each fsoItem in fsoSubFolders
		if left(fsoItem.name, 1) <> "_" then
			redim preserve arrFolders(1, ubound(arrFolders, 2) + 1)
			arrFolders(0, ubound(arrFolders, 2)) = fsoItem.name
			arrFolders(1, ubound(arrFolders, 2)) = fsoItem.size
		end if
	next

	Set fsoFolder = nothing
	Set fsoSubFolders = nothing
	Set fso = nothing
end sub

sub ShowFoldList
	dim i
	Response.Write "<b><a href=photoFolderMan.asp?folder=home>Home</a></b><br>"
	
	for i = 1 to ubound(arrFolders, 2)
		Response.Write "&gt; <a href=""photoFolderMan.asp?folder=" & arrFolders(0, i) & _
					   """>" & arrFolders(0, i) & "</a>"
		if arrFolders(1, i) = 0 then _
			Response.Write " [" & _
						   "<a href=""photoFolderMan.asp?todo=delete&folder=" & arrFolders(0, i) & _
			               """>delete</a>" & _
			               "]"
		Response.Write "<br>"
	next
end sub

sub UpdateDB(strOld, strNew)
	strSQL = "SELECT NomPhoto " & _
			 "FROM Photo " & _
			 "WHERE (NomPhoto Like '%.jpg' OR NomPhoto Like '%.gif') AND " & _ 
			 "NomPhoto Like '" & strOld & "/%';"

	rs0.Open strSQL, conConnexion, 2, 3
	while not rs0.EOF
		rs0("NomPhoto") = strNew & mid(rs0("NomPhoto"), len(strOld) + 1)
		rs0.update
		rs0.MoveNext
	wend	
	rs0.close
end sub

sub ShowFiles(strFolder)
	if strFolder = "home" then
		strSQL = "SELECT IDPhoto, NomPhoto " & _
				 "FROM Photo " & _
				 "WHERE (NomPhoto Like '%.jpg' OR NomPhoto Like '%.gif') AND " & _
				 "NomPhoto Not Like '%/%'" & _
				 "ORDER BY Date, NomPhoto;"
	else
		strSQL = "SELECT IDPhoto, NomPhoto " & _
				 "FROM Photo " & _
				 "WHERE (NomPhoto Like '%.jpg' OR NomPhoto Like '%.gif') AND " & _
				 "NomPhoto Like '" & strFolder & "/%'" & _
				 "ORDER BY Date, NomPhoto;"
	end if

	rs0.Open strSQL, conConnexion
	while not rs0.EOF
		Response.Write "<input type=checkbox name=X_" & rs0("IDPhoto") & " value=X>"
		Response.Write rs0("NomPhoto") & "<br>"
		rs0.MoveNext
	wend	
	rs0.close
end sub

sub ShowFolderDrop
	dim i
	Response.Write "<select name=folder class=box>"
	Response.Write "<option value=home>Home"

	for i = 1 to ubound(arrFolders, 2)
		Response.Write "<option value=""" & arrFolders(0, i) & """>" & arrFolders(0, i)
	next
	Response.Write "</select>"
end sub

sub MoveFile(lngIDFile, strFolder)
	dim strOldName, strNewName, strOldNameTN, strNewNameTN

	strSQL = "SELECT * " & _
			 "FROM Photo " & _
			 "WHERE IDPhoto=" & lngIDFile & ";"

	rs0.Open strSQL, conConnexion, 2, 3
	if not rs0.EOF then
		strOldName = rs0("NomPhoto")
		if strFolder = "home" then
			strNewName = mid(strOldName, inStr(strOldName, "/") + 1)
		else
			if inStr(strOldName, "/") = 0 then
				strNewName = strFolder & "/" & strOldName
			else
				strNewName = strFolder & mid(strOldName, inStr(strOldName, "/"))
			end if
		end if 

		strOldNameTN = left(strOldName, len(strOldName) - 4) & ".tn" & right(strOldName, 4)
		strNewNameTN = left(strNewName, len(strNewName) - 4) & ".tn" & right(strNewName, 4)

'		on error resume next
		fso.MoveFile server.mappath(strImage & strOldName), _
					 server.mappath(strImage & strNewName)
		fso.MoveFile server.mappath(strImage & strOldNameTN), _
					 server.mappath(strImage & strNewNameTN)
'		on error goto 0

		rs0("NomPhoto") = strNewName
		rs0.update
	end if	
	rs0.close
end sub
%>

<!--#include VIRTUAL="/Include/DAOFooter.asp"-->
<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->

