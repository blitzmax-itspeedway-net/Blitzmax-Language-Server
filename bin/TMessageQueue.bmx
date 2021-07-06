
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

' The Message Queue listens for messages on a thread and adds them to a queue ready for
' parsing



Type TMessageQueue
    global requestThread:TThread
    global sequential:TQueue<Int>
    global nonsequential:TQueue<Int>

    Method new()
        ' Start the listener thread
        'requestThread = CreateThread( Listener, null )
        ' Start the responder thread
        'respondThread = CreateThread( Responder, null )
        ' Start the sequential message thread
        'syncMessageThread = createThread( Sequencer, null )
        ' Start the async message thread
        'asyncMessageThread = createThread( , null )

        ' Wait for exit condition
        'Repeat
        'until 
    End Method

    Function ReadStdIn:string()

        local contentlength:Int
        local contenttype:string
        local content:string
        local line:string

        Local stdIN:TStream = TTextStream.Create( New TCStandardIO, ETextStreamFormat.UTF8 )
        If not stdIN
            'logfile.write "Failed to open StdIN"
            return ""
        end if

        Repeat
            'print( "BYTES: "+len(line))
            '    if line="" exit
            print "STREAMSIZE: "+StreamSize(stdIN)
            print "STREAMPOS: "+StreamPos(stdIN)
            print "EOF:"+eof(stdIn)
            line = stdIN.ReadLine()
            print( "BYTES: "+len(line))

        forever  
        rem    
        repeat    
            'BLOCKING CALL
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
                'Logfile.write( "Content-Length:"+contentlength)
            ElseIf line.startswith("Content-Type:")
                contenttype = Int( line[13..] )
                ' Backward compatibility, utf8 should be utf-8
                If contenttype = "utf8" contenttype = "utf-8"
                'Logfile.write( "Content-Type:"+contenttype)
            ElseIf line=""
                'Logfile.write( "- WAITING FOR CONTENT...")
                content = stdIN.ReadString$( contentlength )
                'Logfile.write( "- RECEIVED:~n"+content )
                ' Process Message
                'MessageArrived( content )
            Else
                'Logfile.write( "SKIP: "+line)
            End If
            'end select
            'Input$( "#" )

        Until quit  'len(line)=0 or eof(stdIn)
        'logfile.write "Graceful shutdown"
            end rem
    End Function
rem
    ' Thread that listens for incoming messages
    Function Listener() ' THREAD FUNCTION
        local contentlength:Int
        local contenttype:string
        local content:string
        local line:string

        Local stdIN:TStream = TTextStream.Create( New TCStandardIO, ETextStreamFormat.UTF8 )
        If not stdIN
            'logfile.write "Failed to open StdIN"
            return
        end if

        Repeat
            'if 
            
            'BLOCKING CALL
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
                'Logfile.write( "Content-Length:"+contentlength)
            ElseIf line.startswith("Content-Type:")
                contenttype = Int( line[13..] )
                ' Backward compatibility, utf8 should be utf-8
                If contenttype = "utf8" contenttype = "utf-8"
                'Logfile.write( "Content-Type:"+contenttype)
            ElseIf line=""
                'Logfile.write( "- WAITING FOR CONTENT...")
                content = stdIN.ReadString$( contentlength )
                'Logfile.write( "- RECEIVED:~n"+content )
                ' Process Message
                'MessageArrived( content )
            Else
                'Logfile.write( "SKIP: "+line)
            End If
            'end select
            'Input$( "#" )

        Until quit  'len(line)=0 or eof(stdIn)
        'logfile.write "Graceful shutdown"

    End Function


    Function MessageArrived( message:object )
        ' Parse the received JSON-RPC message
        Local J:JNode = JSON.Parse( message )
        ' Validate message
        if not J or J.isInvalid()
            local errtext:string = "ERROR("+JSON.errNum+") "+JSON.errText+" at {"+JSON.errLine+","+JSON.errpos+"}"
            'logfile.write "- Failed to parse message"
            'logfile.write "- "+errtext
            ' Send error message to LSP Client
            respond_error( ERR_PARSE_ERROR, errtext )
            return
        end if
        ' Check for a method
        local node:JNode = J.find("method")
        if not node
            'logfile.write "- No method specified"
            ' Send error message to LSP Client
            respond_error( ERR_METHOD_NOT_FOUND, "No method specified" )
            Return
        end if
        ' Get method
        Local methd:String = node.tostring()
        'Logfile.write( "- RPC METHOD: "+methd )
        if methd = ""
            'logfile.write "- Method is empty"
            ' Send error message to LSP Client
            respond_error( ERR_INVALID_REQUEST, "Method cannot be empty" )
            Return
        end if
        ' Validation
        if not LSP.initialized and methd<>"initialize"
            'logfile.write "- Server is not initialized"
            respond_error( ERR_SERVER_NOT_INITIALIZED, "Server is not initialized" )
            return
        end if
        if LSP.shutdown and methd<>"exit"
            'logfile.write "- Server is not initialized"
            respond_error( ERR_INVALID_REQUEST, "Server has been shut down" )
            return
        end if

        'HERE
       '      
    end Function

    ' Thread that responds to client
    Function Responder() ' THREAD FUNCTION
    end Function
end rem
End Type