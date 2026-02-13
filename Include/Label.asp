<%
dim strFullAscendance, strFullDescendance, strFullVersionWarning, strLastIn
dim strClassicVersion, strHorizontalVersion, strVerticalVersion, strTableVersion, strExcelVersion
dim strBornInM, strBornInF, strDiedInM, strDiedInF
dim strClose, strSearch
dim strCouple, strBiography, strComments, strPictures, strDocuments, strWith, strBack, strTop
dim strFileName, strDate, strParticipants, strSize, strUploaded

dim arrMonth()
redim arrMonth(12)

dim strMenuHome, strMenuGenealogy, strMenuNames, strMenuYears, strMenuCalendar, strMenuPictures
dim strMenuDocs, strMenuIntro
dim strMenuHelp, strMenuLogin, strMenuAdmin, strMenuUpdate, strMenuPeople, strMenuCouple
dim strMenuComments, strMenuMessage
dim strMessPerso, strMessSubject, strMessFrom, strMessSend, strMessEmail, strMessTo, strMessAll
dim strWarningSubject, strWarningFrom, strWarningEmail, strWarningBody, strWarningTo

dim strIndividuals, strCalendarWarning, strPicturesAll
dim strLoginMessage, strPassword, strHelpUser, strHelpTech, strFooter
dim strLangOptions, strLangOptPrem

strLangOptions = "<a href=/frameDom.asp?Language=ENG target=_parent>English</a> | " & _
				 "<a href=/frameDom.asp?Language=FRA target=_parent>Fran&ccedil;ais</a> | " & _
				 "<a href=/frameDom.asp?Language=ESP target=_parent>Espa&ntilde;ol</a> | " & _
				 "<a href=/frameDom.asp?Language=ITA target=_parent>Italiano</a> | " & _
				 "<a href=/frameDom.asp?Language=POR target=_parent>Portugu&ecirc;s</a> | " & _
				 "<a href=/frameDom.asp?Language=DEU target=_parent>Deutsch</a> | " & _
				 "<a href=/frameDom.asp?Language=NLD target=_parent>Nederlands</a><br>"

strLangOptPrem = "<a href=/p.frame.asp?Language=ENG target=_parent>English</a> | " & _
				 "<a href=/p.frame.asp?Language=FRA target=_parent>Fran&ccedil;ais</a> | " & _
				 "<a href=/p.frame.asp?Language=ESP target=_parent>Espa&ntilde;ol</a> | " & _
				 "<a href=/p.frame.asp?Language=ITA target=_parent>Italiano</a> | " & _
				 "<a href=/p.frame.asp?Language=POR target=_parent>Portugu&ecirc;s</a> | " & _
				 "<a href=/p.frame.asp?Language=DEU target=_parent>Deutsch</a> | " & _
				 "<a href=/p.frame.asp?Language=NLD target=_parent>Nederlands</a><br>"


