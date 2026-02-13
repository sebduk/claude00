<%
Response.Write "<html>"
Response.Write "<head>"
Response.Write "<title>www.see-our-family.com</title>"
Response.Write "<link rel=stylesheet type=text/css href=/style.css>"
Response.Write "<meta http-equiv=""Content-Type"" content=""text/html; charset=iso-8859-1"" />"
Response.Write "</head>"

Response.Write "<body bgcolor=silver topmargin=0 leftmargin=0 rightmargin=0 bottommargin=0>"

Response.Write "<table border=0 width=950 height=500 align=left cellpadding=0 cellspacing=0 bgcolor=white>"

Response.Write "<tr valign=top height=100>"
Response.Write "<td>"
Response.Write "<a href=/home.asp><img src=/Image/SeeOurFamily.jpg border=0 width=800 height=100></a>"
Response.Write "</td>"
'Response.Write "<!--Advertising-->"
'Response.Write "<td bgcolor=#BAEE70 width=150 align=center rowspan=8>"
'Response.Write "[Advertising]<br>"
'Response.Write "<img src=/Pub/120-600.gif width=120 height=600>"
'Response.Write "<object data=/Pub/pub.asp?Size=120x600 type=text/html border=0 width=124 height=604></object>"
'Response.Write "<iframe src=/Pub/pub.asp?Size=120x600 width=120 height=600 scrolling=no frameborder=0></iframe>"
'Response.Write "</td>"
Response.Write "</tr>"


Response.Write "<tr>"
Response.Write "<td height=94 background=/Image/HeadBG2.jpg valign=top>"
Response.Write "<table border=0 width=100% cellpadding=0 cellspacing=0>"
Response.Write "<tr>"
Response.Write "<td height=20>&nbsp;"
Response.Write "<a href=/home.asp>Home</a> | "
Response.Write "<a href=/whoWeAre.asp>Who we are</a> | "
'Response.Write "<a href=/guide.asp>User Guide</a> | "
Response.Write "<a href=javascript:openHelp();>Help</a> | "
Response.Write "<a href=/contactUs.asp>Contact Us</a>"
Response.Write "</td>"
Response.Write "<td>&nbsp;</td>"
Response.Write "</tr>"

Response.Write "<script language=Javascript>"
Response.Write "function openHelp(){" & _
			   "newWindow=window.open(" & _
			   """/Help/frame.asp"" , " & _
			   """Help"", " & _
			   """toolbar=0,location=0,directories=0,status=0,menubar=0,scrollbars=1," & _
			   "resizable=0,copyhistory=0,width=500,height=350"")" & _
			   ";}"
Response.Write "</script>"


if Session("IDUser") <> empty then
	Response.Write "<tr>"
	Response.Write "<td><h1>&nbsp;<a href=/domain.asp>Go to your Family Tree</a></h1></td>"
	Response.Write "<td align=right>"
	Response.Write "<b>Welcome " & Session("UserName") & "!</b>&nbsp;<br><br>"
	Response.Write "<a href=/signIn.asp?User=me>Update your account</a>&nbsp;<br>"
	Response.Write "<a href=/home.asp?log=off>Logoff</a>&nbsp;<br>"
	Response.Write "</td>"
	Response.Write "</tr>"
else
	Response.Write "<tr>"
	Response.Write "<td>&nbsp;</td>"
	Response.Write "<form action=/domain.asp name=myForm method=post>"
	Response.Write "<td align=right>"
	Response.Write "<input type=hidden name=password>"
	Response.Write "Login <input type=text name=login value=""" & Request("login") & """ class=login><br>"
	Response.Write "Password <input type=password name=pswd class=login><br>"
	Response.Write "<input type=submit value=enter class=login><br>"
	Response.Write "<a href=contactUs.asp?todo=forgotPass>Forgot your password?</a>"
	Response.Write "</td>"
	Response.Write "</form>"
	Response.Write "<script language=javascript>"
	Response.Write "document.forms.myForm.login.focus();"
	Response.Write "</script>"
	Response.Write "</tr>"
end if
Response.Write "</table>"
Response.Write "</td>"
Response.Write "</tr>"
%>