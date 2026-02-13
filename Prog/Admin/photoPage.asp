<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->
<!--#include VIRTUAL="/Include/Label.asp"-->


<%
dim lngIDPhoto, lngIDPersonne, intPos, intCpt, strError, strTNWarning

strTNWarning =  "<table border=0 width=500 cellpadding=0 cellspacing=0><tr><td>" & _
				"If you do not see the thumbnail (and see a broken picture icon instead) you may have simply forgotten to upload it. " & _
				"Thumbnails are small versions of pictures used in the picture lists. These are resized to be lighter and fit a list view. " & _
				"To create a thumbnail resize your picture to have its largest dimension (height or width) at 100 pixels keeping the same ratio. " & _
				"If your picture is called MyPicture.jpg name the thumbnail MyPicture.tn.jpg (.tn.gif) and upload it using the <b>Add a Picture</b> screen." & _
				"</td></tr></table>"

Response.Write "<b>Pictures</b><br><br>"

if Request("todo") = "update" then

	strSQL = "DELETE * FROM LienPhotoPerso WHERE IdPhoto=" & Request("IDPhoto")
	rs0.Open strSQL, conConnexion

	strSQL = "SELECT * FROM Photo WHERE IDPhoto=" & Request("IDPhoto")
	'Response.Write strSQL & "<br>"
	rs0.Open strSQL, conConnexion, 2, 3

	if request("del") <> empty then
		rs0.Delete	
	else
		if Request("NomPhoto") <> rs0("NomPhoto") and Request("NomPhoto") <> empty then
			Dim fso, strItemOld, strItemNew, strTNOld, strTNNew
			Set fso = CreateObject("Scripting.FileSystemObject")


			strItemOld = server.mappath(strImage & rs0("NomPhoto"))
			strItemNew = server.mappath(strImage & Request("NomPhoto"))
			strTNOld = Left(strItemOld, Len(strItemOld) - 3) & "tn." & Right(strItemOld, 3)
			strTNNew = Left(strItemNew, Len(strItemNew) - 3) & "tn." & Right(strItemNew, 3)

			if fso.FileExists(strItemNew) then
				strError = Request("NomPhoto") & " already exists!"
			else
				if fso.FileExists(strItemOld) then fso.MoveFile strItemOld, strItemNew
				if fso.FileExists(strTNOld) then fso.MoveFile strTNOld, strTNNew
				rs0("NomPhoto") = Request("NomPhoto")
			end if

			Set fso = nothing
		end if

		if Request("DescrPhoto") <> empty then
			rs0("DescrPhoto") = Request("DescrPhoto")
		else
			rs0("DescrPhoto") = null
		end if

		if Request("DtYear") <> empty then
			rs0("DtYear") = Request("DtYear")
			rs0("Date") = Format(Request("DtYear"), "0000")
		else
			rs0("DtYear") = null
			rs0("Date") = null
		end if

		if Request("DtMonth") <> empty then
			rs0("DtMonth") = Request("DtMonth")
			if Request("DtMonth") > 0 then
				rs0("Date") = rs0("Date") & "/" & Format(Request("DtMonth"), "00")
			end if
		else
			rs0("DtMonth") = null
		end if

		if Request("DtDay") <> empty then
			rs0("DtDay") = Request("DtDay")
			if Request("DtDay") > 0 then
				rs0("Date") = rs0("Date") & "/" & Format(Request("DtDay"), "00")
			end if
		else
			rs0("DtDay") = null
		end if

		rs0("LastUpdateWho") = Session("IDUser")
		rs0("LastUpdateWhen") = now()

		rs0.Update

		lngIDPersonne = Request("IdPersonne")
		intPos = instr(lngIDPersonne, ",")
		intCpt = 1
		while intPos > 1
			strSQL = "INSERT INTO LienPhotoPerso (IdPhoto, IdPersonne, SortKey) " & _
			         "SELECT " & Request("IDPhoto") & ", " & _
			         left(lngIDPersonne, intPos - 1) & ", " & intCpt
			rs1.Open strSQL, conConnexion
			lngIDPersonne = mid(lngIDPersonne, intPos + 1)
			intPos = instr(lngIDPersonne, ",")
			intCpt = intCpt + 1
		wend
		if lngIDPersonne <> empty then
			strSQL = "INSERT INTO LienPhotoPerso (IdPhoto, IdPersonne, SortKey) " & _
			         "SELECT " & Request("IDPhoto") & ", " & lngIDPersonne & ", " & intCpt
			rs1.Open strSQL, conConnexion
		end if
	end if
	rs0.Close

