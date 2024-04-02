
'   LANGUAGE SERVER MESSAGE HANDLER
'   (c) Copyright Si Dunford, October 2021, All Right Reserved
'   
'   https://microsoft.github.io/language-server-protocol/specifications/specification-current/#completionItem_resolve
'   REQUEST:    completionItem/resolve
'
'   Provide additional information for item selected in the completion list

Rem EXAMPLE
{
  "id": 5,
  "jsonrpc": "2.0",
  "method": "completionItem/resolve",
  "params": {
    "data": 1,
    "insertTextFormat": 1,
    "kind": 1,
    "label": "Scaremonger"
  }
}
End Rem

Function bls_completionItem_resolve:JSON( message:TMessage )
    logfile.debug( "bls_completionItem_resolve() - TEST CODE~n"+message.J.stringify() )
    logfile.info( "~n"+message.j.Prettify() )
	
    Local id:String = message.getid()
    Local params:JSON = message.params
	
	Local data:Int = params.find("data").toint()
	Local inserttextformat:Int = params.find("insertTextFormat").toint()
	Local kind:Int = params.find("kind").toint()
	Local label:String = params.find("label").toString()

	' Generate response
	Local response:JSON = Response_OK()
	Local items:JSON = New JSON( JARRAY )
	Local item:JSON
	'response.set( "id", message.MsgID )
	'response.set( "jsonrpc", JSONRPC )
	response.set( "result|items", items )

	' HERE WE SHOULD LOOK UP THE COMPLETION ITEM USING INDEX OF "data"
	
	If data=1	' SCAREMONGER
			
		item = New JSON()
		item.set( "detail", "Scaremonger details" )
		item.set( "documentation", "He is a very tall geek" )
		items.addlast( item )

	ElseIf data=2	' BLITZMAX

		item = New JSON()
		item.set( "detail", "Blitzmax detail" )
		item.set( "documentation", "Blitzmax documentation" )
		items.addlast( item )

	End If
	
	' Reply to the client
	Return( response )  

End Function
