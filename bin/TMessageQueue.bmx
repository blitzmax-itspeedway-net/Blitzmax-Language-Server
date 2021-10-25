
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved
'   MESSAGE QUEUE

Rem Event Lifecycle Explained

	JSON Message arrives from client
	LSP Receiver Thread packages this up into an event
		Event ID:	EV_messageReceived event
		Extra:		Original JSON message
	Message queue receives this event
		Validates JSON.Method
		If Extra (JSON) contains an ID
			Adds message to the message queue
		If Extra (JSON) does not contain an ID
			(It is a notification)
			Emits an event
				Event ID:	Matches the Method in the request
				Extra:		Original JSON message
	Messagequeue processes queue
		Next message is emitted as an event
			Event ID:	Matches the Method in the request
			Extra:		Original JSON message
	Message queue processes CANCEL EVENTS
		Loops through message queue and flags message as cancelled.

End Rem

Type TMessageQueue Extends TEventHandler
    Global requestThread:TThread
    Global sendqueue:TQueue<String>         ' Messages waiting to deliver to Language Client
    Global taskqueue:TList				    ' Tasks Waiting or Running
    'Global taskqueue:TIntMap                ' Tasks Waiting or Running
    ' Locks
    Field sendMutex:TMutex = CreateMutex()
    Field taskMutex:TMutex = CreateMutex()
    ' Semaphores
    Field sendCounter:TSemaphore = CreateSemaphore( 0 )
    'Field taskCounter:TSemaphore = CreateSemaphore( 0 )

    Method New()
        sendQueue = New TQueue<String>()
        'taskQueue = New TIntMap()
        taskQueue = New TList()
'DebugStop

		' V0.3, Start Event Listener
		'listen()
		
		' V4 - Register handler
		register()
		
        ' Subscribe to messages
        'Subscribe( ["pushtask","sendmessage","exitnow","cancelrequest"] )
    End Method

	Method Close()
		'unlisten()
		PostSemaphore( sendCounter )
	End Method

Rem
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
            If task.cancelled 
				'JSON RPC REQUIRES THAT EVERY REQUEST SENDS BACK A RESPONSE
				client.send( Response_OK( task.id ) )
                taskqueue.remove( task.id )
			ElseIf task.state=STATE_COMPLETE
                Publish( "Closing Task "+task.id)
                taskqueue.remove( task.id )
            ElseIf task.state = STATE_WAITING
                'Publish( "Task "+task.id+" waiting")
                task.state = STATE_RUNNING
                UnlockMutex( TaskMutex )
                Return task
            Else
                Publish( "$$ Task "+task.id+" running")
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
End Rem

    ' Retrieve a message from send queue
    Method popSendQueue:String()
        LockMutex( sendMutex )
        Local result:String = String( sendqueue.dequeue() )
        UnlockMutex( sendMutex )
        Return result
    End Method
    
    ' Retrieve a message from task queue
    Method popTaskQueue:TMessage()
        LockMutex( TaskMutex )
        Local result:TMessage = TMessage( taskqueue.removefirst() )
        UnlockMutex( TaskMutex )
        Return result
    End Method

    ' Observations
' DEPRECIATED 25/10/21

'    Method Notify( event:String, data:Object, extra:Object )
'        Select event
'        Rem 31/8/21, Moved to V0.3 event handler
'		Case "cancelrequest"   '$/cancelRequest
'            ' A request has been cancelled
'            Local node:JSON = JSON( data )
'            If Not node Return
'            Local id:Int = node.toInt()
'            LockMutex( taskmutex )
'            For Local task:TMessage = EachIn taskqueue
'                If task.id = id 
'                    task.cancelled = True
'                    Exit
'                End If
'            Next
'            UnlockMutex( taskMutex )
'        Case "sendmessage"         ' Send a message to the language client
'            pushSendQueue( String(data) )
'        Case "pushtask"             ' Add a task to the task queue
'            Publish( "debug", "Pushtask received")
'            Local task:TMessage = TMessage(data)
'            If task pushTaskQueue( task )
'            Publish( "debug", "Pushtask done" )
'		EndRem
'        Case "exitnow"      ' System exit requested
'            ' Force waiting threads to exit
'            PostSemaphore( sendCounter )
'            'PostSemaphore( taskCounter )
'        Default
'            logfile.error( "TMessageQueue: event '"+event+"' ignored" )
'        End Select
'    End Method

    Private

    ' Add a new message to the queue
    Method pushTaskQueue( message:TMessage )
        'Publish( "debug", "PushTaskQueue()" )
        If Not message Return
        'Publish( "debug", "- task is not null" )
        LockMutex( TaskMutex )

		'Local JID:JSON = message.J.find("id")
		'Local taskid:String = JID.tostring()
		logfile.debug( "Pushing Message Task ("+message.msgid+", '"+ message.methd +"'" )
		
        'Publish( "debug", "- task mutex locked" )
        'taskqueue.insert( message.taskid, message )
		taskqueue.addlast( message )
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

	' Raises an event for a message
	'Method TaskToEvent( task:TMessage )
		'TMSG.emit()
	'End Method

	Public

	'	V3 MESSAGE HANDLERS
	'	DEPRECIATED


	' Received a message from the client
