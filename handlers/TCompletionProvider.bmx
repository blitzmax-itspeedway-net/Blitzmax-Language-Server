
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	completionProvider (NOT IMPLEMENTED)

Type TCompletionProvider Extends TMessageHandler

	Method New()
		' Register Capabilities
		lsp.addCapability( Self, ["completionProvider","{~qresolveProvider~q:true}"] )
		lsp.'addHandlers( Self, [] )
	End Method
	
	'Method Notify( message:String, data:Object, extra:Object )
	'End Method
	
	'Method Signal:Int( event:String, data:Object, extra:Object )
	'End Method
	
	' Called by Worker thread to process a message
	Method run:String( message:TMessage )
		'Publish( "info", "TCompletionProvider received "+message.methd )
		'Select message.methd
		'End Select
		'Return ""
	End Method

End Type