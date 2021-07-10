
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	MESSAGE:	$/cancelRequest
'	TYPE:       Notification

Type TMethod_dollar_cancelRequest Extends TMessage
    'Field id:int           ' Notification doesn't have an id
    'Field jsonrpc:String   ' Not important
    'Field methd:String     ' Not important
    Field params:JSON

    Method Run:String()
        Publish( "TMethod_pid_cancelRequest.execute() " )

        Local idnode:JSON = J.find("id")
        If idnode Publish( "cancelrequest", idnode )

        Return "" ' No response necessary
    End Method

End Type
