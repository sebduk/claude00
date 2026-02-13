<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
Dim i, intNbChildren

Response.Write "<form action=persWizard.asp method=post>"
Response.Write "<table border=0>"

Response.Write "<tr valign=top><td colspan=2 align=center>"
Response.Write "<h1>People Wizard</h1>"
Response.Write "</td></tr>"

select case Request("todo")
	case "save"
		doSave 
		doSearch 
	case "search", "search again"
		doSearch 
	case else
		doForm
end select

Response.Write "</table>"
Response.Write "</form>"

'Response.Write "<br><a href=persWizard.asp>reload</a>"
Response.Write "<p><a href=persList.asp target=left>&lt;&lt;&lt; Refresh the Person list &lt;&lt;&lt;</a></p>"
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->
<!--#include VIRTUAL="/Include/DAOFooter.asp"-->

<%
sub doForm()
	if Request("todo") = "+++ Add a child +++" then
		intNbChildren = clng(Request("intNbChildren")) + 1
	elseif Request("todo") = "--- Remove a child ---" then
		intNbChildren = clng(Request("intNbChildren")) - 1
	else
		intNbChildren = 4
	end if
	
	Response.Write "<tr valign=top><td colspan=2 align=center>"
	Response.Write "<hr size=1 noshade>"
	Response.Write "</td></tr>"

	Response.Write "<tr>"
	Response.Write "<td align=center>"
		printMiniProfile "MFather"
	Response.Write "</td>"

	Response.Write "<td align=center>"
		printMiniProfile "MMother"
	Response.Write "</td>"
	Response.Write "</tr>"

	Response.Write "<tr valign=top><td colspan=2 align=center>"
		printMiniProfile "MPerson"
	Response.Write "</td></tr>"

	Response.Write "<tr valign=top><td colspan=2 align=center>"
	Response.Write "<hr size=1 noshade>"
	Response.Write "</td></tr>"

	Response.Write "<tr>"
	Response.Write "<td align=center>"
		printMiniProfile "FFather"
	Response.Write "</td>"

	Response.Write "<td align=center>"
		printMiniProfile "FMother"
	Response.Write "</td>"
	Response.Write "</tr>"

	Response.Write "<tr valign=top><td colspan=2 align=center>"
		printMiniProfile "FPerson"
	Response.Write "</td></tr>"

	Response.Write "<tr valign=top><td colspan=2 align=center>"
	Response.Write "<hr size=1 noshade>"
	Response.Write "</td></tr>"

	Response.Write "<tr valign=top>"
	Response.Write "<td colspan=2 align=center>"
	Response.Write "<b>Children</b><br>"
	Response.Write "<table>"
	for i = 0 to intNbChildren
		printChild i
	next
	Response.Write "<tr>"
	Response.Write "<td>&nbsp;</td>"
	Response.Write "<td colspan=5 align=center>"
	Response.Write "<input type=hidden name=intNbChildren value=" & intNbChildren & ">"
	Response.Write "<input type=submit name=todo value=""+++ Add a child +++"" class=box> "
	Response.Write "<input type=submit name=todo value=""--- Remove a child ---"" class=box></td>"
	Response.Write "</tr>"

	Response.Write "</table>"
	Response.Write "</td>"
	Response.Write "</tr>"

	Response.Write "<tr valign=top><td colspan=2 align=center>"
	Response.Write "<hr size=1 noshade>"
	Response.Write "</td></tr>"

	Response.Write "<tr valign=top><td colspan=2 align=center>"
	Response.Write "<input type=submit name=todo value=search class=box> "
	Response.Write "<input type=submit name=todo value=clear class=box>"
	Response.Write "</td></tr>"
end sub

