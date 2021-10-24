
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, July 2021, All Right Reserved

Include "TLSP_Stdio.bmx"
Include "TLSP_TCP.bmx"

Type TLSP Extends TObserver
    Global instance:TLSP

    Field exitcode:Int = 0

	Field initialised:Int = False   	' Set by "iniialized" message
    Field shutdown:Int = False      	' Set by "shutdown" message
	Field setTrace:String = "off"		' Set by $/setTrace
	
	' ROOT URI and ROOT WORKSPACE are now saved into TWorkspaces
	'Field rooturi:String					' Root URI
	'Field rootworkspace:TWorkspace			' Root workspace
	
    'Field client:TClient = New TClient()		' Moved to a global

	' Create a document manager
	'Field textDocument:TTextDocument_Handler	' Do not initialise here: Depends on lsp.

    ' Threads
    Field QuitMain:Int = True       ' Atomic State - Set by "exit" message

    Field Receiver:TThread
    Field QuitReceiver:Int = True   ' Atomic State

    Field Sender:TThread
    Field QuitSender:Int = True     ' Atomic State

    Field ThreadPool:TThreadPoolExecutor
    Field ThreadPoolSize:Int
    Field sendMutex:TMutex = CreateMutex()

    
	' System
	'Field capabilities:JSON = New JSON()	' Empty object
	Field handlers:TMap = New TMap
	
    Method run:Int() Abstract
    Method getRequest:String() Abstract     ' Waits for a message from client

    Method Close() ; End Method

	'V0.0
    Function ExitProcedure()
        'Publish( "debug", "Exit Procedure running" )
        Publish( "exitnow" )
        instance.Close()
        'Logfile.Close()
    End Function

	'V0.1
    ' Thread based message receiver
    Function ReceiverThread:Object( data:Object )
        Local lsp:TLSP = TLSP( data )
        Local quit:Int = False     ' Local loop state

        ' Read messages from Language Client
        Repeat

            Local node:JSON
                       
            ' Get inbound message from Language Client
            Local content:String = lsp.getRequest()

            ' Parse message into a JSON object
			'Publish( "debug", "Parse starting" )
            Local J:JSON = JSON.Parse( content )
			'Publish( "debug", "Parse finished" )
            ' Report an error to the Client using stdOut
            If Not J Or J.isInvalid()
				Local errtext:String
				If J.isInvalid()
					errtext = "ERROR("+J.errNum+") "+J.errText+" at {"+J.errLine+","+J.errpos+"}"
				Else
					errtext = "ERROR: Parse returned null"
				End If
                ' Send error message to LSP Client
				Publish( "debug", errtext )
                Publish( "send", Response_Error( ERR_PARSE_ERROR, errtext ) )
                Continue
            End If
			'Publish( "debug", "Parse successful" )
			
            ' Debugging
            'Local debug:String = JSON.stringify(J)
            'logfile.write( "STRINGIFY:" )
            'logfile.write( "  "+debug )

			' V0.3 Event Creation
			New TMessage( "RECEIVE-FROM-CLIENT", J ).emit()		' Send Message Received event	
   
Rem V0.2 depreciated
            ' Check for a method
            node = J.find("method")
            If Not node 
                Publish( "send", Response_Error( ERR_METHOD_NOT_FOUND, "No method specified" ))
                Continue
            End If
            Local methd:String = node.tostring()
            'Publish( "log", "DEBG", "RPC METHOD: "+methd )
            If methd = "" 
                Publish( "send", Response_Error( ERR_INVALID_REQUEST, "Method cannot be empty" ))
                Continue
            End If

            ' Validation
            If Not LSP.initialized And methd<>"initialize"
                Publish( "send", Response_Error( ERR_SERVER_NOT_INITIALIZED, "Server is not initialized" ))
                Continue
            End If
                
            ' Transpose JNode into Blitzmax Object
            Local request:TMessage
            Try
                Local typestr:String = "TMethod_"+methd
                typestr = typestr.Replace( "/", "_" )
                typestr = typestr.Replace( "$", "dollar" ) ' Protocol Implementation Dependent
                'Publish( "log", "DEBG", "BMX METHOD: "+typestr )
                ' Transpose RPC
                request = TMessage( J.transpose( typestr ))
				' V0.2 - This is no longer a failure as we may have a handler
                'If Not request
                '    Publish( "log", "DEBG", "Transpose to '"+typestr+"' failed")
                '    Publish( "send", Response_Error( ERR_METHOD_NOT_FOUND, "Method is not available" ))
                '    Continue
                'Else
                '    ' Save JNode into message
                '    request.J = J
                'End If
				' V0.2, Save the original J node
				If request 
                    request.J = J
                    Publish( "debug", "Transposed successfully" )
                End If
                'If Not request Publish( "debug", "Transpose to '"+typestr+"' failed")
            Catch exception:String
                Publish( "send", Response_Error( ERR_INTERNAL_ERROR, exception ))
            End Try

			' V0.2
			' If Transpose fails, then all is not lost
			If Not request
				Publish( "debug", "Creating V0.2 message object")
				request = New TMessage( methd, J )
			End If
    
            ' A Request is pushed to the task queue
            ' A Notification is executed now
            If request.contains( "id" )
                ' This is a request, add to queue
                Publish( "debug", "Pushing request to queue")
                Publish( "pushtask", request )
                'lsp.queue.pushTaskQueue( request )
                Continue
            Else
                ' This is a Notification, execute it now and throw away any response
                Try
                    Publish( "debug", "Notification "+methd+" starting" )
                    request.run()
                    Publish( "debug", "Notification "+methd+" completed" )
                Catch exception:String
                    Publish( "send", Response_Error( ERR_INTERNAL_ERROR, exception ))    
                End Try
            End If
