
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, July 2021, All Right Reserved

Include "TLSP_Stdio.bmx"
Include "TLSP_TCP.bmx"

Type TLanguageServer Extends TEventHandler
    Global instance:TLanguageServer

	Const STATE_UNINITIALISED:Int	= 0
	Const STATE_INITIALISING:Int	= 1
	Const STATE_INITIALISED:Int		= 2
	Const STATE_SHUTDOWN:Int		= 3

    Field exitcode:Int				= 0

	Field state:Int					= STATE_UNINITIALISED
	'Field initialised:Int			= False   	' Set by "initialized" message
    'Field shutdown:Int				= False		' Set by "shutdown" message
	Field trace:String				= "off"		' Set by $/setTrace or OnTraceNotification
	Field sendbuffer:String[]		= []
	
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
	'Field handlers:TMap = New TMap
	
	Method New()
'DebugStop
		' V4 - Register handler
		register()
	End Method
	
    Method run:Int() Abstract
    Method getRequest:String() Abstract     ' Waits for a message from client

    Method Close() ; End Method

	' Send a message to the client 
	Method send( message:JSON )
		Local response:Int = False
		' Check we have a valid JSON object, or replace with error
		If Not message ; message = Response_Error( ERR_INTERNAL_ERROR, "Incomplete Event" ) 
		
		' Extract message
		Local Text:String = message.stringify()
		If Not Text ; Return
		If message.contains("id") ; response = True
		
		logfile.debug( "# METHOD IS '"+ message.find("method").tostring()+"'" )
		If response 
			logfile.debug( "# MESSAGE IS A RESPONSE" )
		Else
			logfile.debug( "# MESSAGE IS A NOTIFICATION" )
		End If

		' Validation
		Local allowed:Int = response | (state=STATE_INITIALISED)	
		logfile.debug( "allowed="+allowed )
		If Not allowed
			Select state
			Case STATE_UNINITIALISED		' Server not connected, nothing to send to!
				logfile.critical( "## SERVER IS UNINITIALISED:~n"+Text )
			Case STATE_INITIALISING
				Select message.find( "method" ).toString()
				Case "initialize", "window/showMessage", "window/logMessage", "telemetry/event", "window/showMessageRequest"
					allowed = True
				End Select
			'Case STATE_INITIALISED
			'	allowed = True
			Case STATE_SHUTDOWN
				logfile.critical( "## SERVER IS SHUTDOWN:~n"+Text )
			End Select
		End If
		logfile.debug( "# ALLOWED TO SEND: "+["FALSE","TRUE"][allowed]+" ("+allowed+")" )
		
		' Send message
		If allowed	' SEND MESSAGE
			client.sendMessage( Text )
		Else		' ADD TO BUFFER
			logfile.debug( "# BUFFERING MESSAGE:~n"+Text )
			sendbuffer :+ [Text]
		End If
		
		' Send buffered messages?
		If state = STATE_INITIALISED And sendbuffer<>[]
			logfile.debug( "# EMPTYING BUFFER" )
			For Local buffered:String = EachIn sendbuffer
				client.sendMessage( buffered )
			Next
			sendbuffer = []			
			logfile.debug( "# BUFFER EMPTY" )
		End If
			
	End Method

	'V0.0
    Function ExitProcedure()
        'Publish( "debug", "Exit Procedure running" )
        'Publish( "exitnow" )
		logfile.info( "Running Exit Procedure" )
        instance.Close()
        'Logfile.Close()
    End Function

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
				logfile.error( content )
				If J.isInvalid()
					errtext = "ERROR("+J.errNum+") "+J.errText+" at {"+J.errLine+","+J.errpos+"}"
				Else
					errtext = "ERROR: Parse returned null"
				End If
                ' Send error message to LSP Client
				'Publish( "debug", errtext )
                'Publish( "send", Response_Error( ERR_PARSE_ERROR, errtext ) )
				logfile.debug( errtext )
				'send( Response_Error( ERR_PARSE_ERROR, errtext ) )
                Continue
            End If
			'Publish( "debug", "Parse successful" )
						
