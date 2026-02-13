<%@ LANGUAGE="VBSCRIPT" %>

<%
if Session("QueryOK") = "safe" then

	strFolder = Session("MyFilesUpFolder")
	if strFolder = "" then strFolder = application("BaseFolder") 

	'page header
	''''''''''''''''''''''''''''''''''''''''
	Response.Write "<html>"
	Response.Write "<head>"
	Response.Write "<title>File Upload</title>"
	Response.Write "<link rel=stylesheet type=text/css href=/QueryMan/style.css></head>"
	Response.Write "<body bgcolor=#ffffff onload=""window.opener.location = 'files.asp?Folder=" & strFolder & "';window.close();"">"
	''''''''''''''''''''''''''''''''''''''''

	'Variables
	'*********
	Dim mySmartUpload
	Dim intCount
	        
	'Object creation
	'***************
	Set mySmartUpload = Server.CreateObject("aspSmartUpload.SmartUpload")

	'Upload
	'******
	mySmartUpload.Upload

	'Save the files with their original names in a virtual path of the web server
	'****************************************************************************
	intCount = mySmartUpload.Save(strFolder)
	' sample with a physical path 
	' intCount = mySmartUpload.Save("c:\temp\")

	'Display the number of files uploaded
	'************************************
	Response.Write intCount & " file(s) uploaded<br>"

	Response.Write "<a href=""javascript:window.opener.location = 'files.asp?Folder=" & strFolder & "';window.close();"">Close</a>"


	'page footer
	'''''''''''''''''''''''''''''''
	Response.Write "</body></html>"
	'''''''''''''''''''''''''''''''

else 
	Response.Write "<html><head><script language=""javascript"">window.opener.location = 'files.asp';window.close();</script></head></html>"
end if

%>

