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
	dim kCol, kRow, intTotal, intPage
	dim flgPrev, flgNext
	dim strNamePhoto(), strCommPhoto(), strDatePhoto(), lngIDPhoto(), strDateTag()
	dim cptPhoto, intCol, intRow, i, j
	kCol = 4
	kRow = 5
	redim strNamePhoto(kCol, kRow)
	redim strCommPhoto(kCol, kRow)
	redim strDatePhoto(kCol, kRow)
	redim   lngIDPhoto(kCol, kRow)
	redim strDateTag(0)

	intTotal = CountPictures()
	SetPageCounter
	SetPictureTitles

	Response.Write "<table border=1 cellpadding=0 cellspacing=0 align=center bgcolor=silver bordercolor=silver>"

	PrintPageCounter
	PrintFolders

	dim strAltTitle
	for i = 1 to kRow
		Response.Write "<tr align=center valign=middle height=100>"
		for j = 1 to kCol
			strAltTitle = PresentComment(strNamePhoto(j, i), strCommPhoto(j, i), strDatePhoto(j, i))
			if strNamePhoto(j, i) <> "" then
				Response.Write "<td width=100><a href=""photo.asp?IDPhoto=" & lngIDPhoto(j, i) & """" & _
				" alt=""" & strAltTitle & """ " & _
				" title=""" & strAltTitle & """ " & _
				">" & myThumbnailTag(strNamePhoto(j, i)) & "</a></td>"

			else
				Response.Write "<td width=100><img src=/Image/pix.gif height=100 width=100></td>"
			end if
		next
		Response.Write "</tr>"
	next

	PrintAllPictures
	Response.Write "</table>"
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->

<%
end if
%>

<!--#include VIRTUAL="/Include/DAOFooter.asp"-->

<% 
Function CountPictures()
	strSQL = "SELECT Count(IDPhoto) FROM Photo " & _
			 "WHERE Right(NomPhoto, 3)='jpg' OR Right(NomPhoto, 3)='gif';"
	rs0.Open strSQL, conConnexion
	if not rs0.eof then
		CountPictures = rs0(0)
	else
		CountPictures = 0
	end if
	rs0.Close
End Function

Function PresentComment(byval strNameWork, byval strCommWork, byval strDateWork)
	Dim Pos1, Pos2, strWork
	
	strNameWork = cstr(strNameWork)
	strCommWork = cstr(strCommWork & "")
	
'	if strNameWork = "" then
'		strWork = ""
'	elseif strCommWork = "" then
'		strNameWork = strReverse(strNameWork)
'		Pos1 = inStr(strNameWork, ".")
'		Pos2 = inStr(strNameWork, "/")
'		if Pos1 + Pos2 > 2 then strNameWork = mid(strNameWork, Pos1 + 1, Pos2 - Pos1 - 1)
'		strWork = strReverse(strNameWork)
'	else
'		strCommWork = replace(strCommWork, VbCrlf ," ")
'		strCommWork = replace(strCommWork, """" ,"'")
'		strWork = strDateWork & " " & strCommWork
'	end if

	if strNameWork <> "" then
		strNameWork = strReverse(strNameWork)
		Pos1 = inStr(strNameWork, ".")
		Pos2 = inStr(strNameWork, "/")
		if Pos1 + Pos2 > 2 then strNameWork = mid(strNameWork, Pos1 + 1, Pos2 - Pos1 - 1)
		strWork = strReverse(strNameWork)
	end if

	PresentComment = strWork
End Function

sub SetPageCounter()
	strSQL = "SELECT * FROM Photo " & _
			 "WHERE Right(NomPhoto, 3)='jpg' OR Right(NomPhoto, 3)='gif' " & _
			 "ORDER BY Date, NomPhoto"
	rs0.Open strSQL, conConnexion, 2, 3
	cptPhoto = 0 
	while not rs0.EOF 
		select case cptPhoto
			case 0
				redim preserve strDateTag(ubound(strDateTag) + 1)
				strDateTag(ubound(strDateTag)) = "[" & rs0("DtYear") & "]"
			case (kCol * kRow) - 1
				if "[" & rs0("DtYear") & "]" <> strDateTag(ubound(strDateTag)) then _
					strDateTag(ubound(strDateTag)) = strDateTag(ubound(strDateTag)) & _
													 "[" & rs0("DtYear") & "]"
				cptPhoto = -1
		end select 

		rs0.MoveNext
		cptPhoto = cptPhoto + 1 
	wend
	if ubound(strDateTag) > 0 then
		rs0.MoveFirst
		rs0.MoveLast
		if "[" & rs0("DtYear") & "]" <> strDateTag(ubound(strDateTag)) then _
			strDateTag(ubound(strDateTag)) = strDateTag(ubound(strDateTag)) & _
											 "[" & rs0("DtYear") & "]"
	end if
