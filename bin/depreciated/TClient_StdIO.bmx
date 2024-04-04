
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

Type TClient_StdIO Extends TClient

	Field StdIn:TStream
'	Field StdIOlock:TMutex = New TMutex()
	
	' Open StdIn
	Method open:Int()
'DebugLog( "OPENING STDIO" )
		StdIn = ReadStream( StandardIOStream )
'DebugLog( "STDIO OPEN" )
		If StdIn ; Return True
'DebugLog( "STDIO - FAILED" )
		Trace.critical( "Failed To open StdIN" )
		Return False
	End Method
	
	' Close StdIN
	Method Close()
	End Method
	
	' Read Message from Client
	Method Read:String()
		If Not StdIn ; Return ""
		
'DebugLog( "STDIN NOT NULL" )

        Local line:String
        'Local content:String
        Local contentlength:Int
		'Local contenttype:String = "utf-8"
		Local contenttype:String = "application/vscode-jsonrpc; charset=utf-8"

        ' Read messages from StdIN
		Local running:Int = True     ' Local loop state
'DebugLog( "STARTING LOOP" )
        Repeat
            Try
'DebugLog( "STARTING TO LISTEN" )
                line = stdIn.ReadLine()
				Trace.info( "STDIN < "+line )
'DebugLog( "GOT CONTENT" )
                If line.startswith("Content-Length:")
                    contentlength = Int( line[15..] )
                    Trace.debug( "Content-Length:"+contentlength)
                ElseIf line.startswith("Content-Type:")
                    contenttype = Int( line[13..] )
                    ' Backward compatibility, utf8 is no longer supported
                    If contenttype = "utf8" contenttype = "utf-8"
					contenttype.Replace( "utf8", "utf-8" )
					Trace.debug( "Content-Type:"+contenttype)
                ElseIf line=""
                    Trace.debug( "WAITING FOR CONTENT...")
                    Local content:String = stdIN.ReadString$( contentlength )
                    Trace.debug( "TLSP_Stdio.getRequest() received "+contentlength+" bytes" )
                    If Len(content) > 0; Return content
                Else
                    Trace.debug( "Skipping: "+line )
                End If
            Catch Exception:String
                Trace.critical( Exception )
            End Try
        'Until endprocess
        Until CompareAndSwap( lsp.QuitMain, running, False )
Trace.debug( "TClient_StdIO() - Quitting" )
	End Method
	
	' Write Message to Client
'BUG HERE - CLIENT Not RECEIVING REPLIES

	Method write( content:String )

		If content = "" ; Return
		
		Local response:String = "Content-Length: "+Len(content)+EOL
		response :+ EOL
		response :+ content
		' Log the response
'		Trace.debug( "TClient_StdIO() - Writing data to client~n"+response )
		' Send to client
'		StdIOlock.lock()
		StandardIOStream.WriteString( response )
		StandardIOStream.Flush()
'		StdIOlock.unlock()
'Trace.debug( "TClient_StdIO() - data written to client" )
	End Method
	
End Type

