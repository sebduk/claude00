<%@ LANGUAGE="VBSCRIPT" %>

<%
if Session("QueryOK") = "safe" then
	Dim fso, fsoFolder, fsoItem, fsoSubFolders, fsoFiles
	Set fso = CreateObject("Scripting.FileSystemObject")

	'page header
	''''''''''''''''''''''''''''''''''''''''

	if Request("Name") = "New" then
		Response.Write "<html>"
		Response.Write "<head>"
		Response.Write "<title>File Edit</title>"
		Response.Write "<link rel=stylesheet type=text/css href=/Queryman/style.css></head>"
		Response.Write "<body bgcolor=#ffffff>"

		Response.Write "<form action=filesEdit.asp method=post>"
		Response.Write "<input type=hidden name=Todo value=add>"
		Response.Write "<input type=hidden name=Folder value=""" & Request("Folder") & """>"
		Response.Write "Create a new Folder<br>"
		Response.Write "<input type=text name=NewFolder style={width:299pt} class=box><br>"
		Response.Write "<input type=submit value=""Add Folder"" class=button>"
		Response.Write "<input type=button value=""Close"" onclick=window.close() class=button>"
		Response.Write "</form>"

	elseif Request("Todo") = "add" then
		if Request("NewFolder") <> empty and Request("NewFolder") <> "" then
			strCreate = Request("Folder") & "/" & Request("NewFolder")

			on error resume next
			Set fsoFolder = fso.CreateFolder(server.mappath(strCreate))
			on error goto 0
			
			Response.Write "<html>"
			Response.Write "<head>"
			Response.Write "<title>File Edit</title>"
			Response.Write "<link rel=stylesheet type=text/css href=/Queryman/style.css></head>"
			Response.Write "<body bgcolor=#ffffff onload=""window.opener.location = 'files.asp?Folder=" & Request("Folder") & "';window.close();"">"

			Response.Write Request("NewFolder") & ": Successfully Created<br>"
			Response.Write "<a href=""javascript:window.opener.location = 'files.asp?Folder=" & Request("Folder") & "';window.close();"">Close</a>"
			
			Set fsoFolder = nothing
			
		else
			Response.Write "New Folder Error"
		end if

	elseif Request("Todo") = "Delete" then
		strItem = server.mappath(Request("Folder") & "/" & Request("Name"))
	
		Set fsoFolder = fso.GetFolder(server.mappath(Request("Folder")))

		if Request("Type") = "Folder" then
			Set fsoSubFolders = fso.GetFolder(strItem)
			fsoSubFolders.delete
			Set fsoSubFolders = nothing
		else
			Set fsoFiles = fso.GetFile(strItem)
			fsoFiles.delete
			Set fsoFiles = nothing
		end if

		Set fsoFolder = nothing

		Response.Write "<html>"
		Response.Write "<head>"
		Response.Write "<title>File Edit</title>"
		Response.Write "<link rel=stylesheet type=text/css href=/Queryman/style.css></head>"
		Response.Write "<body bgcolor=#ffffff onload=""window.opener.location = 'files.asp?Folder=" & Request("Folder") & "';window.close();"">"

		Response.Write Request("Name") & ": Successfully Deleted<br>"
		Response.Write "<a href=""javascript:window.opener.location = 'files.asp?Folder=" & Request("Folder") & "';window.close();"">Close</a>"

	elseif Request("Todo") = "Rename" or Request("Todo") = "Move" then
		strItemOld = server.mappath(Replace(Request("Folder") & "/" & Request("Name"), "//", "/"))
		strItemNew = server.mappath(Replace(Request("Folder") & "/" & Request("NewName"), "//", "/"))
	
		if Request("Type") = "Folder" then
			fso.MoveFolder strItemOld, strItemNew
		else
			fso.MoveFile strItemOld, strItemNew
		end if

		Response.Write "<html>"
		Response.Write "<head>"
		Response.Write "<title>File Edit</title>"
		Response.Write "<link rel=stylesheet type=text/css href=/Queryman/style.css></head>"
		Response.Write "<body bgcolor=#ffffff onload=""window.opener.location = 'files.asp?Folder=" & Request("Folder") & "';window.close();"">"

		Response.Write Request("Name") & ": Successfully Moved/Renamed<br>"
		Response.Write "<a href=""javascript:window.opener.location = 'files.asp?Folder=" & Request("Folder") & "';window.close();"">Close</a>"

	elseif Request("Todo") = "Copy" then
		strItemOld = server.mappath(Request("Folder") & "/" & Request("Name"))
		strItemNew = server.mappath(Request("Folder") & "/" & Request("NewName"))
	
		if Request("Type") = "Folder" then
			fso.CopyFolder strItemOld, strItemNew
		else
			fso.CopyFile strItemOld, strItemNew
		end if

		Response.Write "<html>"
		Response.Write "<head>"
		Response.Write "<title>File Edit</title>"
		Response.Write "<link rel=stylesheet type=text/css href=/Queryman/style.css></head>"
		Response.Write "<body bgcolor=#ffffff onload=""window.opener.location = 'files.asp?Folder=" & Request("Folder") & "';window.close();"">"

		Response.Write Request("Name") & ": Successfully Copied<br>"
		Response.Write "<a href=""javascript:window.opener.location = 'files.asp?Folder=" & Request("Folder") & "';window.close();"">Close</a>"

	else
		Response.Write "<html>"
		Response.Write "<head>"
		Response.Write "<title>File Edit</title>"
		Response.Write "<link rel=stylesheet type=text/css href=/Queryman/style.css></head>"
		Response.Write "<body bgcolor=#ffffff>"

		Response.Write "<form action=filesEdit.asp method=post>"
		Response.Write "<input type=hidden name=Folder value=""" & Request("Folder") & """>"
		Response.Write "<input type=hidden name=Type value=""" & Request("Type") & """>"
		Response.Write "<input type=hidden name=Name value=""" & Request("Name") & """>"
		Response.Write "Update Folder<br>"
		Response.Write "<input type=text name=NewName value=""" & Request("Name") & """ style={width:299pt} class=box><br>"
		Response.Write "<input type=submit name=todo value=""Rename"" class=button>"
		Response.Write "<input type=submit name=todo value=""Delete"" class=button>"
		Response.Write "<input type=submit name=todo value=""Copy"" class=button>"
		Response.Write "<input type=submit name=todo value=""Move"" class=button>"
		Response.Write "<input type=button value=""Close"" onclick=window.close() class=button>"
		Response.Write "</form>"
	end if


	'page footer
	'''''''''''''''''''''''''''''''
	Response.Write "</body></html>"
	'''''''''''''''''''''''''''''''

	Set fso = nothing

else 
	Response.Write "<html><head><script language=""javascript"">window.opener.location = 'files.asp';window.close();</script></head></html>"
end if
%>

