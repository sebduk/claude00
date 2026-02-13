<!--#include VIRTUAL=/Include/CodeHeader.asp-->
<%
strConn = "PROVIDER=Microsoft.Jet.OLEDB.4.0;DATA SOURCE=" & server.mappath("/Data/user.mdb") & ";"
%>
<!--#include VIRTUAL=/Include/DAOHeader.asp-->
<%
dim strCurr, strNext


if Request("Language") <> empty then Session("Language") = Request("Language")
if Session("Language") =  empty then Session("Language") = "ENG"

Response.Write "<html>"
Response.Write "<head>"
Response.Write "<title>www.see-our-family.com</title>"
Response.Write "<link rel=stylesheet type=text/css href=/style.css>"

Response.Write "<style>"

Response.Write "</style>"

Response.Write "</head>"

Response.Write "<body topmargin=0 leftmargin=0 rightmargin=0 bottommargin=0>"

if request("Key") <> empty then

	Response.Write "<table height=100% border=0 cellpadding=0 cellspacing=0>"
	Response.Write "<tr valign=top><td bgcolor=#669900 width=100>"

	Response.Write "<div style={white-space:nowrap;overflow:hidden;color:#ffffff;}>" & _
				   "<a href=frame.asp?Language=ENG style={color:#ffffff;}>en</a>|" & _
				   "<a href=frame.asp?Language=FRA style={color:#ffffff;}>fr</a>" & _
				   "</div><br>"
'				   "<a href=frame.asp?Language=ENG style={color:#ffffff;}>es</a>|" & _
'				   "<a href=frame.asp?Language=ENG style={color:#ffffff;}>it</a>|" & _
'				   "<a href=frame.asp?Language=ENG style={color:#ffffff;}>po</a>|" & _
'				   "<a href=frame.asp?Language=ENG style={color:#ffffff;}>de</a>|" & _
'				   "<a href=frame.asp?Language=ENG style={color:#ffffff;}>nl</a>" & _

	strSQL = "SELECT * FROM [Help] " & _
			 "WHERE HelpIsOnline AND HelpLanguage='" & Session("Language") & "' AND " & _
			 "NOT HelpTitle IS NULL " & _
			 "ORDER BY HelpSortKey;"
	rs0.Open strSQL, conConnexion, 2, 3

	while not rs0.EOF

		strCurr = rs0("HelpSortKey")
		rs0.MoveNext
		if rs0.EOF then
			strNext = ""
		else
			strNext = rs0("HelpSortKey")
		end if
		rs0.MovePrevious
			
		if rs0("HelpBody") <> empty or rs0("HelpImage") <> empty then
			Response.Write "<div style={white-space:nowrap;overflow:hidden;}>" & _
						   PresentLevels(strCurr, strNext) & _
						   "<a href=frame.asp?Key=" & rs0("HelpSortKey") & " style={color:#ffffff;}>" & _
						   server.HTMLEncode(rs0("HelpTitle")) & "</a></div>"
		else
			Response.Write "<div style={white-space:nowrap;overflow:hidden;color:#ffffff;}>" & _
						   PresentLevels(strCurr, strNext) & _
						   server.HTMLEncode(rs0("HelpTitle")) & "</div>"
		end if
		rs0.MoveNext
	wend

	Response.Write "<br><div style={white-space:nowrap;overflow:hidden;}>" & _
				   "<a href=frame.asp style={color:#ffffff;}>" & _
				   "Menu Only</a></div>"
	Response.Write "<div style={white-space:nowrap;overflow:hidden;}>" & _
				   "<a href=javascript:window.close(); style={color:#ffffff;}>" & _
				   "Close window</a></div>"

	rs0.Close

	Response.Write "</td><td bgcolor=#669900>&nbsp;</td><td>&nbsp;</td><td width=300>"

	strSQL = "SELECT * FROM [Help] " & _
			 "WHERE HelpIsOnline AND HelpSortKey LIKE '" & request("Key") & "%' " & _
			 "AND HelpLanguage='" & Session("Language") & "' " & _
			 "ORDER BY HelpSortKey"
	rs0.Open strSQL, conConnexion	', 2, 3

	while not rs0.EOF
		if rs0("HelpTitle") <> "" then
			Response.Write "<b>" & server.HTMLEncode(rs0("HelpTitle")) & "</b><br>"
		end if
		if rs0("HelpImage") <> "" then
			Response.Write "<img src=/Image/Help/" & rs0("HelpImage") & " border=1><br>"
		end if
		if rs0("HelpBody") <> "" then
			Response.Write Replace(server.HTMLEncode(rs0("HelpBody")), VbCrlf, "<br>") & "<br>"
