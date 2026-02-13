<%@ Language=VBScript %>

<%
dim arrPub(), arrPrint(), i, intRND, reloadTime
redim arrPub(3, 0)
redim arrPrint(2, 0)
reloadTime = 60

'120x600 120x240 160x600 180x150 234x60 250x250 300x250 336x280 468x60 728x90

i = Ubound(arrPub, 2) + 1 : redim preserve arrPub(3, i)
arrPub(1, i) = "120x600" : arrPub(2, i) = "120-600.gif" : arrPub(3, i) = "http://www.google.com"

i = Ubound(arrPub, 2) + 1 : redim preserve arrPub(3, i)
arrPub(1, i) = "120x600" : arrPub(2, i) = "120x600.gif" : arrPub(3, i) = "http://www.google.com"

i = Ubound(arrPub, 2) + 1 : redim preserve arrPub(3, i)
arrPub(1, i) = "120x600" : arrPub(2, i) = "120x600.jpg" : arrPub(3, i) = "http://www.google.com"

i = Ubound(arrPub, 2) + 1 : redim preserve arrPub(3, i)
arrPub(1, i) = "120x240" : arrPub(2, i) = "120x240.gif" : arrPub(3, i) = "http://www.google.com"

i = Ubound(arrPub, 2) + 1 : redim preserve arrPub(3, i)
arrPub(1, i) = "160x600" : arrPub(2, i) = "160x600.gif" : arrPub(3, i) = "http://www.google.com"

i = Ubound(arrPub, 2) + 1 : redim preserve arrPub(3, i)
arrPub(1, i) = "180x150" : arrPub(2, i) = "180x150.gif" : arrPub(3, i) = "http://www.google.com"

i = Ubound(arrPub, 2) + 1 : redim preserve arrPub(3, i)
arrPub(1, i) = "234x60" : arrPub(2, i) = "234-60.gif" : arrPub(3, i) = "http://www.google.com"

i = Ubound(arrPub, 2) + 1 : redim preserve arrPub(3, i)
arrPub(1, i) = "234x60" : arrPub(2, i) = "234x60.gif" : arrPub(3, i) = "http://www.google.com"

i = Ubound(arrPub, 2) + 1 : redim preserve arrPub(3, i)
arrPub(1, i) = "250x250" : arrPub(2, i) = "250x250.gif" : arrPub(3, i) = "http://www.google.com"

i = Ubound(arrPub, 2) + 1 : redim preserve arrPub(3, i)
arrPub(1, i) = "300x250" : arrPub(2, i) = "300x250.jpg" : arrPub(3, i) = "http://www.google.com"

i = Ubound(arrPub, 2) + 1 : redim preserve arrPub(3, i)
arrPub(1, i) = "300x250" : arrPub(2, i) = "300x250.gif" : arrPub(3, i) = "http://www.google.com"

i = Ubound(arrPub, 2) + 1 : redim preserve arrPub(3, i)
arrPub(1, i) = "336x280" : arrPub(2, i) = "336x280.gif" : arrPub(3, i) = "http://www.google.com"

i = Ubound(arrPub, 2) + 1 : redim preserve arrPub(3, i)
arrPub(1, i) = "468x60" : arrPub(2, i) = "468x60.jpg" : arrPub(3, i) = "http://www.google.com"

i = Ubound(arrPub, 2) + 1 : redim preserve arrPub(3, i)
arrPub(1, i) = "468x60" : arrPub(2, i) = "468x60.gif" : arrPub(3, i) = "http://www.google.com"

i = Ubound(arrPub, 2) + 1 : redim preserve arrPub(3, i)
arrPub(1, i) = "468x60" : arrPub(2, i) = "468-60.gif" : arrPub(3, i) = "http://www.google.com"

i = Ubound(arrPub, 2) + 1 : redim preserve arrPub(3, i)
arrPub(1, i) = "728x90" : arrPub(2, i) = "728x90.jpg" : arrPub(3, i) = "http://www.google.com"

i = Ubound(arrPub, 2) + 1 : redim preserve arrPub(3, i)
arrPub(1, i) = "728x90" : arrPub(2, i) = "728x90.gif" : arrPub(3, i) = "http://www.google.com"

i = Ubound(arrPub, 2) + 1 : redim preserve arrPub(3, i)
arrPub(1, i) = "120x600" : arrPub(2, i) = "cepu.gif" : arrPub(3, i) = "http://www.google.com"

i = Ubound(arrPub, 2) + 1 : redim preserve arrPub(3, i)
arrPub(1, i) = "468x60" : arrPub(2, i) = "meridiana.gif" : arrPub(3, i) = "http://www.google.com"

'i = Ubound(arrPub, 2) + 1 : redim arrPub(2, i)
'arrPub(1, i) = "" : arrPub(2, i) = ""

Response.Write "<html>"
Response.Write "<head>"
Response.Write "<meta http-equiv=""Refresh"" content=""" & reloadTime & ";URL=/Pub/pub.asp"
if Request("Size") <> empty then
	Response.Write "?Size=" & Request("Size")
end if
Response.Write """>"
Response.Write "</head>"

Response.Write "<body topmargin=0 leftmargin=0 rightmargin=0 bottommargin=0 bgcolor=silver>"
Response.Write "<center>"

if Request("Size") <> empty then
	for i = 1 to Ubound(arrPub, 2)
		if arrPub(1, i) = Request("Size") then
			redim preserve arrPrint(2, Ubound(arrPrint, 2) + 1)
			arrPrint(1, Ubound(arrPrint, 2)) = arrPub(2, i)
			arrPrint(2, Ubound(arrPrint, 2)) = arrPub(3, i)
		end if
	next
end if

if Ubound(arrPrint, 2) > 0 then
	randomize
	intRND = int(rnd() * Ubound(arrPrint, 2)) + 1
	Response.Write "<a href=" & arrPrint(2, intRND) & " target=_blank>"
	Response.Write "<img src=/Pub/" & arrPrint(1, intRND) & " border=0>"
	Response.Write "</a>"
end if

Response.Write "</center>"
Response.Write "</body>"
Response.Write "</html>"
%>
