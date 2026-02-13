<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
Dim lngIDForum, lngIDPersonne, intPos

if Request("todo") = "add" then DoAdd
if Request("todo") = "update" then DoUpdate
if Request("toggle") <> empty then DoToggle Request("toggle")
if Request("purge") <> empty then 
	DoPurge Request("purge")
	lngIDForum = Request("purge")
end if


if Request("IDForum") <> empty then lngIDForum = Request("IDForum")

if lngIDForum <> empty then
	strSQL = "SELECT * FROM Forum WHERE IDForum=" & lngIDForum
	rs0.Open strSQL, conConnexion, 2, 3
'IDForum IdDad ForumSort ForumSortKey ForumAdmin ForumTitle ForumIsOnline
	if not rs0.EOF then
		Response.Write "<form action=messPage.asp name=myForm method=post>"
		Response.Write "<input type=hidden name=IDForum value=" & rs0("IDForum") & ">"
		Response.Write "<input type=hidden name=todo value=update>"
		Response.Write "<table border=0 cellpadding=0 cellspacing=0><tr valign=top><td align=right>&nbsp;<br>"
		Response.Write "Name&nbsp;<input type=text name=ForumAdmin size=30 value=""" & rs0("ForumAdmin") & """ class=box><br>"
		Response.Write "Title&nbsp;<input type=text name=ForumTitle size=30 value=""" & rs0("ForumTitle") & """ class=box><br>"
		Response.Write "Sort&nbsp;<input type=text name=ForumSort size=3 value=""" & rs0("ForumSort") & """ class=box> "
		Response.Write "| <input type=checkbox name=ForumIsOnline value=X"
		if rs0("ForumIsOnline") = true then Response.Write " checked"
		Response.Write "> Is Online<br>"
		Response.Write "<br><input type=submit value=Update class=box>"
		Response.Write "<input type=submit name=del value=Delete class=box>"
		Response.Write "</td></tr></table>"
		Response.Write "</form>"
		Response.Write "<p><a href=messList.asp target=left>&lt;&lt;&lt; Refresh the Message Board list &lt;&lt;&lt;</a></p><br>"


		Response.Write "<table border=0 cellpadding=0 cellspacing=0>"
		Response.Write "<tr bgcolor=999999><td colspan=5><b>Messages:</b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
		Response.Write "<a href=messPage.asp?purge=" & lngIDForum & ">Purge offline messages</a>"
		Response.Write "</td></tr>"
		strSQL = "SELECT * FROM ForumItem " & _
				 "WHERE IdForum=" & lngIDForum & " " & _
				 "ORDER BY ForumItemDate DESC;"
		rs1.Open strSQL, conConnexion, 2, 3
		while not rs1.EOF
			if rs1("ForumItemIsOnline") = true then
				Response.Write "<tr bgcolor=cccccc>" & _
							   "<td>" & rs1("ForumItemTitle") & "&nbsp;</td>" & _
							   "<td>" & rs1("ForumItemFrom") &  "&nbsp;</td>" & _
							   "<td>" & rs1("ForumItemEmail") &  "&nbsp;</td>" & _
							   "<td>" & rs1("ForumItemDate") &  "&nbsp;</td>" & _
							   "<td><a href=messPage.asp?toggle=" & rs1("IDForumItem") & "&IDForum=" & lngIDForum & ">put offline</a></td>" & _
							   "</tr>"
			else
				Response.Write "<tr>" & _
							   "<td>" & rs1("ForumItemTitle") & "&nbsp;</td>" & _
							   "<td>" & rs1("ForumItemFrom") &  "&nbsp;</td>" & _
							   "<td>" & rs1("ForumItemEmail") &  "&nbsp;</td>" & _
							   "<td>" & rs1("ForumItemDate") &  "&nbsp;</td>" & _
							   "<td><a href=messPage.asp?toggle=" & rs1("IDForumItem") & "&IDForum=" & lngIDForum & ">put online</a></td>" & _
							   "</tr>"
			end if
			rs1.MoveNext
		wend
		rs1.Close
		Response.Write "</table>"
	else
		if Request("Del") <> empty then
			Response.Write "Entry Deleted<br>"
		else
			Response.Write "Problem[1]!"
		end if
	end if

else
	Response.Write "<form action=messPage.asp method=post>"
	Response.Write "<input type=hidden name=todo value=add>"
	Response.Write "<table border=0 cellpadding=0 cellspacing=0><tr><td align=right>&nbsp;<br>"
	Response.Write "Name&nbsp;<input type=text name=ForumAdmin size=30 value="""" class=box><br>"
	Response.Write "Title&nbsp;<input type=text name=ForumTitle size=30 value="""" class=box><br>"
	Response.Write "Sort&nbsp;<input type=text name=ForumSort size=3 value="""" class=box> "
	Response.Write "| <input type=checkbox name=ForumIsOnline value=X checked> Is Online<br>"
	Response.Write "<br><input type=submit value=Add class=box>"
	Response.Write "</td></tr></table>"
	Response.Write "</form>"
	Response.Write "<p><a href=messList.asp target=left>&lt;&lt;&lt; Refresh the Message Board list &lt;&lt;&lt;</a></p><br>"
