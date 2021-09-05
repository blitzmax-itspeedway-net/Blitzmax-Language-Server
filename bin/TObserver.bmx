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
	
	Method Close()
		unlisten()
	End Method

	Method listen()
		'publish( "log", "DBG", "# TEventHandler Listening" )
		AddHook( EmitEventHook, EventHandler, Self )
	End Method
	
	Method unlisten()
		'publish( "log", "DBG", "# TEventHandler Stopped" )
		RemoveHook( EmitEventHook, EventHandler, Self )
	End Method
		
	Method distribute:TMessage( id:Int, message:TMessage )
'DebugStop
		Try
			Local this:TTypeId = TTypeId.ForObject(Self)
			'publish( "log", "DBG", "# "+this.name+".distribute("+message.methd+")" )		
			'Local running:Int = False
			
			'publish( "log", "DBG", "# DISTRIBUTING: "+message.methd+ " ("+id+")")
			Select id

			Case EV_receivedFromClient		;	Return onReceivedFromClient( message )
			Case EV_sendToClient			;	Return onSendToClient( message )

			Case EV_initialize				;	Return onInitialize( message )
			Case EV_initialized				;	Return onInitialized( message )
			Case EV_shutdown				;	Return onShutdown( message )
			Case EV_exit					;	Return onExit( message )

			Case EV_DidChangeConfiguration	;	Return onDidChangeConfiguration( message )

			' COMPLETIONITEM/
			Case EV_completionItem_resolve			;	Return onCompletionResolve( message )

			' TEXTDOCUMENT/
			Case EV_textDocument_didChange			;	Return onDidChange( message )
			Case EV_textDocument_didOpen			;	Return onDidOpen( message )
			Case EV_textDocument_willSave			;	Return onWillSave( message )
			Case EV_textDocument_willSaveWaitUntil	;	Return onWillSaveWaitUntil( message )
			Case EV_textDocument_didSave			;	Return onDidSave( message )
			Case EV_textDocument_didClose			;	Return onDidClose( message )
			Case EV_textDocument_definition			;	Return onDefinition( message )
			Case EV_textDocument_completion			;	Return onCompletion( message )
			
			' DOLLAR/
			Case EV_CancelRequest			;	Return onCancelRequest( message )
			Case EV_SetTraceNotification	;	Return onSetTraceNotification( message )	

			'Case NEXTONE			;	NEXTONE( message )
			Default
				publish( "log", "DBG", "# TEventHandler: Missing '"+message.methd+"'" )			
			End Select
		Catch Exception:String
			logfile.info( "## EXCEPTION: TEventHandler.distribute~n"+Exception )
		End Try

	End Method

	'	V0.3 EVENT HANDLERS
	'	WE MUST RETURN MESSAGE IF WE DO NOT HANDLE IT
	'	RETURN NULL WHEN MESSAGE HANDLED OR ERROR HANDLED

	Method onReceivedFromClient:TMessage( message:TMessage ) ; Return message ; End Method
	Method onSendToClient:TMessage( message:TMessage ) ; Return message ; End Method	
	
	Method onExit:TMessage( message:TMessage ) ; Return message ; End Method
	Method onInitialize:TMessage( message:TMessage ) ; Return message ; End Method
	Method onInitialized:TMessage( message:TMessage ) ; Return message ; End Method
	Method onShutdown:TMessage( message:TMessage ) ; Return message ; End Method

	Method onDidChangeConfiguration:TMessage( message:TMessage ) ; Return message ; End Method
	
	Method onDidChange:TMessage( message:TMessage ) ; Return message ; End Method
	Method onDidOpen:TMessage( message:TMessage ) ; Return message ; End Method
	Method onWillSave:TMessage( message:TMessage ) ; Return message ; End Method
	Method onWillSaveWaitUntil:TMessage( message:TMessage ) ; Return message ; End Method
	Method onDidSave:TMessage( message:TMessage ) ; Return message ; End Method
	Method onDidClose:TMessage( message:TMessage ) ; Return message ; End Method
	Method onDefinition:TMessage( message:TMessage ) ; Return message ; End Method
	Method onCompletion:TMessage( message:TMessage ) ; Return message ; End Method
	Method onCompletionResolve:TMessage( message:TMessage ) ; Return message ; End Method
			
	Method onCancelRequest:TMessage( message:TMessage ) ; Return message ; End Method
	Method onSetTraceNotification:TMessage( message:TMessage ) ; Return message ; End Method
	
	Function EventHandler:Object( id:Int, data:Object, context:Object )
