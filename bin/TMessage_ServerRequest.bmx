
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	Server Request (Also contains Client response)

Type TServerRequest Extends TMessage

	Field ClientResponse:JSON

	Method New( payload:JSON )
		Super.New( payload )
		Self.name = "ServerRequest{"+methd+"/"+id+"/"+classname()+"}"
		Self.class = TMessage._RESPONSE
	End Method

	Method addResponse( response:JSON )
		ClientResponse = response
	End Method

	Method Launch()
		lsp.distribute( Self )
	End Method

End Type