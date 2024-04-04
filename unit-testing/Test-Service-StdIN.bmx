SuperStrict
'   UNIT TEST: Service-StdIN
'
'   (c) Copyright Si Dunford, MMM 2022, All Rights Reserved. 
'   VERSION: 1.0

Import bmx.observer
Import bmx.json

Import "../lib/Service_StdIN.bmx"
Import "../lib/messages.bmx"

Observer.threaded()

Local Watcher:TWatcher = New TWatcher()

' Start the service thread
Service_StdIN.start()

Repeat
	Delay(5)
Until AppTerminate()

Type TWatcher Implements IObserver

	Method New()
		Observer.on( MSG_CLIENT_IN, Self )
		Observer.on( MSG_SERVER_OUT, Self )
	End Method

	Method Observe( id:Int, data:Object )
		Local J:JSON = JSON( data )
		Select id
		Case MSG_CLIENT_IN
			DebugLog( "> INBOUND:  "+j.stringify() )
		Case MSG_SERVER_OUT
			DebugLog( "< OUTBOUND: "+j.stringify() )
		End Select
	End Method
	
End Type