Rem
Message is sent as a receiveFromClient, but it has an ID from the original message
so it becomes a REQEST.
receiveFromClient doesn't return a result and TMessage.send() identifies it as a request and 
returns a failure back to the client which forces the IDE to close the BLS.

I can either modify message in receiveFromClient (and sendto Client) so that it is a notification
Or I can process the message here and send it without using "receiveFromClient" (Much cleaner)

ReceiverThread Gets message from connection (StdIn)
	Parses STRING into JSON and packages it into TMessage 
	:- calls TMessage("receiveFromClient").send()
TMEssage.Send() calls TLSP.distribute()
TEventHandler.Distribute() Extracts Method from Message
	:- Calls TMEssageQueue.on_ReceiveFromClient()
TMEssageQueue.on_ReceiveFromClient() validates method and message
	Repackages into another TMessage and calls Send...
	
End Rem

			' J is my JSON (Freshly arrived from IDE)
			
			' Check for a method
			If Not J.contains("method")
				'client.send( Response_Error( ERR_METHOD_NOT_FOUND, "No method specified" ) )
				logfile.critical( "## No Method specified~n"+J.stringify() )
				Continue
			End If
				
			' Get Method and Ensure it isn't empty
			Local methd:String = J.find("method").toString()
			If methd = "" 
				'client.send( Response_Error( ERR_INVALID_REQUEST, "Method cannot be empty" ) )
				logfile.critical( "## Method cannot be empty~n"+J.stringify() )
				Continue
			End If
				
			' Extract "Params" if they exist (They should)
			'Local params:JSON = J.find( "params" )

			' Create a Message object
			Local message:TMessage = New TMessage( methd, J ) ', params )
			Local id:String = message.getid()
			
            ' Validation
			Select True
			Case lsp.state = lsp.STATE_INITIALISED And methd="initialize"
				logfile.critical( "## Server already initialized~n"+J.stringify() )
				lsp.send( Response_Error( ERR_INVALID_REQUEST, "Server already initialized", id ) )
				Continue
			Case lsp.state <> lsp.STATE_INITIALISED And methd<>"initialize"
				logfile.critical( "## Server is not initialized~n"+J.stringify() )
				lsp.send( Response_Error( ERR_SERVER_NOT_INITIALIZED, "Server is not initialized", id ))
				Continue
            End Select

			logfile.debug( "- ID:      "+id )
			logfile.debug( "- METHOD:  "+methd )
			'Publish( "debug", "- REQUEST:~n"+J.Prettify() )
			'Publish( "debug", "- PARAMS:  "+message.params.stringify() )
			
			' REQUEST or NOTIFICATION
			If message.request
				logfile.debug( "- TYPE:    REQUEST" )
				' This is a request, add to queue
				'logfile.debug( "Pushing request '"+methd+"' to queue")
				message.priority = QUEUE_PRIORITY_REQUEST
				message.post()
				'client.pushTaskQueue( message )		
			Else
				' The message is a notification, send it now.
				logfile.debug( "- TYPE:    NOTIFICATION" )
				'Publish( "debug", "Executing notification "+methd )
				'New TMessage( methd, message.J, params ).emit()
				message.priority = QUEUE_PRIORITY_NOTIFICATION
				message.post()
				'client.pushTaskQueue( message )	
				'message.execute()
			End If

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

	' Report an Implementation Incomplete State
	Method ImplementationIncomplete( message:TMessage )
		logfile.error( "## IMPLEMENTATION INCOMPLETE: '"+message.methd+"'~n"+message.J.Prettify() )
	End Method

	'V0.1
    ' Thread based message sender
    Function SenderThread:Object( data:Object )
        Local lsp:TLanguageServer = TLanguageServer( data )
        Local quit:Int = False          ' Always got to know when to quit!
        
        'DebugLog( "SenderThread()" )
        Repeat
            Try
                'Publish( "debug", "TLSP.SenderThread going to sleep")
                logfile.debug("TLSP.SenderThread going To sleep")
				
                WaitSemaphore( client.sendcounter )
                'Publish( "debug", "TLSP.SenderThread is awake" )
                logfile.debug( "TLSP.SenderThread is awake" )
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
				logfile.critical( Exception )
            End Try
        Until CompareAndSwap( lsp.QuitSender, quit, True )
        'Publish( "debug", "SenderThread - Exit" )
        logfile.debug( "SenderThread - Exit" )
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
	
