SuperStrict

'   Blitzmax Language Server / Application
'   (c) Copyright Si Dunford, JAN 2023, All Rights Reserved. 
'   VERSION: 1.0

Import bmx.observer

'Import "jtypes.bmx"
'Import "lsp_types.bmx"
Import "messages.bmx"
Import "trace.bmx"
Import "textdocuments.bmx"			' Document manager
Import "workspace.bmx"				' Workspace Manager
Import "client.bmx"

Type Application Implements IObserver

	'Global instance:Application
	
	Field AppVersion:String = ""
	Field systemstate:ESYSTEMSTATE = ESYSTEMSTATE.NONE	'0
	
	'Field mutex:TMutex = CreateMutex()
	
	Field documents:TTextDocumentManager		' Document Manager
	Field workspace:TWorkspaceManager			' Workspace Manager
	' 
	Field hasConfigurationCapability:Int = False
	'Field workspace_root:String
	
	Method New( version:String )
		AppVersion = version
		documents = New TTextDocumentManager()
		workspace = New TWorkspaceManager()
		
		' Listen for events
		Observer.on( EV_SYSTEM_STATE, Self )

		' Register as default handler
		TMessage.register( "*", Self )
		' Register to receive messages of a specific type
		TMessage.register( "$", Self )			' For example $ for $/<message>
	End Method
	
	Method Observe( id:Int, data:Object )
		Select id
		Case EV_SYSTEM_STATE
			'LockMutex( mutex )
			systemState = ESYSTEMSTATE(Int[](data)[0])	' Unbox the integer
			'UnlockMutex( mutex )
			trace.debug( "Application received system state change: "+systemState.toString() )
		End Select
	End Method

	' EXAMPLE MESSAGE HANDLERS ===================================
	
	' CLIENT REQUEST and NOTIFICATION HAVE ONE ARGUMENT
'	Method on_dummy_message( request:TMessage )
'		Trace.debug( "DUMMY MESSAGE RECEIVED" )
'		Local JText:String = "{'result':'Working'}".Replace("'",Chr(34))
'		'Local result:String = "{'id':'"+data.id+"','result':'Working'}".Replace("'",Chr(34))
'		DebugStop
'		Local result:JSON = JSON.parse( JText )
'		'Return result
'		
'		' No response required from a notification
'		' An error or reply is required from a request
'		' request.error( ERROCODES.whatever, "Some error occurred" )
'		' request.reply( result )
'	End Method
'
'	' SERVER REQUESTS HAVE TWO ARGUMENTS
'	' You receive it here when the reply returns and this is the second argument
'	Method on_server_request( request:TMessage, response:JSON )
'		Trace.debug( "DUMMY SERVER REQUEST" )
'
'		' No response required from a server request
'	End Method

	' MESSAGE HANDLERS ===========================================

