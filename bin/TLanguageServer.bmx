
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, July 2021, All Right Reserved

'Include "TLSP_Stdio.bmx"	'	DEPRECIATED - Moved to TClient_StdIO
'Include "TLSP_TCP.bmx"		'	DEPRECIATED - Moved to TClient_TCP

Type TLanguageServer Extends TEventHandler
    Global instance:TLanguageServer

	Const STATE_UNINITIALISED:Int	= 0
	Const STATE_INITIALISING:Int	= 1
	Const STATE_INITIALISED:Int		= 2
	Const STATE_SHUTDOWN:Int		= 3
	
	Const REQUEST_EXPIRATION:Int	= 350000 ' 5 minutes in milliseconds

    Field exitcode:Int				= 0

	Field state:Int					= STATE_UNINITIALISED
	'Field initialised:Int			= False   	' Set by "initialized" message
    'Field shutdown:Int				= False		' Set by "shutdown" message
	Field onTrace:String				= "off"		' Set by $/setTrace or OnTraceNotification
	Field sendbuffer:TTask[]		= []
	
	Field requests:TMap							' Requests that have been sent to client
	
	' ROOT URI and ROOT WORKSPACE are now saved into TWorkspaces
	'Field rooturi:String					' Root URI
	'Field rootworkspace:TWorkspace			' Root workspace
	
    'Field client:TClient = New TClient()		' Moved to a global

	' Create a document manager
	'Field textDocument:TTextDocument_Handler	' Do not initialise here: Depends on lsp.

    ' Threads
    Field QuitMain:Int = False       ' Atomic State - Set by "exit" message

    Field Receiver:TThread
    Field QuitReceiver:Int = True   ' Atomic State

    Field Sender:TThread
    Field QuitSender:Int = True     ' Atomic State

    Field ThreadPool:TThreadPoolExecutor
    Field ThreadPoolSize:Int
    Field sendMutex:TMutex = CreateMutex()

	' System
	'Field capabilities:JSON = New JSON()	' Empty object
	'Field handlers:TMap = New TMap
	
	Method New()
'DebugStop
		' V4 - Register handler
		register()
		requests = New TMap()				' Requests sent to client
	End Method
	
    'Method run:Int() Abstract
    'Method getRequest:String() Abstract     ' Waits for a message from client

    Method Close() ; End Method

	' Send a message to the client 
	' It will buffer messages sent before initialisation has completed.
	Method send( message:JSON )
		Local response:Int = False
		' Check we have a valid JSON object, or replace with error
		If Not message ; message = Response_Error( ERR_INTERNAL_ERROR, "Incomplete Event" ) 
		Local id:String = message.find("id").toString()
		Local methd:String = message.find("method").toString()
		
		' Extract message
		Local Text:String = message.stringify()
		If Not Text ; Return
		
		' Message Classification
		Local class:Int = $000
		If id<>""    ; class = TMessage._ID
		If methd<>"" ; class :+ TMessage._METHOD
		
		'Trace.debug( "# METHOD IS '"+ message.find("method").tostring()+"'" )
		'If response 
		Trace.debug( "# MESSAGE CLASS IS "+class )

		' Validation
		Local allowed:Int = ( state = STATE_INITIALISED )
		Select class 
		Case TMessage._RESPONSE
			allowed = True
		Case TMessage._REQUEST
			' SERVER REQUESTS (To Client) should be inserted into requests queue
			message.set( "created", MilliSecs() )
			requests.insert( id, New TServerRequest( message ) )
		EndSelect

		' Check if we are allowed to send!
		If Not allowed
			Select state
			Case STATE_UNINITIALISED		' Server not connected, nothing to send to!
				Trace.critical( "## SERVER IS UNINITIALISED:~n"+Text )
			Case STATE_INITIALISING
				Select methd
				Case "initialize", "window/showMessage", "window/logMessage", "telemetry/event", "window/showMessageRequest"
					allowed = True
				End Select
			'Case STATE_INITIALISED
			'	allowed = True
			Case STATE_SHUTDOWN
				Trace.critical( "## SERVER IS SHUTDOWN:~n"+Text )
			End Select
		End If
		Trace.debug( "# ALLOWED TO SEND: "+["FALSE","TRUE"][allowed]+" ("+allowed+")" )
		
		' Send message
		Local msg:TTask = New TTaskSend( Text )
		If allowed	' SEND MESSAGE
			msg.post()
		Else		' ADD TO BUFFER
			Trace.debug( "# BUFFERING MESSAGE:~n"+Text )
			sendbuffer :+ [msg]
		End If
		
		' Send buffered messages?
		If state = STATE_INITIALISED And sendbuffer<>[]
			Trace.debug( "# EMPTYING BUFFER" )
			For msg = EachIn sendbuffer
				'Local msg:TTask = New TTaskSend( buffered )
				msg.post()
				'client.sendMessage( buffered )
			Next
			sendbuffer = []			
			Trace.debug( "# BUFFER EMPTY" )
		End If
			
	End Method
	
	Function Typeof:String( o:Object )
		Local typeid:TTypeId = TTypeId.ForObject( o )
		If typeid ; Return typeid.name()
		Return "UNKNOWN"
	End Function
	
	Method matchResponseToRequest:TServerRequest( id:String )
		Trace.debug( "MATCHING ID="+id )
		
