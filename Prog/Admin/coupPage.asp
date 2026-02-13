<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
Dim lngIDCouple

if Request("todo") = "update" then
	strSQL = "SELECT * FROM Couple WHERE IDCouple=" & Request("IDCouple")
	rs0.Open strSQL, conConnexion, 2, 3

	if Request("Del") <> empty then
		rs0.Delete
	else
		if Request("IDPersMasc") <> empty then
			rs0("IDPersMasc") = Request("IDPersMasc")
		else
			rs0("IDPersMasc") = Null
		end if

		if Request("IDPersFem") <> empty then
			rs0("IDPersFem") = Request("IDPersFem")
		else
			rs0("IDPersFem") = Null
		end if

		if Request("DtCouple") <> empty then
			rs0("DtCouple") = Request("DtCouple")
		else
			rs0("DtCouple") = Null
		end if

		if Request("DateCouple") <> empty then
			rs0("DateCouple") = Request("DateCouple")
		else
			rs0("DateCouple") = Null
		end if

		if Request("LieuCouple") <> empty then
			rs0("LieuCouple") = Request("LieuCouple")
		else
			rs0("LieuCouple") = Null
		end if

		rs0("LastUpdateWho") = Session("IDUser")
		rs0("LastUpdateWhen") = now()

		rs0.Update
	end if
	rs0.Close

elseif Request("todo") = "add" then

	strSQL = "SELECT * FROM Couple WHERE IDCouple=0"
	rs0.Open strSQL, conConnexion, 2, 3

	rs0.AddNew
	if Request("IDPersMasc") <> empty then
		rs0("IDPersMasc") = Request("IDPersMasc")
	else
		rs0("IDPersMasc") = Null
	end if

	if Request("IDPersFem") <> empty then
		rs0("IDPersFem") = Request("IDPersFem")
	else
		rs0("IDPersFem") = Null
	end if

	if Request("DtCouple") <> empty then
		rs0("DtCouple") = Request("DtCouple")
	else
		rs0("DtCouple") = Null
	end if

	if Request("DateCouple") <> empty then
		rs0("DateCouple") = Request("DateCouple")
	else
		rs0("DateCouple") = Null
	end if

	if Request("LieuCouple") <> empty then
		rs0("LieuCouple") = Request("LieuCouple")
	else
		rs0("LieuCouple") = Null
	end if

	rs0("LastUpdateWho") = Session("IDUser")
	rs0("LastUpdateWhen") = now()

	rs0.Update
	rs0.MoveFirst
	lngIDCouple = rs0(0)
	rs0.Close
end if


if Request("IDCouple") <> Empty then lngIDCouple = Request("IDCouple")

