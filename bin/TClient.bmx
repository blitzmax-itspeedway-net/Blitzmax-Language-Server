
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

Global client:TClient = New TClient()

Type TClient Extends TMessageQueue
	Field capabilities:JSON = New JSON()
	Field documentSettings:JSON = New JSON()
	Field initialized:Int = False
	
	Method New()
		listen()
	End Method
	
	Method Close()
		unlisten()
	End Method
	
	Method getDocumentSettings( resource:String )
	': Thenable<ExampleSettings> 

Rem
		If (!hasConfigurationCapability) {
			Return Promise.resolve(globalSettings);
		}
		let result = documentSettings.get(resource);
		If (!result) {
			result = connection.workspace.getConfiguration({
			scopeUri: resource,
			section: 'languageServerExample'
		});
		documentSettings.set(resource, result);
		}
End Rem
		'Return result;
	End Method
	
	' Check if Client has a particular capability (Only works with Boolean types)
	Method has:Int( capability:String )
		Local J:JSON = capabilities.find( capability )
		If Not J Return False
		Return ( J.tostring() = "true" )
	End Method
	
	' HELPER: Send a message to client
	Method Send( message:JSON )
		New TMessage( "SEND-TO-CLIENT", message ).emit()		' Send message to client
	End Method
	
	' EVENT HANDLERS

	Method onInitialize:Int( message:TMessage )
		publish( "log", "DBG", "TClient.onInitialize()" )
		initialized = True
		Local id:String = message.getid()
		Local params:JSON = message.params
		
		' Extract Client Capabilities
		capabilities = params.find( "capabilities" )
		publish( "log", "DBG", "CLIENT CAPABILITIES~n"+capabilities.prettyprint() )
		
        ' Write Client information to logfile
        If params
            'logfile.write( "PARAMS EXIST" )
            'if params.isvalid() logfile.write( "PARAMS IS VALID" )
            Local clientinfo:JSON = params.find( "clientInfo" )    ' VSCODE=clientInfo
            If clientinfo
                'logfile.write( "CLIENT INFO EXISTS" )
                Local clientname:String = clientinfo["name"]
                Local clientver:String = clientinfo["version"]
                Publish "CLIENT: "+clientname+", "+clientver
            'else
                'logfile.write( "NO CLIENT INFO EXISTS" )
            End If
        End If

        ' RESPONSE 

		'V0.2, Capabilities are managed by the LSP
		'Local cap:JSON = lsp.capabilities

Publish( "log", "DEBG", "Initialize:Capabilities: "+lsp.capabilities.stringify() )
        Local response:JSON = New JSON()
        response.set( "id", id )
        response.set( "jsonrpc", JSONRPC )
        'response.set( "result|capabilities", [["hover","true"]] )
        'response.set( "result|capabilities", [["hoverProvider","true"]] )

        response.set( "result|capabilities", lsp.capabilities )

        response.set( "result|serverinfo", [["name","~q"+AppTitle+"~q"],["version","~q"+version+"."+build+"~q"]] )
Publish( "log", "DEBG", "RESULT: "+response.stringify() )

		send( response )
		'
		message.state = STATE_COMPLETE
		
		' Register for Configuration updates (If supported by client)
		If has( "workspace|configuration" )
			Publish( "log", "DGB", "-> Client supports workspace configuration" )
'			response = New JSON()
'			response.set( "jsonrpc", JSONRPC )
'			response.set( "error", [["code",code],["message","~q"+message+"~q"]] )
'			send( response )
		End If
		
        Return False

	End Method

	Method onDidChangeConfiguration:Int( message:TMessage )
		publish( "log", "DBG", "TClient.onDidChangeConfiguration()" )
	End Method
End Type