'		For Local key:String = EachIn requests.keys()
'			Local o:Object = requests[key]
'			Trace.debug( "- KEY:"+key+" = "+typeof( o ) )
'		Next
		
		' Pop Request (if it exists)
		Local request:TServerRequest = TServerRequest( requests.valueForKey( id ) )
		If request ; requests.remove( id )
		
		If request 
			Trace.debug( "- REQUEST FOUND" )
		Else
			Trace.debug( "- REQUEST NOT FOUND" )
		End If

		' Timeout old messages			
		For Local key:String = EachIn requests.keys()
			Local message:TServerRequest = TServerRequest( requests[key] )
			If message 
				If message.timeout()
					Trace.debug( "- KEY "+key+" TIMEOUT" )
					requests.remove( key )
				End If
			Else
				' Invalid message, remove key
			    Trace.debug( "- INVALID KEY "+key+" REMOVED" )
				requests.remove( key )
			End If
		Next
		
		Return request
	End Method
	
	'V0.0
    Function ExitProcedure()
        'Publish( "debug", "Exit Procedure running" )
        'Publish( "exitnow" )
		Trace.info( "Running Exit Procedure" )
        instance.Close()
        'Trace.Close()

		'	STOP the global message queue
		Trace.debug( "- Stopping Message Queue" )
		TaskQueue.stop()
		Trace.debug( "- Message Queue Stopped" )
		
    End Function

Rem
	'V0.1
    ' Thread based message receiver
    Function ReceiverThread:Object( data:Object )
        Local lsp:TLanguageServer = TLanguageServer( data )
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
				Trace.error( content )
				If J.isInvalid()
					errtext = "ERROR("+J.errNum+") "+J.errText+" at {"+J.errLine+","+J.errpos+"}"
				Else
					errtext = "ERROR: Parse returned null"
				End If
                ' Send error message to LSP Client
				'Publish( "debug", errtext )
                'Publish( "send", Response_Error( ERR_PARSE_ERROR, errtext ) )
				Trace.debug( errtext )
				'send( Response_Error( ERR_PARSE_ERROR, errtext ) )
                Continue
            End If
			'Publish( "debug", "Parse successful" )
					

			' J is my JSON (Freshly arrived from IDE)

			Local message:TMessage = New TMessage( J )
			Local methd:String = message.methd

			Trace.debug( "- ID:      "+message.id )
			Trace.debug( "- METHOD:  "+message.methd )
			Trace.debug( "- CLASS:   "+message.classname() )
		
			Select message.class
			Case TMessage._REQUEST
			
				' Check server has initialised
				Select True
				Case lsp.state = lsp.STATE_INITIALISED And methd="initialize"
					Trace.critical( "## Server already initialized~n"+J.stringify() )
					lsp.send( Response_Error( ERR_INVALID_REQUEST, "Server already initialized", message.id ) )
					Continue
				Case lsp.state <> lsp.STATE_INITIALISED And methd<>"initialize"
					Trace.critical( "## Server is not initialized~n"+J.stringify() )
					lsp.send( Response_Error( ERR_SERVER_NOT_INITIALIZED, "Server is not initialized", message.id ))
					Continue
				End Select
				
				' Add message to queue
				message.priority = QUEUE_PRIORITY_REQUEST
				message.postv1()
				
			Case TMessage._RESPONSE

				' Add message to queue
				message.priority = QUEUE_PRIORITY_RESPONSE
				message.postv1()
				
			Case TMessage._NOTIFICATION
			
				' Add message to queue
				message.priority = QUEUE_PRIORITY_NOTIFICATION
				message.postv1()
				
			Default
				Trace.critical( "## Invalid message~n"+J.Stringify() )
				Continue
			End Select


        Until CompareAndSwap( lsp.QuitReceiver, quit, True )
        'Publish( "debug", "ReceiverThread - Exit" )
    End Function
