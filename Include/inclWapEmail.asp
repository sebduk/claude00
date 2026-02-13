<%
Sub SendEmailWap(strSubject, strBody, strAddress, strAtt)
	Dim objMail
	Set objMail = Server.CreateObject("Persits.MailSender")

	objMail.Host = "localhost"
	objMail.Port = 29
	objMail.From = session("WebMasterAdd")
	objMail.FromName = session("WebMaster")
	objMail.Subject = strSubject
	objMail.Body = strBody
	objMail.IsHTML = True
	objMail.Priority = 3 '1top/3mid/5low
	objMail.AddAttachment strAtt
	objMail.AddAddress strAddress

on error resume next
	objMail.Send()
on error goto 0

	if Err <> 0 Then
		Response.Write "An Email was not sent"
	   SendEmailWap = "Error: " & Err.Description
	else
	   SendEmailWap = ""
	end if

	Set objMail = Nothing
end sub

Function SendWapmail(strFromName, strFrom, strToName, strTo, strSubject, strBody)
	dim arrTo(), arrToName()
	redim arrTo(0)
	redim arrToName(0)
	
	if strFromName = "" then strFromName = "Automated email"
	if strFrom = "" then strFrom = "info@wisebourne.com"
	
	strTo = Trim(strTo)
	strToName = Trim(strToName)
	if strTo <> "" then
		while instr(strTo, ",") > 0
			redim preserve arrTo(Ubound(arrTo) + 1)
			arrTo(Ubound(arrTo)) = left(strTo, instr(strTo, ","))
			strTo = Trim(mid(strTo, instr(strTo, ",") + 1))
		wend
		redim preserve arrTo(Ubound(arrTo) + 1)
		arrTo(Ubound(arrTo)) = strTo

		while instr(strToName, ",") > 0
			redim preserve arrToName(Ubound(arrToName) + 1)
			arrToName(Ubound(arrToName)) = left(strToName, instr(strToName, ","))
			strToName = Trim(mid(strToName, instr(strToName, ",") + 1))
		wend
		redim preserve arrToName(Ubound(arrToName) + 1)
		arrToName(Ubound(arrToName)) = strToName


		Dim objMail
		Set objMail = Server.CreateObject("Persits.MailSender")

		objMail.Host = "localhost"
		objMail.Port = 29
		objMail.From = strFrom
		objMail.FromName = strFromName
		objMail.Subject = strSubject
		objMail.Body = strBody
		objMail.IsHTML = True
		objMail.Priority = 3 '1top/3mid/5low
		'objMail.AddAttachment strAtt
		for i = 1 to Ubound(arrTo)
			objMail.AddAddress arrTo(i), arrToName(i)
		next
		objMail.AddBCC strFrom, strFromName

on error resume next
		objMail.Send()
on error goto 0

		if Err <> 0 Then
		   SendWapmail = "Error: " & Err.Description
		else
		   SendWapmail = "Email sent successfully"
		end if

		Set objMail = Nothing

	else
		SendWapmail = "Error: no To: address"
	end if
end function
%>
