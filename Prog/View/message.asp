<!--#include VIRTUAL=/Include/CodeHeader.asp-->
<!--#include VIRTUAL=/Include/DAOHeader.asp-->
<!--#include VIRTUAL=/Include/HTMLHeader.asp-->
<!--#include VIRTUAL=/Include/Label.asp-->

<style>
.MessPerso {color:white;}
</style>

<table border="0" width="80%" align="center">

<%
dim isFirst, strSendResults, intCpt, intMax, strColorMessBoard, strColorMessPerso

if Request("todo") = "add" then DoAdd
if Request("todo") = "send" then DoSend strSendResults

if Request("v") <> empty then
	intMax = 1000
else
	intMax = 4
end if

strColorMessBoard = "#cccccc"
strColorMessPerso = "#999999"

strSQL = "SELECT * FROM Forum " & _
		 "WHERE ForumIsOnline " & _
		 "ORDER BY ForumSort, ForumTitle;"
rs0.Open strSQL, conConnexion, 2, 3



if Request("IDForum") = "perso" or rs0.EOF then
	Response.Write "<tr bgcolor=" & strColorMessPerso & "><td>" & _
				   "<a href=message.asp?IDForum=perso><b class=MessPerso>" & strMessPerso & "</b></a>" & _
				   "</td></tr>"
	Response.Write "<tr><td>" & _
				   "<hr width=100% size=1 noshade>" & _
				   "</td></tr>"
	Response.Write "<form action=message.asp method=post name=SendForm>"
	Response.Write "<input type=hidden name=todo value=send>"
	Response.Write "<input type=hidden name=IdForum value=perso>"
	Response.Write "<tr valign=top><td>"
	Response.Write "<table border=0 cellpadding=0 cellspacing=3 bgcolor=#999999>"
	Response.Write "<tr><td colspan=3 class=MessPerso>" & _
				   strMessSubject & " <input type=text name=ForumItemTitle size=40 tabindex=1 class=text> " & _
				   strMessFrom & " <input type=text name=ForumItemFrom size=20 tabindex=2 class=text> " & _
				   strMessEmail & " <input type=text name=ForumItemEmail size=20 tabindex=3 class=text> " & _
				   "<input type=button value=" & strMessSend & " tabindex=5 class=text onClick=verifySubmit(); id=button1 name=button1></td></tr>"
	Response.Write "<tr valign=bottom><td>" & _
				   "<textarea name=ForumItemBody rows=20 cols=80 tabindex=4 class=text></textarea></td>"

	strSQL = "SELECT * " & _
			 "FROM Personne " & _
			 "WHERE NOT Email IS NULL " & _
			 "ORDER BY Nom, Prenom;"
	rs1.Open strSQL, conConnexion, 2, 3

	Response.Write "<td class=MessPerso>" & strMessTo & "<br>" & _
				   "<select name=IDTo multiple size=20 class=text>"
	while not rs1.EOF
		Response.Write "<option value=" & rs1("IDPersonne")
		if rs1("IDPersonne") = cdbl(request("IDPerso")) then Response.Write " selected"
		Response.Write ">" & rs1("Nom") & ", " & rs1("Prenom") & " (" & rs1("DtNaiss") & ")"
		rs1.MoveNext
	wend
	Response.Write "<option value=W>&gt;&gt;&gt;WebMaster&lt;&lt;&lt;"
	Response.Write "</select></td></tr>"

	rs1.Close

	Response.Write "</table>"

	Response.Write "</td></tr>"
	Response.Write "</form>"
	Response.Write "<tr><td>"
	Response.Write strSendResults
	Response.Write "<hr width=100% size=1 noshade>" & _
				   "</td></tr>"
	printJavacriptPerso
else
	Response.Write "<tr bgcolor=" & strColorMessPerso & "><td>" & _
				   "<a href=message.asp?IDForum=perso><b class=MessPerso>" & strMessPerso & "</b></a>" & _
				   "</td></tr>"
end if