End Rem

	' Report an Implementation Incomplete State
	Method ImplementationIncomplete( message:TMessage )
		Trace.error( "## IMPLEMENTATION INCOMPLETE: "+message.className()+"{"+message.getid()+"|"+message.methd+"}~n"+message.J.Prettify() )
	End Method

Rem
	'V0.1
    ' Thread based message sender
    Function SenderThread:Object( data:Object )
        Local lsp:TLanguageServer = TLanguageServer( data )
        Local quit:Int = False          ' Always got to know when to quit!
        
        'DebugLog( "SenderThread()" )
        Repeat
            Try
                'Publish( "debug", "TLSP.SenderThread going to sleep")
                Trace.debug("TLSP.SenderThread going To sleep")
				
                WaitSemaphore( client.sendcounter )
                'Publish( "debug", "TLSP.SenderThread is awake" )
                Trace.debug( "TLSP.SenderThread is awake" )
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
                'Publish( "log", "CRIT", Exception )
				Trace.critical( Exception )
            End Try
        Until CompareAndSwap( lsp.QuitSender, quit, True )
        'Publish( "debug", "SenderThread - Exit" )
        Trace.debug( "SenderThread - Exit" )
    End Function  
End Rem

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
	
'	Method sendPreInitialisedError:Object( id:String )
'		client.send( Response_Error:JSON( ERR_SERVER_NOT_INITIALIZED, "Server is not initialised", id ) )
'		Return Null
'	End Method

	'	V4 MESSAGE HANDLERS
	'	REQUESTS MUST RETURN A RESPONSE OR CLIENT IS SENT AN ERROR
		
	' ############################################################
	' ##### GENERAL MESSAGES #####################################

	Method on_Exit:JSON( message:TMessage )						' NOTIFICATION
		Trace.debug( "TLSP.onExit()" )

		' QUIT MAIN LOOP
        AtomicSwap( QuitMain, True )

		'	STOP the global message queue
		Trace.debug( "- Stopping Message Queue" )
		TaskQueue.stop()
		Trace.debug( "- Message Queue Stopped" )
		
		' NOTIFICATION: No response necessary
	End Method
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#initialize
	Method on_Initialize:JSON( message:TMessage )				' REQUEST
		'Trace.debug( "MESSAGE:~n"+message.J.prettify() )
		Local id:String = message.getid()
		Local params:JSON = message.params
	
		state = STATE_INITIALISING
				
		'Trace.debug( "onInitialise()~n"+message.J.prettify() )
		'Trace.debug( "ONINITIALISE ID="+id )
		
		' Client must extract capabilities etc.
		client.initialise( params )			' Will extract "capabilities" and "clientInfo"
		
		' Workspace must extract rootURI and anything else of interest
		'workspaces.initialise( params )		' Will extract "rootPath" and "workspaceFolders"
		
		' Standardise the rootUri path
		'	(If multi-workspace is disabled, this will be set, otherwise it will be file:///"
		Local uri:TURI = New TURI( params.find( "rootUri" ).toString() )
		'Trace.debug( "ROOTURI:" + params.find( "rootUri" ).toString() ) 
		'Trace.debug( "ROOTURI:" + uri.toString() ) 
		'Trace.debug( "-~tOriginal: "+uri ) 
