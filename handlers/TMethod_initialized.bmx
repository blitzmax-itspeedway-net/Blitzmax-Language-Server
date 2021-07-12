
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	MESSAGE:	initialized
'   TYPE:       Notification
'
'https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#initialized

Type TMethod_initialized Extends TMessage
    ' Commented out as we don't actually need them at the moment
    'Field jsonrpc:String
    'Field methd:String
    'field params:TMap 

    Method Run:String()
        Publish( "TMethod_initialized.run()" )

        ' Request configuration
        'local request:JNode = JSON.create()
        'request.set( "id", id )
        'request.set( "jsonrpc", JSONRPC )
        'request.set( "method", "workspace/configuration" )
        'request.set( "params|items", [["scope","lsp.todo"]] )
        'local message:string = request.stringify()
        'SendMessage( message )

        ' NO RESPONSE REQUIRED
    End Method

End Type
