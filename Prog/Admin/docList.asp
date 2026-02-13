<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
if Session(strUpload & "IsAdmin") = true then
	if Request("ViewPix") <> empty then Session("ViewPix") = Request("ViewPix")

	dim strTN, strMyPix, arrSort(), i, j

	Response.Write "<b>Documents</b><br><br>"

	Response.Write "<b><a href=docUpload.asp target=right>Add a Document</a></b><br>"
	Response.Write "<a href=docHelp.asp target=right>Online Help</a><br><br>"

	Response.Write "Sort by:<br>"
	if Request("c") = 1 and Request("d") = "a" then
		Response.Write "<a href=docList.asp?c=1&t=a&d=d>File Name &lt;</a><br>"
	else
		Response.Write "<a href=docList.asp?c=1&t=a&d=a>File Name &gt;</a><br>"
	end if
	if Request("c") = 2 and Request("d") = "a" then
		Response.Write "<a href=docList.asp?c=2&t=n&d=d>File Type &lt;</a><br>"
	else
		Response.Write "<a href=docList.asp?c=2&t=n&d=a>File Type &gt;</a><br>"
	end if
	if Request("c") = 3 and Request("d") = "a" then
		Response.Write "<a href=docList.asp?c=3&t=n&d=d>File Size &lt;</a><br>"
	else
		Response.Write "<a href=docList.asp?c=3&t=n&d=a>File Size &gt;</a><br>"
	end if
	if Request("c") = 4 and Request("d") = "a" then
		Response.Write "<a href=docList.asp?c=4&t=n&d=d>File Date &lt;</a><br>"
	else
		Response.Write "<a href=docList.asp?c=4&t=n&d=a>File Date &gt;</a><br>"
	end if
	if Request("c") = 6 and Request("d") = "a" then
		Response.Write "<a href=docList.asp?c=6&t=n&d=d>Event Date &lt;</a><br>"
	else
		Response.Write "<a href=docList.asp?c=6&t=n&d=a>Event Date &gt;</a><br>"
	end if

	Response.Write "<br>"


	FillTable arrPix
	SortTable arrPix, arrSort

	dim strExt', j
	for i = 1 to UBound(arrSort)
		strExt = right(arrPix(1, arrSort(i)), 3)
		select case strExt
			case "doc", "mdb", "pdf", "ppt", "pps", "txt", "xls", "zip"
				Response.Write "<img src=/Image/Icon/" & strExt & ".gif align=absbottom> "
			case else
				Response.Write "<img src=/Image/Icon/other.gif align=absbottom> "
		end select
		if arrPix(5, arrSort(i)) <> empty then
			Response.Write "<a href=""docPage.asp?IDPhoto=" & arrPix(5, arrSort(i)) & """ target=right>"
		else
			Response.Write "<a href=""docPage.asp?docDetails=" & arrPix(1, arrSort(i)) & """ target=right>"
		end if
		Response.Write arrPix(1, arrSort(i))
		Response.Write "</a>"
		if arrPix(3, arrSort(i)) = empty then Response.Write " <b>Out</b>"
		if arrPix(5, arrSort(i)) = empty then Response.Write " <a href=""docList.asp?Del=" & arrPix(1, arrSort(i)) & """><b>Del</b></a>"
		Response.Write "<br>"

	'	for j = 1 to 6
	'		Response.Write arrPix(j, arrSort(i)) & "|"
	'	next
	'	Response.Write "<br>"
	next

	Response.Write "<br><b><a href=docUpload.asp target=right>Add a Document</a></b><br>"
	Response.Write "<a href=docHelp.asp target=right>Online Help</a>"
end if
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->
<!--#include VIRTUAL="/Include/DAOFooter.asp"-->

<%
function MyTN(strPixName)

	dim strWork, pos
	
	strWork = strReverse(strPixName)
	pos = inStr(strWork, ".")
	
	if pos > 0 then
		strWork = left(strWork, pos) & "nt" & mid(strWork, pos)
		MyTN = strReverse(strWork)
	else
		MyTN = strReverse(strWork) & ".tn"
	end if
end function




sub FillTable(arrPix)
	Dim fso, fsoFolder, fsoItem, fsoSubFolders, fsoFiles, strID, strTN, strExt
	Set fso = CreateObject("Scripting.FileSystemObject")
	Set fsoFolder = fso.GetFolder(server.mappath(strDocument))
	Set fsoFiles = fsoFolder.Files
	redim arrPix(6, 0)

	if Request("Del") <> empty then strTN = MyTN(Request("Del"))

	for each fsoItem in fsoFiles
		if Ucase(fsoItem.name) = Ucase(Request("Del")) or _
		   Ucase(fsoItem.name) = Ucase(strTN) then
			fsoItem.delete
		else
			strExt = lcase(right(fsoItem.name, 4))
			if strExt <> ".jpg" and strExt <> ".gif" then 
				redim preserve arrPix(6, UBound(arrPix, 2) + 1)
				arrPix(0, UBound(arrPix, 2)) = arrPix(0, UBound(arrPix, 2) - 1) + 1
				arrPix(1, UBound(arrPix, 2)) = fsoItem.name
				arrPix(2, UBound(arrPix, 2)) = strExt
				arrPix(3, UBound(arrPix, 2)) = fsoItem.size
				arrPix(4, UBound(arrPix, 2)) = cdbl(fsoItem.DateLastModified)
				
				strSQL = "SELECT IDPhoto, [Date] FROM Photo " & _
						 "WHERE NomPhoto=""" & fsoItem.name & """;"
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

	strSQL = "SELECT IDPhoto, NomPhoto, [Date] FROM Photo " & _
			 "WHERE Right(NomPhoto, 4) <> '.jpg' AND Right(NomPhoto, 4) <> '.gif' AND " & _
			 "IDPhoto NOT IN (" & strID & "0);"
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



sub SortTable(arrPix, arrSort)
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
%>
