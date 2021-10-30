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
'import bmx.blitzmaxparser

AppTitle = "BlitzMax Language Server"	' BLS

?debug
Print"~n~n~t~tWARNING:~n~t~tYou are compiling in DEBUG mode~n~n"
?

'DebugStop
' Load order - FIRST
Include "bin/TArguments.bmx"	' Uses TConfig, TLogger
Include "bin/TConfig.bmx"		
Include "bin/TLogger.bmx"		' Uses TConfig

' Language Server Protocol Interface
Include "bin/language-server-protocol.bmx"

' Load order - SECOND
Include "bin/TLSP.bmx"
Include "bin/responses.bmx"

' Load order - ANY
Include "bin/TEventHandler.bmx"
Include "bin/TMessage.bmx"
Include "bin/TMessageQueue.bmx"
Include "bin/TClient.bmx"		' Represents the remote IDE
'Include "bin/TTemplate.bmx"    ' Depreciated (Functionality moved into JSON)
'Include "bin/json.bmx"

'Include "bin/sandbox.bmx"

' Text Document Manager
Include "bin/TSymbolTable.bmx"	
Include "bin/TTextDocument.bmx"	
Include "bin/TWorkspace.bmx"
'Include "bin/TDocumentMGR.bmx"	' Depreciated 20/10/21 - Will be replaced by TWorkspace

' SANDBOX LEXER
'Include "lexer/TLexer.bmx"
'Include "lexer/TToken.bmx"
'Include "lexer/TException.bmx"

' SANDBOX PARSER
'Include "parser/TParser.bmx"
'Include "parser/TASTNode.bmx"
'Include "parser/TASTBinary.bmx"
'Include "parser/TASTCompound.bmx"
'Include "parser/TVisitor.bmx"
'Include "parser/TParseValidator.bmx"

' SANDBOX BLITZMAX LEXER/PARSER
' Included here until stable release pushed back into module
Include "bmx/lexer-const-bmx.bmx"
Include "bmx/TBlitzMaxAST.bmx"
Include "bmx/TBlitzMaxLexer.bmx"
Include "bmx/TBlitzMaxParser.bmx"

'debugstop
' Message Handlers
Include "handlers/handlers.bmx"

Include "bin/constants.bmx"

DebugStop
Local td:TDiagnostic = New TDiagnostic()

'DebugStop
'   GLOBALS
Global DEBUGGER:Int = True							' TURN ON/OFF DEBUGGING
Global Config:TConfig = New TConfig					' Configuration manager
' Apply Command line arguments
Global Logfile:TLogger = New TLogger()				' Log File Manager
New TArguments()			' Arguments
Global Client:TClient = New TClient()				' Client Manager
Global LSP:TLSP 									' Language Server
' This will be based on arguments in the future, but for now we only support STDIO
' if Config['transport']="stdio"
	LSP = New TLSP_StdIO()
' else
'	LSP = New TLSP_TCP()
' end if
'Global Documents:TDocumentMGR = New TDocumentMGR()	' Document Manager, Depreciated (See Workspace)
Global Workspaces:TWorkspaces = New TWorkspaces()

'   INCREMENT BUILD NUMBER

' @bmk include build.bmk
' @bmk incrementVersion build.bmx
Include "build.bmx"
logfile.info( AppTitle )
logfile.info( "  VERSION:    "+version+"."+build )
logfile.debug( "  CURRENTDIR: "+CurrentDir$() )
logfile.debug( "  AppDir:     "+AppDir )

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
logfile.debug( "Starting Language Server..." )

'DebugStop

Try
	' V0.2, Moved creation into the TLSP file
    'LSP = New TLSP_Stdio( Int(CONFIG["threadpool"]) )
    exit_( LSP.run() )
    'Publish( "debug", "Exit Gracefully" )
Catch exception:String
    logfile.critical( exception )
End Try
