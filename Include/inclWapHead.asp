<%
if Request("Code") <> empty then
	Response.ContentType = "text/vnd.wap.wml"
	'Response.ContentType = "text/HTML"
	Response.Expires = 0
	strCode = Replace(Request("Code"), ";;", ";")

	pos = inStr(strCode, ";")
	if pos > 0 then
		strParam = mid(strCode, pos + 1)
		strCode = left(strCode, pos - 1)
	end if

	WapSessions = application("WapSessions")
	for i = 1 to UBound(WapSessions, 2)
		if strCode = WapSessions(1, i) then
			strID = WapSessions(2, i)
			strDomain = WapSessions(4, i)
			strTime = WapSessions(5, i)
			WapSessions(6, i) = now()
			strAgent = WapSessions(7, i)
		end if
	next
	application("WapSessions") = WapSessions

	if strID <> "" then

		ExtractParams strParam

		'Response.Write "<?xml version=""1.0"" encoding=""iso-8859-1""?>" & VbCrlf
		Response.Write "<?xml version=""1.0""?>" & VbCrlf
		Response.Write "<!DOCTYPE wml PUBLIC ""-//WAPFORUM//DTD WML 1.1//EN"" ""http://www.wapforum.org/DTD/wml_1.1.xml"">" & VbCrlf
		Response.Write "<wml>" & VbCrlf
%>