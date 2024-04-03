SuperStrict

'   BLITZMAX LANGUAGE SERVER
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	OBJECT HEIRARCHY
'	----------------
'	TEventHandler
'		TLanguageServer extends TEventHandler
'			TClient Extends TEventHandler
'				TClient_StdIO Extends TClient
'				TClient_TCP Extends TClient
'		TLogger Extends TEventHandler
'		TWorkspaces Extends TEventHandler
'	TTextDocument Implements ITextDocument
'		TFullTextDocument Extends TTextDocument
'	TTask
'		TMessage Extends TTask
'		TTaskReceiver Extended TTask
'		TTaskDocumentParse Extends TTask
'		TTaskWorkspaceScan Extends TTask
'		TTaskSend Extends TTask						' Sends a message to the client

' ########## BLITZMAX MODULES

Framework brl.standardio 

Import brl.collections      ' Used for Tokeniser
'Import brl.linkedlist
'Import brl.filesystem
Import brl.map              ' Used as JSON dictionary
Import brl.maxutil			' Used for ModulePath()
Import brl.reflection		' USed by JSON.transpose
Import brl.retro
Import brl.stringbuilder
Import brl.system
Import brl.threads
Import brl.threadpool
'Import brl.randomdefault	' Used by genWorkDoneToken()
Import random.core	' Used by genWorkDoneToken()

' ########## BRUCEYS MODULES

Import bah.database
Import bah.dbsqlite

' ########## CRYPTOGRAPHIC MODULES

Import Crypto.MD5Digest		' Used by MD5 checksums in TWorkspace

' ########## PUBLIC MODULES

Import pub.freeprocess

' ########## TEXT MODULES

Import Text.RegEx

' ########## ITSPEEDWAY/SCAREMONGER MODULES

Import bmx.observer
Import bmx.json
'import bmx.blitzmaxparser

' ########## APPLICATION LIBRARIES

'DebugStop
' FIRST LOADED WILL BE LAST EXIT PROCEDURE TO RUN
Import "lib/logfile.bmx"

' ########## APPLICATION

AppTitle = "BlitzMax Language Server"	' BLS

' Load order - FIRST
Include "bin/TArguments.bmx"	' Uses TConfig, TLogger
'Include "bin/TConfig.bmx"		
'Include "bin/TLogger.bmx"		' Uses TConfig

' Language Server Protocol Interface
Include "bin/language-server-protocol.bmx"

' Load order - SECOND
Include "bin/TLanguageServer.bmx"
Include "bin/TURI.bmx"					' URI Support
Include "bin/responses.bmx"

Include "bin/functions.bmx"

' Tasks
Include "bin/TTask.bmx"						' Ancestral Task type
Include "bin/TTaskQueue.bmx"				' The global task queue
Include "bin/TTaskDiagnostic.bmx"			' Compiles and returns disagnostics information
Include "bin/TTaskDocumentParse.bmx"		' Parses a source file
Include "bin/TTaskModuleScan.bmx"			' Scans modules
Include "bin/TTaskWorkspaceScan.bmx"		' Scans workspace looking for source files
Include "bin/TTaskReceiver.bmx"				' Message Receiver (Listener)
Include "bin/TTaskSend.bmx"					' Sends a message to the client (Server Request, Client Respose or Notification)

' Events and Messages
Include "bin/TEventHandler.bmx"
Include "bin/TMessage.bmx"
Include "bin/TMessage_ServerRequest.bmx"	' Server Request Messages (To client)
'Include "bin/TMessageQueue.bmx"			' 15/12/21, Replaced with TTaskQueue
Include "bin/TClient.bmx"					' Represents the remote IDE
Include "bin/TClient_StdIO.bmx"				' Client StdIO communication
Include "bin/TClient_TCP.bmx"				' Client TCP communication
'Include "bin/TTemplate.bmx"    			' Depreciated (Functionality moved into JSON)
'Include "bin/json.bmx"

'Include "bin/sandbox.bmx"

Include "bin/TCacheDB.bmx"	
Include "bin/TModuleCache.bmx"				' Manages the module cache database

' Text Document Manager
Include "bin/TSymbolTable.bmx"	
Include "bin/TTextDocument.bmx"	
Include "bin/TWorkspaces.bmx"		' Manages ALL workspaces
Include "bin/TWorkspace.bmx"		' Manages a single workspace
Include "bin/TWorkspaceCache.bmx"	' Manages the workspace cache
Include "bin/TDBDocument.bmx"		' Database Document Interaction
Include "bin/TGift.bmx"				' Gift brought by a Visitor ;)

'Include "bin/TDocumentMGR.bmx"	' Depreciated 20/10/21 - replaced by TWorkspace

' SANDBOX LEXER
'Include "lexer/TLexer.bmx"
'Include "lexer/TToken.bmx"
'Include "lexer/TException.bmx"

' SANDBOX PARSER
Include "sandbox/bmx.parser/TParser.bmx"
Include "sandbox/bmx.parser/TASTNode.bmx"
Include "sandbox/bmx.parser/TASTBinary.bmx"
Include "sandbox/bmx.parser/TASTUnary.bmx"
Include "sandbox/bmx.parser/TASTGroup.bmx"
Include "sandbox/bmx.parser/TASTCompound.bmx"
Include "sandbox/bmx.parser/TVisitor.bmx"
Include "sandbox/bmx.parser/TParseValidator.bmx"
Include "sandbox/bmx.parser/TASTErrorMessage.bmx"
Include "sandbox/bmx.parser/TASTWalker.bmx"

