<!--#include VIRTUAL=/Include/CodeHeader.asp-->
<%
strConn = "PROVIDER=Microsoft.Jet.OLEDB.4.0;DATA SOURCE=" & server.mappath("/Data/user.mdb") & ";"
%>
<!--#include VIRTUAL=/Include/DAOHeader.asp-->
<%
dim lngIDHelp
select case Request("todo")
	case "add"
		addHelp lngIDHelp
	case "update"
		updateHelp
end select

dim strCurr, strNext, i

Response.Write "<html>"
Response.Write "<head>"
Response.Write "<title>www.see-our-family.com</title>"
Response.Write "<link rel=stylesheet type=text/css href=/style.css>"
Response.Write "</head>"

Response.Write "<script language=""Javascript"">"
Response.Write "function openHelp(){" & _
			   "newWindow=window.open( ""/Help/frame.asp"" , ""Help"", " & _
			   """toolbar=0,location=0,directories=0,status=0,menubar=0,scrollbars=1," & _
			   "resizable=0,copyhistory=0,width=500,height=350"");}"
Response.Write "</script>"

Response.Write "<body topmargin=0 leftmargin=0 rightmargin=0 bottommargin=0>"

Response.Write "<table height=100% border=0 cellpadding=0 cellspacing=0>"
Response.Write "<tr valign=top><td width=300>"

if request("IDHelp") <> empty then
	strSQL = "SELECT * FROM [Help] " & _
			 "WHERE IDHelp=" & request("IDHelp") & ";"
	rs0.Open strSQL, conConnexion	', 2, 3

	Response.Write "<table border=0 cellpadding=0 cellspacing=2>"
	Response.Write "<form action=helpForm.asp method=post>"

	if not rs0.eof then
		Response.Write "<input type=hidden name=todo value=update>" & _
					   "<input type=hidden name=IDHelp value=" & rs0("IDHelp") & ">"

		Response.Write "<tr><td>" & _
					   "Dad</td><td>"
		
		strSQL = "SELECT * FROM [Help] " & _
				 "WHERE HelpIsOnline AND HelpTitle <> '' AND " & _
				 "HelpLanguage = '" & Session("Language") & "' " & _
				 "ORDER BY HelpSortKey;"
		rs1.Open strSQL, conConnexion	', 2, 3

		Response.Write "<select name=IdDad class=box>"
		Response.Write "<option value=0>Top"
		while not rs1.eof
			Response.Write "<option value=" & rs1("IDHelp")
			if rs0("IdDad") = rs1("IDHelp") then Response.Write " selected"
			Response.Write ">"
			for i = 1 to len(rs1("HelpSortKey")) / 2
				Response.Write "-"
			next
			Response.Write rs1("HelpTitle")
			rs1.MoveNext
		wend		
		rs1.Close
		Response.Write "</select>"

		Response.Write "</td></tr>"
		
		Response.Write "<tr><td>Sort</td><td>" & _
					   "<input type=text name=HelpSort value=" & rs0("HelpSort") & " size=30 class=box>" & _
					   "</td></tr>"
		Response.Write "<tr><td>Sort Key</td><td>" & _
					   "<b>" & rs0("HelpSortKey") & "</b>" & _
					   "</td></tr>"
		Response.Write "<tr><td>Title</td><td>" & _
					   "<input type=text name=HelpTitle value=""" & rs0("HelpTitle") & """ size=30 class=box>" & _
					   "<input type=text name=HelpLanguage value=""" & rs0("HelpLanguage") & """ size=3 class=box>" & _
					   "</td></tr>"
		Response.Write "<tr><td colspan=2>" & _
					   "<textarea name=HelpBody class=box cols=50 rows=25>" & rs0("HelpBody") & "</textarea>" & _
					   "</td></tr>"
		Response.Write "<tr><td>Image</td><td>" & _
					   "<input type=text name=HelpImage value=""" & rs0("HelpImage") & """ size=30 class=box>" & _
					   "</td></tr>"
		Response.Write "<tr><td>Is Online</td><td>"
		Response.Write "<input type=checkbox name=HelpIsOnline value=X"
		if rs0("HelpIsOnline") = true then Response.Write " checked"
		Response.Write ">" & _
					   "</td></tr>"
		Response.Write "<tr><td>&nbsp</td><td>" & _
					   "<input type=submit name=SubUpd value=update class=box>" & _
					   "</td></tr>"
		if rs0("HelpImage") <> "" then
			Response.Write "<tr><td colspan=2>" & _
						   "<img src=/Image/Help/" & rs0("HelpImage") & " border=1>" & _
						   "</td></tr>"
		end if
	else
		Response.Write "<input type=hidden name=todo value=add>"
		
		Response.Write "<tr><td>" & _
					   "Dad</td><td>"
		
		strSQL = "SELECT * FROM [Help] " & _
				 "WHERE HelpIsOnline AND HelpTitle <> '' AND " & _
				 "HelpLanguage = '" & Session("Language") & "' " & _
				 "ORDER BY HelpSortKey;"
		rs1.Open strSQL, conConnexion	', 2, 3

		Response.Write "<select name=IdDad class=box>"
		Response.Write "<option value=0>Top"
		while not rs1.eof
			Response.Write "<option value=" & rs1("IDHelp")
			Response.Write ">"
			for i = 1 to len(rs1("HelpSortKey")) / 2
				Response.Write "-"
			next
			Response.Write rs1("HelpTitle")
			rs1.MoveNext
		wend
		rs1.Close
		Response.Write "</select>"

		Response.Write "</td></tr>"
		
		Response.Write "<tr><td>Sort</td><td>" & _
					   "<input type=text name=HelpSort size=30 class=box>" & _
					   "</td></tr>"
		Response.Write "<tr><td>Sort Key</td><td>" & _
					   "<b>New</b>" & _
					   "</td></tr>"
		Response.Write "<tr><td>Title</td><td>" & _
					   "<input type=text name=HelpTitle size=30 class=box>" & _
					   "<input type=text name=HelpLanguage value=""" & Session("Language") & """ size=3 class=box>" & _
					   "</td></tr>"
		Response.Write "<tr><td colspan=2>" & _
					   "<textarea name=HelpBody class=box cols=50 rows=25></textarea>" & _
					   "</td></tr>"
		Response.Write "<tr><td>Image</td><td>" & _
					   "<input type=text name=HelpImage size=30 class=box>" & _
					   "</td></tr>"
		Response.Write "<tr><td>Is Online</td><td>"
		Response.Write "<input type=checkbox name=HelpIsOnline value=X checked>" & _
					   "</td></tr>"
		Response.Write "<tr><td>&nbsp</td><td>" & _
					   "<input type=submit name=SubUpd value=add class=box>" & _
					   "</td></tr>"
	end if

	Response.Write "</form>"
	Response.Write "</table>"

	rs0.Close
end if

Response.Write "</td></tr>"
Response.Write "</table>"

Response.Write "</body>"
Response.Write "</html>"
%>
<!--#include VIRTUAL="/Include/DAOFooter.asp"-->
<%
'IDHelp, IdDad, HelpSort, HelpSortKey, HelpTitle, HelpBody, HelpImage, HelpIsOnline
sub addHelp(lngHelp)
	dim strLang
	if Request("HelpLanguage") <> empty then
		strLang = Request("HelpLanguage")
	else
		strLang = "ENG"
	end if


	strSQL = "SELECT * FROM [Help] " & _
			 "WHERE IDHelp=0;"
	rs0.Open strSQL, conConnexion, 2, 3
	rs0.AddNew

	if Request("IdDad") <> empty then
		rs0("IdDad") = Request("IdDad")
	else
		rs0("IdDad") = 0
	end if

	if Request("HelpSort") <> empty then
		rs0("HelpSort") = Request("HelpSort")
	else
		rs0("HelpSort") = 0
	end if

	rs0("HelpLanguage") = strLang

	if Request("HelpTitle") <> empty then
		rs0("HelpTitle") = Request("HelpTitle")
	else
		rs0("HelpTitle") = Null
	end if

	if Request("HelpBody") <> empty then
		rs0("HelpBody") = Request("HelpBody")
	else
		rs0("HelpBody") = Null
	end if

	if Request("HelpImage") <> empty then
		rs0("HelpImage") = Request("HelpImage")
	else
		rs0("HelpImage") = Null
	end if

	if Request("HelpIsOnline") <> empty then
		rs0("HelpIsOnline") = true
	else
		rs0("HelpIsOnline") = false
	end if

	rs0.Update
	rs0.MoveFirst
	lngHelp = rs0(0)
	rs0.Close

	EraseSortKeys strLang
	UpdateSortKey strLang, 0, ""
	if CheckSortKeys(strLang) then 
		Response.Write "We detected an error in the tree, please verify your organisation.<br>"
	end if
end sub

'IDHelp, IdDad, HelpSort, HelpSortKey, HelpTitle, HelpBody, HelpImage, HelpIsOnline
sub updateHelp()
	dim strLang
	if Request("HelpLanguage") <> empty then
		strLang = Request("HelpLanguage")
	else
		strLang = "ENG"
	end if


	strSQL = "SELECT * FROM [Help] " & _
			 "WHERE IDHelp=" & request("IDHelp") & ";"
	rs0.Open strSQL, conConnexion, 2, 3

	if Request("IdDad") <> empty then
		rs0("IdDad") = Request("IdDad")
	else
		rs0("IdDad") = 0
	end if

	if Request("HelpSort") <> empty then
		rs0("HelpSort") = Request("HelpSort")
	else
		rs0("HelpSort") = 0
	end if

	rs0("HelpLanguage") = strLang

	if Request("HelpTitle") <> empty then
		rs0("HelpTitle") = Request("HelpTitle")
	else
		rs0("HelpTitle") = Null
	end if

	if Request("HelpBody") <> empty then
		rs0("HelpBody") = Request("HelpBody")
	else
		rs0("HelpBody") = Null
	end if

	if Request("HelpImage") <> empty then
		rs0("HelpImage") = Request("HelpImage")
	else
		rs0("HelpImage") = Null
	end if

	if Request("HelpIsOnline") <> empty then
		rs0("HelpIsOnline") = true
	else
		rs0("HelpIsOnline") = false
	end if

	rs0.Update
	rs0.Close

	EraseSortKeys strLang
	UpdateSortKey strLang, 0, ""
	if CheckSortKeys(strLang) then 
		Response.Write "We detected an error in the tree, please verify your organisation.<br>"
	end if
end sub

sub UpdateSortKey(strLang, lngIdDad, strKeyDad)
	dim rsRecurse, intAscPos1, intAscPos2
	set rsRecurse = Server.CreateObject("ADODB.Recordset")			
	
	intAscPos1 = 97
	intAscPos2 = 97
		
	strSQL = "SELECT * FROM [Help] " & _
			 "WHERE IdDad=" & lngIdDad & " AND HelpLanguage='" & strLang & "' " & _
			 "ORDER BY HelpSort, HelpTitle"
	rsRecurse.open strSQL, conConnexion, 2, 3

	while not rsRecurse.EOF

		rsRecurse.MoveNext
		if rsRecurse.EOF then
			rsRecurse.MovePrevious
			rsRecurse("HelpSortKey") = strKeyDad & "zz"
		else
			rsRecurse.MovePrevious
			rsRecurse("HelpSortKey") = strKeyDad & chr(intAscPos1) & chr(intAscPos2)
		end if
		rsRecurse.Update
		
		UpdateSortKey strLang, rsRecurse("IDHelp"), rsRecurse("HelpSortKey")

		rsRecurse.MoveNext
		intAscPos2 = intAscPos2 + 1
		if intAscPos2 > 122 then
			intAscPos1 = intAscPos1 + 1
			intAscPos2 = 97
		end if
	wend

	rsRecurse.Close
	set rsRecurse = nothing
end sub

sub EraseSortKeys(strLang)
	strSQL = "UPDATE [Help] SET HelpSortKey='-' WHERE HelpLanguage='" & strLang & "';"
	rs0.Open strSQL, conConnexion
end sub

function CheckSortKeys(strLang)
	strSQL = "SELECT * FROM [Help] WHERE HelpSortKey='-' AND HelpLanguage='" & strLang & "';"
	rs0.Open strSQL, conConnexion
	
	if not rs0.EOF then 
		CheckSortKeys = true
	else
		CheckSortKeys = false
	end if

	rs0.Close
end function
%>