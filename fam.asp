<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<%
if Request("fam") <> empty then
	Dim con, rs, strSQL, strMove

	strConn = "PROVIDER=Microsoft.Jet.OLEDB.4.0;DATA SOURCE=" & server.mappath("/Data/user.mdb") & ";"
	Set con = Server.CreateObject("ADODB.Connection")
	con.Open strConn
	Set rs = Server.CreateObject("ADODB.Recordset")

	'strSQL = "SELECT [Domain].*, [Status] " & _
	'		 "FROM [Domain] INNER JOIN LkDomainUser ON [Domain].IDDomain = LkDomainUser.IdDomain " & _
	'		 "WHERE IdUser=0" & Session("IDUser") & " AND DomainName='" & Request("fam") & "';"
	strSQL = "SELECT [Domain].* " & _
			 "FROM [Domain] " & _
			 "WHERE DomainName='" & Request("fam") & "';"
	'Response.Write strSQL & "<br>"
	rs.Open strSQL, con

	if not rs.eof then
		Session("DomainName") = rs("DomainName")
		Session("DomainURL") = rs("DomainURL")
		Session("DomainDB") = rs("DomainDB")
		Session("DomainLanguage") = rs("DomainLanguage")
		Session("DomainDateFormat") = rs("DomainDateFormat")
		Session("DomainUpload") = rs("DomainUpload")
		Session("DomainHeadTitle") = rs("DomainHeadTitle")
		Session("DomainPackage") = rs("DomainPackage")
		Session("DomainPwdGuest") = rs("DomainPwdGuest")
		Session("DomainPwdAdmin") = rs("DomainPwdAdmin")
		Session("Language") = Session("DomainLanguage")
	end if

	rs.Close
	con.Close
	Set rs = Nothing 
	Set con = Nothing
end if

Response.Write "<html>"
Response.Write "<head>"
Response.Write "<title>See Our Family</title>"
Response.Write "</head>"

select case Session("DomainPackage")
	case "Platinum", "Gold"
		Response.Write "<frameset rows=""20,*,16"" border=0 framespacing=0>"
		Response.Write "<frame frameborder=0 name=menu src=/Prog/menu.asp scrolling=no>"
		Response.Write "<frame frameborder=0 name=main src=/Prog/View/intro.asp>"
		Response.Write "<frame frameborder=0 name=lang src=/Prog/lang.asp>"
	case else
		Response.Write "<frameset rows=""20,*,16,66"" border=0 framespacing=0>"
		Response.Write "<frame frameborder=0 name=menu src=/Prog/menu.asp scrolling=no>"
		Response.Write "<frame frameborder=0 name=main src=/Prog/View/intro.asp>"
		Response.Write "<frame frameborder=0 name=lang src=/Prog/lang.asp>"
		Response.Write "<frame frameborder=0 name=pub src=/Pub/pub.asp?Size=468x60>"
end select

Response.Write "<noframes>"
Response.Write "<body bgcolor=#666666>"
Response.Write "This site would be nicer with Frames."
Response.Write "</body>"
Response.Write "</noframes>"
Response.Write "</frameset>"
Response.Write "</html>"
%>
