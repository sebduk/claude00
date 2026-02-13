<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL=/Include/HTMLHeader.asp-->
<!--#include VIRTUAL=/Include/Label.asp-->

<table border="0" width="80%" align="center"><tr><td>


<h1>Aide Technique</h1>
<h2>Mettre le site &agrave; jour</h2>

<hr noShade size="1">
<p align=right>
<a href="<%=strHelpUser%>">Aide Utilisateur</a> | <a href="<%=strHelpTech%>">Aide Technique</a>
</p>
<hr noShade size="1">

<p>
L'ensemble du site est dynamique, c'est &agrave; dire que les ajouts ou modifications que vous portez sont directement en ligne.<br>
<br>
Un simple Login &agrave; &eacute;t&eacute; mis en place pour prot&eacute;ger l'acc&egrave;s aux modifications.<br>
Cliquez sur [<%=strMenuLogin%>] &agrave; gauche dans votre menu et suivez les instructions.<br>
Si vous ne trouvez pas de lien [<%=strMenuLogin%>] dans votre menu, vous &ecirc;tes d&eacute;j&agrave; logg&eacute;.<br>
<br>
En cliquant au bas de l'&eacute;cran sur:<br>
<table cellpadding=5 cellspacing=0 border=1 bordercolor=black bgcolor=silver>
 <tr>
  <td>
<%=strMenuUpdate%> [<%=strMenuPeople%>] [<%=strMenuCouple%>] [<%=strMenuComments%>] [<%=strMenuPictures%>]
  </td>
 </tr>
</table>
vous pouvez modifier les informations rattach&eacute;es aux personnes.<br>
</p>

<hr noShade size="1">

<p>
<table cellpadding=5 cellspacing=0 border=1 bordercolor=black bgcolor=silver>
 <tr>
  <td>
<%=strMenuUpdate%> [<%=strMenuPeople%>] [<%=strMenuCouple%>]
  </td>
 </tr>
