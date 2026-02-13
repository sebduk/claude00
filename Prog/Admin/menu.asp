<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL="/Include/Label.asp"-->

<%
Response.Write "<html>"
Response.Write "<head>"
Response.Write "<link rel=""stylesheet"" type=""text/css"" href=""/style.css"">"
Response.Write "</head>"
Response.Write "<body bgcolor=#cccccc topmargin=0 bottommargin=0 leftmargin=0 rightmargin=0>"
Response.Write "<table border=0 width=100% cellpadding=0 cellspacing=0>"
Response.Write "<tr>"
Response.Write "<td width=35><img src=/Image/menuTree2.jpg width=35 height=20 border=0></td>"
Response.Write "<td>"
Response.Write "[<a href=adminHome.asp target=adminMain><b>h</b>ome</a>] &gt; "
Response.Write "<b>u</b>pdate "
Response.Write "[<a href=persIndex.asp target=adminMain><b>p</b>eople</a>] "
Response.Write "[<a href=coupIndex.asp target=adminMain><b>c</b>ouples</a>] "
Response.Write "[<a href=commIndex.asp target=adminMain><b>c</b>omments</a>] "
Response.Write "[<a href=photoIndex.asp target=adminMain><b>p</b>ictures</a>] "
Response.Write "[<a href=docIndex.asp target=adminMain><b>d</b>ocuments</a>] "
Response.Write "[<a href=infoIndex.asp target=adminMain><b>i</b>nformation</a>] "
if Session("DomainPackage") = "Platinum" then
	Response.Write "[<a href=messIndex.asp target=adminMain><b>m</b>essages</a>]"
end if
Response.Write "</td>"
Response.Write "</tr>"
Response.Write "</table>"
Response.Write "</body>"
Response.Write "</html>"
%>
