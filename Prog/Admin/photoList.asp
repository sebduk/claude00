<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
if Session(strUpload & "IsAdmin") = true then
	dim strTN, strMyPix, arrPix(), arrSort(), i, j
	redim arrPix(6,0)

	if Request("SF") = "home" then
		Session("SF") = empty
	elseif Request("SF") <> empty then
		Session("SF") = Request("SF")
	end if

	ShowHeader
	FoldList
end if
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->
<!--#include VIRTUAL="/Include/DAOFooter.asp"-->

<%
function MyTN(strPixName)

	dim strWork, pos

	if Session("SF") <> empty then
		strWork = strReverse(Session("SF") & "/" & strPixName)
	else
		strWork = strReverse(strPixName)
	end if
	pos = inStr(strWork, ".")

	if pos > 0 then
		strWork = left(strWork, pos) & "nt" & mid(strWork, pos)
		MyTN = strReverse(strWork)
	else
		MyTN = strReverse(strWork) & ".tn"
	end if
end function


sub ShowHeader()
	Response.Write "<b><a href=photoUpload.asp target=right>Add a Picture</a></b><br>"
	Response.Write "<b><a href=photoFolderNew.asp target=right>Add a Folder</a></b><br>"
	Response.Write "<b><a href=photoFolderMan.asp target=right>Manage Folders</a></b><br>"
	Response.Write "<a href=photoHelp.asp target=right>Online Help</a><br><br>"

	if Request("ViewPix") <> empty then Session("ViewPix") = Request("ViewPix")
	if Session("ViewPix") = "On" then
		Response.Write "<a href=photoList.asp?ViewPix=Off>Hide Pictures</a><br><br>"
	else
		Response.Write "<a href=photoList.asp?ViewPix=On>View Pictures</a><br><br>"
	end if

	Response.Write "<b>Sort by:</b><br>"
	if Request("c") = 1 then
		if Request("d") = "a" then
			Response.Write "<a href=photoList.asp?c=1&t=a&d=d>File Name &gt;</a><br>"
		else
			Response.Write "<a href=photoList.asp?c=1&t=a&d=a>File Name &lt;</a><br>"
		end if
	else
		Response.Write "<a href=photoList.asp?c=1&t=a&d=a>File Name</a><br>"
	end if

	if Request("c") = 3 then
		if Request("d") = "a" then
			Response.Write "<a href=photoList.asp?c=3&t=n&d=d>File Size &gt;</a><br>"
		else
			Response.Write "<a href=photoList.asp?c=3&t=n&d=a>File Size &lt;</a><br>"
		end if
	else
		Response.Write "<a href=photoList.asp?c=3&t=n&d=a>File Size</a><br>"
	end if

	if Request("c") = 4 then
		if Request("d") = "a" then
			Response.Write "<a href=photoList.asp?c=4&t=n&d=d>File Date &gt;</a><br>"
		else
			Response.Write "<a href=photoList.asp?c=4&t=n&d=a>File Date &lt;</a><br>"
		end if
	else
		Response.Write "<a href=photoList.asp?c=4&t=n&d=a>File Date</a><br>"
	end if

	if Request("c") = 6 then
		if Request("d") = "a" then
			Response.Write "<a href=photoList.asp?c=6&t=n&d=d>Event Date &gt;</a><br>"
		else
			Response.Write "<a href=photoList.asp?c=6&t=n&d=a>Event Date &lt;</a><br>"
		end if
	else
		Response.Write "<a href=photoList.asp?c=6&t=n&d=a>Event Date</a><br>"
	end if

	Response.Write "<br>"
end sub


