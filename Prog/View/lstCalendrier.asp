<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->
<!--#include VIRTUAL="/Include/Label.asp"-->

<%
if Session(strUpload & "IsUser") <> true then
	Response.Redirect "/login.asp"
else
%>

<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
	dim intMonth(), strTab(), i, j, flgOut
	redim intMonth(12)
	redim strTab(12, 31)

	intMonth(01) = 31
	intMonth(02) = 29
	intMonth(03) = 31
	intMonth(04) = 30
	intMonth(05) = 31
	intMonth(06) = 30
	intMonth(07) = 31
	intMonth(08) = 31
	intMonth(09) = 30
	intMonth(10) = 31
	intMonth(11) = 30
	intMonth(12) = 31


	strSQL = "SELECT IDPersonne, Prenom, Nom, Day(DateNaiss) as [Day], Month(DateNaiss) as [Month], Year(DateNaiss) as [Year], DtDec, Email " & _
			 "FROM Personne " & _
			 "WHERE DateNaiss<>null " & _
			 "ORDER BY Month(DateNaiss), Day(DateNaiss), Year(DateNaiss)"
	rs0.Open strSQL, conConnexion, 2, 3

	for i = 1 to 12
		strTab(i, 0) = "<td align=center bgcolor=#cccccc width=""33%""><b>" & arrMonth(i) & "</b></td>"
		for j = 1 to intMonth(i)
			if i = Month(Now()) and j = Day(Now()) then
				strTab(i, j) = "<td bgcolor=#999999>"
			else
				strTab(i, j) = "<td>"
			end if
			if not rs0.eof then
				if rs0("Month") = i and rs0("Day") = j then
					strTab(i, j) = strTab(i, j) & "<a href=frame.asp?IDPerso=" & rs0("IDPersonne") & ">" & _
					replace(server.HTMLEncode(rs0("Nom") & " " & rs0("Prenom"))," " , "&nbsp;") & _
					"&nbsp;(" & rs0("Year") & ")</a>"
					if rs0("Email") <> empty and IsNull(rs0("DtDec")) then _
						strTab(i, j) = strTab(i, j) & _
						" <a href=message.asp?IDForum=perso&IDPerso=" & _
						rs0("IDPersonne") & "><b>&#64;</b></a>"
					rs0.MoveNext

					flgOut=false
					while not rs0.eof and not flgOut
						if rs0("Month") = i and rs0("Day") = j then
							strTab(i, j) = strTab(i, j) & "<br><a href=frame.asp?IDPerso=" & rs0("IDPersonne") & ">" & _
							replace(server.HTMLEncode(rs0("Nom") & " " & rs0("Prenom"))," " , "&nbsp;") & _
							"&nbsp;(" & rs0("Year") & ")</a>"
							if rs0("Email") <> empty and IsNull(rs0("DtDec")) then _
								strTab(i, j) = strTab(i, j) & _
								" <a href=message.asp?IDForum=perso&IDPerso=" & _
								rs0("IDPersonne") & "><b>&#64;</b></a>"
							rs0.MoveNext
						else
							flgOut= true
						end if
					wend
				else
					strTab(i, j) = strTab(i, j) & "&nbsp;"
				end if  
			else
				strTab(i, j) = strTab(i, j) & "&nbsp;"
			end if  
			strTab(i, j) = strTab(i, j) & "</td>"
		next
	next



	Response.Write "<table cellpadding=0 cellspacing=0 border=1 align=center width=""70%"">"
	for i = 1 to 12 step 3 
		for j = 0 to 31
			Response.Write "<tr valign=top>"
			if j <> 0 then
				Response.Write "<td align=right bgcolor=#cccccc>" & j & "</td>"

				if strTab(i, j)<>"" then
					Response.Write strTab(i, j) 
				else
					Response.Write "<td>&nbsp;</td>" 
				end if

				if strTab(i + 1, j)<>"" then
					Response.Write strTab(i + 1, j) 
				else
					Response.Write "<td>&nbsp;</td>" 
				end if

				if strTab(i + 2, j)<>"" then
					Response.Write strTab(i + 2, j) 
				else
					Response.Write "<td>&nbsp;</td>" 

				end if

				Response.Write "<td align=right bgcolor=#cccccc>" & j & "</td>"
			else
				Response.Write "<td bgcolor=#cccccc>&nbsp;</td>" & strTab(i, j) & strTab(i + 1, j) & strTab(i + 2, j) & "<td bgcolor=#cccccc>&nbsp;</td>"
			end if
			Response.Write "</tr>"
		next
	next
	Response.Write "<tr bgcolor=#cccccc><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>"
	Response.Write "</table>"

	Response.Write "<center>"
	Response.Write "[" & strCalendarWarning & "]"
	Response.Write "</center>"
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->

<%
end if
%>

<!--#include VIRTUAL="/Include/DAOFooter.asp"-->