EndRem
        Until CompareAndSwap( lsp.QuitReceiver, quit, True )
        'Publish( "debug", "ReceiverThread - Exit" )
    End Function

	'V0.1
    ' Thread based message sender
    Function SenderThread:Object( data:Object )
        Local lsp:TLSP = TLSP( data )
        Local quit:Int = False          ' Always got to know when to quit!
        
        'DebugLog( "SenderThread()" )
        Repeat
            Try
                Publish( "debug", "TLSP.SenderThread going to sleep")
                WaitSemaphore( client.sendcounter )
                Publish( "debug", "TLSP.SenderThread is awake" )
                ' Create a Response from message
                Local content:String = client.popSendQueue()
                'Publish( "log", "DEBG", "Sending '"+content+"'" )
                If content<>""  ' Only returns "" when thread exiting
                    Local response:String = "Content-Length: "+Len(content)+EOL
                    response :+ EOL
                    response :+ content
                    ' Log the response
                    'Publish( "log", "DEBG", "Sending:~n"+response )
                    ' Send to client
                    LockMutex( lsp.sendMutex )
                    StandardIOStream.WriteString( response )
                    StandardIOStream.Flush()
                    UnlockMutex( lsp.sendMutex )
                    'Publish( "debug", "Content sent" )
                End If
            Catch Exception:String 
                'DebugLog( Exception )
                Publish( "log", "CRIT", Exception )
            End Try
        Until CompareAndSwap( lsp.QuitSender, quit, True )
        Publish( "debug", "SenderThread - Exit" )
    End Function  


	'V0.2
	' Add a Capability
	'Method addCapability( capability:String )
	'	capabilities :+ [capability]
	'End Method	

	'V0.2
	' Retrieve all registered capabilities
	'Method getCapabilities:String[][]()
	'	Local result:String[][]
	'	For Local capability:String = EachIn capabilities
	'		result :+ [[capability,"true"]]
	'	Next
	'	Return result
	'End Method

Rem 31/8/21 Depreciated
	'V0.2
	' Add Message Handler
	Method addHandler( handler:TMessageHandler, events:String[] )
		For Local event:String = EachIn events
			handlers.insert( event, handler )
		Next
	End Method

	'V0.2
	' Get a Message Handler
	Method getMessageHandler:TMessageHandler( methd:String )
		Return TMessageHandler( handlers.valueForkey( methd ) )
	End Method
