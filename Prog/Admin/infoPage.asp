<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/DAOHeader.asp"-->
<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->

<%
Dim lngIDInfo, lngIDPersonne, intPos

if Request("todo") = "add" then
	strSQL = "SELECT * FROM Info WHERE IDInfo=0"
	rs0.Open strSQL, conConnexion, 2, 3

	rs0.AddNew
	if Request("InfoLocation") <> empty then
		rs0("InfoLocation") = Request("InfoLocation")
	else
		rs0("InfoLocation") = Null
	end if

	if Request("InfoContent") <> empty then
		rs0("InfoContent") = Request("InfoContent")
	else
		rs0("InfoContent") = Null
	end if

	rs0("InfoIsOnline") = true

	rs0("LastUpdateWho") = Session("IDUser")
	rs0("LastUpdateWhen") = now()

	rs0.UpDate
	rs0.MoveFirst
	lngIDInfo = rs0(0) 
	rs0.Close

elseif Request("todo") = "update" then
	strSQL = "SELECT * FROM Info WHERE IDInfo=" & Request("IDInfo")
	rs0.Open strSQL, conConnexion, 2, 3

	if Request("Del") <> empty then
		rs0.Delete
	else
		if Request("InfoLocation") <> empty then
			rs0("InfoLocation") = Request("InfoLocation")
		else
			rs0("InfoLocation") = Null
		end if

		if Request("InfoContent") <> empty then
			rs0("InfoContent") = Request("InfoContent")
		else
			rs0("InfoContent") = Null
		end if

		rs0("InfoIsOnline") = true

		rs0("LastUpdateWho") = Session("IDUser")
		rs0("LastUpdateWhen") = now()

		rs0.UpDate
	end if

	rs0.Close

end if



if Request("IDInfo") <> empty then lngIDInfo = Request("IDInfo")

if lngIDInfo <> empty then
	strSQL = "SELECT * FROM Info WHERE IDInfo=" & lngIDInfo
	rs0.Open strSQL, conConnexion, 2, 3

	if not rs0.EOF then
		Response.Write "<form action=infoPage.asp name=myForm method=post>"
		Response.Write "<input type=hidden name=IDInfo value=" & rs0("IDInfo") & ">"
		Response.Write "<input type=hidden name=todo value=update>"
		Response.Write "<table border=0 cellpadding=0 cellspacing=0><tr valign=top><td align=right>&nbsp;<br>"
		Response.Write "Location&nbsp;<input type=text name=InfoLocation size=30 value=""" & rs0("InfoLocation") & """ class=box><br>"
		Response.Write "<textarea name=InfoContent cols=70 rows=21 class=box>" & rs0("InfoContent") & "</textarea><br>"
		Response.Write "<br><input type=submit value=Update class=box>"
		Response.Write "<input type=submit name=del value=Delete class=box>"
		Response.Write "</td></tr></table>"
		Response.Write "</form>"

	else
		if Request("Del") <> empty then
			Response.Write "Entry Deleted<br>"
		else
			Response.Write "Problem[1]!"
		end if
	end if

else
	Response.Write "<form action=infoPage.asp method=post>"
	Response.Write "<input type=hidden name=todo value=add>"
	Response.Write "<table border=0 cellpadding=0 cellspacing=0><tr><td align=right>"
	Response.Write "Location&nbsp;<input type=text name=InfoLocation size=30 class=box><br>"
	Response.Write "<textarea name=InfoContent cols=70 rows=15 class=box></textarea><br>"
	Response.Write "<br><input type=submit value=Add class=box>"
	Response.Write "</td></tr></table>"
	Response.Write "</form>"
end if


Response.Write "<p><a href=infoList.asp target=left>&lt;&lt;&lt; Refresh the information list &lt;&lt;&lt;</a></p>"
%>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->
<!--#include VIRTUAL="/Include/DAOFooter.asp"-->
