	
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

' EVENT TYPES
' DEPRECIATED 25/10/21

'Global EV_UNKNOWN:Int = AllocUserEventId( "UNKNOWN" )

' INTERNAL IO
'Global EV_receivedFromClient:Int = AllocUserEventId( "ReceivedFromClient" )
'Global EV_sendToClient:Int = AllocUserEventId( "SendToClient" )

' DOLLAR
'Global EV_CancelRequest:Int = AllocUserEventId( "$/cancelRequest" )
'Global EV_SetTraceNotification:Int = AllocUserEventId( "$/setTraceNotification" )

' GENERAL MESSAGES
'Global EV_initialize:Int = AllocUserEventId( "initialize" )
'Global EV_initialized:Int = AllocUserEventId( "initialized" )
'Global EV_shutdown:Int = AllocUserEventId( "shutdown" )
'Global EV_exit:Int = AllocUserEventId( "exit" )
'Global EV_logTrace:Int = AllocUserEventId( "logTrace" )
'Global EV_setTrace:Int = AllocUserEventId( "setTrace" )

' WORKSPACE
'Global EV_workspace_workspaceFolders:Int = AllocUserEventId( "workspace/workspaceFolders" )
'Global EV_didChangeWorkspaceFolders:Int = AllocUserEventId( "didChangeWorkspaceFolders" )
'Global EV_didChangeWatchedFiles:Int = AllocUserEventId( "didChangeWatchedFiles" )
'Global EV_DidChangeConfiguration:Int = AllocUserEventId( "didChangeConfiguration" )

' TEXT SYNCHRONISATION
'Global EV_textDocument_didChange:Int = AllocUserEventId( "textDocument/didChange" )
'Global EV_textDocument_didOpen:Int = AllocUserEventId( "textDocument/didOpen" )
'Global EV_textDocument_willSave:Int = AllocUserEventId( "textDocument/willSave" )
'Global EV_textDocument_willSaveWaitUntil:Int = AllocUserEventId( "textDocument/willSaveWaitUntil" )
'Global EV_textDocument_didSave:Int = AllocUserEventId( "textDocument/didSave" )
'Global EV_textDocument_didClose:Int = AllocUserEventId( "textDocument/didClose" )

' LANGUAGE FEATURES
'Global EV_completionItem_resolve:Int = AllocUserEventId( "completionItem/resolve" )
'Global EV_textDocument_definition:Int = AllocUserEventId( "textDocument/definition" )
'Global EV_textDocument_completion:Int = AllocUserEventId( "textDocument/completion" )
'Global EV_textDocument_documentSymbol:Int = AllocUserEventId( "textDocument_documentSymbol/completion" )

' MESSAGE V4
Type TMessage 
	
	Private

	Field _id:String			' Original message "id"

	Public
	
	Field J:JSON				' Original Message

	Field methd:String			' Original message "method"
	Field params:JSON			' Original message "params"
	
	Field request:Int = False	' Request or notification
	'Field taskid:int			' Message ID

    'Field state:Int = STATE_WAITING		' State of the message
    Field cancelled:Int = False         ' Message cancellation	
	
	Method New( methd:String, payload:JSON )	', params:JSON=Null )
		' Arguments
		Self.methd = methd
		Self.J = payload
		
		' Extractions
		params = payload.find( "params" )
		
		' Extract ID (if there is one) 
		If payload.contains( "id" )
			request = True
			_id = payload.find( "id" ).toString()
		End If

	End Method
			
	' Getter!
	Method getid:String()
		Return _id
	End Method

	' Helper function for message distribution
	Method send()
		lsp.distribute( Self )
	End Method

End Type

		'Publish( "log", "DBG", "** TMSG: '"+methd+"'" )
		' DEPRECIATED 25/10/21
'		Select methd
		
		' MESSAGE IO
'		Case "SEND-TO-CLIENT" 					; id = EV_sendToClient
'		Case "RECEIVE-FROM-CLIENT" 				; id = EV_receivedFromClient
		
		' DOLLAR NOTIFICATIONS
'		Case "$/cancelRequest"					; id = EV_cancelRequest
'		Case "$/setTraceNotification"			; id = EV_setTraceNotification

		' GENERAL MESSAGES
'		Case "initialize" 						; id = EV_initialize
'		Case "initialized" 						; id = EV_initialized
'		Case "shutdown" 						; id = EV_shutdown
'		Case "exit" 							; id = EV_exit

		' WORKSPACE
'		Case "workspace/didChangeWorkspaceFolders"	; id = EV_didChangeWorkspaceFolders
'		Case "didChangeWatchedFiles"			; id = EV_didChangeWatchedFiles
'		Case "didChangeConfiguration"			; id = EV_DidChangeConfiguration
'		
'		Case "workspace/workspaceFolders"		; id = EV_workspace_workspaceFolders


		' TEXT SYNCHRONISATION
'		Case "textDocument/didChange" 			; id = EV_textDocument_didChange
'		Case "textDocument/didOpen" 			; id = EV_textDocument_didOpen
'		Case "textDocument/willSave" 			; id = EV_textDocument_willSave
'		Case "textDocument/willSaveWaitUntil"	; id = EV_textDocument_willSaveWaitUntil
'		Case "textDocument/didSave" 			; id = EV_textDocument_didSave
'		Case "textDocument/didClose" 			; id = EV_textDocument_didClose	
		
		' LANGUAGE FEATURES
'		Case "completionItem/resolve"			; id = EV_completionItem_resolve
'		Case "textDocument/completion"			; id = EV_textDocument_completion
'		Case "textDocument/definition"			; id = EV_textDocument_definition
'		Case "textDocument/documentSymbol"		; id = EV_textDocument_documentSymbol
						
		'Case "NEXTONE" 		; id = NEXTONE
'		Default
'			'Publish( "log", "DBG", "** TMessage: UNKNOWN EVENT '"+methd+"'" )
'			logfile.debug( "** TMessage: UNKNOWN EVENT '"+methd+"'" )
'			id = EV_UNKNOWN
'		End Select
'		'Publish( "log", "DBG", "** TMSG: '"+methd+"' ("+id+")" )		

	
	' 
	
	' NOT USED AT THE MOMENT - BUT SHOULD BE!
	'Method reflect:TASTNode()
	'	Local this:TTypeId = TTypeId.ForObject( LSP )
		
	'	Local callable:String = Replace("on_"+methd,"-","")
		
	'	Local call:TMethod = this.FindMethod( callable )
'DebugStop
	'	If call 
	'		logfile.debug( "CALLING: "+callable+"()" )
	'		call.invoke( Self, [Self] )
	'	Else
	'		logfile.debug( "UNABLE TO CALL: "+callable+"()" )
	'	End If
	'End Method
	
	
	' Override Emit(), so that we can deal with unhandled events
	' data should be NULL if event has been handled.
	'Method Emit_OLD()
	'	Local data:Object = RunHooks( EmitEventHook, Self )		
	'	If data
	'		logfile.debug( "## TMessage.emit() - UNHANDLED EVENT: "+methd )
	'		' Identify unhandled requests so that we can send an error back to the client
	'		If J.contains("id")
	'			Local JID:JSON = J.find("id")
	'			If JID
	'				Local id:String = JID.tostring()
	'				Local response:JSON
	'				client.send( Response_Error( ERR_INTERNAL_ERROR, "Method handler missing", id ) )
	'			EndIf
	'		End If
	'	End If
	'	' Set task as complete
	'	state = STATE_COMPLETE
	'End Method
