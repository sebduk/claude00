<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL=/Include/HTMLHeader.asp-->
<!--#include VIRTUAL=/Include/Label.asp-->

<table border="0" width="80%" align="center"><tr><td>


<h1>Aide Utilisateur</h1>
<h2>Visitez le site!</h2>

<hr noShade size="1">
<p align=right>
<a href="<%=strHelpUser%>">Aide Utilisateur</a> | <a href="<%=strHelpTech%>">Aide Technique</a>
</p>
<hr noShade size="1">

<p>
En cliquant en haut de l'&eacute;cran sur :<br>
<table cellpadding=5 cellspacing=0 border=1 bordercolor=black bgcolor=silver>
 <tr>
  <td>
<%=strMenuGenealogy%> [<%=strMenuNames%>] [<%=strMenuYears%>] [<%=strMenuCalendar%>] [<%=strMenuPictures%>]
  </td>
 </tr>
</table>
vous acc&eacute;dez &agrave; la liste des personnes qui figurent sur le site<br>
<br>
<u><%=strMenuNames%></u>: ordonn&eacute;es par noms de famille et pr&eacute;noms.<br>
<u><%=strMenuYears%></u>: ordonn&eacute;es par ann&eacute;e de naissance.<br>
<u><%=strMenuCalendar%></u>: ordonn&eacute;es par anniversaire pr&eacute;sent&eacute; sous forme de calendrier<br>(Pour les personnes dont la date de naissance exacte est connue).<br>
<u><%=strMenuPictures%></u>: liste des photos enregistr&eacute;es sur le site par ordre chronologique.<br>
<br>
En cliquant sur un nom vous acc&eacute;dez &agrave; un arbre g&eacute;n&eacute;alogique centr&eacute; sur cette personne, incluant deux g&eacute;n&eacute;rations pr&eacute;c&eacute;dantes et deux g&eacute;n&eacute;rations suivantes (des grands parents aux petits enfants).<br>
En cliquant sur une photo vous obtenez cette photo en grand format et les liens vers les personnes pr&eacute;sentes sur la photo.<br>
</p>


<hr noShade size="1">


<p>
D&eacute;tail d'un arbre:
<table cellpadding="0" cellspacing="0" border="1" bordercolor="#000000">
 <tr>
  <td>
<table cellpadding="5" cellspacing="0" border="0">
 <tr>
  <td align="right">Jean&nbsp;DUPONT<br>(1800-1865)</td>
  <td>Marie&nbsp;DUBOIS<br>(1805-1880)</td>
 </tr>
</table>
  </td>
 </tr>
</table>
En cliquant sur un nom, vous pouvez recenter l'arbre g&eacute;n&eacute;alogique sur une personne.<br>
En cliquant sur une dates, vous ouvrez une nouvelle fen&ecirc;tre qui contient la biographie de cette personne, des commentaires la concernant (en groupe avec d'autres personnes de la famille) et des photos.<br>
<br>
Au dessus de chaque arbre vous trouverez une s&eacute;rie d'options suppl&eacute;mentaires:
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
Ascendance compl&egrave;te:<br>
<u>Horizontale</u> une pyramide invers&eacute;e avec &agrave; la base la personnes choisie et l'ensemble de ses anc&egrave;tres sans limite de g&eacute;n&eacute;rations.<br>
<u>Verticale</u> une pyramide renvers&eacute;e similaire &agrave; la pr&eacute;c&eacute;dente.<br>
<u>Table</u> une pr&eacute;sentation en tableau de l'ensemble des anc&egrave;tres d'une personne.<br>
<u>Excel</u> similaire au pr&eacute;c&eacute;dant mais directement au format Excel. Si cette version ne marche pas (Excel pas install&eacute;, trop lent, etc...) choisissez la pr&eacute;c&eacute;dante et Copier/Coller l'information dans un tableur.<br>
<br>
Descendance compl&egrave;te:<br>
<u>Horizontale</u> une pyramide avec au sommet la personnes choisie et l'ensemble de sa descendance sans limite de g&eacute;n&eacute;rations.<br>
<u>Verticale</u> une pyramide renvers&eacute;e similaire &agrave; la pr&eacute;c&eacute;dente.<br>
<u>Table</u> une pr&eacute;sentation en tableau de l'ensemble de la descendance d'une personne.<br>
<u>Excel</u> similaire au pr&eacute;c&eacute;dant mais directement au format Excel. Si cette version ne marche pas (Excel pas install&eacute;, trop lent, etc...) choisissez la pr&eacute;c&eacute;dante et Copier/Coller l'information dans un tableur.<br>
<br>
<b>Ces versions sont <u>tr&egrave;s</u> lourdes &agrave; g&eacute;n&eacute;rer. Soyez <u>tr&egrave;s</u> patient!</b><br>
</p>


<hr noShade size="1">


<p>
D&eacute;tails d'une biographie:
<table cellpadding="5" cellspacing="0" border="1" bordercolor="#000000">
 <tr>
  <td>
<center>
<h1>Jean&nbsp;Joseph&nbsp;Louis&nbsp;DUPONT</a></h1>
<b>(1/25/1800-1/30/1865)</b><br>
<%=strBornInM%> Paris. <%=strDiedInM%> Paris<br>
</center>
<hr noShade size="1">
<b><%=strBiography%></b><br>
<br>
<hr noShade size="1">
<b><%=strComments%></b><br>
<u>(1818-1822) Ecole...</u><br>
Diplom&eacute; de l'Ecole...<br>
<i>Avec: Jules&nbsp;DESCHAMPS, Louis&nbsp;DURANT.</i><br>
<br>
<hr noShade size="1">

<b><%=strPictures%></b><br>
<table border="0" cellpadding="0" cellspacing="2">
<tr>
<td><hr size="1" width="100%" noshade></td>
</tr>
<tr valign="top">
<td align="center" width="100" height="100"><img src="/Image/DucosGaston1900.tn.jpg" WIDTH="67" HEIGHT="100"></td>
<td>(1900)<br>
Diplom&eacute; de l'Ecole...<br>
<i>Avec: Jules&nbsp;DESCHAMPS, Louis&nbsp;DURANT.</i></td>
</tr>
<tr><td><hr size="1" width="100%" noshade></td></tr>
</table>
  </td>
 </tr>
</table>
<br>
Dans une biographie, vous pouvez cliquer sur le <b>nom de la personne</b> pour recentrer l'arbre sur elle, ou cliquer sur les noms en <i>italique</i> pour ouvrir les biographies d'autres personnes.
</p>

<hr noShade size="1">
<p align=right>
<a href="<%=strHelpUser%>">Aide Utilisateur</a> | <a href="<%=strHelpTech%>">Aide Technique</a>
</p>
<hr noShade size="1">

</td></tr></table>

<!--#include VIRTUAL=/Include/HTMLFooter.asp-->
