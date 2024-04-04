SuperStrict

Import bmx.JSON

'Import "application.bmx"
'Import "client.bmx"
Import "constants.bmx"
Import "generic.bmx"
Import "lsp_types.bmx"
Import "trace.bmx"
Import "tasks.bmx"

Type TMessage Extends TTask

	Const EXPIRATION:Int = 10000					'350000	' 5 minutes timeout

	Global handlers:TStringMap = New TStringMap()	' Registered Message handlers
	Global defHandler:Object						' Default handler

	Field created:Long								' Time message created
	Field response_posted:Int = False				' Flag to identify if a response sent
	
	Field request:JSON								' Request
	Field response:JSON								' Client response to server request
	
	' Request Fields
'	Field id:String										' Original message "id"
	Field methd:String		{serialisedname="method"}	' Original message "method"
	
'	Field name:String       = "{Unnamed}"		' Used to identify message in logs		
	Field class:MESSAGECLASS = MESSAGECLASS.NONE	' Used to identify REQUEST/REPLY or NOTIFICATION

	Method New( request:JSON )
		Self.request = request
		created = Long(MilliSecs())
		If Not request Or request.isInvalid(); Return
		classify()
		'Print( "Message " + name )
		'Print( "id:     " + id )
		'Print( "method: " + methd )
	End Method
			
	' Classify message
	Method classify()
		class = MESSAGECLASS.NONE
		'If Not data; Print( "DATA is null" )
		If Not request; Return 

		' Extract ID and METHOD (if they exist) 
		If request.contains( "id" )     ; id = request.find( "id" ).toInt()	'String()
		If request.contains( "method" ) ; methd = request.find( "method" ).toString()

		Select True
		Case id<>"" And methd<>""	;	class = MESSAGECLASS.REQUEST
		Case id=""  And methd<>""	;	class = MESSAGECLASS.NOTIFICATION
		Case id<>"" And methd=""	;	class = MESSAGECLASS.RESPONSE
		End Select
		
		name = "{"+classname()+"|"+iif(id="","-",id)+"|"+iif(methd="","-",methd)+"}"
		'Print( "NAME: "+name )
		
	End Method

	' Debugging method to identify class by name
	Method classname:String()
		Return class.toString()
	End Method
	
	' Timeout a server request to cancel it
	Method timeout:Int()

		Local now:Long = Long( MilliSecs() )
		If now < 0
			' Milliseconds overflowed, wait but doesn't need to be exact!
			now :+ 4294967296:Long
		End If
		
		'Trace.Debug( "TIMEOUT: " + name )
		'Trace.Debug( "- CREATED " + created )
		'Trace.Debug( "- EXPIRES " + ( created + EXPIRATION ))
		'Trace.Debug( "- NOW     " + now )		
		
		Return( now > created + EXPIRATION )
	End Method

	' Task executor
	Method run()
	
		Trace.info( "Task "+name+": Starting" )
		TMessage.handle( Self )
		Trace.info( "Task "+name+": Completed" )

		' No response necessary:
		If class = MESSAGECLASS.NOTIFICATION Or ..
		   class = MESSAGECLASS.RESPONSE; Return
		
		' Response sent:
		If response_posted; Return
		
		' Report a system error
		Trace.error( name+" did not respond to server" )
		Error( ERRORCODES.InternalError, "Server failed to respond '"+methd+"' ("+id+")" )
	End Method
	
	' Method used by handler to return a reply to the server
	Method reply( result:JSON = Null )
		Local J:JSON = New JResponse_Ok( Self, result )
		Observer.post( MSG_SERVER_OUT, J )
		'sendLogTrace( "Server response '"+methd+"' ("+id+")" )
		response_posted = True
	End Method
	
	' Method used by handler to return an error to the server
	Method error( errcode:Int, errtext:String="" )
		Local J:JSON = New JResponse_Error( Self, errcode, errtext )
		Observer.post( MSG_SERVER_OUT, J )
		'sendLogTrace( errtext+" [ERR:"+errcode+"] "+methd+" ("+id+")" )
		response_posted = True
	End Method
	
	' Register a type to receive messages
	Function register( prefix:String, handler:Object )
		If Not prefix Or Not handler; Return
		' Set the default handler
		handlers.insert( prefix, handler )
	End Function 

	' Uses reflection to identify a message handler in a list of 
	' registered objects
	Function handle( message:TMessage )
		If Not message; Return		
		
		' Pre-handle $/setTrace
		'If message.methd = "$/setTrace"
		'	Local value:String = message.request.find("params|value").toString()
		'	Client.setTrace( value )
		'	Return
		'End If
		
		' Identify the object that handles the message
		
		Local handler:Object
		Local slash:Int = Instr( message.methd, "/" )
		' Try method startsWith
		If slash > 0
			Trace.Debug( "# Matching handler: "+message.methd[..(slash-1)] )
			handler = handlers[ message.methd[..(slash-1)] ]
		End If
		' Try full method
		If Not handler
			Trace.Debug( "# Matching handler: "+message.methd )
			handler = handlers[ message.methd ]
		End If
		' Fallback to default
		If Not handler
			Trace.Debug( "# Matching handler: *" )
			handler = handlers[ "*" ]
		End If
		' No handler defined
		If Not handler
			Trace.Debug( "# No handler for "+message.name )
			message.error( ERRORCODES.MethodNotFound, "No handler for "+message.name )
			'sendLogTrace( "Server has no handler for "+message.methd )
			Return
		End If
		
		' Create Function String; removing unwanted characters
		
		Local MethodName:String = "on_"+message.methd
		MethodName = Replace( MethodName, "$/", "dollar_" )
		MethodName = Replace( MethodName, "/", "_" )
		MethodName = Replace( MethodName, "-", "_" )
		
		' Find message handler for Method
		Local parent:TTypeId = TTypeId.ForObject( handler )
		If Not parent; Return
		Local FN:TMethod = parent.FindMethod( MethodName )

		' If specific message handler does not exist, try a default one
		If Not FN
			Trace.debug( message.name+" handler missing in '"+parent.name()+"' falling back to default" )
			FN = parent.FindMethod( "on_message" )
		End If

		' Handle the event
		If FN
			' Call the message handler
			FN.invoke( handler, [message] )
		Else
			' Method doesn't exist, so respond with an error
			Trace.debug( "Default handler does not exist in type '"+parent.name()+"'" )
			Local J:JSON = New JError( ERRORCODES.MethodNotFound, "Method Not Found" )
			'sendLogTrace( "Server has no handler for "+message.methd )
			If message.id; J["id"] = message.id
			Observer.post( MSG_SERVER_OUT, J )
		End If
		
	End Function
	

	
