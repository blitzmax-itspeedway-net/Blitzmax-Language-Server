
'   BLITZMAX LANGUAGE SERVER
'   (c) Copyright Si Dunford, July 2021, All Right Reserved

'	CONSTANTS

' RPC2.0 Error Messages
Const ERR_PARSE_ERROR:String =       "-32700"  'Invalid JSON was received by the server.
Const ERR_INVALID_REQUEST:String =   "-32600"  'The JSON sent is not a valid Request object.
Const ERR_METHOD_NOT_FOUND:String =  "-32601"  'The method does not exist / is not available.
Const ERR_INVALID_PARAMS:String =    "-32602"  'Invalid method parameter(s).
Const ERR_INTERNAL_ERROR:String =    "-32603"  'Internal JSON-RPC error.

' LSP Error Messages
Const ERR_SERVER_NOT_INITIALIZED:String = "-32002"
Const ERR_CONTENT_MODIFIED:String =       "-32801"
Const ERR_REQUEST_CANCELLED:String =      "-32800"
'
Const JSONRPC:String = "2.0"		' Supported JSON-RPC version

' MESSAGE STATES
Const STATE_WAITING:Int = 0
Const STATE_RUNNING:Int = 1
Const STATE_COMPLETE:Int = 2
'const STATE_CANCELLED:int = 3
'Const STATE_UNHANDLED:Int = 4

?win32
    Const EOL:String = "~n"
?Not win32
    Const EOL:String = "~r~n"
?

