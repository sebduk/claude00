<!--#include VIRTUAL=/Include/CodeHeader.asp-->
<%
strConn = "PROVIDER=Microsoft.Jet.OLEDB.4.0;DATA SOURCE=" & server.mappath("/Data/user.mdb") & ";"
%>
<!--#include VIRTUAL=/Include/DAOHeader.asp-->
<%
dim strDomainKey
select case Request("todo")
	case "add"
		addDomain strDomainKey
	case "update"
		updateDomain
end select

dim arrLanguage(), i, intLangTop
redim arrLanguage(2, 7)

intLangTop = 7
arrLanguage(1, 1) = "ENG" : arrLanguage(2, 1) = "English"
arrLanguage(1, 2) = "FRA" : arrLanguage(2, 2) = "Fran&ccedil;ais"
arrLanguage(1, 3) = "ESP" : arrLanguage(2, 3) = "Espa&ntilde;ol"
arrLanguage(1, 4) = "ITA" : arrLanguage(2, 4) = "Italiano"
arrLanguage(1, 5) = "POR" : arrLanguage(2, 5) = "Portugu&ecirc;s"
arrLanguage(1, 6) = "DEU" : arrLanguage(2, 6) = "Deutsch"
arrLanguage(1, 7) = "NLD" : arrLanguage(2, 7) = "Nederlands"

dim arrDate(), intDateTop
redim arrDate(2, 2)

intDateTop = 2
arrDate(1, 1) = "dmy" : arrDate(2, 1) = "Day/Month/Year"
arrDate(1, 2) = "mdy" : arrDate(2, 2) = "Month/Day/Year"


dim strMessage

'Response.Write cleanString(Request("DomainName")) & "<br>"
'if Request("FamilyName") <> empty then
'	strSQL = "INSERT INTO [Domain] " & _
'			 "INSERT INTO [Domain] " & _
'	rs0.Open strSQL, conConnexion
'
'
'else
'	strMessage = "Enter a Family Name."
'end if

%>
<!--#include VIRTUAL=/Include/HTMLHomeHeader.asp-->
<%
Response.Write "<tr valign=top>"
Response.Write "<!--Body-->"
Response.Write "<td height=380>"
Response.Write "<table border=0 height=100% width=100% cellpadding=6 cellspacing=0>"
Response.Write "<tr><td valign=top>"

Response.Write "<form action=treePage.asp method=post name=myForm>"
Response.Write "<table border=0 cellpadding=0 cellspacing=0 align=center>"

if Request("DomainRNDKey") <> empty then strDomainKey = Request("DomainRNDKey")

