<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/Label.asp"-->

<%
if Session(strUpload & "IsUser") <> true then
	Response.Redirect "/login.asp"
else
%>

<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
	dim strPersCaption()
	redim strPersCaption(0)

	dim strMySearch, strLogo

	MaxCols = 3

'SELECT Personne.IDPersonne, Nom, Prenom, DtNaiss, DtDec, Count(LienPhotoPerso.IdPhoto) AS cptPhoto
'FROM Personne LEFT JOIN LienPhotoPerso ON Personne.IDPersonne = LienPhotoPerso.IdPersonne
'GROUP BY Personne.IDPersonne, Nom, Prenom, DtNaiss, DtDec;



	strSQL = "SELECT Personne.IDPersonne, Nom, Prenom, DtNaiss, DtDec, Personne.LastUpdateWhen, " & _
			 "Count(LienPhotoPerso.IdPhoto) AS cptPhoto " & _
			 "FROM Personne LEFT JOIN LienPhotoPerso ON " & _
			 "Personne.IDPersonne = LienPhotoPerso.IdPersonne "

	if request("search") <> empty then
		strMySearch = replace(request("search"), " ", "%")
		strMySearch = request("search")
		strSQL = strSQL & "WHERE Nom&Prenom&Nom LIKE '%" & strMySearch & "%' "
	end if

	strSQL = strSQL & "GROUP BY Personne.IDPersonne, Nom, Prenom, DtNaiss, DtDec, Personne.LastUpdateWhen "

	select case request("tri")
		case "Dates" 
			strSQL = strSQL & "ORDER BY DtNaiss, DtDec, Nom, Prenom"
		case "Last" 
			strSQL = strSQL & "ORDER BY Personne.LastUpdateWhen DESC, Personne.IDPersonne DESC"
		case else
			strSQL = strSQL & "ORDER BY Nom, Prenom, DtNaiss"
	end select
	rs0.Open strSQL, conConnexion, 2, 3


	while not rs0.EOF
		redim preserve strPersCaption(ubound(strPersCaption) + 1)

		if rs0("cptPhoto") = 0 then
			strLogo = "<img src=/Image/Icon/logBio.gif border=0 valign=absolute-middle>"
		else
			strLogo = "<img src=/Image/Icon/logPhoto.gif border=0 valign=absolute-middle>"
		end if

		select case request("tri")
			case "Dates" 
				strPersCaption(ubound(strPersCaption)) = _
					"<a href=bio.asp?ID=" & rs0("IDPersonne") & ">" & strLogo & "</a>" & _
					"<a href=frame.asp?IDPerso=" & _
					rs0("IDPersonne") & ">(" & rs0("DtNaiss") & "-" & rs0("DtDec") & ")&nbsp;" & _
					replace(server.HTMLEncode(rs0("Nom") & " " & rs0("Prenom")), " ", "&nbsp;") & _
					"</a>"
			case else
				strPersCaption(ubound(strPersCaption)) = _
					"<a href=bio.asp?ID=" & rs0("IDPersonne") & ">" & strLogo & "</a>" & _
					"<a href=frame.asp?IDPerso=" & rs0("IDPersonne") & ">" & _
					replace(server.HTMLEncode(rs0("Nom") & " " & rs0("Prenom")), " ", "&nbsp;") & _
					"&nbsp;(" & rs0("DtNaiss") & "-" & rs0("DtDec") & ")</a>"
		end select
		
		rs0.MoveNext
	wend

	dim MaxRows, MaxCols, lngLine, i, j

	'MaxRows = 110
	'MaxCols = ubound(strPersCaption) / MaxRows
	'if int(MaxCols) < MaxCols then MaxCols = int(MaxCols) + 1
	MaxRows = ubound(strPersCaption) / MaxCols
	if int(MaxRows) < MaxRows then MaxRows = int(MaxRows) + 1

	Response.Write "<table border=0 cellpadding=0 cellspacing=0 align=center>"
	Response.Write "<form action=lstNomDate.asp method=post>"
	Response.Write "<tr><td colspan=2><a href=lstNomDate.asp?tri=Last>" & strLastIn & "</a></td>"
	Response.Write "<td colspan=" & (MaxCols - 1) * 2 & " align=right>"
	Response.Write "<input type=hidden name=tri value=""" & request("tri") & """>"
	Response.Write "<input type=text name=search value=""" & request("search") & """ class=box>"
	Response.Write "<input type=submit value=""" & strSearch & """ class=box><br>"
	Response.Write "</td></tr>"
	Response.Write "<tr><td colspan=" & MaxCols * 2 & ">"
	Response.Write "<hr size=1 noshade>"
	Response.Write "</td></tr>"
	Response.Write "</form>"

	for i = 1 to MaxRows
		Response.Write "<tr>"
		for j = 1 to MaxCols
			Response.Write "<td>"
			lngLine = (j-1)*MaxRows+i
			if lngLine <= ubound(strPersCaption) then
				Response.Write strPersCaption(lngLine)
			else
				Response.Write "&nbsp;"
			end if
			Response.Write "</td><td>&nbsp;</td>"
		next
		Response.Write "</tr>"
	next

	Response.Write "<tr>"
	Response.Write "<td align=center colspan=" & MaxCols * 2 & "><br>" & ubound(strPersCaption) & " " & strIndividuals & "</td>"
	Response.Write "</tr>"

	Response.Write "</table>"
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->

<%
end if
%>

<!--#include VIRTUAL="/Include/DAOFooter.asp"-->
