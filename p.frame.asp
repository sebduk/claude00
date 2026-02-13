<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<%
if Request("DomKey") <> empty then
	Dim con, rs, strSQL, strMove

	strConn = "PROVIDER=Microsoft.Jet.OLEDB.4.0;DATA SOURCE=" & server.mappath("/Data/user.mdb") & ";"
	Set con = Server.CreateObject("ADODB.Connection")
	con.Open strConn
	Set rs = Server.CreateObject("ADODB.Recordset")

	strSQL = "SELECT * FROM [Domain] " & _
			 "WHERE DomainRNDKey='" & Request("DomKey") & "';"
	'Response.Write strSQL & "<br>"
	rs.Open strSQL, con

	if not rs.eof then
		Session("DomainName") = rs("DomainName")
		Session("DomainURL") = Session("DomainName") & ".cea-ebm.com"
		Session("DomainDB") = rs("DomainDB")
		Session("DomainLanguage") = rs("DomainLanguage")
		Session("DomainDateFormat") = rs("DomainDateFormat")
		Session("DomainUpload") = rs("DomainUpload")
		Session("DomainHeadTitle") = rs("DomainHeadTitle")
		Session("DomainPackage") = rs("DomainPackage")
		Session("DomainPwdGuest") = rs("DomainPwdGuest")
		Session("DomainPwdAdmin") = rs("DomainPwdAdmin")
	end if

	rs.Close
	con.Close
	Set rs = Nothing 
	Set con = Nothing
end if
%>
<html>
<head>
<% '<%=strHeadTitle%>

<title>Généalogie</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
</head>

<frameset rows="20,*,16" border=0 framespacing=0>
	<frame frameborder=0 name=menu src=/Prog/p.menu.asp scrolling=no>
	<frame frameborder=0 name=main src=/Prog/View/intro.asp>
	<frame frameborder=0 name=lang src=/Prog/p.lang.asp>

	<noframes>
		<body bgcolor=#666666>
This site would be nicer with Frames.<br>
If your browser does not support them <a href=mailto:sebduk@gmail.com>write to me</a> !<br><br>
		</body>
	</noframes>

</frameset>

</html>
