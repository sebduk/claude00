<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/FunctImg.asp"-->
<!--#include VIRTUAL="/Include/Label.asp"-->

<%
if Session(strUpload & "IsUser") <> true then
	Response.Redirect "/login.asp"
else
%>

<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
	dim kCol, kRow, intTotal, intPage
	dim cptPhoto, MaxCols, i
	dim strNamePhoto, lngIDPhoto, strDateTag()
	redim strDateTag(0)

	if Request("folder") <> empty or Request("tri") = "last" then
		MaxCols = 4		'in all pictures page
	else
		MaxCols = 8	
	end if
	kCol = 4			'in limited picture page
	kRow = 5

	SetPageCounter

	Response.Write "<table border=1 cellpadding=0 cellspacing=0 align=center bgcolor=silver bordercolor=silver>"
	PrintPageCounter
	PrintFolders

	if Request("folder") <> empty then
		strSQL = "SELECT * FROM Photo " & _
				 "WHERE (Right(NomPhoto, 3)='jpg' OR Right(NomPhoto, 3)='gif') AND " & _
				 "NomPhoto LIKE '" & Request("folder") & "/%' " & _
				 "ORDER BY DtYear, DtMonth, DtDay, NomPhoto"
	elseif Request("tri") = "last" then
		strSQL = "SELECT top 20 * FROM Photo " & _
				 "WHERE Right(NomPhoto, 3)='jpg' OR Right(NomPhoto, 3)='gif' " & _
				 "ORDER BY LastUpdateWhen DESC, IDPhoto DESC"
	else
		strSQL = "SELECT * FROM Photo " & _
				 "WHERE Right(NomPhoto, 3)='jpg' OR Right(NomPhoto, 3)='gif' " & _
				 "ORDER BY DtYear, DtMonth, DtDay, NomPhoto"
	end if
	rs0.Open strSQL, conConnexion, 2, 3

	cptPhoto = 0 
	while not rs0.eof
		if cptPhoto = 0 then
			Response.Write "<tr height=100>"
		elseif cptPhoto = MaxCols then
			cptPhoto = 0	 
			Response.Write "</tr><tr height=100>"
		end if

		strNamePhoto = strImage & rs0("NomPhoto")
		lngIDPhoto = rs0("IDPhoto")

		Response.Write "<td align=center width=100>"
		Response.Write "<a href=photo.asp?IDPhoto=" & lngIDPhoto & ">" & myThumbnailTag(strNamePhoto) & "</a></td>"

		cptPhoto = cptPhoto + 1 
		rs0.MoveNext
	wend
	rs0.Close

	for i = cptPhoto + 1 to MaxCols
		Response.Write "<td width=100><img src=/Image/pix.gif height=100 width=100></td>"
	next
	Response.Write "</tr>"

	PrintAllPictures
	Response.Write "</table>"
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->

<%
end if

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
	rs0.Close
end sub

sub PrintPageCounter
	Response.Write "<tr><td colspan=" & maxCols & " align=center>."
	for i = 1 to uBound(strDateTag)
		if intPage <= Ubound(strDateTag) then
			Response.Write "<a href=lstPhotos.asp?start=" & (i-1)*kCol*kRow & _
						   " alt=""" & strDateTag(i) & """ " & _
						   " title=""" & strDateTag(i) & """ " & _
						   ">" & i & "</a>."
		else
			Response.Write "<a href=lstPhotos.asp?start=" & (i-1)*kCol*kRow & _
						   ">" & i & "</a>."
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

	Response.Write "<tr><td colspan=" & maxCols & " align=center>"
	while not rs0.EOF
		Response.Write "<a href=""lstPhotosAll.asp?folder=" & rs0("Folder") & """>" & replace(rs0("Folder"), " ", "&nbsp;") & "</a>"
		rs0.MoveNext
		if not rs0.EOF then Response.Write " | "
	wend
	Response.Write "</td></tr>"
	rs0.Close
end sub

sub PrintAllPictures()
	Response.Write "<tr><td colspan=" & maxCols & " align=center>"
	Response.Write "<a href=lstPhotosAll.asp>" & strPicturesAll & "</a> | "
	Response.Write "<a href=lstPhotosAll.asp?tri=last>" & strLastIn & "</a>"
	Response.Write "</td></tr>"
end sub

%>

<!--#include VIRTUAL="/Include/DAOFooter.asp"-->

