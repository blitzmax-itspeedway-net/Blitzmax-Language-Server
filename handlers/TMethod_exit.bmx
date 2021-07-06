
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	MESSAGE:	exit
'	TYPE:       Notification
'
'https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#exit

Type TMethod_exit Extends TMessage
    ' Commented out as we don't actually need them
    'Field id:int
    'Field jsonrpc:String
    'Field methd:String
    Method Run:string()
        Publish( "lsp.exit.run() " )
        ' Stop LSP application loop
        LSP.quit = True
        ' NO RESPONSE REQUIRED
    End Method

End Type
