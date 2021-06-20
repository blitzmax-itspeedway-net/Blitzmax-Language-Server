
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	REQUEST:	initialize
'	RESPONSE:	

Type REQ_shutdown Extends TRequest
    Field jsonrpc:String
    Field methd:String

    Method Execute()
Logfile.write( "LSP_initialize.execute()" )
    End Method

End Type