isFirst = true
while not rs0.EOF
	if Request("IDForum") = cstr(rs0("IDForum")) or _
	  (Request("IDForum") = empty and isFirst) then

		Response.Write "<tr bgcolor=" & strColorMessBoard & "><td>" & _
					   "<a href=message.asp?IDForum=" & rs0("IDForum") & "><b>" & rs0("ForumTitle") & "</b></a> | " & _
					   "<a href=message.asp?IDForum=" & rs0("IDForum") & "&v=a>" & strMessAll & "</a> " & _
					   "</td></tr>"

		strSQL = "SELECT * FROM ForumItem " & _
				 "WHERE ForumItemIsOnline AND IdForum=" & rs0("IDForum") & " " & _
				 "ORDER BY ForumItemDate DESC;"
		rs1.Open strSQL, conConnexion, 2, 3

		intCpt = 1 
		while not rs1.EOF and intCpt <= intMax
			Response.Write "<tr bgcolor=#eeeeee><td><b>" & _
						   rs1("ForumItemTitle") & " | " & _
						   rs1("ForumItemFrom") & " | " & _
						   PresentDate(rs1("ForumItemDate")) & _
						   "</b></td></tr>"
			Response.Write "<tr><td>" & _
						   "<i>" & Replace(rs1("ForumItemBody") & " ", VbCrlf, "<br>") & "</i>" & _
						   "</td></tr>"
			rs1.MoveNext
			intCpt = intCpt + 1
		wend
		rs1.Close

		Response.Write "<tr><td>" & _
					   "<hr width=100% size=1 noshade>" & _
					   "</td></tr>"
		Response.Write "<form action=message.asp method=post name=SendForm>"
		Response.Write "<input type=hidden name=todo value=add>"
		Response.Write "<input type=hidden name=IdForum value=" & rs0("IDForum") & ">"
		Response.Write "<tr bgcolor=#999999><td>&nbsp;" & _
					   strMessSubject & " <input type=text name=ForumItemTitle size=40 tabindex=1 class=text> " & _
					   strMessFrom & " <input type=text name=ForumItemFrom size=20 tabindex=2 class=text> " & _
					   strMessEmail & " <input type=text name=ForumItemEmail size=20 tabindex=3 class=text> " & _
					   "<input type=button value=" & strMessSend & " tabindex=5 class=text onClick=verifySubmit();><br>" & _
					   "<textarea name=ForumItemBody rows=5 cols=120 tabindex=4 class=text></textarea>" & _
					   "</td></tr>"
		Response.Write "</form>"
		Response.Write "<tr><td>" & _
					   "<hr width=100% size=1 noshade>" & _
					   "</td></tr>"
		printJavacriptMess
	else
		Response.Write "<tr bgcolor=" & strColorMessBoard & "><td>" & _
					   "<a href=message.asp?IDForum=" & rs0("IDForum") & "><b>" & rs0("ForumTitle") & "</b></a>" & _
					   "</td></tr>"
	end if
	rs0.MoveNext
	isFirst = false
wend
rs0.Close
%>

</table>

<!--#include VIRTUAL=/Include/HTMLFooter.asp-->
<!--#include VIRTUAL=/Include/DAOFooter.asp-->
<!--#include VIRTUAL=/Include/FunctEmail.asp-->

<%
sub DoAdd()
	if Trim(Request("ForumItemBody")) <> empty or _
	   Trim(Request("ForumItemTitle")) <> empty then
		strSQL = "SELECT * FROM Forumitem " & _
				 "WHERE IDForumItem=0;"
		rs1.Open strSQL, conConnexion, 2, 3
		rs1.AddNew
		rs1("IdForum") = Request("IdForum") 

		if Request("ForumItemTitle") <> empty then
			rs1("ForumItemTitle") = Request("ForumItemTitle")
		else
			rs1("ForumItemTitle") = null
		end if

		if Request("ForumItemFrom") <> empty then
			rs1("ForumItemFrom") = Request("ForumItemFrom")
		else
			rs1("ForumItemFrom") = null
		end if

		if Request("ForumItemEmail") <> empty then
			rs1("ForumItemEmail") = Request("ForumItemEmail")
		else
			rs1("ForumItemEmail") = null
		end if

		if Request("ForumItemBody") <> empty then
			rs1("ForumItemBody") = Request("ForumItemBody")
		else
			rs1("ForumItemBody") = null
		end if

		rs1("ForumItemDate") = Now()
		rs1("ForumItemIsOnline") = true

		rs1.Update
		rs1.Close
	end if
end sub

