<%
		Response.Write "</wml>" & VbCrlf
	else
		Response.Redirect "/Wap/default.asp"
	end if
else
	Response.Redirect "/Wap/default.asp"
end if

Function WapEncode(strWork)

	if strWork <> empty then
		strWork = Replace(strWork, "&", "&amp;")
		strWork = Replace(strWork, "'", "&apos;")
		strWork = Replace(strWork, ">", "&gt;")
		strWork = Replace(strWork, "<", "&lt;")
		strWork = Replace(strWork, """", "&quot;")
		strWork = Replace(strWork, "-", "&shy;")
		strWork = Replace(strWork, VbCrlf, "<br/>")
		WapEncode = strWork
	else
		WapEncode = ""
	end if

End Function

Sub ExtractParams(strWork)

	pos1 = inStr(strWork, "=")
	pos2 = inStr(strWork, ";")
	while pos2 > 0
		if pos1 > 1 then Session(left(strWork, pos1 - 1)) = mid(strWork, pos1 + 1, pos2 - pos1 - 1)
		strWork = mid(strWork, pos2 + 1)
		pos1 = inStr(strWork, "=")
		pos2 = inStr(strWork, ";")
	wend
	pos1 = inStr(strWork, "=")

	if pos1 > 1 then Session(left(strWork, pos1 - 1)) = mid(strWork, pos1 + 1)

End Sub
%>
