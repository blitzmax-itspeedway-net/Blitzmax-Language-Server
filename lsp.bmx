SuperStrict

'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved
'   VERSION 0.00 PA

Framework brl.standardio 
Import pub.freeprocess
Import brl.stringbuilder
Import brl.retro

Import brl.collections      ' Used for Tokeniser
Import brl.map              ' Used as JSON dictionary
Import brl.reflection		' USed by JSON.transpose
'Import brl.retro
'Import brl.linkedlist

Include "bin/TLogger.bmx"
Include "bin/json.bmx"

'   SANDBOX

Type TRequest
    Field id:String
End Type

'Type TRequest
'    Field id:String
'    Field invoke:String
'    Field params:Object[]
'End Type

'Type TMessage
'    Field jsonrpc:String
'    Field id:Int
'    Field methd:String
'End Type

Type TShutdown Extends TRequest
    Field jsonrpc:String
    Field methd:String
End Type

Print "TESTING"

'DebugStop

Local text:String = "{~qname~q: ~qJohn~q, ~qage~q: 30, ~qcity~q: ~qNew York~q}"
Local j:JSON
Try
    j = JSON.parse( text )
Catch E:String
    Print e
End Try

Print j.stringify()

DebugStop 

Local shutdown:String = "{~qjsonrpc~q:~q2.0~q,~qid~q:1,~qmethod~q:~qshutdown~q}"
j = JSON.Parse( shutdown )

Local message:TRequest = j.transpose()

Print j.stringify()

' Test that we can extract a value
Local invoke_method:String = j["method"].tostring()
Print "METHOD: "+invoke_method

DebugStop
'if j["method"]="shutdown"
'    local request:TShutdown = new TShutdown( j.transpose( "TShutdown" ) )
'    .OR.
'    local request:TShutdown 
'    j.transpose( "TShutdown", request )
'end if
'print sm.jsonrpc


'print "BACK TO TEXT"
'local result:String = json.Stringify(j)
'print result

End


Global Version:String = "0.00 Pre-Alpha"

Type Main
    Global instance:Main

    Field exitcode:Int = 0
    Field Log:TLogger
    Field quit:Int = False      ' When to quit

    Method New()
        Log = New TLogger()
        DebugLog( "# BlitzMax LSP" )
        DebugLog( "# V"+Version )
        Log.write( "Initialised")
        ' Set up exit function
        instance = Self
        OnEnd( Main.OnEnd )        
    End Method

    Method run:Int()
        'Local stdIN:TStream
        Local line:String   ', char:String
        Local content:String
        Local contentlength:Int
        Local fsm:Int = 0
Local counter:Int = 0
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
                    Log.write( "HEADER: Content-Length")
                    Print( "HEADER: Cntent-length")
                    contentlength = Int( line[15..] )
                    Log.write( "- LENGTH:"+contentlength )
                    Print( "- LENGTH:"+contentlength )
                ElseIf line=""
                    Log.write( "IGNORE BLANK")
                    content = stdIN.ReadString$( contentlength )
                    Log.write( "RECEIVED:~n"+content )

                    ' Start a thread to process content
                    'local thread:TThread = CreateThread( Request, content )
                    Request( content )
                Else
                    Log.write( "SKIP:"+line)
                End If
                'end select
                'Input$( "#" )

            Until quit  'len(line)=0 or eof(stdIn)
Rem
            print "STDIN OPEN"
            repeat 
                print( "Waiting for input" )
                ' ## BLOCKING CALL ##
                line = stdIN.ReadLine()
                print "FINISHED READING LINE"
                select fsm
                case 0  ' Waiting for Content-Length
                    print( "WAITING FOR CONTENT-LENGTH")
                    if line.StartsWith( "Content-Length:" )
                        contentlength = int( line[15..] )
                        print( "LENGTH:"+contentlength )
                        fsm = 1
                    Else
                        print( "SKIP: "+line)
                    end if
                case 1  ' Waiting for Header to complete (Blank Line)
                    print( "WAITING FOR HEADER")
                    line = stdIN.ReadLine()
                    if trim(line)=""
                        print( "Header complete")
                        content = stdIN.ReadString$( contentlength )
                        print "RECEIVED:~n"+content
                        fsm = 0
                    Else
                        print( "SKIP: "+line)
                    end if
                Default
                    print "..."
                End Select
                    ' Ignore everything else until start of JSON
'                    local ignored:string
 '                   Repeat
  '                      char = stdIN.ReadString(1)
   '                     ignored :+ char
    '                until char="{"
     '               print "IGNORED: "+ignored

                    'char :+ 
                'else just ignore line
                'End If
                'Local input:string = ReadLine( stdIN )
                'print( input )
                counter :+ 1
                if counter>5 end
            Until quit 'or counter > 5
end Rem
        Else
            Print "Failed to open StdIN"
        End If
            
        

        ' Clean up and exit gracefully
        Log.Close()
        Return exitcode
    End Method
    
    Method Close()
        Log.Close()
    End Method

    ' Parse a request
    Function Request( content:String )
        Local j:Object = json.parse( content )

        'select j["method"]
        'case "shutdown"
        'case "initialise"
        'default
        'end select

    End Function

    Function OnEnd()
        Print( "Running exit function")
        instance.Close()
    End Function

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

exit_( New Main().run() )
