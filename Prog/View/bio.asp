<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/Label.asp"-->
<!--#include VIRTUAL="/Include/FunctImg.asp"-->

<%
if Session(strUpload & "IsUser") <> true then
	Response.Redirect "/login.asp"
else
%>

<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
	Dim lngID, bolSexe, strPhoto, strB, strC, strP, strD, strLinkTop

	strLinkTop = "<tr><td colspan=4><a href=#top style={color:red}>" & strTop & _
				 "</a><hr size=1 noshade></td></tr>"

	if Request("ID") = Empty then
		lngID = 0
	else
		lngID = Request("ID")
	end if

	strSQL = "SELECT * FROM Personne WHERE IDPersonne=" & lngID
	rs0.Open strSQL, conConnexion, 2, 3

	if not rs0.EOF then

		printHeader
		strB = printBio(rs0("Comm"))
		strC = printComments(rs0("IDPersonne"))
		strP = printPictures(rs0("IDPersonne"))
		strD = printDocs(rs0("IDPersonne"))

		Response.Write "<table border=0 width=100%cellpadding=0 cellspacing=2>"
		Response.Write "<tr><td colspan=4>"
		Response.Write "<b>"
	'	Response.Write "<a href=javascript:history.back();>" & strBack & "</a>&nbsp;"
		if strB <> "" then Response.Write "&gt; <a href=#bio>" & strBiography & "</a>&nbsp;"
		if strC <> "" then Response.Write "&gt; <a href=#com>" & strComments & "</a>&nbsp;"
		if strP <> "" then Response.Write "&gt; <a href=#pic>" & strPictures & "</a>&nbsp;"
		if strD <> "" then Response.Write "&gt; <a href=#doc>" & strDocuments & "</a>&nbsp;"
		if strB & strC & strP & strD <> "" then Response.Write "<br><br>"
		Response.Write "</b>"
		Response.Write "<hr size=1 noshade>"
		Response.Write "</td></tr>"

		Response.Write strB & strC & strP & strD
		Response.Write "</table>"

	end if
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->

<%
end if
%>

<!--#include VIRTUAL="/Include/DAOFooter.asp"-->

<%
function PresDate(dtDate)
	dim strDate
	
	if strDateFormat = "mdy" then
		strDate = arrMonth(Month(dtDate)) & " " & Day(dtDate) & ", " & Year(dtDate)
	else
		strDate = Day(dtDate) & " " & arrMonth(Month(dtDate)) & " " & Year(dtDate)
	end if
	
	PresDate = strDate

end function


sub printHeader()
	Response.Write "<a name=top></a><center>" 'Print Header 
	Response.Write "<h1><a href=frame.asp?IDPerso=" & rs0("IDPersonne") & " target=main>"
	Response.Write rs0("Prenoms") & "&nbsp;" & rs0("Nom") & "</a></h1>"
	Response.Write "<b>("
	if Not IsNull(rs0("DateNaiss")) then
		Response.Write PresDate(rs0("DateNaiss"))
	else
		Response.Write rs0("DtNaiss")
	end if
	Response.Write "-"
	if Not IsNull(rs0("DateDec")) then
		Response.Write PresDate(rs0("DateDec"))
	else
		Response.Write rs0("DtDec")
	end if
	Response.Write ")</b><br>"

	if not IsNull(rs0("LieuNaiss")) then
		if rs0("IsMasc") then
			Response.Write strBornInM & "&nbsp;" & rs0("LieuNaiss") & ".&nbsp;"
		else
			Response.Write strBornInF & "&nbsp;" & rs0("LieuNaiss") & ".&nbsp;"
		end if
	end if

	if not IsNull(rs0("LieuDec")) then
		if rs0("IsMasc") then
			Response.Write strDiedInM & "&nbsp;" & rs0("LieuDec") & ".&nbsp;"
		else
			Response.Write strDiedInF & "&nbsp;" & rs0("LieuDec") & ".&nbsp;"
		end if
	end if

	if rs0("Email") <> empty and IsNull(rs0("DtDec")) then _
		Response.Write "<br>[<a href=message.asp?IDForum=perso&IDPerso=" & _
					   rs0("IDPersonne") & ">Email</a>]"
	Response.Write "</center><br>" 

	Response.Write PresentLinks(rs0("Link")) 
end sub


function printBio(strWork)
	if strWork <> empty then
		printBio =	"<tr><td colspan=4><a name=bio></a><h2>" & strBiography & "</h2></td></tr>" & _
					"<tr><td colspan=3>&nbsp;</td><td>" & Replace(strWork & " ", VbCrlf, "<br>") & "</td></tr>" & _
					strLinkTop
	else
		printBio =	""
	end if
end function


