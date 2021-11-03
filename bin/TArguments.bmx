
'   BLITZMAX LANGUAGE SERVER
'   (c) Copyright Si Dunford, July 2021, All Right Reserved

'	COMMAND LINE ARGUMENTS

Rem
	IMPLEMENTED ARGUMENTS
	
	-x:<option>	Enable experminental option
	
End Rem


' NOT IMPLEMENTED:
'	ARGUMENTS:	
'   -C XXX      - Capabilities

'   

' *** NONE OF THESE ARE CURRENTLY SUPPORTED ***
'
'	--debug:<filename>			- Turn on extended debug logging to a file
'	-v | --version				- Return current version number
'	-h | --help					- Show list of supported arguments
'	--port:<port>				- Use TCP on supplied port ustead of StandardIO
'	--lint:<options>			- Comma seperated list of linter options
'									ifthen=<enforcer>	-	Enforce the use of THEN
'												- Default=0 (Disabled)
'									endspace=<enforce>	-	Enforce "END <block>" Spaces
'												- Default=0 (Disabled)
'									bbdoc=<enforce>		-	Enforce the use of bbdoc comments
'												- Default=0 (Disabled)
'									indentifiercase=0|1 - 	Disable|Titlecase
'												- Default=1 (Titlecase)

'	<enforcer> defined as:
'	00 = Do not Enforce (Feature disabled)
'	01 = (Not a valid option)
'	10 = Enforce Not required
'	11 = Enforce Required
'
'	For example: 
'		--lint:ifthen=0		' Disables if..then checking
'		--lint:ifthen=10	' Enforce THEN is not used
'		--lint:ifthen=11	' Enforce THEN is used

Global EXPERIMENTAL:String[][] = [..
	[ "ast", "AST" ], ..
	[ "docsym", "Document Symbols" ] ..
	]

Type TArguments

	Method New()
'DebugStop
		'   ARGUMENTS
		'Publish "log", "DBG", "  ARGS: ("+AppArgs.length+")~n"+("#".join(AppArgs))
		logfile.debug( "  ARGS:" )'       "+AppArgs.length+"~n"+("#".join(AppArgs)) )
		
		' Set the application argument in case we need it later
		CONFIG[ "app" ] = AppArgs[0]
		
		'DebugStop
		'DebugLog( "ARGS:"+AppArgs.length )
		
		' Parse all the arguments, splitting them by ":"
		For Local n:Int=1 Until AppArgs.length
			' Split argument into KEY/VALUE pair
			Local items:String[] = AppArgs[n].split(":")
			Local key:String = Lower( items[0] )
			Local value:String = ""
			Select items.length
			Case 1
				value = ""
			Case 2
				value = Lower(items[1])
			Default
				value = ":".join( items[1..] )
			End Select
			
			logfile.debug( "    "+n+") "+key + " = '"+value+"'" )
			'
			Select key
			Case "-x"		' EXPERIMENTAL
				Local lab:String = experiment( value )
				If lab = ""
					Print( "Argument '"+AppArgs[n] + "' is an unknown experiment" )
					logfile.warning( "## Argument '"+AppArgs[n] + "' is an unknown experiment" )
				Else 
					CONFIG["experimental|"+value] = "true"  
					Print( "WARNING: '"+value+"' ("+lab+") is experimental" )
					logfile.warning( "## Feature '"+value+"' ("+lab+") is experimental" )
DebugLog( config.J.prettify() )
				End If
			Case "-h","-help"
				CONFIG["cli|help"] = "true"  
			Case "-v","-ver","-version"
				CONFIG["cli|version"] = "true"
			Default
				' Invalid argument!
				Print( "Argument '"+AppArgs[n] + "' is invalid" )
				logfile.warning( "    Argument '"+AppArgs[n] + "' is invalid" )
			End Select
		Next

		' Parse CLI commands
		If CONFIG.isTrue( "cli|help" )
			help()
			exit_(1)
		EndIf

		If CONFIG.isTrue( "cli|version" )
			Print AppTitle
			Print "Version "+version+"."+build
			exit_(1)
		EndIf

		'Publish( "log", "DBG", "CONFIG:~n"+CONFIG.J.Prettify() )
		'logfile.debug( "CONFIG:~n"+CONFIG.J.Prettify() )
	End Method
	
	Method experiment:String( criteria:String )
		For Local i:Int = 0 Until experimental.length
			If experimental[i][0]=criteria ; Return experimental[i][1]
		Next
		Return ""
	End Method
	
	'Method operator []:String(key:String)
	'	'Local value:
	'	Return String(ValueForKey( key ))
	'End Method

	Method help()
		Print AppTitle+"~n"
		Print( "-h | --help          Show Help" )
	End Method
	
End Type

' Testing
'Print "Missing: "+Args["missing"]
'For Local arg:String = EachIn args.keys()
'	Print arg[..10]+" == "+args[arg]
'Next