End Type




Rem
Type TMessage Extends TLSPMessage

	Field params:JSON							' Original message "params"
	Field result:JSON							' Used when class=RESPONSE

	'Field priority:Int							' Used to priorotise messages in the queue
	
	Private
	
	'Field _created:Long				' Time message created
    'Field _cancelled:Int = False	' Message cancellation	


	Public
	
	Method New( data:JSON )
		' Arguments
		Self.data = data
		classify()

		' Extract params
		'params = data.find( "params" )
		'result = data.find( "result" )
	End Method
	
End Type
End Rem

' A TServerRequest is held in a list by the InQueue and matched
' against replies coming in from the client or times out.

Rem
Type TServerRequest Extends TLSPMessage

	Const EXPIRATION:Int = 10000	'350000	' 5 minutes timeout

	Field created:Long				' Time message created
		
	Method New( request:JSON )
		Super.New( request )
		created = Long(MilliSecs())
		'data = request
		If Not data Or data.isInvalid(); Return
		'classify()
		Print( "Message " + name )
		Print( "id:     " + id )
		Print( "method: " + methd )
	End Method
		
	Method timeout:Int()

		Local now:Long = Long( MilliSecs() )
		If now < 0
			' Milliseconds overflowed, wait but doesn't need to be exact!
			now :+ 4294967296:Long
		End If
		
		'Trace.Debug( "TIMEOUT: " + name )
		'Trace.Debug( "- CREATED " + created )
		'Trace.Debug( "- EXPIRES " + ( created + EXPIRATION ))
		'Trace.Debug( "- NOW     " + now )		
		
		Return( now > created + EXPIRATION )
	End Method
	
End Type
End Rem

' General response
Type JResponse_Ok Extends JSON

	' Without a result, we simple return JSON:null
	Method New( request:TMessage, result:JSON=Null )
		set( "id", request.id )
		set( "jsonrpc", "2.0" )
		If result = Null; result = New JSON( JNULL )
		set( "result", result )
	End Method

End Type

Type JResponse_Error Extends JSON

	' We do not complete "result" or "error" because we don't know which it might be
	Method New( request:TMessage, ErrorCode:Int, ErrorText:String )
		set( "id", request.id )
		set( "jsonrpc", "2.0" )
		set( "error|code", ErrorCode )
		set( "error|message", ErrorText )
	End Method

End Type

Type JRequest Extends JSON

	Method New( methd:String, params:JSON=Null )
		set( "jsonrpc", "2.0" )
		set( "id", GenerateID() )
		set( "method", methd )
		If params; set( "params", params )
	End Method
	
End Type

Type JNotification Extends JSON

	Method New( methd:String, params:JSON=Null )
		set( "jsonrpc", "2.0" )
		set( "method", methd )
		If params; set( "params", params )
	End Method
	
End Type

Type JError Extends JSON

	Method New( ErrorCode:Int, ErrorText:String )
		set( "jsonrpc", "2.0" )
		set( "error|code", ErrorCode )
		set( "error|message", ErrorText )
	End Method

End Type

'Function JFactory:JSON( class:String="" )
'	Select class
'	'Case "messaged"
'	'	Return JSON.serialise( new Tkkk) 
'	Default
'		Return New JSON()
'	End Select
'End Function

' This type is used during onInitialised to create client registrations
Type JRegistration Extends JSON

	Method New( capability:String, options:JSON=Null )
		set( "id", GenerateUID() )
		set( "method", capability )
		If options; set( "registerOptions", options )
	End Method
	
End Type

