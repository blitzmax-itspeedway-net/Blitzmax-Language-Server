
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

Include "TMethod_exit.bmx"
Include "TMethod_initialize.bmx"
Include "TMethod_initialized.bmx"
Include "TMethod_shutdown.bmx"
Include "TMethod_dollar_cancelrequest.bmx"

Include "TTextDocument.bmx"

Const STATE_WAITING:Int = 0
Const STATE_RUNNING:Int = 1
Const STATE_COMPLETE:Int = 2
'const STATE_CANCELLED:int = 3

' BASIC REQUEST TYPE
Type TMessage
    Field state:Int = STATE_WAITING    ' State of the message
    Field cancelled:Int = False         ' Message cancellation
    Field J:JNode                       ' Original JNode message
    Field id:Int

	' V0.2
	Field methd:String					' Original "method" from message
	Method New( methd:String, J:JNode )
		Self.methd = methd
		Self.J = J
		' Extract ID (if there is one)
		Local idnode:JNode = J.find( "id" )
		If idnode id=idnode.toint()
	End Method

	' V0.0
    Method Run:String()     ' V0.2, changed from Abstract to Ancestor
		'V0.2 
		' Get the message handler
		Local handler:TMessageHandler = lsp.getMessageHandler( methd )
		If Not handler Return Response_Error( ERR_METHOD_NOT_FOUND, "Method is not available", id )
		'
		Return handler.run( Self )
	End Method

    ' Identify if message contains a symbol
    Method contains:Int( path:String )
        'if J Publish( "log", "DEBG", J.Stringify() )
        If J And J.find( path ) Return True
        Return False
    End Method
End Type

' MESSAGE HANDLER V0.02
Type TMessageHandler Extends TObserver

	' Default handler will return "METHOD_NOT_FOUND"
	Method run:String( message:TMessage )
		'Local idnode:JNode = J.find("id")
		'If Not idnode Return	' Ignore notifications
		' Return an unknown method
		'Local id:String = idnode.tostring()
		Publish( "send", Response_Error( ERR_METHOD_NOT_FOUND, "Method is not available", message.id ))
	End Method
	
End Type
