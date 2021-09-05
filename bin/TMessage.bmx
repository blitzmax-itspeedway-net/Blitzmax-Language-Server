
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

' EVENT TYPES
Global EV_UNKNOWN:Int = AllocUserEventId( "UNKNOWN" )

Global EV_receivedFromClient:Int = AllocUserEventId( "ReceivedFromClient" )
Global EV_sendToClient:Int = AllocUserEventId( "SendToClient" )

Global EV_initialize:Int = AllocUserEventId( "initialize" )
Global EV_initialized:Int = AllocUserEventId( "initialized" )
Global EV_shutdown:Int = AllocUserEventId( "shutdown" )
Global EV_exit:Int = AllocUserEventId( "exit" )

Global EV_CancelRequest:Int = AllocUserEventId( "$/cancelRequest" )
Global EV_SetTraceNotification:Int = AllocUserEventId( "$/setTraceNotification" )

Global EV_DidChangeConfiguration:Int = AllocUserEventId( "didChangeConfiguration" )

' TEXTDOCUMENT
Global EV_DidChange:Int = AllocUserEventId( "textDocument/didChange" )
Global EV_DidOpen:Int = AllocUserEventId( "textDocument/didOpen" )
Global EV_WillSave:Int = AllocUserEventId( "textDocument/willSave" )
Global EV_WillSaveWaitUntil:Int = AllocUserEventId( "textDocument/willSaveWaitUntil" )
Global EV_DidSave:Int = AllocUserEventId( "textDocument/didSave" )
Global EV_DidClose:Int = AllocUserEventId( "textDocument/didClose" )
Global EV_Definition:Int = AllocUserEventId( "textDocument/definition" )

' MESSAGE V0.3
Type TMessage Extends TEvent

	Field J:JSON		' Original Message

	Field MsgID:String	' Original message ID
	Field methd:String
	Field params:JSON	' Empty until processed by message queue
	'Field taskid:int	' Message ID

    Field state:Int = STATE_WAITING		' State of the message
    Field cancelled:Int = False         ' Message cancellation
	
	Method New( methd:String, payload:JSON, params:JSON=Null )
		' TMessage values
		Self.methd = methd
		Self.J = payload
		Self.params = params
		' TEvent values
		Self.extra = payload
		Self.source = Self
		
		' Extract ID (if there is one) - Used in the task queue
		Local JID:JSON = payload.find( "id" )
		If JID ; MsgID = JID.toString()
		
		'Publish( "log", "DBG", "** TMSG: '"+methd+"'" )
		Select methd
		
		Case "SEND-TO-CLIENT" 					; id = EV_sendToClient
		Case "RECEIVE-FROM-CLIENT" 				; id = EV_receivedFromClient
		
		Case "initialize" 						; id = EV_initialize
		Case "initialized" 						; id = EV_initialized
		Case "shutdown" 						; id = EV_shutdown
		Case "exit" 							; id = EV_exit
		
		Case "textDocument/didChange" 			; id = EV_DidChange
		Case "textDocument/didOpen" 			; id = EV_DidOpen
		Case "textDocument/willSave" 			; id = EV_WillSave
		Case "textDocument/willSaveWaitUntil"	; id = EV_WillSaveWaitUntil
		Case "textDocument/didSave" 			; id = EV_DidSave
		Case "textDocument/didClose" 			; id = EV_DidClose	
		Case "textDocument/definition"			; id = EV_Definition
		
		Case "$/cancelRequest"					; id = EV_cancelRequest
		Case "$/setTraceNotification"			; id = EV_setTraceNotification
		
		'Case "NEXTONE" 		; id = NEXTONE
		Default
			Publish( "log", "DBG", "** TMessage: UNKNOWN EVENT '"+methd+"'" )
			id = EV_UNKNOWN
		End Select
		'Publish( "log", "DBG", "** TMSG: '"+methd+"' ("+id+")" )		
	End Method
	
	' Quick-n-dirty method to extract the message ID (If there is one)
	Method getid:String()
		If Not extra Return "null"
		Local J:JSON = JSON(extra).find("id")
		If Not J Return "null"
		Return J.toString()
	End Method

	' Override Emit(), so that we can deal with unhandled events
	' data should be NULL if event has been handled.
	Method Emit()
		Local data:Object = RunHooks( EmitEventHook, Self )		
		If data
			logfile.debug( "## TMessage.emit() - UNHANDLED EVENT: "+methd )
			' Identify unhandled requests so that we can send an error back to the client
			If J.contains("id")
				Local JID:JSON = J.find("id")
				If JID
					Local id:String = JID.tostring()
					Local response:JSON
					client.send( Response_Error( ERR_INTERNAL_ERROR, "Method handler missing", id ) )
				EndIf
			End If
		End If
		' Set task as complete
		state = STATE_COMPLETE
	End Method
End Type