'	Method on_message( message:TMessage )				' DEFAULT HANDLER
'		Trace.debug( "Application default handler called for "+message.name )
'	End Method

	' ============================================================
	
	Method on_dollar_settrace( message:TMessage )		' NOTIFICATION
		Trace.debug( "APPLICATION: on_dollar_settrace()" )
		If Not message Or Not message.request; Return
		Local value:String = message.request.find("params|value").toString()
		Client.setTrace( value )
	End Method

	' ============================================================
	
	Method on_initialize( message:TMessage )			' REQUEST
		'Local state:ESYSTEMSTATE = systemstate
		
		Trace.debug( "RECEIVED: initialize" )
		'Trace.debug( "on_initialize(), state="+state )
				
		' Only one INITIALISE message is allowed
		If systemstate <> ESYSTEMSTATE.INITIALIZING
			message.error( ERRORCODES.InvalidRequest, "initialise already received" )
			Return
		End If
		
		' Extract the request parameters
		Local params:JSON = message.request.find("params")
		Trace.debug( params.stringify() )
		
		' Extract client capabilities
		'Local J:JSON = params.find("capabilities")
		'Local capabilities:TClientCapabilities = TClientCapabilities( J.Transpose( "TClientCapabilities" ) )
		If Not client.setCapabilities( params.find("capabilities") )
			Trace.error( "Unable to extract client capabilities" )
			Return
		End If

		'If capabilities.workspace; hasConfigurationCapability = capabilities.workspace.configuration	
	
		'Local workspace_root:String
		workspace.root = params.find("rootPath").tostring()
		
		' Get initial trace value
		Client.setTrace( params.find("trace").tostring() )
		Trace.debug( "INITIAL TRACE VALUE: "+ Client.getTrace() )
		
		' Create a result
		Local result:JSON = New JSON()
		result["serverInfo|name"] = AppTitle
		result["serverInfo|version"] = AppVersion
	
		' Workspace capabilities
		'If client.has( "workspace|workspaceFolders" )
		'	result["capabilities|workspace|workspaceFolders|supported"] = New JSON( JSON_BOOLEAN, True )
		'End If
		'result["capabilities|positionEncoding"] = "utf-16"			' 3.17, PositionEncodingKind, V3.17
		
		' DEBUG - TURN OFF DOCUMENT SYNC
		'result["capabilities|textDocumentSync"] = New JSON( JSON_NUMBER, ETextDocumentSyncKind.NONE.ordinal() )
		' END DEBUG
		result["capabilities|textDocumentSync"] = New JSON( JNUMBER, documents.syncKind.ordinal() )
			' TextDocumentSyncOptions | TextDocumentSyncKind
		
		'result["capabilities|notebookDocumentSync"] = 				' 3.17, NotebookDocumentSyncOptions | NotebookDocumentSyncRegistrationOptions
		'result["capabilities|completionProvider"] = 				':CompletionOptions
		'result["capabilities|hoverProvider"] = 					' boolean | HoverOptions
		'result["capabilities|signatureHelpProvider"] = 			' SignatureHelpOptions
		'result["capabilities|declarationProvider"] = 				' boolean | DeclarationOptions | DeclarationRegistrationOptions
		'result["capabilities|definitionProvider"] = 				' boolean | DefinitionOptions
		'result["capabilities|typeDefinitionProvider"] = 			' boolean | TypeDefinitionOptions | TypeDefinitionRegistrationOptions
		'result["capabilities|implementationProvider"] =			' boolean | ImplementationOptions | ImplementationRegistrationOptions
		'result["capabilities|referencesProvider"] =				' boolean | ReferenceOptions
		'result["capabilities|documentHighlightProvider"] =			' boolean | DocumentHighlightOptions
		'result["capabilities|documentSymbolProvider"] =			' boolean | DocumentSymbolOptions
		'result["capabilities|codeActionProvider"] =				' boolean | CodeActionOptions
		'result["capabilities|codeLensProvider"] =					' CodeLensOptions
		'result["capabilities|documentLinkProvider"] =				' DocumentLinkOptions
		'result["capabilities|colorProvider"] =						' boolean | DocumentColorOptions | DocumentColorRegistrationOptions
		'result["capabilities|documentFormattingProvider"] =		' boolean | DocumentFormattingOptions
		'result["capabilities|documentRangeFormattingProvider"] =	' boolean | DocumentRangeFormattingOptions
		'result["capabilities|documentOnTypeFormattingProvider"] =	' DocumentOnTypeFormattingOptions
		'result["capabilities|renameProvider"] =					' boolean | RenameOptions
		'result["capabilities|foldingRangeProvider"] =				' boolean | FoldingRangeOptions | FoldingRangeRegistrationOptions
		'result["capabilities|executeCommandProvider"] =			' ExecuteCommandOptions
		'result["capabilities|selectionRangeProvider"] =			' boolean | SelectionRangeOptions | SelectionRangeRegistrationOptions
		'result["capabilities|linkedEditingRangeProvider"] =		' boolean | LinkedEditingRangeOptions | LinkedEditingRangeRegistrationOptions
		'result["capabilities|callHierarchyProvider"] =				' boolean | CallHierarchyOptions | CallHierarchyRegistrationOptions
		'result["capabilities|semanticTokensProvider"] =			' SemanticTokensOptions | SemanticTokensRegistrationOptions
		'result["capabilities|monikerProvider"] =					' boolean | MonikerOptions | MonikerRegistrationOptions
		'result["capabilities|typeHierarchyProvider"] =				' boolean | TypeHierarchyOptions | TypeHierarchyRegistrationOptions
		'result["capabilities|inlineValueProvider"] =				' boolean | InlineValueOptions | InlineValueRegistrationOptions
		'result["capabilities|inlayHintProvider"] =					' boolean | InlayHintOptions | InlayHintRegistrationOptions
		'result["capabilities|diagnosticProvider"] =				' DiagnosticOptions | DiagnosticRegistrationOptions
		'result["capabilities|workspaceSymbolProvider"] =			' boolean | WorkspaceSymbolOptions
		'Local fileFilters:JSON = New JSON( ["**/*.bmx"] )
		'result["capabilities|workspace|fileOperations|didCreate|filters"] = fileFilters
		'result["capabilities|workspace|fileOperations|willCreate|filters"] = fileFilters
		'result["capabilities|workspace|fileOperations|didRename|filters"] = fileFilters
		'result["capabilities|workspace|fileOperations|willRename|filters"] = fileFilters
		'result["capabilities|workspace|fileOperations|didDelete|filters"] = fileFilters
		
		'result["capabilities|workspace|fileOperations|willDelete|filters"] = fileFilters
		'result["capabilities|experimental"] =	
		
		' Respond to the "initialise" request
		'Local response:JSON = New JResponse_OK()
		'response["result"] = result
		message.reply( result )
		'message.reply( New JSON() )

		' Update system state
		Observer.post( EV_SYSTEM_STATE, [ESYSTEMSTATE.INITIALIZED.ordinal()] )
	End Method

	' ============================================================

	Method on_initialized( message:TMessage )			' NOTIFICATION
		Trace.debug( "RECEIVED: initialized" )
		'
		' Only one INITIALISE message is allowed
		If systemstate <> ESYSTEMSTATE.INITIALIZED
			message.error( ERRORCODES.InvalidRequest, "initialise already received" )
			Return
		End If

		' Create a list of registrations
		Local registrations:TList = New TList
			
		' 20 JAN 2023
		' Blitzmax client extension does not support workDoneProgress so this has not been tested
		'If client.has("window|workDoneProgress")
		'End If
		
		If client.has("workspace|configuration")
			Trace.debug( "CLIENT SUPPORTS: workspace/didChangeConfiguration" )
			registrations.addlast( New JRegistration( "workspace/didChangeConfiguration" ) )
		End If
		
		If client.has("workspace|didChangeWatchedFiles|dynamicRegistration")
			Trace.debug( "CLIENT SUPPORTS: workspace/didChangeWatchedFiles" )

