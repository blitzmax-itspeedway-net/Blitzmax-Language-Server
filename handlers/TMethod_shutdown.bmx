'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved
'   "shutdown" request
'
'  https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#shutdown

Type TMethod_shutdown Extends TMessage
    Field id:Int
    Field jsonrpc:String
    Field methd:String

    Method Run:String()
        Publish( "TMethod_shutdown.run("+id+") " )

        LSP.shutdown = True

        Local response:JSON = New JSON()
        response.set( "id", id )
        response.set( "jsonrpc", JSONRPC )
        response.set( "result", "null" )
        'response.set( "error", [["code",0],["message","TTFN"]] )
        Return response.stringify() 

    End Method

End Type