end sub

sub SetPictureTitles()
	if not rs0.eof then rs0.MoveFirst
	cptPhoto = 0 
	if int(Request("start")) > 0 then
		i = 0
		while not rs0.EOF and i < int(Request("start"))
			i = i + 1
			rs0.MoveNext
		wend
		flgPrev = int(Request("start")) - kCol * kRow + 1
	end if

	while not rs0.EOF and cptPhoto < kCol * kRow
		cptPhoto = cptPhoto + 1
		intRow = int((cptPhoto - 1)/kCol) + 1
		intCol = cptPhoto - (intRow - 1) * kCol

		strNamePhoto(intCol, intRow) = strImage & rs0("NomPhoto")
		strCommPhoto(intCol, intRow) = rs0("DescrPhoto")
		strDatePhoto(intCol, intRow) = "[" & rs0("Date") & "]"
		lngIDPhoto(intCol, intRow) = rs0("IDPhoto")

		rs0.MoveNext
	wend

	if not rs0.EOF then flgNext = cptPhoto + int(Request("start"))
	rs0.Close
end sub

sub PrintPageCounter
	Response.Write "<tr><td colspan=" & kCol & " align=center>."
	for i = 1 to uBound(strDateTag)
		if (i-1)*kCol*kRow = int(Request("start")) then
			Response.Write "<a href=lstPhotos.asp?start=" & (i-1)*kCol*kRow & _
						   " alt=""" & strDateTag(i) & """ " & _
						   " title=""" & strDateTag(i) & """ " & _
						   "><b>" & i & "</b></a>."
		else
			if intPage <= Ubound(strDateTag) then
				Response.Write "<a href=lstPhotos.asp?start=" & (i-1)*kCol*kRow & _
							   " alt=""" & strDateTag(i) & """ " & _
							   " title=""" & strDateTag(i) & """ " & _
							   ">" & i & "</a>."
			else
				Response.Write "<a href=lstPhotos.asp?start=" & (i-1)*kCol*kRow & _
							   ">" & i & "</a>."
			end if
		end if
	next
	Response.Write "</td></tr>"
end sub

sub PrintFolders()
	strSQL = "SELECT Left([NomPhoto],InStr([NomPhoto],'/')-1) AS Folder " & _
			 "FROM Photo " & _
			 "WHERE Photo.NomPhoto Like '%/%' " & _
			 "GROUP BY Left([NomPhoto],InStr([NomPhoto],'/')-1) " & _
			 "ORDER BY Left([NomPhoto],InStr([NomPhoto],'/')-1);"
	rs0.Open strSQL, conConnexion

	Response.Write "<tr><td colspan=" & kCol & " align=center>"
	while not rs0.EOF
		Response.Write "<a href=""lstPhotosAll.asp?folder=" & rs0("Folder") & """>" & replace(rs0("Folder"), " ", "&nbsp;") & "</a>"
		rs0.MoveNext
		if not rs0.EOF then Response.Write " | "
	wend
	Response.Write "</td></tr>"
	rs0.Close
end sub

sub PrintAllPictures()
	Response.Write "<tr><td colspan=" & kCol & " align=center>"
	Response.Write "<a href=lstPhotosAll.asp>" & strPicturesAll & "</a> | "
	Response.Write "<a href=lstPhotosAll.asp?tri=last>" & strLastIn & "</a>"
	Response.Write "</td></tr>"
end sub


'	Response.Write "<tr><td colspan=" & kCol & " align=center>"
'	if flgPrev > 0 then
'		Response.Write "<a href=lstPhotos.asp?start=" & flgPrev - 1 & ">&lt;--</a>"
'	else
'		Response.Write "&lt;--"
'	end if
'	Response.Write " | "
'	if flgNext > 0 then
'		Response.Write "<a href=lstPhotos.asp?start=" & flgNext & ">--&gt;</a>"
'	else
'		Response.Write "--&gt;"
'	end if
'	Response.Write "</td></tr>"
'--------------------------------------------------------------------------
'	Response.Write "<tr><td colspan=" & kCol & " align=center>"
'	if flgPrev > 0 then
'		Response.Write "<a href=lstPhotos.asp?start=" & flgPrev - 1 & ">&lt;--</a>"
'	else
'		Response.Write "&lt;--"
'	end if
'	Response.Write " | "
'	if flgNext > 0 then
'		Response.Write "<a href=lstPhotos.asp?start=" & flgNext & ">--&gt;</a>"
'	else
'		Response.Write "--&gt;"
'	end if
'	Response.Write "</td></tr>"

'	Response.Write "<tr><td colspan=" & kCol & " align=center>"
'	Response.Write "<a href=lstPhotosAll.asp>" & strPicturesAll & "</a>"
'	Response.Write "</td></tr>"

%>