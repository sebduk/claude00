<!--#include VIRTUAL=/Include/CodeHeader.asp-->
<%
strConn = "PROVIDER=Microsoft.Jet.OLEDB.4.0;DATA SOURCE=" & server.mappath("/Data/user.mdb") & ";"
%>
<!--#include VIRTUAL=/Include/DAOHeader.asp-->
<!--#include VIRTUAL=/Include/HTMLHomeHeader.asp-->
<%
Response.Write "<tr valign=top>"
Response.Write "<!--Body-->"
Response.Write "<td height=380>"
Response.Write "<table border=0 height=100% width=100% cellpadding=6 cellspacing=0>"
Response.Write "<tr><td valign=top>"

if Request("todo") <> "send" then
	Response.Write "<form action=contactUs.asp name=myMail method=post>"
end if

select case Request("todo")
	case "send"
		sendMail Request("FromEmail"), Request("FromName"), Request("sendTo"), Request("Subject"), Request("Body")
	case "forgotPass"
		doForgotPass
	case "forgotPass2"
		doForgotPass2
	case "upgrade"
		doUpgrade
	case else
		doFreeMail
end select

if Request("todo") <> "send" then
	Response.Write "</form>"
	Response.Write "<center>All fields are mandatory!</center>"

	printJavacript
end if

Response.Write "</td></tr></table>"
Response.Write "</td>"
Response.Write "</tr>"
%>
<!--#include VIRTUAL=/Include/HTMLHomeFooter.asp-->
<!--#include VIRTUAL=/Include/DAOFooter.asp-->
<!--#include VIRTUAL=/Include/FunctEmail.asp-->
<%
sub doFreeMail()
	Response.Write "<input type=hidden name=todo value=send>"
	Response.Write "<input type=hidden name=sendTo value=webmaster>"

	Response.Write "<table align=center>"
	Response.Write "<tr><td align=right>Your name</td>"
	Response.Write "<td><input type=text name=FromName class=box150></td>"
	Response.Write "<td>&nbsp;</td></tr>"

	Response.Write "<tr><td align=right>Your email</td>"
	Response.Write "<td><input type=text name=FromEmail class=box150></td>"
	Response.Write "<td>&nbsp;</td></tr>"

	Response.Write "<tr><td align=right>Subject</td>"
	Response.Write "<td><input type=text name=Subject class=box150></td>"
	Response.Write "<td>&nbsp;</td></tr>"

	Response.Write "<tr><td align=right valign=top>Text</td>"
	Response.Write "<td><textarea name=Body rows=10 class=box150></textarea></td>"
	Response.Write "<td>&nbsp;</td></tr>"

	Response.Write "<tr><td>&nbsp;</td>"
	Response.Write "<td><input type=button value=send class=box150 onClick=""verifySubmit();""></td>"
	Response.Write "<td>&nbsp;</td></tr>"
	Response.Write "</table>"
end sub

sub doUpgrade()
	Response.Write "<input type=hidden name=todo value=send>"
	Response.Write "<input type=hidden name=sendTo value=webmaster>"

	Response.Write "<table align=center>"
	Response.Write "<tr><td align=right>Your name</td>"
	Response.Write "<td><input type=text name=FromName class=box150></td>"
	Response.Write "<td>&nbsp;</td></tr>"

	Response.Write "<tr><td align=right>Your email</td>"
	Response.Write "<td><input type=text name=FromEmail class=box150></td>"
	Response.Write "<td>&nbsp;</td></tr>"

	Response.Write "<tr><td align=right>Subject</td>"
	Response.Write "<td><input type=text name=Subject value=""Family Tree Upgrade"" class=box150></td>"
	Response.Write "<td>&nbsp;</td></tr>"

	Response.Write "<tr><td align=right valign=top>Text</td>"
	Response.Write "<td><textarea name=Body rows=10 class=box150>" & _
				   "Please upgrade my site." & VbCrlf & _
				   "Site Key: " & Request("from") & VbCrlf & VbCrlf & _
				   "I understand you will contact me shortly via email to organise this process." & VbCrlf & VbCrlf & _
				   "</textarea></td>"
	Response.Write "<td>&nbsp;</td></tr>"

	Response.Write "<tr><td>&nbsp;</td>"
	Response.Write "<td><input type=button value=send class=box150 onClick=""verifySubmit();""></td>"
	Response.Write "<td>&nbsp;</td></tr>"
	Response.Write "</table>"
end sub

