SuperStrict

'	Language Server Protocol Classes
'	Based on V3.17 Specification at: 
'
'	https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/

Import bmx.json
'Include "version.bmx"

Enum ETextDocumentSyncKind ; NONE = 0 ; FULL = 1 ; INCREMENTAL = 2 ; EndEnum

Type ERRORCODES
	Const ParseError:Int			= -32700
	Const InvalidRequest:Int		= -32600
	Const MethodNotFound:Int		= -32601
	Const InvalidParams:Int			= -32602
	Const InternalError:Int			= -32603
	
	Const ServerNotInitialized:Int	= -32002
	Const UnknownErrorCode:Int		= -32001

	Const ContentModified:Int		= -32801
	Const RequestCancelled:Int		= -32800

	' @since 3.17.0
	Const RequestFailed:Int			= -32803
	Const ServerCancelled:Int		= -32802
End Type

' Message types used in window/showMessage
Type MESSAGETYPE
	Const Error:Int = 1		' An error message.
	Const Warning:Int = 2	' A warning message.
	Const Info:Int = 3		' An information message.
	Const Log:Int = 4	' A Log message.
End Type

Rem
Type TClientCapabilities
	Field workspace:TClientCapabilities_workspace
	Field textDocument:JSON				' TextDocumentClientCapabilities
	Field notebookDocument:JSON			' NotebookDocumentClientCapabilities
	Field window:JSON
	Field general:JSON
	Field experimental:JSON				' LSPAny
End Type

Type TClientCapabilities_workspace
	Field applyEdit:Int
	Field workspaceEdit:JSON			' WorkspaceEditClientCapabilities
	Field didChangeConfiguration:JSON	' DidChangeConfigurationClientCapabilities
	Field didChangeWatchedFiles:JSON	' DidChangeWatchedFilesClientCapabilities
	Field symbol:JSON					' WorkspaceSymbolClientCapabilities
	Field executeCommand:JSON			' ExecuteCommandClientCapabilities
	Field workspaceFolders:Int
	Field configuration:Int				' ? Client supports configuration capabilities
	Field semanticTokens:JSON			' SemanticTokensWorkspaceClientCapabilities
	Field codeLens:JSON					' CodeLensWorkspaceClientCapabilities
	Field fileOperations: JSON
	Field inlineValue:JSON				' InlineValueWorkspaceClientCapabilities
	Field inlayHint:JSON				' InlayHintWorkspaceClientCapabilities
	Field diagnostics:JSON				' DiagnosticWorkspaceClientCapabilities
End Type
End Rem

Rem
Type T_initialize
	Field id:Int
	Field jsonrpc:String
	Field methd:String		{serialisedname="method"}
	Field params:TInitializeParams
End Type

Type TInitializeParams
	Field processId: Int
	Field clientInfo: TInitializeParams_clientInfo
	Field locale: String
	Field rootPath: String					'# DEPRECIATED - See rootUri
	Field rootUri: String					'# DEPRECIATED - See workspaceFolders
'	Field initializationOptions: JSON		'LSPAny
	Field capabilities:TClientCapabilities
	Field trace: String
	Field workspaceFolders:TWorkspaceFolder[]
End Type

Type TInitializeParams_clientInfo
	Field name: String
	Field version:String
End Type

' Result returned from initialize" message
Type TInitializeResult
	Field capabilities:TServerCapabilities
	Field serverInfo:TInitializeResult_serverInfo
	
	Method New()
		capabilities = New TServerCapabilities()
		serverInfo = New TInitializeResult_serverInfo()
	End Method
End Type

Type TInitializeResult_serverInfo
	Field name: String   = AppTitle
	Field version:String = appvermax+"."+appvermin+"."+appbuild
End Type



Type TServerCapabilities
'	Field positionEncoding:String = "utf-16"			' 3.17, PositionEncodingKind, V3.17
	Field textDocumentSync:JSON							' TextDocumentSyncOptions | TextDocumentSyncKind
'	Field notebookDocumentSync:JSON						' 3.17, NotebookDocumentSyncOptions | NotebookDocumentSyncRegistrationOptions
	Field completionProvider:CompletionOptions
