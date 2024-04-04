SuperStrict

Import bmx.observer
Import bmx.json

Import "constants.bmx"
Import "generic.bmx"
Import "lsp_types.bmx"
Import "messages.bmx"
Import "trace.bmx"

Client.initialise()

' NAMESPACE / Not creatable
Type Client Implements IObserver

	Private
	Global instance:Client

	Global JCapabilities:JSON			' Capabilities
	Global traceValue:String = "off"	' $/setTrace and $/logTrace use this value
	
	' 
	Method New()
		Observer.on( MSG_CLIENT_IN, Self )
		Observer.on( MSG_SERVER_OUT, Self )
	End Method
	
	Public

	Method Observe( id:Int, data:Object )
		Local J:JSON = JSON( data )
		If Not J; Return

		Local msgid:String = J["id"].toString()
		Local methd:String = J["method"].toString()

		' Do not create a circular reference by sending logtrace about logtrace:
		If methd = "$/logTrace"; Return		
		
		' Build response
		Local message:String, verbose:String
		Select id
		Case MSG_CLIENT_IN	; 	message = "received"
		Case MSG_SERVER_OUT	;	message = "sent"
		End Select
			
		Select True
		Case msgid<>"" And methd<>""
			message :+ " request '"+methd+" - ("+msgid+")'."
			verbose = J.find("params").Prettify()
		Case msgid=""  And methd<>""
			message :+ " notification '"+methd+"'."
			verbose = J.find("params").Prettify()
		Case msgid<>"" And methd=""
			
			If J.exists("error")
				message :+ " response ("+msgid+") - ERROR."
				verbose = J.find("error").Prettify()
			ElseIf J.exists("result")
				message :+ " response ("+msgid+") - OK."
				verbose = J.find("result").Prettify()
			Else
				message :+ " response ("+msgid+")."
				verbose = J.prettify()
			End If
			
		Default
			message = "invalid message."
			verbose = J.prettify()
		End Select

		' Send logTrace
		
		Client.logTrace( AppTitle + " " + message, verbose )
		
	End Method
	
	Function Initialise()
		If Not instance; instance = New Client()
	End Function

	' ===== CLIENT CAPABILITIES =====
	
	Function setCapabilities:Int( J:JSON )
		JCapabilities = J
		
		'Trace.debug( J.stringify() )

		'capabilities = TClientCapabilities( J.Transpose( "TClientCapabilities" ) )
		'If Not capabilities; Return False
		
		'If capabilities.workspace
		'	hasConfigurationCapability = capabilities.workspace.configuration
		'End If
		'Local workspace.configuration
		'Trace.debug( "client.hasConfigurationCapability IS: "+["FALSE","TRUE"][client.hasConfigurationCapability] )
		Trace.debug( "Client has:" )
		Trace.debug( "- ConfigurationCapability: "+iif( has("workspace|configuration") ) )
		Trace.debug( "- workspace.didChangeWatchedFiles: "+iif( has("workspace|didChangeWatchedFiles|dynamicRegistration") ) )
		Trace.debug( "- window.workDoneProgress: "+iif( has("window|workDoneProgress") ) )

		Return True
	End Function
	
	Function has:Int( capability:String )
		Return JCapabilities.find( capability ).toInt()
	End Function
	
	' ===== $/setTrace, $/logTrace =====
	
	Function setTrace( value:String )
		Select value
		Case "off", "messages", "verbose"
			traceValue = value
			Trace.debug( "TraceValue set to: "+value )
		Default
			Trace.error( "$/setTrace('"+value+"') is invalid" )
		End Select
	End Function
	
	Function getTrace:String()
		Return traceValue
	End Function

	Function logTrace( message:String, verbose:String="" )
		Trace.debug( "LOGTRACE="+TraceValue+": '"+message+"'" )
		Select TraceValue
		Case "messages"
			Local J:JSON = New JNotification( "$/logTrace" )
			J["params|message"] = message
			send( J )
		Case "verbose"
			Local J:JSON = New JNotification( "$/logTrace" )
			J["params|message"] = message
			J["params|verbose"] = verbose
			send( J )
		End Select
	End Function

	' ===== CLIENT REQUEST / NOTIFICATION =====

	' Send a message to the client
	' THIS MUST NOT BE USED FOR REPLIES: see TMessage.reply() and TMessage.error()
	' Message must be a fully compliant json_rpc 2 Request or Notification
	Function send( message:JSON )
		Observer.post( MSG_SERVER_OUT, message )
	End Function

	' ===== CLIENT WINDOW MESSAGES =====

	' Sends a log message to the client
	' This is displayed in the extension log
	Function Log( message:String, loglevel:Int = MESSAGETYPE.Log )
		Local J:JSON = New JNotification( "window/logMessage" )
		J.set( "params|message", message )
		J.set( "params|type", loglevel )
		Observer.post( MSG_SERVER_OUT, J )
	End Function

	' Sends a log message to the client
	' This is displayed as a popup message
	Function Show( message:String, loglevel:Int = MESSAGETYPE.Log )
		Local J:JSON = New JNotification( "window/showMessage" )
		J.set( "params|message", message )
		J.set( "params|type", loglevel )
		Observer.post( MSG_SERVER_OUT, J )
	End Function
	
End Type