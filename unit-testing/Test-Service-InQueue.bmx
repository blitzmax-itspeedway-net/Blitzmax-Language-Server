SuperStrict
'   UNIT TEST: Service-InQueue
'
'   (c) Copyright Si Dunford, MMM 2022, All Rights Reserved. 
'   VERSION: 1.0

Import bmx.observer
Import bmx.json

Import "../lib/Service_InQueue.bmx"
Import "../lib/messages.bmx"

Observer.threaded()

Graphics 320,200

Local watcher:TWatcher = New TWatcher()

' Start the service thread

Service_InQueue.start()

Local quit:Int = False
Repeat
	Cls
	DrawText( "N - Create a dummy Client Notification", 5,5 )
	DrawText( "R - Create a dummy Client Request", 5,15 )
	DrawText( "S - Create a dummy Server Request", 5,25 )
	DrawText( "A - Create a dummy Client Reply", 5,35 )

	DrawText( "1 - Send 'initialize'", 5,55 )
	DrawText( "2 - Send 'initialized'", 5,65 )
	DrawText( "3 - Send 'shutdown'", 5,75 )
	DrawText( "4 - Send 'exit'", 5,85 )

	DrawText( "Q - Quit", 5,105 )

	Local result:Int[] = Service_InQueue.instance.debug()

	DrawText( result[0]+" records in Message Queue", 5,175 )
	DrawText( result[1]+" records in Requests Queue", 5,185 )
	
	If KeyHit( KEY_A )
		Local dummy:String = "{'jsonrpc':'2.0','id':22,'result':{'test':'example'}}".Replace("'",Chr(34))
		Observer.Post( MSG_CLIENT_IN, JSON.Parse( dummy ) )
	End If
	
	If KeyHit( KEY_N )
		Local dummy:String = "{'jsonrpc':'2.0','method':'$/dummy'}".Replace("'",Chr(34))
		'Print( dummy)
		Observer.Post( MSG_CLIENT_IN, JSON.Parse( dummy ) )
	End If

	If KeyHit( KEY_R )
		Local dummy:String = "{'jsonrpc':'2.0','id':1,'method':'textDocument/dummy'}".Replace("'",Chr(34))
		'Print( dummy)
		
		Observer.Post( MSG_CLIENT_IN, JSON.Parse( dummy ) )
	End If
	
	If KeyHit( KEY_S )
		Local dummy:String = "{'jsonrpc':'2.0','id':22,'method':'dummy','params':{'example':'sample'}}".Replace("'",Chr(34))
		'Print( dummy)
		'DebugStop
		'Local x:JSON = JSON.Parse(dummy)
		'Print x.stringify()
		'DebugStop
		Observer.Post( MSG_SERVER_OUT, JSON.Parse( dummy ) )
	End If
	
	If KeyHit( KEY_Q ) Or KeyHit( KEY_ESCAPE ); quit = True
	
	If KeyHit( KEY_1 )
		Local dummy:String = "{'jsonrpc':'2.0','id':0,'method':'initialize','params':{'processId':17638,'clientInfo':{'name':'Example IDE','version':'0.0.1'},'locale':'en-gb','rootPath':'/','rootUri':'file:///','capabilities':{}},'trace':'messages','workspaceFolders':[{'uri':'file:///home/si/dev/sandbox/bls/testqueue','name':'testqueue'}]}".Replace("'",Chr(34))
		Observer.Post( MSG_CLIENT_IN, JSON.Parse( dummy ) )
	End If

	If KeyHit( KEY_2 )
		Local dummy:String = "{'jsonrpc':'2.0','method':'initialized','params':{}}".Replace("'",Chr(34))
		Observer.Post( MSG_CLIENT_IN, JSON.Parse( dummy ) )
	End If
	
	If KeyHit( KEY_3 )
		Local dummy:String = "{'jsonrpc':'2.0','id':1,'method':'shutdown'}".Replace("'",Chr(34))
		Observer.Post( MSG_CLIENT_IN, JSON.Parse( dummy ) )
	End If

	If KeyHit( KEY_4 )
		Local dummy:String = "{'jsonrpc':'2.0','id':8,'method':'exit'}".Replace("'",Chr(34))
		Observer.Post( MSG_CLIENT_IN, JSON.Parse( dummy ) )
	End If

	
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
			DebugLog( "> INBOUND:  "+j.stringify() )
		Case MSG_SERVER_OUT
			'Print( J.stringify() )
			DebugLog( "< OUTBOUND: "+j.stringify() )
		Case EV_TASK_ADD
			Local task:TTask = TTask( data )
			DebugLog( ": TASK.add:    "+ task.name+"/"+task.id )
		Case EV_TASK_CANCEL
			Local task:TTask = TTask( data )
			DebugLog( ": TASK.cancel: "+ task.name+"/"+task.id )
		Case LOGTRACE
			Local logdata:Trace = Trace( data )
			If logdata; DebugLog( "- LOGTRACE: "+Trace.Prefix(logdata.level)+", "+logdata.message )
		End Select
	End Method
	
End Type