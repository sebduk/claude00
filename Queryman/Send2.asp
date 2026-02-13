<%@ Language=VBScript %>
<%

for each X in Request.Form
	if UCase(left(X, 1)) = "X" then
		intPos = mid(X, 2)

		set smtp = Server.CreateObject("Bamboo.SMTP")				
		smtp.Server = "mail.iea.org"								
		smtp.From = "sebduk@gmail.com"							
		smtp.FromName = "IEA-DSM WebMaster"		
		smtp.Rcpt = Request("Email" & intPos)
		smtp.Subject = Request("Title" & intPos)
		smtp.Message = Request("Text" & intPos)
																			
		On Error Resume Next										
		smtp.Send													

		set smtp = nothing											
		if Err then
			set smtp = Server.CreateObject("Bamboo.SMTP")				
			smtp.Server = "mail.iea.org"								
			smtp.From = "sebduk@gmail.com"							
			smtp.FromName = "DSM Automated eMail (" & Now() & ")"		
			smtp.Rcpt = "sebduk@gmail.com"									
			smtp.Subject = "Pb with En Masse Automated Email"
			smtp.Message = Request("Email" & intPos) & vbCrlf & Request("Text" & intPos) & vbCrlf & "Error : " & Err
			smtp.Send													
			set smtp = nothing											
			Response.Write Request("Email" & intPos) & " : Error : " & Err & "<br>" & VbCrlf 								
		else
			Response.Write Request("Email" & intPos) & " : Done<br>" & VbCrlf 								
		end if								
		On Error Goto 0												
	end if
next
%>