sub doSearch()
	intNbChildren = Request("intNbChildren")
	
	Response.Write "<tr valign=top><td colspan=2 align=center>"
	Response.Write "<hr size=1 noshade>"
	Response.Write "</td></tr>"

	Response.Write "<tr>"
	Response.Write "<td align=center>"
		printMiniProfileSearch "MFather"
	Response.Write "</td>"

	Response.Write "<td align=center>"
		printMiniProfileSearch "MMother"
	Response.Write "</td>"
	Response.Write "</tr>"

	Response.Write "<tr valign=top><td colspan=2 align=center>"
		printMiniProfileSearch "MPerson"
	Response.Write "</td></tr>"

	Response.Write "<tr valign=top><td colspan=2 align=center>"
	Response.Write "<hr size=1 noshade>"
	Response.Write "</td></tr>"

	Response.Write "<tr>"
	Response.Write "<td align=center>"
		printMiniProfileSearch "FFather"
	Response.Write "</td>"

	Response.Write "<td align=center>"
		printMiniProfileSearch "FMother"
	Response.Write "</td>"
	Response.Write "</tr>"

	Response.Write "<tr valign=top><td colspan=2 align=center>"
		printMiniProfileSearch "FPerson"
	Response.Write "</td></tr>"

	Response.Write "<tr valign=top><td colspan=2 align=center>"
	Response.Write "<hr size=1 noshade>"
	Response.Write "</td></tr>"

	Response.Write "<tr valign=top>"
	Response.Write "<td colspan=2 align=center>"
	Response.Write "<b>Children</b><br>"
	Response.Write "<table>"
	for i = 0 to intNbChildren
		printChildSearch i
	next
	Response.Write "<tr>"
	Response.Write "<td>&nbsp;</td>"
	Response.Write "<td colspan=6 align=center>"
	Response.Write "<input type=hidden name=intNbChildren value=" & intNbChildren & ">"
	Response.Write "<input type=submit name=todo value=""+++ Add a child +++"" class=box> "
	Response.Write "<input type=submit name=todo value=""--- Remove a child ---"" class=box></td>"
	Response.Write "</tr>"

	Response.Write "</table>"
	Response.Write "</td>"
	Response.Write "</tr>"

	Response.Write "<tr valign=top><td colspan=2 align=center>"
	Response.Write "<hr size=1 noshade>"
	Response.Write "</td></tr>"

	Response.Write "<tr valign=top><td colspan=2 align=center>"
	Response.Write "<input type=submit name=todo value=""search again"" class=box> "
	Response.Write "<input type=submit name=todo value=save class=box> "
	Response.Write "<input type=submit name=todo value=clear class=box>"
	Response.Write "</td></tr>"
end sub

