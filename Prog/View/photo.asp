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
Response.Write "<center>"
'Response.Write "<center><a href=javascript:window.close();>" & strClose & "</a><br><br>"

dim lngIDPhoto

if Request("IDPhoto") = Empty then
	lngIDPhoto = 0
else
	lngIDPhoto = Request("IDPhoto")
end if

strSQL = "SELECT * FROM Photo WHERE IDPhoto=" & lngIDPhoto
rs0.Open strSQL, conConnexion, 2, 3

if not rs0.EOF then

	Response.Write "<a href=javascript:history.back();><img src=""" & strImage & rs0("NomPhoto") & """ border=0></a><br><br>"
	if rs0("DescrPhoto") <> empty then
		Response.Write replace(rs0("DescrPhoto"), VbCrlf, "<br>") & "<br>"
	end if

	Response.Write PresentDatePhoto(rs0("DtYear"), rs0("DtMonth"), rs0("DtDay"))

	strSQL = "SELECT Personne.* " & _
			 "FROM Personne INNER JOIN LienPhotoPerso ON (Personne.IDPERSONNE = LienPhotoPerso.IdPersonne) " & _
			 "WHERE IdPhoto=" & lngIDPhoto & _
			 " ORDER BY SortKey, Nom, Prenom"
	rs1.Open strSQL, conConnexion, 2, 3

	if not rs1.EOF then
		Response.Write "<i><a href=bio.asp?ID=" & rs1("IDPersonne") & _
					   " alt=""" & PresentDate(rs1("dtNaiss"), rs1("dtDec")) & """" & _
					   " title=""" & PresentDate(rs1("dtNaiss"), rs1("dtDec")) & """" & _
					   ">" & rs1("Prenom") & " " & rs1("Nom") & "</a>"
		rs1.MoveNext
		while not rs1.EOF 
			Response.Write ", <a href=bio.asp?ID=" & rs1("IDPersonne") & _
						   " alt=""" & PresentDate(rs1("dtNaiss"), rs1("dtDec")) & """" & _
						   " title=""" & PresentDate(rs1("dtNaiss"), rs1("dtDec")) & """" & _
						   ">" & rs1("Prenom") & " " & rs1("Nom") & "</a>"
			rs1.MoveNext
		wend
		Response.Write ".</i>"
	end if

	rs1.Close
end if

rs0.Close

Response.Write "</center>"
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->

<%
end if
%>

<!--#include VIRTUAL="/Include/DAOFooter.asp"-->

<%
Function PresentDate(byval dtNaiss, byval dtDec)
	if dtDec <> "" then
		PresentDate  = "["& dtNaiss &"-"& dtDec &"]"
	else
		PresentDate = "["& dtNaiss &"]"
	end if
End Function

function PresentDatePhoto(myYear, myMonth, myDay)

	dim strPresentDatePhoto
	
	if myYear <> empty then 
		strPresentDatePhoto = "<b>("
			if myMonth > 0 then
				if myDay > 0 then
					strPresentDatePhoto = strPresentDatePhoto & myDay & " "
				end if
				strPresentDatePhoto = strPresentDatePhoto & arrMonth(myMonth) & " "
			end if
		strPresentDatePhoto = strPresentDatePhoto & myYear & ")</b><br><br>"
	end if

	PresentDatePhoto = strPresentDatePhoto

end function

%>