
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

Type TClient Extends TMessageQueue
	Field documentSettings:JSON = New JSON()
	Field initialized:Int = False
	
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
	
	' Check if Client has a particular capability (Only works with Boolean types)
	Method has:Int( capability:String )
		Local J:JSON = capabilities.find( capability )
		Return ( J And J.isTrue() )
		'If Not J Return False
		'Return ( J.tostring() = "true" )
	End Method

	' HELPER: Send a message to client by pushing it to the send queue
	Method logMessage( message:String, messagetype:Int )
		Local J:JSON = EmptyMessage( "window/logMessage" )
		J.set( "params|type",  messagetype  )
		J.set( "params|message", message )
		send( J )
	End Method
	
	' HELPER: Send a message to client by pushing it to the send queue
	Method Send( message:JSON )

		' Check we have a valid JSON object, or replace with error
		If Not message ; message = Response_Error( ERR_INTERNAL_ERROR, "Incomplete Event" ) 
		
		' Extract message
		Local Text:String = message.stringify()
		
		'logfile.debug( "TMessageQueue.on_SendToClient()~n"+Text )
		Local dbg:String = Text[0..500]
		If Len(Text)>500 ; dbg :+ "..."
		logfile.debug( "TClient.Send()~n"+dbg )

		If Text ; pushSendQueue( Text )
	End Method
	
End Type