'	Method sendPreInitialisedError:Object( id:String )
'		client.send( Response_Error:JSON( ERR_SERVER_NOT_INITIALIZED, "Server is not initialised", id ) )
'		Return Null
'	End Method

	'	V4 MESSAGE HANDLERS
	'	REQUESTS MUST RETURN A RESPONSE OR CLIENT IS SENT AN ERROR
		
	' ############################################################
	' ##### GENERAL MESSAGES #####################################

	Method on_Exit:JSON( message:TMessage )						' NOTIFICATION
		logfile.debug( "TLSP.onExit()" )

		' QUIT MAIN LOOP
        AtomicSwap( QuitMain, False )

		' NOTIFICATION: No response necessary
	End Method
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#initialize
	Method on_Initialize:JSON( message:TMessage )				' REQUEST
		'logfile.debug( "MESSAGE:~n"+message.J.prettify() )
		Local id:String = message.getid()
		Local params:JSON = message.params
	
		state = STATE_INITIALISING
				
		'logfile.debug( "onInitialise()~n"+message.J.prettify() )
		'logfile.debug( "ONINITIALISE ID="+id )
		
		' Client must extract capabilities etc.
		client.initialise( params )			' Will extract "capabilities" and "clientInfo"
		
		' Workspace must extract rootURI and anything else of interest
		'workspaces.initialise( params )		' Will extract "rootPath" and "workspaceFolders"
		
		' Standardise the rootUri path
		'	(If multi-workspace is disabled, this will be set, otherwise it will be file:///"
		Local uri:TURI = New TURI( params.find( "rootUri" ).toString() )
		'logfile.debug( "ROOTURI:" + params.find( "rootUri" ).toString() ) 
		'logfile.debug( "ROOTURI:" + uri.toString() ) 
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
		If params.contains( "workspaceFolders" )
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
		End If
		
		' Extract other information that we may need
		' clientProcessID = params.find( "processId" )
		' locale = params.find( "locale" )
		' initializationOptions = params.find( "initializationOptions" )
		' trace = params.find( "trace" )
		
		Local value:String = params.find( "trace" ).toString()
		If value = "off" Or value="messages" Or value="verbose"
			trace = value
		End If
		logfile.info( "# TraceValue is '"+trace+"'" )
		
		' Respond to the client
		Local serverCapabilities:JSON = New JSON()
		serverCapabilities.set( "textDocumentSync", TextDocumentSyncKind.INCREMENTAL.ordinal() )
		'serverCapabilities.set( "completionProvider|resolveProvider", "true" )
		'serverCapabilities.set( "completionProvider|workDoneProgress", "true" )
		'serverCapabilities.set( "definitionProvider", "true" )
		'serverCapabilities.set( "hoverProvider", "true" )
		'serverCapabilities.set( "hoverProvider|workDoneProgress", "true" )
		'serverCapabilities.set( "signatureHelpProvider", [] )
		'serverCapabilities.set( "signatureHelpProvider|workDoneProgress", "true" )
		'serverCapabilities.set( "declarationProvider", [] )
		'serverCapabilities.set( "definitionProvider", [] )
		'serverCapabilities.set( "typeDefinitionProvider", [] )
		'serverCapabilities.set( "implementationProvider", [] )
		'serverCapabilities.set( "referencesProvider", [] )
		'serverCapabilities.set( "referencesProvider|workDoneProgress", "true" )
		'serverCapabilities.set( "documentHighlightProvider", [] )
		serverCapabilities.set( "documentSymbolProvider", True )
		serverCapabilities.set( "documentSymbolProvider|workDoneProgress", "true" )
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
		'serverCapabilities.set( "workspaceSymbolProvider", [] )
		'serverCapabilities.set( "workspaceSymbolProvider|workDoneProgress", "true" )
		If client.has( "workspace|workspaceFolders" ) 
			logfile.debug( "# Client HAS workspace|workspaceFolders" )
			serverCapabilities.set( "workspace|workspaceFolders|supported", "true" )
			' send plural and non-plural due to a typo in the LSP 3.16 documentation that doesn't explain
			' which one is correct!
			serverCapabilities.set( "workspace|workspaceFolders|changeNotifications", "true" )
			serverCapabilities.set( "workspace|workspaceFolders|changeNotification", "true" )
		End If
		serverCapabilities.set( "workspace|configuration", "file" )
		'serverCapabilities.set( "workspace|fileOperations|didCreate|filters|scheme", "file" )
		'serverCapabilities.set( "workspace|fileOperations|willCreate|filters|scheme", "file" )
		'serverCapabilities.set( "workspace|fileOperations|didRename|filters|scheme", "file" )
		'serverCapabilities.set( "workspace|fileOperations|willRename|filters|scheme", "file" )
		'serverCapabilities.set( "workspace|fileOperations|didDelete|filters|scheme", "file" )
		'serverCapabilities.set( "workspace|fileOperations|willDelete|filters|scheme", "file" )
		'serverCapabilities.set( "experimental", [] )
		
		Local InitializeResult:JSON = Response_OK( id )

        'InitializeResult.set( "result|capabilities", lsp.capabilities )
        InitializeResult.set( "result|capabilities", serverCapabilities )
        InitializeResult.set( "result|serverinfo", [["name","~q"+AppTitle+"~q"],["version","~q"+version+"."+build+"~q"]] )

		'Publish( "log", "DEBG", "CAPABLITIES: "+serverCapabilities.Prettify() )

		' Enable all other message processing
		' initialised = True 
		state = STATE_INITIALISED
		
		' REQUEST: Return response
		Return InitializeResult
	End Method
	
	Method on_Initialized:JSON( message:TMessage )		' NOTIFICATION
		'publish( "log", "DBG", "EVENT onInitialized()" )
		logfile.debug( "TLSP.on_Initialized()" )
		
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
	logfile.debug( "## CLIENT SUPPORTS: window|workDoneProgress" )
	
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
	logfile.debug( "## CLIENT DOES NOT SUPPORT: window|workDoneProgress" )
