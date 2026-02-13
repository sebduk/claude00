<!--#include VIRTUAL=/Include/CodeHeader.asp-->
<%
strConn = "PROVIDER=Microsoft.Jet.OLEDB.4.0;DATA SOURCE=" & server.mappath("/Data/user.mdb") & ";"
%>
<!--#include VIRTUAL=/Include/DAOHeader.asp-->
<%
if Request("Language") <> empty then 
	Session("Language") = Request("Language")
	if Request("Language") <> "ENG" then DoAddLanguage Request("Language")
end if
if Session("Language") = empty then Session("Language") = "ENG"

dim strCurr, strNext, i

Response.Write "<html>"
Response.Write "<head>"
Response.Write "<title>www.see-our-family.com</title>"
Response.Write "<link rel=stylesheet type=text/css href=/style.css>"
Response.Write "</head>"

Response.Write "<script language=""Javascript"">"
Response.Write "function openHelp(){" & _
			   "newWindow=window.open( ""/Help/frame.asp"" , ""Help"", " & _
			   """toolbar=0,location=0,directories=0,status=0,menubar=0,scrollbars=1," & _
			   "resizable=0,copyhistory=0,width=500,height=350"");}"
Response.Write "</script>"

Response.Write "<body topmargin=0 leftmargin=0 rightmargin=0 bottommargin=0>"

Response.Write "<table height=100% width=100% border=0 cellpadding=0 cellspacing=0>"
Response.Write "<tr valign=top><td bgcolor=#669900>"

Response.Write "<div style={white-space:nowrap;color:#ffffff;}>" & _
			   "<a href=helpList.asp?Language=ENG style={color:#ffffff;}>en</a>|" & _
			   "<a href=helpList.asp?Language=FRA style={color:#ffffff;}>fr</a>|" & _
			   "<a href=helpList.asp?Language=ESP style={color:#ffffff;}>es</a>|" & _
			   "<a href=helpList.asp?Language=ITA style={color:#ffffff;}>it</a>|" & _
			   "<a href=helpList.asp?Language=POR style={color:#ffffff;}>po</a>|" & _
			   "<a href=helpList.asp?Language=DEU style={color:#ffffff;}>de</a>|" & _
			   "<a href=helpList.asp?Language=NLD style={color:#ffffff;}>nl</a>" & _
			   "</div><br>"
Response.Write "<div style={white-space:nowrap;}>" & _
			   "<a href=helpForm.asp?IDHelp=0 style={color:#ffffff;} target=form>+++Add+++</a></div>"
Response.Write "<div style={white-space:nowrap;}>" & _
			   "<a href=javascript:openHelp(); style={color:#ffffff;}>Help Window</a></div><br>"


strSQL = "SELECT * FROM [Help] " & _
		 "WHERE HelpLanguage='" & Session("Language") & "' " & _
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

	if rs0("HelpTitle") <> empty then
		Response.Write "<div style={white-space:nowrap;}>" & _
					   PresentLevels(strCurr, strNext) & _
					   "<a href=helpForm.asp?IDHelp=" & rs0("IDHelp") & " style={color:#ffffff;} target=form>" & _
					   rs0("HelpTitle") & "</a></div>"
	else
		Response.Write "<div style={white-space:nowrap;}>" & _
					   PresentLevels(strCurr, strNext) & _
					   "<a href=helpForm.asp?IDHelp=" & rs0("IDHelp") & " style={color:#ffffff;} target=form>" & _
					   "...</a></div>"
	end if
	rs0.MoveNext
wend

rs0.Close

Response.Write "<br><div style={white-space:nowrap;}>" & _
			   "<a href=helpForm.asp?IDHelp=0 style={color:#ffffff;} target=form>+++Add+++</a></div>"
Response.Write "<div style={white-space:nowrap;}>" & _
			   "<a href=javascript:openHelp(); style={color:#ffffff;}>Help Window</a></div>"

Response.Write "</td></tr>"
Response.Write "</table>"

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

sub DoAddLanguage(strLanguage)
	strSQL = "INSERT INTO Help " & _
			 "(HelpSort, HelpSortKey, IdENG, HelpLanguage, HelpTitle, HelpBody, HelpImage, HelpIsOnline) " & _
			 "SELECT HelpSort, HelpSortKey, IDHelp, '" & strLanguage & "', HelpTitle, HelpBody, HelpImage, HelpIsOnline " & _
			 "FROM Help " & _
			 "WHERE HelpLanguage='ENG' AND IDHelp NOT IN " & _
			 "(SELECT IdENG FROM Help WHERE HelpLanguage='" & strLanguage & "');"
	rs0.Open strSQL, conConnexion

	strSQL = "UPDATE " & _
			 "(Help INNER JOIN Help AS Help_1 ON Help.IdENG = Help_1.IDHelp) " & _
			 "INNER JOIN Help AS Help_2 ON Help_1.IdDad = Help_2.IdENG " & _
			 "SET Help.IdDad = [Help_2].[IDHelp] " & _
			 "WHERE Help.HelpLanguage='" & strLanguage & "' AND Help_1.HelpLanguage='ENG' " & _
			 "AND Help_2.HelpLanguage='" & strLanguage & "';"
	rs0.Open strSQL, conConnexion
end sub
%>