function printComments(lngID)
	dim strWork, strBody

	strSQL = "SELECT Commentaire.* " & _
			 "FROM LienCommPerso INNER JOIN Commentaire ON LienCommPerso.IdCommentaire = Commentaire.IDCommentaire " & _
			 "WHERE LienCommPerso.IdPersonne=" & lngID & " " & _
			 "ORDER BY Commentaire.DtVecu"
	rs1.Open strSQL, conConnexion, 2, 3

	if not rs1.EOF then
		strWork =	"<tr><td colspan=4>" & _
					"<a name=com></a><h2>" & strComments & "</h2>" & _
					"</td></tr>"

		while not rs1.EOF
			strSQL = "SELECT Personne.Nom, Personne.Prenom, Personne.IDPersonne " & _
					 "FROM LienCommPerso INNER JOIN Personne ON LienCommPerso.IdPersonne=Personne.IDPersonne " & _
					 "WHERE IdCommentaire=" & rs1("IDCommentaire") & " AND LienCommPerso.IdPersonne<>" & lngID & " " & _
					 "ORDER BY SortKey, Nom, Prenom, DtNaiss"
			rs2.Open strSQL, conConnexion, 2, 3

			strBody = replace(rs1("Comm") & " ", VbCrlf, "<br>")

			strWork = strWork & "<tr valign=top>" & _
								"<td width=150 colspan=2><b>" & rs1("Titre") & "</b></td><td>&nbsp;</td>" & _
								"<td>"

			if rs1("DtVecu") <> empty then strWork = strWork & "<b>(" & rs1("DtVecu") & ")</b> "
			if rs1("Comm") <> empty then strWork = strWork & replace(rs1("Comm") & " ", VbCrlf, "<br>") & "<br>"

			if not rs2.EOF then
				strWork = strWork & "<i>" & strWith & ": " & _
						  "<a href=bio.asp?ID=" & rs2("IDPersonne") & ">" & _
						  rs2("Prenom") & "&nbsp;" & rs2("Nom") & "</a>"
				rs2.MoveNext

				while not rs2.EOF
					strWork = strWork & ", <a href=bio.asp?ID=" & rs2("IDPersonne") & _
							  ">" & rs2("Prenom") & "&nbsp;" & rs2("Nom") & "</a>"
					rs2.MoveNext
				wend
				strWork = strWork & ".</i><br>"
			end if

			rs2.Close
			rs1.MoveNext
		wend

		strWork = strWork & "</td></tr>" & strLinkTop
	end if
	rs1.close

	printComments = strWork
end function


function printPictures(lngID)
	dim strWork, strBody

	strSQL = "SELECT Photo.* " & _
			 "FROM LienPhotoPerso INNER JOIN Photo ON LienPhotoPerso.IdPhoto = Photo.IDPhoto " & _
			 "WHERE LienPhotoPerso.IdPersonne=" & lngID & " AND " & _
			 "(Right(NomPhoto, 3)='jpg' OR Right(NomPhoto, 3)='gif') " & _
			 "ORDER BY DtYear, DtMonth, DtDay, NomPhoto;"
	rs1.Open strSQL, conConnexion, 2, 3

	if not rs1.EOF then
		strWork =	"<tr><td colspan=4>" & _
					"<a name=pic></a><h2>" & strPictures & "</h2>" & _
					"</td></tr>"

		while not rs1.EOF
			strSQL = "SELECT Nom, Prenom, Personne.IDPersonne " & _
					 "FROM LienPhotoPerso INNER JOIN Personne ON LienPhotoPerso.IdPersonne=Personne.IDPersonne " & _
					 "WHERE LienPhotoPerso.IdPhoto=" & rs1("IDPhoto") & " AND LienPhotoPerso.IdPersonne<>" & lngID & " " & _
					 "ORDER BY SortKey, Nom, Prenom, DtNaiss"
			rs2.Open strSQL, conConnexion, 2, 3

			strPhoto = strImage & rs1("NomPhoto")
			strWork = strWork & "<tr valign=top><td colspan=2 align=center width=150 height=100>" & _
					  "<a href=photo.asp?IDPhoto=" & rs1("IDPhoto") & ">" & myThumbnailTag(strPhoto) & "</a>" & _
					  "</td><td>&nbsp;</td><td>"

			strWork = strWork & PresentDate(rs1("DtYear"), rs1("DtMonth"), rs1("DtDay"))
			if rs1("DescrPhoto") <> empty then strWork = strWork & replace(rs1("DescrPhoto") & " ", VbCrlf, "<br>") & "<br>"

			if not rs2.EOF then
				strWork = strWork & "<i>" & strWith & ": " & _
						  "<a href=bio.asp?ID=" & rs2("IDPersonne") & ">" & _
						  rs2("Prenom") & "&nbsp;" & rs2("Nom") & "</a>"
				rs2.MoveNext
				while not rs2.EOF
					strWork = strWork & ", <a href=bio.asp?ID=" & rs2("IDPersonne") & _
					">" & rs2("Prenom") & "&nbsp;" & rs2("Nom") & "</a>"
					rs2.MoveNext
				wend
				strWork = strWork & ".</i><br><br>"
			end if

			rs2.Close
			rs1.MoveNext
		wend
		strWork = strWork & "</td></tr>" & strLinkTop
	end if
	rs1.close

	printPictures = strWork
