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

Type TObserver
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
