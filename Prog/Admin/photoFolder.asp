<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%

Dim fso, fsoFolder, fsoItem, fsoSubFolders, fsoFiles

select case Request("todo")
	case "add"
		Set fso = CreateObject("Scripting.FileSystemObject")
		on error resume next
		Set fsoFolder = fso.CreateFolder(server.mappath(strImage & Request("folder")))
		on error goto 0
		Session("SF") = Request("folder")
	case "update"
		Set fso = CreateObject("Scripting.FileSystemObject")
		on error resume next
		fso.MoveFolder server.mappath(strImage & Request("old")), _
					   server.mappath(strImage & Request("folder"))
		on error goto 0
		Session("SF") = Request("folder")
	case "delete"
		Set fso = CreateObject("Scripting.FileSystemObject")
		Set fsoFolder = fso.GetFolder(server.mappath(strImage))
		Set fsoSubFolders = fso.GetFolder(server.mappath(strImage & Request("Folder")))
		fsoSubFolders.delete
		Set fsoSubFolders = nothing
		Session("SF") = empty
end select

Response.Write "<p><b>Warning!</b></p>"

Response.Write "<p>You are about to add or update a folder to the site.<br>"
Response.Write "Folders are directories on the server.<br>"
Response.Write "All Folders names must be different, check that you don't have identicals in the list.</p>"

Response.Write "<p><b>Do not use: . , ; "" ' & / \ * in you folder names as they may enter in conflict with the host system.</b></p>"

Response.Write "<form action=photoFolder.asp method=post>"

if Request("todo") <> "delete" then
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
else
	Response.Write "<b>Deleted</b><br>"
end if

Response.Write "</form>"

Response.Write "<p><b>PS. In case of problem send your folder names to <a href=mailto:sebduk@gmail.com class=BLink>sebduk@gmail.com</a>, they will be added ASAP.</b></p>"

Response.Write "<p><a href=photoList.asp target=left>&lt;&lt;&lt; Refresh the file list &lt;&lt;&lt;</a></p>"


sub old()
	dim strTN, i

	Response.Write "<p><b>Warning!</b></p>"

	Response.Write "<p>You are about to add a picture to the site.<br>"
	Response.Write "We suggest you keep your file names to the following format:</p>"

	Response.Write "<p><b>LastFirstNamesYearMonthDay.jpg</b> or <b>LastFirstNamesYearMonthDay.gif</b><br>"
	Response.Write "Ex.: <b>DucosGabrielTheo20020530.jpg</b></p>"

	Response.Write "<p>Name the picture on your computer before you upload it.<br>"
	Response.Write "All picture names must be different, check that you don't have identicals in the list.</p>"

	Response.Write "<p><b>Do use: .jpg or .gif at the end of your file name or the application will not recognise them.<br>"
	Response.Write "Do not use: , ; "" ' _ - & / \ * in you file names as they may enter in conflict with the host system.</b></p>"

	Response.Write "<form method=POST action=photoUpload2.asp enctype=""multipart/form-data"" id=form1 name=form1>"
	for i = 1 to 4
		Response.Write "<input type=FILE name=FILE" & i & " size=60 style={width=250pt} class=box><br>"
	next
	Response.Write "<input type=submit value=Upload class=box>"
	Response.Write "</form>"

	Response.Write "<p><b>PS. In case of problem send your pictures to <a href=mailto:sebduk@gmail.com class=BLink>sebduk@gmail.com</a>, they will be added ASAP.</b></p>"

	Response.Write "<p>Pictures should be uploaded with their thumbnails. "
	Response.Write "Thumbnails are small versions of pictures used in the picture lists. These are resized to be lighter and fit a list view. "
	Response.Write "To create a thumbnail resize your picture to have its largest dimension (height or width) at 100 pixels keeping the same ratio. "
	Response.Write "If your picture is called MyPicture.jpg name the thumbnail MyPicture.tn.jpg (.tn.gif).</p>"

	Response.Write "<p><a href=photoList.asp target=left>&lt;&lt;&lt; Refresh the file list &lt;&lt;&lt;</a></p>"
end sub
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->

