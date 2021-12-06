
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

Type TClient Extends TMessageQueue
	Field documentSettings:JSON = New JSON()
	Field initialized:Int = False
	
	Field messageCounter:Int = 0		' Outgoing message ID
	
	' Fields taken from "initialize" message
	Field clientname:String = "Unknown"
	Field clientver:String = ""
	Field capabilities:JSON = New JSON()
	
	'Method New()
		'listen()
		'
		'	REGISTER CAPABILITIES
		
		' Enable workspace/didChangeWorkspaceFolders notifications
		'lsp.capabilities.set( "workspace|workspaceFolders|changeNotification", "true" )

		' Enable onDidChangeConfiguration
		'lsp.capabilities.set( "workspace|workspaceFolders|changeNotification", "true" )

	'End Method
	
	'Method Close()
	'	unlisten()
	'End Method
	
	'Method onInitialize:TMessage( message:TMessage )
	Method initialise( params:JSON )
		logfile.debug( "TClient.initialize()" )
		initialized = True
		'logfile.debug( "PARAMS:~n"+params.prettify() )
		If Not params Return
		'logfile.write( "PARAMS EXIST" )

		'Local id:String = message.getid()
		'Local params:JSON = message.params
		'publish( "log", "DBG", "MESSAGE~n"+params.Prettify() )
		
		' Extract Client Capabilities
		capabilities = params.find( "capabilities" )
		'publish( "log", "DBG", "CLIENT CAPABILITIES~n"+capabilities.Prettify() )
		
        ' Save Client information
		Local clientinfo:JSON = params.find( "clientInfo" )    ' VSCODE=clientInfo
		If clientinfo
			'logfile.write( "CLIENT INFO EXISTS" )
			clientname = clientinfo["name"]
			clientver = clientinfo["version"]
			logfile.info "CLIENT INFORMATION:"
			logfile.info "  NAME:    "+clientname
			logfile.info "  VERSION: "+clientver
		Else
			logfile.info( "NO CLIENT INFO EXISTS" )
		End If	
		
	End Method
	
	Method getDocumentSettings:JSON( resource:String )
		Return capabilities.find( resource )
	End Method
	
	' Check if Client has a particular capability (works by name only)
	Method contains:Int( capability:String )
		Return Not( capabilities.search( capability ) = Null )
	End Method

	' Check if Client has a particular capability (Only works with Boolean types)
	Method has:Int( capability:String )
		Local J:JSON = capabilities.find( capability )
		Return ( J And J.isTrue() )
		'If Not J Return False
		'Return ( J.tostring() = "true" )
	End Method
	
	' HELPER: Send a message to client by pushing it to the send queue
	Method logMessage( message:String, messagetype:Int )
		Local J:JSON = EmptyResponse( "window/logMessage" )
		J.set( "params|type",  messagetype  )
		J.set( "params|message", message )
		sendMessage( J.stringify() )
	End Method
	
	' HELPER: Send a message to client by pushing it to the send queue
	' MESSAGE MUST BE VALID JSON REQUEST/REPLY OR NOTIFICATION
	Method SendMessage( message:String )

		' Check we have a valid JSON object, or replace with error
		'If Not message ; message = Response_Error( ERR_INTERNAL_ERROR, "Incomplete Event" ) 
		
		' Extract message
		'Local Text:String = message.stringify()
		
		'logfile.debug( "TMessageQueue.on_SendToClient()~n"+Text )
		If Len(message)>500 
			logfile.debug( "TClient.SendMessage()~n"+message[0..500]+"..." )
		Else
			logfile.debug( "TClient.SendMessage()~n"+message )
		End If

		If message ; pushSendQueue( message )
	End Method
	
	' Generate a random work done token for progress bars
	Method genWorkDoneToken:String()
		Local token:String
		token :+ Hex(Rand(-$0FFFFFFF,$0FFFFFFF))+"-"
		token :+ Hex(Rand(0,$0000FFFF))[4..8]+"-"
		token :+ Hex(Rand(0,$0000FFFF))[4..8]+"-"
		token :+ Hex(Rand(0,$0000FFFF))[4..8]+"-"
		token :+ Hex(Rand(-$0FFFFFFF,$0FFFFFFF))
		Return Lower(token)
	End Method
	
	Method getNextMsgID:Int()
		Local id:Int = messageCounter
		messageCounter :+ 1
		Return id
	End Method
	
	' CREATE A PROGRESS TOKEN
	Method progress_register:String()
		Local J:JSON = EmptyResponse( "window/workDoneProgress/create" )
		Local token:String = genWorkDoneToken() 
		J.set( "id", getNextMsgID() )
		J.set( "params|token", token )
		sendMessage( J.stringify() )
		Return token
	End Method
	
	' SEND A PROGRESS BEGIN
	Method progress_begin( workDoneToken:String, title:String, message:String, cancellable:Int=False )
		Local J:JSON = EmptyResponse( "$/progress" )
		J.set( "params|token", workDoneToken )
		J.set( "params|value|kind", "begin" )
		J.set( "params|value|title", title )
		J.set( "params|value|cancellable", cancellable )
		J.set( "params|value|message", message )
		J.set( "params|value|percentage", 0 )
		sendMessage( J.stringify() )
	End Method

	Method progress_update( workDoneToken:String, message:String, percentage:Int )
		Local J:JSON = EmptyResponse( "$/progress" )
		J.set( "params|token", workDoneToken )
		J.set( "params|value|kind", "report" )
		J.set( "params|value|message", message )
		J.set( "params|value|percentage", percentage )
		sendMessage( J.stringify() )
	End Method
	
	Method progress_end( workDoneToken:String, message:String )
		Local J:JSON = EmptyResponse( "$/progress" )
		J.set( "params|token", workDoneToken )
		J.set( "params|value|kind", "end" )
		J.set( "params|value|message", message )
		sendMessage( J.stringify() )
	End Method
	
	
End Type

