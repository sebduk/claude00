<!--#include VIRTUAL=/Include/CodeHeader.asp-->
<%
strConn = "PROVIDER=Microsoft.Jet.OLEDB.4.0;DATA SOURCE=" & server.mappath("/Data/user.mdb") & ";"
%>
<!--#include VIRTUAL=/Include/DAOHeader.asp-->
<%
dim strMessage
if Request("login") <> empty and Request("pswd") <> empty then
	strSQL = "SELECT * FROM [User] " & _
			 "WHERE UserIsOnline AND UserLogin='" & Request("login") & "' AND " & _
			 "UserPassword='" & Request("pswd") & "';"
	'Response.Write strSQL & "<br>"
	rs0.Open strSQL, conConnexion

	if not rs0.eof then
		Session("IDUser") = rs0("IDUser")
		Session("UserName") = rs0("UserName")
	else
		strMessage = "<br><center><b>Please verify your Login and Password or Create a new account.</b></center>"
	end if
	rs0.Close
else
	strMessage = "<br><center><b>Please enter your Login and Password or Create a new account.</b></center>"
end if

if Request("DomainRNDKey") <> empty and Session("IDUser") <> empty then
	strSQL = "SELECT * FROM [Domain] " & _
			 "WHERE DomainRNDKey='" & Request("DomainRNDKey") & "';"
	'Response.Write strSQL & "<br>"
	rs0.Open strSQL, conConnexion

	if not rs0.eof then
		strSQL = "SELECT * FROM LkDomainUser " & _
				 "WHERE IdDomain=" & rs0("IDDomain") & " AND IdUser=" & Session("IDUser") & ";"
		'Response.Write strSQL & "<br>"
		rs1.Open strSQL, conConnexion, 3, 2

		if rs1.eof then
			rs1.AddNew
			rs1("IdDomain") = rs0("IDDomain")
			rs1("IdUser") = Session("IDUser")
			rs1("Status") = "Guest"
			rs1.Update
		end if
		rs1.Close
	end if
	rs0.Close
else
	strMessage = "<br><center><b>Please enter your Login and Password or Create a new account.</b></center>"
end if

%>
<!--#include VIRTUAL=/Include/HTMLHomeHeader.asp-->
<%
Response.Write "<tr valign=top>"
Response.Write "<!--Body-->"
Response.Write "<td height=380>"
Response.Write "<table border=0 height=100% width=100% cellpadding=6 cellspacing=0>"
Response.Write "<tr><td valign=top>"


if Session("IDUser") <> empty then
	strSQL = "SELECT DomainName, DomainRNDKey, DomainPackage, DomainURL, [Status] " & _
			 "FROM [Domain] INNER JOIN LkDomainUser ON [Domain].IDDomain = LkDomainUser.IdDomain " & _
			 "WHERE DomainIsOnline AND IdUser=" & Session("IDUser") & " " & _
			 "ORDER BY " & _
			 "[Status]='Owner', [Status]='Admin', [Status]='Guest', " & _
			 "DomainPackage='Platinum', DomainPackage='Gold', DomainPackage='Starter', " & _
			 "DomainName;"
	'Response.Write strSQL & "<br>"
	rs0.Open strSQL, conConnexion

	dim strStatus
	if not rs0.eof then
		Response.Write "<table border=0 cellpadding=0 cellspacing=0>"
		Response.Write "<tr><td><b>Enter your family tree&nbsp;</b></td><td colspan=3>&nbsp;</td></tr>" '<br><br>"
		while not rs0.eof
			if strStatus <> rs0("Status") then
				strStatus = rs0("Status")
				Response.Write "<tr>"
				Response.Write "<td align=center><br><b>" & strStatus & "&nbsp;</b></td>"
				Response.Write "<td colspan=3>&nbsp;</td>"
				Response.Write "</tr>"
			end if
			
			Response.Write "<tr>"
			Response.Write "<td align=right><a href=/frameDom.asp?DomainRNDKey=" & rs0("DomainRNDKey") & " target=nohide>"
			Response.Write "<b>" & rs0("DomainName") & "</b></a>&nbsp</td>"
		'	Response.Write "<td><b>"
		'	Response.Write rs0("Status")
		'	Response.Write "&nbsp;</b></td>"
			if rs0("Status") = "Owner" then
				Response.Write "<td>&nbsp;<a href=treePage.asp?DomainRNDKey=" & rs0("DomainRNDKey") & ">Update site profile</a></td>"
			else
				Response.Write "<td>&nbsp;</td>"
			end if
			Response.Write "<td>&nbsp;|&nbsp;" & rs0("DomainPackage") & "</td>"
			if rs0("DomainPackage") = "Platinum" then
			Response.Write "<td>&nbsp;|&nbsp;<a href=http://" & rs0("DomainURL") & " target=_top>http://" & rs0("DomainURL") & "</td>"
			else
				Response.Write "<td>&nbsp;</td>"
			end if
			Response.Write "</tr>"
			rs0.MoveNext
		wend
		Response.Write "</table>"
	else
		Response.Write "<b>We found no Family Tree for your account.</b><br>"
	end if
	rs0.Close


	Response.Write "</td></tr><tr><td valign=bottom>"


	Response.Write "<table border=0 cellpadding=0 cellspacing=0>"
	Response.Write "<tr><td colspan=2><b>Join an existing Family Tree</b></td></tr>"
	Response.Write "<form action=domain.asp method=post name=joinTree>"
	Response.Write "<tr><td>Family Key&nbsp;</td>"
	Response.Write "<td><input type=text name=DomainRNDKey class=box150>"
	Response.Write "<input type=submit value=""access the new Family Tree"" class=box150></td></tr>"
	Response.Write "</form>"

	Response.Write "<tr><td colspan=2><br><b>Create a new Family Tree</b></td></tr>"
	Response.Write "<form action=treePage.asp method=post name=createTree onSubmit=""return checkForm()"">"
	Response.Write "<tr><td>Family Name&nbsp;</td>"
	Response.Write "<td><input type=text name=DomainName class=box150>"
	Response.Write "<input type=submit value=""create this Family Tree"" class=box150></td></tr>"
	Response.Write "<tr><td colspan=2><i>&laquo;I have read the <a href=/policy.asp>See Our Family Policy</a> and agree to follow it&raquo;</i>: <input type=checkbox name=PolicyCheck></td></tr>"
	Response.Write "</form>"
	Response.Write "</table>"
else
	Response.Write "<center><br><br><br>"
	Response.Write "<a href=signIn.asp><img src=/Image/createAccount.gif border=0></a>"
	Response.Write "</center>"

	Response.Write strMessage
end if


Response.Write "</td></tr></table>"
Response.Write "</td>"
Response.Write "</tr>"

Response.Write "<script language=JavaScript>"
Response.Write "function checkForm(){"
Response.Write "if (document.createTree.DomainName.value == '') {"
Response.Write "alert('Please enter a Family Name.');"
Response.Write "return false;"
Response.Write "}"
Response.Write "else if (document.createTree.PolicyCheck.checked == false) {"
Response.Write "alert('Please check our Policy box.');"
Response.Write "return false;"
Response.Write "}"
Response.Write "else {"
Response.Write "return true;"
Response.Write "}"
Response.Write "}"
Response.Write "</script>"
%>
<!--#include VIRTUAL=/Include/HTMLHomeFooter.asp-->
<!--#include VIRTUAL=/Include/DAOFooter.asp-->