End If
EndRem

		'logfile.trace( "THIS IS A TEST 'LOGTRACE' MESSAGE", "WITH VERBOSE STUFF IN HERE, SORRY ABOUT ALL THE WAFFLE" )
		
		'	MODULE COMPATABILITY

		If Not JSON.VersionCheck( JSON_MINIMUM_VERSION, JSON_MINIMUM_BUILD )
			Local error:String = "JSON Version "+JSON.Version()+" is not compatible."
			logfile.critical( "## "+error )
			client.logMessage( error, EMessageType.Error.Ordinal() )
		'	Print( error )
		End If
		
		' NOTIFICATION: No response necessary
	End Method 

	Method on_Shutdown:JSON( message:TMessage )			' REQUEST
		logfile.debug( "TLSP.onShutdown()" )
		state = STATE_SHUTDOWN
		' SEND RESPONSE
		Return Response_OK( message.getid() )
	End Method

	' ############################################################
	' #####TRACE NOTIFICATIONS ###################################

	' 3.16 documentation says $/setTrace, but VSCODE sends $/setTraceNotification
	Method on_dollar_setTrace:JSON( message:TMessage )					' NOTIFICATION
		logfile.debug( "TLSP.on_dollar_setTrace()~n"+message.J.prettify() )
		Local value:String = message.params.find( "value" ).toString()
		If value = "off" Or value="messages" Or value="verbose"
			trace = value
			logfile.info( "## TraceValue is '"+trace+"'" )
		End If
		' NOTIFICATION: No response necessary
	End Method
	
	' 3.16 documentation says $/setTrace, but VSCODE sends $/setTraceNotification
	' Library version in BlitzMax Extension updated by Hezkore 12/11/21 fixed this issue
	' Trace notifications