'			Response.Write Replace(rs0("HelpBody"), VbCrlf, "<br>") & "<br>"
		end if
		Response.Write "<hr size=1 noshade><br>"
		rs0.MoveNext
	wend

	rs0.Close

	Response.Write "</td><td>&nbsp;</td></tr>"
	Response.Write "</table>"
else
	Response.Write "<table width=100% height=100% border=0 cellpadding=0 cellspacing=0>"
	Response.Write "<tr valign=top><td bgcolor=#669900>"

	Response.Write "<div style={white-space:nowrap;overflow:hidden;color:#ffffff;}>" & _
				   "<a href=frame.asp?Language=ENG style={color:#ffffff;}>en</a>|" & _
				   "<a href=frame.asp?Language=FRA style={color:#ffffff;}>fr</a>" & _
				   "</div><br>"
'				   "<a href=frame.asp?Language=ENG style={color:#ffffff;}>es</a>|" & _
'				   "<a href=frame.asp?Language=ENG style={color:#ffffff;}>it</a>|" & _
'				   "<a href=frame.asp?Language=ENG style={color:#ffffff;}>po</a>|" & _
'				   "<a href=frame.asp?Language=ENG style={color:#ffffff;}>de</a>|" & _
'				   "<a href=frame.asp?Language=ENG style={color:#ffffff;}>nl</a>" & _

	strSQL = "SELECT * FROM [Help] " & _
			 "WHERE HelpIsOnline AND HelpLanguage='" & Session("Language") & "' AND " & _
			 "NOT HelpTitle IS NULL " & _
			 "ORDER BY HelpSortKey;"
	'Response.Write strSQL & "<br>"
	rs0.Open strSQL, conConnexion, 2, 3

	while not rs0.EOF

		strCurr = rs0("HelpSortKey")
		rs0.MoveNext
		if rs0.EOF then
			strNext = ""
		else
			strNext = rs0("HelpSortKey")
		end if
		rs0.MovePrevious
			
		if rs0("HelpBody") <> empty or rs0("HelpImage") <> empty then
			Response.Write "<div style={white-space:nowrap; overflow:hidden;}>" & _
						   PresentLevels(strCurr, strNext) & _
						   "<a href=frame.asp?Key=" & rs0("HelpSortKey") & " style={color:#ffffff;}>" & _
						   server.HTMLEncode(rs0("HelpTitle")) & "</a></div>"
		else
			Response.Write "<div style={white-space:nowrap; overflow:hidden;color:#ffffff;}>" & _
						   PresentLevels(strCurr, strNext) & _
						   server.HTMLEncode(rs0("HelpTitle")) & "</div>"
		end if
		rs0.MoveNext
	wend

	rs0.Close

	Response.Write "<br><div style={white-space:nowrap;overflow:hidden;}>" & _
				   "<a href=javascript:window.close(); style={color:#ffffff;}>" & _
				   "Close window</a></div>"

	Response.Write "</td></tr>"
	Response.Write "</table>"
end if

Response.Write "</body>"
Response.Write "</html>"
%>
<!--#include VIRTUAL="/Include/DAOFooter.asp"-->
<%
function PresentLevels(strCurrSortKey, strNextSortKey)
	dim strFolder, intCurrKeyLength, intNextKeyLength, i, strWork
	strFolder = "/Image/Icon/"

	if strCurrSortKey <> empty then
		intCurrKeyLength = Len(strCurrSortKey) / 2
		intNextKeyLength = Len(strNextSortKey) / 2
	
		for i = 2 to intCurrKeyLength - 1
			if mid(strCurrSortKey, i * 2 - 1, 2)="zz" then
				strWork = strWork & "<img src=" & strFolder & _
							"offsetBlk.gif border=0 align=absmiddle>"
			else
				strWork = strWork & "<img src=" & strFolder & _
							"offsetMid.gif border=0 align=absmiddle>"
			end if
		next

		if intCurrKeyLength > 1 then
			if left(strCurrSortKey, intCurrKeyLength - 1) = left(strNextSortKey, intCurrKeyLength - 1) then
				if right(strCurrSortKey, 2)="zz" then
					strWork = strWork & "<img src=" & strFolder & _
								"offsetBot.gif border=0 align=absmiddle>"
				else
					strWork = strWork & "<img src=" & strFolder & _
								"offset.gif border=0 align=absmiddle>"
				end if
			else
				strWork = strWork & "<img src=" & strFolder & _
							"offsetBot.gif border=0 align=absmiddle>"
			end if
		end if

	end if

	PresentLevels = strWork
end function
%>