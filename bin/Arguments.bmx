'SuperStrict
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, July 2021, All Right Reserved

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

	End Method
	
	Method operator []:String(key:String)
		'Local value:
		Return String(ValueForKey( key ))
	End Method
	
End Type

' Testing
'Print "Missing: "+Args["missing"]
'For Local arg:String = EachIn args.keys()
'	Print arg[..10]+" == "+args[arg]
'Next
