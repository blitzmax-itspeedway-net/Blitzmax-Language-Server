SuperStrict

' TEST ARGUMENT SYSTEM

Import bmx.json

'Include "bin/constants.bmx"
'Include "bin/TEventHandler.bmx"
Include "bin/TConfig.bmx"
Include "bin/TArguments.bmx"
'Include "bin/TLogger.bmx"
'Include "bin/TMessage.bmx"
'Include "bin/TMessageQueue.bmx"
'Include "bin/TTask.bmx"
'Include "bin/TLanguageServer.bmx"
'Include "bin/responses.bmx"
'Include "bin/TClient.bmx"
'Include "bin/TWorkspace.bmx"
'Include "bin/language-server-protocol.bmx"
'Include "bin/TTextDocument.bmx"

'Include "sandbox/bmx.parser/TASTNode.bmx"

'Const JSON_MINIMUM_VERSION:Float = 2.1
'Const JSON_MINIMUM_BUILD:Int = 10

Incbin "arguments.json"

Global version:String = "0"
Global build:String = "0"

?win32
    Const EOL:String = "~n"
?Not win32
    Const EOL:String = "~r~n"
?

'Global LSP:TLanguageServer									' Language Server

'Global Client:TClient 
'Global Workspaces:TWorkspaces

Type TLogger
	Method debug( msg:String )
		Print "DEBUG:" + msg
	End Method
	Method error( msg:String )
		Print "ERROR:" + msg
	End Method
	Method info( msg:String )
		Print "INFO:" + msg
	End Method
	Method warning( msg:String )
		Print "WARNING: " + msg
	End Method
End Type

Global CONFIG:TConfig = New TConfig					' Configuration manager
Global Logfile:TLogger = New TLogger()				' Log File Manager
New TArguments()			' Arguments

logfile.debug( "CONFIG:~n"+config.J.prettify() )