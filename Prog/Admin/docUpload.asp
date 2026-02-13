<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
dim strTN, i

Response.Write "<p><b>Warning!</b></p>"

Response.Write "<p>You are about to add a document to the site.<br>"
Response.Write "We suggest you keep your file names to the following format:</p>"

Response.Write "<p><b>LastFirstNamesYearMonthDay.doc, .xls, .pdf, etc...</b><br>"
Response.Write "Ex.: <b>DucosGabrielTheo20020530.doc</b></p>"

Response.Write "<p>Important: .exe, .bat, .asp documents will be rejected for security reasons<br>"
Response.Write "We may extend this list in the future.</p>"

Response.Write "<p>Name the document on your computer before you upload it.<br>"
Response.Write "All document names must be different, check that you don't have identicals in the list.</p>"

Response.Write "<p><b>Do use extensions at the end of your file name (.doc, .xls, .pdf, ect...)<br>or the application will not recognise them.<br>"
Response.Write "Do not use: , ; "" ' _ - & / \ * in you file names as they may enter in conflict with the host system.</b></p>"

Response.Write "<form method=POST action=docUpload2.asp enctype=""multipart/form-data"">"
for i = 1 to 4
	Response.Write "<input type=FILE name=FILE" & i & " size=60 style={width=250pt} class=box><br>"
next
Response.Write "<input type=submit value=Upload class=box>"
Response.Write "</form>"

Response.Write "<p><b>PS. In case of problem send your documents to <a href=mailto:sebduk@gmail.com class=BLink>sebduk@gmail.com</a>, they will be added ASAP.</b></p>"

Response.Write "<p><a href=docList.asp target=left>&lt;&lt;&lt; Refresh the file list &lt;&lt;&lt;</a></p>"
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->