'	Method onReceivedFromClient:TMessage( message:TMessage )		
'		logfile.debug( "TMessageQueue.onReceivedFromClient()")
'		
'		' Message.Extra contains the original JSON from client
'		Local J:JSON = JSON( message.extra )
'		If Not J 
'			client.send( Response_Error( ERR_INVALID_REQUEST, "Invalid request" ) )
'			Return Null
'		End If
'		
'		' Check for a method
'		Local node:JSON = J.find("method")
'		If Not node 
'			client.send( Response_Error( ERR_METHOD_NOT_FOUND, "No method specified" ) )
'			Return Null
'		End If
'		
'		' Validate methd
'		Local methd:String = node.tostring()
'		If methd = "" 
'			client.send( Response_Error( ERR_INVALID_REQUEST, "Method cannot be empty" ) )
'			Return Null
'		End If
'		
'		' Extract "Params" if it exists (which it should)
'		'If J.contains( "params" )
'		Local params:JSON = J.find( "params" )
'		'End If
'
'		logfile.debug( "- ID:      "+message.getid() )
'		logfile.debug( "- METHOD:  "+methd )
'		'Publish( "debug", "- REQUEST:~n"+J.Prettify() )
'		'Publish( "debug", "- PARAMS:  "+params.stringify() )
'
'		' An ID indicates a request message
'		If J.contains( "id" )
'			logfile.debug( "- TYPE:    REQUEST" )
'			' This is a request, add to queue
'			logfile.debug( "Pushing request '"+methd+"' to queue")
'			pushTaskQueue( New TMessage( methd, J, params ) )
'			Return Null
'		End If
'					
'		' The message is a notification, send it now.
'		logfile.debug( "- TYPE:    NOTIFICATION" )
'		'Publish( "debug", "Executing notification "+methd )
'		New TMessage( methd, J, params ).emit()
'		'Return Null
'	End Method
	
	' Sending a message to the client
'	Method onSendToClient:TMessage( message:TMessage )
'		'Publish( "debug", "TMessageQueue.OnSendtoClient()" )
'
'		' Message.Extra contains the JSON being sent
'		Local J:JSON = JSON( message.extra )
'		If Not J
'			client.send( Response_Error( ERR_INTERNAL_ERROR, "Incomplete Event" ) )
'			Return Null
'		End If
'		
'		' Extract message
'		Local Text:String = J.stringify()
'		'publish( "debug", "TMessageQueue.onSendToClient()~n"+text )
'		logfile.debug( "TMessageQueue.onSendToClient()~n"+Text )
'		
'		If Text ; pushSendQueue( Text )
'		'Return null
'	End Method	

	' Cancel Request