sub DoSend(strSendResults)
	dim arrEmail(), strSubject, strFrom, strEmail, strBody
	redim arrEmail(0)
	
	strSubject = Request("ForumItemTitle")
	strFrom = Request("ForumItemFrom")
	strEmail = Request("ForumItemEmail")
	strBody = Request("ForumItemBody")
	
	strSendResults = strMessFrom & ": " & strFrom & "<br>" & _
					 strMessEmail & ": " & strEmail & "<br>" & _
					 strMessTo & ": "

	

	strSQL = "SELECT * " & _
			 "FROM Personne " & _
			 "WHERE IDPersonne IN (0," & Request("IDTo") & ");"
	rs0.Open strSQL, conConnexion, 2, 3
	while not rs0.EOF
		redim preserve arrEmail(Ubound(arrEmail) + 1)
		arrEmail(Ubound(arrEmail)) = rs0("Email")
		strSendResults = strSendResults & rs0("Prenom") & " " & rs0("Nom") & ", "
		rs0.MoveNext
	wend
	rs0.Close

	redim preserve arrEmail(Ubound(arrEmail) + 1)
	arrEmail(Ubound(arrEmail)) = "sebduk@gmail.com"

	strSendResults = left(strSendResults, len(strSendResults) - 2) & ".<br><br>" & _
					 strMessSubject & ": " & strSubject & "<br>" & _
					 """" & Replace(strBody & " ", VbCrlf, "<br>") & """"

	sendMultiMail strEmail, strFrom, arrEmail, strSubject, strBody
end sub

function PresentDate(dtDate)
	PresentDate = Day(dtDate) & " " & _
				  arrMonth(Month(dtDate)) & " " & _
				  Year(dtDate) & ", " & _
				  Hour(dtDate) & ":" & _
				  Minute(dtDate)
end function

sub printJavacriptMess()
	Response.Write "<script language=javascript>"
	Response.Write "document.SendForm.ForumItemTitle.focus();"

	Response.Write  "function verifySubmit(){"
	Response.Write	 "var FromName = document.SendForm.ForumItemFrom.value;"
	Response.Write   "var FromEmail = document.SendForm.ForumItemEmail.value;"
	Response.Write   "var Subject = document.SendForm.ForumItemTitle.value;"
	Response.Write   "var Body = document.SendForm.ForumItemBody.value;"
	Response.Write   "if (Subject == '') {"
	Response.Write    "alert(""" & strWarningSubject & """)"
	Response.Write   "} else if (FromName == ''){"
	Response.Write    "alert(""" & strWarningFrom & """)"
	Response.Write   "} else if (FromEmail.indexOf('@') < 1){"
	Response.Write    "alert(""" & strWarningEmail & """)"
	Response.Write   "} else if (FromEmail.indexOf('.') < 3){"
	Response.Write    "alert(""" & strWarningEmail & """)"
	Response.Write   "} else if (FromEmail.length < 5){"
	Response.Write    "alert(""" & strWarningEmail & """)"
	Response.Write   "} else if (FromEmail.charAt(FromEmail.length - 1) == '.'){"
	Response.Write    "alert(""" & strWarningEmail & """)"
	Response.Write   "} else if (Body == '') {"
	Response.Write    "alert(""" & strWarningBody & """)"
	Response.Write   "} else {"
	Response.Write    "document.SendForm.submit()"
	Response.Write   "}"
	Response.Write  "}"
	Response.Write "</script>"
end sub

sub printJavacriptPerso()
	Response.Write "<script language=javascript>"
	Response.Write "document.SendForm.ForumItemTitle.focus();"

	Response.Write  "function verifySubmit(){"
	Response.Write	 "var FromName = document.SendForm.ForumItemFrom.value;"
	Response.Write   "var FromEmail = document.SendForm.ForumItemEmail.value;"
	Response.Write   "var Subject = document.SendForm.ForumItemTitle.value;"
	Response.Write   "var Body = document.SendForm.ForumItemBody.value;"
	Response.Write   "var To = document.SendForm.IDTo.value;"
	Response.Write   "if (Subject == '') {"
	Response.Write    "alert(""" & strWarningSubject & """)"
	Response.Write   "} else if (FromName == ''){"
	Response.Write    "alert(""" & strWarningFrom & """)"
	Response.Write   "} else if (FromEmail == ''){"
	Response.Write    "alert(""" & strWarningEmail & """)"
	Response.Write   "} else if (FromEmail.indexOf('@') < 1){"
	Response.Write    "alert(""" & strWarningEmail & """)"
	Response.Write   "} else if (FromEmail.indexOf('.') < 3){"
	Response.Write    "alert(""" & strWarningEmail & """)"
	Response.Write   "} else if (FromEmail.length < 5){"
	Response.Write    "alert(""" & strWarningEmail & """)"
	Response.Write   "} else if (FromEmail.charAt(FromEmail.length - 1) == '.'){"
	Response.Write    "alert(""" & strWarningEmail & """)"
	Response.Write   "} else if (Body == '') {"
	Response.Write    "alert(""" & strWarningBody & """)"
	Response.Write   "} else if (To == '') {"
	Response.Write    "alert(""" & strWarningTo & """)"
	Response.Write   "} else {"
	Response.Write    "document.SendForm.submit()"
	Response.Write   "}"
	Response.Write  "}"
	Response.Write "</script>"
end sub

%>