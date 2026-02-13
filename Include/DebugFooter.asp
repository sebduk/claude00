<%		if Session("DROITS") = "power" then
			DebugPrint strRequest
		end if
	else
		Session("LoginOK") = False
		Redirige Application("strRootPath") & "/default.asp"
	end if %>
