SuperStrict

Import bmx.observer

'	Client Messages
'	MSG_CLIENT_IN is a Request or Notification from Client to the Server
'	MSG_SERVER_OUT is a Reply, Request or Notification from Server to the Client

Global MSG_CLIENT_IN:Int	= Observer.Allocate( "Inbound Message from Client" ) ' JSON
Global MSG_SERVER_OUT:Int	= Observer.Allocate( "Outbound Message to Client" )  ' JSON

'	Server Messages
'	EV_CLIENT_REQUEST is a message sent to the client and awaiting a response.
'Global EV_CLIENT_REQUEST:Int	=  Observer.Allocate( "Request from Server to Client" )

'	MESSAGES
Global EV_TASK_ADD:Int			=  Observer.Allocate( "Add task" )		' TASK
Global EV_TASK_CANCEL:Int		=  Observer.Allocate( "Cancel task" )	' JSON
Global EV_SYSTEM_STATE:Int		=  Observer.Allocate( "System State" )	' int[]

Enum MESSAGECLASS
	NONE			= $00
	'ID				= $01	' Bit-Value when message has an ID field
	'METHD			= $10	' Bit-Value when message has a METHOD field	
	REQUEST			= $11	' Request has an ID and a METHOD
	RESPONSE		= $01	' Response has an ID but not a METHOD
	NOTIFICATION	= $10	' Notification has a METHOD but not an ID	
EndEnum

Enum ESYSTEMSTATE
	NONE			= 0		' BEFORE initialise
	INITIALIZING	= 1		' AFTER initialise, BEFORE initialise response
	INITIALIZED		= 2		' AFTER initialise response, BEFORE initialised
	READY			= 3		' AFTER initialised (Normal running)
	SHUTDOWN		= 4		' AFTER shutdown
EndEnum
