
'   BLITZMAX LANGUAGE SERVER
'   (c) Copyright Si Dunford, July 2021, All Right Reserved

'	STANDARD RESPONSES

Function Response_OK:JSON( id:String="null" )
    'Publish( "log", "INFO", "ResponseOK" )
	Local response:JSON = New JSON()
	response.set( "id", id )
	response.set( "jsonrpc", JSONRPC )
	response.set( "result", "null" )
    Return response
End Function

Function Response_Error:JSON( code:String, message:String, id:String="null" )
    'Publish( "log", "ERRR", message )
    Local response:JSON = New JSON()
    response.set( "id", id )
    response.set( "jsonrpc", JSONRPC )
    response.set( "error", [["code",code],["message","~q"+message+"~q"]] )
    Return response
End Function

Function EmptyResponse:JSON( methd:String="" )
    Local response:JSON = New JSON()
    response.set( "jsonrpc", JSONRPC )
	If methd <> "" ; response.set( "method", methd )
    Return response
End Function