EndRem
	
	Method sendPreInitialisedError:Object( id:String )
		client.send( Response_Error:JSON( ERR_SERVER_NOT_INITIALIZED, "Server is not initialised", id ) )
		Return Null
	End Method

	'	V0.3 EVENT HANDLERS
	'	WE MUST RETURN MESSAGE IF WE DO NOT HANDLE IT
	'	RETURN NULL WHEN MESSAGE HANDLED OR ERROR HANDLED
	
	'	##### GENERAL MESSAGES #####

	Method onExit:TMessage( message:TMessage )						' NOTIFICATION
		publish( "log", "DBG", "EVENT onExit()" )
		' QUIT MAIN LOOP
        AtomicSwap( QuitMain, False )
		'message.state = STATE_COMPLETE
		' NOTIFICATION: No response necessary
	End Method
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#initialize
	Method onInitialize:TMessage( message:TMessage )				' REQUEST
		Local id:String = message.getid()
		Local params:JSON = message.params
		
		'logfile.debug( "onInitialise()~n"+message.J.prettify() )
		
		' Client must extract capabilities etc.
		client.initialise( params )			' Will extract "capabilities" and "clientInfo"
		
		' Workspace must extract rootURI and anything else of interest
		'workspaces.initialise( params )		' Will extract "rootPath" and "workspaceFolders"
		
		' Standardise the rootUri path
		
		' Add the rootURI to workspaces
		'	(If multi-workspace is disabled, this will be set, otherwise it will be file:///"
		Local uri:TURI = New TURI( params.find( "rootUri" ).toString() )
		'logfile.debug( "ROOTURI:" ) 
		'logfile.debug( "-~tOriginal: "+uri ) 
'		uri = TURI.parse( uri ).toString()			' Normalise the uri
		'logfile.debug( "-~tStandard: "+uri )
		'logfile.debug( "Adding 'root' workspace: "+uri )
		workspaces.add( uri, New TWorkspace( "root", uri ) )
		
		' Create a workspace and add it to the workspace manager
Rem
"workspaceFolders": [
      {
        "name": "example",
        "uri": "file: ///home/si/dev/example"
      },
      {
        "name": "testing",
        "uri": "file: ///home/si/dev/sandbox/transpiler/testing"
      }
    ]
