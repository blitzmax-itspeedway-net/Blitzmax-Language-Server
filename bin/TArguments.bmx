
'   BLITZMAX LANGUAGE SERVER
'   (c) Copyright Si Dunford, July 2021, All Right Reserved

Rem	IMPLEMENTED ARGUMENTS

	Arguments can be combined. For example "-o:ast" and "-o:eol" can be combined into "-o:ast,eol"
	
	-x:<option>		Enable experimental option
					diag		Diagnostics Provider
					wsym		Workspace Symbol Provider
	-ast			DEPRECIATED, PLEAE USE -o:ast
	-eol			DEPRECIATED, PLEAE USE -o:eol
	-o:<options>
					ast			Show AST in outline
					eol			Show EOL in AST
					noname		Do not display token name in outline
	
	** Options can be combined by seperating them with a cooa, for example:
		
		-o:ast,noname
	
	TERMINAL ONLY ARGUMENTS
	
	--version		Return current version number
	--help			Show list of supported arguments

	THINGS TO DO
	
	* Update help page
	
	FEATURE TO ARGUMENT MAPPING
	
	linting									-l:FEATURE:VALUE
	
	Diagnostics 							-diag
	Code Completion Provider 				-cc
	Code Action Provider					-ca
	Codelens Provider 						-cl
	Color Provider 							-c
	Definition Provider						-d
	Document Formatting Provider			-df
	Document Range Formatting Provider		-dr
	Document On-Type Formatting Provider 	-do
	Document Highlight Provider				-dh
	Document Symbol Provider 				-o
	Hovers 									-h
	References Provider						-ref
	Rename Provider 						-ren
	Resolve Provider 				 		-res
	Signature Help 							-s
	Workspace Symbol Provider 				-w			-x:wsym
		
End Rem

' NOT IMPLEMENTED:
'	ARGUMENTS:	
'   -C XXX      - Capabilities

'   

' *** NONE OF THESE ARE CURRENTLY SUPPORTED ***
'
'	--debug:<filename>			- Turn on extended debug logging to a file
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

Rem 
Global EXPERIMENTAL:String[][] = [..
	[ "diag", "experimental|diag", "Diagnostic Information" ] ..
	]

'	[ "ast", "ast|show", "AST" ], ..
'	[ "docsym", "experimental|docsym", "Document Symbols" ], ..

Global FEATURES:String[][] = [..
	[ "-ast", "outline|ast", "true", "Show AST in Outline" ], ..
	[ "-eol", "outline|eol", "true", "Show EOL in AST" ] ..
	]
End Rem

Rem

Const ARGUMENTS:String = "{" +..
"	'-ast':{" +..
"		'default':{ 'key':'outline|ast', 'value':'true', 'hint':'-ast is depreciated, use -o:ast'}" +..
"	}," +..
"	'-eol':{" +..
"		'default':{ 'key':'outline|eol', 'value':'true', 'hint':'-eol is depreciated, use -o:eol'}" +..
"	}," +..
"	'-diag':{" +..
"		'default':{ 'key':'experimental|diag', 'value':'true', 'hint':'Diagnostic Information' }" +..
"	}," +..
"	'--help':{" +..
"		'default':{ 'key':'cli|help', 'value':'true' }" +..
"	}," +..
"	'-l':{" +..
"		'a001':{ 'key':'linter|xyz', 'hint':'Enable XYZ' }" +..
"	}," +..
"	'-o':{" +..
"		'ast':{ 'key':'outline|ast', 'value':'true', 'hint':'Show AST in Outline' }," +..
"		'eol':{ 'key':'outline|eol', 'value':'true', 'hint':'Show EOL in AST'}," +..
"		'noname':{ 'key':'outline|noname', 'value':'true', 'hint':'Hide Name in Outline'}" +..
"	}," +..
"	'--version':{" +..
"		'default':{ 'key':'cli|version', 'value':'true' }" +..
"	}," +..
"	'-x':{" +..
"		'diag':{ 'key':'experimental|diag', 'value':'true', 'hint':'Diagnostic Information' }" +..
"	}" +..
"}"
End Rem
'debuglog FEATURES.prettify()



Type TArguments

	Method New()
'DebugStop
		'   ARGUMENTS
'		DebugLog( "ARGS: ("+AppArgs.length+")" )
		'Publish "log", "DBG", "  ARGS: ("+AppArgs.length+")~n"+("#".join(AppArgs))
		'logfile.debug( "  ARGS:" )'       "+AppArgs.length+"~n"+("#".join(AppArgs)) )
		'DebugStop
		
'DebugStop		

		' Parse CLI commands
		Select Lower(AppArgs[1])
		Case "--help", "-h", "/?"
			help()
			exit_(1)
		Case "--version", "-v", "/v"
			Print AppTitle
			Print "Version "+version+"."+build
			exit_(1)
		Case "set"
			If AppArgs.length<=3
				Print( "Missing argument" )
				Print()
				Print( "Syntax:" )
				Print( "  "+StripDir(AppArgs[0])+ " set <key> <value>" )
				Print()
				Print( "  <key> options can be split using '.', for example" )
				Print( "  "+StripDir(AppArgs[0])+ " set my.user.variable TRUE" )
				Exit_(1)
			End If
			Local key:String = AppArgs[2].Replace(".","|")
			Local value:String = " ".join( AppArgs[3..] )
