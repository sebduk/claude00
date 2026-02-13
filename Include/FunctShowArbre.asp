Sub ShowCouple(rsShow, Level, NbPos)

	Response.Write &quot;<!-- " & NbPos & " -->&quot;
	Response.Write &quot;<td>&nbsp;&quot; &amp; Application(&quot;BaseFont&quot;)


	if rsShow(&quot;MFamDir&quot;) then
		Response.Write &quot;<a href="arbre.asp?IDPerso=&quot;" & rsShow("MID") & ">&quot; &amp; Application(&quot;ImgLien&quot;) &amp; &quot;</a>&nbsp;&quot;
	end if

	Response.Write &quot;<a href="Comm.asp?ID=&quot;" & rsShow("MID") & " target="comm">&quot; &amp; Application(&quot;ImgComm&quot;)&amp; &quot;</a><br>&quot;

	Response.Write rsShow(&quot;MP&quot;) &amp; &quot;&nbsp;&quot; &amp; rsShow(&quot;MN&quot;) &amp; &quot;<br>&quot;
	Response.Write &quot;(&quot; &amp; rsShow(&quot;MDN&quot;) &amp; &quot;-&quot; &amp; rsShow(&quot;MDD&quot;) &amp; &quot;)&quot;


	Response.Write &quot;</font></td>&quot;
	Response.Write &quot;<td>&nbsp;</td>&quot;
	Response.Write &quot;<td>&nbsp;&quot; &amp; Application(&quot;BaseFont&quot;)


	if rsShow(&quot;FFamDir&quot;) then 
		Response.Write &quot;<a href="arbre.asp?IDPerso=&quot;" & rsShow("FID") & "#point>&quot; &amp; Application(&quot;ImgLien&quot;) &amp; &quot;</a>&nbsp;&quot;
	end if

	Response.Write &quot;<a href="Comm.asp?ID=&quot;" & rsShow("FID") & " target="comm">&quot; &amp; Application(&quot;ImgComm&quot;)&amp; &quot;</a><br>&quot;
	Response.Write rsShow(&quot;FP&quot;) &amp; &quot;&nbsp;&quot; &amp; rsShow(&quot;FN&quot;) &amp; &quot;<br>&quot;
	Response.Write &quot;(&quot; &amp; rsShow(&quot;FDN&quot;) &amp; &quot;-&quot; &amp; rsShow(&quot;FDD&quot;) &amp; &quot;)&quot;


	Response.Write &quot;</font></td>&quot;

End Sub



Sub ShowPerso(rsShow, Level, NbPos)

	Response.Write &quot;<!-- " & NbPos & " -->&quot;
	Response.Write &quot;<td>&nbsp;&quot; &amp; Application(&quot;BaseFont&quot;)

	if rsShow(&quot;MFamDir&quot;) then
		Response.Write &quot;<a href="arbre.asp?IDPerso=&quot;" & rsShow("MID") & ">&quot; &amp; Application(&quot;ImgLien&quot;) &amp; &quot;</a>&nbsp;&quot;
	end if

	Response.Write rsShow(&quot;MP&quot;) &amp; &quot;&nbsp;&quot; &amp; rsShow(&quot;MN&quot;) &amp; &quot;<br>&quot;
	Response.Write &quot;(&quot; &amp; rsShow(&quot;MDN&quot;) &amp; &quot;-&quot; &amp; rsShow(&quot;MDD&quot;) &amp; &quot;)&quot;


	Response.Write &quot;</font></td>&quot;

End Sub






























'*******************************************************************************************************************************

'*******************************************************************************************************************************
Response.Write &quot;<!-- 2 --><td>&nbsp;&quot; &amp; Application(&quot;BaseFont&quot;)																							
if rs02(&quot;MFamDir&quot;) then Response.Write &quot;<a href="arbre.asp?IDPerso=&quot;" & rs02("MID") & "#point>&quot; &amp; Application(&quot;ImgLien&quot;) &amp; &quot;</a>&nbsp;&quot;	
Response.Write &quot;<a href="Comm.asp?ID=&quot;" & rs02("MID") & " target="comm">&quot; &amp; Application(&quot;ImgComm&quot;)&amp; &quot;</a><br>&quot;			
Response.Write rs02(&quot;MP&quot;) &amp; &quot;&nbsp;&quot; &amp; rs02(&quot;MN&quot;) &amp; &quot;<br>&quot;												
Response.Write &quot;(&quot; &amp; rs02(&quot;MDN&quot;) &amp; &quot;-&quot; &amp; rs02(&quot;MDD&quot;) &amp; &quot;)</font></td>&quot;														
																									
