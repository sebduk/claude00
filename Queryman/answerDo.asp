<%
'"RUN TYPE" QUERY
rs.Open strSQL, conn	

'PRINT QUERY

response.write "<html>"
response.write "<head><link rel=stylesheet type=text/css href=/queryman/style.css></head>"
response.write "<body>"
response.write "<b>" & strSQL & "</b><br><br>"
Response.Write "Query Done"
Response.Write "</body></html>"

'ERRORS
if Err <> 0 then
	response.write "<html>"
	response.write "<head><link rel=stylesheet type=text/css href=/style.css></head>"
	response.write "<body>"
	response.write "<b>" & strSQL & "</b><br><br>"
	Response.Write "Error (" & Err & ") in the query"
	Response.Write "</body></html>"
end if
%>