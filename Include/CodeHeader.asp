<%@ LANGUAGE="VBSCRIPT" %>
<% 'Option Explicit %>

<%
Sub Redirige( strURL )
	Response.Write "<html><head>" & vbCrlf
	Response.Write "<meta HTTP-EQUIV=REFRESH CONTENT=""0; URL=" & strURL & """> </head>" & VbCrlf
	Response.Write "</head></html>" & VbCrlf
	Response.End
End Sub

Function Format(intValue, strFormat)
	dim intLenVal, intLenFor
	intLenVal = len(intValue)
	intLenFor = len(strFormat)

	if strFormat = string(intLenFor, "0") and intLenVal < intLenFor then
		Format = string(intLenFor - intLenVal, "0") & intValue
	else
		Format = intValue
	end if
	
End Function

Dim strTitle, strBgColor, numGenerations
Dim strHeadTitle, strLanguage, strDateFormat, strConn
Dim strImage, strDocument, strUpload, strIcon, isLogged

if Request("LinkDom") <> Empty then 
	Session("DomainDB") = Request("LinkDom") & ".mdb"
	Session("DomainUpload") = Request("LinkDom")
	Session(Session("DomainUpload") & "IsUser") = true
end if

numGenerations = 2
strLanguage = Session("DomainLanguage")
strDateFormat = Session("DomainDateFormat")
strConn = "PROVIDER=Microsoft.Jet.OLEDB.4.0;DATA SOURCE=" & server.mappath("/Gene/Data/" & Session("DomainDB")) & ";"
strImage = "/Gene/File/" & Session("DomainUpload") & "/Image/"
strDocument = "/Gene/File/" & Session("DomainUpload") & "/Document/"
strUpload = Session("DomainUpload")
strHeadTitle = Session("DomainHeadTitle")
strIcon = Session("DomainUpload") & ".ico"

if Session("DomainPwdAdmin") <> "" then
	if Ucase(Request("Login")) = Ucase(Session("DomainPwdAdmin")) then  
		Session(strUpload & "IsAdmin") = true
		Session(strUpload & "IsUser") = true
	end if
else
	Session(strUpload & "IsAdmin") = true
end if

if Session("DomainPwdGuest") <> "" then
	if Ucase(Request("Login")) = Ucase(Session("DomainPwdGuest")) then  
		Session(strUpload & "IsUser") = true
	end if
else
	Session(strUpload & "IsUser") = true
end if

if Request("Language") <> empty then Session("Language") = Request("Language")
if Session("Language") <> empty then strLanguage = Session("Language")
%>
