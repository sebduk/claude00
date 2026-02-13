<%@ LANGUAGE="VBSCRIPT" %>

<%
if Session("QueryOK") = "safe" then

	'page header
	''''''''''''''''''''''''''''''''''''''''
	Response.Write "<html>"
	Response.Write "<head>"
	Response.Write "<title>File Upload</title>"
	Response.Write "<link rel=stylesheet type=text/css href=/QueryMan/style.css></head>"
	Response.Write "<body bgcolor=#ffffff onLoad=window.focus();>"
	''''''''''''''''''''''''''''''''''''''''

	Response.Write "<form method=POST action=filesUp2.asp enctype=""multipart/form-data"">"
	for i = 1 to 4
		Response.Write "<input type=FILE name=FILE" & i & " style={width=251pt} class=box><br>"
	next
	Response.Write "<input type=submit value=Upload class=button>"
	Response.Write "</form>"

	'page footer
	'''''''''''''''''''''''''''''''
	Response.Write "</body></html>"
	'''''''''''''''''''''''''''''''

	Session("MyFilesUpFolder") = Request("Folder")
else 
	Response.Write "<html><head><script language=""javascript"">window.opener.location = 'files.asp';window.close();</script></head></html>"
end if

%>

