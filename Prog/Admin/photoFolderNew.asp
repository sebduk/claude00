<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
Dim fso, fsoFolder, fsoItem, fsoSubFolders, fsoFiles

if Request("todo") = "add" then
	Set fso = CreateObject("Scripting.FileSystemObject")
	on error resume next
	Set fsoFolder = fso.CreateFolder(server.mappath(strImage & Request("folder")))
	on error goto 0
end if

Response.Write "<p><b>"
Response.Write "Add a Folder"
Response.Write "<br>Warning!"
Response.Write "</b></p>"

Response.Write "<p>You are about to add a folder to the site.<br>"
Response.Write "Folders are directories on the server.<br>"
Response.Write "All Folders names must be different, check that you don't have identicals in the list.</p>"

Response.Write "<p><b>Do not use: . , ; "" ' & / \ * in you folder names as they may enter in conflict with the host system.</b></p>"

Response.Write "<form action=photoFolderNew.asp method=post>"

if Request("folder") <> empty then
	Response.Write "<input type=hidden name=todo value=update>"
	Response.Write "<input type=hidden name=old value=""" & Request("folder") & """>"
	Response.Write "<input type=text name=folder value=""" & Request("folder") & """ size=60 style={width=250pt} class=box>"
	Response.Write "<input type=submit value=update class=box>"
else
	Response.Write "<input type=hidden name=todo value=add>"
	Response.Write "<input type=text name=folder size=60 style={width=250pt} class=box>"
	Response.Write "<input type=submit value=add class=box>"
end if

Response.Write "</form>"

Response.Write "<p><b>PS. In case of problem send your folder names to <a href=mailto:sebduk@gmail.com class=BLink>sebduk@gmail.com</a>, they will be added ASAP.</b></p>"

Response.Write "<p><a href=photoList.asp target=left>&lt;&lt;&lt; Refresh the file list &lt;&lt;&lt;</a></p>"
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->