select case strLanguage
	case "ENG"
		strLastIn = "Last updates"

		strFullAscendance = "View All Parents"
		strFullDescendance = "View All Children"
		strClassicVersion = "Classic"
		strHorizontalVersion = "Horizontal"
		strVerticalVersion = "Vertical"
		strTableVersion = "Table"
		strExcelVersion = "Excel"
		strFullVersionWarning = "These versions require heavier processing.<br>Be patient!"

		strBornInM = "Born in"
		strBornInF = "Born in"
		strDiedInM = "Died in"
		strDiedInF = "Died in"
		strSearch = "Search"
		strClose = "Close"
		strCouple = "Couple"
		strBiography = "Biography"
		strComments = "Comments"
		strPictures = "Pictures"
		strDocuments = "Documents"
		strWith = "With"
		strBack = "Back"
		strTop = "top"
		
		arrMonth(01) = "January"
		arrMonth(02) = "February"
		arrMonth(03) = "March"
		arrMonth(04) = "April"
		arrMonth(05) = "May"
		arrMonth(06) = "June"
		arrMonth(07) = "July"
		arrMonth(08) = "August"
		arrMonth(09) = "September"
		arrMonth(10) = "October"
		arrMonth(11) = "November"
		arrMonth(12) = "December"
		
		strMenuHome = "<b>h</b>ome"
		strMenuGenealogy = "<b>g</b>enealogy by"
		strMenuNames = "<b>n</b>ames"
		strMenuYears = "<b>y</b>ears"
		strMenuCalendar = "<b>b</b>irthdays"
		strMenuPictures = "<b>p</b>ictures"
		strMenuDocs = "<b>d</b>ocuments"
		strMenuIntro = "<b>i</b>ntro"
		strMenuHelp = "<b>h</b>elp"
		strMenuLogin = "<b>l</b>ogin"
		strMenuAdmin = "<b>a</b>dmin"
		strMenuUpdate = "<b>u</b>pdate"
		strMenuPeople = "<b>p</b>eople"
		strMenuCouple = "<b>c</b>ouples"
		strMenuComments = "<b>c</b>omments"
		strMenuMessage = "<b>m</b>essages"

		strMessAll = "All Messages"
		strMessPerso = "Personal Messages"
		strMessSubject = "Subject"
		strMessFrom = "From"
		strMessTo = "To"
		strMessSend = "Send"
		strMessEmail = "Email"
		strWarningSubject = "Please enter a Subject"
		strWarningFrom = "Please enter a your name in From"
		strWarningEmail = "Please enter an Email"
		strWarningBody = "Please enter a Message"
		strWarningTo = "Please select one or more people to send the message To"

		strFileName = "File Name"
		strDate = "Date"
		strParticipants = "Participants"
		strSize = "Size"
		strUploaded = "Uploaded"

		strIndividuals = "Individuals"
		strCalendarWarning = "Only individuals for whom a precise birthdate is known are listed"
		strPicturesAll = "View all pictures"
		strLoginMessage = "Login to broaden the menu and gain access to the update functions.<br>(you will be automatically logged off if you close your browser)"
		strPassword = "Password"

		strHelpUser = "User.eng.asp"
		strHelpTech = "Tech.eng.asp"

		strFooter = "<hr noShade size=1><p>" & _
					"For all information contact <a href=mailto:sebduk@gmail.com>sebduk@gmail.com</a><br><br>" & _
					"<b>Links:</b><br>" & _
					"<a href=User.eng.asp>User guide</a><br>" & _
					"<br>" & _
					strLangOptions & _
					"Would you like to see this site translated in your language?<br>" & _
					"Write to <a href=mailto:sebduk@gmail.com>sebduk@gmail.com</a>." & _
					"</p><hr noShade size=1>"


	case "ESP"
		strLastIn = "Ultimas modificaciones"

		strFullAscendance = "Ver todos los Padres"
		strFullDescendance = "Ver todos los Hijos"
		strClassicVersion = "Classico"
		strHorizontalVersion = "Horizontal"
		strVerticalVersion = "Vertical"
		strTableVersion = "Tabla"
		strExcelVersion = "Excel"
		strFullVersionWarning = "Versiones pesadas.<br>Sea paciente!"

		strBornInM = "Nacido en"
		strBornInF = "Nacida en"
		strDiedInM = "Fallecido en"
		strDiedInF = "Fallecida en"
		strSearch = "Busca"
		strClose = "Cerrar"
		strCouple = "Pareja"
		strBiography = "Biografia"
		strComments = "Comentarios"
		strPictures = "Fotos"
		strDocuments = "Documentos"
		strWith = "Con"
		strBack = "Anterior"
		strTop = "top"

		arrMonth(01) = "enero"
		arrMonth(02) = "febrero"
		arrMonth(03) = "marzo"
		arrMonth(04) = "abril"
		arrMonth(05) = "mayo"
		arrMonth(06) = "junio"
		arrMonth(07) = "julio"
		arrMonth(08) = "agosto"
		arrMonth(09) = "septiembre"
		arrMonth(10) = "octubre"
		arrMonth(11) = "noviembre"
		arrMonth(12) = "diciembre"

		strMenuHome = "<b>i</b>nicio"
		strMenuGenealogy = "<b>g</b>enealogia por"
		strMenuNames = "<b>n</b>ombres"
		strMenuYears = "<b>a</b>&ntilde;os"
		strMenuCalendar = "<b>c</b>umplea&ntilde;os"
		strMenuPictures = "<b>f</b>otos"
		strMenuDocs = "<b>d</b>ocumentos"
		strMenuIntro = "<b>i</b>ntro"
		strMenuHelp = "<b>a</b>yuda"
		strMenuLogin = "<b>c</b>onecc&iacute;on"
		strMenuAdmin = "<b>a</b>dmin"
		strMenuUpdate = "<b>m</b>odificar las"
		strMenuPeople = "<b>p</b>ersonas"
		strMenuCouple = "<b>p</b>arejas"
		strMenuComments = "<b>c</b>omentarios"
		strMenuMessage = "<b>m</b>ensages"

		strMessAll = "Todos los Messages"
		strMessPerso = "Mensajes Personales"
		strMessSubject = "Titulo"
		strMessFrom = "De"
		strMessTo = "A"
		strMessSend = "Enviar"
		strMessEmail = "Email"
		strWarningSubject = "Please enter a Subject"
		strWarningFrom = "Please enter a your name in From"
		strWarningEmail = "Please enter an Email"
		strWarningBody = "Please enter a Message"
		strWarningTo = "Please select one or more people to send the message To"

		strFileName = "Fichero"
		strDate = "Fecha"
		strParticipants = "Participantes"
		strSize = "Talla"
		strUploaded = "A&ntilde;ido"

		strIndividuals = "Personas"
		strCalendarWarning = "Solo las personas para las quales se recuerda una fecha de nacimiento exacta aparencen en la lista"
		strPicturesAll = "Todas las Fotos"
		strLoginMessage = "conectase para modificar el menu y ganar aceso a las modificaciones.<br>(sera desconectado automaticamente al cerrar su browser)"
		strPassword = "contrase&ntilde;a"

		strHelpUser = "User.eng.asp"
		strHelpTech = "Tech.eng.asp"

		strFooter = "<hr noShade size=1><p>" & _
					"Para qualquier informac&iacute;on contacta <a href=mailto:sebduk@gmail.com>sebduk@gmail.com</a><br><br>" & _
					"<b>Enlaces:</b><br>" & _
					"<a href=User.eng.asp>Gu&iacute;a del usuario</a><br>" & _
					"<br>" & _
					strLangOptions & _
					"&iquest;Quiziera ver este sitio en su idioma?<br>" & _
					"Escriba a <a href=mailto:sebduk@gmail.com>sebduk@gmail.com</a>." & _
					"</p><hr noShade size=1>"


	case "ITA"
		strLastIn = "Ultimo aggiornamento"

		strFullAscendance = "Tutti Genitori"
		strFullDescendance = "Tutti Figli"
		strClassicVersion = "Classico"
		strHorizontalVersion = "Horizontale"
		strVerticalVersion = "Verticale"
		strTableVersion = "Tabella"
		strExcelVersion = "Excel"
		strFullVersionWarning = "Processi pesanti.<br>Sia paziente!"

		strBornInM = "Nato a"
		strBornInF = "Nata a"
		strDiedInM = "Morto a"
		strDiedInF = "Morta a"
		strSearch = "Cerca"
		strClose = "Chiudere"
		strCouple = "Coppia"
		strBiography = "Biografia"
		strComments = "Commentari"
		strPictures = "Fotos"
		strDocuments = "Documenti"
		strWith = "Con"
		strBack = "Anteriore"
		strTop = "top"

		arrMonth(01) = "gennaio"
		arrMonth(02) = "febbraio"
		arrMonth(03) = "marzo"
		arrMonth(04) = "aprile"
		arrMonth(05) = "maggio"
		arrMonth(06) = "giugno"
		arrMonth(07) = "luglio"
		arrMonth(08) = "agosto"
		arrMonth(09) = "settembre"
		arrMonth(10) = "ottobre"
		arrMonth(11) = "novembre"
		arrMonth(12) = "dicembre"
		
		strMenuHome = "<b>h</b>ome"
		strMenuGenealogy = "<b>g</b>enealogia per"
		strMenuNames = "<b>n</b>ome"
		strMenuYears = "<b>a</b>nno"
		strMenuCalendar = "<b>c</b>ompleanno"
		strMenuPictures = "<b>f</b>oto"
		strMenuDocs = "<b>d</b>ocumento"
		strMenuIntro = "<b>i</b>ntro"
		strMenuHelp = "<b>a</b>iuto"
		strMenuLogin = "<b>l</b>ogin"
		strMenuAdmin = "<b>a</b>dmin"
		strMenuUpdate = "<b>a</b>ggiornare le"
		strMenuPeople = "<b>p</b>ersone"
		strMenuCouple = "<b>c</b>oppie"
		strMenuComments = "<b>c</b>ommentari"
		strMenuMessage = "<b>m</b>essagio"

		strMessAll = "Tutti Messagi"
		strMessPerso = "Messagi Personali"
		strMessSubject = "Tittolo"
		strMessFrom = "Di"
		strMessTo = "A"
		strMessSend = "Send"
		strMessEmail = "Email"
		strWarningSubject = "Please enter a Subject"
		strWarningFrom = "Please enter a your name in From"
		strWarningEmail = "Please enter an Email"
		strWarningBody = "Please enter a Message"
		strWarningTo = "Please select one or more people to send the message To"

		strFileName = "File Name"
		strDate = "Data"
		strParticipants = "Participanti"
		strSize = "Size"
		strUploaded = "Uploaded"

		strIndividuals = "Personne"
		strCalendarWarning = "Soltanto le persone per quale una data di nascita precisa è conosciuta sono elencati"
		strPicturesAll = "Tutte le Fotos"
		strLoginMessage = "Login per cambiare il menu ed avere accesso al sitio o all'aggiornamento."
		strPassword = "Password" '"Parola d'Accesso"

		strHelpUser = "User.eng.asp"
		strHelpTech = "Tech.eng.asp"

		strFooter = "<hr noShade size=1><p>" & _
					"Per tutte informazioni, contattare <a href=mailto:sebduk@gmail.com>sebduk@gmail.com</a><br><br>" & _
					"<b>Collegamenti:</b><br>" & _
					"<a href=User.eng.asp>Guida dell'utente</a><br>" & _
					"<br>" & _
					strLangOptions & _
					"Desiderate vedere questo sito nella sua lingua?<br>" & _
					"Scriva a <a href=mailto:sebduk@gmail.com>sebduk@gmail.com</a>." & _
					"</p><hr noShade size=1>"


	case "POR"
		strLastIn = "Ultimas modifica&ccedil;oes"

		strFullAscendance = "Veja todos os Pais"
		strFullDescendance = "Veja todas as Crian&ccdil;as"
		strClassicVersion = "Classico"
		strHorizontalVersion = "Horizontal"
		strVerticalVersion = "Vertical"
		strTableVersion = "Tabela"
		strExcelVersion = "Excel"
		strFullVersionWarning = "Estas versões requerem um processo pesado.<br>Seja paciente!"

		strBornInM = "Nascido em"
		strBornInF = "Nascida em"
		strDiedInM = "Falecido em"
		strDiedInF = "Falecida em"
		strSearch = "Busca"
		strClose = "Fechar"
		strCouple = "Casal"
		strBiography = "Biografia"
		strComments = "Commentarios"
		strPictures = "Fotos"
		strDocuments = "Documentos"
		strWith = "Com"
		strBack = "Anterior"
		strTop = "top"

		arrMonth(01) = "Janeiro"
		arrMonth(02) = "Fevereiro"
		arrMonth(03) = "Mar&ccedil;o"
		arrMonth(04) = "Abril"
		arrMonth(05) = "Maio"
		arrMonth(06) = "Junho"
		arrMonth(07) = "Julho"
		arrMonth(08) = "Agosto"
		arrMonth(09) = "Setembro"
		arrMonth(10) = "Outubro"
		arrMonth(11) = "Novembro"
		arrMonth(12) = "Dezembro"
		
		strMenuHome = "<b>h</b>ome"
		strMenuGenealogy = "<b>g</b>enealogia por"
		strMenuNames = "<b>n</b>omes"
		strMenuYears = "<b>a</b>nhos"
		strMenuCalendar = "<b>a</b>nivers&aacute;rios"
		strMenuPictures = "<b>f</b>otos"
		strMenuDocs = "<b>d</b>ocumentos"
		strMenuIntro = "<b>i</b>ntro"
		strMenuHelp = "<b>a</b>juda"
		strMenuLogin = "<b>l</b>ogin"
		strMenuAdmin = "<b>a</b>dmin"
		strMenuUpdate = "<b>m</b>odificar"
		strMenuPeople = "<b>p</b>essoas"
		strMenuCouple = "<b>c</b>asais"
		strMenuComments = "<b>c</b>ommentarios"
		strMenuMessage = "<b>m</b>essajems"

		strMessAll = "Toudos Messages"
		strMessPerso = "Messajems Pesoias"
		strMessSubject = "T&igrave;tulo"
		strMessFrom = "De"
		strMessTo = "A"
		strMessSend = "Send"
		strMessEmail = "Email"
		strWarningSubject = "Please enter a Subject"
		strWarningFrom = "Please enter a your name in From"
		strWarningEmail = "Please enter an Email"
		strWarningBody = "Please enter a Message"
		strWarningTo = "Please select one or more people to send the message To"

		strFileName = "File Name"
		strDate = "Date"
		strParticipants = "Participantes"
		strSize = "Size"
		strUploaded = "Uploaded"

		strIndividuals = "Pessoas"
		strCalendarWarning = "Somente os indiv&iacute;duos para quem uma data de nascimento precisa &eacute; conocida aparecem na lista"
		strPicturesAll = "Todas as fotos"
		strLoginMessage = "Conecta para ganar alacance as fun&ccedil;&otilde;es de modifica&ccedil;&atilde;o.<br>(Ser&aacute; desconectado automaticamente ao fechar do seu browser)"
		strPassword = "Senha"

		strHelpUser = "User.eng.asp"
		strHelpTech = "Tech.eng.asp"

		strFooter = "<hr noShade size=1><p>" & _
					"Para touda informa&ccedil;&atilde;o, contacte <a href=mailto:sebduk@gmail.com>sebduk@gmail.com</a><br><br>" & _
					"<b>Liga&ccedil;&otilde;es:</b><br>" & _
					"<a href=User.eng.asp>Guia do usu&aacute;rio</a><br>" & _
					"<br>" & _
					strLangOptions & _
					"Gostaria de ver este sitio traduzido na sua l&iacute;ngua?<br>" & _
					"Escreva a <a href=mailto:sebduk@gmail.com>sebduk@gmail.com</a>." & _
					"</p><hr noShade size=1>"


	case "DEU"
		strLastIn = "Last updates"

		strFullAscendance = "Alle Vorfahren"
		strFullDescendance = "Alle Nachfahren"
		strClassicVersion = "Classic"
		strHorizontalVersion = "Horizontale"
		strVerticalVersion = "Vertikale"
		strTableVersion = "Tabelle"
		strExcelVersion = "Excel"
		strFullVersionWarning = "Diese Versionen erfordern schwereren Proze&szlig;.<br>Seien Sie geduldig!"

		strBornInM = "Geboren in"
		strBornInF = "Geboren in"
		strDiedInM = "Gestorben in"
		strDiedInF = "Gestorben in"
		strSearch = "Suche"
		strClose = "Schliessen"
		strCouple = "Par"
		strBiography = "Biographie"
		strComments = "Anmerkungen"
		strPictures = "Bilder"
		strDocuments = "Dokumenten"
		strWith = "Mit"
		strBack = "Back"
		strTop = "top"

		arrMonth(01) = "Januar"
		arrMonth(02) = "Februar"
		arrMonth(03) = "M&auml;rz"
		arrMonth(04) = "April"
		arrMonth(05) = "Mai"
		arrMonth(06) = "Juni"
		arrMonth(07) = "Juli"
		arrMonth(08) = "August"
		arrMonth(09) = "September"
		arrMonth(10) = "Oktober"
		arrMonth(11) = "November"
		arrMonth(12) = "Dezember"
		
		strMenuHome = "<b>h</b>ome"
		strMenuGenealogy = "<b>G</b>enealogie pro"
		strMenuNames = "<b>N</b>amen"
		strMenuYears = "<b>J</b>ahre"
		strMenuCalendar = "<b>G</b>eburtstag"
		strMenuPictures = "<b>B</b>ilder"
		strMenuDocs = "<b>D</b>okumenten"
		strMenuIntro = "<b>I</b>ntro"
		strMenuHelp = "<b>H</b>ilfe"
		strMenuLogin = "<b>L</b>ogin"
		strMenuAdmin = "<b>a</b>dmin"
		strMenuUpdate = "<b>&Auml;</b>ndern"
		strMenuPeople = "<b>L</b>eute"
		strMenuCouple = "<b>P</b>aare"
		strMenuComments = "<b>A</b>nmerkungen"
		strMenuMessage = "<b>m</b>essages"

		strMessAll = "All Messages"
		strMessPerso = "Personal Messages"
		strMessSubject = "Subject"
		strMessFrom = "From"
		strMessTo = "To"
		strMessSend = "Send"
		strMessEmail = "Email"
		strWarningSubject = "Please enter a Subject"
		strWarningFrom = "Please enter a your name in From"
		strWarningEmail = "Please enter an Email"
		strWarningBody = "Please enter a Message"
		strWarningTo = "Please select one or more people to send the message To"

		strFileName = "File Name"
		strDate = "Date"
		strParticipants = "Participants"
		strSize = "Size"
		strUploaded = "Uploaded"

		strIndividuals = "Individuen"
		strCalendarWarning = "Nur jene Individuen, f&uuml;r die ein exakter Geburtstag bekannt ist, werden verzeichnet"
		strPicturesAll = "Alle Bilder"
		strLoginMessage = "Login to broaden the menu and gain access to the update functions.<br>(you will be automatically logged off if you close your browser)"
		strPassword = "Kennwort"

		strHelpUser = "User.eng.asp"
		strHelpTech = "Tech.eng.asp"

		strFooter = "<hr noShade size=1><p>" & _
					"For all information contact <a href=mailto:sebduk@gmail.com>sebduk@gmail.com</a><br><br>" & _
					"<b>Verbindungen:</b><br>" & _
					"<a href=User.eng.asp>Benutzerhandbuch</a><br>" & _
					"<br>" & _
					strLangOptions & _
					"W&uuml;nschen Sie dieses Site in Ihrer Sprache sehen?<br>" & _
					"Schreiben Sie an <a href=mailto:sebduk@gmail.com>sebduk@gmail.com</a>." & _
					"</p><hr noShade size=1>"


	case "NLD"
		strLastIn = "Last updates"

		strFullAscendance = "Alle ouders"
		strFullDescendance = "Alle kinderen"
		strClassicVersion = "Classic"
		strHorizontalVersion = "Horizontale"
		strVerticalVersion = "Verticale"
		strTableVersion = "Tabelle"
		strExcelVersion = "Excel"
		strFullVersionWarning = "Deze versies vereisen zwaardere verwerking.<br>Geduld a.u.b.!"

		strBornInM = "Geboren in"
		strBornInF = "Geboren in"
		strDiedInM = "Overlijdt in"
		strDiedInF = "Overlijdt in"
		strSearch = "Zoek"
		strClose = "Sluit"
		strCouple = "Par"
		strBiography = "Biografie"
		strComments = "Commentaren"
		strPictures = "Afbeeldingen"
		strDocuments = "Documenten"
		strWith = "Met"
		strBack = "Terug"
		strTop = "top"

		arrMonth(01) = "Januari"
		arrMonth(02) = "Februari"
		arrMonth(03) = "Maart"
		arrMonth(04) = "April"
		arrMonth(05) = "Mai"
		arrMonth(06) = "Juni"
		arrMonth(07) = "Juli"
		arrMonth(08) = "Augustus"
		arrMonth(09) = "September"
		arrMonth(10) = "Oktober"
		arrMonth(11) = "November"
		arrMonth(12) = "December"
		
		strMenuHome = "<b>h</b>ome"
		strMenuGenealogy = "<b>g</b>enealogie per"
		strMenuNames = "<b>n</b>amen"
		strMenuYears = "<b>g</b>eboortejaren"
		strMenuCalendar = "<b>v</b>erjaardagen"
		strMenuPictures = "<b>a</b>fbeeldingen"
		strMenuDocs = "<b>d</b>ocumenten"
		strMenuIntro = "<b>i</b>ntro"
		strMenuHelp = "<b>h</b>ulp"
		strMenuLogin = "<b>l</b>ogin"
		strMenuAdmin = "<b>a</b>dmin"
		strMenuUpdate = "<b>w</b>ijzigen"
		strMenuPeople = "<b>m</b>ensen"
		strMenuCouple = "<b>p</b>aren"
		strMenuComments = "<b>c</b>ommentaren"
		strMenuMessage = "<b>b</b>erigten"

		strMessAll = "All Messages"
		strMessPerso = "Personal Messages"
		strMessSubject = "Subject"
		strMessFrom = "From"
		strMessTo = "To"
		strMessSend = "Send"
		strMessEmail = "Email"
		strWarningSubject = "Please enter a Subject"
		strWarningFrom = "Please enter a your name in From"
		strWarningEmail = "Please enter an Email"
		strWarningBody = "Please enter a Message"
		strWarningTo = "Please select one or more people to send the message To"

		strFileName = "Naam"
		strDate = "Datum"
		strParticipants = "Met"
		strSize = "Size"
		strUploaded = "Uploaded"

		strIndividuals = "Personen"
		strCalendarWarning = "Slechts de personen voor wie een nauwkeurige geboortedatum gekend is zijn vermeld"
		strPicturesAll = "Alle afbeeldingen"
		strLoginMessage = "Login om het menu te verbreden en tot de wijzigenfuncties toegang te krijgen.<br>(you will be automatically logged off if you close your browser)"
		strPassword = "Wachtwoord"

		strHelpUser = "User.eng.asp"
		strHelpTech = "Tech.eng.asp"

		strFooter = "<hr noShade size=1><p>" & _
					"Voor alle informatie schrijft aan <a href=mailto:sebduk@gmail.com>sebduk@gmail.com</a><br><br>" & _
					"<b>Verbindingen:</b><br>" & _
					"<a href=User.eng.asp>Gebruikers handboek</a><br>" & _
					"<br>" & _
					strLangOptions & _
					"Zou u deze site in uw taal vertaald willen zien?<br>" & _
					"Schrijft dan aan <a href=mailto:sebduk@gmail.com>sebduk@gmail.com</a>." & _
					"</p><hr noShade size=1>"


	case else '"FRA"
		strLastIn = "Derni&egrave;res mises &agrave jour"

		strFullAscendance = "Ascendance compl&egrave;te"
		strFullDescendance = "Descendance compl&egrave;te"
		strClassicVersion = "Classique"
		strHorizontalVersion = "Horizontale"
		strVerticalVersion = "Verticale"
		strTableVersion = "Table"
		strExcelVersion = "Excel"
		strFullVersionWarning = "Versions lourdes &agrave; g&eacute;n&eacute;rer.<br>Soyez patient!"

		strBornInM = "N&eacute; &agrave;"
		strBornInF = "N&eacute;e &agrave;"
		strDiedInM = "D&eacute;c&eacute;d&eacute; &agrave;"
		strDiedInF = "D&eacute;c&eacute;d&eacute;e &agrave;"
		strSearch = "Rechercher"
		strClose = "Fermer"
		strCouple = "Couple"
		strBiography = "Biographie"
		strComments = "Commentaires"
		strPictures = "Photos"
		strDocuments = "Documents"
		strWith = "Avec"
		strBack = "Retour"
		strTop = "haut"

		arrMonth(01) = "janvier"
		arrMonth(02) = "f&eacute;vrier"
		arrMonth(03) = "mars"
		arrMonth(04) = "avril"
		arrMonth(05) = "mai"
		arrMonth(06) = "juin"
		arrMonth(07) = "juillet"
		arrMonth(08) = "ao&ucirc;t"
		arrMonth(09) = "septembre"
		arrMonth(10) = "octobre"
		arrMonth(11) = "novembre"
		arrMonth(12) = "d&eacute;cembre"

		strMenuHome = "<b>a</b>cceuil"
		strMenuGenealogy = "<b>g</b>&eacute;n&eacute;alogie par"
		strMenuNames = "<b>n</b>oms"
		strMenuYears = "<b>a</b>nn&eacute;es"
		strMenuCalendar = "<b>a</b>nniversaires"
		strMenuPictures = "<b>p</b>hotos"
		strMenuDocs = "<b>d</b>ocuments"
		strMenuIntro = "<b>i</b>ntro"
		strMenuHelp = "<b>a</b>ide"
		strMenuLogin = "<b>l</b>ogin"
		strMenuAdmin = "<b>a</b>dmin"
		strMenuUpdate = "<b>m</b>odifier les"
		strMenuPeople = "<b>p</b>ersonnes"
		strMenuCouple = "<b>c</b>ouples"
		strMenuComments = "<b>c</b>ommentaires"
		strMenuMessage = "<b>m</b>essages"

		strMessAll = "Tous les Messages"
		strMessPerso = "Messages Personnels"
		strMessSubject = "Sujet"
		strMessFrom = "De"
		strMessTo = "A (Ctrl pour s&eacute;lect. + destinataires)"
		strMessSend = "Envoyer"
		strMessEmail = "Email"
		strWarningSubject = "Veuillez taper un Sujet"
		strWarningFrom = "Veuillez taper votre nom dans De"
		strWarningEmail = "Veuillez taper votre adresse Email"
		strWarningBody = "Veuillez taper un Message"
		strWarningTo = "Veuillez taper selectionner une ou plusieur personnes dans la liste"

		strFileName = "Nom de Fichier"
		strDate = "Date"
		strParticipants = "Participants"
		strSize = "Taille"
		strUploaded = "Ajout&eacute; le"

		strIndividuals = "Personnes"
		strCalendarWarning = "Seules les personnes dont la date de naissance exacte est connue apparaissent dans cette liste"
		strPicturesAll = "Toutes les Photos"
		strLoginMessage = "Loggez pour modifier le menu et avoir acc&egrave;s aux modifications.<br>(vous serez automatiquement d&eacute;logg&eacute;, si vous fermez votre navigateur)"
		strPassword = "Mot de Passe"

		strHelpUser = "User.fra.asp"
		strHelpTech = "Tech.fra.asp"

		strFooter = "<hr noShade size=1><p>" & _
					"Pour toute information contactez <a href=mailto:sebduk@gmail.com>sebduk@gmail.com</a><br><br>" & _
					"<b>Liens:</b><br>" & _
					"<a href=User.fra.asp>Aide Utilisateur</a><br>" & _
					"<br>" & _
					strLangOptions & _
					"Vous souhaitez voir ce site traduit dans votre langue?<br>" & _
					"Ecrivez &agrave; <a href=mailto:sebduk@gmail.com>sebduk@gmail.com</a>." & _
					"</p><hr noShade size=1>"

end select

strFooter = "<hr noShade size=1><p>" & _
			strLangOptions & _
			"</p><hr noShade size=1>"
%>