if lngIDCouple <> empty then
	strSQL = "SELECT * FROM Couple WHERE IDCouple=" & lngIDCouple
	rs0.Open strSQL, conConnexion, 2, 3

	if not rs0.EOF then
		Response.Write "<form action=coupPage.asp method=post>"
		Response.Write "<input type=hidden name=IDCouple value=" & rs0("IDCouple") & ">"
		Response.Write "<input type=hidden name=todo value=update>"
		Response.Write "<table>"

		Response.Write "<tr valign=top><td>Man</td>"
		Response.Write "<td><select name=IDPersMasc class=box><option value="""">"

		strSQL = "SELECT * FROM Personne WHERE IsMasc ORDER BY Nom, Prenom, DtNaiss"
		rs1.Open strSQL, conConnexion, 2, 3
		while not rs1.EOF
			Response.Write "<option value=" & rs1("IDPersonne")
			if CLng(rs1("IDPersonne")) = CLng(rs0("IDPersMasc")) then Response.Write " selected"
			Response.Write ">" & rs1("Nom") & " " & rs1("Prenom") & " (" & rs1("DtNaiss") & ")</option>"
			rs1.MoveNext
		wend
		rs1.close

		Response.Write "</select></td></tr>"

		Response.Write "<tr valign=top><td>Woman</td>"
		Response.Write "<td><select name=IDPersFem class=box><option value="""">"

		strSQL = "SELECT * FROM Personne WHERE NOT IsMasc ORDER BY Nom, Prenom, DtNaiss"
		rs1.Open strSQL, conConnexion, 2, 3
		while not rs1.EOF
			Response.Write "<option value=" & rs1("IDPersonne")
			if CLng(rs1("IDPersonne")) = CLng(rs0("IDPersFem")) then Response.Write " selected"
			Response.Write ">" & rs1("Nom") & " " & rs1("Prenom") & " (" & rs1("DtNaiss") & ")</option>"
			rs1.MoveNext
		wend
		rs1.close

		Response.Write "</select></td></tr>"

		Response.Write "<tr><td>Year</td>"
		Response.Write "<td><input type=text name=DtCouple size=5 value=""" & rs0("DtCouple") & """ class=box></td></tr>"

		Response.Write "<tr><td>Date</td>"
		Response.Write "<td><input type=text name=DateCouple size=10 value=""" & rs0("DateCouple") & """ class=box> [mm/dd/yyyy]</td></tr>"

		Response.Write "<tr><td>Location</td>"
		Response.Write "<td><input type=text name=LieuCouple size=15 value=""" & rs0("LieuCouple") & """ class=box></td></tr>"

		Response.Write "<tr><td><input type=submit value=Update class=box></td>"
		Response.Write "<td><input type=submit name=Del value=Delete class=box></td></tr>"

		Response.Write "</table>"
		Response.Write "</form>"
	else
		if Request("Del") <> empty then
			Response.Write "Couple removed<br>"
		else
			Response.Write "Problem [1]!<br>"
		end if
	end if


else

	Response.Write "<form action=coupPage.asp method=post>"
	Response.Write "<input type=hidden name=todo value=add>"
	Response.Write "<table>"

	Response.Write "<tr valign=top><td>Man</td>"
	Response.Write "<td><select name=IDPersMasc class=box><option value="""">"

	strSQL = "SELECT * FROM Personne WHERE IsMasc ORDER BY Nom, Prenom, DtNaiss"
	rs1.Open strSQL, conConnexion, 2, 3
	while not rs1.EOF
		Response.Write "<option value=" & rs1("IDPersonne")
		Response.Write ">" & rs1("Nom") & " " & rs1("Prenom") & " (" & rs1("DtNaiss") & ")</option>"
		rs1.MoveNext
	wend
	rs1.close

	Response.Write "</select></td></tr>"

	Response.Write "<tr valign=top><td>Woman</td>"
	Response.Write "<td><select name=IDPersFem class=box><option value="""">"

	strSQL = "SELECT * FROM Personne WHERE NOT IsMasc ORDER BY Nom, Prenom, DtNaiss"
	rs1.Open strSQL, conConnexion, 2, 3
	while not rs1.EOF
		Response.Write "<option value=" & rs1("IDPersonne")
		Response.Write ">" & rs1("Nom") & " " & rs1("Prenom") & " (" & rs1("DtNaiss") & ")</option>"
		rs1.MoveNext
	wend
	rs1.close

	Response.Write "</select></td></tr>"

	Response.Write "<tr><td>Year</td>"
	Response.Write "<td><input type=text name=DtCouple size=5 class=box></td></tr>"

	Response.Write "<tr><td>Date</td>"
	Response.Write "<td><input type=text name=DateCouple size=10 class=box> [mm/dd/yyyy]</td></tr>"

	Response.Write "<tr><td>Location</td>"
	Response.Write "<td><input type=text name=LieuCouple size=15 class=box></td></tr>"

	Response.Write "<tr><td><input type=submit value=Add class=box></td>"
	Response.Write "<td></td></tr>"

	Response.Write "</table>"
	Response.Write "</form>"
end if

Response.Write "<p><a href=coupList.asp target=left>&lt;&lt;&lt; Refresh the couple list &lt;&lt;&lt;</a></p>"
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->
<!--#include VIRTUAL="/Include/DAOFooter.asp"-->
