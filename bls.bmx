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
Include "bin/TConfig.bmx"		' Must be before TLogger		
Include "bin/TLogger.bmx"		' Must be before TLSP, after Config	
Include "bin/Arguments.bmx"		' Must be before TLSP, but after TLogger

' Load order - SECOND
Include "bin/TLSP.bmx"
Include "bin/responses.bmx"

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

Include "bin/constants.bmx"

'   GLOBALS
Global DEBUGGER:Int = True							' TURN ON/OFF DEBUGGING
Global Config:TConfig = New TConfig					' Configuration manager
Global Logfile:TLogger = New TLogger()				' Log File Manager
Global Args:TArgMap = New TArgMap()					' Arguments
Global Client:TClient = New TClient()				' Client Manager
' This will be based on arguments in the future, but for now we only support STDIO
Global LSP:TLSP = New TLSP_StdIO()					' Language Server
Global Documents:TDocumentMGR = New TDocumentMGR()	' Document Manager

'   INCREMENT BUILD NUMBER

' @bmk include build.bmk
' @bmk incrementVersion build.bmx
Include "build.bmx"
Publish "log", "INFO", AppTitle
Publish "log", "INFO", "  VERSION:    "+version+"."+build
Publish "log", "DEBG", "  CURRENTDIR: "+CurrentDir$()
Publish "log", "DEBG", "  APPDIR:     "+AppDir

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
Publish( "log", "DEBG", "Starting Language Server..." )

'DebugStop

Try
	' V0.2, Moved creation into the TLSP file
    'LSP = New TLSP_Stdio( Int(CONFIG["threadpool"]) )
    exit_( LSP.run() )
    'Publish( "debug", "Exit Gracefully" )
Catch exception:String
    Publish( "log", "CRIT", exception )
End Try
