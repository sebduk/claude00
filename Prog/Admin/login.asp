<!--#include VIRTUAL="/Include/CodeHeader.asp"-->

<%
if Session(strUpload & "IsAdmin") = true then
	Response.Redirect "frame.asp"
else
%>

<!--#include VIRTUAL="/Include/HTMLHeader.asp"-->
<!--#include VIRTUAL="/Include/Label.asp"-->

<center>
<%=strLoginMessage%>
<br>
<br>

<form action="login.asp" method="post" name=myForm>

<input type="text" name="Login" value="<%=strPassword%>" class=box>
<input type="submit" value="ok" class=box>

</form>

</center>

<script language="javascript">
document.myForm.Login.focus();
</script>

<!--#include VIRTUAL="/Include/HTMLFooter.asp"-->

<%
end if
%>