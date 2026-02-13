<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
Dim lngIDPersonne, x

if Request("todo") = "update" then
	strSQL = "SELECT * FROM Personne WHERE IDPersonne=" & Request("IDPersonne")
	rs0.Open strSQL, conConnexion, 2, 3

	if Request("Del") <> empty then
		rs0.Delete
	else
		if Request("IDCouple") <> empty then
			rs0("IDCouple") = Request("IDCouple")
		else
			rs0("IDCouple") = Null
		end if

		if Request("TriCouple") <> empty then
			rs0("TriCouple") = Request("TriCouple")
		else
			rs0("TriCouple") = Null
		end if

		if Request("Nom") <> empty then
			rs0("Nom") = Request("Nom")
		else
			rs0("Nom") = Null
		end if

		if Request("Prenom") <> empty then
			rs0("Prenom") = Request("Prenom")
		else
			rs0("Prenom") = Null
		end if

		if Request("Prenoms") <> empty then
			rs0("Prenoms") = Request("Prenoms")
		else
			rs0("Prenoms") = Null
		end if

		if Request("IsMasc") <> empty then
			rs0("IsMasc") = true
		else
			rs0("IsMasc") = false
		end if

		if Request("DtNaiss") <> empty then
			rs0("DtNaiss") = Request("DtNaiss")
		else
			rs0("DtNaiss") = Null
		end if

		if Request("DtDec") <> empty then
			rs0("DtDec") = Request("DtDec")
		else
			rs0("DtDec") = Null
		end if

		if Request("DateNaiss") <> empty then
			rs0("DateNaiss") = Request("DateNaiss")
		else
			rs0("DateNaiss") = Null
		end if

		if Request("DateDec") <> empty then
			rs0("DateDec") = Request("DateDec")
		else
			rs0("DateDec") = Null
		end if

		if Request("LieuNaiss") <> empty then
			rs0("LieuNaiss") = Request("LieuNaiss")
		else
			rs0("LieuNaiss") = Null
		end if

		if Request("LieuDec") <> empty then
			rs0("LieuDec") = Request("LieuDec")
		else
			rs0("LieuDec") = Null
		end if

		if Request("Comm") <> empty then
			rs0("Comm") = Request("Comm")
		else
			rs0("Comm") = Null
		end if

		if Request("Email") <> empty then
			rs0("Email") = Request("Email")
		else
			rs0("Email") = Null
		end if

		rs0("LastUpdateWho") = Session("IDUser")
		rs0("LastUpdateWhen") = now()
	end if

	rs0.Update
	rs0.Close

elseif Request("todo") = "add" then

	strSQL = "SELECT * FROM Personne WHERE IDPersonne=0"
	rs0.Open strSQL, conConnexion, 2, 3

	rs0.AddNew
	if Request("IDCouple") <> empty then
		rs0("IDCouple") = Request("IDCouple")
	else
		rs0("IDCouple") = Null
	end if

	if Request("TriCouple") <> empty then
		rs0("TriCouple") = Request("TriCouple")
	else
		rs0("TriCouple") = Null
	end if

	if Request("Nom") <> empty then
		rs0("Nom") = Request("Nom")
	else
		rs0("Nom") = Null
	end if

	if Request("Prenom") <> empty then
		rs0("Prenom") = Request("Prenom")
	else
		rs0("Prenom") = Null
	end if

	if Request("Prenoms") <> empty then
		rs0("Prenoms") = Request("Prenoms")
	else
		rs0("Prenoms") = Null
	end if

	if Request("IsMasc") <> empty then
		rs0("IsMasc") = true
	else
		rs0("IsMasc") = false
	end if

	if Request("DtNaiss") <> empty then
		rs0("DtNaiss") = Request("DtNaiss")
	else
		rs0("DtNaiss") = Null
	end if

	if Request("DtDec") <> empty then
		rs0("DtDec") = Request("DtDec")
	else
		rs0("DtDec") = Null
	end if

	if Request("DateNaiss") <> empty then
		rs0("DateNaiss") = Request("DateNaiss")
	else
		rs0("DateNaiss") = Null
	end if

	if Request("DateDec") <> empty then
		rs0("DateDec") = Request("DateDec")
	else
		rs0("DateDec") = Null
	end if

	if Request("LieuNaiss") <> empty then
		rs0("LieuNaiss") = Request("LieuNaiss")
	else
		rs0("LieuNaiss") = Null
	end if

	if Request("LieuDec") <> empty then
		rs0("LieuDec") = Request("LieuDec")
	else
		rs0("LieuDec") = Null
	end if

	if Request("Comm") <> empty then
		rs0("Comm") = Request("Comm")
	else
		rs0("Comm") = Null
	end if

	if Request("Email") <> empty then
		rs0("Email") = Request("Email")
	else
		rs0("Email") = Null
	end if

	rs0("LastUpdateWho") = Session("IDUser")
	rs0("LastUpdateWhen") = now()

	rs0.Update
	rs0.MoveFirst
	lngIDPersonne = rs0(0)
	rs0.Close

