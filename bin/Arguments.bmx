'SuperStrict
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, July 2021, All Right Reserved

'	ARGUMENTS:	*** NONE OF THESE ARE CURRENTLY SUPPORTED ***
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

Global Args:TArgMap = New TArgMap()

Type TArgMap Extends TMap

	Method New()
		
		'   ARGUMENTS
		'Publish "log", "DEBG", "ARGS: ("+AppArgs.length+")"     '+(" ".join(AppArgs))
		
		insert( "app",AppArgs[0] )
		For Local n:Int=1 Until AppArgs.length
			Local items:String[] = AppArgs[n].split("=")
			If items.length>1
				insert( items[0], "=".join( items[1..] ) )
			Else
				insert( AppArgs[n], "true" )
			End If
			'Publish "log", "DEBG", n+") "+AppArgs[n]
		Next

		If contains( "-h" ) Or contains( "--help" )
			help()
			exit_(1)
		EndIf

		If contains( "-v" ) Or contains( "--version" )
			Print AppTitle
			Print "Version "+version+"."+build
			exit_(1)
		EndIf

	End Method
	
	Method operator []:String(key:String)
		'Local value:
		Return String(ValueForKey( key ))
	End Method

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