'DebugStop
		Try
			' Test for valid event
			' (Handled events return null, so we can ignore them)
			Local event:TEvent = TEvent( data )
			If Not event Return data

			' Test for valid message (and not system event)
			Local message:TMessage = TMessage( event.source )
			'Local J:JSON = JSON( event.extra )
			If Not message Return data
			'If Not message Or Not J Return data
	'publish( "log", "DBG", "# Event Handler: "+message.methd )
	'publish( "log", "DBG", "# ("+event.id+") "+event.tostring() )

			' Distribute event
			Local obj:TEventHandler = TEventHandler( context )
			' Distribute message
			If obj ; Return obj.distribute( event.id, message )
			' We didn;t process this, so pass to next handler
			Return data
		Catch Exception:String
			logfile.info( "## EXCEPTION: TEventHandler.EventHandler~n"+Exception )
		End Try
	End Function

End Type

Type TObserver Extends TEventHandler
    Private
	' V0.2, changed from abstract to ancestor
    Method Notify( event:String, data:Object, extra:Object ) ; End Method
    Public
    Method Subscribe( event:String )
        TSignal.Subscribe( event, Self )
    End Method
    Method Subscribe( events:String[])
        For Local event:String = EachIn events
            TSignal.Subscribe( event, Self )
        Next
    End Method
    Method Unsubscribe( event:String )
        TSignal.Unsubscribe( event, Self )
    End Method
    'Method Publish( event:string, data:object=null )
    '    TSignal.Publish( event, data )
    'End Method
End Type

Type TSignal

    Private

    Global lock:TMutex = CreateMutex()
    Global list:TMap = New TMap()

    Method New() Abstract   ' Prevent instance creation
    
    Public

    Global DisposeEmpties:Int = True    ' Dispose of empty queue's

    Function Publish:Int( event:String, data:Object=Null, extra:Object=Null )
        ' Standardise event
        event = Lower( Trim(event) )
        ' Get the event queue
        Local queue:TList = TList( list.ValueForKey( event ) )
        If Not queue Return False
        ' Send event
        For Local observer:TObserver = EachIn queue
            observer.Notify( event:String, data, extra )
        Next
        Return True
    End Function

    Function Subscribe( event:String, observer:TObserver )
        ' Standardise event
        event = Lower( Trim(event) )
        ' Get the messeventage queue
        Local queue:TList = TList( list.ValueForKey( event ) )
        ' If queue does not exist, create it
        LockMutex( lock )
        If Not queue
            queue = New TList()
            list.insert( event, queue )
        End If
        ' Add observer to event queue
        queue.addlast( observer )
        UnlockMutex( lock )
    End Function

    Function Unsubscribe( event:String, observer:TObserver )
        ' Standardise event
        event = Lower( Trim(event) )
        ' Get the event queue
        Local queue:TList = TList( list.ValueForKey( event ) )
        If Not queue Return
        ' Remove the observer
        LockMutex( lock )
        queue.remove( observer )
        ' Remove the queue (You may not always want to do this)
        If queue.isempty() And disposeEmpties
            list.remove( event )
        End If
        UnlockMutex( lock )
    End Function

End Type

' Publish an event
Function Publish:Int( event:String, data:Object=Null, extra:Object=Null )
    Return TSignal.Publish( event, data, extra )
End Function
