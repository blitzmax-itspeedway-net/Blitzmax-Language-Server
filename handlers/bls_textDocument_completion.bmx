
'   LANGUAGE SERVER MESSAGE HANDLER
'   (c) Copyright Si Dunford, October 2021, All Right Reserved
'
'   https://microsoft.github.io/language-server-protocol/specifications/specification-current/#textDocument_completion
'   REQUEST:    textDocument/completion
'
'   Provide a list of completion items

Rem EXAMPLE
{
  "id": 4,
  "jsonrpc": "2.0",
  "method": "textDocument/completion",
  "params": {
    "context": {
      "triggerKind": 1
    },
    "position": {
      "character": 1,
      "line": 9
    },
    "textDocument": {
      "uri": "file: ///home/si/dev/sandbox/transpiler/visualiser.bmx"
    }
  }
}
End Rem

Function bls_textDocument_completion:JSON( message:TMessage )
    Trace.debug( "bls_textDocument_completion() - TEST CODE~n"+message.J.stringify() )
    Trace.info( "~n"+message.j.Prettify() )
	
    Local id:String = message.getid()
    Local params:JSON = message.params

    ' Generate response
    Local response:JSON = Response_Ok( id )
    Local items:JSON = New JSON( JARRAY )
    'response.set( "id", message.MsgID )
    'response.set( "jsonrpc", JSONRPC )
    response.set( "result|isIncomplete", "true" )
    response.set( "result|items", items )

    Local item:JSON

    item = New JSON()
    item.set( "label", "Scaremonger" )
    item.set( "kind", CompletionItemKind._Text.ordinal() )
    item.set( "data", 1 )	' INDEX
    items.addlast( item )

    item = New JSON()
    item.set( "label", "BlitzMax" )
    item.set( "kind", CompletionItemKind._Text.ordinal() )
    item.set( "data", 2 )	' INDEX
    items.addlast( item )

    ' Reply to the client
    Return( response )

End Function




