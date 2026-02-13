<%
Response.Buffer = true
Response.ContentType = "text/xml"
Response.Write "<?xml version=""1.0"" encoding=""ISO-8859-1""?>"

strMyPubDate = CalcPubDate()

LoadSites strSites, strURLs, strDBs, strPacks, strUsers
LoadDBs   strDBs, strLastDates, strPrintDates, strTopDate
PrintRssHeader strTopDate
ShowItems strSites, strURLs, strDBs, strPacks, strUsers, strLastDates, strPrintDates
PrintRssFooter

'Response.Write strSites & "<br><br>"
'Response.Write strURLs & "<br><br>"
'Response.Write strDBs & "<br><br>"
'Response.Write strPacks & "<br><br>"
'Response.Write strUsers & "<br><br>"
'Response.Write strLastDates & "<br><br>"
'Response.Write strPrintDates & "<br><br>"
'Response.Write strTopDate & "<br><br>"




Sub PrintRssHeader(strTopDate)
'	Response.Write  "<rss version=""2.0"">" & VbCrlf & _
'					"<channel>" & VbCrlf & _
'					"<title>See Our Family [" & strTopDate & "]</title>" & VbCrlf & _
'					"<link>http://www.see-our-family.com</link>" & VbCrlf & _
'					"<description>See Our Family sites</description>" & VbCrlf
	Response.Write  "<rss version=""2.0"">" & VbCrlf & _
					"<channel>" & VbCrlf & _
					"<title>See Our Family</title>" & VbCrlf & _
					"<link>http://www.see-our-family.fr</link>" & VbCrlf & _
					"<description>See Our Family sites</description>" & VbCrlf
End Sub

Sub PrintRssFooter()
	Response.Write  "</channel>" & _
					"</rss>"
End Sub

Sub LoadSites(strSites, strURLs, strDBs, strPacks, strUsers)
	strConn = "PROVIDER=Microsoft.Jet.OLEDB.4.0;DATA SOURCE=" & server.mappath("/Data/user.mdb") & ";"
	Set con = Server.CreateObject("ADODB.Connection")
	con.Open strConn
	Set rs = Server.CreateObject("ADODB.Recordset")

	strSQL = "SELECT DomainName, DomainURL, DomainDB, DomainPackage, [User].IDUser, UserName, Status " & _
			 "FROM ([Domain] INNER JOIN LkDomainUser ON [Domain].IDDomain = LkDomainUser.IdDomain) INNER JOIN [User] ON LkDomainUser.IdUser = [User].IDUser " & _
			 "WHERE DomainIsOnline=True AND UserIsOnline=True AND Status<>'Guest' " & _
			 "ORDER BY [Domain].IDDomain, Status='Owner', [User].IDUser;"
	rs.Open strSQL, con

	strLastDomainDB = ""
	while not rs.EOF
		if strLastDomainDB <> rs("DomainDB") then
			strSites = strSites & "|" & rs("DomainName")
			strURLs  = strURLs  & "|" & rs("DomainURL")
			strDBs   = strDBs   & "|" & rs("DomainDB")
			strPacks = strPacks & "|" & rs("DomainPackage")
			strUsers = strUsers & "|"
			strLastDomainDB = rs("DomainDB")
		end if
		strUsers = strUsers & rs("IDUser") & "-" & replace(rs("UserName"), " ", "") & " "	'"-"  & lcase(left(rs("Status"), 1)) & " "
		rs.MoveNext
	wend


	rs.Close
	con.Close
	Set rs = Nothing 
	Set con = Nothing
End Sub

