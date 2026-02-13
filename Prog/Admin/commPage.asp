<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
Dim lngIDCommentaire, lngIDPersonne, intPos, intCpt

if Request("todo") = "add" then
	strSQL = "SELECT * FROM Commentaire WHERE IDCommentaire=0"
	rs0.Open strSQL, conConnexion, 2, 3

	rs0.AddNew
	if Request("Titre") <> empty then
		rs0("Titre") = Request("Titre")
	else
		rs0("Titre") = Null
	end if

	if Request("DtVecu") <> empty then
		rs0("DtVecu") = Request("DtVecu")
	else
		rs0("DtVecu") = Null
	end if

	if Request("Comm") <> empty then
		rs0("Comm") = Request("Comm")
	else
		rs0("Comm") = Null
	end if

	rs0("LastUpdateWho") = Session("IDUser")
	rs0("LastUpdateWhen") = now()

	rs0.UpDate
	rs0.MoveFirst
	lngIDCommentaire = rs0(0) 
	rs0.Close

elseif Request("todo") = "update" then
	strSQL = "DELETE * FROM LienCommPerso WHERE IDCommentaire=" & Request("IDCommentaire")
	rs0.Open strSQL, conConnexion

	strSQL = "SELECT * FROM Commentaire WHERE IDCommentaire=" & Request("IDCommentaire")
	rs0.Open strSQL, conConnexion, 2, 3

	if Request("Del") <> empty then
		rs0.Delete
	else
		if Request("Titre") <> empty then
			rs0("Titre") = Request("Titre")
		else
			rs0("Titre") = Null
		end if

		if Request("DtVecu") <> empty then
			rs0("DtVecu") = Request("DtVecu")
		else
			rs0("DtVecu") = Null
		end if

		if Request("Comm") <> empty then
			rs0("Comm") = Request("Comm")
		else
			rs0("Comm") = Null
		end if

		rs0("LastUpdateWho") = Session("IDUser")
		rs0("LastUpdateWhen") = now()

		rs0.UpDate

		lngIDPersonne = Request("IdPersonne")
		intPos = instr(lngIDPersonne, ",")
		intCpt = 1
		while intPos > 1
			strSQL = "INSERT INTO LienCommPerso (IdCommentaire, IdPersonne, SortKey) " & _
			         "SELECT " & Request("IDCommentaire") & ", " & _
			         left(lngIDPersonne, intPos - 1) & ", " & intCpt
			rs1.Open strSQL, conConnexion
			lngIDPersonne = mid(lngIDPersonne, intPos + 1)
			intPos = instr(lngIDPersonne, ",")
			intCpt = intCpt + 1
		wend
		if lngIDPersonne <> empty then
			strSQL = "INSERT INTO LienCommPerso (IdCommentaire, IdPersonne, SortKey) " & _
			         "SELECT " & Request("IDCommentaire") & ", " & lngIDPersonne & ", " & intCpt
			rs1.Open strSQL, conConnexion
		end if
	end if
	rs0.Close

end if



if Request("IDCommentaire") <> empty then lngIDCommentaire = Request("IDCommentaire")

