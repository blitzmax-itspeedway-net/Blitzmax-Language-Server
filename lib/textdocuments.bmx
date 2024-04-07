SuperStrict

'   NAME
'   (c) Copyright Si Dunford, MMM 2022, All Rights Reserved. 
'   VERSION: 1.0

'   CHANGES:
'   DD MMM YYYY  Initial Creation
'

Import bmx.observer

Import "client.bmx"
Import "lsp_types.bmx"
Import "messages.bmx"

' DOCUMENT MANAGER
Type TTextDocumentManager 'Implements IObserver

	Field syncKind:ETextDocumentSyncKind = ETextDocumentSyncKind.INCREMENTAL
	
	Method New()
		' Register to receive textDocument messages
		TMessage.register( "textDocument", Self )
	End Method
	
	'Method listen( connection:IConnection )
	'End Method
	
'	Method Observe( id:Int, data:Object )
'		'Select id
'		'Case MSG_TEXTDOCUMENT_DIDOPEN
'		'Case MSG_TEXTDOCUMENT_DIDCHANGE
'		'End Select
'	End Method
	
	' ============================================================

'	Method on_message( message:TMessage )				' DEFAULT HANDLER
'		Trace.debug( "TextDocument default handler called for "+message.name )
'	End Method

	' ============================================================
	
	Method on_textDocument_didOpen( message:TMessage )	' NOTIFICATION	
		Trace.error( "on_textDocument_didOpen() - NOT IMPLEMENTED" )
		Client.Log( "thanks, opening file..." )
	End Method

	Method on_textDocument_didChange( message:TMessage )	' NOTIFICATION	
		Trace.error( "on_textDocument_didChange() - NOT IMPLEMENTED" )
	End Method

	Method on_textDocument_didClose( message:TMessage )	' NOTIFICATION	
		Trace.error( "on_textDocument_didClose() - NOT IMPLEMENTED" )
	End Method

	Method on_textDocument_didSave( message:TMessage )	' NOTIFICATION	
		Trace.error( "on_textDocument_didSave() - NOT IMPLEMENTED" )
	End Method	
End Type


