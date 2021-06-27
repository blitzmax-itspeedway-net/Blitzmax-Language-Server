
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	MESSAGE:	initialized
'   TYPE:       Notification
'
'https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#initialized

Type TMethod_initialized Extends TMessage
    ' Commented out as we don't actually need them
    'Field jsonrpc:String
    'Field methd:String
    'field params:TMap 

    Method Execute()
        Logfile.write( "TMethod_initialized.execute()" )
        ' NO RESPONSE REQUIRED
    End Method

End Type