'		uri = TURI.parse( uri ).toString()			' Normalise the uri
		'Trace.debug( "-~tStandard: "+uri )
		'Trace.debug( "Adding 'root' workspace: "+uri )
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
		If params.contains( "workspaceFolders" )
			Local workspaceFolders:JSON[] = params.find( "workspaceFolders" ).toArray()
			'Trace.debug( "WORKSPACEFOLDERS:~n"+params.find( "workspaceFolders" ).prettify() )
			'Trace.debug( "ARRAY:"+workspaceFolders[0].prettify() )
			'Trace.debug( workspacefolders.length + " WORKSPACES" )
			For Local workspace:JSON = EachIn workspaceFolders
				Local name:String = workspace.find( "name" ).toString()
				uri = New TURI( workspace.find( "uri" ).toString())
				'uri = TURI.parse( uri ).toString()			' Normalise the uri
				'Trace.debug( "ADDING '"+name+"' at "+uri )
				If name And uri
					'Trace.debug( ".. Adding" )
					workspaces.add( uri, New TWorkspace( name, uri ) )
				End If
			Next
			Trace.debug( "WORKSPACES:~n"+workspaces.reveal() )
		End If
		
		' Extract other information that we may need
		' clientProcessID = params.find( "processId" )
		' locale = params.find( "locale" )
		' initializationOptions = params.find( "initializationOptions" )
		' ontrace = params.find( "trace" )
		
		Local value:String = params.find( "trace" ).toString()
		If value = "off" Or value="messages" Or value="verbose"
			onTrace = value
		End If
		Trace.info( "# TraceValue is '"+onTrace+"'" )
		
		' Respond to the client
		Local serverCapabilities:JSON = New JSON()
		serverCapabilities.set( "textDocumentSync", TextDocumentSyncKind.INCREMENTAL.ordinal() )
		'serverCapabilities.set( "completionProvider|resolveProvider", "true" )
		'serverCapabilities.set( "completionProvider|workDoneProgress", "true" )
		'serverCapabilities.set( "definitionProvider", "true" )
		If client.contains( "workspace|symbol" ) And config.has( "experimental|hover" )
			Trace.debug( "# ENABLING: hoverProvider" )
			serverCapabilities.set( "hoverProvider", "true" )
			'serverCapabilities.set( "hoverProvider|workDoneProgress", "true" )
		End If
		If client.contains( "textDocument|signatureHelp" ) And config.has( "experimental|sighelp" )
			Trace.debug( "# ENABLING: signatureHelpProvider" )
			serverCapabilities.set( "signatureHelpProvider|triggerCharacters", "(" )
			serverCapabilities.set( "signatureHelpProvider|retriggerCharacters", ",:" )
			'serverCapabilities.set( "signatureHelpProvider|workDoneProgress", "true" )
		End If
		'serverCapabilities.set( "declarationProvider", [] )
		'serverCapabilities.set( "definitionProvider", [] )
		'serverCapabilities.set( "typeDefinitionProvider", [] )
		'serverCapabilities.set( "implementationProvider", [] )
		'serverCapabilities.set( "referencesProvider", [] )
		'serverCapabilities.set( "referencesProvider|workDoneProgress", "true" )
		'serverCapabilities.set( "documentHighlightProvider", [] )
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
		'serverCapabilities.set( "executeCommandProvider|workDoneProgress", "true" )
		'serverCapabilities.set( "selectionRangeProvider", [] )
		'serverCapabilities.set( "linkedEditingRangeProvider", [] )
		'serverCapabilities.set( "callHierarchyProvider", [] )
		'serverCapabilities.set( "monikerProvider", [] )

		'	TEXT DOCUMENT CAPABILITIES
		
		'If client.has( "textDocument|documentSymbol" )
			serverCapabilities.set( "documentSymbolProvider", True )
			serverCapabilities.set( "documentSymbolProvider|workDoneProgress", "true" )
		'End If

		
		'	WORKSPACE CAPABILITIES
		
		If client.contains( "workspace|symbol" ) And config.has( "experimental|wsym" )
			Trace.debug( "# ENABLING: workspaceSymbolProvider" )
			If client.has( "workspace|symbol|workDone" )	'Progress support
			'serverCapabilities.set( "workspaceSymbolProvider", [] )
				serverCapabilities.set( "workspaceSymbolProvider|workDoneProgress", "true" )
			Else
				serverCapabilities.set( "workspaceSymbolProvider", "true" )
			End If
		End If
		If client.has( "workspace|workspaceFolders" ) 
			Trace.debug( "# ENABLING: workspace|workspaceFolders" )
			serverCapabilities.set( "workspace|workspaceFolders|supported", "true" )
			' send plural and non-plural due to a typo in the LSP 3.16 documentation that doesn't explain
			' which one is correct!
			serverCapabilities.set( "workspace|workspaceFolders|changeNotifications", "true" )
			serverCapabilities.set( "workspace|workspaceFolders|changeNotification", "true" )
		End If
		'If client.has( "workspace|configuration" )
		'	Trace.debug( "# ENABLING: workspace|configuration" )
		'	serverCapabilities.set( "workspace|configuration", "file" )
		'End If
		'serverCapabilities.set( "workspace|fileOperations|didCreate|filters|scheme", ["file"] )
		'serverCapabilities.set( "workspace|fileOperations|willCreate|filters|scheme", "file" )
		'serverCapabilities.set( "workspace|fileOperations|didRename|filters|scheme", "file" )
		'serverCapabilities.set( "workspace|fileOperations|willRename|filters|scheme", "file" )
		'serverCapabilities.set( "workspace|fileOperations|didDelete|filters|scheme", "file" )
		'serverCapabilities.set( "workspace|fileOperations|willDelete|filters|scheme", "file" )
		'serverCapabilities.set( "experimental", [] )
		
		'	PREPARE RESPONSE
		
		Local InitializeResult:JSON = Response_OK( id )

        'InitializeResult.set( "result|capabilities", lsp.capabilities )
        InitializeResult.set( "result|capabilities", serverCapabilities )
        InitializeResult.set( "result|serverinfo", [["name","~q"+AppTitle+"~q"],["version","~q"+appvermax+"."+appvermin+" build "+appbuild+"~q"]] )

		'Publish( "log", "DEBG", "CAPABLITIES: "+serverCapabilities.Prettify() )

		' Enable all other message processing
		' initialised = True 
		state = STATE_INITIALISED
		
		' REQUEST: Return response
		Return InitializeResult
	End Method
	
	Method on_Initialized:JSON( message:TMessage )		' NOTIFICATION
		'publish( "log", "DBG", "EVENT onInitialized()" )
		Trace.debug( "TLSP.on_Initialized()" )
		
		' Dynamically Register Capabilities
		'client.RegisterForConfigChanges()		' Register for configuration changes
		'message.state = STATE_COMPLETE
		
		' Request Workspace folders that are open
		'Local workspaceFolders:JSON = New JSON()
		'workspaceFolders.set( "jsonrpc", JSONRPC )
		'workspaceFolders.set( "jsonrpc", JSONRPC )
		'workspaceFolders.set( "method", "workspace/workspaceFolders" )
		'workspaceFolders.set( "params", "null" )
		'client.send( workspaceFolders )