if lngIDCommentaire <> empty then
	strSQL = "SELECT * FROM Commentaire WHERE IDCommentaire=" & lngIDCommentaire
	rs0.Open strSQL, conConnexion, 2, 3

	if not rs0.EOF then
		Response.Write "<form action=commPage.asp name=myForm method=post>"
		Response.Write "<input type=hidden name=IDCommentaire value=" & rs0("IDCommentaire") & ">"
		Response.Write "<input type=hidden name=todo value=update>"
		Response.Write "<table border=0 cellpadding=0 cellspacing=0><tr valign=top><td align=right>&nbsp;<br>"
		Response.Write "Date&nbsp;<input type=text name=DtVecu size=30 value=""" & rs0("DtVecu") & """ class=box><br>"
		Response.Write "Title&nbsp;<input type=text name=Titre size=30 value=""" & rs0("Titre") & """ class=box><br>"
		Response.Write "</td><td rowspan=2>&nbsp;</td><td rowspan=2>All:<br>"

		strSQL = "SELECT * FROM Personne ORDER BY Nom, Prenom"
		rs2.Open strSQL, conConnexion, 2, 3
		Response.Write "<select name=Tous multiple onChange=""Add()"" size=25 class=box style={width:200px}>"
		while not rs2.eof
			Response.Write "<option value=" & rs2("IDPersonne")
			Response.Write ">" & rs2("Nom") & " " &  rs2("Prenom")
			rs2.MoveNext
		wend
		Response.Write "</select><br>"
		rs2.Close
		Response.Write "<b>Click to Select</b>" 

		Response.Write "</td><td rowspan=2>Referred to in the Comment:<br>" 

		strSQL = "SELECT Personne.*, IDCommentaire FROM Personne, LienCommPerso " & _
				 "WHERE Personne.IDPersonne=LienCommPerso.IdPersonne " & _
				 "AND LienCommPerso.IdCommentaire=" & rs0("IDCommentaire") & " " & _
				 "ORDER BY SortKey, Nom, Prenom"
		rs2.Open strSQL, conConnexion, 2, 3
		Response.Write "<select name=IdPersonne multiple size=25 class=box style={width:200px}>"
		while not rs2.eof
			Response.Write "<option value=" & rs2("IDPersonne")
			Response.Write ">" & rs2("Nom") & " " &  rs2("Prenom")
			rs2.MoveNext
		wend
		Response.Write "</select><br>"
		rs2.Close
		Response.Write "<b>Move : "
		Response.Write "<a href=javascript:MoveUp();>Up</a>/" 
		Response.Write "<a href=javascript:MoveDwn();>Down</a> | " 
		Response.Write "<a href=javascript:Remove();>Remove</a>" 
		'Response.Write "<input type=text name=myTest>" 
		Response.Write "</b>" 
		Response.Write "</td></tr>"

		Response.Write "<tr valign=top><td>"
		Response.Write "<textarea name=Comm cols=35 rows=21 class=box>" & rs0("Comm") & "</textarea><br>"
		Response.Write "<br><input type=submit value=Update OnClick=""SelectAll();"" class=box>"
		Response.Write "<input type=submit name=del value=Delete class=box>"
		Response.Write "</td></tr></table>"
		Response.Write "</form>"

		Response.Write "<script language=""JavaScript"">"
		Response.Write "function Add(){"
		Response.Write	"var lstL = document.myForm.Tous, lstR = document.myForm.IdPersonne;"
		Response.Write	"var tabValR = new Array(), tabTxtR = new Array();"
		Response.Write	"var ItemCount = lstR.options.length, i, flag = false;"
		Response.Write	"for (i = 0; i < ItemCount; i++) {"
		Response.Write		"if (lstR.options[i].value == lstL.options[lstL.selectedIndex].value)"
		Response.Write			"flag = true;"
		Response.Write		"tabValR[i] = lstR.options[i].value;"
		Response.Write		"tabTxtR[i] = lstR.options[i].text;"
		Response.Write	"}"
		Response.Write	"if (flag == false) {"
		Response.Write		"tabValR[ItemCount] = lstL.options[lstL.selectedIndex].value;"
		Response.Write		"tabTxtR[ItemCount] = lstL.options[lstL.selectedIndex].text;"
		Response.Write		"ItemCount++;"
		Response.Write	"}"
		Response.Write	"for (i = 0; i < ItemCount; i++) {"
		Response.Write		"var no = new Option();"
		Response.Write		"no.value = tabValR[i];"
		Response.Write		"no.text = tabTxtR[i];"
		Response.Write		"lstR[i] = no;"
		Response.Write	"}"
		Response.Write "}"

		Response.Write "function Remove(){"
		Response.Write	"var lstR = document.myForm.IdPersonne, tabValR = new Array(), tabTxtR = new Array();"
		Response.Write	"var i, j = 0, ItemCount = lstR.options.length;"
		Response.Write	"for (i=0; i<ItemCount; i++) {"
		Response.Write		"if (lstR.options[i].value != lstR.options[lstR.selectedIndex].value) {"
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
		'Response.Write  "document.myForm.myTest.value=lstSI;"
		Response.Write	"if (lstSI >= 0) {"
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
		Response.Write	"else {"
		Response.Write		"lstR.options[0].selected = true;"
		'Response.Write		"lstR.options[ItemCount - 1].selected = true;"
		Response.Write	"}"
		Response.Write "}"

		Response.Write "function MoveDwn(){"
		Response.Write	"var lstR = document.myForm.IdPersonne, lstSI = lstR.selectedIndex;"
		Response.Write	"var tabValR = new Array(), tabTxtR = new Array();"
		Response.Write	"var i, j = 0, ItemCount = lstR.options.length;"
		'Response.Write  "document.myForm.myTest.value=lstSI;"
		Response.Write	"if (lstSI < ItemCount - 1) {"
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
	else
		if Request("Del") <> empty then
			Response.Write "Entry Deleted<br>"
		else
			Response.Write "Problem[1]!"
		end if
	end if

else
	Response.Write "<form action=commPage.asp method=post>"
	Response.Write "<input type=hidden name=todo value=add>"
	Response.Write "<table border=0 cellpadding=0 cellspacing=0><tr><td align=right>"
	Response.Write "Date&nbsp;<input type=text name=DtVecu size=30 class=box><br>"
	Response.Write "Title&nbsp;<input type=text name=Titre size=30 class=box><br>"
	Response.Write "</td></tr>"
	Response.Write "<tr><td>"
	Response.Write "<textarea name=Comm cols=35 rows=15 class=box></textarea><br>"
	Response.Write "<br><input type=submit value=Add class=box>"
	Response.Write "</td></tr></table>"
	Response.Write "</form>"
end if


Response.Write "<p><a href=commList.asp target=left>&lt;&lt;&lt; Refresh the comment list &lt;&lt;&lt;</a></p>"
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->
<!--#include VIRTUAL="/Include/DAOFooter.asp"-->