end function


function printDocs(lngID)
	dim strWork, strBody, strFileN, strExtension
	
	strSQL = "SELECT Photo.* " & _
			 "FROM LienPhotoPerso INNER JOIN Photo ON LienPhotoPerso.IdPhoto = Photo.IDPhoto " & _
			 "WHERE LienPhotoPerso.IdPersonne=" & rs0("IDPersonne") & " AND " & _
			 "(Right(NomPhoto, 3)<>'jpg' AND Right(NomPhoto, 3)<>'gif') " & _
			 "ORDER BY Photo.Date, Photo.NomPhoto"
	rs1.Open strSQL, conConnexion, 2, 3

	if not rs1.EOF then
		strWork =	"<tr><td colspan=4>" & _
					"<a name=doc></a><h2>" & strDocuments & "</h2>" & _
					"</td></tr>"

		while not rs1.EOF
			strSQL = "SELECT Nom, Prenom, Personne.IDPersonne " & _
					 "FROM LienPhotoPerso INNER JOIN Personne ON LienPhotoPerso.IdPersonne=Personne.IDPersonne " & _
					 "WHERE LienPhotoPerso.IdPhoto=" & rs1("IDPhoto") & " AND LienPhotoPerso.IdPersonne<>" & rs0("IDPersonne") & " " & _
					 "ORDER BY SortKey, Nom, Prenom, DtNaiss"
			rs2.Open strSQL, conConnexion, 2, 3

			strPhoto = strImage & rs1("NomPhoto")

			strWork = strWork & "<tr valign=top><td align=center>"

			strFileN = Left(rs1("NomPhoto"), len(rs1("NomPhoto")) - 4)
'			strFileN = replace(Left(rs1("NomPhoto"), len(rs1("NomPhoto")) - 4), " ", "&nbsp;")
			strExtension = Right(rs1("NomPhoto"), 3)
			select case strExtension
				case "doc", "mdb", "pdf", "ppt", "pps", "txt", "xls", "zip"
					strWork = strWork & "<img src=/Image/Icon/" & strExtension & ".gif>"
				case else
					strWork = strWork & "<img src=/Image/Icon/other.gif>"
			end select

			strWork = strWork & "</td><td width=150>" & _
					  "<a href=""" & strDocument & rs1("NomPhoto") & """><b>" & _
					  strFileN & "</b></a></td><td>&nbsp;</td><td>"

			if rs1("Date") <> empty then strWork = strWork & "<b>(" & rs1("Date") & ")</b> "
			if rs1("DescrPhoto") <> empty then strWork = strWork & replace(rs1("DescrPhoto") & " ", VbCrlf, "<br>") & "<br>"

			if not rs2.EOF then
				strWork = strWork & "<i>" & strWith & ": " & _
						  "<a href=bio.asp?ID=" & rs2("IDPersonne") & ">" & _
						  rs2("Prenom") & "&nbsp;" & rs2("Nom") & "</a>"
				rs2.MoveNext
				while not rs2.EOF
					strWork = strWork & ", <a href=bio.asp?ID=" & rs2("IDPersonne") & _
					">" & rs2("Prenom") & "&nbsp;" & rs2("Nom") & "</a>"
					rs2.MoveNext
				wend
				strWork = strWork & ".</i><br><br>"
			end if
			rs2.Close
			rs1.MoveNext
		wend
		strWork = strWork & "</td></tr>" & strLinkTop
	end if
	rs1.close

	printDocs = strWork
end function

function PresentDate(myYear, myMonth, myDay)

	dim strPresentDate
	
	if myYear <> empty then 
		strPresentDate = "<b>("
			if myMonth > 0 then
				if myDay > 0 then
					strPresentDate = strPresentDate & myDay & " "
				end if
				strPresentDate = strPresentDate & arrMonth(myMonth) & " "
			end if
		strPresentDate = strPresentDate & myYear & ")</b> "
	end if

	PresentDate = strPresentDate

end function

function PresentLinks(strLink)
	dim strWork
	if strLink <> empty then
		arrLink = Split(strLink, VbCrlf)
		
		for i = 0 to ubound(arrLink)
			intPos1 = inStr(arrLink(i), "-")
			intPos2 = inStr(arrLink(i), "=")
			if intPos1 > 0 and intPos2 > 0 then
				strDom   = left(arrLink(i), intPos2 - 1)
				strTitle = mid(arrLink(i), intPos1 + 1, intPos2 - intPos1 - 1)
				strID    = mid(arrLink(i), intPos2 + 1)

				strWork = strWork & _
					"&lt;<a href=""bio.asp?ID=" & strID & "&LinkDom=" & strDom & """>" & _
					strTitle & "</a>&gt; "
			end if 
		next
	end if
	PresentLinks = strWork & "<br><br>" 
end function
%>