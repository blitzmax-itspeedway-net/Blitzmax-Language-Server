
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	Simply sends a message to the client

Type TTaskSend Extends TTask

	Field message:String

	Method New( message:String )
		priority = QUEUE_PRIORITY_HIGH
		unique = False
		Self.message = message
	End Method

	Method launch()
		
		'logfile.debug( "TMessageQueue.on_SendToClient()~n"+Text )
		If Len(message)>500 
			logfile.debug( "TTaskSend~n"+message[0..500]+"..." )
		Else
			logfile.debug( "TTaskSend~n"+message )
		End If

		' Send to IDE
		If message ; client.write( message )
		
	End Method

End Type