EndRem
		Local workspaceFolders:JSON[] = params.find( "workspaceFolders" ).toArray()
		'logfile.debug( "WORKSPACEFOLDERS:~n"+params.find( "workspaceFolders" ).prettify() )
		'logfile.debug( "ARRAY:"+workspaceFolders[0].prettify() )
		'logfile.debug( workspacefolders.length + " WORKSPACES" )
		For Local workspace:JSON = EachIn workspaceFolders
			Local name:String = workspace.find( "name" ).toString()
			uri = New TURI( workspace.find( "uri" ).toString())
			'uri = TURI.parse( uri ).toString()			' Normalise the uri
			'logfile.debug( "ADDING '"+name+"' at "+uri )
			If name And uri
				'logfile.debug( ".. Adding" )
				workspaces.add( uri, New TWorkspace( name, uri ) )
			End If
		Next
		logfile.debug( "WORKSPACES:~n"+workspaces.reveal() )
		
		' Extract other information that we may need
		' clientProcessID = params.find( "processId" )
		' locale = params.find( "locale" )
		' initializationOptions = params.find( "initializationOptions" )
		' trace = params.find( "trace" )
		
		' Respond to the client
		Local serverCapabilities:JSON = New JSON()
		serverCapabilities.set( "textDocumentSync", TextDocumentSyncKind.INCREMENTAL.ordinal() )
		serverCapabilities.set( "completionProvider|resolveProvider", "true" )
		serverCapabilities.set( "definitionProvider", "true" )
		'serverCapabilities.set( "hoverProvider", "true" )
		'serverCapabilities.set( "signatureHelpProvider", [] )
		'serverCapabilities.set( "declarationProvider", [] )
		'serverCapabilities.set( "definitionProvider", [] )
		'serverCapabilities.set( "typeDefinitionProvider", [] )
		'serverCapabilities.set( "implementationProvider", [] )
		'serverCapabilities.set( "referencesProvider", [] )
		'serverCapabilities.set( "documentHighlightProvider", [] )
		'serverCapabilities.set( "documentSymbolProvider", [] )
		'serverCapabilities.set( "codeActionProvider", [] )
		'serverCapabilities.set( "codeLensProvider", [] )
		'serverCapabilities.set( "documentLinkProvider", [] )
		'serverCapabilities.set( "colorProvider", [] )
		'serverCapabilities.set( "documentFormattingProvider", [] )
		'serverCapabilities.set( "documentRangeFormattingProvider", [] )
		'serverCapabilities.set( "documentOnTypeFormattingProvider", [] )
		'serverCapabilities.set( "renameProvider", [] )
		'serverCapabilities.set( "foldingRangeProvider", [] )
		'serverCapabilities.set( "executeCommandProvider", [] )
		'serverCapabilities.set( "selectionRangeProvider", [] )
		'serverCapabilities.set( "linkedEditingRangeProvider", [] )
		'serverCapabilities.set( "callHierarchyProvider", [] )
		'serverCapabilities.set( "monikerProvider", [] )
		'serverCapabilities.set( "workspaceSymbolProvider", [] )
		If client.has( "workspace|workspaceFolders" ) 
			Publish( "log", "DBG", "# Client HAS workspace|workspaceFolders" )
			serverCapabilities.set( "workspace|workspaceFolders|supported", True )
			serverCapabilities.set( "workspace|workspaceFolders|changeNotifications", True )
		End If
		serverCapabilities.set( "workspace|fileOperations|didCreate|filters|scheme", "file" )
		serverCapabilities.set( "workspace|fileOperations|willCreate|filters|scheme", "file" )
		serverCapabilities.set( "workspace|fileOperations|didRename|filters|scheme", "file" )
		serverCapabilities.set( "workspace|fileOperations|willRename|filters|scheme", "file" )
		serverCapabilities.set( "workspace|fileOperations|didDelete|filters|scheme", "file" )
		serverCapabilities.set( "workspace|fileOperations|willDelete|filters|scheme", "file" )
		'serverCapabilities.set( "experimental", [] )
		
		Local InitializeResult:JSON = Response_OK( id )

        'InitializeResult.set( "result|capabilities", lsp.capabilities )
        InitializeResult.set( "result|capabilities", serverCapabilities )
        InitializeResult.set( "result|serverinfo", [["name","~q"+AppTitle+"~q"],["version","~q"+version+"."+build+"~q"]] )

		'Publish( "log", "DEBG", "CAPABLITIES: "+serverCapabilities.Prettify() )

		' SEND RESPONSE
		client.send( InitializeResult )

		' Enable all other message processing
		initialised = True
	End Method
	
	Method onInitialized:TMessage( message:TMessage )		' NOTIFICATION
		publish( "log", "DBG", "EVENT onInitialized()" )
		
		' Dynamically Register Capabilities
		client.RegisterForConfigChanges()		' Register for configuration changes
		'message.state = STATE_COMPLETE
		
		' Request Workspace folders that are open
		Local workspaceFolders:JSON = New JSON()
		workspaceFolders.set( "jsonrpc", JSONRPC )
		workspaceFolders.set( "method", "workspace/workspaceFolders" )
		workspaceFolders.set( "params", "null" )
		client.send( workspaceFolders )
		
		' NOTIFICATION: No response necessary
	End Method 

	Method onShutdown:TMessage( message:TMessage )			' REQUEST
		Local id:String = message.getid()
		publish( "log", "DBG", "EVENT onShutdown()" )
		shutdown = True
		'
		'message.state = STATE_COMPLETE
		' SEND RESPONSE
		client.send( Response_OK( id ) )
	End Method
	
	' Trace notifications
	Method OnSetTraceNotification:TMessage( message:TMessage )			' NOTIFICATION
		publish( "log", "DBG", "EVENT onSetTraceNotification()" )
		' Set our value to match params:
		Local J:JSON = message.J.find( "params|value" )
		If J 
			Publish( "log","DBG", J.prettify() )
			setTrace = J.toString()
		End If
		' NOTIFICATION: No response necessary
	End Method
	
	'	##### WORKSPACE MESSAGES #####
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#workspace_workspaceFolders
	Method onWorkspaceFolders:TMessage( message:TMessage )				' NOTIFICATION
		publish( "log", "DBG", "## NOT IMPLEMENTED: onWorkspaceFolders()~n"+message.J.Prettify() )
	End Method

	'https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#workspace_didChangeWorkspaceFolders
	Method onDidChangeWorkspaceFolders:TMessage( message:TMessage )		' NOTIFICATION
		publish( "log", "DBG", "## NOT IMPLEMENTED: onDidChangeWorkspaceFolders()~n"+message.J.Prettify() )
		
		Local params:JSON = message.params
		Local added:JSON[] = params.find( "added" ).toArray()
		Local removed:JSON[] = params.find( "remove" ).toArray()
		
		For Local item:JSON = EachIn added
			Local name:String = item.find( "name" ).toString()
			Local uri:String = item.find( "uri" ).toString()
			If uri
				'Workspaces.add( uri, New TWorkspace( name, uri ) )
			End If
		Next

		For Local item:JSON = EachIn removed
			Local uri:TURI = New TURI( item.find( "uri" ).toString() )
			If uri ; Workspaces.remove( uri )
			
			' Check if we just removed the root workspace
			'If rooturi = uri
			'	
			'	If added.length >0
			'		' Use the newly added record as new root uri
			'		rooturi = added[0].find( "uri" ).toString()
			'		rootworkspace = Workspaces.get( rooturi )
			'	Else
			'		Local workspace:TWorkspace = Workspaces.getfirst()
			'		If Not workspace ; Continue	' This seems to only occur when server shutting down
			'		rooturi = workspace.uri
			'		rootworkspace = workspace
			'	End If
			'	
			'End If
		Next
		
