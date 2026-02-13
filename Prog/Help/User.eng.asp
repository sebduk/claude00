<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL=/Include/HTMLHeader.asp-->
<!--#include VIRTUAL=/Include/Label.asp-->

<table border="0" width="80%" align="center"><tr><td>


<h1>User Guide</h1>
<h2>Visit the site!</h2>

<p>
Find at the top of the screen :<br>
<table cellpadding=5 cellspacing=0 border=1 bordercolor=black bgcolor=silver>
 <tr>
  <td>
<%=strMenuGenealogy%> [<%=strMenuNames%>] [<%=strMenuYears%>] [<%=strMenuCalendar%>] [<%=strMenuPictures%>]
  </td>
 </tr>
</table>
to access the list of people registered on the site<br>
<br>
<u><%=strMenuNames%></u>: ordered by family names and christian names.<br>
<u><%=strMenuYears%></u>: ordered by year of birth.<br>
<u><%=strMenuCalendar%></u>: ordered by birthday and presented as a calendar<br>(For people for whom an exact birthday is known).<br>
<u><%=strMenuPictures%></u>: list of pictures on the site by chronological order.<br>
<br>
Click on a name to access a family tree centred on the person, with 2 generations above and 2 below (from grand-parents to grand-children).<br>
Click on a picture to see it in full format and get links to all the people present on the picture.<br>
</p>


<hr noShade size="1">


<p>
Tree details:
<table cellpadding="0" cellspacing="0" border="1" bordercolor="#000000">
 <tr>
  <td>
<table cellpadding="5" cellspacing="0" border="0">
 <tr>
  <td align="right">John&nbsp;SMITH<br>(1800-1865)</td>
  <td>Mary&nbsp;JONES<br>(1805-1880)</td>
 </tr>
</table>
  </td>
 </tr>
</table>
Click on a name to recenter the tree on a person.<br>
Click on dates to open a the person's biography in a separate window, with comments (shared with other members of the family) and pictures.<br>
<br>
The following links appear above each tree:
<table cellpadding="5" cellspacing="0" border="1" bordercolor="#000000">
 <tr><td>
	<table cellpadding=0 cellspacing=0 border=0>
	 <tr valign=top><td>
<b>John SMITH</b>&nbsp;
	 </td><td>
<%=strFullAscendance%><br> 
<%=strFullDescendance%>
	 </td><td>
&nbsp;|&nbsp;[<%=strHorizontalVersion%>]
[<%=strVerticalVersion%>]
[<%=strTableVersion%>]
[<%=strExcelVersion%>]
<br>
&nbsp;|&nbsp;[<%=strHorizontalVersion%>]
[<%=strVerticalVersion%>]
[<%=strTableVersion%>]
[<%=strExcelVersion%>]
	 </td></tr>
	</table>
 </td></tr>
</table>
<br>
All Parents:<br>
<u>Horizontal</u> an inverted pyramid based on the chosen person including all his/her forefathers.<br>
<u>Vertical</u> an pyramid on its side similar to the previous.<br>
<u>Table</u> a table presentation of one's forefathers.<br>
<u>Excel</u> identical to the previous in an Excel format. If this version fails (Excel not installed, too slow, etc...) try the previous which you may select, copy and paste into a spreadsheet.<br>
<br>
All Children:<br>
<u>Horizontal</u> a pyramid topped by the chosen person including all his/her heirs.<br>
<u>Vertical</u> an pyramid on its side similar to the previous.<br>
<u>Table</u> a table presentation of one's children.<br>
<u>Excel</u> identical to the previous in an Excel format.<br>
<br>
<b>These versions may be <u>very</u> heavy to generate. Be <u>very</u> patient!</b><br>
</p>


<hr noShade size="1">


<p>
Biography details:
<table cellpadding="5" cellspacing="0" border="1" bordercolor="#000000">
 <tr>
  <td>
<center>
<h1>John&nbsp;Paul&nbsp;SMITH</a></h1>
<b>(1/25/1800-1/30/1865)</b><br>
<%=strBornInM%> London. <%=strDiedInM%> Sydney<br>
</center>
<hr noShade size="1">
<b><%=strBiography%></b><br>
<br>
<hr noShade size="1">
<b><%=strComments%></b><br>
<u>(1818-1822) College...</u><br>
Graduated from ... College<br>
<i>With: James&nbsp;LEWIS, Jack&nbsp;LORDS.</i><br>
<br>
<hr noShade size="1">

<b><%=strPictures%></b><br>
<table border="0" cellpadding="0" cellspacing="2">
<tr>
<td><hr size="1" width="100%" noshade></td>
</tr>
<tr valign="top">
<td align="center" width="100" height="100"><img src="/Image/DucosGaston1900.tn.jpg" WIDTH="67" HEIGHT="100"></td>
<td>(1822)<br>
Graduated from ... College<br>
<i>With: James&nbsp;LEWIS, Jack&nbsp;LORDS.</i></td>
</tr>
<tr><td><hr size="1" width="100%" noshade></td></tr>
</table>
  </td>
 </tr>
</table>
<br>
You may click on the <b>person's name</b> to center the tree around him/her, or click a name in <i>italic</i> to see other people's biography.
</p>

</td></tr></table>

<!--#include VIRTUAL=/Include/HTMLFooter.asp-->
