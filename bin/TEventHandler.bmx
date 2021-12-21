'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved
'   OBSERVER (Publish/Subscribe)

Rem     
        Currently defined event types:

        EVENT           DATA    EXTRA
        log             STRING  STRING      ' Request to log a message
        debug           STRING              ' Same as ("log", "DEBG", message)
        error           STRING              ' Same as ("log", "ERRR", message)
        critical        STRING              ' Same as ("log", "CRIT", message)
        receive         STRING              ' Message received from client
        sendmessage     JNODE               ' Message or Response to be sent to client
        pushtask        TMessage            ' New Request to add to the queue
        cancelrequest   JNODE               ' Request cancellation ($/cancelRequest)
        exitnow                             ' ExitProcedure() has been called.

End Rem

Type TEventHandler
	
	' V4.0
	Global handlers:TList = New TList()	
	Field handle:TLink
	
	Method register( event:String = "*" )
		If Not handle ; handle = handlers.addLast( Self )
	End Method 
	
	Method unregister()
		If handle ; handle.remove()
		handle = Null
	End Method

	'V4.0
	Method distribute( message:TMessage )
		Local count:Int = 0
		
		' Create function string; removing unwanted characters
		Local callable:String = "on_"+message.methd
		callable = Replace( callable, "$/", "dollar_" )
		callable = Replace( callable, "/", "_" )
		callable = Replace( callable, "-", "" )
		
		' Check for Message Handler
		
		For Local handler:TEventHandler = EachIn handlers
			
			Local this:TTypeId = TTypeId.ForObject( handler )
			
			' Use reflection to obtain method
			Local call:TMethod = this.FindMethod( callable )
	'DebugStop
			If call 
				logfile.debug( "CALLING: "+callable+"() .. "+message.classname() )
				'Local response:JSON = JSON( call.invoke( Self, [message] ) )
				count :+1
				
				Try
					' Process the message...
					Select message.class
					Case TMessage._REQUEST 
						' REQUESTS must always return a response to the client
						Local response:JSON = JSON( call.invoke( Self, [message] ) )
						If Not response Or response.isInvalid()
							response = Response_Error( ERR_INTERNAL_ERROR, "Handler failed to respond" ) 
						End If
						
						lsp.send( response )
					Case TMessage._RESPONSE 
					
					
'10-12-2021 18:21:44 DEBG MESSAGEQUEUE: Popped Message{/0/RESPONSE}, priority 2
'10-12-2021 18:21:44 WARN ## No registered handler For ''
'10-12-2021 18:21:44 DEBG ## Method on_() is missing
'10-12-2021 18:21:44 DEBG MESSAGEQUEUE: Popped Message{/1/RESPONSE}, priority 2
'10-12-2021 18:21:44 WARN ## No registered handler For ''
'10-12-2021 18:21:44 DEBG ## Method on_() is missing


						' RESPONSE from the client to a request we have sent.
						' First we have To lookup the request
						'Local request:TMessage = lsp.matchResponseToRequest( message.getID() )
						call.invoke( Self, [message] )
					Case TMessage._NOTIFICATION
						' Simple notification from client
						call.invoke( Self, [message] )
					End Select
				Catch Exception:String
					logfile.critical( "TEventHandler.distribute(): "+ exception )
				End Try

			End If
		Next
		'
		' Report unhandled messages
		If count=0
			If message.class = TMessage._REQUEST
				logfile.critical( "## No registered handler for '"+message.methd+"'" ) 
			Else
				logfile.warning( "## No registered handler for '"+message.methd+"'" ) 
			End If
			logfile.debug( "## Method "+callable+"() is missing" )
		End If
	End Method
	
	' DEPRECIATED AFTER HERE...
	
' DEPRECIATED 25/10/21

'	Method Close()
'		unlisten()
'	End Method

'	Method listen()
'		'publish( "log", "DBG", "# TEventHandler Listening" )
'		AddHook( EmitEventHook, EventHandler, Self )
'	End Method
	
'	Method unlisten()
'		'publish( "log", "DBG", "# TEventHandler Stopped" )
'		RemoveHook( EmitEventHook, EventHandler, Self )
'	End Method
	


	'V3.0
'DEPRECIATED 25/10/21
'	Method distribute:TMessage( id:Int, message:TMessage )
'DebugStop
'	
'		' Dont bother sending if the message is invalid
'		If Not message Or Not message.J
'			client.send( Response_Error( ERR_INTERNAL_ERROR, "Null value" ) )
'			Return Null
'		End If
		
