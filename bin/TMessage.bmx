
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

' MESSAGE V0.3
Type TMessage Extends TEvent

	Field J:JSON		' Original Message

	Field methd:String	' Will be RECEIVED-FROM-CLIENT until message queue updates it
						' Or SEND-TO-CLIENT until message queue sends it.
	Field params:JSON	' Empty until processed by message queue
'	Field msgid:Int		' Message ID

    Field state:Int = STATE_WAITING		' State of the message
    Field cancelled:Int = False         ' Message cancellation
	
	Method New( methd:String, payload:JSON, params:JSON=Null )
		Self.methd = methd
		Self.extra = payload
		Self.source = Self
		Self.params = params
		
		' Extract ID (if there is one)
'		Local idnode:JSON = payload.find( "id" )
'		If idnode ; msgid=idnode.toint()
		
		'Publish( "log", "DBG", "** TMSG: '"+methd+"'" )
		Select methd
		
		Case "SEND-TO-CLIENT" 		; id = EV_sendToClient
		Case "RECEIVE-FROM-CLIENT" 	; id = EV_receivedFromClient
		
		Case "initialize" 			; id = EV_initialize
		Case "initialized" 			; id = EV_initialized
		Case "shutdown" 			; id = EV_shutdown
		Case "exit" 				; id = EV_exit
		
'		Case "onDidChangeContent" 	; id = EV_DidChangeContent
'		Case "onDidChangeContent" 	; id = EV_DidChangeContent
		Case "textDocument/didOpen" ; id = EV_DidOpen
'		Case "onWillSave" 			; id = EV_WillSave
'		Case "onWillSaveWaitUntil"	; id = EV_WillSaveWaitUntil
'		Case "onDidSave" 			; id = EV_DidSave
'		Case "onDidClose" 			; id = EV_DidClose	
		'case "$/setTraceNotification"	;	id = EV_setTraceNotification
		'Case "NEXTONE" 		; id = NEXTONE
		Default
			Publish( "log", "DBG", "** TMSG: UNHANDLED EVENT '"+methd+"'" )
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
	
End Type