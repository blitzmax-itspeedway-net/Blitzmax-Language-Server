SuperStrict

'   BLITZMAX LANGUAGE SERVER
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

Framework brl.standardio 
Import brl.collections      ' Used for Tokeniser
'Import brl.linkedlist
Import brl.map              ' Used as JSON dictionary
Import brl.reflection		' USed by JSON.transpose
Import brl.retro
Import brl.stringbuilder
Import brl.system
Import brl.threads
Import brl.threadpool
Import Text.RegEx

Import pub.freeprocess
'debugstop
'   INCLUDE APPLICATION COMPONENTS

Import bmx.json

AppTitle = "BlitzMax Language Server"	' BLS

'DebugStop
' Load order - FIRST
Include "bin/Arguments.bmx"		' Must be before TLSP
Include "bin/TConfig.bmx"		' Must be before TLogger		
Include "bin/TLogger.bmx"		' Must be before TLSP		

' Load order - SECOND
Include "bin/TLSP.bmx"

' Load order - ANY
Include "bin/TObserver.bmx"
Include "bin/TMessage.bmx"
Include "bin/TMessageQueue.bmx"
Include "bin/TClient.bmx"		' Represents the remote IDE
'Include "bin/TTemplate.bmx"    ' Depreciated (Functionality moved into JSON)
'Include "bin/json.bmx"

'Include "bin/sandbox.bmx"

' Text Document Manager
Include "bin/TDocumentMGR.bmx"

'debugstop
' Message Handlers
'Include "handlers/handlers.bmx"



' RPC2.0 Error Messages
Const ERR_PARSE_ERROR:String =       "-32700"  'Invalid JSON was received by the server.
Const ERR_INVALID_REQUEST:String =   "-32600"  'The JSON sent is not a valid Request object.
Const ERR_METHOD_NOT_FOUND:String =  "-32601"  'The method does not exist / is not available.
Const ERR_INVALID_PARAMS:String =    "-32602"  'Invalid method parameter(s).
Const ERR_INTERNAL_ERROR:String =    "-32603"  'Internal JSON-RPC error.

' LSP Error Messages
Const ERR_SERVER_NOT_INITIALIZED:String = "-32002"
Const ERR_CONTENT_MODIFIED:String =       "-32801"
Const ERR_REQUEST_CANCELLED:String =      "-32800"
'
Const JSONRPC:String = "2.0"		' Supported JSON-RPC version

' MESSAGE STATES
Const STATE_WAITING:Int = 0
Const STATE_RUNNING:Int = 1
Const STATE_COMPLETE:Int = 2
'const STATE_CANCELLED:int = 3

?win32
    Const EOL:String = "~n"
?Not win32
    Const EOL:String = "~r~n"
?

'   GLOBALS
Global DEBUGGER:Int = True

'Local Logfile:TLogger = New TLogger()         ' Please use Observer


'   INCREMENT BUILD NUMBER

' @bmk include build.bmk
' @bmk incrementVersion build.bmx
Include "build.bmx"
Publish "log", "INFO", AppTitle
Publish "log", "INFO", "Version "+version+"."+build
Publish "log", "DEBG", "CURRENTDIR: "+CurrentDir$()
Publish "log", "DEBG", "APPDIR:     "+AppDir

Rem 31/8/21, Depreciated by new message queue
'   Worker Thread
Type TRunnableTask Extends TRunnable
    Field message:TMSG
    Field lsp:TLSP

    Method New( handler:TMSG, lsp:TLSP )
        Self.message = handler
        Self.lsp = lsp
    End Method

    Method run()
		Local response:String = message.run()
		'V0.2, default to error if nothing returned from handler
		If response="" response = Response_Error( ERR_METHOD_NOT_FOUND, "Method is not available", message.id )
		' Send the response to the client
		Publish( "sendmessage", response )
		'lsp.queue.pushSendQueue( response )
		' Close the request as complete
		message.state = STATE_COMPLETE
    End Method
End Type
End Rem

'   Run the Application
Publish( "log", "DEBG", "Starting LSP..." )

'DebugStop

Try
	' V0.2, Moved creation into the TLSP file
    'LSP = New TLSP_Stdio( Int(CONFIG["threadpool"]) )
    exit_( LSP.run() )
    'Publish( "debug", "Exit Gracefully" )
Catch exception:String
    Publish( "log", "CRIT", exception )
End Try
