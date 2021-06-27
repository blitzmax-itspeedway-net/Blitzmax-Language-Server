SuperStrict

'	JSON TYPE TESTING
'	(c) Copyright Si Dunford, June 2021

' EASY JSON CREATION

Include "../bin/json.bmx"

'DUMMY LOGFILE SO WE CAN STILL TEST JSON LIBRARY
Type TDummyLog
    Method write(nul:String)
    End Method
End Type
Global logfile:TDummyLog = New TDummyLog
'DUMMY END

Local response:JNode = JSON.Create()
DebugStop;'DebugStop
response.set( "id", 99 )
DebugStop
response.set( "test", "testing" )
response.set( "error|code", 42 )


Local J:JNode 
J = response.find( "id" )
Print J.stringify()
J = response.find( "test" )
Print J.stringify()
J = response.find( "error" )
Print J.stringify()
J = response.find( "error|code" )
Print J.stringify()
J = response.find( "error|text",True )
Print J.stringify()

response.set( "error|text", "~qLife the universe and everything~q" )
DebugStop;Print response.stringify()

DebugStop
response.set( "result|capabilities", [["hoverProvider","true"]] )

response.set( "capabilities", [["hover","true"]] )


''result.set( "capabilities", [["hover","true"]] )
'result.set( "serverinfo|name", "~qBlitzmax Language Server~q" )

Print( "-------------_" )
DebugStop
Print response.stringify()

Print( "-------------_" )
'DebugStop
Local str:String = ""
str   = "{~qjsonrpc~q:~q2.0~q,~qid~q:0,~qmethod~q:~qinitialize~q,"
str  :+ "~qclientInfo~q:{~qname~q:~qVisual Studio~q,~qversion~q:~q123ABC~q},"
str  :+ "~qlocale~q:~qen-gb~q}"

DebugStop
Local JS:JNode = JSON.parse( str )
Print JS.stringify()

J = JS.find( "method" )
DebugStop
Print J.stringify()
DebugStop

Local clientinfo:JNode = JS.find( "clientInfo" )
If clientinfo
	Print( "CLIENT INFO EXISTS" )
	Local clientname:String = clientinfo["name"]
	Local clientver:String = clientinfo["version"]
	
	Print clientname
	Print clientver
Else
	Print( "NO CLIENT INFO EXISTS" )
End If




