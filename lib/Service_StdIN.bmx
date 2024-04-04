SuperStrict

'   StdIN Service for BlitzMax Language Server
'   (c) Copyright Si Dunford, JAN 2023, All Rights Reserved. 
'   VERSION: 1.0

Import bmx.observer
Import bmx.json

Import "messages.bmx"
'Import "jtypes.bmx"
Import "lsp_types.bmx"		' ERRORCODES
Import "trace.bmx"

Observer.threaded()
Service_StdIN.initialise()

Type Service_StdIN

	Global instance:Service_StdIN
	
	Field StdIN:TStream
	Field thread:TThread	= Null	' The message queue thread
	
	Function initialise()
		If Not instance; instance = New Service_StdIN()
	End Function

	' Start Thread
	Function start()
		If Not instance; Throw( "Failed to start StdIN" )

		' Connect to StdIN
		instance.StdIN = ReadStream( StandardIOStream )
		If Not instance.StdIN
			Trace.Write( SEVERITY.CRITICAL, "StdIN: Unable to connect" )
			Throw( "StdIN: Unable to connect" )
		End If
		'
		Trace.Info( "StdIN Service starting" )
		instance.thread	= CreateThread( FN, instance )	
	End Function
		
'	Method New()
'	End Method
	
	Function FN:Object( data:Object )
		Local this:Service_StdIN = Service_StdIN( data )
		
		Repeat
			' Get inbound TEXT from Client
            Local content:String = this.read()
			Trace.debug( ">> "+content )
			
            ' Parse message into JSON
            Local J:JSON = JSON.Parse( content )

            ' Validate the JSON message
			Select True
			Case Not J
				Local Error:JSON = New JError( ERRORCODES.ParseError, "Parse returned Null" )
				Observer.post( MSG_SERVER_OUT, Error )
			Case J.isInvalid()
				Local Error:JSON = New JError( ERRORCODES.InvalidRequest, "ERROR("+J.errNum+") "+J.errText+" at {"+J.errLine+","+J.errpos+"}" )
				Observer.post( MSG_SERVER_OUT, Error )
			Default
				' Forward message to Input queue
				Observer.post( MSG_CLIENT_IN, J )
			End Select
		Forever	
	End Function

	' Read a single message from input stream
	Method read:String()

		If Not StdIN ; Return ""

        Local line:String
        Local contentlength:Int
		Local contenttype:String = "application/vscode-jsonrpc; charset=utf-8"

        ' Read messages from StdIN
		Local running:Int = True     ' Local loop state
        Repeat
			line = StdIN.ReadLine()
			If line.startswith("Content-Length:")
				contentlength = Int( line[15..] )
			ElseIf line.startswith("Content-Type:")	' We dont really use this here!
				contenttype = Int( line[13..] )
				' Backward compatibility; utf8 is invalid
				'If contenttype = "utf8"; contenttype = "utf-8"
				contenttype.Replace( "utf8", "utf-8" )
			ElseIf line=""	' And contentlength>0
				Local content:String = stdIN.ReadString$( contentlength )
				If Len(content)>0; Return content
			End If
        Forever
	End Method
		
End Type
