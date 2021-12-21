
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
		logfile.critical( "Failed To open StdIN" )
		Return False
	End Method
	
	' Close StdIN
	Method Close()
	End Method
	
	' Read Message from Client
	Method read:String()
		If Not StdIn ; Return ""
		
'DebugLog( "STDIN NOT NULL" )

        Local line:String
        Local content:String
        Local contentlength:Int
		Local contenttype:String = "utf-8"

        ' Read messages from StdIN
		Local running:Int = True     ' Local loop state
'DebugLog( "STARTING LOOP" )
        Repeat
            Try
'DebugLog( "STARTING TO LISTEN" )
                line = stdIn.ReadLine()
'DebugLog( "GOT CONTENT" )
                If line.startswith("Content-Length:")
                    contentlength = Int( line[15..] )
                    logfile.debug( "Content-Length:"+contentlength)
                ElseIf line.startswith("Content-Type:")
                    contenttype = Int( line[13..] )
                    ' Backward compatibility, utf8 is no longer supported
                    If contenttype = "utf8" contenttype = "utf-8"
                   logfile.debug( "Content-Type:"+contenttype)
                ElseIf line=""
                    logfile.debug( "WAITING FOR CONTENT...")
                    content = stdIN.ReadString$( contentlength )
                    logfile.debug( "TLSP_Stdio.getRequest() received "+contentlength+" bytes" )
                    Return content
                Else
                    logfile.debug( "Skipping: "+line )
                End If
            Catch Exception:String
                logfile.critical( Exception )
            End Try
        'Until endprocess
        Until CompareAndSwap( lsp.QuitMain, running, False )
logfile.debug( "TClient_StdIO() - Quitting" )
	End Method
	
	' Write Message to Client
'BUG HERE - CLIENT Not RECEIVING REPLIES

	Method write( content:String )

		If content = "" ; Return
		
		Local response:String = "Content-Length: "+Len(content)+EOL
		response :+ EOL
		response :+ content
		' Log the response
'		logfile.debug( "TClient_StdIO() - Writing data to client~n"+response )
		' Send to client
'		StdIOlock.lock()
		StandardIOStream.WriteString( response )
		StandardIOStream.Flush()
'		StdIOlock.unlock()
'logfile.debug( "TClient_StdIO() - data written to client" )
	End Method
	
End Type