</table>
L'arbre g&eacute;n&eacute;alogique est compos&eacute; de personnes et de couples.<br>
&gt;Un couple est forc&eacute;ment compos&eacute; de deux personnes d&eacute;j&agrave; enregistr&eacute;es.<br>
&gt;L'application ne prend  en compte pour le moment que les couples homme/femme.<br>
&gt;Une personne peut &ecirc;tre enregistr&eacute;e comme faisant partie de deux couples, ils seront pr&eacute;sent&eacute;s conc&eacute;cutivement dans la g&eacute;n&eacute;alogie.<br>
&gt;Les enfants sont forc&eacute;ment issus d'un couple (quelque soit le status marital pass&eacute; ou pr&eacute;sent des parents).<br>
<br>
Pour former l'arbre, l'application recherche &agrave; partir d'une personne, son appartenance &agrave; un couple.<br>
&gt;Si la personne est &quot;c&eacute;libataire&quot;, l'application fait une recherche du couple dont elle est issue, et des couples dont sont issus ses parents (en l'absence d'information sur les parents et/ou grands parents, ils sont repr&eacute;sent&eacute;s par des points d'interrogation).<br>
&gt;Si la personne fait partie d'un couple, l'application fait la m&ecirc;me recherche en amont, et une recherche des ses enfants et petits enfants.<br>
&gt;Si la personne fait partie de plusieurs couples, l'application fait la recherche ci-dessus pour chacun des couples conc&eacute;cutivement.<br>
Toutes les personnes represent&eacute;es sur l'arbre (sauf les points d'interrogation) on un lien HTML attach&eacute; &agrave; leur nom pour recr&eacute;er l'arbre en les positionant au centre du graphique, et un lien attach&eacute; &agrave; leur(s) date(s) pour ouvrir leur biographie.<br>
<br>
En cliquant sur [<%=strMenuPeople%>] ou sur [<%=strMenuCouple%>] vous obtiendrez un &eacute;cran d'ajout et mise &agrave; jour de personnes ou de couples (en anglais).<br>
Ces &eacute;crans listent dans leur partie gauche l'ensemble des personnes ou des couples d&eacute;j&agrave; enregistr&eacute;s (utilisez l'ascenseurs pour voir le bas de la liste).<br>
En cliquant sur une personne ou un couple vous obtiendrez sa fiche d&eacute;taill&eacute;e.<br>
<br>
<u>Reload All</u>: Rafraichir la liste de toutes les personnes connues<br>
<u>With Parents</u>: Lister les personnes dont les parents sont connus (Famille)<br>
<u>W/o Parents</u>: Lister les personnes dont les parents ne sont pas connus (Anc&ecirc;tres et belle famille)<br>
<u>Errors</u>: Lister les personnes dont les parents ne sont pas connus mais qui ont un rang fr&egrave;res/soeurs ou vice-versa<br>
<br>
<b><%=strMenuPeople%></b><br>
Les champs &agrave; renseigners sont: (laissez vides les informations manquantes)<br>
<u>First Name</u>: Pr&eacute;nom usuel (utilis&eacute; dans l'arbre et les diff&eacute;rentes listes)<br>
<u>First Names</u>: L'ensemble des pr&eacute;noms (Utilis&eacute;s dans la biographie)<br>
<u>Last Name</u>: Nom de famille<br>
<u>Birth Year</u>: Ann&eacute;e de Naissance, au format 1732, 1942 ou 2002.<br>
<u>Deceased Year</u>: Ann&eacute;e de D&eacute;c&egrave;s, idem<br>
<u>Birth Date</u>: Date de Naissance, mm/jj/aaaa<br>
<u>Deceased Date</u>: Date de D&eacute;c&egrave;s, idem<br>
<u>Birth Location</u>: Lieu de Naissance, ville, et pays si hors de France<br>
<u>Deceased Location</u>: Lieu de D&eacute;c&egrave;s, idem<br>
<u>Parents</u>: Choisissez les parents en d&eacute;roulant la liste. Dans le cas d'une &quot;pi&egrave;ce rapport&eacute;e&quot; dont les parents ne sont pas dans la liste, laissez blanc<br>
<u>Order Sibilings</u>: Rang Fr&egrave;res/Soeurs, 1, 2 ou 3, etc...<br>
<u>Masc.</u>: Signalez si la personne est un homme<br>
<u>(zone de texte)</u>: Commentaire rapport&eacute; &agrave; une personne, sa biographie, etc... (sans limite de taille)<br>
<br>
Pour ajouter une nouvelle personne cliquez sur le lien en haut de la liste des noms et renseignez.<br>
N'oubliez pas de cliquer le bouton OK pour prendre en compte vos modifications.<br>
<br>
<b>Couples</b><br>
Les champs &agrave; renseigners sont: (laissez vides les informations manquantes)<br>
<u>Man</u>: Homme, choisissez un homme dans le menu d&eacute;roulant<br>
<u>Woman</u>: Femme, idem<br>
<u>Year</u>: Ann&eacute;e, au format 1732, 1932 ou 2002.<br>
<u>Date</u>: mm/jj/aaaa<br>
<u>Location</u>: Lieu, ville, et pays si hors de France<br>
<br>
Pour ajouter un nouveau couple cliquez sur le lien en haut de la liste des noms et renseignez.<br>
N'oubliez pas de cliquer le bouton Update pour prendre en compte vos modifications.<br>
</p>

<hr noShade size="1">

<p>
<table cellpadding=5 cellspacing=0 border=1 bordercolor=black bgcolor=silver>
 <tr>
  <td>
<%=strMenuUpdate%> [<%=strMenuComments%>] [<%=strMenuPictures%>]
  </td>
 </tr>
</table>
Les commentaires et les photos se comportent de fa&ccedil;on similaire: Ils sont visible &agrave; partir des biographies et se rapportent &agrave; une ou plusieurs personnes.<br>
<br>
<b><%=strMenuComments%></b><br>
Cliquez sur un commentaire pour le mettre &agrave; jour.<br>
<u>Date</u>: Ann&eacute;e ou ann&eacute;e/mois<br>
<u>Title</u>: Titre en 2/3 mots<br>
<u>(zone de texte)</u>: Commentaire complet (sans limite de taille)<br>
<u>All/Referred</u>: Liste de toutes les personnes enregistrees sur le site, et liste des personnes concernees par le commentaire (Cliquez dans les listes pour ajouter et retirer des noms de la liste de droite)<br>
<br>
Pour ajouter un nouveau commentaire cliquez sur le lien "Add a Comment".<br>
N'oubliez pas de cliquer le bouton Update pour prendre en compte vos modifications.<br>
<br>
<b><%=strMenuPictures%></b><br>
Cliquez sur une photo pour la mettre &agrave; jour.<br>
<u>File Name</u>: Nom du fichier .jpg ou .gif<br>
<u>Date</u>: Ann&eacute;e ou ann&eacute;e/mois<br>
<u>(zone de texte)</u>: Commentaire complet (sans limite de taille)<br>
<u>All/Present</u>: Liste de toutes les personnes enregistr&eacute;es sur le site, et liste des personnes presentes sur la photo (Cliquez dans les listes pour ajouter et retirer des noms de la liste de droite)<br>
<br>
Pour ajouter une nouvelle photo cliquez sur le lien "Add a Picture".<br>
L'ajout se fait en deux temps :<br> 
Vous devez d'abord sur votre disque dur s&eacute;lectionner la photo choisie et la mettre au format 
d&eacute;sir&eacute; (800 * 600 pixels &eacute;tant la norme moyenne des &eacute;crans d'ordinateurs portables).<br>
Vous devez, ensuite, cr&eacute;er une deuxi&egrave;me photo (vignette) identique &agrave; la pr&eacute;c&eacute;dent que vous 
renommerez comme la pr&eacute;c&eacute;dente en ajoutant .tn et que vous dimensionnerez &agrave; 100 pixels sur 
le plus grand cot&eacute; (hauteur ou largeur).<br>
<br>
Ex : GastonDucos.jpg sur 600 * 800 pixels et GastonDucos.tn.jpg sur 75 * 100 pixels<br> 
<br>
Vous chargez, enfin,  les photos (l'original + la vignette) et les renseignez comme pour les 
autres dossiers.<br>
N'oubliez pas de cliquer le bouton Update
</p>




<hr noShade size="1">
<p align=right>
<a href="<%=strHelpUser%>">Aide Utilisateur</a> | <a href="<%=strHelpTech%>">Aide Technique</a>
</p>
<hr noShade size="1">


</td></tr></table>

<!--#include VIRTUAL=/Include/HTMLFooter.asp-->