Response.Write &quot;<td>&nbsp;</td>&quot;																					
																									
Response.Write &quot;<td>&nbsp;&quot; &amp; Application(&quot;BaseFont&quot;)																							
if rs02(&quot;FFamDir&quot;) then Response.Write &quot;<a href="arbre.asp?IDPerso=&quot;" & rs02("FID") & "#point>&quot; &amp; Application(&quot;ImgLien&quot;) &amp; &quot;</a>&nbsp;&quot;	
Response.Write &quot;<a href="Comm.asp?ID=&quot;" & rs02("FID") & " target="comm">&quot; &amp; Application(&quot;ImgComm&quot;)&amp; &quot;</a><br>&quot;			
Response.Write rs02(&quot;FP&quot;) &amp; &quot;&nbsp;&quot; &amp; rs02(&quot;FN&quot;) &amp; &quot;<br>&quot;												
Response.Write &quot;(&quot; &amp; rs02(&quot;FDN&quot;) &amp; &quot;-&quot; &amp; rs02(&quot;FDD&quot;) &amp; &quot;)</font></td>&quot;														
'*******************************************************************************************************************************

'*******************************************************************************************************************************
Response.Write &quot;<!-- 3 --><td align="right" colspan="3"><hr size="1" noshade><table border="0" cellpadding="0" cellspacing="0"><tr><td align="center">&quot;
if rs0(&quot;MFamDir&quot;) then Response.Write &quot;<a href="arbre.asp?IDPerso=&quot;" & rs0("MID") & "#point>&quot; &amp; Application(&quot;ImgLien&quot;) &amp; &quot;</a>&quot;	
Response.Write &quot;&nbsp;<a href="Comm.asp?ID=&quot;" & rs0("MID") & " target="comm">&quot; &amp; Application(&quot;ImgComm&quot;)&amp; &quot;</a><br>&quot;			
Response.Write Application(&quot;BaseFont&quot;) &amp; &quot;<b>&quot; &amp; rs0(&quot;MP&quot;) &amp; &quot;&nbsp;&quot; &amp; rs0(&quot;MN&quot;) &amp; &quot;<br>&quot;														
Response.Write &quot;(&quot; &amp; rs0(&quot;MDN&quot;) &amp; &quot;-&quot; &amp; rs0(&quot;MDD&quot;) &amp; &quot;)</b></font></td></tr></table></td>&quot;										
																									
Response.Write &quot;<td><a name point""></td>&quot;																						
																									
Response.Write &quot;<td colspan="3"><hr size="1" noshade><table border="0" cellpadding="0" cellspacing="0"><tr><td align="center">&quot;		
if rs0(&quot;FFamDir&quot;) then Response.Write &quot;<a href="arbre.asp?IDPerso=&quot;" & rs0("FID") & "#point>&quot; &amp; Application(&quot;ImgLien&quot;) &amp; &quot;</a>&quot;	
Response.Write &quot;&nbsp;<a href="Comm.asp?ID=&quot;" & rs0("FID") & " target="comm">&quot; &amp; Application(&quot;ImgComm&quot;)&amp; &quot;</a><br>&quot;			
Response.Write Application(&quot;BaseFont&quot;) &amp; &quot;<b>&quot; &amp; rs0(&quot;FP&quot;) &amp; &quot;&nbsp;&quot; &amp; rs0(&quot;FN&quot;) &amp; &quot;<br>&quot;														
Response.Write &quot;(&quot; &amp; rs0(&quot;FDN&quot;) &amp; &quot;-&quot; &amp; rs0(&quot;FDD&quot;) &amp; &quot;)</b></font></td></tr></table></td>&quot;										
'*******************************************************************************************************************************


'*******************************************************************************************************************************
Response.Write &quot;<!-- 4 --><td><table border="0" cellspacing="0" cellpadding="0"><tr>&quot;											
																									
