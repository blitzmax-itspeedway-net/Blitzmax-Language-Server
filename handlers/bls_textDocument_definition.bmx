
'   LANGUAGE SERVER MESSAGE HANDLER
'   (c) Copyright Si Dunford, October 2021, All Right Reserved
'
'   https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_definition
'   REQUEST:    textDocument/completion
'
'   Provide definition when you press F12 on a keyword

Rem EXAMPLE
{
  "id": 3,
  "jsonrpc": "2.0",
  "method": "textDocument/definition",
  "params": {
    "position": {
      "character": 28,
      "line": 0
    },
    "textDocument": {
      "uri": "file: ///home/si/dev/sandbox/transpiler/visualiser.bmx"
    }
  }
}
End Rem

Function bls_textDocument_definition( message:TMessage )
    logfile.debug( "bls_textDocument_definition() - TEST CODE~n"+message.J.stringify() )
    logfile.info( "~n"+message.j.Prettify() )
	
    Local id:String = message.getid()
    Local params:JSON = message.params

	client.send( Response_OK( id ) )
End Function

