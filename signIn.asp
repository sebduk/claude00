<!--#include VIRTUAL=/Include/CodeHeader.asp-->
<%
strConn = "PROVIDER=Microsoft.Jet.OLEDB.4.0;DATA SOURCE=" & server.mappath("/Data/user.mdb") & ";"
%>
<!--#include VIRTUAL=/Include/DAOHeader.asp-->
<!--#include VIRTUAL=/Include/HTMLHomeHeader.asp-->
<%
dim lngIdUser
select case Request("todo")
	case "add"
		addUser lngIdUser
	case "update"
		updateUser
end select

Response.Write "<tr valign=top>"
Response.Write "<!--Body-->"
Response.Write "<td height=380>"
Response.Write "<table border=0 height=100% width=65% cellpadding=6 cellspacing=0 align=center>"
Response.Write "<tr><td valign=top>"

Response.Write "<center>"
'Response.Write "<br>"
Response.Write "<a href=signIn.asp><img src=/Image/createAccount.gif border=0></a>"
Response.Write "<br><br>"

Response.Write "<form action=signIn.asp name=MyForm method=post>"

if Request("User") = "me" then lngIdUser = Session("IDUser")
if Request("IDUser") <> empty then lngIdUser = Request("IDUser")

if lngIdUser <> empty and lngIdUser <> -1 then
	strSQL = "SELECT * FROM [User] " & _
			 "WHERE UserIsOnline AND IDUser=" & lngIdUser & ";"
	rs0.Open strSQL, conConnexion

	if not rs0.eof then
		Response.Write "<input type=hidden name=todo value=update>"
		Response.Write "<input type=hidden name=IDUser value=" & rs0("IDUser") & ">"
		Response.Write "<table>"

		Response.Write "<tr><td align=right>User Name&nbsp;</td>"
		Response.Write "<td><input type=text name=UserName value=""" & rs0("UserName") & """ class=box150></td>"
		Response.Write "<td>&nbsp;</td></tr>"

		Response.Write "<tr><td align=right>Email&nbsp;</td>"
		Response.Write "<td><input type=text name=UserEmail value=""" & rs0("UserEmail") & """ class=box150></td>"
		Response.Write "<td>*</td></tr>"

		Response.Write "<tr><td align=right>Login&nbsp;</td>"
		Response.Write "<td><b>" & rs0("UserLogin") & "</b></td>"
		Response.Write "<td>&nbsp;</td></tr>"

		Response.Write "<tr><td align=right>Password&nbsp;</td>"
		Response.Write "<td><input type=password name=UserPassword class=box150></td>"
		Response.Write "<td>&nbsp;</td></tr>"

		Response.Write "<tr><td align=right>Re-enter Password&nbsp;</td>"
		Response.Write "<td><input type=password name=UserPass2 class=box150></td>"
		Response.Write "<td>&nbsp;</td></tr>"

		Response.Write "<tr><td>&nbsp;</td>"
		Response.Write "<td><input type=button value=""update this account"" onClick=""verifySubmit();"" class=box150></td>"
		Response.Write "<td>&nbsp;</td></tr>"

		Response.Write "</form>"
		Response.Write "<form action=domain.asp method=post>"
		Response.Write "<input type=hidden name=login value=""" & rs0("UserLogin") & """>"
		Response.Write "<input type=hidden name=pswd value=""" & rs0("UserPassword") & """>"
		Response.Write "<tr><td>&nbsp;</td>"
		Response.Write "<td><input type=submit value=""Login!"" class=box150></td>"
		Response.Write "<td>&nbsp;</td></tr>"

		Response.Write "</table>"

		Response.Write "<script language=JavaScript>"
		Response.Write  "function verifySubmit(){"
		Response.Write   "var UserEmail = document.MyForm.UserEmail.value;"
		Response.Write   "var UserPassword = document.MyForm.UserPassword.value;"
		Response.Write   "var UserPass2 = document.MyForm.UserPass2.value;"
		Response.Write   "if (UserEmail == ''){"
		Response.Write    "alert(""Please enter your Email!\nEx: name@domain.com"")"
		Response.Write   "} else if (UserEmail.indexOf('@') < 1){"
		Response.Write    "alert(""Your Email appears to be erroneous.\nPlease re-enter your Email!"")"
		Response.Write   "} else if (UserEmail.indexOf('.') < 3){"
		Response.Write    "alert(""Your Email appears to be erroneous.\nPlease re-enter your Email!"")"
		Response.Write   "} else if (UserEmail.length < 5){"
		Response.Write    "alert(""Your Email appears to be erroneous.\nPlease re-enter your Email!"")"
		Response.Write   "} else if (UserEmail.charAt(UserEmail.length - 1) == '.'){"
		Response.Write    "alert(""Your Email appears to be erroneous.\nPlease re-enter your Email!"")"
		Response.Write   "} else if ((UserPassword != '') && (UserPassword.length < 6)) {"
		Response.Write    "alert(""You Password must be at least 6 characters long!"");"
		Response.Write    "document.MyForm.UserPass2.value = '';"
		Response.Write   "} else if (UserPass2 != UserPassword) {"
		Response.Write    "alert(""Please re-enter your Password!"");"
		Response.Write    "document.MyForm.UserPass2.value = '';"
		Response.Write   "} else {"
		Response.Write    "document.MyForm.submit()"
		Response.Write   "}"
		Response.Write  "}"
		Response.Write "</script>"
	else
		Response.Write "User unknown."
	end if
	
else
	if lngIdUser = -1 then 
		Response.Write "<b>Please choose a different Login!</b><br>"
	end if

	Response.Write "<input type=hidden name=todo value=add>"
	Response.Write "<table>"

	Response.Write "<tr><td align=right>User Name&nbsp;</td>"
	Response.Write "<td><input type=text name=UserName class=box150></td>"
	Response.Write "<td>&nbsp;</td></tr>"

	Response.Write "<tr><td align=right>Email&nbsp;</td>"
	Response.Write "<td><input type=text name=UserEmail class=box150></td>"
	Response.Write "<td>*</td></tr>"

	Response.Write "<tr><td align=right>Login&nbsp;</td>"
	Response.Write "<td><input type=text name=UserLogin class=box150></td>"
	Response.Write "<td>&nbsp;</td></tr>"

	Response.Write "<tr><td align=right>Password&nbsp;</td>"
	Response.Write "<td><input type=password name=UserPassword class=box150></td>"
	Response.Write "<td>&nbsp;</td></tr>"

	Response.Write "<tr><td align=right>Re-enter Password&nbsp;</td>"
	Response.Write "<td><input type=password name=UserPass2 class=box150></td>"
	Response.Write "<td>&nbsp;</td></tr>"

	Response.Write "<tr><td>&nbsp;</td>"
	Response.Write "<td><input type=button value=""create this account"" onClick=""verifySubmit();"" class=box150></td>"
	Response.Write "<td>&nbsp;</td></tr>"

	Response.Write "</table>"

	printJavascript
end if

Response.Write "</form>"

Response.Write "<br><br><br>"
Response.Write "* See Our Family only uses your email for internal purposes."
Response.Write "</center>"

Response.Write "</td></tr></table>"
Response.Write "</td>"
Response.Write "</tr>"

%>
<!--#include VIRTUAL=/Include/HTMLHomeFooter.asp-->
<!--#include VIRTUAL=/Include/DAOFooter.asp-->
<%
sub addUser(lngIdUser)
	strSQL = "SELECT * FROM [User] " & _
			 "WHERE UserIsOnline AND UserLogin='" & Request("UserLogin") & "';"
	rs0.Open strSQL, conConnexion, 3, 2

	if not rs0.eof then
		lngIdUser = -1
	else
		rs0.AddNew
			rs0("UserLogin") = Request("UserLogin")
			rs0("UserPassword") = Request("UserPassword")
			rs0("UserName") = Request("UserName")
			rs0("UserEmail") = Request("UserEmail")
			rs0("UserIsOnline") = true
		rs0.Update
		rs0.MoveFirst
		lngIdUser = rs0("IDUser")
	end if
	rs0.Close
end sub

sub updateUser()
	strSQL = "SELECT * FROM [User] " & _
			 "WHERE IDUser=" & Request("IDUser") & ";"
	rs0.Open strSQL, conConnexion, 3, 2

	if not rs0.eof then
		if Request("UserPassword") <> empty then
			rs0("UserPassword") = Request("UserPassword")
		end if
		rs0("UserName") = Request("UserName")
		rs0("UserEmail") = Request("UserEmail")
		rs0.Update
	end if

	rs0.Close
end sub

sub printJavascript()
	Response.Write "<script language=JavaScript>"
	Response.Write  "function verifySubmit(){"
	Response.Write	 "var UserName = document.MyForm.UserName.value;"
	Response.Write   "var UserEmail = document.MyForm.UserEmail.value;"
	Response.Write   "var UserLogin = document.MyForm.UserLogin.value;"
	Response.Write   "var UserPassword = document.MyForm.UserPassword.value;"
	Response.Write   "var UserPass2 = document.MyForm.UserPass2.value;"
	Response.Write   "if (UserName == ''){"
	Response.Write    "alert(""Please enter your Name!\nEx: John Smith"")"
	Response.Write   "} else if (UserEmail == ''){"
	Response.Write    "alert(""Please enter your Email!\nEx: name@domain.com"")"
	Response.Write   "} else if (UserEmail.indexOf('@') < 1){"
	Response.Write    "alert(""Your Email appears to be erroneous.\nPlease re-enter your Email!"")"
	Response.Write   "} else if (UserEmail.indexOf('.') < 3){"
	Response.Write    "alert(""Your Email appears to be erroneous.\nPlease re-enter your Email!"")"
	Response.Write   "} else if (UserEmail.length < 5){"
	Response.Write    "alert(""Your Email appears to be erroneous.\nPlease re-enter your Email!"")"
	Response.Write   "} else if (UserEmail.charAt(UserEmail.length - 1) == '.'){"
	Response.Write    "alert(""Your Email appears to be erroneous.\nPlease re-enter your Email!"")"
	Response.Write   "} else if (UserLogin == '') {"
	Response.Write    "alert(""Please enter your Login!"")"
	Response.Write   "} else if (UserPassword == '') {"
	Response.Write    "alert(""Please enter your Password!"")"
	Response.Write   "} else if (UserPassword.length < 6) {"
	Response.Write    "alert(""You Password must be at least 6 characters long!"");"
	Response.Write    "document.MyForm.UserPass2.value = '';"
	Response.Write   "} else if (UserPass2 == '') {"
	Response.Write    "alert(""Please enter your Password as second time!"")"
	Response.Write   "} else if (UserPass2 != UserPassword) {"
	Response.Write    "alert(""Please re-enter your Password!"");"
	Response.Write    "document.MyForm.UserPass2.value = '';"
	Response.Write   "} else {"
	Response.Write    "document.MyForm.submit()"
	Response.Write   "}"
	Response.Write  "}"
	Response.Write "</script>"
end sub
%>