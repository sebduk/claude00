<!--#include VIRTUAL=/Include/CodeHeader.asp-->
<%
if Request("log") = "off" then
'	Session.Abandon
	Session("IDUser") = empty
	Session("UserName") = empty
end if
Session("DomainHeadTitle") = empty
%>
<!--#include VIRTUAL=/Include/HTMLHomeHeader.asp-->
<%
Response.Write "<tr valign=top>"
Response.Write "<!--Body-->"
Response.Write "<td height=380>"
Response.Write "<table border=0 height=100% width=100% cellpadding=0 cellspacing=0>"
Response.Write "<tr><td colspan=4>"

Response.Write "<center><br>"
Response.Write "<a href=signIn.asp><img src=/Image/createAccount.gif border=0></a>"
Response.Write "</center>"

Response.Write "</td></tr>"
Response.Write "<tr><td valign=bottom>"

Response.Write "<object classid=""clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"" codebase=""http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=5,0,0,0"" width=413 height=300 viewastext id=ShockwaveFlash1>"
Response.Write "<param name=movie value=/Image/logo.swf>"
Response.Write "<param name=quality value=high>"
Response.Write "<param name=bgcolor value=white>"
Response.Write "<embed src=/Image/logo.swf quality=high bgcolor=white width=413 height=300 TYPE=""application/x-shockwave-flash"" PLUGINSPAGE=""http://www.macromedia.com/shockwave/download/index.cgi?P1_Prod_Version=ShockwaveFlash"">"
Response.Write "</object>"

Response.Write "</td><td>&nbsp;</td><td valign=top>"

Response.Write "<br>"
Response.Write "<center><h1>see our family</h1></center>"

strDomain = Request.ServerVariables("SERVER_NAME")
strDomain = strReverse(strDomain)
strDomain = mid(strDomain, inStr(strDomain, ".") + 1, len(strDomain) - inStr(strDomain, "."))
strDomain = strReverse(strDomain)
Response.Write strDomain

Response.Write "<br>"
Response.Write "<b>&quot;Create you family tree, record memories, add pictures and "
Response.Write "share your history with the ones who matter&quot;</b><br>"
Response.Write "<br><br><br>"
Response.Write "<i>&laquo;Best in class! See Our Family is the easiest way to share "
Response.Write "cherrished family moments&raquo;</i><br>"
Response.Write "<div align=right>The Tracy Gazette</div><br>"
Response.Write "<br>"
Response.Write "<i>&laquo;We loved it!... I opened an account an within an hour "
Response.Write "my children where adding their family pictures for all to enjoy&raquo;</i><br>"
Response.Write "<div align=right>Geek Grannies Online</div><br>"

Response.Write "</td><td>&nbsp;</td>"

Response.Write "</tr></table>"
Response.Write "</td>"
Response.Write "</tr>"
%>
<!--#include VIRTUAL=/Include/HTMLHomeFooter.asp-->
