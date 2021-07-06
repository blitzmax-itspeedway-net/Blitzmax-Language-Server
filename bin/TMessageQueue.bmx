'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved
'   MESSAGE QUEUE

Type TMessageQueue extends TObserver
    global requestThread:TThread
    global sendqueue:TQueue<String>         ' Messages waiting to deliver to Language Client
    global taskqueue:TIntMap                ' Tasks Waiting or Running
    ' Locks
    Field sendMutex:TMutex = CreateMutex()
    Field taskMutex:TMutex = CreateMutex()
    ' Semaphores
    Field sendCounter:TSemaphore = CreateSemaphore( 0 )
    Field taskCounter:TSemaphore = CreateSemaphore( 0 )

    Method new()
        sendQueue = new TQueue<String>()
        taskQueue = new TIntMap()
        ' Subscribe to messages
        Subscribe( ["pushtask","sendmessage","exitnow","cancelrequest"] )
    End Method

    ' Get next waiting message in the queue
    Method getNextTask:TMessage()
        if taskqueue.isEmpty() return null
        Publish( "getNextTask()" )
        LockMutex( TaskMutex )
        for local task:TMessage = eachin taskqueue.values()
            ' Debugging
            local state:string =  ["waiting","running","complete"][task.state]
            if task.cancelled state :+ ",cancelled"
            Publish( "Task "+task.id+" ["+state+"]")
            '
            if task.cancelled or task.state=STATE_COMPLETE
                Publish( "Closing Task "+task.id)
                taskqueue.remove( task.id)
            elseif task.state = STATE_WAITING
                'Publish( "Task "+task.id+" waiting")
                task.state = STATE_RUNNING
                UnlockMutex( TaskMutex )
                return task
            'else
            '    Publish( "Task "+task.id+" running")
            end if
        next
        UnlockMutex( TaskMutex )
        return null
    end Method

    ' Remove a message from the queue 
    Method removeTask( task:TMessage )
        LockMutex( TaskMutex )
        taskqueue.remove( task.id )
        UnlockMutex( TaskMutex )
    end Method
    
    ' Retrieve a message from send queue
    Method popSendQueue:string()
        LockMutex( sendMutex )
        local result:String = String( sendqueue.dequeue() )
        UnlockMutex( sendMutex )
        return result
    End Method

    ' Observations
    Method Notify( event:string, data:object, extra:object )
        select event
        case "cancelrequest"   '$/cancelRequest
            ' A request has been cancelled
            local node:JNode = JNode( data )
            if not node return
            local id:int = node.toInt()
            LockMutex( taskmutex )
            for local task:TMessage = eachin taskqueue
                if task.id = id 
                    task.cancelled = True
                    Exit
                end if
            next
            UnlockMutex( taskMutex )
        case "exitnow"      ' System exit requested
            ' Force waiting threads to exit
            PostSemaphore( sendCounter )
            PostSemaphore( taskCounter )
        case "sendmessage"         ' Send a message to the language client
            pushSendQueue( string(data) )
        case "pushtask"             ' Add a task to the task queue
            Publish( "debug", "Pushtask received")
            local task:TMessage = TMessage(data)
            if task pushTaskQueue( task )
            Publish( "debug", "Pushtask done" )
        default
            Publish( "error", "TMessageQueue: event '"+event+"' ignored" )
        end select
    End Method

    private

    ' Add a new message to the queue
    Method pushTaskQueue( task:TMessage )
        Publish( "debug", "PushTaskQueue()" )
        if not task return
        Publish( "debug", "- task is not null" )
        LockMutex( TaskMutex )
        Publish( "debug", "- task mutex locked" )
        taskqueue.insert( task.id, task )
        Publish( "debug", "- task inserted" )
        PostSemaphore( taskCounter )
        Publish( "debug", "- task Semaphore Incremented" )
        UnlockMutex( TaskMutex )
        Publish( "debug", "- task mutex unlocked" )
    end Method
    
    ' Add a message to send queue
    Method pushSendQueue( message:string )
        message = trim( message )
        if message="" return
        LockMutex( sendMutex )
        sendqueue.enqueue( message )
        PostSemaphore( sendCounter )
        UnlockMutex( sendMutex )
    End Method

End Type