'		Try
'			Local this:TTypeId = TTypeId.ForObject(Self)
'			'publish( "log", "DBG", "# "+this.name+".distribute("+message.methd+")" )		
'			'Local running:Int = False
'			
'			'publish( "log", "DBG", "# DISTRIBUTING: "+message.methd+ " ("+id+")")
'			Select id '		Defined in TMEssage
'
'			' INTERNAL IO
'			Case EV_receivedFromClient		;	Return onReceivedFromClient( message )
'			Case EV_sendToClient			;	Return onSendToClient( message )
'
'			' DOLLAR
'			Case EV_CancelRequest			;	Return onCancelRequest( message )
'			Case EV_SetTraceNotification	;	Return onSetTraceNotification( message )	
'
'			' GENERAL MESSAGES
'			Case EV_initialize				;	Return onInitialize( message )
'			Case EV_initialized				;	Return onInitialized( message )
'			Case EV_shutdown				;	Return onShutdown( message )
'			Case EV_exit					;	Return onExit( message )
'
'			' WORKSPACE/
'			Case EV_didChangeWorkspaceFolders	;	Return onDidChangeWorkspaceFolders( message )
'			Case EV_didChangeConfiguration		;	Return onDidChangeConfiguration( message )
'			Case EV_didChangeWatchedFiles		;	Return onDidChangeWatchedFiles( message )
'
'			' TEXTDOCUMENT/
'			Case EV_textDocument_didChange			;	Return onDidChange( message )
'			Case EV_textDocument_didOpen			;	Return onDidOpen( message )
'			Case EV_textDocument_willSave			;	Return onWillSave( message )
'			Case EV_textDocument_willSaveWaitUntil	;	Return onWillSaveWaitUntil( message )
'			Case EV_textDocument_didSave			;	Return onDidSave( message )
'			Case EV_textDocument_didClose			;	Return onDidClose( message )
'
'			' LANGAGE FEATURES
'			Case EV_completionItem_resolve			;	Return onCompletionResolve( message )
'			Case EV_textDocument_definition			;	Return onDefinition( message )
'			Case EV_textDocument_completion			;	Return onCompletion( message )
'			Case EV_textDocument_documentSymbol		;	Return onDocumentSymbol( message )
'			
'			'Case NEXTONE			;	NEXTONE( message )
'			Default
'				'publish( "log", "DBG", "# TEventHandler: Missing '"+message.methd+"'" )	
'				logfile.debug( "# TEventHandler: Missing '"+message.methd+"'" )		
'			End Select
'		Catch Exception:String
'			logfile.info( "## EXCEPTION: TEventHandler.distribute~n"+Exception )
'		End Try
'
'	End Method

	'	V0.3 EVENT HANDLERS
	'	WE MUST RETURN MESSAGE IF WE DO NOT HANDLE IT
	'	RETURN NULL WHEN MESSAGE HANDLED OR ERROR HANDLED
	
	'	DEPRECIATED 25/10/21

	' MESSAGE IO
'	Method on_ReceiveFromClient:JSON( message:TMessage ) ; Return Null ; End Method

'	Method onReceivedFromClient:TMessage( message:TMessage ) ; Return message ; End Method
'	Method onSendToClient:TMessage( message:TMessage ) ; Return message ; End Method	

	' PROTOCOL INDEPENDENT IMPLEMENTATION ( $/ NOTIFCATIONS )
'	Method onCancelRequest:TMessage( message:TMessage ) ; Return message ; End Method
'	Method onSetTraceNotification:TMessage( message:TMessage ) ; Return message ; End Method

	' GENERAL MESSAGES
'	Method onExit:TMessage( message:TMessage ) ; Return message ; End Method
'	Method onInitialize:TMessage( message:TMessage ) ; Return message ; End Method
'	Method onInitialized:TMessage( message:TMessage ) ; Return message ; End Method
'	Method onShutdown:TMessage( message:TMessage ) ; Return message ; End Method
'	'Method onLogTrace:TMessage( message:TMessage ) ; Return message ; End Method
'	'Method setTrace:TMessage( message:TMessage ) ; Return message ; End Method

	' WINDOW
'	'Method onShowMessage:TMessage( message:TMessage ) ; Return message ; End Method
'	'Method onMessageRequest:TMessage( message:TMessage ) ; Return message ; End Method
'	'Method onShowDocument:TMessage( message:TMessage ) ; Return message ; End Method
'	'Method onLogMessage:TMessage( message:TMessage ) ; Return message ; End Method
'	'Method onProcessCreate:TMessage( message:TMessage ) ; Return message ; End Method
'	'Method onProcessCancel:TMessage( message:TMessage ) ; Return message ; End Method
'	
'	' CLIENT
'	'Method onRegisterCapability:TMessage( message:TMessage ) ; Return message ; End Method
'	'Method onUnRegisterCapability:TMessage( message:TMessage ) ; Return message ; End Method
'	
'	' WORKSPACE EVENTS
'	Method onDidChangeWorkspaceFolders:TMessage( message:TMessage ) ; Return message ; End Method
'	Method onDidChangeConfiguration:TMessage( message:TMessage ) ; Return message ; End Method
'	Method onDidChangeWatchedFiles:TMessage( message:TMessage ) ; Return message ; End Method
'
'	' TEXT SYNCHRONISATION
'	Method onDidChange:TMessage( message:TMessage ) ; Return message ; End Method
'	Method onDidOpen:TMessage( message:TMessage ) ; Return message ; End Method
'	Method onWillSave:TMessage( message:TMessage ) ; Return message ; End Method
'	Method onWillSaveWaitUntil:TMessage( message:TMessage ) ; Return message ; End Method
'	Method onDidSave:TMessage( message:TMessage ) ; Return message ; End Method
'	Method onDidClose:TMessage( message:TMessage ) ; Return message ; End Method
'	
'	'LANGUAGE FEATURES
'	Method onDefinition:TMessage( message:TMessage ) ; Return message ; End Method
'	Method onCompletion:TMessage( message:TMessage ) ; Return message ; End Method
'	Method onCompletionResolve:TMessage( message:TMessage ) ; Return message ; End Method
'	Method onDocumentSymbol:TMessage( message:TMessage ) ; Return message ; End Method	
	
	' EVENT HOOK HANDLER
