SuperStrict

'   Input Queue Service for BlitzMax Language Server
'   (c) Copyright Si Dunford, JAN 2023, All Rights Reserved.
'
'   VERSION: 1.0

Import bmx.observer
Import bmx.json

Import "messages.bmx"
'Import "jtypes.bmx"
Import "trace.bmx"
Import "tasks.bmx"

Observer.threaded()
Service_InQueue.initialise()

Type Service_InQueue Implements IObserver

	Global instance:Service_InQueue
	
	Field timeout:Int 		= 5000	' Default timeout value	
		
	Field MessageQueue:TList		' of JSON
	Field RequestQueue:TStringMap	' of TServerRequest by ID

	Field thread:TThread	= Null	' The message queue thread
	Field sleeper:TCondVar
	Field messageLock:TMutex
	Field requestLock:TMutex
	
	Field systemState:ESYSTEMSTATE = ESYSTEMSTATE.NONE
		
	Function initialise()
		If Not instance; instance = New Service_InQueue()
	End Function

	' Start Thread
	Function start()
		If Not instance; Throw( "Failed to start inputQueue" )
		instance.thread	= CreateThread( FN, instance )	
	End Function
		
	Method New()
		Trace.Info( "InputQueue Service starting" )
		
		MessageQueue = New TList()
		RequestQueue = New TStringMap()
		
		' Observer
		Observer.on( MSG_CLIENT_IN, Self )
		Observer.on( MSG_SERVER_OUT, Self )
		Observer.on( EV_SYSTEM_STATE, Self )
		
		' Start Thread
		sleeper     = CreateCondVar()
		messageLock = CreateMutex()
		requestLock = CreateMutex()
	
	End Method

	Method debug:Int[]()
		Local result:Int[2]
		LockMutex( messageLock )
		result[0] = messageQueue.count()
		UnlockMutex( messageLock )
		LockMutex( RequestLock )
		result[1] = 0
		For Local k:String = EachIn RequestQueue.Keys()
			result[1] :+ 1
		Next
		UnlockMutex( RequestLock )
		'Print( result[0]+","+result[1] )
		Return result
	End Method

	Method Observe( id:Int, data:Object )

		Select id
		' Inbound messages from client are added to a queue ready for classification
		' and processing
		Case MSG_CLIENT_IN
			Local J:JSON = JSON( data )
			If Not J; Return
						
			LockMutex( messageLock )
			MessageQueue.addlast( J )
			UnlockMutex( messageLock )
			sleeper.signal()	' Wake up the sleeping thread
		
		' Outbound Requests are added to a request queue ready to be matched to
		' replies or timed out by the thread
		Case MSG_SERVER_OUT
			'Print( "SERVER OUT" )
			'Print( J.stringify() )
			Local J:JSON = JSON( data )
			If Not J; Return
			Local request:TMessage = New TMessage( J )

			' Only keep SERVER REQUESTS (Not notification or anything else)
			If Not request; Return
			If Not (request.class = MESSAGECLASS.REQUEST); Return
			
			LockMutex( requestLock )
			RequestQueue.insert( request.id, request )
			UnlockMutex( requestLock)
		
		Case EV_SYSTEM_STATE
			' System state has changed
			systemstate = ESYSTEMSTATE(Int[](data)[0])	' Unbox the integer
			trace.debug( "InQueue received system state change: "+systemState.toString() )
		End Select
		
	End Method

	Method findRequest:TMessage( msgid:String )
		If Not Trim(msgid); Return Null
		Local id:Int = Int(msgid)
		Trace.Info( "MATCHING ID="+id )
		
		' Pop Request (if it exists)
		LockMutex( requestLock )
		Local request:TMessage = TMessage( RequestQueue.valueForKey( id ) )		
		If request ; RequestQueue.remove( id )
		UnlockMutex( requestLock )
		
		If request 
			Trace.Debug( "- REQUEST FOUND" )
		Else
			Trace.Debug( "- REQUEST NOT FOUND" )
		End If

		Return request
	End Method
	
	' Timeout old requests
	Method RequestTimeout()
		LockMutex( RequestLock )		
		For Local key:String = EachIn requestQueue.keys()
			Local request:TMessage = TMessage( requestQueue.valueForKey( key ) )
			If request 
				If request.timeout()
					Trace.Info( "- KEY "+key+" TIMEOUT" )
					' Remove from list
					requestQueue.remove( key )
					' Send a Cancellation to Client
					Local J:JSON = New JNotification( "$/cancelRequest" )
					J["params|id"] = key
					Observer.post( MSG_SERVER_OUT, J )
				End If
			Else
				' Invalid message, remove from list
				Trace.Info( "- INVALID KEY "+key+" REMOVED" )
				requestQueue.remove( key )
			End If
		Next
		UnlockMutex( RequestLock )
	End Method
	
	' Checks the system state before processing a message
	Method checkstate:Int( message:TMessage )
		If Not message; Return False
		
		Trace.info( "INQUEUE.checkstate( "+message.name+" ), state="+systemState )
		'Local state:Int = SYSTEMSTATE.get()
		Local methd:String = message.methd
		Local class:MESSAGECLASS = message.class
		
		' Exit is always allowed!
		If methd = "exit"; Return True
		
		' SYSTEMSTATE IS NONE

		Rem
		The initialize request is sent as the first request from the client to the server. 
		If the server receives a request or notification before the initialize request it should act as follows:

		* For a request the response should be an error with code: -32002. The message can be picked by the server.
		* Notifications should be dropped, except for the exit notification. This will allow the exit of a server without an initialize request.
		End Rem

		If systemState = ESYSTEMSTATE.NONE
			If methd = "initialize"
				Observer.post( EV_SYSTEM_STATE, [ESYSTEMSTATE.INITIALIZING.ordinal()] )
				Return True
			End If
			'If methd = "exit"; Return True
			'
			If message.class = MESSAGECLASS.REQUEST			
				message.error( ERRORCODES.ServerNotInitialized, "Server is not initialised" )
			EndIf
			Trace.debug( "INQUEUE DROPPING "+message.name+" DURING "+systemState.toString() )
			Return False
		End If
		
		' SYSTEMSTATE IS INITIALIZING
		
		Rem
		Until the server has responded to the initialize request with an InitializeResult, 
		the client must not send any additional requests or notifications to the server.
		End Rem
		
		If systemState = ESYSTEMSTATE.INITIALIZING
		
			If message.class = MESSAGECLASS.REQUEST			
				message.error( ERRORCODES.ServerNotInitialized, "Server is not initialised" )
			EndIf
			Trace.debug( "INQUEUE DROPPING "+message.name+" DURING "+systemState.toString() )
			Return False
			
		End If
		
		' SYSTEMSTATE IS SHUTDOWN
		
		Rem
		Only the Exit notification is allowed when the server is shut down
		(We have dealt with this earlier)
		End Rem
		
		If systemState = ESYSTEMSTATE.SHUTDOWN
			Trace.debug( "INQUEUE DROPPING "+message.name+" DURING "+systemState.toString() )
			Return False
		End If
		
		' Anything else is allowed
		Return True
	End Method
	
	' Worker Thread
	Function FN:Object( data:Object )
		Local this:Service_InQueue = Service_InQueue( data )

		LockMutex( this.messageLock )
		Repeat
			' Process Timeout for Requests 
			this.RequestTimeout()
		
			' Sleep for a while if message queue is empty
			If this.messagequeue.isempty(); this.sleeper.TimedWait( this.messageLock, this.timeout ) 

			' Get a message from the message queue
			' Condvar will have locked the resource already
			Local J:JSON = JSON( this.messageQueue.RemoveFirst() )
			If J
				Local message:TMessage = New TMessage( J )
				
				Trace.Debug( "InQueue: - ID:      "+message.id )
				Trace.Debug( "InQueue: - METHOD:  "+message.methd )
				Trace.Debug( "InQueue: - CLASS:   "+message.className() )
		
				' Check message is allowed in current state
				If Not this.checkState( message ); Continue
		
				' Process message into the queue
				Local methd:String = message.methd
				Select message.class
				Case MESSAGECLASS.REQUEST
					'Local task:TTask = New TTask_Request( message )
					Observer.post( EV_TASK_ADD, message )
				Case MESSAGECLASS.NOTIFICATION
					If message.methd = "$/cancelRequest"
						Observer.post( EV_TASK_CANCEL, message )
						'Observer.post( EV_TASK_CANCEL, New TTask_Notification( message ) )
					Else
						Observer.post( EV_TASK_ADD, message )
						'Observer.post( EV_TASK_ADD, New TTask_Notification( message ) )
					End If
				Case MESSAGECLASS.RESPONSE
					' Find matching request
					Local request:TMessage = this.findRequest( message.id )
					'Print "REQUEST:  "+request.data.stringify()
					'Print "RESPONSE: "+J.stringify()
					
					If request
					
						' If the response is simply "null", then we dont need to process anything
						' because the client has responded with "ok", so we can close it down
						'Trace.debug( "DO WE HAVE A NULL RESPONSE?" )
						'Trace.debug( J.stringify() )
						Local reply:JSON = J.find("result")
						If reply.isNull(); Continue
					
						' Merge Request and Response
						request.response = J
						'Local task:TTask = New TTask_Response( request, message )
						Observer.post( EV_TASK_ADD, request )
					Else
						Trace.Info( "InQueue:, Unable to match response to request "+message.id )
					End If
				End Select
								
			End If
						
		Forever
	End Function
	
End Type

Private