Trace.ERROR( "THIS DOES Not SEEM To BE WORKING, Application.on_initialised()" )
			
			Local watchers:JSON = New JSON( JARRAY )
			Local pattern:JSON = New JSON()
			pattern["globPattern"] = "**/*.bmx"	'"**/*.{bmx,max}"
			watchers.addLast( pattern )
			registrations.addlast( New JRegistration( "workspace/didChangeWatchedFiles", watchers ) )
		End If
		
		'	registrations.addlast( New JRegistration( "workspace/didChangeConfiguration" ))

		'If client.has("workspace|configuration")
		'	registrations.addlast( New JRegistration( "workspace/didChangeConfiguration" ) )
		'End If
		'If client.has("workspace|didChangeWatchedFiles")
		'	registrations.addlast( New JRegistration( "workspace/didChangeConfiguration" ) )
		'End If
		
		'If hasWorkspaceFolderCapability
		''connection.workspace.onDidChangeWorkspaceFolders(_event => {
		'  connection.console.Log('Workspace folder change event received.');
		'});
		'End If
		
		' Do we have some registrations to send to client
		If Not registrations.isEmpty()

			'Local params:JSON = New JSON()
			'params["registrations"] = []
			
			Local list:JSON = New JSON( JARRAY )
			
			For Local registration:JSON = EachIn registrations
				list.addlast( registration )
				'params["registrations"].addlast( registration )
			Next
			
			Local params:JSON = New JSON()
			params.set( "registrations", list )
			
			Local request:JSON = New JRequest( "client/registerCapability", params )
			Client.send( request )
		End If

		' Update system state
		Observer.post( EV_SYSTEM_STATE, [ESYSTEMSTATE.READY.ordinal()] )
		
		' NOTIFICATION / No response necessary
	End Method

	' ============================================================
	
	Method on_shutdown( message:TMessage )				' REQUEST
		Trace.debug( "RECEIVED: shutdown" )

		' Update system state
		Observer.post( EV_SYSTEM_STATE, [ESYSTEMSTATE.SHUTDOWN.ordinal()] )

		message.reply()		' NULL response expected
	End Method

	' ============================================================
	
	Method on_exit( message:TMessage )					' NOTIFICATION
	
		Rem
		A notification to ask the server to exit its process. 
		The server should exit with success code 0 if the shutdown request has been received before
		otherwise with error code 1.
		End Rem
		
		Trace.debug( "RECEIVED: exit" )
		If systemstate = ESYSTEMSTATE.SHUTDOWN; exit_(0)
		exit_(1)
	End Method
	
	' ============================================================
	
'	Method on_window_showMessage( message:TMessage )	' RESPONSE
'		Rem
'		This is a resposne To our request, so nothing further To do
'		End Rem
'		Trace.debug( "on_window_showmessage / RESPONSE" )
'	End Method
	
Rem
connection.onDidChangeWatchedFiles(_change => {
  // Monitored files have change in VS Code
  connection.console.Log('We received a file change event');
});

Function getDocumentSettings(resource: String): Thenable<ExampleSettings> {
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
  Return result;
}

connection.onDidChangeConfiguration(change => {
  If (hasConfigurationCapability) {
    // Reset all cached document settings
    documentSettings.clear();
  } Else {
    globalSettings = <ExampleSettings>(
      (change.settings.languageServerExample || defaultSettings)
    );
  }

  // Revalidate all open Text documents
  documents.all().forEach(validateTextDocument);
});	

connection.onDidChangeConfiguration(change => {
  If (hasConfigurationCapability) {
    // Reset all cached document settings
    documentSettings.clear();
  } Else {
    globalSettings = <ExampleSettings>(
      (change.settings.languageServerExample || defaultSettings)
    );
  }

  // Revalidate all open Text documents
  documents.all().forEach(validateTextDocument);
});
EndRem
End Type


