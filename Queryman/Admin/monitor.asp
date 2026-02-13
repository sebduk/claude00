<%@ LANGUAGE="VBSCRIPT" %>

<%
if Session("QueryOK") = "safe" then 

	strHeader = "Intranet - Monitor"

	%>
	<!-- #INCLUDE VIRTUAL="/QueryMan/Admin/inclDAOHead.asp" -->
	<!-- #INCLUDE VIRTUAL="/QueryMan/Admin/inclMenuAdmin.asp" -->
	<%

	Response.Write "<td valign=top align=center height=*><br>"


	''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''


	if Request("DEL")<>empty then
		select case Request("DEL")
'''''''''''''Online users
			case "OnlineUsersDelete"
				dim arrDel()
				redim arrDel(10, 0)
				application("arrOnlineUsers") = arrDel

'''''''''''''KeyInOut
			case "keyInOut"
				dim arrKeyInOutDel()
				redim arrKeyInOutDel(2, 0)
				Session("KeyInOut") = arrKeyInOutDel

'''''''''''''Wap users
			case "WapSessionsDelete"
				dim arrWap()
				redim arrWap(8, 0)
				application("WapSessions") = arrWap

'''''''''''''AlwaysOn Kick Out
			case "AlwaysOnKickOutEdit"
				if request("AlwaysOnKickOut") <> empty then Application("AlwaysOnKickOut") = request("AlwaysOnKickOut")
				Response.Write "<form action=monitor.asp method=post>"
				Response.Write "<input type=hidden name=DEL value=AlwaysOnKickOutEdit>"
				Response.Write "<input type=text size=50 name=AlwaysOnKickOut value=""" & Application("AlwaysOnKickOut") & """>"
				Response.Write "</form>"

			case "AlwaysOnKickOutDelete"
				application("AlwaysOnKickOut") = empty

'''''''''''''Online chat users
			case "OnlineUsersChatEdit"
				if request("OnlineUsersChat") <> empty then Application("OnlineUsersChat") = request("OnlineUsersChat")
				Response.Write "<form action=monitor.asp method=post>"
				Response.Write "<input type=hidden name=DEL value=OnlineUsersChatEdit>"
				Response.Write "<input type=text size=50 name=OnlineUsersChat value=""" & Application("OnlineUsersChat") & """>"
				Response.Write "</form>"

			case "OnlineUsersChatDelete"
				application("OnlineUsersChat") = empty

'''''''''''''Chat
			case "ChatDelete"
				Application("ShowText") = empty

'''''''''''''IP
			case "IPEdit"
				if request("BadIP") <> empty then Application("BadIP") = request("BadIP")
				Response.Write "<form action=delete.asp method=post>"
				Response.Write "<input type=hidden name=DEL value=IPEdit>"
				Response.Write "<input type=text size=50 name=BadIP value=""" & Application("BadIP") & """>"
				Response.Write "</form>"

			case "IPDelete"
				Application("BadIP") = empty

'''''''''''''Error
			case else
				Response.Write "Parameter Error"
		end select
	end if


	''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''


	arrOnlineUsers = application("arrOnlineUsers")
	Response.Write "<table border=1 cellpadding=3 cellspacing=0>"
	Response.Write "<tr>"
	Response.Write "<td colspan=4><b>Online Users</b></td>"
	Response.Write "<td colspan=2><b><a href=monitor.asp?DEL=OnlineUsersDelete>Delete</a></b></td>"
	Response.Write "<td colspan=5><b>" & Now() & "</b>&nbsp;</td>"
	Response.Write "</tr>"

	Response.Write "<tr bgcolor=#cccccc>"
	Response.Write "<td>Domain</td>"
	Response.Write "<td>ID</td>"
	Response.Write "<td>Last Login</td>"
	Response.Write "<td>Code</td>"
	Response.Write "<td>IP</td>"
	Response.Write "<td>Initials</td>"
	Response.Write "<td>Last Pass</td>"
	Response.Write "<td>&nbsp;</td>"
	Response.Write "<td>&nbsp;</td>"
	Response.Write "<td>&nbsp;</td>"
	Response.Write "<td>Rights</td>"
	Response.Write "</tr>"

	for i = 1 to UBound(arrOnlineUsers, 2)
		Response.Write "<tr>"
		if len(arrOnlineUsers(0, i)) > 10 then
			Response.Write "<td>" & left(arrOnlineUsers(0, i), 10) & "...</td>"
		else
			Response.Write "<td>" & arrOnlineUsers(0, i) & "</td>"
		end if
		Response.Write "<td>" & arrOnlineUsers(1, i) & "</td>"
		Response.Write "<td>" & arrOnlineUsers(2, i) & "</td>"
		Response.Write "<td>" & arrOnlineUsers(3, i) & "</td>"
		Response.Write "<td>" & arrOnlineUsers(4, i) & "</td>"
		dblTime = cdbl(Now() - cdate(arrOnlineUsers(6, i)) - cdate("00:01:10")) 'gone after 1 minute 10 seconds
		if dblTime > 0 then 
			Response.Write "<td>" & arrOnlineUsers(5, i) & "</td>"
			Response.Write "<td>" & arrOnlineUsers(6, i) & "&nbsp;</td>"
		else
			Response.Write "<td><b>" & arrOnlineUsers(5, i) & "</b></td>"
			Response.Write "<td><b>" & arrOnlineUsers(6, i) & "</b>&nbsp;</td>"
		end if
		Response.Write "<td>" & arrOnlineUsers(7, i) & "</td>"
		Response.Write "<td>" & arrOnlineUsers(8, i) & "</td>"
		Response.Write "<td>" & arrOnlineUsers(9, i) & "</td>"
		Response.Write "<td>" & arrOnlineUsers(10, i) & "</td>"
		Response.Write "</tr>"
	next
	Response.Write "</table>"


	Response.Write "<br>"
	Response.Write "<b>Site Up Since:</b> " & Application("SiteUpSince") & " -> " & FormatTimeSince(Now() - Application("SiteUpSince")) & "<br>"
	Response.Write "<b>Domain Group:</b> " & session("DomainGroup") & "<br>"
	Response.Write "<b>Guest Group:</b> " & session("GuestGroup") & "<br>"
	Response.Write "<b>Admin Group:</b> " & session("AdminGroup") & "<br>"
	Response.Write "<b>My Groups:</b> " & Session("Groups") & "<br>"
	Response.Write "<br>"


	Response.Write "<table border=0 cellpadding= cellspacing=0>"
	Response.Write "<tr valign=top><td>"

		Response.Write "<table border=1 cellpadding=3 cellspacing=0>"
		Response.Write "<tr><td bgcolor=#cccccc>AlwaysOnKickOut</td>"
		Response.Write "<td>" & Application("AlwaysOnKickOut") & "&nbsp;</td>"
		Response.Write "<td><a href=monitor.asp?DEL=AlwaysOnKickOutEdit>Edit</a></td>"
		Response.Write "<td><a href=monitor.asp?DEL=AlwaysOnKickOutDelete>Delete</a></td></tr>"

		Response.Write "<tr><td bgcolor=#cccccc>OnlineUsersChat</td>"
		Response.Write "<td>" & Application("OnlineUsersChat") & "&nbsp;</td>"
		Response.Write "<td><a href=monitor.asp?DEL=OnlineUsersChatEdit>Edit</a></td>"
		Response.Write "<td><a href=monitor.asp?DEL=OnlineUsersChatDelete>Delete</a></td></tr>"

		Response.Write "<tr><td bgcolor=#cccccc>Chat</td>"
		if Application("ShowText")<> empty then 
			Response.Write "<td><b>Chat</b></td>"
		else
			Response.Write "<td>&nbsp;</td>"
		end if
		Response.Write "<td><a href=javascript:openChat();>Edit</a></td>"
		Response.Write "<td><a href=monitor.asp?DEL=ChatDelete>Delete</a></td></tr>"

		Response.Write "<tr><td bgcolor=#cccccc>BadIP</td>"
		Response.Write "<td>" & Application("BadIP") & "&nbsp;</td>"
		Response.Write "<td><a href=monitor.asp?DEL=IPEdit>Edit</a></td>"
		Response.Write "<td><a href=monitor.asp?DEL=IPDelete>Delete</a></td></tr>"
		Response.Write "</table>"

	Response.Write "</td><td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td><td>"

		Response.Write "<form name=Calculator>"
		Response.Write "<b>Download time calculator</b>"
		Response.Write "<table cellpadding=0 cellspacing=0>"
		Response.Write "<tr>"
		Response.Write "<td>Size</td>"
		Response.Write "<td>"
		Response.Write "<input type=text size=5 name=FileSize value=10 class=text>"
		Response.Write "<select name=Unit class=text>"
		Response.Write "<option value=1>bytes"
		Response.Write "<option value=1024>Kb"
		Response.Write "<option value=1048567 selected>Mb"
		Response.Write "<option value=1073741824>Gb"
		Response.Write "</select>"
		Response.Write "</td>"
		Response.Write "</tr>"
 
		Response.Write "<tr>"
		Response.Write "<td>Speed&nbsp;</td>"
		Response.Write "<td>"								' 8bits per byte
		Response.Write "<select name=Speed class=text>"		' + 12.5% for TCP/IP
		Response.Write "<option value=1638>14.4K"			'   14.4 * 1024   / (8*1.125) =     1 638
		Response.Write "<option value=3277>28.8K"			'   28.8 * 1024   / (8*1.125) =     3 277
		Response.Write "<option value=6372 selected>56K"	'     56 * 1024   / (8*1.125) =     6 372
		Response.Write "<option value=14564>128K"			'    128 * 1024   / (8*1.125) =    14 564
		Response.Write "<option value=29127>256K"			'    256 * 1024   / (8*1.125) =    29 127
		Response.Write "<option value=179889>T1 (1.544M)"	'  1.544 * 1024^2 / (8*1.125) =   179 889
		Response.Write "<option value=179889>Cable (13M)"	' 13.184 * 1024^2 / (8*1.125) = 1 536 000
		Response.Write "<option value=179889>Cable (26M)"	' 26.367 * 1024^2 / (8*1.125) = 3 072 000
		Response.Write "</select>"
		Response.Write "</td>"
		Response.Write "</tr>"

		Response.Write "<tr>"
		Response.Write "<td>Time&nbsp;</td>"
		Response.Write "<td><input type=text size=15 name=Result class=text></td>"
		Response.Write "</tr>"

		Response.Write "<tr>"
		Response.Write "<td>&nbsp;</td>"
		Response.Write "<td><input type=button value=calculate onclick=javascript:Calculate(); class=text id=button1 name=button1></td>"
		Response.Write "</tr>"

		Response.Write "</table>"
		Response.Write "</form>"

	Response.Write "</td></tr>"
	Response.Write "</table>"

	Response.Write "<br>"

	WapSessions = application("WapSessions")
	Response.Write "<table border=1 cellpadding=3 cellspacing=0>"
	Response.Write "<tr>"
	Response.Write "<td colspan=4><b>Wap Users</b></td>"
	Response.Write "<td align=right><b><a href=monitor.asp?DEL=WapSessionsDelete>Delete</a></b></td>"
	Response.Write "</tr>"

	Response.Write "<tr bgcolor=#cccccc>"
	Response.Write "<td>ID</td>"
	Response.Write "<td>Code</td>"
	Response.Write "<td>Initials</td>"
	Response.Write "<td>Groups</td>"
	Response.Write "<td>Key</td>"
	Response.Write "</tr>"
	Response.Write "<tr bgcolor=#cccccc>"
	Response.Write "<td colspan=3>First</td>"
	Response.Write "<td>Last</td>"
	Response.Write "<td>Agent</td>"
	Response.Write "</tr>"

	for i = 1 to UBound(WapSessions, 2)
		Response.Write "<tr>"
		Response.Write "<td>" & WapSessions(1, i) & "</td>"
		Response.Write "<td>" & WapSessions(2, i) & "</td>"
		Response.Write "<td>" & WapSessions(3, i) & "</td>"
		Response.Write "<td>" & WapSessions(4, i) & "</td>"
		Response.Write "<td>" & WapSessions(5, i) & "</td>"
		Response.Write "</tr>"
		Response.Write "<tr>"
		Response.Write "<td colspan=3>" & WapSessions(6, i) & "</td>"
		Response.Write "<td>" & WapSessions(7, i) & "</td>"
		Response.Write "<td>" & WapSessions(8, i) & "</td>"
		Response.Write "</tr>"
	next
	Response.Write "</table>"

	Response.Write "<br><br>"


	''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''


	Response.Write "<script language=javascript>"
	Response.Write "function Calculate(){"
	Response.Write "var DLTime = Math.round(document.Calculator.FileSize.value * document.Calculator.Unit.value / document.Calculator.Speed.value);"
	Response.Write "var DLHours = Math.floor(DLTime / 3600);"
	Response.Write "var DLMinutes = Math.floor(DLTime / 60) - DLHours * 60;"
	Response.Write "var DLSeconds = DLTime - DLHours * 3600 - DLMinutes * 60;"
	Response.Write "document.Calculator.Result.value = DLHours + 'h, ' + DLMinutes + 'm, ' + DLSeconds + 's';"
	Response.Write "}"

	Response.Write "function openChat(){newWindow=window.open( ""/Intranet/chat/frame.asp"" , ""WBChat"", ""toolbar=0,location=0,directories=0,status=0,menubar=0,scrollbars=0,resizable=1,copyhistory=0,width=800,height=300"");}"
	Response.Write "</script>"

	'page footer
	'''''''''''''''''''''''''''''''
	Response.Write "</td><tr>"
	Response.Write "</table>"
	Response.Write "</body></html>"
	'''''''''''''''''''''''''''''''

	%>
	<!-- #INCLUDE VIRTUAL="/QueryMan/inclDAOFoot.asp" -->
	<%
end if


Function FormatTimeSince(lngTime)

	lngTime = int(lngTime * 24 * 3600)

	intSec = lngTime - 60 * int(lngTime/60)
	lngTime = int(lngTime/60)
	intMin = lngTime - 60 * int(lngTime/60)
	lngTime = int(lngTime/60)
	intHou = lngTime - 24 * int(lngTime/24)
	lngTime = int(lngTime/24)
	intDay = lngTime

	FormatTimeSince = intDay & "d " & intHou & "h" & " " & intMin & "'" & " " & intSec & "''"

End Function
%>
