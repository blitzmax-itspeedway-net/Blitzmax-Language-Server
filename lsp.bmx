SuperStrict

'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved
'   VERSION 0.00 PA

Framework brl.standardio 
Import brl.collections      ' Used for Tokeniser
'Import brl.linkedlist
Import brl.map              ' Used as JSON dictionary
Import brl.reflection		' USed by JSON.transpose
Import brl.retro
Import brl.stringbuilder
Import brl.system

Import pub.freeprocess

'   INCLUDE APPLICATION COMPONENTS

Include "bin/TLogger.bmx"
Include "bin/json.bmx"

Include "bin/sandbox.bmx"
Include "bin/REQ_initialize.bmx"
Include "bin/REQ_shutdown.bmx"

'   GLOBALS

'Global Version:String = "0.00 Pre-Alpha"
Global Logfile:TLogger = New TLogger()

'   INCREMENT BUILD NUMBER

' @bmk include build.bmk
' @bmk incrementVersion build.bmx
Include "build.bmx"
print( "Version "+version+":"+build )

'   MAIN APPLICATION

Type Main
    Global instance:Main

    Field exitcode:Int = 0
    Field quit:Int = False      ' When to quit

	Field initialised:Int = False
	
    Method New()
        DebugLog( "# BlitzMax LSP" )
        DebugLog( "# V"+Version+":"+build )
        'Log.write( "Initialised")
        ' Set up exit function
        instance = Self
        OnEnd( Main.OnEnd )        
    End Method

    Method run:Int()
        'Local stdIN:TStream
        Local line:String   ', char:String
        Local content:String
        Local contentlength:Int
		Local contenttype:String = "utf-8"
        'Local fsm:Int = 0
        'Local counter:Int = 0
        Local stdIN:TStream = ReadStream( StandardIOStream )
        If stdIN
            Repeat


                line = stdIN.ReadLine()
                'print( "BYTES: "+len(line))
                '    if line="" exit
                'print "STREAMSIZE: "+StreamSize(stdIN)
                'print "STREAMPOS: "+StreamPos(stdIN)
                'print "EOF:"+eof(stdIn)
                'select fsm
                'case 0  ' Read Headers
                If line.startswith("Content-Length:")
                    contentlength = Int( line[15..] )
                    Logfile.write( "HEADER: Content-Length:"+contentlength)
                ElseIf line.startswith("Content-Type:")
                    contenttype = Int( line[13..] )
					' Backward compatibility, utf8 is no longer supported
					If contenttype = "utf8" contenttype = "utf-8"
                    Logfile.write( "HEADER: Content-Type:"+contenttype)
                ElseIf line=""
                    Logfile.write( "CONTENT STARTING...")
                    content = stdIN.ReadString$( contentlength )
                    Logfile.write( "- RECEIVED:~n"+content )

                    ' Start a thread to process content
                    'local thread:TThread = CreateThread( OnMessage, content )
                    OnMessage( content )
                Else
                    Logfile.write( "SKIP:"+line)
                End If
                'end select
                'Input$( "#" )

            Until quit  'len(line)=0 or eof(stdIn)

        Else
            Print "Failed to open StdIN"
        End If
            
        

        ' Clean up and exit gracefully
		Logfile.Close()
        Return exitcode
    End Method
    
    Method Close()
    End Method

    ' Parse a request
    Function OnMessage( message:String )
		' Parse message into a JSON object
        Logfile.write( "onMessage()" )
        Local j:JNode = JSON.Parse( message )

        logfile.write( "JSON COMPLETION:" )
        logfile.write( "ERROR("+JSON.errNum+") "+JSON.errText+" at {"+JSON.errLine+","+JSON.errpos+"}" )

        ' Report an error to the Client using stdOut
        if J.isInvalid()
            print "Failed to parse message"
            print "ERROR("+JSON.errNum+") "+JSON.errText+" at {"+JSON.errLine+","+JSON.errpos+"}"
            if len(message)>50
                print message[..50]+"..."
            else
                print message
            end if
        end if

        Local debug:String = JSON.stringify(J)
        logfile.write( "STRINGIFY:" )
        logfile.write( debug )

		' Check if message is a Request:
		'	(Requests contain "method" key)
		Local methd:String = j["method"].tostring()
        Logfile.write( "- Method="+methd )
		If methd<>""
            Logfile.write( "Transposing..." )
            Try
                Local request:TRequest = TRequest( j.transpose( "REQ_"+methd ))
                If request
                    Logfile.write( "- Executing" )
                    request.execute()
                Else
                    Logfile.write( "- TRequest is null")
                End If
            Catch exception:String
                logfile.write( exception )
            End Try
            Logfile.write( "Execution complete" )
		else
            Logfile.write( "No Method identified")
        End If

    End Function

    Function OnEnd()
        Print( "Running exit function")
        instance.Close()
		Logfile.Close()
    End Function

End Type

' BASIC REQUEST TYPE
Type TRequest
    Field id:String	' Always "2.0"
    Method Execute() Abstract
End Type

Function StdIO_Read_Thread()
    'LockMutex( stdIO_read )
    'UnlockMutex( stdIO_read )
End Function

Function StdIO_Write_Thread()
    'LockMutex( stdIO_write )
    'UnlockMutex( stdIO_write )
End Function

'   Run the Application
print "Starting LSP..."
try
    Global LSP:Main = New Main()
    exit_( LSP.run() )
catch exception:string
    DebugLog( exception )
end try