Rem ' TEST A PROGRESS BAR
If client.has( "window|workDoneProgress" )
	Trace.debug( "## CLIENT SUPPORTS: window|workDoneProgress" )
	
	' Generate and register a token
	Local workDoneToken:String = client.progress_register()
	client.progress_begin( workDoneToken, "Testing a progress Bar", String(MilliSecs())+"ms" )

	Local time:Int = MilliSecs() + 1000
	Local finished:Int = MilliSecs() + 10000
	Local count:Int = 0
	Repeat
		If MilliSecs() > time
			time :+ 1000
			client.progress_update( workDoneToken, String(time)+"ms", count )
			count :+ 10
		End If	
	Until MilliSecs() > finished	
	client.progress_end( workDoneToken, "Completed" )
Else
	Trace.debug( "## CLIENT DOES NOT SUPPORT: window|workDoneProgress" )
End If
EndRem

		'Trace.trace( "THIS IS A TEST 'LOGTRACE' MESSAGE", "WITH VERBOSE STUFF IN HERE, SORRY ABOUT ALL THE WAFFLE" )
		
		'	MODULE COMPATABILITY

		If Not JSON.VersionCheck( JSON_MINIMUM_VERSION, 0 )
			Local error:String = "JSON Version "+JSON.Version()+" is not compatible."
			Trace.critical( "## "+error )
			client.logMessage( error, EMessageType.Error.Ordinal() )
		'	Print( error )
		End If
		
		' NOTIFICATION: No response necessary
	End Method 

	Method on_Shutdown:JSON( message:TMessage )			' REQUEST
		Trace.debug( "TLSP.onShutdown()" )
		state = STATE_SHUTDOWN
		' SEND RESPONSE
		Return Response_OK( message.getid() )
	End Method

	' ############################################################
	' #####TRACE NOTIFICATIONS ###################################

	' 3.16 documentation says $/setTrace, but VSCODE sends $/setTraceNotification
	Method on_dollar_setTrace:JSON( message:TMessage )					' NOTIFICATION
		Trace.debug( "TLSP.on_dollar_setTrace()~n"+message.J.prettify() )
		Local value:String = message.params.find( "value" ).toString()
		If value = "off" Or value="messages" Or value="verbose"
			onTrace = value
			Trace.info( "## TraceValue is '"+onTrace+"'" )
		End If
		' NOTIFICATION: No response necessary
	End Method
	
	' 3.16 documentation says $/setTrace, but VSCODE sends $/setTraceNotification
	' Library version in BlitzMax Extension updated by Hezkore 12/11/21 fixed this issue
	' Trace notifications