sub doForgotPass()
	Response.Write "<input type=hidden name=todo value=forgotPass2>"
	Response.Write "<input type=hidden name=sendTo value=webmaster>"

	Response.Write "<table align=center>"
	Response.Write "<tr><td align=right>Your name</td>"
	Response.Write "<td><input type=text name=FromName class=box150></td>"
	Response.Write "<td>&nbsp;</td></tr>"

	Response.Write "<tr><td align=right>Your email</td>"
	Response.Write "<td><input type=text name=FromEmail class=box150></td>"
	Response.Write "<td>*</td></tr>"

	Response.Write "<tr><td align=right>Subject</td>"
	Response.Write "<td><input type=text name=Subject value=""I forgot my Password"" class=box150></td>"
	Response.Write "<td>&nbsp;</td></tr>"

	Response.Write "<tr><td align=right valign=top>Text</td>"
	Response.Write "<td><textarea name=Body rows=10 class=box150>Please send me my Password</textarea></td>"
	Response.Write "<td>&nbsp;</td></tr>"

	Response.Write "<tr><td>&nbsp;</td>"
	Response.Write "<td><input type=button value=send class=box150 onClick=""verifySubmit();""></td>"
	Response.Write "<td>&nbsp;</td></tr>"

	Response.Write "<tr><td>&nbsp;</td>"
	Response.Write "<td>* as was given when you signed in</td>"
	Response.Write "<td>&nbsp;</td></tr>"
	Response.Write "</table>"
end sub

sub doForgotPass2()
	dim strBody

	if Request("FromEmail") <> empty then
		strSQL = "SELECT * FROM [User] WHERE UserEmail='" & Request("FromEmail") & "';"
		rs0.Open strSQL, conConnexion

		if not rs0.eof then

			strBody = "Dear " & rs0("UserName") & ",<br><br>" & _
					  "You have requested us to send you your login and password.<br>" & _
					  "<b>Login:</b> " & rs0("UserLogin") & "<br>" & _
					  "<b>Password:</b> " & rs0("UserPassword") & "<br><br>" & _
					  "<a href=http://www.see-our-family.com target=_blank>See Our Family</a><br><br>" & _
					  "Don't hesitate to contact us if you encounter further problems loging-in.<br>" & _
					  "The See Our Family Webmaster"
			
			sendMail "webmaster", "webmaster", rs0("UserEmail"), "Your See Our Family Details", strBody
			Response.Write "<center>Your password has been sent to your address (" & rs0("UserEmail") & ").</center><br><br>"
		else
			Response.Write "<center>Your email is not in our database.</center><br><br>"
			doForgotPass
		end if
		rs0.Close
	else
		doForgotPass
	end if
	Response.Write "<input type=hidden name=FromName>"
end sub

sub printJavacript()
	Response.Write "<script language=javascript>"
	Response.Write "document.forms.myMail.FromName.focus();"

	Response.Write  "function verifySubmit(){"
	Response.Write	 "var FromName = document.myMail.FromName.value;"
	Response.Write   "var FromEmail = document.myMail.FromEmail.value;"
	Response.Write   "var Subject = document.myMail.Subject.value;"
	Response.Write   "var Body = document.myMail.Body.value;"
	Response.Write   "if (FromName == ''){"
	Response.Write    "alert(""Please enter your Name!\nEx: John Smith"")"
	Response.Write   "} else if (FromEmail == ''){"
	Response.Write    "alert(""Please enter your Email!\nEx: name@domain.com"")"
	Response.Write   "} else if (FromEmail.indexOf('@') < 1){"
	Response.Write    "alert(""Your Email appears to be erroneous.\nPlease re-enter your Email!"")"
	Response.Write   "} else if (FromEmail.indexOf('.') < 3){"
	Response.Write    "alert(""Your Email appears to be erroneous.\nPlease re-enter your Email!"")"
	Response.Write   "} else if (FromEmail.length < 5){"
	Response.Write    "alert(""Your Email appears to be erroneous.\nPlease re-enter your Email!"")"
	Response.Write   "} else if (FromEmail.charAt(FromEmail.length - 1) == '.'){"
	Response.Write    "alert(""Your Email appears to be erroneous.\nPlease re-enter your Email!"")"
	Response.Write   "} else if (Subject == '') {"
	Response.Write    "alert(""Please enter a Subject!"")"
	Response.Write   "} else if (Body == '') {"
	Response.Write    "alert(""Please enter a Body!"")"
	Response.Write   "} else {"
	Response.Write    "document.myMail.submit()"
	Response.Write   "}"
	Response.Write  "}"
	Response.Write "</script>"
end sub
%>