<%
sub sendMail(strFrom, strFromName, strTo, strSubject, strBody)

	dim strServer
	strServer = LCase(Request.ServerVariables("SERVER_NAME"))

	if strServer <> "id-00155" and strServer <> "localhost" then 

		dim objNewMail
		set objNewMail = Server.CreateObject("Persits.MailSender")

		strBody = "<html><body>" & _
				  "<head><style>" & _
				  "BODY {font-family:Verdana,Arial,Helvetica,sans-serif;font-size:10pt;color:black;}" & _
				  "</style></head>" & _
				  "<body link=black vlink=black alink=black>" & strBody & _
				  "</body></html>"

		if strTo = "webmaster" then	strTo = "sebduk@gmail.com"
		if strFrom = "webmaster" then strFrom = "sebduk@gmail.com"
					
		objNewMail.Host = "mail.iea.org"
		objNewMail.From = strFrom
		objNewMail.FromName = strFromName
		objNewMail.AddAddress strTo
		objNewMail.Subject = strSubject
		objNewMail.Body = strBody
		objNewMail.IsHTML = True
		objNewMail.Priority = 3

		'objNewMail.AppendBodyFromFile	str
		'objNewMail.AddAttachment		str
		'objNewMail.AddEmbeddedImage	str
		'objNewMail.AddCC				str
		'objNewMail.AddBCC				str

		objNewMail.Send()
					
		if Err <> 0 then
			Response.Write "<center><b>Error: " & Err &  "</b></center>"
		else
			Response.Write "<center><b>Your message was sent successfully<br>" & _
						   "We will contact you shortly</b></center>"
		end if
					

		set objNewMail = Nothing
	else
		Response.Write "<center><b>Your message was sent successfully<br>" & _
					   "We will contact you shortly</b><br>" & _
					   "Not online</center>"
	end if
end sub

sub sendMultiMail(strFrom, strFromName, arrTo(), strSubject, strBody)

	dim strServer, i
	strServer = LCase(Request.ServerVariables("SERVER_NAME"))

	if strServer <> "id-00155" and strServer <> "localhost" then 

		dim objNewMail
		set objNewMail = Server.CreateObject("Persits.MailSender")

		strBody = "<html><body>" & _
				  "<head><style>" & _
				  "BODY {font-family:Verdana,Arial,Helvetica,sans-serif;font-size:10pt;color:black;}" & _
				  "</style></head>" & _
				  "<body link=black vlink=black alink=black>" & Replace(strBody & " ", VbCrlf, "<br>") & _
				  "</body></html>"

		'if strTo = "webmaster" then	strTo = "sebduk@gmail.com"
		'if strFrom = "webmaster" then strFrom = "sebduk@gmail.com"
					
		objNewMail.Host = "mail.iea.org"
		objNewMail.From = strFrom
		objNewMail.FromName = strFromName
		for i = 1 to Ubound(arrTo)
			objNewMail.AddAddress arrTo(i)
		next
		objNewMail.Subject = strSubject
		objNewMail.Body = strBody
		objNewMail.IsHTML = True
		objNewMail.Priority = 3

		'objNewMail.AppendBodyFromFile	str
		'objNewMail.AddAttachment		str
		'objNewMail.AddEmbeddedImage	str
		'objNewMail.AddCC				str
		'objNewMail.AddBCC				str

		objNewMail.Send()
					
		if Err <> 0 then
			Response.Write "<center><b>Error: " & Err &  "</b></center>"
		end if
					

		set objNewMail = Nothing
	else
		Response.Write "<center><b>Your message was sent successfully<br>" & _
					   "Not online</center>"
	end if
end sub
%>