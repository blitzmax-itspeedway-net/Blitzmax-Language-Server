'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved
'   OBSERVER (Publish/Subscribe)

REM     
        Currently defined event types:

        EVENT           DATA    EXTRA
        log             STRING  STRING      ' Request to log a message
        debug           STRING              ' Same as ("log", "DEBG", message)
        error           STRING              ' Same as ("log", "ERRR", message)
        receive         STRING              ' Message received from client
        sendmessage     JNODE               ' Message or Response to be sent to client
        pushtask        TMessage            ' New Request to add to the queue
        cancelrequest   JNODE               ' Request cancellation ($/cancelRequest)
        exitnow                             ' ExitProcedure() has been called.

END REM

Type TObserver
    private
    Method Notify( event:string, data:object, extra:object ) abstract
    public
    Method Subscribe( event:string )
        TSignal.Subscribe( event, self )
    End Method
    Method Subscribe( events:string[])
        for local event:string = eachin events
            TSignal.Subscribe( event, self )
        Next
    End Method
    Method Unsubscribe( event:string )
        TSignal.Unsubscribe( event, self )
    End Method
    'Method Publish( event:string, data:object=null )
    '    TSignal.Publish( event, data )
    'End Method
End Type

Type TSignal

    Private

    Global lock:TMutex = CreateMutex()
    Global list:TMap = New TMap()

    Method New() abstract   ' Prevent instance creation
    
    Public

    global DisposeEmpties:int = True    ' Dispose of empty queue's

    Function Publish:int( event:string, data:object=null, extra:object=null )
        ' Standardise event
        event = lower( trim(event) )
        ' Get the event queue
        local queue:TList = Tlist( list.ValueForKey( event ) )
        If not queue return False
        ' Send event
        for local observer:TObserver = eachin queue
            observer.Notify( event:string, data, extra )
        next
        Return True
    End Function

    Function Subscribe( event:string, observer:TObserver )
        ' Standardise event
        event = lower( trim(event) )
        ' Get the messeventage queue
        local queue:TList = Tlist( list.ValueForKey( event ) )
        ' If queue does not exist, create it
        LockMutex( lock )
        If not queue
            queue = new TList()
            list.insert( event, queue )
        End If
        ' Add observer to event queue
        queue.addlast( observer )
        UnLockMutex( lock )
    End Function

    Function Unsubscribe( event:string, observer:TObserver )
        ' Standardise event
        event = lower( trim(event) )
        ' Get the event queue
        local queue:TList = Tlist( list.ValueForKey( event ) )
        If not queue return
        ' Remove the observer
        LockMutex( lock )
        queue.remove( observer )
        ' Remove the queue (You may not always want to do this)
        if queue.isempty() and disposeEmpties
            list.remove( event )
        end if
        UnLockMutex( lock )
    End Function

End Type

' Publish an event
Function Publish:int( event:string, data:object=null, extra:object=null )
    ' Are we publishing an informational log event?
    if not data and not extra
        Return TSignal.Publish( "log", "INFO", event )
    else
        Return TSignal.Publish( event, data, extra )
    end if
End Function
