<%@ LANGUAGE="VBSCRIPT" %>
<% 'Option Explicit %>

<%
if instr(LCase(Request.ServerVariables("HTTP_ACCEPT")), ".wap.") = 0 and _
   instr(LCase(Request.ServerVariables("PATH_INFO")), "rss.asp") = 0 then
	Dim strConn, con, rs, strSQL, strMove, strDomain

	strConn = "PROVIDER=Microsoft.Jet.OLEDB.4.0;DATA SOURCE=" & server.mappath("/Data/user.mdb") & ";"
	Set con = Server.CreateObject("ADODB.Connection")
	con.Open strConn
	Set rs = Server.CreateObject("ADODB.Recordset")

	strDomain = Request.ServerVariables("SERVER_NAME")
	strDomain = strReverse(strDomain)
	strDomain = mid(strDomain, inStr(strDomain, ".") + 1, len(strDomain) - inStr(strDomain, "."))
	strDomain = strReverse(strDomain)

	strSQL = "SELECT * FROM [Domain] " & _
			 "WHERE DomainIsOnline=TRUE AND DomainPackage='Platinum' AND " & _
			 "DomainURL='" & strDomain & "';"
	rs.Open strSQL, con

	if not rs.EOF then
		Session("DomainName") = rs("DomainName")
		Session("DomainURL") = rsDomainURL
		Session("DomainDB") = rs("DomainDB")
		Session("DomainLanguage") = rs("DomainLanguage")
		Session("DomainDateFormat") = rs("DomainDateFormat")
		Session("DomainUpload") = rs("DomainUpload")
		Session("DomainHeadTitle") = rs("DomainHeadTitle")
		Session("DomainPackage") = rs("DomainPackage")
		Session("DomainPwdGuest") = rs("DomainPwdGuest")
		Session("DomainPwdAdmin") = rs("DomainPwdAdmin")
		Session("DomainTarget") = "/p.frame.asp"
	else
		Session("DomainTarget") = "/home.asp"
	end if

	rs.Close
	con.Close
	Set rs = Nothing
	Set con = Nothing

	Session("FromGlobal") = true
	Response.Redirect Session("DomainTarget") '"/"
end if
%>

</SCRIPT>