elseif Request("todo") = "add" then

	strSQL = "SELECT * FROM Photo WHERE IDPhoto=0"
	'Response.Write strSQL & "<br>"
	rs0.Open strSQL, conConnexion, 2, 3

	rs0.AddNew
	if Request("NomPhoto") <> empty then
		rs0("NomPhoto") = Request("NomPhoto")
	else
		rs0("NomPhoto") = null
	end if

	if Request("DescrPhoto") <> empty then
		rs0("DescrPhoto") = Request("DescrPhoto")
	else
		rs0("DescrPhoto") = null
	end if

	if Request("DtYear") <> empty then
		rs0("DtYear") = Request("DtYear")
		rs0("Date") = Format(Request("DtYear"), "0000")
	else
		rs0("DtYear") = null
		rs0("Date") = null
	end if

	if Request("DtMonth") <> empty then
		rs0("DtMonth") = Request("DtMonth")
		if Request("DtMonth") > 0 then
			rs0("Date") = rs0("Date") & "/" & Format(Request("DtMonth"), "00")
		end if
	else
		rs0("DtMonth") = null
	end if

	if Request("DtDay") <> empty then
		rs0("DtDay") = Request("DtDay")
		if Request("DtDay") > 0 then
			rs0("Date") = rs0("Date") & "/" & Format(Request("DtDay"), "00")
		end if
	else
		rs0("DtDay") = null
	end if

	rs0("LastUpdateWho") = Session("IDUser")
	rs0("LastUpdateWhen") = now()

	rs0.Update
	rs0.MoveFirst
	lngIDPhoto = rs0("IDPhoto")
	rs0.Close

end if

if Request("IDPhoto") <> empty then lngIDPhoto = Request("IDPhoto")

