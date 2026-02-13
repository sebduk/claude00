<%@ LANGUAGE="VBSCRIPT" %>

<%
If Session("Refresh") = 0 then
%>
<HTML><BODY bgcolor=#ffffff><%=Application("ShowText")%><form action=top.asp><input type=submit value=Refresh></form></BODY></HTML><script language="JavaScript" type="text/javascript">function scrollWindow() {this.scroll(0,65000);setTimeout('scrollWindow()', 200);}scrollWindow();</script>
<%
Else
%>
<HTML><HEAD><META HTTP-EQUIV="Refresh" content="<%=Session("Refresh")%>;top.asp"></HEAD><BODY bgcolor=#ffffff><%=Application("ShowText")%></BODY></HTML><script language="JavaScript" type="text/javascript">function scrollWindow() {this.scroll(0,65000);setTimeout('scrollWindow()', 200);}scrollWindow();</script>
<%
End If
%>
