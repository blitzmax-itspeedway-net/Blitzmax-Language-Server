
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	Simply sends a message to the client

Type TTaskSend Extends TTask

	Field message:JSON

	Method New( message:JSON )
		priority = QUEUE_PRIORITY_HIGH
		unique = False
		Self.message = message
	End Method

	Method launch()
		client.write( message.Stringify() )
	End Method

End Type