if Request("PhotoDetails") <> empty then
	Dim strTN

	strTN = FindTN(strImage, Request("PhotoDetails"))
	Response.Write "<form action=photoPage.asp method=post>" 
	Response.Write "<input type=hidden name=todo value=add>" 
	Response.Write "<input type=hidden name=NomPhoto value=""" & Request("PhotoDetails") & """>" 

	Response.Write "<table border=0 cellpadding=0 cellspacing=0>"
	Response.Write "<tr><td align=right>"

	Response.Write "File Name&nbsp;<input type=text name=Nothing value=""" & Request("PhotoDetails") & """ size=30 class=box><br>"
	Response.Write "Date&nbsp;"
	PrintDayDrop 0
	PrintMonthDrop 0
	Response.Write "<input type=text name=DtYear size=5 maxlength=4 class=box><br>"
	Response.Write "<textarea name=DescrPhoto cols=30 rows=15 class=box>"
	Response.Write "</textarea><br><br>"
	Response.Write "<input type=submit value=Add class=box><br><br>"
	Response.Write "<a href=""" & strImage & Request("PhotoDetails") & """ target=_blank>"
	Response.Write "<img src=""" & strTN & """ border=0></a><br>"
	Response.Write "&nbsp;<br>&nbsp;<br>&nbsp;<br>"

	Response.Write "</td></tr>"
	Response.Write "</table>"

	Response.Write "</form>"

	Response.Write strTNWarning

elseif lngIDPhoto <> empty then

	lngIDPersonne = "."
	strSQL = "SELECT * FROM LienPhotoPerso WHERE IDPhoto=" & lngIDPhoto
	rs1.Open strSQL, conConnexion, 2, 3
	while not rs1.eof
		lngIDPersonne = lngIDPersonne & rs1("IdPersonne") & "."
		rs1.MoveNext
	wend
	rs1.Close
		
	strSQL = "SELECT * FROM Photo WHERE IDPhoto=" & lngIDPhoto
	rs1.Open strSQL, conConnexion, 2, 3
	
	if not rs1.eof then
		strTN = FindTN(strImage, rs1("NomPhoto"))
		Response.Write "<form action=photoPage.asp name=myForm method=post>" 
		Response.Write "<input type=hidden name=IDPhoto value=" & rs1("IDPhoto") & ">" 
		Response.Write "<input type=hidden name=todo value=update>" 

		Response.Write "<table border=0 cellpadding=0 cellspacing=0><tr valign=top><td align=right>" 

		Response.Write "File Name <input type=text size=30 name=NomPhoto value=""" & rs1("NomPhoto") & """ class=box><br>"
		Response.Write "Date&nbsp;"
		PrintDayDrop rs1("DtDay")
		PrintMonthDrop rs1("DtMonth")
		Response.Write "<input type=text name=DtYear size=5 maxlength=4 value=""" & rs1("DtYear") & """ class=box><br>"
		Response.Write "<textarea name=DescrPhoto cols=30 rows=15 class=box>"
		Response.Write rs1("DescrPhoto")
		Response.Write "</textarea><br><br>"
		Response.Write "<input type=submit value=Update OnClick=""SelectAll();"" class=box>"
		Response.Write "<input type=submit name=del value=Delete class=box><br><br>"
		Response.Write "<a href=""" & strImage & rs1("NomPhoto") & """ target=_blank>"
		Response.Write "<img src=""" & strTN & """ border=0></a>"

		Response.Write "</td><td>&nbsp;</td><td>All:<br>" 

		strSQL = "SELECT * FROM Personne ORDER BY Nom, Prenom, DtNaiss"
		rs2.Open strSQL, conConnexion, 2, 3
		Response.Write "<select name=Tous multiple onChange=""Add()"" size=25 class=box style={width:200px}>"
		while not rs2.eof
			Response.Write "<option value=" & rs2("IDPersonne")
			Response.Write ">" & rs2("Nom") & " " &  rs2("Prenom") & " " &  rs2("DtNaiss")
			rs2.MoveNext
		wend
		Response.Write "</select><br>"
		rs2.Close
		Response.Write "<b>Click to Select</b>"

		Response.Write "</td><td>Present on the Picture:<br>" 

		strSQL = "SELECT Personne.*, IDPhoto FROM Personne, LienPhotoPerso " & _
				 "WHERE Personne.IDPersonne=LienPhotoPerso.IdPersonne " & _
				 "AND LienPhotoPerso.IdPhoto=" & rs1("IDPhoto") & " " & _
				 "ORDER BY SortKey, Nom, Prenom, DtNaiss"
		rs2.Open strSQL, conConnexion, 2, 3
		Response.Write "<select name=IdPersonne multiple size=25 class=box style={width:200px}>"
		while not rs2.eof
			Response.Write "<option value=" & rs2("IDPersonne")
			Response.Write ">" & rs2("Nom") & " " &  rs2("Prenom") & " " &  rs2("DtNaiss")
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
		Response.Write "</table>"

		Response.Write "</form>"

		Response.Write strTNWarning

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
		if request("del") <> empty then
			Response.Write "Entry Deleted<br>"
		else
			Response.Write "Problem! [1]<br>"
		end if
	end if

	rs1.close

else
	Response.Write "Problem! [2]<br>"
end if

Response.Write "<p><a href=photoList.asp target=left>&lt;&lt;&lt; Refresh the file list &lt;&lt;&lt;</a></p>"

if strError <> empty then
	Response.Write "<p><b>" & strError & "</b></p>"
end if
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->
<!--#include VIRTUAL="/Include/DAOFooter.asp"-->

<%
function FindTN(MyFolder, MyFileName)
	select case LCase(right(MyFileName, 3))
		case "jpg", "gif"
			FindTN = MyFolder & left(MyFileName, len(MyFileName) - 3) & "tn." & right(MyFileName, 3)
		case "doc"
			FindTN = "/Image/doc.gif"
		case "mdb"
			FindTN = "/Image/mdb.gif"
		case "pdf"
			FindTN = "/Image/pdf.gif"
		case "ppt"
			FindTN = "/Image/ppt.gif"
		case "txt"
			FindTN = "/Image/txt.gif"
		case "xls"
			FindTN = "/Image/xls.gif"
		case "zip"
			FindTN = "/Image/zip.gif"
		case else
			FindTN = "/Image/other.gif"
	end select

end function

sub PrintDayDrop(myDay)
	dim iDay

	Response.Write "<select name=DtDay class=box>"
	Response.Write "<option value=0> "
	for iDay = 1 to 31
		Response.Write "<option value=" & iDay
		if iDay = cdbl(myDay) then Response.Write " selected"
		Response.Write ">" & iDay
	next
	Response.Write "</select>"

end sub

sub PrintMonthDrop(myMonth)

	dim iMonth, strArrMonths()
	redim strArrMonths(12)

	strArrMonths(01) = "Jan" : strArrMonths(02) = "Feb" : strArrMonths(03) = "Mar"
	strArrMonths(04) = "Apr" : strArrMonths(05) = "May" : strArrMonths(06) = "Jun"
	strArrMonths(07) = "Jul" : strArrMonths(08) = "Aug" : strArrMonths(09) = "Sep"
	strArrMonths(10) = "Oct" : strArrMonths(11) = "Nov" : strArrMonths(12) = "Dec"

	Response.Write "<select name=DtMonth class=box>"
	Response.Write "<option value=0> "
	for iMonth = 1 to 12
		Response.Write "<option value=" & iMonth
		if iMonth = cdbl(myMonth) then Response.Write " selected"
		Response.Write ">" & strArrMonths(iMonth)
	next
	Response.Write "</select>"

end sub
%>
