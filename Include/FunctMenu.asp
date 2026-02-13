<SCRIPT LANGUAGE="VBSCRIPT" RUNAT="SERVER">

Sub PrintMenuTitle(strText)

	Response.Write "<TR>" & Chr(13) & Chr(10)
	Response.Write "	<TD WIDTH=200>&nbsp;</TD>" & Chr(13) & Chr(10)
	Response.Write "	<TD ALIGN=LEFT>" & Chr(13) & Chr(10)
	Response.Write "		<H2>" & strText & "</H2>" & Chr(13) & Chr(10)
	Response.Write "	</TD>" & Chr(13) & Chr(10)
	Response.Write "</TR>" & Chr(13) & Chr(10)

End Sub

Sub PrintMenuHeader(strText)

	Response.Write "<TR><TD COLSPAN=2><HR NOSHADE SIZE=1></TD></TR>" & Chr(13) & Chr(10)
	Response.Write "<TR>" & Chr(13) & Chr(10)
	Response.Write "<TD WIDTH=200 COLSPAN=2><FONT FACE=""ARIAL,Helvetica"" SIZE=2><B>&nbsp;" & strText & "</B></FONT></TD>" & Chr(13) & Chr(10)
	Response.Write "</TR>" & Chr(13) & Chr(10)

End Sub

Sub PrintMenuItem(strText, strUrl)

	Response.Write "<TR>" & Chr(13) & Chr(10)
	Response.Write "<TD ALIGN=RIGHT VALIGN=MIDDLE>" & Chr(13) & Chr(10)
	'Response.Write "<FORM ACTION=" & Chr(34) & strUrl & Chr(34) & " METHOD=POST>" & Chr(13) & Chr(10)
	'Response.Write "<INPUT TYPE=IMAGE SRC=" & Application("strImagePath") & "/btn_rightarrow_on.gif border=0>" & Chr(13) & Chr(10)
	'Response.Write "</TD></FORM>" & Chr(13) & Chr(10)
	Response.Write "<a href=" & strUrl & ">" & "<img SRC=" & Application("strImagePath") & "/btn_rightarrow_on.gif border=0></a>" & Chr(13) & Chr(10)  & "</TD>"
	Response.Write "<TD>" & Chr(13) & Chr(10)
	Response.Write "&nbsp;<font face=""ARIAL,Helvetica"" size=2>" & strText & "</font>" & Chr(13) & Chr(10)
	Response.Write "</TD>" & Chr(13) & Chr(10)
	Response.Write "</TR>" & Chr(13) & Chr(10)

End Sub

Sub PrintNavMenu(strMenu)
	
	Response.Write "<center><table border=1 cellspacing=0 cellpadding=0 bordercolor=#991111>"
	Response.Write "<tr><td><table border=0 bgcolor=#efefef>"

	if strMenu = "FDP" then
		Response.Write "<tr><td>" & Application("MenuPrinc") & "</td><td>&nbsp;&nbsp;</td><td>" & Application("MenuFDP") & "</td></tr>"
	else
		Response.Write "<tr><td>" & Application("MenuPrinc") & "</td><td>&nbsp;&nbsp;</td><td>" & Application("MenuMono") & "</td></tr>"
	end if

	Response.Write "</table></td></tr>"
	Response.Write "</table></center>"

End Sub
</SCRIPT>