sub FoldList
	Dim fso, fsoFolder, fsoItem, fsoSubFolders, fsoFiles, strID, strTN, strExt
	Set fso = CreateObject("Scripting.FileSystemObject")
	Set fsoFolder = fso.GetFolder(server.mappath(strImage))
	Set fsoSubFolders = fsoFolder.SubFolders

	if Session("SF") = empty then
		Response.Write "<a href=photoList.asp?SF=home><b>Home</b></a><br>"
		PixFillTable arrPix
		PixSortTable arrPix, arrSort
		PixList arrPix, arrSort
	else
		Response.Write "<a href=photoList.asp?SF=home><b>Home</b></a><br>"
	end if

	for each fsoItem in fsoSubFolders
		if left(fsoItem.name, 1) <> "_" then
			if Session("SF") = fsoItem.name then
				Response.Write "&nbsp;<a href=""photoList.asp?SF=" & fsoItem.name & """><b>" & _
							   fsoItem.name & "</b></a><br>"
				PixFillTable arrPix
				PixSortTable arrPix, arrSort
				PixList arrPix, arrSort
			else
				Response.Write "&nbsp;<a href=""photoList.asp?SF=" & fsoItem.name & """><b>" & _
							   fsoItem.name & "</b></a><br>"
			end if
		end if
	next

	Set fsoFolder = nothing
	Set fsoSubFolders = nothing
	Set fso = nothing
end sub


sub PixFillTable(arrPix)

	Dim fso, fsoFolder, fsoItem, fsoSubFolders, fsoFiles, strID, strTN, strExt
	Dim strFolder, strSQL1, strSQL2

	if Session("SF") <> empty then
		strFolder = strImage & Session("SF") & "/"
		strSQL1 = "SELECT IDPhoto, [Date] FROM Photo WHERE NomPhoto='" & Session("SF") & "/"
		strSQL2 = "SELECT IDPhoto, NomPhoto, [Date] FROM Photo " & _
				  "WHERE (Right(NomPhoto, 4) = '.jpg' OR Right(NomPhoto, 4) = '.gif') AND " & _
				  "NomPhoto LIKE '" & Session("SF") & "/%' AND "
	else
		strFolder = strImage
		strSQL1 = "SELECT IDPhoto, [Date] FROM Photo WHERE NomPhoto='"
		strSQL2 = "SELECT IDPhoto, NomPhoto, [Date] FROM Photo " & _
				  "WHERE (Right(NomPhoto, 4) = '.jpg' OR Right(NomPhoto, 4) = '.gif') AND " & _
				  "NomPhoto NOT LIKE '%/%' AND "
	end if

	Set fso = CreateObject("Scripting.FileSystemObject")
	Set fsoFolder = fso.GetFolder(server.mappath(strFolder))
	Set fsoFiles = fsoFolder.Files

	if Request("Del") <> empty then strTN = MyTN(Request("Del"))

	for each fsoItem in fsoFiles
		if Ucase(fsoItem.name) = Ucase(Request("Del")) or _
		   Ucase(fsoItem.name) = Ucase(strTN) then
			fsoItem.delete
		else
			strExt = lcase(right(fsoItem.name, 4))
			if instr(fsoItem.name, ".tn.") = 0 and instr(fsoItem.name, ".lg.") = 0 and _
			   (strExt = ".jpg" or strExt = ".gif") then
				redim preserve arrPix(6, UBound(arrPix, 2) + 1)
				arrPix(0, UBound(arrPix, 2)) = arrPix(0, UBound(arrPix, 2) - 1) + 1
				arrPix(1, UBound(arrPix, 2)) = fsoItem.name
'				Response.Write strImage & MyTN(fsoItem.name) & "<br>"
				if fso.FileExists(server.mappath(strImage & MyTN(fsoItem.name))) then arrPix(2, UBound(arrPix, 2)) =  "TN"
				arrPix(3, UBound(arrPix, 2)) = fsoItem.size
				arrPix(4, UBound(arrPix, 2)) = cdbl(fsoItem.DateLastModified)

				strSQL = strSQL1 & replace(fsoItem.name, "'", "''") & "';"
'				Response.Write strSQL & "<br>"
				rs0.Open strSQL, conConnexion
				if not rs0.eof then
					arrPix(5, UBound(arrPix, 2)) = rs0("IDPhoto")
					arrPix(6, UBound(arrPix, 2)) = rs0("Date")
					strID = strID & rs0("IDPhoto") & ","
				end if
				rs0.close
			end if
		end if
	next

	Set fsoFolder = nothing
	Set fsoFiles = nothing
	Set fso = nothing

	strSQL = strSQL2 & "IDPhoto NOT IN (" & strID & "0);"