logfile.debug( "WORKSPACES:~n"+workspaces.reveal() )

		'If Not rootworkspace Return Null

logfile.debug( ">> REVIEWING WORKSPACES" )

		' Check if any documents in the root workspace should be moved
		'For Local document:TTextDocument = EachIn rootworkspace.all()
		'	Local workspace:TWorkspace = Workspaces.get( document.uri )
		'	If Not workspace ; Continue
		'	' Candidate found, so move it...
		'	workspace.document_add( document.uri, document )
		'	rootworkspace.document_remove( document.uri )
		'Next

logfile.debug( "WORKSPACES:~n"+workspaces.reveal() )

	End Method

	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#workspace_didChangeConfiguration
	Method onDidChangeConfiguration:TMessage( message:TMessage )		' NOTIFICATION
		publish( "log", "DBG", "## NOT IMPLEMENTED: onDidChangeConfiguration()~n"+message.J.Prettify() )
		Local params:JSON = message.params
		
		'Local workspace:TWorkspace = Workspaces.findUri( uri )
		'workspace.config_update( cfg )
		
		' Lint all files in workspace using new config settings
		' foreach document in workspace
		'	document.lint()
		' next
	End Method

	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#workspace_configuration
	Method onWorkspaceConfiguraion:TMessage( message:TMessage )			' REQUEST
		Local id:String = message.getid()
		publish( "log", "DBG", "## NOT IMPLEMENTED: onWorkspaceConfiguraion()~n"+message.J.Prettify() )
		client.send( Response_OK( id ) )
	End Method

	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#workspace_didChangeWatchedFiles
	Method onDidChangeWatchedFiles:TMessage( message:TMessage )			' NOTIFICATION
		publish( "log", "DBG", "## NOT IMPLEMENTED: onDidChangeWatchedFiles()~n"+message.J.Prettify() )
		
		Local params:JSON = message.params
		
		' PSUDOCODE UNTIL I SEE A REAL MESSAGE
		
		' local changes:JSON[] = params.find( "changes" ).toArray()
		' for local change:JSON = eachin changes
		'	local uri:String = change.find( "uri" )
		'	local extension:string = extractExt( uri )
		'	Local workspace:TWorkspace = Workspaces.findUri( uri )
		'	CAN BE BMX OR CONFIGURATION
		'	select extension
		'	case "bmx"
		'		add, remove or delete!
		'	case "???" ' Will this be an xml or json etc?
		'	end select
		'		
		
		'workspace.config_update( cfg )
		
	End Method

	'	##### TEST DOCUMENT SYNC #####
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_didOpen
	' textDocument/didOpen
	Method onDidOpen:TMessage( message:TMessage )						' NOTIFICATION
		publish( "log", "DBG", "NOT IMPLEMENTED: onDidOpen()" )
		'
Try
		Local params:JSON = message.params
		Local uri:TURI = New TURI( params.find( "textDocument|uri" ).tostring() )
		'Local languageid:String = params.find( "textDocument|languageId" ).toString()
		Local Text:String = params.find( "textDocument|text" ).toString()
		Local version:UInt = params.find( "textDocument|version" ).toint()
		
		logfile.debug( "DOCUMENT: "+uri.tostring() )
		Local document:TFullTextDocument = New TFullTextDocument( uri, Text, version )
		logfile.debug( "Created document" )
		Local workspace:TWorkspace = Workspaces.get( uri )
	If Not workspace logfile.debug( "WORKSPACE IS NULL" )
	If Not document logfile.debug( "DOCUMENT IS NULL" )
		If workspace And document
			logfile.debug( "Got workspace" )
			workspace.add( uri, document )
	'logfile( "Document is in workspace: "+workspace.name )
			logfile.debug( "WORKSPACES:~n"+workspaces.reveal() )
			' Run Linter
			'lint( document )
		
			' Wake up the Document Thread
			'PostSemaphore( semaphore )
		End If
	Catch Exception:Object
			logfile.debug( Exception.toString() )
	End Try
		
		' NOTIFICATION: No response required.
	End Method

	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_didChange
	' textDocument/didChange
	Method onDidChange:TMessage( message:TMessage )						' NOTIFICATION
