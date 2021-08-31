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

END REM

' EVENT TYPES
Global EV_receivedFromClient:Int = AllocUserEventId( "ReceivedFromClient" )
Global EV_sendToClient:Int = AllocUserEventId( "SendToClient" )

Global EV_initialize:Int = AllocUserEventId( "initialize" )
Global EV_initialized:Int = AllocUserEventId( "initialized" )
Global EV_shutdown:Int = AllocUserEventId( "shutdown" )
Global EV_exit:Int = AllocUserEventId( "exit" )

Global EV_CancelRequest:Int = AllocUserEventId( "$/cancelRequest" )

Global EV_DidChangeContent:Int = AllocUserEventId( "onDidChangeContent" )
Global EV_DidOpen:Int = AllocUserEventId( "onDidOpen" )
Global EV_WillSave:Int = AllocUserEventId( "onWillSave" )
Global EV_WillSaveWaitUntil:Int = AllocUserEventId( "onWillSaveWaitUntil" )
Global EV_DidSave:Int = AllocUserEventId( "onDidSave" )
Global EV_DidClose:Int = AllocUserEventId( "onDidClose" )
'Global NEXTONE:Int = AllocUserEventId( "NEXTONE" )

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
	
	Method distribute:Int( id:Int, message:TMessage )
'DebugStop
		Local this:TTypeId = TTypeId.ForObject(Self)
		'publish( "log", "DBG", "# "+this.name+".distribute("+message.methd+")" )		
		'Local running:Int = False
		
		'publish( "log", "DBG", "# DISTRIBUTING: "+message.methd+ " ("+id+")")
		Select id
		Case EV_receivedFromClient	;	Return onReceivedFromClient( message )
		Case EV_sendToClient		;	Return onSendToClient( message )

		Case EV_CancelRequest		;	Return OnCancelRequest( message )

		Case EV_initialize			;	Return onInitialize( message )
		Case EV_initialized			;	Return onInitialized( message )
		Case EV_shutdown			;	Return onShutdown( message )
		Case EV_exit				;	Return onExit( message )
		
		Case EV_DidChangeContent	;	Return onDidChangeContent( message )
		Case EV_DidOpen				;	Return onDidOpen( message )
		Case EV_WillSave			;	Return onWillSave( message )
		Case EV_WillSaveWaitUntil	;	Return onWillSaveWaitUntil( message )
		Case EV_DidSave				;	Return onDidSave( message )
		Case EV_DidClose			;	Return onDidClose( message )
		'Case NEXTONE			;	NEXTONE( message )
		Default
			publish( "log", "DBG", "# TEventHandler: Missing '"+message.methd+"'" )			
		End Select
		
	End Method

	' EVENT HANDLERS
	Method onReceivedFromClient:Int( message:TMessage ) ; End Method
	Method onSendToClient:Int( message:TMessage ) ; End Method	
	
	Method onExit:Int( message:TMessage ) ; End Method
	Method onInitialize:Int( message:TMessage ) ; End Method
	Method onInitialized:Int( message:TMessage ) ; End Method
	Method onShutdown:Int( message:TMessage ) ; End Method

	Method onCancelRequest:Int( message:TMessage ) ; End Method
	
	Method onDidChangeContent:Int( message:TMessage ) ; End Method
	Method onDidOpen:Int( message:TMessage ) ; End Method
	Method onWillSave:Int( message:TMessage ) ; End Method
	Method onWillSaveWaitUntil:Int( message:TMessage ) ; End Method
	Method onDidSave:Int( message:TMessage ) ; End Method
	Method onDidClose:Int( message:TMessage ) ; End Method

	Function EventHandler:Object( id:Int, data:Object, context:Object )
'DebugStop
		' Test for valid event
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
		If obj 
			' Distribute message and return null if processed
			If obj.distribute( event.id, message ) ; Return Null
		EndIf
		' We didn;t process this, so pass to next handler
		Return data
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