sub printMiniProfile(strField)
'strField = MFather | MMother | FFather | FMother | MPerson | FPerson 
	dim strNameEx, strDateEx

	select case strField
		case "MFather", "FFather"
			Response.Write "Father<br>"
		case "MMother", "FMother"
			Response.Write "Mother<br>"
		case "MPerson"
			Response.Write "<b>Man</b><br>"
			strNameEx = "(John | Smith)"
			strDateEx = "(1915 | 1995)"
		case "FPerson"
			Response.Write "<b>Woman</b><br>"
			strNameEx = "(Mary | Jones)"
			strDateEx = "(1920 | 2002)"
	end select

	Response.Write "<table border=0 cellpadding=0 cellspacing=0>"

	if Request("todo") = "clear" then
		select case strField
			case "MFather", "FFather", "MMother", "FMother"
				Response.Write "<tr valign=top><td align=center>"
				Response.Write "<input type=text size=15 name=" & strField & "Prenom "
				Response.Write	"value="""" class=box> "
				Response.Write "<input type=text size=15 name=" & strField & "Nom "
				Response.Write	"value="""" class=box><br>"
				Response.Write "<input type=text size=5 name=" & strField & "DtNaiss "
				Response.Write	"value="""" class=box> "
				Response.Write "<input type=text size=5 name=" & strField & "DtDec "
				Response.Write	"value="""" class=box>"
				Response.Write "</td></tr>"
			case "MPerson", "FPerson"
				Response.Write "<tr valign=top>"
				Response.Write "<td width=120 align=right>Name&nbsp;</td><td align=center>"
				Response.Write "<input type=text size=20 name=" & strField & "Prenom "
				Response.Write	"value="""" class=box> "
				Response.Write "<input type=text size=20 name=" & strField & "Nom "
				Response.Write	"value="""" class=box>"
				Response.Write "</td><td width=120 align=center>" & strNameEx
				Response.Write "</td></tr>"

				Response.Write "<tr valign=top>"
				Response.Write "<td align=right>Dates&nbsp;</td><td align=center>"
				Response.Write "<input type=text size=5 name=" & strField & "DtNaiss "
				Response.Write	"value="""" class=box> "
				Response.Write "<input type=text size=5 name=" & strField & "DtDec "
				Response.Write	"value="""" class=box>"
				Response.Write "</td><td align=center>" & strDateEx
				Response.Write "</td></tr>"
		end select
	else
		select case strField
			case "MFather", "FFather", "MMother", "FMother"
				Response.Write "<tr valign=top><td align=center>"
				Response.Write "<input type=text size=15 name=" & strField & "Prenom "
				Response.Write	"value=""" & Request(strField & "Prenom") & """ class=box> "
				Response.Write "<input type=text size=15 name=" & strField & "Nom "
				Response.Write	"value=""" & Request(strField & "Nom") & """ class=box><br>"
				Response.Write "<input type=text size=5 name=" & strField & "DtNaiss "
				Response.Write	"value=""" & Request(strField & "DtNaiss") & """ class=box> "
				Response.Write "<input type=text size=5 name=" & strField & "DtDec "
				Response.Write	"value=""" & Request(strField & "DtDec") & """ class=box>"
				Response.Write "</td></tr>"
			case "MPerson", "FPerson"
				Response.Write "<tr valign=top>"
				Response.Write "<td width=120 align=right>Name&nbsp;</td><td align=center>"
				Response.Write "<input type=text size=20 name=" & strField & "Prenom "
				Response.Write	"value=""" & Request(strField & "Prenom") & """ class=box> "
				Response.Write "<input type=text size=20 name=" & strField & "Nom "
				Response.Write	"value=""" & Request(strField & "Nom") & """ class=box>"
				Response.Write "</td><td width=120 align=center>" & strNameEx
				Response.Write "</td></tr>"

				Response.Write "<tr valign=top>"
				Response.Write "<td align=right>Dates&nbsp;</td><td align=center>"
				Response.Write "<input type=text size=5 name=" & strField & "DtNaiss "
				Response.Write	"value=""" & Request(strField & "DtNaiss") & """ class=box> "
				Response.Write "<input type=text size=5 name=" & strField & "DtDec "
				Response.Write	"value=""" & Request(strField & "DtDec") & """ class=box>"
				Response.Write "</td><td align=center>" & strDateEx
				Response.Write "</td></tr>"
		end select
	end if

	Response.Write "</table>"
end sub

sub printMiniProfileSearch(strField)
'strField = MFather | MMother | FFather | FMother | MPerson | FPerson 
	dim strNameEx, strDateEx

	select case strField
		case "MFather", "FFather"
			Response.Write "Father<br>"
			doSearchPerson strField, "M"
		case "MMother", "FMother"
			Response.Write "Mother<br>"
			doSearchPerson strField, "F"
		case "MPerson"
			Response.Write "<b>Man</b><br>"
			doSearchPerson strField, "M"
			strNameEx = "(John | Smith)"
			strDateEx = "(1915 | 1995)"
		case "FPerson"
			Response.Write "<b>Woman</b><br>"
			doSearchPerson strField, "F"
			strNameEx = "(Mary | Jones)"
			strDateEx = "(1920 | 2002)"
	end select

	Response.Write "<table border=0 cellpadding=0 cellspacing=0>"

	select case strField
		case "MFather", "FFather", "MMother", "FMother"
			Response.Write "<tr valign=top><td align=center>"
			Response.Write "<input type=text size=15 name=" & strField & "Prenom value=""" & Request(strField & "Prenom") & """ class=box> "
			Response.Write "<input type=text size=15 name=" & strField & "Nom value=""" & Request(strField & "Nom") & """ class=box><br>"
			Response.Write "<input type=text size=5 name=" & strField & "DtNaiss value=""" & Request(strField & "DtNaiss") & """ class=box> "
			Response.Write "<input type=text size=5 name=" & strField & "DtDec value=""" & Request(strField & "DtDec") & """ class=box>"
			Response.Write "</td></tr>"
		case "MPerson", "FPerson"
			Response.Write "<tr valign=top>"
			Response.Write "<td width=120 align=right>Name&nbsp;</td><td align=center>"
			Response.Write "<input type=text size=20 name=" & strField & "Prenom value=""" & Request(strField & "Prenom") & """ class=box> "
			Response.Write "<input type=text size=20 name=" & strField & "Nom value=""" & Request(strField & "Nom") & """ class=box>"
			Response.Write "</td><td width=120 align=center>" & strNameEx
			Response.Write "</td></tr>"

			Response.Write "<tr valign=top>"
			Response.Write "<td align=right>Dates&nbsp;</td><td align=center>"
			Response.Write "<input type=text size=5 name=" & strField & "DtNaiss value=""" & Request(strField & "DtNaiss") & """ class=box> "
			Response.Write "<input type=text size=5 name=" & strField & "DtDec value=""" & Request(strField & "DtDec") & """ class=box>"
			Response.Write "</td><td align=center>" & strDateEx
			Response.Write "</td></tr>"
	end select

	Response.Write "</table>"
end sub

sub printChild(intPosition)
	if intPosition = 0 then
		Response.Write "<tr>"
		Response.Write "<td>&nbsp;</td>"
		Response.Write "<td>First Name</td>"
		Response.Write "<td>Last Name</td>"
		Response.Write "<td>Birth</td>"
		Response.Write "<td>Death</td>"
		Response.Write "<td>Gender</td>"
		Response.Write "</tr>"
	else
		if Request("todo") = "clear" then
			Response.Write "<tr>"
			Response.Write "<td>" & intPosition & "</td>"
			Response.Write "<td><input type=text size=20 name=C" & intPosition & "Prenom value="""" class=box></td>"
			Response.Write "<td><input type=text size=20 name=C" & intPosition & "Nom value="""" class=box></td>"
			Response.Write "<td><input type=text size=5 name=C" & intPosition & "DtNaiss value="""" class=box></td>"
			Response.Write "<td><input type=text size=5 name=C" & intPosition & "DtDec value="""" class=box></td>"
			Response.Write "<td><select name=C" & intPosition & "IsMasc class=box>"
			Response.Write "<option value=true"
			Response.Write ">Son"
			Response.Write "<option value=false"
			Response.Write ">Daughter"
			Response.Write "</select></td>"
			Response.Write "</tr>"
		else
			Response.Write "<tr>"
			Response.Write "<td>" & intPosition & "</td>"
			Response.Write "<td><input type=text size=20 name=C" & intPosition & "Prenom value=""" & Request("C" & intPosition & "Prenom") & """ class=box></td>"
			Response.Write "<td><input type=text size=20 name=C" & intPosition & "Nom value=""" & Request("C" & intPosition & "Nom") & """ class=box></td>"
			Response.Write "<td><input type=text size=5 name=C" & intPosition & "DtNaiss value=""" & Request("C" & intPosition & "DtNaiss") & """ class=box></td>"
			Response.Write "<td><input type=text size=5 name=C" & intPosition & "DtDec value=""" & Request("C" & intPosition & "DtDec") & """ class=box></td>"
			Response.Write "<td><select name=C" & intPosition & "IsMasc class=box>"
			Response.Write "<option value=true"
			if Request("C" & intPosition & "IsMasc") = "true" then Response.Write " selected"
			Response.Write ">Son"
			Response.Write "<option value=false"
			if Request("C" & intPosition & "IsMasc") = "false" then Response.Write " selected"
			Response.Write ">Daughter"
			Response.Write "</select></td>"
			Response.Write "</tr>"
		end if
	end if
end sub

sub printChildSearch(intPosition)
	if intPosition = 0 then
		Response.Write "<tr>"
		Response.Write "<td colspan=2>&nbsp;</td>"
		Response.Write "<td>First Name</td>"
		Response.Write "<td>Last Name</td>"
		Response.Write "<td>Birth</td>"
		Response.Write "<td>Death</td>"
		Response.Write "<td>Gender</td>"
		Response.Write "</tr>"
	else
		Response.Write "<tr>"
		Response.Write "<td >" & intPosition & "</td>"
		Response.Write "<td>"
		if Request("C" & i & "IsMasc") = "true" then
			doSearchPerson "C" & i, "M"
		else
			doSearchPerson "C" & i, "F"
		end if
		Response.Write "</td>"
		Response.Write "<td><input type=text size=15 name=C" & intPosition & "Prenom value=""" & Request("C" & intPosition & "Prenom") & """ class=box></td>"
		Response.Write "<td><input type=text size=15 name=C" & intPosition & "Nom value=""" & Request("C" & intPosition & "Nom") & """ class=box></td>"
		Response.Write "<td><input type=text size=5 name=C" & intPosition & "DtNaiss value=""" & Request("C" & intPosition & "DtNaiss") & """ class=box></td>"
		Response.Write "<td><input type=text size=5 name=C" & intPosition & "DtDec value=""" & Request("C" & intPosition & "DtDec") & """ class=box></td>"
		Response.Write "<td><select name=C" & intPosition & "IsMasc class=box>"
		Response.Write "<option value=true"
		if Request("C" & intPosition & "IsMasc") = "true" then Response.Write " selected"
		Response.Write ">Son"
		Response.Write "<option value=false"
		if Request("C" & intPosition & "IsMasc") = "false" then Response.Write " selected"
		Response.Write ">Daughter"
		Response.Write "</select></td>"
		Response.Write "</tr>"
	end if
end sub

sub doSearchPerson(strField, strGender)
	dim strGenderCondition
	
	if strGender = "M" then
		strGenderCondition = "IsMasc"
	else
		strGenderCondition = "NOT IsMasc"
	end if

	strSQL = "SELECT IDPersonne, Prenom, Nom, DtNaiss, DtDec, IsMasc, " & _
			 "(Nom = '" & Request(strField & "Nom") & "' AND " & _
			 "Prenom = '" & Request(strField & "Prenom") & "') AS AllTrue, " & _
			 "(Nom = '" & Request(strField & "Nom") & "' OR " & _
			 "Prenom = '" & Request(strField & "Prenom") & "') AS OneTrue " & _
			 "FROM Personne " & _
			 "WHERE " & strGenderCondition & " AND " & _
			 "(Prenom = '" & Request(strField & "Prenom") & "' OR " & _
			 "Nom = '" & Request(strField & "Nom") & "') " & _
			 "ORDER BY " & _
			 "(Nom = '" & Request(strField & "Nom") & "' AND " & _
			 "Prenom = '" & Request(strField & "Prenom") & "'), " & _
			 "(Nom = '" & Request(strField & "Nom") & "' OR " & _
			 "Prenom = '" & Request(strField & "Prenom") & "'), " & _
			 "DtNaiss = '" & Request(strField & "DtNaiss") & "', " & _
			 "DtDec = '" & Request(strField & "DtDec") & "';"
	'Response.Write strSQL & "<br>"
	rs0.Open strSQL, conConnexion
	Dim flgFirst
	flgFirst = true
	Response.Write "<select name=" & strField & "IDPersonne class=WizardDropBox>"
	Response.Write "<option value=0>Add new name"
	while not rs0.eof
		Response.Write "<option value=" & rs0("IDPersonne")
		if flgFirst = true then
			Response.Write " selected"
			flgFirst = false
		end if
		Response.Write ">" & rs0("Nom") & " " & rs0("Prenom") & " (" & rs0("DtNaiss") & "-" & rs0("DtDec") & ")"
		rs0.MoveNext
	wend
	Response.Write "</select>"
	rs0.Close

	Response.Write "<br>"
end sub

sub doSave()
	dim arrField(), arrID(), arrCouple(), i
	redim arrField(6)
	redim arrID(6)
	redim arrCouple(3)
	
	arrField(1) = "MFather"
	arrField(2) = "MMother"
	arrField(3) = "FFather"
	arrField(4) = "FMother"
	arrField(5) = "MPerson"
	arrField(6) = "FPerson"

	for i = 1 to 6
		if Request(arrField(i) & "IDPersonne") = 0 and _
		  (Request(arrField(i) & "Nom") <> empty or _
		   Request(arrField(i) & "Prenom") <> empty) then
			arrID(i) = addPersonne(arrField(i))
		else
			arrID(i) = Request(arrField(i) & "IDPersonne")
		end if
	next

	for i = 0 to 2
		arrCouple(i + 1) = getCouple(arrID(i * 2 + 1), arrID(i * 2 + 2))
	next

	checkCouple arrID(5), arrCouple(1), 0 'his parents couple
	checkCouple arrID(6), arrCouple(2), 0 'her parents couple

	'Children
	for i = 1 to Request("intNbChildren")
		if Request("C" & i & "IDPersonne") <> 0 then
			checkCouple Request("C" & i & "IDPersonne"), arrCouple(3), i 
		else
			if Request("C" & i & "Prenom") <> empty or _
			   Request("C" & i & "Nom") <> empty then
				checkCouple addPersonne("C" & i), arrCouple(3), i 
			end if
		end if
	next
end sub

function addPersonne(strField)
	strSQL = "SELECT * FROM Personne WHERE IDPersonne=0;"
	rs0.Open strSQL, conConnexion, 3, 2

	rs0.AddNew
	if Request(strField & "Nom") <> empty then 
		rs0("Nom") = Request(strField & "Nom")
	end if
	if Request(strField & "Prenom") <> empty then 
		rs0("Prenom") = Request(strField & "Prenom")
	end if
	if Request(strField & "Prenom") <> empty then 
		rs0("Prenoms") = Request(strField & "Prenom")
	end if
	if Request(strField & "DtNaiss") <> empty then 
		rs0("DtNaiss") = Request(strField & "DtNaiss")
	end if
	if Request(strField & "DtDec") <> empty then 
		rs0("DtDec") = Request(strField & "DtDec")
	end if

	select case strField
		case "MFather", "FFather", "MPerson"
			rs0("IsMasc") = True
		case "MMother", "FMother", "FPerson"
			rs0("IsMasc") = false
		case else
			if Request(strField & "IsMasc") = "true" then
				rs0("IsMasc") = True
			else
				rs0("IsMasc") = false
			end if
	end select

	rs0("LastUpdateWho") = Session("IDUser")
	rs0("LastUpdateWhen") = now()

	rs0.Update

	rs0.MoveFirst
	addPersonne = rs0(0)
	rs0.Close
end function

function getCouple(MID, FID)
	if MID <> 0 and FID <> 0 then
		strSQL = "SELECT * FROM Couple " & _
				 "WHERE IDPersMasc=" & MID & " AND IDPersFem=" & FID & ";"
		rs0.Open strSQL, conConnexion, 3, 2
		if not rs0.eof then
			getCouple = rs0("IDCouple")
		else
			rs0.AddNew
			rs0("IDPersMasc") = MID
			rs0("IDPersFem")  = FID
			rs0("LastUpdateWho") = Session("IDUser")
			rs0("LastUpdateWhen") = now()
			rs0.Update

			rs0.MoveFirst
			getCouple = rs0(0)
		end if
		rs0.Close
	else
		getCouple = 0
	end if
end function

sub checkCouple(IDPerson, IDCouple, intPos)
	if IDCouple <> 0 then
		if intPos <> 0 then
			strSQL = "UPDATE Personne " & _
					 "SET IDCouple=" & IDCouple & ", " & _
					 "   TriCouple=" & intPos & " " & _
					 "WHERE IDPersonne=" & IDPerson & ";"
			rs0.Open strSQL, conConnexion, 3, 2
		else
			strSQL = "UPDATE Personne " & _
					 "SET IDCouple=" & IDCouple & " " & _
					 "WHERE IDPersonne=" & IDPerson & ";"
			rs0.Open strSQL, conConnexion, 3, 2
		end if
	end if
end sub

%>