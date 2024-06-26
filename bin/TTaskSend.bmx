
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	Simply sends a message to the client

Type TTaskSend Extends TTask

	Field message:String

	Method New( message:String )
		priority = QUEUE_PRIORITY_HIGH
		unique = False
		Self.message = message
		Local temp:String = message
		If Len(temp)>30 ; temp = temp[..30]
		name = "Send{"+temp+"}"
	End Method

	Method launch()
		
		'Trace.debug( "TMessageQueue.on_SendToClient()~n"+Text )
		If Len(message)>500 
			Trace.debug( "TTaskSend~n"+message[0..500]+"..." )
		Else
			Trace.debug( "TTaskSend~n"+message )
		End If

		' Send to IDE
		If message ; client.write( message )
		
	End Method

End Type