end if

if Request("IDPersonne") <> Empty then lngIDPersonne = Request("IDPersonne")

if lngIDPersonne <> empty then
	strSQL = "SELECT * FROM Personne WHERE IDPersonne=" & lngIDPersonne
	rs0.Open strSQL, conConnexion, 2, 3

	if not rs0.EOF then
		Response.Write "<form action=messPersPage.asp method=post>"
		Response.Write "<input type=hidden name=IDPersonne value=" & rs0("IDPersonne") & ">"
		Response.Write "<input type=hidden name=todo value=update>"
		Response.Write "<table>"
		Response.Write "<tr valign=top><td>First Name</td>"
		Response.Write "<td><input type=text size=20 name=Prenom value=""" & rs0("Prenom") & """ class=box>&nbsp;"
		Response.Write "Masc.<input type=checkbox name=IsMasc value=X"
		if rs0("IsMasc") then Response.Write " checked"
		Response.Write "></td>"
		Response.Write "<td rowspan=11 colspan=2><textarea name=Comm cols=40 rows=15 class=box>" & rs0("Comm") & "</textarea></td></tr>"
		Response.Write "<tr><td>First Names</td><td><input type=text size=40 name=Prenoms value=""" & rs0("Prenoms") & """ class=box></td></tr>"
		Response.Write "<tr><td>Last Name</td><td><input type=text size=20 name=Nom value=""" & rs0("Nom") & """ class=box></td></tr>"
		Response.Write "<tr><td>Birth Year</td><td><input type=text size=5 name=DtNaiss value=""" & rs0("DtNaiss") & """ class=box></td></tr>"
		Response.Write "<tr><td>Deceased Year</td><td><input type=text size=5 name=DtDec value=""" & rs0("DtDec") & """ class=box></td></tr>"
		Response.Write "<tr><td>Birth Date</td><td><input type=text size=10 name=DateNaiss value=""" & rs0("DateNaiss") & """ class=box> [mm/dd/yyyy]</td></tr>"
		Response.Write "<tr><td>Deceased Date</td><td><input type=text size=10 name=DateDec value=""" & rs0("DateDec") & """ class=box> [mm/dd/yyyy]</td></tr>"
		Response.Write "<tr><td>Birth Location</td><td><input type=text size=20 name=LieuNaiss value=""" & rs0("LieuNaiss") & """ class=box></td></tr>"
		Response.Write "<tr><td>Deceased Location</td><td><input type=text size=20 name=LieuDec value=""" & rs0("LieuDec") & """ class=box></td></tr>"
		Response.Write "<tr valign=top><td>Parents</td><td><select name=IDCouple class=box><option value=0>"

		strSQL = "SELECT Couple.IDCouple, Personne.Prenom AS MP, Personne.Nom AS MN, Personne_1.Prenom AS FP, Personne_1.Nom AS FN " & _
				 "FROM (Couple INNER JOIN Personne ON Couple.IDPersMasc = Personne.IDPersonne) INNER JOIN Personne AS Personne_1 ON Couple.IDPersFem = Personne_1.IDPersonne " & _
				 "ORDER BY Personne.Nom, Personne.Prenom, Personne_1.Nom, Personne.Prenom"
		rs1.Open strSQL, conConnexion, 2, 3

		while not rs1.EOF
			if IsNull(rs0("IDCouple")) then
				Response.Write "<option value=" & rs1("IDCouple") & ">" & rs1("MP") & " " & rs1("MN") & " & " & rs1("FP") & " " & rs1("FN") & "</option>"
			else
				Response.Write "<option value=" & rs1("IDCouple")
				if CLng(rs0("IDCouple")) = CLng(rs1("IDCouple")) then Response.Write " selected"
				Response.Write ">" & rs1("MN") & " " & rs1("MP") & " & " & rs1("FN") & " " & rs1("FP") & "</option>"
			end if

			rs1.MoveNext
		wend

		rs1.close

		Response.Write "</select></td></tr>"
		Response.Write "<tr><td>Order Sibilings</td><td><input type=text size=3 name=TriCouple value=""" & rs0("TriCouple") & """ class=box></td></tr>"
		Response.Write "<tr><td>Email [*]</td><td><input type=text name=Email size=40 value=""" & rs0("Email") & """ class=box></td>"
		Response.Write "<td align=right><input type=submit value=Update class=box></td>"
		Response.Write "<td><input type=submit name=Del value=Delete class=box></td></tr>"
		Response.Write "</table></form>"
	else
		if Request("Del") <> empty then
			Response.Write "Person Removed<br>"
		else
			Response.Write "Problem [1]!<br>"
		end if
	end if
else

	Response.Write "<form action=messPersPage.asp method=post>"
	Response.Write "<input type=hidden name=todo value=add>"
	Response.Write "<table>"
	Response.Write "<tr valign=top><td>First Name</td>"
	Response.Write "<td><input type=text size=20 name=Prenom class=box>&nbsp;"
	Response.Write "Masc.<input type=checkbox name=IsMasc value=X></td>"
	Response.Write "<td rowspan=11><textarea cols=40 rows=15 name=Comm class=box></textarea></td></tr>"
	Response.Write "<tr><td>First Names</td><td><input type=text size=40 name=Prenoms class=box></td></tr>"
	Response.Write "<tr><td>Last Name</td><td><input type=text size=20 name=Nom class=box></td></tr>"
	Response.Write "<tr><td>Birth Year</td><td><input type=text size=5 name=DtNaiss class=box></td></tr>"
	Response.Write "<tr><td>Deceased Year</td><td><input type=text size=5 name=DtDec class=box></td></tr>"
	Response.Write "<tr><td>Birth Date</td><td><input type=text size=10 name=DateNaiss class=box> [mm/dd/yyyy]</td></tr>"
	Response.Write "<tr><td>Deceased Date</td><td><input type=text size=10 name=DateDec class=box> [mm/dd/yyyy]</td></tr>"
	Response.Write "<tr><td>Birth Location</td><td><input type=text size=20 name=LieuNaiss class=box></td></tr>"
	Response.Write "<tr><td>Deceased Location</td><td><input type=text size=20 name=LieuDec class=box></td></tr>"
	Response.Write "<tr valign=top><td>Parents</td><td><select name=IDCouple class=box><option value=0>"

	strSQL = "SELECT Couple.IDCouple, Personne.Prenom AS MP, Personne.Nom AS MN, Personne_1.Prenom AS FP, Personne_1.Nom AS FN " & _
			 "FROM (Couple INNER JOIN Personne ON Couple.IDPersMasc = Personne.IDPersonne) INNER JOIN Personne AS Personne_1 ON Couple.IDPersFem = Personne_1.IDPersonne " & _
			 "ORDER BY Personne.Nom, Personne.Prenom, Personne_1.Nom, Personne.Prenom"
	rs1.Open strSQL, conConnexion, 2, 3
	while not rs1.EOF
		Response.Write "<option value=" & rs1("IDCouple") & ">" & rs1("MN") & " " & rs1("MP") & " & " & rs1("FN") & " " & rs1("FP")
		rs1.MoveNext
	wend
	rs1.close

	Response.Write "</select></td></tr>"
	Response.Write "<tr><td>Order Sibilings</td><td><input type=text size=3 name=TriCouple class=box></td></tr>"
	Response.Write "<tr><td>Email [*]</td><td><input type=text size=40 name=Email class=box></td>"
	Response.Write "<td align=center><input type=submit value=Add class=box></td></tr>"
	Response.Write "</table></form>"
end if

Response.Write "<p><a href=messList.asp target=left>&lt;&lt;&lt; Refresh the Person list &lt;&lt;&lt;</a></p>"
Response.Write "<p>[*] For privacy and anti-spam reasons, the <b>Email Addresses</b> will not be visible on the site.<br>" & _
			   "Use the Message module to contact family members.</p>"
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->
<!--#include VIRTUAL="/Include/DAOFooter.asp"-->
