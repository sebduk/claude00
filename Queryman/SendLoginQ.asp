<%@ LANGUAGE="VBSCRIPT" %>

<HTML>
<head>
<link rel=stylesheet type=text/css href=/queryman/style.css>
</head>
<BODY bgcolor=#888888>

<center>

<table border=0>
	<tr align=center valign=top>

<Form Action=Send1.asp target=answer method=post>
		<td>
			<select name=MyDSN>
			 <option value="DSN=NewDSM;">NewDSM</option>
			 <option value="DSN=DSM;">DSM</option>
			 <option value="DSN=task1Data;">Task 1 Data</option>
			 <option value="DSN=task1Search;">Task 1 Search</option>
			 <option value="DSN=task2;">Task 2</option>
			 <option value="DSN=task3;">Task 3</option>
			 <option value="DSN=task4;">Task 4</option>
			 <option value="DSN=task5;">Task 5</option>
			 <option value="DSN=task6;">Task 6</option>
			 <option value="DSN=task7;">Task 7</option>
			 <option value="DSN=task8;">Task 8</option>
			 <option value="DSN=task9;">Task 9</option>
			 <option value="DSN=RND;">RND</option>
			</select><br>

			<textarea cols=30 rows=5 name=MyQuery>SELECT Email, Login, Password
FROM ContactDSM
WHERE IsTaskI</textarea><br>Query (List : Email, Login, Password)
		</td>
		<td>
			Title : <input type=text size=70 name=MyTitle value="Login and Password"><br>
			<textarea cols=70 rows=5 name=MyText>Your text

Login : [Login]
Password : [Password]</textarea><br>Text (include Login, Password between [])
		</td>
	</tr>
	<tr>
		<td colspan=2 align=center>
			<input type=submit value="Submit" id=submit name=submit>
		</td>
</form>

	</tr>
</table>

</center>

</BODY>
</HTML>

<SCRIPT LANGUAGE="Javascript">
function openChat()
{
newWindow=window.open( "/queryman/chat/frame.asp" , "Chat", "toolbar=0,location=0,directories=0,status=0,menubar=0,scrollbars=0,resizable=1,copyhistory=0,width=750,height=150" ) ;
}
</SCRIPT>


