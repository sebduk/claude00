<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/Label.asp"-->

<%
Response.Write "<html>"
Response.Write "<head>"
Response.Write "<link rel=""stylesheet"" type=""text/css"" href=""/style.css"">"
Response.Write "<meta http-equiv=""Content-Type"" content=""text/html; charset=iso-8859-1"" />"
Response.Write "</head>"
Response.Write "<body bgcolor=silver topmargin=0 bottommargin=0 leftmargin=0 rightmargin=0>"
Response.Write "<table border=0 width=100% cellpadding=0 cellspacing=0>"
Response.Write "<tr>"
Response.Write "<td width=35><a href=http://www.see-our-family.fr/domain.asp target=_top>"
Response.Write "<img src=/Image/menuTree.jpg width=35 height=20 border=0>"
Response.Write "</a></td>"

if Session(strUpload & "IsUser") = true then
	Response.Write "<td>"
	Response.Write "[<a href=""/Prog/View/intro.asp"" target=main>" & strMenuHome & "</a>] &gt; "
	Response.Write strMenuGenealogy
	Response.Write " [<a href=""/Prog/View/lstNomDate.asp?tri=Nom"" target=main>" & strMenuNames & "</a>]"
	Response.Write "[<a href=""/Prog/View/lstNomDate.asp?tri=Dates"" target=main>" & strMenuYears & "</a>]"
	Response.Write "[<a href=""/Prog/View/lstCalendrier.asp"" target=main>" & strMenuCalendar & "</a>]"
	Response.Write "[<a href=""/Prog/View/lstPhotos.asp"" target=main>" & strMenuPictures & "</a>]"
	Response.Write "[<a href=""/Prog/View/lstDocs.asp"" target=main>" & strMenuDocs & "</a>]"
	if Session("DomainPackage") = "Platinum" then
		Response.Write "[<a href=""/Prog/View/message.asp"" target=main>" & strMenuMessage & "</a>]"
	end if
	Response.Write "</td>"
	Response.Write "<td align=right>"
	Response.Write "[<a href=""/Prog/Help/" & strHelpUser & """ target=main>" & strMenuHelp & "</a>]"
'	Response.Write "[<a href=""/Prog/Admin/frame.asp"" target=main>" & strMenuAdmin & "</a>]"
	Response.Write "&nbsp;"
	Response.Write "</td>"
else
	Response.Write "<td>"
	Response.Write "[<a href=""/Prog/View/intro.asp"" target=""main"">" & strMenuHome & "</a>]"
	Response.Write "</td>"
	Response.Write "<td width=40% align=right>"
	Response.Write "[<a href=""/Prog/Help/" & strHelpUser & " target=""main"">" & strMenuHelp & "</a>]"
	Response.Write "[<a href=""/p.login.asp"" target=""main"">" & strMenuLogin & "</a>]"
	Response.Write "&nbsp;"
	Response.Write "</td>"
end if

Response.Write "</tr>"
Response.Write "</table>"
Response.Write "</body>"
Response.Write "</html>"
%>