if strDomainKey <> empty then
	strSQL = "SELECT * FROM [Domain] " & _
			 "WHERE DomainRNDKey='" & strDomainKey & "';"
	rs0.Open strSQL, conConnexion

	if not rs0.eof then
		Response.Write "<input type=hidden name=todo value=update>"
		Response.Write "<input type=hidden name=DomainRNDKey value=""" & rs0("DomainRNDKey") & """>"

		Response.Write "<tr>"
		Response.Write "<td align=right>Family Name</td>"
	'	Response.Write "<td><b>&nbsp;&nbsp;" & rs0("DomainName") & "</b></td>"
		Response.Write "<td><b>&nbsp;&nbsp;<a href=/frameDom.asp?DomainRNDKey=" & rs0("DomainRNDKey") & ">"
		Response.Write "<b>" & rs0("DomainName") & "</a></b></td>"
		Response.Write "</tr>"

		Response.Write "<tr>"
		Response.Write "<td align=right>Family Title</td>"
		Response.Write "<td>&nbsp;<input type=text name=DomainHeadTitle value=""" & rs0("DomainHeadTitle") & """ class=Box150></td>"
		Response.Write "</tr>"

		Response.Write "<tr>"
		Response.Write "<td align=right>Package</td>"
		Response.Write "<td><b>&nbsp;&nbsp;" & rs0("DomainPackage") & "</b>"
		if rs0("DomainPackage") <> "Platinum" then
			Response.Write "&nbsp;&nbsp;&nbsp;<a href=contactUs.asp?todo=upgrade&from=" & rs0("DomainRNDKey") & ">&gt;&gt;&gt;Upgrade&lt;&lt;&lt;"
		else
			Response.Write "*"
		end if
		Response.Write "</td>"
		Response.Write "</tr>"

		if rs0("DomainPackage") = "Platinum" then
			Response.Write "<tr>"
			Response.Write "<td align=right><i>Private URL</i></td>"
			Response.Write "<td><b>&nbsp;&nbsp;<a href=""http://" & rs0("DomainURL") & """ target=_blank>http://" & rs0("DomainURL") & "</a></b>"
			Response.Write "</tr>"

			Response.Write "<tr>"
			Response.Write "<td align=right><i>Visitor Password</i></td>"
			Response.Write "<td>&nbsp;<input type=text name=DomainPwdGuest value=""" & rs0("DomainPwdGuest") & """ class=Box150></td>"
			Response.Write "</tr>"

		'	Response.Write "<tr>"
		'	Response.Write "<td align=right><i>Admin Password</i></td>"
		'	Response.Write "<td>&nbsp;<input type=text name=DomainPwdAdmin value=""" & rs0("DomainPwdAdmin") & """ class=Box150></td>"
		'	Response.Write "</tr>"
		end if

		Response.Write "<tr>"
		Response.Write "<td align=right>Language</td>"
		Response.Write "<td>&nbsp;"
		Response.Write "<select name=DomainLanguage class=Box150>"
		for i = 1 to intLangTop
			Response.Write "<option value=" & arrLanguage(1, i)
			if rs0("DomainLanguage") = arrLanguage(1, i) then Response.Write " selected"
			Response.Write ">" & arrLanguage(2, i)
		next
		Response.Write "</select>"
		Response.Write "</td>"
		Response.Write "</tr>"

		Response.Write "<tr>"
		Response.Write "<td align=right>Date Format</td>"
		Response.Write "<td>&nbsp;"
		Response.Write "<select name=DomainDateFormat class=Box150>"
		for i = 1 to intDateTop
			Response.Write "<option value=" & arrDate(1, i)
			if rs0("DomainDateFormat") = arrDate(1, i) then Response.Write " selected"
			Response.Write ">" & arrDate(2, i)
		next
		Response.Write "</select>"
		Response.Write "</td>"
		Response.Write "</tr>"

		strSQL = "SELECT [User].IDUser, UserName, [Status] " & _
				 "FROM (LkDomainUser INNER JOIN [User] ON [User].IDUser = LkDomainUser.IdUser) " & _
				 "INNER JOIN [Domain] ON [Domain].IDDomain = LkDomainUser.IdDomain " & _
				 "WHERE DomainRNDKey='" & strDomainKey & "' AND [Status]<>'Owner' " & _
				 "ORDER BY [Status]='Admin', [Status]='Guest', UserName;"
		rs1.Open strSQL, conConnexion

		Response.Write "<tr valign=top>"
		Response.Write "<td align=right>Participants</td>"
		Response.Write "<td>&nbsp;"
		Response.Write "<select name=IdPersonne size=8 multiple class=box150>"
		dim strStatus, flgGuest
		flgGuest = false
		strStatus = "Admin"
		Response.Write "<option value=A>********* Admins *********"
		while not rs1.eof
			if strStatus <> rs1("Status") then
				strStatus = rs1("Status")
				flgGuest = true
				Response.Write "<option value=G>********* Guests *********"
			end if
			Response.Write "<option value=" & rs1("IDUser") & ">" & rs1("UserName")
			rs1.MoveNext
		wend
		if flgGuest = false then Response.Write "<option value=G>********* Guests *********"
		Response.Write "</select>"
		Response.Write "</td>"
		Response.Write "</tr>"

		Response.Write "<tr valign=top>"
		Response.Write "<td>&nbsp;</td>"
		Response.Write "<td align=center><b><a href=javascript:MoveUp()>up</a>/<a href=javascript:MoveDwn()>down</a> | <a href=javascript:Remove()>delete</a></b></td>"
		Response.Write "</tr>"

		Response.Write "<tr valign=top>"
		Response.Write "<td align=right>Invitations<br><br>Enter your<br>guests' emails</td>"
		Response.Write "<td>"
		Response.Write "&nbsp;<input type=text name=inviteMail1 class=box150><br>"
		Response.Write "&nbsp;<input type=text name=inviteMail2 class=box150><br>"
		Response.Write "&nbsp;<input type=text name=inviteMail3 class=box150><br>"
		Response.Write "&nbsp;<input type=text name=inviteMail4 class=box150><br>"
		Response.Write "&nbsp;<input type=text name=inviteMail5 class=box150><br>"
		Response.Write "</td>"
		Response.Write "</tr>"

		Response.Write "<tr>"
		Response.Write "<td colspan=2>&nbsp;</td>"
		Response.Write "</tr>"

		Response.Write "<tr>"
		Response.Write "<td>&nbsp;</td>"
		Response.Write "<td>&nbsp;<input type=submit value=""update this Family Tree"" class=Box150 onClick=SelectAll(); id=submit1 name=submit1></td>"
		Response.Write "</tr>"

		if rs0("DomainPackage") = "Platinum" then
			Response.Write "<tr>"
			Response.Write "<td colspan=2>"
			Response.Write "* This package includes:<br>" & _
						   "a Private URL to access your family tree directly<br>" & _
						   "a Visitor Password to protect from random browsing<br>"
			Response.Write "</td>"
			Response.Write "</tr>"
		end if

		Response.Write "<tr>"
		Response.Write "<td colspan=2>&nbsp;</td>"
		Response.Write "</tr>"

		rs1.Close
		printJavacript
	else
		Response.Write "<tr>"
		Response.Write "<td>Error: Wrong RNDKey</td>"
		Response.Write "</tr>"
	end if
else
	Response.Write "<input type=hidden name=todo value=add>"

	Response.Write "<tr>"
	Response.Write "<td align=right>Family Name</td>"
	Response.Write "<td>&nbsp;<input type=text name=DomainName value=""" & Request("DomainName") & """ class=Box150></td>"
	Response.Write "<td>&nbsp;</td>"
	Response.Write "</tr>"

	Response.Write "<tr>"
	Response.Write "<td align=right>Family Title</td>"
	Response.Write "<td>&nbsp;<input type=text name=DomainHeadTitle class=Box150></td>"
	Response.Write "<td>&nbsp;Ex: ""Smith Family Genealogy"".</td>"
	Response.Write "</tr>"

	Response.Write "<tr>"
	Response.Write "<td align=right>Language</td>"
	Response.Write "<td>&nbsp;"
	Response.Write "<select name=DomainLanguage class=Box150>"
	for i = 1 to intLangTop
		Response.Write "<option value=" & arrLanguage(1, i) & ">" & arrLanguage(2, i)
	next
	Response.Write "</select>"
	Response.Write "</td>"
	Response.Write "<td>&nbsp;</td>"
	Response.Write "</tr>"

	Response.Write "<tr>"
	Response.Write "<td align=right>Date Format</td>"
	Response.Write "<td>&nbsp;"
	Response.Write "<select name=DomainDateFormat class=Box150>"
	for i = 1 to intDateTop
		Response.Write "<option value=" & arrDate(1, i) & ">" & arrDate(2, i)
	next
	Response.Write "</select>"
	Response.Write "</td>"
	Response.Write "<td>&nbsp;</td>"
	Response.Write "</tr>"

	Response.Write "<tr>"
	Response.Write "<td colspan=2>&nbsp;</td>"
	Response.Write "</tr>"

	Response.Write "<tr>"
	Response.Write "<td>&nbsp;</td>"
	Response.Write "<td>&nbsp;<input type=submit value=""create this Family Tree"" class=Box150></td>"
	Response.Write "<td>&nbsp;<b>All fields are mandatory.</b></td>"
	Response.Write "</tr>"

	Response.Write "<tr>"
	Response.Write "<td colspan=2>&nbsp;</td>"
	Response.Write "</tr>"

end if

Response.Write "</table>"
Response.Write "</form>"

Response.Write "</td></tr></table>"
Response.Write "</td>"
Response.Write "</tr>"
%>
<!--#include VIRTUAL=/Include/HTMLHomeFooter.asp-->
<!--#include VIRTUAL=/Include/DAOFooter.asp-->
<!--#include VIRTUAL=/Include/FunctEmail.asp-->
<%
function geneRNDKey()
	dim i, strWork
	randomize

	for i = 1 to 15
		strWork = strWork & chr(rnd() * 25 + 97)
	next

	geneRNDKey = strWork
end function

function cleanString(strWork)
	strWork = Replace(strWork, " ", "")
	strWork = Lcase(strWork)
	
	strWork = Replace(strWork, "š", "s")
	strWork = Replace(strWork, "œ", "oe")
	strWork = Replace(strWork, "ž", "z")
	strWork = Replace(strWork, "ÿ", "y")
	strWork = Replace(strWork, "à", "a")
	strWork = Replace(strWork, "á", "a")
	strWork = Replace(strWork, "â", "a")
	strWork = Replace(strWork, "ã", "a")
	strWork = Replace(strWork, "ä", "a")
	strWork = Replace(strWork, "å", "a")
	strWork = Replace(strWork, "æ", "ae")
	strWork = Replace(strWork, "ç", "c")
	strWork = Replace(strWork, "è", "e")
	strWork = Replace(strWork, "é", "e")
	strWork = Replace(strWork, "ê", "e")
	strWork = Replace(strWork, "ë", "e")
	strWork = Replace(strWork, "ì", "i")
	strWork = Replace(strWork, "í", "i")
	strWork = Replace(strWork, "î", "i")
	strWork = Replace(strWork, "ï", "i")
	strWork = Replace(strWork, "ð", "d")
	strWork = Replace(strWork, "ñ", "n")
	strWork = Replace(strWork, "ò", "o")
	strWork = Replace(strWork, "ó", "o")
	strWork = Replace(strWork, "ô", "o")
	strWork = Replace(strWork, "õ", "o")
	strWork = Replace(strWork, "ö", "o")
	strWork = Replace(strWork, "ø", "o")
	strWork = Replace(strWork, "ù", "u")
	strWork = Replace(strWork, "ú", "u")
	strWork = Replace(strWork, "û", "u")
	strWork = Replace(strWork, "ü", "u")
	strWork = Replace(strWork, "ý", "y")
	strWork = Replace(strWork, "þ", "o")
	strWork = Replace(strWork, "ß", "ss")

	for i = 0 to 47
		strWork = Replace(strWork, chr(i), "")
	next
	for i = 58 to 96
		strWork = Replace(strWork, chr(i), "")
	next
	for i = 123 to 255
		strWork = Replace(strWork, chr(i), "")
	next
	cleanString = strWork
end function

sub addDomain(strDomainKey)
	dim lgnIDDomain, strCleanDomain
	strDomainKey = geneRNDKey()

	strSQL = "SELECT * FROM [Domain] WHERE IDDomain=0;"
	rs0.Open strSQL, conConnexion, 3, 2
	rs0.addNew
		rs0("DomainName") = Request("DomainName")
		rs0("DomainLanguage") = Request("DomainLanguage")
		rs0("DomainDateFormat") = Request("DomainDateFormat")
		rs0("DomainHeadTitle") = Request("DomainHeadTitle")
		rs0("DomainPackage") = "Starter"
		rs0("DomainRNDKey") = strDomainKey
		rs0("DomainIsOnline") = true
	rs0.update
	rs0.MoveFirst
		lgnIDDomain = rs0("IDDomain")
		strCleanDomain = cleanString(Request("DomainName"))
		rs0("DomainDB") = lgnIDDomain & "-" & strCleanDomain & ".mdb"
		rs0("DomainUpload") = lgnIDDomain & "-" & strCleanDomain
	rs0.update
	rs0.Close
	strSQL = "INSERT INTO LkDomainUser " & _
			 "(IdDomain, IdUser, Status) " & _
			 "SELECT " & _
			 lgnIDDomain & ", " & _
			 Session("IDUser") & ", " & _
			 "'Owner';"
	rs0.Open strSQL, conConnexion

	Dim fso, strCreateFolder, strDBOld, strDBNew, fsoFolder
	Set fso = CreateObject("Scripting.FileSystemObject")

	strCreateFolder = server.mappath("/Gene/File/" & lgnIDDomain & "-" & strCleanDomain)
	Set fsoFolder = fso.CreateFolder(strCreateFolder)
	strCreateFolder = server.mappath("/Gene/File/" & lgnIDDomain & "-" & strCleanDomain & "/Document")
	Set fsoFolder = fso.CreateFolder(strCreateFolder)
	strCreateFolder = server.mappath("/Gene/File/" & lgnIDDomain & "-" & strCleanDomain & "/Image")
	Set fsoFolder = fso.CreateFolder(strCreateFolder)

	strDBOld = server.mappath("/Gene/Data/0-empty.mdb")
	strDBNew = server.mappath("/Gene/Data/" & lgnIDDomain & "-" & strCleanDomain & ".mdb")
	fso.CopyFile strDBOld, strDBNew

	Set fso = nothing
end sub

sub updateDomain()
	dim strIdPersonne, intPos, lngID, strStatus, i
	strSQL = "SELECT * FROM [Domain] WHERE DomainRNDKey='" & Request("DomainRNDKey") & "';"
	rs0.Open strSQL, conConnexion, 3, 2
	if not rs0.eof then
		rs0("DomainLanguage") = Request("DomainLanguage")
		rs0("DomainDateFormat") = Request("DomainDateFormat")
		if Request("DomainHeadTitle") <> empty then
			rs0("DomainHeadTitle") = Request("DomainHeadTitle")
		else
			rs0("DomainHeadTitle") = rs0("DomainName")
		end if
		if Request("DomainPwdGuest") <> empty then
			rs0("DomainPwdGuest") = Request("DomainPwdGuest")
		else
			rs0("DomainPwdGuest") = null
		end if
	'	if Request("DomainPwdAdmin") <> empty then
	'		rs0("DomainPwdAdmin") = Request("DomainPwdAdmin")
	'	else
	'		rs0("DomainPwdAdmin") = rs0("DomainName")
	'	end if
		'rs0("DomainPackage") = "Starter"
		rs0.update

		strSQL = "DELETE * FROM LkDomainUser " & _
				 "WHERE [Status]<>'Owner' AND IdDomain=" & rs0("IDDomain") & ";"
		rs1.Open strSQL, conConnexion

		strIdPersonne = Request("IdPersonne")
		intPos = instr(strIdPersonne, ",")
		while intPos > 0
			lngID = left(strIdPersonne, intPos - 1)
			if lngID = "A" then
				strStatus = "Admin"
			elseif lngID = "G" then
				strStatus = "Guest"
			else
				strSQL = "INSERT INTO LkDomainUser (IdDomain, IdUser, [Status]) " & _
						 "SELECT " & _
						 rs0("IDDomain") & ", " & _
						 lngID & ", " & _
						 "'" & strStatus & "';"
				rs1.Open strSQL, conConnexion
			end if
			strIdPersonne = mid(strIdPersonne, intPos + 2)
			intPos = instr(strIdPersonne, ",")
		wend

		lngID = trim(strIdPersonne)
		if lngID = "G" then
			strStatus = "Guest"
		else
			strSQL = "INSERT INTO LkDomainUser (IdDomain, IdUser, [Status]) " & _
					 "SELECT " & _
					 rs0("IDDomain") & ", " & _
					 lngID & ", " & _
					 "'" & strStatus & "';"
			rs1.Open strSQL, conConnexion
		end if

		dim strTo, strSubject, strBody
		for i = 1 to 5
			if Request("inviteMail" & i) <> empty then
				strTo = Request("inviteMail" & i)
				strSubject = "Invitation to See Our Family" 
				strBody = "Hi, <br>" & _
						  "you have been invited to join the """ & rs0("DomainHeadTitle") & """ Family Tree in <b>See Our Family</b>.<br><br>" & _
						  "You should first got to the See Our Family site and Sign In.<br>" & _
						  "<a href=http://www.see-our-family.com target=_blank>http://www.see-our-family.com</a><br><br>" & _
						  "You either need to Login or Create a New Account if you don't yet have one.<br><br>" & _
						  "Follow <b>Go to your Family Tree</b> and enter your Family Key: <b>" & Request("DomainRNDKey") & "</b><br><br>" & _
						  "Please enjoy See Our Family and don't hesitate to Contact Us if you have any question.<br><br>" & _
						  "The See Our Family Team"

				sendMail strTo, "See Our Family", strTo, strSubject, strBody
			end if
		next
	end if
	rs0.Close
end sub

sub printJavacript()
	Response.Write "<script language=""JavaScript"">"
	Response.Write "function Remove(){"
	Response.Write	"var lstR = document.myForm.IdPersonne, tabValR = new Array(), tabTxtR = new Array();"
	Response.Write	"var i, j = 0, ItemCount = lstR.options.length;"
	Response.Write	"for (i=0; i<ItemCount; i++) {"
	Response.Write		"if ("
	Response.Write		"(lstR.options[i].value != lstR.options[lstR.selectedIndex].value) || "
	Response.Write		"(lstR.options[i].value == 'A') || "
	Response.Write		"(lstR.options[i].value == 'G')"
	Response.Write			") {"
	Response.Write			"tabValR[j] = lstR.options[i].value;"
	Response.Write			"tabTxtR[j++] = lstR.options[i].text;"
	Response.Write		"}"
	Response.Write	"}"
	Response.Write	"for (i=0; i<j; i++) {"
	Response.Write		"var no = new Option();"
	Response.Write		"no.value = tabValR[i];"
	Response.Write		"no.text = tabTxtR[i];"
	Response.Write		"lstR[i] = no;"
	Response.Write	"}"
	Response.Write	"lstR[j] = null;"
	Response.Write "}"

	Response.Write "function MoveUp(){"
	Response.Write	"var lstR = document.myForm.IdPersonne, lstSI = lstR.selectedIndex - 1;"
	Response.Write	"var tabValR = new Array(), tabTxtR = new Array();"
	Response.Write	"var i, j = 0, ItemCount = lstR.options.length;"
	Response.Write	"if (lstSI >= 1) {"
	Response.Write		"for (i=0; i<ItemCount; i++) {"
	Response.Write			"tabValR[j] = lstR.options[i].value;"
	Response.Write			"tabTxtR[j++] = lstR.options[i].text;"
	Response.Write		"}"
	Response.Write		"for (i=0; i<j; i++) {"
	Response.Write			"if (i == lstSI) {"
	Response.Write				"var no = new Option();"
	Response.Write				"no.value = tabValR[i+1];"
	Response.Write				"no.text = tabTxtR[i+1];"
	Response.Write				"lstR[i] = no;"
	Response.Write				"var no = new Option();"
	Response.Write				"no.value = tabValR[i];"
	Response.Write				"no.text = tabTxtR[i];"
	Response.Write				"lstR[i+1] = no;"
	Response.Write				"i++;i++;"
	Response.Write			"}"
	Response.Write			"else {"
	Response.Write				"var no = new Option();"
	Response.Write				"no.value = tabValR[i];"
	Response.Write				"no.text = tabTxtR[i];"
	Response.Write				"lstR[i] = no;"
	Response.Write			"}"
	Response.Write		"}"
	Response.Write		"lstR.options[lstSI].selected = true;"
	Response.Write	"}"
'	Response.Write	"else {"
'	Response.Write		"lstR.options[1].selected = true;"
'	Response.Write	"}"
	Response.Write "}"

	Response.Write "function MoveDwn(){"
	Response.Write	"var lstR = document.myForm.IdPersonne, lstSI = lstR.selectedIndex;"
	Response.Write	"var tabValR = new Array(), tabTxtR = new Array();"
	Response.Write	"var i, j = 0, ItemCount = lstR.options.length;"
	Response.Write	"if ((lstSI >= 1) && (lstSI < ItemCount - 1)) {"
	Response.Write		"for (i=0; i<ItemCount; i++) {"
	Response.Write			"tabValR[j] = lstR.options[i].value;"
	Response.Write			"tabTxtR[j++] = lstR.options[i].text;"
	Response.Write		"}"
	Response.Write		"for (i=0; i<j; i++) {"
	Response.Write			"if (i == lstSI) {"
	Response.Write				"var no = new Option();"
	Response.Write				"no.value = tabValR[i+1];"
	Response.Write				"no.text = tabTxtR[i+1];"
	Response.Write				"lstR[i] = no;"
	Response.Write				"var no = new Option();"
	Response.Write				"no.value = tabValR[i];"
	Response.Write				"no.text = tabTxtR[i];"
	Response.Write				"lstR[i+1] = no;"
	Response.Write				"i++;i++;"
	Response.Write			"}"
	Response.Write			"else {"
	Response.Write				"var no = new Option();"
	Response.Write				"no.value = tabValR[i];"
	Response.Write				"no.text = tabTxtR[i];"
	Response.Write				"lstR[i] = no;"
	Response.Write			"}"
	Response.Write		"}"
	Response.Write		"lstR.options[lstSI + 1].selected = true;"
	Response.Write	"}"
	Response.Write "}"

	Response.Write "function SelectAll(){"
	Response.Write	"var lstR = document.myForm.IdPersonne, ItemCount = lstR.length;"
	Response.Write	"lstR.multiple = true;"
	Response.Write	"lstR.focus();"
	Response.Write	"for (var i=0; i<ItemCount; i++) {"
	Response.Write		"lstR.options[i].selected = true;"
	Response.Write	"}"
	Response.Write "}"
	Response.Write "</script>"
end sub
%>