'	Method on_dollar_setTraceNotification:JSON( message:TMessage )			' NOTIFICATION
'		Trace.debug( "TLSP.on_dollar_setTraceNotification()~n"+message.J.prettify() )
'		Local value:String = message.params.find( "value" ).toString()
'		If value = "off" Or value="message" Or value="verbose"
'			trace = value
'			Trace.info( "? TraceValue is now: '"+trace+"'" )
'		End If
'		' NOTIFICATION: No response necessary
'	End Method
'
	'	##### TEXT DOCUMENT SYNC #####
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_didOpen
	' NOTIFICATION: textDocument/didOpen
	Method on_textDocument_didOpen:JSON( message:TMessage )
		Local params:JSON = message.params
		Local uri:TURI = New TURI( params.find( "textDocument|uri" ).tostring() )
		'Local languageid:String = params.find( "textDocument|languageId" ).toString()
		Local Text:String = params.find( "textDocument|text" ).toString()
		Local version:UInt = params.find( "textDocument|version" ).toint()
		
		Trace.debug( "DOCUMENT: "+uri.tostring() )

		Local workspace:TWorkspace = Workspaces.get( uri )
If Not workspace Trace.debug( "WORKSPACE IS NULL" )
		If Not workspace ; Return Null

		workspace.open( uri, Text, version )
		
		' NOTIFICATION: No response required.
	End Method

	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_didChange
	' NOTIFICATION: textDocument/didChange
	Method on_textDocument_didChange:JSON( message:TMessage )
		ImplementationIncomplete( message )
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
		
		Local params:JSON = message.params
		Local uri:String = params.find( "textDocument|uri" ).tostring()
		Local version:Int = params.find( "textDocument|version" ).toint()
		Local contentChanges:JSON[] = params.find( "contentChanges" ).toArray()

		Local workspace:TWorkspace = Workspaces.get( uri )
		workspace.change( uri, contentChanges, version )	

		' Add unique low priority tasks to test message queue
		'Local uniquetask:TTestTask = New TTestTask()
		'client.pushTaskQueue( uniquetask, "UNIQUETASK" )

		' Run Linter
		'lint( document )
		' NOTIFICATION: No response necessary
	End Method

	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_didClose
	' NOTIFICATION: textDocument/didClose
	Method on_textDocument_didClose:JSON( message:TMessage )
		'ImplementationIncomplete( message )
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
		Local params:JSON = message.params

		Local uri:TURI = New TURI( params.find( "textDocument|uri" ).tostring() )
		Local workspace:TWorkspace = Workspaces.get( uri )
		workspace.remove( uri )
		Trace.debug( "WORKSPACES:~n"+workspaces.reveal() )
		' NOTIFICATION: No response necessary
	End Method
		
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_willSave
	' textDocument/willSave
'	Method onWillSave:TMessage( message:TMessage )						' NOTIFICATION
'		ImplementationIncomplete( message )
'	End Method
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_willSaveWaitUntil
	' textDocument/willSaveWaitUntil