end if
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->
<!--#include VIRTUAL="/Include/DAOFooter.asp"-->

<%
sub DoAdd()
	strSQL = "SELECT * FROM Forum WHERE IDForum=0"
	rs0.Open strSQL, conConnexion, 2, 3

	rs0.AddNew
	rs0("IdDad") = 0
	rs0("ForumSortKey") = "aa"

	if Request("ForumSort") <> empty then
		rs0("ForumSort") = Request("ForumSort")
	else
		rs0("ForumSort") = Null
	end if

	if Request("ForumAdmin") <> empty then
		rs0("ForumAdmin") = Request("ForumAdmin")
	else
		rs0("ForumAdmin") = Null
	end if

	if Request("ForumTitle") <> empty then
		rs0("ForumTitle") = Request("ForumTitle")
	else
		rs0("ForumTitle") = Null
	end if

	if Request("ForumIsOnline") <> empty then
		rs0("ForumIsOnline") = true
	else
		rs0("ForumIsOnline") = false
	end if

	rs0("LastUpdateWho") = Session("IDUser")
	rs0("LastUpdateWhen") = now()

	rs0.UpDate
	rs0.MoveFirst
	lngIDForum = rs0(0) 
	rs0.Close
end sub

sub DoUpdate()
	strSQL = "SELECT * FROM Forum WHERE IDForum=" & Request("IDForum")
	rs0.Open strSQL, conConnexion, 2, 3

	if Request("Del") <> empty then
		rs0.Delete
	else
		if Request("ForumSort") <> empty then
			rs0("ForumSort") = Request("ForumSort")
		else
			rs0("ForumSort") = Null
		end if

		if Request("ForumAdmin") <> empty then
			rs0("ForumAdmin") = Request("ForumAdmin")
		else
			rs0("ForumAdmin") = Null
		end if

		if Request("ForumTitle") <> empty then
			rs0("ForumTitle") = Request("ForumTitle")
		else
			rs0("ForumTitle") = Null
		end if

		if Request("ForumIsOnline") <> empty then
			rs0("ForumIsOnline") = true
		else
			rs0("ForumIsOnline") = false
		end if

		rs0("LastUpdateWho") = Session("IDUser")
		rs0("LastUpdateWhen") = now()

		rs0.UpDate
	end if

	rs0.Close
end sub

sub DoToggle(lngIDForumItem)
	strSQL = "UPDATE ForumItem " & _
			 "SET ForumItemIsOnline = NOT ForumItemIsOnline " & _
			 "WHERE IDForumItem=" & lngIDForumItem & ";"
	rs0.Open strSQL, conConnexion
end sub

sub DoPurge(lngIDForum)
	strSQL = "DELETE * FROM ForumItem " & _
			 "WHERE IDForum=" & lngIDForum & " AND NOT ForumItemIsOnline;"
	rs0.Open strSQL, conConnexion
end sub
%>