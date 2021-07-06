
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	MESSAGE:	shutdown
'	TYPE:       Request	
'
'  https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#shutdown

Type TMethod_shutdown Extends TMessage
    Field id:int
    Field jsonrpc:String
    Field methd:String

    Method Run:String()
        Publish( "TMethod_shutdown.run() " )

        LSP.shutdown = true

        local response:JNode = JSON.create()
        response.set( "id", id )
        response.set( "jsonrpc", "2.0" )
        response.set( "result", "null" )
        'response.set( "error", [["code",0],["message","TTFN"]] )
        return response.stringify() 

    End Method

End Type
