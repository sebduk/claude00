<!--#include VIRTUAL="/Include/CodeHeader.asp"-->
<!--#include VIRTUAL=/Include/HTMLHeader.asp-->
<!--#include VIRTUAL=/Include/Label.asp-->

<table border="0" width="80%" align="center"><tr><td>


<h1>Technical guide</h1>
<h2>Update the site</h2>

<hr noShade size="1">
<p align=right>
<a href="<%=strHelpUser%>">User guide</a> | <a href="<%=strHelpTech%>">Technical guide</a>
</p>
<hr noShade size="1">

<p>
This site is dynamic meaning that your additions and updates will be automatically and instantly online.<br>
<br>
A simple login has been set to protect the access to updates.<br>
Click [<%=strMenuLogin%>] on the right of your menu bar (down) and follow the instructions.<br>
If you cannot find the [<%=strMenuLogin%>] link in the menu, you must already be logged.<br>
<br>
Click the menu bar (bottom):<br>
<table cellpadding=5 cellspacing=0 border=1 bordercolor=black bgcolor=silver>
 <tr>
  <td>
<%=strMenuUpdate%> [<%=strMenuPeople%>] [<%=strMenuCouple%>] [<%=strMenuComments%>] [<%=strMenuPictures%>]
  </td>
 </tr>
</table>
to update information linked to people.<br>
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
Family trees are made of people and couples.<br>
&gt;A couple must be formed by to registered people.<br>
&gt;The application only recognises different sex couples for now.<br>
&gt;A person may be part of one or more couples, these will be all presented in the family tree.<br>
&gt;Children must be linked to a couple regardless of the couple's status then or now.<br>
<br>
The site starts with an individual to create the tree, seeks his/her partner.<br>
&gt;If the person is single, the site seeks the parent couple and in turn their parents (if this information is unknown, parents and/or grand parents will be represented by question marks).<br>
&gt;If the person belongs to a couple, the site seeks his/her ancestry (as above) but also seeks children, their potential partners and children.<br>
&gt;If the person belongs to more than one couple, the site seeks as above for every couple separatly.<br>
All the people represented on the family tree (excluding the question marks) have an HTML link to recenter the tree on their name, and another to their full biography on their dates.<br>
<br>
Click on [<%=strMenuPeople%>] or on [<%=strMenuCouple%>] to access the relevant add and update screens.<br>
These list on their left all known people and couples.<br>
Click on a person or a couple to access the details.<br>
<br>
<u>Reload All</u>: Reload the full list of known people<br>
<u>With Parents</u>: Load the list of people with parents (Family members)<br>
<u>W/o Parents</u>: Load the list of people without parents (Ancestors and Inlaws)<br>
<u>Errors</u>: Load the list of people without parents but with a sibbling rank or vice-versa<br>
<br>
<b><%=strMenuPeople%></b><br>
The information fields are: (leave empty if the information is missing)<br>
<u>First Name</u>: Calling name (used in the tree and different lists)<br>
<u>First Names</u>: All christian names (used in the biography)<br>
<u>Last Name</u>: Family name<br>
<u>Birth Year</u>: formatted 1732, 1942 or 2002.<br>
<u>Deceased Year</u>: see previous<br>
<u>Birth Date</u>: formatted mm/dd/yyyy<br>
<u>Deceased Date</u>: see previous<br>
<u>Birth Location</u>: Town, City, Country if relevant<br>
<u>Deceased Location</u>: see previous<br>
<u>Parents</u>: Find the parent couple in the list. For "in laws" for whom parents may not be registered this field may be left blank<br>
<u>Order Sibilings</u>: 1, 2, 3, etc... Leave blank if previous is blank<br>
<u>Masc.</u>: Tick if the person is male<br>
<u>(Text area)</u>: Biography, personal comments, etc... (no size limit)<br>
<br>
Click the Add a Person link at the top and bottom of the list to add a person.<br>
Do not forget to click the Add or Update button to save your changes.<br>
<br>
<b><%=strMenuCouple%></b><br>
The information fields are: (leave empty if the information is missing)<br>
<u>Man</u>: Select the man in the couple (people for whom the Masc. has been ticked are listed)<br>
<u>Woman</u>: Select the man in the couple (people for whom the Masc. has not been ticked are listed)<br>
<u>Year</u>: formatted 1732, 1932 or 2002.<br>
<u>Date</u>: mm/dd/yyyy<br>
<u>Location</u>: Town, City, Country if relevant<br>
<br>
Click the Add a Couple link at the top and bottom of the list to add a couple.<br>
Do not forget to click the Add or Update button to save your changes.<br>
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
Comments and pictures have similar functions: They are accessible via people's biographies and are linked to one or more individuals.<br>
<br>
<b><%=strMenuComments%></b><br>
Click on a comment to update it.<br>
<u>Date</u>: Year or year/month ex: 2004/08<br>
<u>Title</u>: 2/3 words<br>
<u>(text area)</u>: Full comment (no size limit)<br>
<u>All/Referred</u>: All known people and selected people referred to in the comment (Click within the lists to add and remove people)<br>
<br>
Click Add a Comment at the top and bottom of the list to add comments.<br>
Do not forget to click the Add or Update button to save your changes.<br>
<br>
<b><%=strMenuPictures%></b><br>
Click on a file name to update.<br>
<u>File Name</u>: .jpg or .gif (may not be modified once uploaded)<br>
<u>Date</u>: Year or year/month ex: 2004/08<br>
<u>(text area)</u>: Full comment (no size limit)<br>
<u>All/Present</u>: All known people and selected people present in the picture (Click within the lists to add and remove people)<br>
<br>
Click Add a Picture to upload new picture files.<br>
Adding pictures is done in two stages: first upload the pictures and their thumbnails, then fill their description form. Please follow naming instructions before uploading a picture.<br>
Do not forget to click the Add or Update button to save your changes.<br>
</p>

<hr noShade size="1">
<p align=right>
<a href="<%=strHelpUser%>">User guide</a> | <a href="<%=strHelpTech%>">Technical guide</a>
</p>
<hr noShade size="1">


</td></tr></table>

<!--#include VIRTUAL=/Include/HTMLFooter.asp-->