' SANDBOX BLITZMAX LEXER/PARSER
' Included here until stable release pushed back into module
Include "sandbox/bmx.blitzmaxparser/lexer-const-bmx.bmx"
Include "sandbox/bmx.blitzmaxparser/TBlitzMaxAST.bmx"
Include "sandbox/bmx.blitzmaxparser/TBlitzMaxLexer.bmx"
Include "sandbox/bmx.blitzmaxparser/TBlitzMaxParser.bmx"

'debugstop
' Message Handlers
Include "handlers/handlers.bmx"

Include "bin/constants.bmx"

'	INCLUDE SUPPORTED ARGUMENTS

Incbin "arguments.json"

' USING PRINT SCREWS UP STDIO SO DONT USE IT!
Function Print( Message:String ) ; End Function

'Local td:TDiagnostic = New TDiagnostic()

'DebugStop
'   GLOBALS
Global DEBUGGER:Int = True							' TURN ON/OFF DEBUGGING
Global CONFIG:TConfig = New TConfig					' Configuration manager
' Apply Command line arguments
'Global Logfile:TLogger = New TLogger()				' Log File Manager

' #####
' ########## BMK FEATURES

' @bmk echo
' @bmk echo *******************************
?Debug
' @bmk echo ****  DEBUG MODE
?Not Debug
' @bmk echo ****  RELEASE MODE
?
' @bmk echo *******************************
' INCREMENT BUILD NUMBER
' @bmk include bin/version.bmk
' @bmk incrementVersion 
' @bmk echo *******************************
' @bmk echo
Include "bin/version.bmx"

' ##########
' #####

Const JSON_MINIMUM_VERSION:Float = 3.0
'Const JSON_MINIMUM_BUILD:Int = 0

Const OBSERVER_MINIMUM_VERSION:Float = 1.6
'Const OBSERVER_MINIMUM_BUILD:Int = 0

'Local Watcher:TWatcher = New TWatcher()	' Create Test

Observer.threaded()		' Enable thread protection

Trace.Debug( "------------------------------------------------------------" )
Trace.Info( AppTitle )
Trace.Info( "- VERSION:    V"+appvermax+"."+appvermin+" build "+appbuild )
Trace.Info( "- JSON:       V"+JSON.Version() )
Trace.Info( "- OBSERVER:   V"+Observer.Version() )
 
If JSON.Version() < JSON_MINIMUM_VERSION
	Trace.Critical( "bmx.json version is below minimum requirements; please update." )
	End
End If
If OBSERVER.Version() < OBSERVER_MINIMUM_VERSION
	Trace.Critical( "bmx.observer version is below minimum requirements; please update." )
	End
End If
Trace.Debug( "- CURRENTDIR: "+CurrentDir$() )
Trace.Debug( "- APPDIR:     "+AppDir )



'	ARGUMENTS AND CONFIGURATION
'DebugStop
New TArguments()			' Arguments
Trace.debug( "CONFIG:~n"+config.J.prettify() )

'	START THE MESSAGE QUEUE

Global TaskQueue:TTaskQueue = New TTaskQueue()			' 12/12/21, Standardised task queue

'	CLIENT COMMUNICATION

Global Client:TClient 			' Client Manager
Config["transport"]="stdio"		' 	This will be based on arguments in the future, but for now we only support STDIO
Select Config["transport"]
Case "tcp"
	client = New TClient_TCP()
Default
	client = New TClient_StdIO()
End Select

If client
	client.open()					' Start the client
Else
	Trace.critical( "Failed to create client" )
End If

'	LANGUAGE SERVER
'DebugStop
Global LSP:TLanguageServer	 = New TLanguageServer()		' Language Server
'DebugStop

' Depreciated 15/12/21 in favour of TClient extensions.
' This will be based on arguments in the future, but for now we only support STDIO
'Select Config["transport"]
'Case "tcp"
'	LSP = New TLSP_TCP()
'Default
'	LSP = New TLSP_StdIO()
'End Select

'	DOCUMENTS AND WORKSPACES

'Global Documents:TDocumentMGR = New TDocumentMGR()	' Document Manager, Depreciated (See Workspace)
Global Workspaces:TWorkspaces = New TWorkspaces()

'	CREATE MODULE SCAN TASK
DebugStop
Global modules:TModuleCache = New TModuleCache()
'DebugStop
Local task:TTaskModuleScan = New TTaskModuleScan( modules )
task.post()

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
Trace.debug( "Starting Language Server..." )

'DebugStop

Try
	' V0.2, Moved creation into the TLSP file
    'LSP = New TLSP_Stdio( Int(CONFIG["threadpool"]) )
    'exit_( LSP.run() )
    'Publish( "debug", "Exit Gracefully" )

	' Wait for listener to close
	client.wait()

Catch exception:String
    Trace.critical( exception )
End Try

Trace.debug( "Language Server Closing..." )
