
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

Global client:TClient = New TClient()

Type TClient Extends TMessageQueue
	Field capabilities:JSON = New JSON()
	Field documentSettings:JSON = New JSON()
	Field initialized:Int = False
	
	Method New()
		listen()
		'
		'	REGISTER CAPABILITIES
		
		' Enable workspace/didChangeWorkspaceFolders notifications
		'lsp.capabilities.set( "workspace|workspaceFolders|changeNotification", "true" )

		' Enable onDidChangeConfiguration
		'lsp.capabilities.set( "workspace|workspaceFolders|changeNotification", "true" )

	End Method
	
	Method Close()
		unlisten()
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
	
	' HELPER: Send a message to client
	Method Send( message:JSON )
		New TMessage( "SEND-TO-CLIENT", message ).emit()		' Send message to client
	End Method

	' Get the client to register for configuration updates
	Method RegisterForConfigChanges()
		' Register for Configuration updates (If supported by client)
		If has( "workspace|configuration" )
			Publish( "log", "DGB", "# Client supports workspace configuration" )
			
			' Create an array for the configuration updates we need
			Local items:JSON = New JSON( JSON_ARRAY )

			' Create an array element for specific items and add to items array
			Local config:JSON = New JSON()
			config.set( "scopeUri", "resource" )
			config.set( "section","bls")
			items.addlast( config )
			
			config = New JSON()
			config.set( "scopeUri", "resource" )
			config.set( "section","blitzmax")
			items.addlast( config )

			' Create a response and add items to params
			Local response:JSON = New JSON()
			response.set( "jsonrpc", JSONRPC )
			response.set( "method", "workspace/configuration" )
			response.set( "params|items", items )			
			send( response )
		Else
			' Fallback to global (or local) settings
		End If
	End Method

	'	V0.3 EVENT HANDLERS
	'	WE MUST RETURN MESSAGE IF WE DO NOT HANDLE IT
	'	RETURN NULL WHEN MESSAGE HANDLED OR ERROR HANDLED

	Method onInitialize:TMessage( message:TMessage )
		publish( "log", "DBG", "TClient.onInitialize()" )
		initialized = True
		Local id:String = message.getid()
		Local params:JSON = message.params
		'publish( "log", "DBG", "MESSAGE~n"+params.Prettify() )
		
		' Extract Client Capabilities
		capabilities = params.find( "capabilities" )
		'publish( "log", "DBG", "CLIENT CAPABILITIES~n"+capabilities.Prettify() )
		
        ' Save Client information
        If params
            'logfile.write( "PARAMS EXIST" )
            'if params.isvalid() logfile.write( "PARAMS IS VALID" )
            Local clientinfo:JSON = params.find( "clientInfo" )    ' VSCODE=clientInfo
            If clientinfo
                'logfile.write( "CLIENT INFO EXISTS" )
                Local clientname:String = clientinfo["name"]
                Local clientver:String = clientinfo["version"]
                logfile.info "CLIENT INFORMATION:"
				logfile.info "  NAME:    "+clientname
				logfile.info "  VERSION: "+clientver
            Else
                logfile.info( "NO CLIENT INFO EXISTS" )
            End If

        End If

        ' RESPONSE 

		'V0.2, Capabilities are managed by the LSP
		'Local cap:JSON = lsp.capabilities

		logfile.info( "PUBLISHING SERVER CAPABILITIES:" )
		logfile.info( "  "+lsp.capabilities.stringify() )
		
        Local response:JSON = New JSON()
        response.set( "id", id )
        response.set( "jsonrpc", JSONRPC )
        'response.set( "result|capabilities", [["hover","true"]] )
        'response.set( "result|capabilities", [["hoverProvider","true"]] )

        response.set( "result|capabilities", lsp.capabilities )

        response.set( "result|serverinfo", [["name","~q"+AppTitle+"~q"],["version","~q"+version+"."+build+"~q"]] )

		'Publish( "log", "DEBG", "RESULT: "+response.stringify() )

		send( response )
		'
		message.state = STATE_COMPLETE
		
        'Return null

	End Method

	Method onDidChangeConfiguration:TMessage( message:TMessage )
		publish( "log", "DBG", "TClient.onDidChangeConfiguration()~n"+message.J.Prettify() )
		'documentSettings = message.value
	End Method

	Method onDidChangeWorkspaceFolders:TMessage( message:TMessage )
		publish( "log", "DBG", "TClient.onDidChangeWorkspaceFolders()~n"+message.J.Prettify() )
	End Method

	Method onDidChangeWatchedFiles:TMessage( message:TMessage )
		publish( "log", "DBG", "TClient.onDidChangeWatchedFiles()~n"+message.J.Prettify() )
	End Method

End Type