'	Method onWillSaveWaitUntil:TMessage( message:TMessage )				' REQUEST
'		ImplementationIncomplete( message )
'		Local id:String = message.getid()
'		lsp.send( Response_OK( id ) )
'	End Method
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_didSave
	' NOTIFICATION: textDocument/didSave
	Method on_textDocument_didSave:TMessage( message:TMessage )
		ImplementationIncomplete( message )
		Local params:JSON = message.params
		Local uri:String  = params.find( "textDocument|uri" ).tostring()
		'local document:TFullTextDocument = Workspaces.document_get( uri )
		' Run Linter
		'lint( document )
	End Method
	


	'	##### LANGUAGE FEATURES #####
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_completion
	'Method onCompletion:JSON( message:TMessage )		; 	Return bls_textDocument_completion( message )	; 	End Method
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#completionItem_resolve
	'Method onCompletionResolve:JSON( message:TMessage )	;	Return bls_textDocument_completion( message )	;	End Method
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_hover
'	Method onHover:TMessage( message:TMessage )							
	' REQUEST: textDocument/hover
	Method on_textDocument_hover:JSON( message:TMessage )
		Trace.debug( "MESSAGE:~n"+message.J.prettify() )

		ImplementationIncomplete( message )
		Return bls_textDocument_hover( message )
	End Method
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_definition
	' REQUEST: textDocument/definition
'	Method onDefinition:JSON( message:TMessage )	; Return bls_textDocument_definition( message )	;	End Method

	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_documentSymbol
	' REQUEST: textDocument/documentSymbol
	Method on_textDocument_documentSymbol:JSON( message:TMessage )
		Trace.debug( "MESSAGE:~n"+message.J.prettify() )
		Return bls_textDocument_documentSymbol( message )
	End Method

	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_signatureHelp
	' REQUEST: textDocument/signatureHelp
	Method on_textDocument_signatureHelp:JSON( message:TMessage )
		Trace.debug( "MESSAGE:~n"+message.J.prettify() )
		Return bls_textDocument_signatureHelp( message )
	End Method
	
	'	##### WORKSPACE MESSAGES #####
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#workspace_workspaceFolders
'	Method onWorkspaceFolders:TMessage( message:TMessage )				' NOTIFICATION
'		ImplementationIncomplete( message )
'	End Method

	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#workspace_didChangeWorkspaceFolders
	' NOTIFICATION: workspace/didChangeWorkspaceFolders
	Method on_workspace_didChangeWorkspaceFolders:JSON( message:TMessage )		
		'ImplementationIncomplete( message )
		
		Local params:JSON = message.params
		
		Local add:JSON = params.find( "event|added" )
Trace.debug( add.getClassName()+":"+add.stringify() )
		Local sub:JSON = params.find( "event|removed" )
Trace.debug( sub.getClassName()+":"+sub.stringify() )
		
		Local added:JSON[] = params.find( "event|added" ).toArray()
		Local removed:JSON[] = params.find( "event|removed" ).toArray()

Trace.debug( "ADDED: "+added.length )
If added.length>0 ; Trace.debug( added[0].stringify() )
Trace.debug( "REMOVED: "+removed.length )
If removed.length>0 ; Trace.debug( removed[0].stringify() )


		' Add new Workspaces
		For Local item:JSON = EachIn added
			Local name:String = item.find( "name" ).toString()
			Local uri:TURI = New TURI( item.find( "uri" ).toString() )
			Trace.debug( "Adding "+name+" - "+ uri.tostring() )
			Trace.debug( item.stringify() )
			If uri ; Workspaces.add( uri, New TWorkspace( name, uri ) )
		Next

		' Remove Workspaces (and files within them)
		For Local item:JSON = EachIn removed
			Local name:String = item.find( "name" ).toString()
			Local uri:TURI = New TURI( item.find( "uri" ).toString() )
			Trace.debug( "Removing "+name+" - "+ uri.tostring() )
			Trace.debug( item.stringify() )

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
		
Trace.debug( "WORKSPACES:~n"+workspaces.reveal() )

		'If Not rootworkspace Return Null

'Trace.debug( ">> REVIEWING WORKSPACES" )

		' Check if any documents in the root workspace should be moved
		'For Local document:TTextDocument = EachIn rootworkspace.all()
		'	Local workspace:TWorkspace = Workspaces.get( document.uri )
		'	If Not workspace ; Continue
		'	' Candidate found, so move it...
		'	workspace.document_add( document.uri, document )
		'	rootworkspace.document_remove( document.uri )
		'Next