Sub LoadDBs(strDBs, strLastDates, strPrintDates, strTopDate)
	arrDBs   = Split(strDBs  , "|") 

	strTodo = "Personne Photo"
	arrTodo = Split(strTodo)
	dtTop  = 0

	for i = 1 to uBound(arrDBs)
		strConn = "PROVIDER=Microsoft.Jet.OLEDB.4.0;DATA SOURCE=" & server.mappath("/Gene/Data/" & arrDBs(i)) & ";"
		Set con = Server.CreateObject("ADODB.Connection")
		con.Open strConn
		Set rs = Server.CreateObject("ADODB.Recordset")

		strDates = ""
		dtLast = 0
		for j = 0 to ubound(arrTodo)
			strSQL =   "SELECT Top 1 LastUpdateWhen, LastUpdateWho " & _
						"FROM " & arrTodo(j) & " " & _
						"ORDER BY LastUpdateWhen DESC;"
			rs.Open strSQL, con
			if not rs.EOF then 
				if rs(0) <> empty then
					dtDate = cdate(left(rs(0), inStr(rs(0), " ") - 1))
					if dtDate > dtLast then dtLast = dtDate
					if dtLast > dtTop then dtTop = dtLast
				else
					dtDate = null
				end if
				
				strDates = strDates & rs(1) & ":" & left(arrTodo(j), 3) & "&gt;" & dtDate & " "
			end if
			rs.Close
		next

		con.Close
		Set rs = Nothing 
		Set con = Nothing

		strLastDates = strLastDates & "|" & dtLast
		'strPDates = left(strPDates, len(strPDates) - 1)
		strPrintDates = strPrintDates & "|" & strDates
	next
	strTopDate = dtTop
End Sub

Sub ShowItems(strSites, strURLs, strDBs, strPacks, strUsers, strLastDates, strPrintDates)
	arrSites      = Split(strSites     , "|") 
	arrURLs       = Split(strURLs      , "|") 
	arrDBs        = Split(strDBs       , "|") 
	arrPacks      = Split(strPacks     , "|") 
	arrUsers      = Split(strUsers     , "|") 
	arrLastDates  = Split(strLastDates , "|") 
	arrPrintDates = Split(strPrintDates, "|") 

	dim arrSort()
	redim arrSort(ubound(arrLastDates))
	for i = 0 to ubound(arrLastDates)
		arrSort(i) = i
	next
	
	flag = true
	while flag
		flag = false
		for i = 2 to ubound(arrSort)
			if cdate(arrLastDates(arrSort(i - 1))) < cdate(arrLastDates(arrSort(i))) then
				intTemp = arrSort(i)
				arrSort(i) = arrSort(i - 1)
				arrSort(i - 1) = intTemp
				flag = true
			end if
		next
	wend

	for i = 1 to Ubound(arrSort)
		PrintItem arrSites(arrSort(i)), arrPacks(arrSort(i)), _
				  arrURLs(arrSort(i)), arrLastDates(arrSort(i)), _
				  arrPrintDates(arrSort(i)) & " " & arrUsers(arrSort(i))
	next
End Sub

Sub PrintItem(strDomName, strDomPack, strDomURL, dtLast, strDesc)
	Response.Write  "<item>" & _
					"<title>" & strDomName & " [" & dtLast & "]</title>"
	if strDomPack = "Platinum" then
		Response.Write "<link>http://" & strDomURL & "</link>"
	else
		Response.Write "<link>http://www.see-our-family.fr</link>"
	end if
	Response.Write "<description>" & strDesc & "</description>" & _
				   "<pubDate>" & strMyPubDate & "</pubDate>" & _
				   "</item>"
End Sub


Function ApplyXMLFormatting(strInput)
  strInput = Replace(strInput,"&", "&amp;")
  strInput = Replace(strInput,"'", "'")
  strInput = Replace(strInput,"""", "&quot;")
  strInput = Replace(strInput, ">", "&gt;")
  strInput = Replace(strInput,"<","&lt;")
  
  ApplyXMLFormatting = strInput
End Function   

Function CalcPubDate()
	strWork = Replace(FormatDateTime(Now() - 2/24, VBLongDate), ",", "")
	arrWork = Split(strWork)
	strWork = Left(arrWork(0), 3) & ", " & _
				   arrWork(2) & " " & _
				   Left(arrWork(1), 3) & " " & _
				   arrWork(3) & " " & _
				   FormatDateTime(Now() - 2/24, VBShortTime) & ":00 GMT"
	CalcPubDate = strWork
End Function
%>