'	Field hoverProvider:JSON							' boolean | HoverOptions
'	Field signatureHelpProvider:JSON					' SignatureHelpOptions
'	Field declarationProvider:JSON						' boolean | DeclarationOptions | DeclarationRegistrationOptions
'	Field definitionProvider:JSON						' boolean | DefinitionOptions
'	Field typeDefinitionProvider:JSON					' boolean | TypeDefinitionOptions | TypeDefinitionRegistrationOptions
'	Field implementationProvider:JSON					' boolean | ImplementationOptions | ImplementationRegistrationOptions
'	Field referencesProvider:JSON						' boolean | ReferenceOptions
'	Field documentHighlightProvider:JSON				' boolean | DocumentHighlightOptions
'	Field documentSymbolProvider:JSON					' boolean | DocumentSymbolOptions
'	Field codeActionProvider:JSON						' boolean | CodeActionOptions
'	Field codeLensProvider:JSON							' CodeLensOptions
'	Field documentLinkProvider:JSON						' DocumentLinkOptions
'	Field colorProvider:JSON							' boolean | DocumentColorOptions | DocumentColorRegistrationOptions
'	Field documentFormattingProvider:JSON				' boolean | DocumentFormattingOptions
'	Field documentRangeFormattingProvider:JSON			' boolean | DocumentRangeFormattingOptions
'	Field documentOnTypeFormattingProvider:JSON			' DocumentOnTypeFormattingOptions
'	Field renameProvider:JSON							' boolean | RenameOptions
'	Field foldingRangeProvider:JSON						' boolean | FoldingRangeOptions | FoldingRangeRegistrationOptions
'	Field executeCommandProvider:JSON					' ExecuteCommandOptions
'	Field selectionRangeProvider:JSON					' boolean | SelectionRangeOptions | SelectionRangeRegistrationOptions
'	Field linkedEditingRangeProvider:JSON				' boolean | LinkedEditingRangeOptions | LinkedEditingRangeRegistrationOptions
'	Field callHierarchyProvider:JSON					' boolean | CallHierarchyOptions | CallHierarchyRegistrationOptions
'	Field semanticTokensProvider:JSON					' SemanticTokensOptions | SemanticTokensRegistrationOptions
'	Field monikerProvider:JSON							' boolean | MonikerOptions | MonikerRegistrationOptions
'	Field typeHierarchyProvider:JSON					' boolean | TypeHierarchyOptions | TypeHierarchyRegistrationOptions
'	Field inlineValueProvider:JSON						' boolean | InlineValueOptions | InlineValueRegistrationOptions
'	Field inlayHintProvider:JSON						' boolean | InlayHintOptions | InlayHintRegistrationOptions
'	Field diagnosticProvider:JSON						' DiagnosticOptions | DiagnosticRegistrationOptions
'	Field workspaceSymbolProvider:JSON					' boolean | WorkspaceSymbolOptions
'	Field workspace:TServerCapabilities_workspace
'	Field experimental:JSON								' LSPAny

	Method New()
		textDocumentSync = New JSON( JSON_NUMBER, ETextDocumentSyncKind.NONE.ordinal() )
		completionProvider = New CompletionOptions()
	End Method
	
End Type

'Type TServerCapabilities_workspace
'	Field workspaceFolders: TWorkspaceFoldersServerCapabilities
'	Field fileOperations: TServerCapabilities_workspace_fileoperations
'End Type

'Type TServerCapabilities_workspace_fileoperations
'	Field didCreate:JSON					' FileOperationRegistrationOptions
'	Field willCreate:JSON					' FileOperationRegistrationOptions
'	Field didRename:JSON					' FileOperationRegistrationOptions
'	Field willRename:JSON					' FileOperationRegistrationOptions
'	Field didDelete:JSON					' FileOperationRegistrationOptions
'	Field willDelete:JSON					' FileOperationRegistrationOptions
'End Type

Type TTextDocumentSyncOptions
	Field openClose:Int = True
	Field change:ETextDocumentSyncKind = ETextDocumentSyncKind.NONE
End Type

Type TWorkspaceFolder
	Field uri:String
	Field name:String
End Type

Type CompletionOptions 'Extends WorkDoneProgressOptions
	'Field triggerCharacters:String[]
	'Field allCommitCharacters:String[]						' @since 3.2.0
	Field resolveProvider:Int = True						' boolean
	'Field completionItem:CompletionOptions_completionItem
End Type

'Type CompletionOptions_completionItem
'	Field labelDetailsSupport:Int					' boolean, @since 3.17.0
'End Type

ENDREM