'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved
'   MESSAGE QUEUE

Type TMessageQueue Extends TObserver
    Global requestThread:TThread
    Global sendqueue:TQueue<String>         ' Messages waiting to deliver to Language Client
    Global taskqueue:TIntMap                ' Tasks Waiting or Running
    ' Locks
    Field sendMutex:TMutex = CreateMutex()
    Field taskMutex:TMutex = CreateMutex()
    ' Semaphores
    Field sendCounter:TSemaphore = CreateSemaphore( 0 )
    'Field taskCounter:TSemaphore = CreateSemaphore( 0 )

    Method New()
        sendQueue = New TQueue<String>()
        taskQueue = New TIntMap()
'DebugStop
        ' Subscribe to messages
        Subscribe( ["pushtask","sendmessage","exitnow","cancelrequest"] )
    End Method

    ' Get next waiting message in the queue
    Method getNextTask:TMessage()
        If taskqueue.isEmpty() Return Null
        Publish( "getNextTask()" )
        LockMutex( TaskMutex )
        For Local task:TMessage = EachIn taskqueue.values()
            ' Debugging
            Local state:String =  ["waiting","running","complete"][task.state]
            If task.cancelled state :+ ",cancelled"
            Publish( "debug", "Task "+task.id+" ["+state+"]")
            '
            If task.cancelled Or task.state=STATE_COMPLETE
                Publish( "Closing Task "+task.id)
                taskqueue.remove( task.id )
            ElseIf task.state = STATE_WAITING
                'Publish( "Task "+task.id+" waiting")
                task.state = STATE_RUNNING
                UnlockMutex( TaskMutex )
                Return task
            'else
            '    Publish( "Task "+task.id+" running")
            End If
        Next
        UnlockMutex( TaskMutex )
        Return Null
    End Method

    ' Remove a message from the queue 
    Method removeTask( task:TMessage )
        LockMutex( TaskMutex )
        taskqueue.remove( task.id )
        UnlockMutex( TaskMutex )
    End Method
    
    ' Retrieve a message from send queue
    Method popSendQueue:String()
        LockMutex( sendMutex )
        Local result:String = String( sendqueue.dequeue() )
        UnlockMutex( sendMutex )
        Return result
    End Method

    ' Observations
    Method Notify( event:String, data:Object, extra:Object )
        Select event
        Case "cancelrequest"   '$/cancelRequest
            ' A request has been cancelled
            Local node:JSON = JSON( data )
            If Not node Return
            Local id:Int = node.toInt()
            LockMutex( taskmutex )
            For Local task:TMessage = EachIn taskqueue
                If task.id = id 
                    task.cancelled = True
                    Exit
                End If
            Next
            UnlockMutex( taskMutex )
        Case "exitnow"      ' System exit requested
            ' Force waiting threads to exit
            PostSemaphore( sendCounter )
            'PostSemaphore( taskCounter )
        Case "sendmessage"         ' Send a message to the language client
            pushSendQueue( String(data) )
        Case "pushtask"             ' Add a task to the task queue
            Publish( "debug", "Pushtask received")
            Local task:TMessage = TMessage(data)
            If task pushTaskQueue( task )
            Publish( "debug", "Pushtask done" )
        Default
            Publish( "error", "TMessageQueue: event '"+event+"' ignored" )
        End Select
    End Method

    Private

    ' Add a new message to the queue
    Method pushTaskQueue( task:TMessage )
        'Publish( "debug", "PushTaskQueue()" )
        If Not task Return
        'Publish( "debug", "- task is not null" )
        LockMutex( TaskMutex )
        'Publish( "debug", "- task mutex locked" )
        taskqueue.insert( task.id, task )
        'Publish( "debug", "- task inserted" )
        'PostSemaphore( taskCounter )
        'Publish( "debug", "- task Semaphore Incremented" )
        UnlockMutex( TaskMutex )
        'Publish( "debug", "- task mutex unlocked" )
    End Method
    
    ' Add a message to send queue
    Method pushSendQueue( message:String )
        message = Trim( message )
        If message="" Return
        LockMutex( sendMutex )
        sendqueue.enqueue( message )
        PostSemaphore( sendCounter )    ' Increase message counter semaphore
        UnlockMutex( sendMutex )
    End Method

End Type