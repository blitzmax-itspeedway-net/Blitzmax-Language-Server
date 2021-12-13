
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

' LOGGER
Const LOG_EMERGENCY:Int = 0 
Const LOG_ALERT:Int     = 1
Const LOG_CRITICAL:Int  = 2
Const LOG_ERROR:Int     = 3
Const LOG_WARNING:Int   = 4
Const LOG_NOTICE:Int    = 5
Const LOG_INFO:Int      = 6
Const LOG_DEBUG:Int     = 7

?win32
    Const EOL:String = "~n"
?Not win32
    Const EOL:String = "~r~n"
?

' How often a progress bar is updated
Const PROGRESS_FREQUENCY:Int = 1000

Rem 20/10/21, Replaced with "language-server-protocol.bmx" version
Type CompletionItemKind
	Const _Text:Int = 1
	Const _Method:Int = 2
	Const _Function:Int = 3
	Const _Constructor:Int = 4
	Const _Field:Int = 5
	Const _Variable:Int = 6
	Const _Class:Int = 7
	Const _Interface:Int = 8
	Const _Module:Int = 9
	Const _Property:Int = 10
	Const _Unit:Int = 11
	Const _Value:Int = 12
	Const _Enum:Int = 13
	Const _Keyword:Int = 14
	Const _Snippet:Int = 15
	Const _Color:Int = 16
	Const _File:Int = 17
	Const _Reference:Int = 18
	Const _Folder:Int = 19
	Const _EnumMember:Int= 20
	Const _Constant:Int = 21
	Const _Struct:Int = 22
	Const _Event:Int = 23
	Const _Operator:Int = 24
	Const _TypeParameter:Int = 25
End Type
EndRem

Rem 20/10/21, Replaced with "language-server-protocol.bmx" version
Type TextDocumentSyncKind
	Const _None:Int = 0
	Const _Full:Int = 1
	Const _Incremental:Int = 2
End Type
EndRem