'	Method on_dollar_setTraceNotification:JSON( message:TMessage )			' NOTIFICATION
'		logfile.debug( "TLSP.on_dollar_setTraceNotification()~n"+message.J.prettify() )
'		Local value:String = message.params.find( "value" ).toString()
'		If value = "off" Or value="message" Or value="verbose"
'			trace = value
'			logfile.info( "? TraceValue is now: '"+trace+"'" )
'		End If
'		' NOTIFICATION: No response necessary
'	End Method
	
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
logfile.debug( add.getClassName()+":"+add.stringify() )
		Local sub:JSON = params.find( "event|removed" )
logfile.debug( sub.getClassName()+":"+sub.stringify() )
		
		Local added:JSON[] = params.find( "event|added" ).toArray()
		Local removed:JSON[] = params.find( "event|removed" ).toArray()

logfile.debug( "ADDED: "+added.length )
If added.length>0 ; logfile.debug( added[0].stringify() )
logfile.debug( "REMOVED: "+removed.length )
If removed.length>0 ; logfile.debug( removed[0].stringify() )


		' Add new Workspaces
		For Local item:JSON = EachIn added
			Local name:String = item.find( "name" ).toString()
			Local uri:TURI = New TURI( item.find( "uri" ).toString() )
			logfile.debug( "Adding "+name+" - "+ uri.tostring() )
			logfile.debug( item.stringify() )
			If uri ; Workspaces.add( uri, New TWorkspace( name, uri ) )
		Next

		' Remove Workspaces (and files within them)
		For Local item:JSON = EachIn removed
			Local name:String = item.find( "name" ).toString()
			Local uri:TURI = New TURI( item.find( "uri" ).toString() )
			logfile.debug( "Removing "+name+" - "+ uri.tostring() )
			logfile.debug( item.stringify() )

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

'logfile.debug( ">> REVIEWING WORKSPACES" )

		' Check if any documents in the root workspace should be moved
		'For Local document:TTextDocument = EachIn rootworkspace.all()
		'	Local workspace:TWorkspace = Workspaces.get( document.uri )
		'	If Not workspace ; Continue
		'	' Candidate found, so move it...
		'	workspace.document_add( document.uri, document )
		'	rootworkspace.document_remove( document.uri )
		'Next

'logfile.debug( "WORKSPACES:~n"+workspaces.reveal() )

	End Method

	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#workspace_symbol
	' REQUEST: workspace/symbol
	Method on_workspace_symbol:JSON( message:TMessage )		
		ImplementationIncomplete( message )
		
		' NOTE: Request may include a params/query, but I don;t know what format this will be.
		' Look for params/workdone flag to create a Progress Bar
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
'	Method onWorkspaceConfiguraion:TMessage( message:TMessage )			' REQUEST
'		ImplementationIncomplete( message )
'		Local id:String = message.getid()
'		lsp.send( Response_OK( id ) )
'	End Method

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
		
		logfile.debug( "DOCUMENT: "+uri.tostring() )

		Local workspace:TWorkspace = Workspaces.get( uri )
If Not workspace logfile.debug( "WORKSPACE IS NULL" )
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
		Local uniquetask:TTestTask = New TTestTask()
		client.pushTaskQueue( uniquetask, "UNIQUETASK" )

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
		logfile.debug( "WORKSPACES:~n"+workspaces.reveal() )
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
'	Method onHover:TMessage( message:TMessage )							' REQUEST
'		ImplementationIncomplete( message )
'		Local id:String = message.getid()
'		logfile.debug( "TLSP.onHover()" )
'		If Not message Or Not message.J
'			lsp.send( Response_Error( ERR_INTERNAL_ERROR, "Null value" ) )
'			Return Null
'		End If
'		logfile.info( "~n"+message.j.Prettify() )
'		' We have NOT dealt with it, so return message
'		lsp.send( Response_OK( id ) )
'	End Method
	
	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_definition
	' REQUEST: textDocument/definition
'	Method onDefinition:JSON( message:TMessage )	; Return bls_textDocument_definition( message )	;	End Method

	' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_documentSymbol
	' REQUEST: textDocument/documentSymbol
	Method on_textDocument_documentSymbol:JSON( message:TMessage )
		logfile.debug( "MESSAGE:~n"+message.J.prettify() )
		Return bls_textDocument_documentSymbol( message )
	End Method

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