' DEPRECIATED 25/10/21

'	Function EventHandler:Object( id:Int, data:Object, context:Object )
'DebugStop
'		Try
'			' Test for valid event
'			' (Handled events return null, so we can ignore them)
'			Local event:TEvent = TEvent( data )
'			If Not event Return data
'
'			' Test for valid message (and not system event)
'			Local message:TMessage = TMessage( event.source )
'			'Local J:JSON = JSON( event.extra )
'			If Not message Return data
'			'If Not message Or Not J Return data
'	'publish( "log", "DBG", "# Event Handler: "+message.methd )
'	'publish( "log", "DBG", "# ("+event.id+") "+event.tostring() )
'
'			' Distribute event
'			Local obj:TEventHandler = TEventHandler( context )
'			' Distribute message
'			If obj ; Return obj.distribute( event.id, message )
'			' We didn;t process this, so pass to next handler
'			Return data
'		Catch Exception:String
'			logfile.info( "## EXCEPTION: TEventHandler.EventHandler~n"+Exception )
'		End Try
'	End Function
	
End Type

' DEPRECIATED 25/10/2021
'Type TObserver Extends TEventHandler
'    Private
'	' V0.2, changed from abstract to ancestor
'    Method Notify( event:String, data:Object, extra:Object ) ; End Method
'    Public
'    Method Subscribe( event:String )
'        TSignal.Subscribe( event, Self )
'    End Method
'    Method Subscribe( events:String[])
'        For Local event:String = EachIn events
'            TSignal.Subscribe( event, Self )
'        Next
'    End Method
'    Method Unsubscribe( event:String )
'        TSignal.Unsubscribe( event, Self )
'    End Method
'    'Method Publish( event:string, data:object=null )
'    '    TSignal.Publish( event, data )
'    'End Method
'End Type

' DEPRECIATED 25/10/2021
'Type TSignal
'
'    Private

'    Global lock:TMutex = CreateMutex()
'    Global list:TMap = New TMap()'

'    Method New() Abstract   ' Prevent instance creation
    
'    Public

'    Global DisposeEmpties:Int = True    ' Dispose of empty queue's

'    Function Publish:Int( event:String, data:Object=Null, extra:Object=Null )
'        ' Standardise event
'        event = Lower( Trim(event) )
'        ' Get the event queue
'        Local queue:TList = TList( list.ValueForKey( event ) )
'        If Not queue Return False
'        ' Send event
'        For Local observer:TObserver = EachIn queue
'            observer.Notify( event:String, data, extra )
'        Next
'        Return True
'    End Function

'    Function Subscribe( event:String, observer:TObserver )
'        ' Standardise event
'        event = Lower( Trim(event) )
'        ' Get the messeventage queue
'        Local queue:TList = TList( list.ValueForKey( event ) )
'        ' If queue does not exist, create it
'        LockMutex( lock )
'        If Not queue
'            queue = New TList()
'            list.insert( event, queue )
'        End If
'        ' Add observer to event queue
'        queue.addlast( observer )
'        UnlockMutex( lock )
'    End Function

'    Function Unsubscribe( event:String, observer:TObserver )
'        ' Standardise event
'        event = Lower( Trim(event) )
'        ' Get the event queue
'        Local queue:TList = TList( list.ValueForKey( event ) )
'        If Not queue Return
'        ' Remove the observer
'        LockMutex( lock )
'        queue.remove( observer )
 '       ' Remove the queue (You may not always want to do this)
'        If queue.isempty() And disposeEmpties
'            list.remove( event )
'        End If
'        UnlockMutex( lock )
'    End Function

'End Type

' Publish an event
' Depreciated 25/10/21
'Function PublishX:Int( event:String, data:Object=Null, extra:Object=Null )
'    Return TSignal.Publish( event, data, extra )
'End Function