Rem
{
  "jsonrpc": "2.0",
  "method": "textDocument/didChange",
  "params": {
    "contentChanges": [
      {
        "range": {
          "end": {
            "character": 1,
            "line": 9
          },
          "start": {
            "character": 0,
            "line": 9
          }
        },
        "rangeLength": 1,
        "text": ""
      }
    ],
    "textDocument": {
      "uri": "file: ///home/si/dev/sandbox/transpiler/visualiser.bmx",
      "version": 9
    }
  }
}
End Rem
		logfile.warning( "## NOT IMPLEMENTED: onDidChange()~n"+message.J.Prettify() )
		
		Local params:JSON = message.params
		Local uri:String = params.find( "textDocument|uri" ).tostring()
		Local ver:Int = params.find( "textDocument|uri" ).toint()
		Local contentChanges:JSON[] = params.find( "contentChanges" ).toArray()

		'Local workspace:TWorkspace = Workspaces.findUri( uri )
		'workspace.document_update( uri, contentChanges )	

		' Run Linter
		'lint( document )
	End Method
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_willSave
	' textDocument/willSave
	Method onWillSave:TMessage( message:TMessage )						' NOTIFICATION
		publish( "log", "DBG", "## NOT IMPLEMENTED: onWillSave()~n"+message.J.Prettify() )
	End Method
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_willSaveWaitUntil
	' textDocument/willSaveWaitUntil
	Method onWillSaveWaitUntil:TMessage( message:TMessage )				' REQUEST
		Local id:String = message.getid()
		publish( "log", "DBG", "## NOT IMPLEMENTED: onWillSaveWaitUntil()~n"+message.J.Prettify() )
		client.send( Response_OK( id ) )
	End Method
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_didSave
	' textDocument/didSave
	Method onDidSave:TMessage( message:TMessage )						' NOTIFICATION
		publish( "log", "DBG", "## NOT IMPLEMENTED: onDidSave()~n"+message.J.Prettify() )
		Local params:JSON = message.params
		Local uri:String  = params.find( "textDocument|uri" ).tostring()
		'local document:TFullTextDocument = Workspaces.document_get( uri )
		' Run Linter
		'lint( document )
	End Method
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_didClose
	' textDocument/didClose
	Method onDidClose:TMessage( message:TMessage )						' NOTIFICATION
Rem
{
  "jsonrpc": "2.0",
  "method": "textDocument/didClose",
  "params": {
    "textDocument": {
      "uri": "file: ///home/si/dev/sandbox/transpiler/visualiser.bmx"
    }
  }
}
End Rem
		publish( "log", "DBG", "## NOT IMPLEMENTED: onDidClose()~n"+message.J.Prettify() )
		Local params:JSON = message.params

		Local uri:TURI = New TURI( params.find( "textDocument|uri" ).tostring() )
		Local workspace:TWorkspace = Workspaces.get( uri )
		workspace.remove( uri )
		logfile.debug( "WORKSPACES:~n"+workspaces.reveal() )
	End Method

	'	##### LANGUAGE FEATURES #####
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_completion
	Method onCompletion:TMessage( message:TMessage )		; 	bls_textDocument_completion( message )	; 	End Method
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#completionItem_resolve
	Method onCompletionResolve:TMessage( message:TMessage )	;	bls_textDocument_completion( message )	;	End Method
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_hover
	Method onHover:TMessage( message:TMessage )							' REQUEST
		Local id:String = message.getid()
		Publish( "log", "DBG", "TLSP.onHover()" )
		If Not message Or Not message.J
			client.send( Response_Error( ERR_INTERNAL_ERROR, "Null value" ) )
			Return Null
		End If
		logfile.info( "~n"+message.j.Prettify() )
		' We have NOT dealt with it, so return message
		client.send( Response_OK( id ) )
	End Method
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_definition
	Method onDefinition:TMessage( message:TMessage )	; bls_textDocument_definition( message )	;	End Method

	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_documentSymbol
	Method onDocumentSymbol:TMessage( message:TMessage )				' REQUEST
		Local id:String = message.getid()
		publish( "log", "DBG", "## NOT IMPLEMENTED: onWillSaveWaitUntil()~n"+message.J.Prettify() )
		client.send( Response_OK( id ) )
	End Method

End Type