Response.Write &quot;<td align="right"><table border="0" cellspacing="0" cellpadding="0"><tr valign="to" align="center">&quot;		
Response.Write &quot;<td>&nbsp;&quot; &amp; Application(&quot;BaseFont&quot;)
if rs2(&quot;MFamDir&quot;) then Response.Write &quot;<a href="arbre.asp?IDPerso=&quot;" & rs2("MID") & "#point>&quot; &amp; Application(&quot;ImgLien&quot;) &amp; &quot;</a>&nbsp;&quot;
Response.Write &quot;<a href="Comm.asp?ID=&quot;" & rs2("MID") & " target="comm">&quot; &amp; Application(&quot;ImgComm&quot;)&amp; &quot;</a><br>&quot;		
Response.Write rs2(&quot;MP&quot;) &amp; &quot;&nbsp;&quot; &amp; rs2(&quot;MN&quot;) &amp; &quot;<br>&quot;														
Response.Write &quot;(&quot; &amp; rs2(&quot;MDN&quot;) &amp; &quot;-&quot; &amp; rs2(&quot;MDD&quot;) &amp; &quot;)</font></td></tr></table></td>&quot;									
																									
Response.Write &quot;<td>&nbsp;</td>&quot;																				
																									
Response.Write &quot;<td><table border="0" cellspacing="0" cellpadding="0"><tr valign="to" align="center">&quot;					
Response.Write &quot;<td>&nbsp;&quot; &amp; Application(&quot;BaseFont&quot;)																						
if rs2(&quot;FFamDir&quot;) then Response.Write &quot;<a href="arbre.asp?IDPerso=&quot;" & rs2("FID") & "#point>&quot; &amp; Application(&quot;ImgLien&quot;) &amp; &quot;</a>&nbsp;&quot;		
Response.Write &quot;<a href="Comm.asp?ID=&quot;" & rs2("FID") & " target="comm">&quot; &amp; Application(&quot;ImgComm&quot;)&amp; &quot;</a><br>&quot;		
Response.Write rs2(&quot;FP&quot;) &amp; &quot;&nbsp;&quot; &amp; rs2(&quot;FN&quot;) &amp; &quot;<br>&quot;														
Response.Write &quot;(&quot; &amp; rs2(&quot;FDN&quot;) &amp; &quot;-&quot; &amp; rs2(&quot;FDD&quot;) &amp; &quot;)</font></td></tr></table></td>&quot;									
																									
Response.Write &quot;</tr><tr><td colspan="3" align="center"><hr size="1" noshade>&quot;														
Response.Write &quot;<table border="0"><tr align="center" valign="top">&quot;													
'*******************************************************************************************************************************

'*******************************************************************************************************************************
Response.Write &quot;<!-- 5 --><td align="right"><table border="0" cellspacing="0" cellpadding="0"><tr valign="to" align="center">&quot;	
Response.Write &quot;<td><a href="arbre.asp?IDPerso=&quot;" & rs3("IDPersonne") & "#point>&quot; &amp; Application(&quot;ImgLien&quot;) &amp; &quot;</a>&nbsp;&quot;
Response.Write &quot;<a href="Comm.asp?ID=&quot;" & rs3("IDPersonne") & " target="comm">&quot; &amp; Application(&quot;ImgComm&quot;)&amp; &quot;</a><br>&quot;
Response.Write Application(&quot;BaseFont&quot;) &amp; &quot;<i>~&quot; &amp; rs3(&quot;Prenom&quot;) &amp; &quot;&nbsp;&quot; &amp; rs3(&quot;Nom&quot;) &amp; &quot;~<br>&quot;										
Response.Write &quot;(&quot; &amp; rs3(&quot;DtNaiss&quot;) &amp; &quot;-&quot; &amp; rs3(&quot;DtDec&quot;) &amp; &quot;)</i></font></td></tr></table></td>&quot;					
'*******************************************************************************************************************************