'Response.Write strSQL & "<br>"
	rs0.Open strSQL, conConnexion
	while not rs0.eof
		redim preserve arrPix(6, UBound(arrPix, 2) + 1)
		arrPix(0, UBound(arrPix, 2)) = arrPix(0, UBound(arrPix, 2) - 1) + 1
		arrPix(1, UBound(arrPix, 2)) = rs0("NomPhoto")
		arrPix(5, UBound(arrPix, 2)) = rs0("IDPhoto")
		arrPix(6, UBound(arrPix, 2)) = rs0("Date")
		rs0.MoveNext
	wend
	rs0.close
end sub


sub PixSortTable(arrPix, arrSort)
	dim flagPerm, intMax, strSortType, strSortDir, strSortCol, intTemp
	intMax = UBound(arrPix, 2)
	redim arrSort(intMax)

	for i = 0 to intMax
		arrSort(i) = arrPix(0, i)
	next

	strSortCol = 0
	strSortType = "n"
	strSortDir = "a"
	if Request("c") <> empty then strSortCol = Request("c")
	if Request("t") <> empty then strSortType = Request("t")
	if Request("d") <> empty then strSortDir = Request("d")

	flagPerm = true
	while flagPerm
		flagPerm = false
		for i = 1 to intMax - 1
			if strSortType = "n" then
				if strSortDir = "a" then
					if arrPix(strSortCol, arrSort(i)) > arrPix(strSortCol, arrSort(i + 1)) then
						intTemp = arrSort(i)
						arrSort(i) = arrSort(i + 1)
						arrSort(i + 1) = intTemp
						flagPerm = true
					end if
				else
					if arrPix(strSortCol, arrSort(i)) < arrPix(strSortCol, arrSort(i + 1)) then
						intTemp = arrSort(i)
						arrSort(i) = arrSort(i + 1)
						arrSort(i + 1) = intTemp
						flagPerm = true
					end if
				end if
			else
				if strSortDir = "a" then
					if UCase(arrPix(strSortCol, arrSort(i))) > UCase(arrPix(strSortCol, arrSort(i + 1))) then
						intTemp = arrSort(i)
						arrSort(i) = arrSort(i + 1)
						arrSort(i + 1) = intTemp
						flagPerm = true
					end if
				else
					if UCase(arrPix(strSortCol, arrSort(i))) < UCase(arrPix(strSortCol, arrSort(i + 1))) then
						intTemp = arrSort(i)
						arrSort(i) = arrSort(i + 1)
						arrSort(i + 1) = intTemp
						flagPerm = true
					end if
				end if
			end if
		next
	wend
end sub


sub PixList(arrPix, arrSort)
	if Session("ViewPix") = "On" then Response.Write "<table border=0><tr><td align=center>"

	for i = 1 to UBound(arrSort)
		if arrPix(5, arrSort(i)) <> empty then
			Response.Write "&nbsp;&nbsp;<a href=""photoPage.asp?IDPhoto=" & arrPix(5, arrSort(i)) & """ target=right>"
		else
			Response.Write "&nbsp;&nbsp;<a href=""photoPage.asp?PhotoDetails=" & arrPix(1, arrSort(i)) & """ target=right>"
		end if

		if Session("ViewPix") = "On" and arrPix(2, arrSort(i)) = "TN" and arrPix(3, arrSort(i)) <> empty then
			Response.Write "<img src=""" & strImage & MyTN(arrPix(1, arrSort(i))) & """ border=0>"
		else
			Response.Write arrPix(1, arrSort(i))
		end if
		Response.Write "</a>"
		if arrPix(3, arrSort(i)) = empty then Response.Write " <b>Out</b>"
		if arrPix(5, arrSort(i)) = empty then Response.Write " <a href=""photoList.asp?Del=" & arrPix(1, arrSort(i)) & """><b>Del</b></a>"
		Response.Write "<br>"
	next
	Response.Write "<br>"

	if Session("ViewPix") = "On" then Response.Write "</td></tr></table>"
end sub

%>