'Trace.debug( "WORKSPACES:~n"+workspaces.reveal() )

	End Method

	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#workspace_symbol
	' REQUEST: workspace/symbol
	Method on_workspace_symbol:JSON( message:TMessage )		
		'ImplementationIncomplete( message )
'Trace.debug( "WORKSPACE/SYMBOLS - START" )

		Local id:String = message.getid()
		Local params:JSON = message.params
		'
		If Not params ; Return Response_Error( ERR_INVALID_PARAMS, "Invalid Params", id )
		Local query:String = ""
		Local criteria:JSON  = params.search( "query" )
		If criteria ; query = criteria.toString()
		'Trace.debug( "QUERY: "+query )
				
		Local response:JSON = Response_OK( id )
		
		' The request does not tell us which workspace the query should look in.
		' So for now, we need to return ALL symbols in ALL workspaces!!!
		Local data:JSON = New JSON( JARRAY )
		
		For Local key:String = EachIn Workspaces.list.keys()
			Local workspace:TWorkspace = TWorkspace( Workspaces.list[key] )
'Trace.debug( "WORKSPACE:" + workspace.name + "/" + key )
			If workspace.cache
				Local symbols:JSON[] = workspace.cache.getSymbols( query )
				' Append workspace symbols to results
				For Local symbol:JSON = EachIn symbols
					data.addlast( symbol )
				Next
'			Else
'Trace.debug( "- invalid cache" )
			End If
		Next


		' Insert workspace results set into response.
		response.set( "result", data )
'Trace.debug( "RESPONSE~n"+response.stringify() )
'Trace.debug( "WORKSPACE/SYMBOLS - FINISH" )
		Return response
	End Method

	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#workspace_didChangeConfiguration
'	Method onDidChangeConfiguration:TMessage( message:TMessage )		' NOTIFICATION
'		ImplementationIncomplete( message )
'		Local params:JSON = message.params
'		
'		'Local workspace:TWorkspace = Workspaces.findUri( uri )
'		'workspace.config_update( cfg )
'		
'		' Lint all files in workspace using new config settings
'		' foreach document in workspace
'		'	document.lint()
'		' next
'	End Method

	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#workspace_configuration
	' RESPONSE: workspace/symbol
	Method on_workspace_configuration:JSON( message:TMessage )		
		ImplementationIncomplete( message )
		Local request:TServerRequest = TServerRequest( message )
		
		If request
			Trace.debug( "# REQUEST ="+request.classname()+"{"+request.getid()+"|"+request.methd+"}" )
			Trace.debug( "# RESPONSE~n"+request.ClientResponse.prettify() )
		Else
			Trace.debug( "# RESPONSE WAS NOT MATCHED" )
		End If

		' DEBUG
		Local REQ:String = request.J.prettify()
		Local RES:String = request.ClientResponse.prettify()

		client.logmessage( "----- REQUEST -----~n"+REQ+"~n----- RESPONSE -----~n"+RES, LOG_DEBUG)


	End Method

	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#workspace_didChangeWatchedFiles
'	Method onDidChangeWatchedFiles:TMessage( message:TMessage )			' NOTIFICATION
'		ImplementationIncomplete( message )
'		
'		Local params:JSON = message.params
'		
'		' PSUDOCODE UNTIL I SEE A REAL MESSAGE
'		
''		' local changes:JSON[] = params.find( "changes" ).toArray()
'		' for local change:JSON = eachin changes
'		'	local uri:String = change.find( "uri" )
'		'	local extension:string = extractExt( uri )
'		'	Local workspace:TWorkspace = Workspaces.findUri( uri )
'		'	CAN BE BMX OR CONFIGURATION
'		'	select extension
'		'	case "bmx"
'		'		add, remove or delete!
'		'	case "???" ' Will this be an xml or json etc?
'		'	end select
'		'		
'		
'		'workspace.config_update( cfg )
'		
'	End Method

	' HANDLER TEMPLATE
	
	'__WEBLINK__
	' REQUEST | NOTIFICATION: _MESSAGE_
	'Method on_HANDLER:JSON( message:TMessage )
	'	ImplementationIncomplete( message )
	'	Local id:String = message.getid()
	'	Local params:JSON = message.params
	'	
		' NOTIFICATION: No response necessary
		' REQUEST: Return response
	'	Return Response_OK( id )
	'End Method


End Type