'*******************************************************************************************************************************
Response.Write &quot;<!-- 6 --><td align="right"><table border="0" cellspacing="0" cellpadding="0"><tr valign="to" align="center">&quot;		
Response.Write &quot;<td><a href="arbre.asp?IDPerso=&quot;" & rs2("MID") & "#point>&quot; &amp; Application(&quot;ImgLien&quot;) &amp; &quot;</a>&nbsp;&quot;		
Response.Write &quot;<a href="Comm.asp?ID=&quot;" & rs2("MID") & " target="comm">&quot; &amp; Application(&quot;ImgComm&quot;)&amp; &quot;</a><br>&quot;		
Response.Write Application(&quot;BaseFont&quot;) &amp; &quot;&nbsp;&quot; &amp; rs2(&quot;MP&quot;) &amp; &quot;&nbsp;&quot; &amp; rs2(&quot;MN&quot;) &amp; &quot;&nbsp;<br>&quot;										
Response.Write &quot;(&quot; &amp; rs2(&quot;MDN&quot;) &amp; &quot;-&quot; &amp; rs2(&quot;MDD&quot;) &amp; &quot;)</font></td></tr></table></td>&quot;									
'*******************************************************************************************************************************

'*******************************************************************************************************************************
Response.Write &quot;<!-- 7 --><td>&nbsp;&quot;																							
if rs01(&quot;MFamDir&quot;) then	Response.Write &quot;<a href="arbre.asp?IDPerso=&quot;" & rs01("MID") & "#point>&quot; &amp; Application(&quot;ImgLien&quot;) &amp; &quot;</a>&nbsp;&quot;
Response.Write &quot;<a href="Comm.asp?ID=&quot;" & rs01("MID") & " target="comm">&quot; &amp; Application(&quot;ImgComm&quot;)&amp; &quot;</a><br>&quot;			
Response.Write Application(&quot;BaseFont&quot;) &amp; rs01(&quot;MP&quot;) &amp; &quot;&nbsp;&quot; &amp; rs01(&quot;MN&quot;) &amp; &quot;<br>&quot;												
Response.Write &quot;(&quot; &amp; rs01(&quot;MDN&quot;) &amp; &quot;-&quot; &amp; rs01(&quot;MDD&quot;) &amp; &quot;)</font></td>&quot;														
																									
Response.Write &quot;<td>&nbsp;</td>&quot;																					
																									
Response.Write &quot;<td>&nbsp;&quot;																							
if rs01(&quot;FFamDir&quot;) then	Response.Write &quot;<a href="arbre.asp?IDPerso=&quot;" & rs01("FID") & "#point>&quot; &amp; Application(&quot;ImgLien&quot;) &amp; &quot;</a>&nbsp;&quot;
Response.Write &quot;<a href="Comm.asp?ID=&quot;" & rs01("FID") & " target="comm">&quot; &amp; Application(&quot;ImgComm&quot;)&amp; &quot;</a><br>&quot;			
Response.Write Application(&quot;BaseFont&quot;) &amp; rs01(&quot;FP&quot;) &amp; &quot;&nbsp;&quot; &amp; rs01(&quot;FN&quot;) &amp; &quot;<br>&quot;												
Response.Write &quot;(&quot; &amp; rs01(&quot;FDN&quot;) &amp; &quot;-&quot; &amp; rs01(&quot;FDD&quot;) &amp; &quot;)</font></td>&quot;														
'*******************************************************************************************************************************

'*******************************************************************************************************************************
Response.Write &quot;<!-- 8 --><td align="center" colspan="3">&quot; &amp; Application(&quot;BaseFont&quot;)																			
if rs0(&quot;MFamDir&quot;) then Response.Write &quot;<a href="arbre.asp?IDPerso=&quot;" & rs0("MID") & "#point>&quot; &amp; Application(&quot;ImgLien&quot;) &amp; &quot;</a>&quot;	
Response.Write &quot;&nbsp;<a href="Comm.asp?ID=&quot;" & rs0("MID") & " target="comm">&quot; &amp; Application(&quot;ImgComm&quot;) &amp; &quot;</a><br>&quot;				
Response.Write &quot;<b>&quot; &amp; rs0(&quot;MP&quot;) &amp; &quot; &quot; &amp; rs0(&quot;MN&quot;) &amp; &quot;<br>&quot;																
Response.Write &quot;(&quot; &amp; rs0(&quot;MDN&quot;) &amp; &quot;-&quot; &amp; rs0(&quot;MDD&quot;) &amp; &quot;)</b></td>&quot;														
'*******************************************************************************************************************************
