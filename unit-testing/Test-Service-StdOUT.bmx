SuperStrict
'   UNIT TEST: Service-StdOUT
'
'   (c) Copyright Si Dunford, MMM 2022, All Rights Reserved. 
'   VERSION: 1.0

Import bmx.observer
Import bmx.json

Import "../lib/Service_StdOUT.bmx"
Import "../lib/messages.bmx"
'Import "../lib/jtypes.bmx"

Observer.threaded()
Local Watcher:TWatcher = New TWatcher()

' Start the service thread
Service_StdOUT.start()

Graphics 320,200


Repeat
	Cls
	DrawText( "Press a number", 5,5 )
	
	Local ch:Int = GetChar()
	
	If ch>0 And ch>=48 And ch<=57
		Print ch
		Local params:JSON = New JSON()
		params.set( "key", ch )
		Observer.post( MSG_SERVER_OUT, New JRequest( "$/example", params ) )
	End If
	
	Delay(5)
	Flip
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