'	Method OnCancelRequest:TMessage( message:TMessage )
'
'logfile.debug( "~n"+message.j.Prettify() )
'		' Message.Extra contains the original JSON being sent
'		' Message.Params contains the parameters
'		If Not message Or Not message.params
'			client.send( Response_Error( ERR_INTERNAL_ERROR, "Incomplete Event" ) )
'			Return Null
'		End If
'		
'		'Local JID:JSON = message.params.find( "id" )
'		'If Not JID
'		'	client.send( Response_Error( ERR_INVALID_REQUEST, "Missing ID" ) )
'		'	Return Null
'		'End If
'		'
'		'Local id:String = JID.toString()
'		LockMutex( taskmutex )
'		
'		logfile.debug( "# CANCELLING MESSAGE: "+message.MsgID )
'		' Remove from queue
'		taskqueue.remove( message )
'Rem
' Tlist does this anyway!
'		For Local task:TMessage = EachIn taskqueue		
'			If task.MsgID = id 
'                Publish( "# CANCELLING TASK: "+task.MsgID )
'				' Remove from queue
'                taskqueue.remove( task )
'				' Send confirmation back to client
'				client.send( Response_OK( task.MsgID ) )
'				Exit ' loop
'			End If
'		Next
'End Rem		
'		UnlockMutex( taskMutex )
'		
'		'	NOTIFICATION - No response required
'		'client.send( Response_OK( message.MsgID ) )
'		'Return null
'	End Method
	
	'	V4 MESSAGE HANDLERS
	'	REQUESTS MUST RETURN A RESPONSE OTHERWISE AN ERROR IS SENT

	Method on_ReceiveFromClient:JSON( message:TMessage )		' NOTIFICATION
		logfile.debug( "-> TMessageQueue.on_ReceiveFromClient()" )
		
		' J contains the original JSON payload from client
		If Not message Or Not message.J 
			client.send( Response_Error( ERR_INVALID_REQUEST, "Invalid request" ) )
			Return Null
		End If
		
		' Check for a method
		Local node:JSON = message.J.find("method")
		If Not node 
			client.send( Response_Error( ERR_METHOD_NOT_FOUND, "No method specified" ) )
			Return Null
		End If
		
		' Validate methd
		Local methd:String = node.tostring()
		If methd = "" 
			client.send( Response_Error( ERR_INVALID_REQUEST, "Method cannot be empty" ) )
			Return Null
		End If
		
		' Extract "Params" if it exists (which it should)
		'If J.contains( "params" )
		Local params:JSON = message.J.find( "params" )
		'End If

		logfile.debug( "- ID:      "+message.getid() )
		logfile.debug( "- METHOD:  "+methd )
		'Publish( "debug", "- REQUEST:~n"+J.Prettify() )
		'Publish( "debug", "- PARAMS:  "+params.stringify() )

		Local newMessage:TMessage = New TMessage( methd, message.J, params )

		' REQUEST or NOTIFICATION
		If message.request
			logfile.debug( "- TYPE:    REQUEST" )
			' This is a request, add to queue
			logfile.debug( "Pushing request '"+methd+"' to queue")
			pushTaskQueue( newMessage )		
		Else
			' The message is a notification, send it now.
			logfile.debug( "- TYPE:    NOTIFICATION" )
			'Publish( "debug", "Executing notification "+methd )
			'New TMessage( methd, message.J, params ).emit()
			newMessage.send()
			'Return Null
		End If
		' NOTIFICATION: No response required
	End Method

	' Sending a message to the client
	Method on_SendToClient:JSON( message:TMessage )			' NOTIFICATION
		'Publish( "debug", "TMessageQueue.OnSendtoClient()" )

		' Message.J contains the JSON being sent
		'Local J:JSON = JSON( message.extra )
		If Not message Or Not message.J
			client.send( Response_Error( ERR_INTERNAL_ERROR, "Incomplete Event" ) )
			Return Null
		End If
		
		' Extract message
		Local Text:String = message.J.stringify()
		'publish( "debug", "TMessageQueue.onSendToClient()~n"+text )
		logfile.debug( "TMessageQueue.on_SendToClient()~n"+Text )
		
		If Text ; pushSendQueue( Text )
		'Return null
		' NOTIFICATION: No response required
	End Method	

	Method On_CancelRequest:TMessage( message:TMessage )			' NOTIFICATION
		logfile.debug( "TMessageQueue.on_CancelRequest~n"+message.j.Prettify() )
		' Message.J contains the original JSON being sent
		' Message.Params contains the parameters
		If Not message Or Not message.params
			client.send( Response_Error( ERR_INTERNAL_ERROR, "Incomplete Event" ) )
			Return Null
		End If
		
		'Local JID:JSON = message.params.find( "id" )
		'If Not JID
		'	client.send( Response_Error( ERR_INVALID_REQUEST, "Missing ID" ) )
		'	Return Null
		'End If
		'
		'Local id:String = JID.toString()
		LockMutex( taskmutex )
		
		logfile.debug( "# CANCELLING MESSAGE: "+message.MsgID )
		' Remove from queue
		taskqueue.remove( message )
	
		UnlockMutex( taskMutex )
		
		'client.send( Response_OK( message.MsgID ) )
		'Return null
		'	NOTIFICATION - No response required
	End Method


	Method on_exit:JSON( message:TMessage )					' NOTIFICATION
		' Force waiting threads to exit
		PostSemaphore( sendCounter )
		' NOTIFICATION: No response required
	End Method
End Type