'DebugLog( "Setting '"+key+"' to '"+value+"'" )
			CONFIG[key]=value
			CONFIG.save()
			Print( CONFIG.J.prettify() )
			exit_(1)			
		Case "clear", "unset"
			If AppArgs.length<=2
				Print( "Missing argument" )
				Print()
				Print( "Syntax:" )
				Print( "  "+StripDir(AppArgs[0])+" "+AppArgs[1]+" <key>" )
				Print()
				Print( "  <key> options can be split using '.', for example" )
				Print( "  "+StripDir(AppArgs[0])+" "+AppArgs[1]+" my.user.variable" )
				Exit_(1)
			End If
			Local key:String = AppArgs[2].Replace(".","|")
			CONFIG[key]="null"
			CONFIG.save()
			Print( CONFIG.J.prettify() )
			exit_(1)
		Case "show", "--show", "/show"
			Print( CONFIG.J.prettify() )
			exit_(1)
		EndSelect

		'	PARSE FEATURES

		' Load supported arguments from disk
		Local file:TStream = ReadStream( "incbin::arguments.json" )
		Local arguments:String
		If file 
			'debuglog "- File Size: "+file.size()+" bytes"
			arguments = ReadString( file, file.size() )
			CloseStream file
		End If
		
		Local Features:JSON = JSON.PARSE( arguments )
		DebugLog( Features.Prettify() )

		' Set the application argument in case we need it later
		CONFIG[ "app" ] = AppArgs[0]
		
		' Parse JSON or report error
		If Features.isInvalid() 
			DebugLog "INTERNAL ERROR:"
			DebugLog "TArguments.new() - Invalid Argment Data"
			DebugLog Features.error()
			logfile.critical( "## INTERNAL ERROR" )
			logfile.critical( "## TArguments.New() - Invalid Argument Data" )
		Else
'DebugStop
		'DebugLog( "ARGS:"+AppArgs.length )
		
			' Parse all the arguments, splitting them by ":"
			For Local n:Int=1 Until AppArgs.length
				' Split argument into KEY/VALUE pair
				Local items:String[] = AppArgs[n].split(":")
				Local section:String = Lower( items[0] )
				Local value:String = ""
				Select items.length
				Case 1
					value = ""
				Case 2
					value = Lower(items[1])
				Default
					value = ":".join( items[1..] )
				EndSelect
				
				' Check the section key is supported
				If Not Features.contains( section )
					logfile.warning "## Invalid argument: "+AppArgs[n]
					Continue
				End If
	'DebugLog "SECTION='"+section+"'"
				Local JSection:JSON = Features.find( section )
				
				' Extract keys from value
				Local keys:String[] = value.split(",")
				If keys[0]="" ; keys[0]="default"			
				For Local key:String = EachIn keys
					' Split KEY into KEY:VALUE
					Local keyvalue:String[] = key.split("=")
					value = ""
					
	'D'ebugLog "- KEY='"+key+"'"
					
					If JSection.contains( keyvalue[0] )
						Local JOption:JSON = JSection.find( keyvalue[0] )
	'DebugLog( "- VALID "+section+":"+keyvalue[0])
						Local hint:String = JOption.find("hint").toString()
						If hint <> "" ; logfile.info( "## " + hint )
						
						If keyvalue.length=1 
							value = JOption.find("value").toString()
						Else
							value = keyvalue[1]
						End If
						CONFIG[ JOption.find("key").toString() ] = value
					Else
						logfile.warning "## Invalid argument: "+section+":"+key
					End If
					
					
				Next

Rem			'
			Select section
			Case "-x"		' EXPERIMENTAL
				Local lab:String[] = lookup( EXPERIMENTAL, value )
				If lab = []
					'Print( "Argument '"+AppArgs[n] + "' is an unknown experiment" )
					logfile.warning( "## Argument '"+AppArgs[n] + "' is an unknown experiment" )
				Else 
					CONFIG[ lab[1] ] = "true"  
					'Print( "WARNING: '"+value+"' ("+lab[2]+") is experimental" )
					logfile.warning( "## Feature '"+value+"' ("+lab[2]+") is experimental" )
'DebugLog( config.J.prettify() )
				End If
			Case "-o"
				
			Case "-h","-help"
				CONFIG["cli|help"] = "true"  
			Case "-v","-ver","-version"
				CONFIG["cli|version"] = "true"
			Default
				Local feature:String[] = lookup( FEATURES, section )
				If feature = []
					logfile.warning( "## Argument '"+AppArgs[n] + "' is invalid" )
				Else
					CONFIG[ feature[1] ] = feature[2]
					logfile.info( "## "+ feature[3] )
				End If
			End Select
End Rem	
			Next

		End If

'DebugStop
'		If CONFIG.has( "experimental|wsym" ) ; DebugLog( "WORKSPACE SYMBOLS ENABLED" )

'DebugLog( "CHECKING CLI OPTIONS" )
		' Parse CLI commands
'		If CONFIG.isTrue( "cli|help" )
'			help()
'			exit_(1)
'		EndIf

'		If CONFIG.isTrue( "cli|version" )
'			Print AppTitle
'			Print "Version "+version+"."+build
'			exit_(1)
'		EndIf

		'Publish( "log", "DBG", "CONFIG:~n"+CONFIG.J.Prettify() )
		'logfile.debug( "CONFIG:~n"+CONFIG.J.Prettify() )
		
		DebugLog( CONFIG.J.prettify() )
	End Method
	
	'Method experiment:String( criteria:String )
	'	For Local i:Int = 0 Until experimental.length
	'		If experimental[i][0]=criteria ; Return experimental[i][1]
	'	Next
	'	Return ""
	'End Method
	
	Method lookup:String[]( list:String[][], key:String )
		For Local i:Int = 0 Until list.length
			If list[i][0]=key ; Return list[i]
		Next
		Return []
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
