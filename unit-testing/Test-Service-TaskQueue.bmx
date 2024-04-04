SuperStrict
'   UNIT TEST: Service-TaskQueue
'
'   (c) Copyright Si Dunford, MMM 2022, All Rights Reserved. 
'   VERSION: 1.0

Import bmx.observer
Import bmx.json

Import "../lib/Service_TaskQueue.bmx"
Import "../lib/messages.bmx"
Import "../lib/tasks.bmx"

Observer.threaded()

' Threadsafe Print
Global printlock:TMutex = CreateMutex()
Function Print( message:String )
	LockMutex( printlock )
	DebugLog( message )
	UnlockMutex( printlock )
End Function

Graphics 320,200

Local watcher:TWatcher = New TWatcher()

' Start the service thread

Service_TaskQueue.start()

Local quit:Int = False
Repeat
	Cls
	DrawText( "N - Create a Client Notification Task", 5,5 )
	DrawText( "R - Create a Client Request Task", 5,15 )
	DrawText( "S - Create a Server Request Task", 5,25 )
	DrawText( "Q - Quit", 5,45 )

	Local result:Int[] = Service_TaskQueue.instance.debug()

	DrawText( result[0]+" records in Task Queue", 5,75 )
	
	'If KeyHit( KEY_A )
	
	'	Local dummy:String = "{'jsonrpc':'2.0','id':22,'result':{'test':'example'}}".Replace("'",Chr(34))
	'	Observer.Post( MSG_CLIENT_IN, JSON.Parse( dummy ) )
	'End If
	
	If KeyHit( KEY_N )
		Local dummy:String = "{'jsonrpc':'2.0','method':'$/dummy'}".Replace("'",Chr(34))
		' This is what inQueue Service does with it:
		Local J:JSON = JSON.Parse( dummy )
		Local message:TMessage = New TMessage( J )
		' Post it to the Task Queue
		Observer.post( EV_TASK_ADD, message )
	End If

	If KeyHit( KEY_R )
		Local dummy:String = "{'jsonrpc':'2.0','id':1,'method':'shutdown'}".Replace("'",Chr(34))

		Local J:JSON = JSON.Parse( dummy )
		Local message:TMessage = New TMessage( J )
		Observer.post( EV_TASK_ADD, message )
	End If
	
	If KeyHit( KEY_S )
		Local dummy_request:String = "{'jsonrpc':'2.0','id':22,'method':'dummy','params':{'example':'sample'}}".Replace("'",Chr(34))
		Local dummy_reply:String = "{'jsonrpc':'2.0','id':22,'result':{'test':'example'}}".Replace("'",Chr(34))
		Local J:JSON 
		Local message:TMessage
				
		' Post the Request
		J = JSON.Parse( dummy_request )
		message = New TMessage( J )
		Observer.post( EV_TASK_ADD, message )

		' Post the response
		J = JSON.Parse( dummy_reply )
		message = New TMessage( J )
		Observer.post( EV_TASK_ADD, message )
		
	End If
	
	If KeyHit( KEY_Q ) Or KeyHit( KEY_ESCAPE ); quit = True
	Delay(5)
	Flip
Until AppTerminate() Or quit

Type TWatcher Implements IObserver

	Method New()
		Observer.on( MSG_CLIENT_IN, Self )
		Observer.on( MSG_SERVER_OUT, Self )
		Observer.on( EV_TASK_ADD, Self )
		Observer.on( EV_TASK_CANCEL, Self )
		Observer.on( LOGTRACE, Self )
	End Method

	Method Observe( id:Int, data:Object )
		'Print( "-> ["+ id+"] "+Observer.name(id) )
		Local J:JSON = JSON( data )
		
		Select id
		Case MSG_CLIENT_IN
			Print( "> INBOUND:  "+j.stringify() )
		Case MSG_SERVER_OUT
			'Print( J.stringify() )
			Print( "< OUTBOUND: "+j.stringify() )
		Case EV_TASK_ADD
			Local task:TTask = TTask( data )
			Print( ": TASK.add:    "+ task.name+"/"+task.id )
		Case EV_TASK_CANCEL
			Local task:TTask = TTask( data )
			Print( ": TASK.cancel: "+ task.name+"/"+task.id )
		Case LOGTRACE
			Local logdata:Trace = Trace( data )
			If logdata; Print( "- LOGTRACE: "+Trace.Prefix(logdata.level)+", "+logdata.message )
		End Select
	End Method
	
End Type
