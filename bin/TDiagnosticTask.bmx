
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

Type TDiagnosticTask Extends TTask

	Method New()
		name = "Diagnostic"
		priority = 5
	End Method

	Method execute()
		logfile.debug( "DIAGNOSTIC TASK IS NOT IMPLEMENTED" )
	End Method

End Type