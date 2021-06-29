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
'debugstop
'   INCLUDE APPLICATION COMPONENTS

Include "bin/TConfig.bmx"
Include "bin/TLogger.bmx"
'Include "bin/TTemplate.bmx"    ' Depreciated (Functionality moved into JSON)
Include "bin/json.bmx"

Include "bin/sandbox.bmx"

Include "handlers/handlers.bmx"

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

?win32
    Const EOL:String = "~n"
?Not win32
    Const EOL:String = "~r~n"
?

'   GLOBALS
apptitle = "Language Server for BlitzMax NG"

'Global Version:String = "0.00 Pre-Alpha"
Global Logfile:TLogger = New TLogger()
Global LSP:TLSP

logfile.debug "ARGS: ("+appargs.length+")"+(" ".join(appargs))
logfile.debug "CURRENTDIR: "+CurrentDir$()
logfile.debug "APPDIR:     "+AppDir

'   INCREMENT BUILD NUMBER

' @bmk include build.bmk
' @bmk incrementVersion build.bmx
Include "build.bmx"
logfile.info( apptitle )
logfile.info( "Version "+version+":"+build )

'   MAIN APPLICATION

'DebugStop
Type TLSP
    Global instance:TLSP

    Field exitcode:Int = 0

	Field initialized:Int = False   ' Set by "iniialized" message
    Field shutdown:int = false      ' Set by "shutdown" message
    Field quit:Int = False          ' Set by "exit" message

    Method run:Int() abstract
End Type

Type TLSP_TCP extends TLSP
    Method Run:int() ; End Method
End Type

Type TLSP_Stdio extends TLSP
	
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
                    Logfile.debug( "Content-Length:"+contentlength)
                ElseIf line.startswith("Content-Type:")
                    contenttype = Int( line[13..] )
					' Backward compatibility, utf8 is no longer supported
					If contenttype = "utf8" contenttype = "utf-8"
                    Logfile.debug( "Content-Type:"+contenttype)
                ElseIf line=""
                    Logfile.debug( "- WAITING FOR CONTENT...")
                    content = stdIN.ReadString$( contentlength )
                    Logfile.debug( "- RECEIVED:~n"+content )

                    ' Start a thread to process content
                    'local thread:TThread = CreateThread( OnMessage, content )
                    OnMessage( content )
                Else
                    Logfile.debug( "SKIP: "+line)
                End If
                'end select
                'Input$( "#" )

            Until quit  'len(line)=0 or eof(stdIn)
            logfile.debug "Graceful shutdown"
        Else
            logfile.critical "Failed to open StdIN"
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
        Logfile.debug( "onMessage()" )
        Local J:JNode = JSON.Parse( message )

        'logfile.debug( "JSON COMPLETION:" )
        'logfile.debug( "ERROR("+JSON.errNum+") "+JSON.errText+" at {"+JSON.errLine+","+JSON.errpos+"}" )

        ' Report an error to the Client using stdOut
        if not J or J.isInvalid()
            local errtext:string = "ERROR("+JSON.errNum+") "+JSON.errText+" at {"+JSON.errLine+","+JSON.errpos+"}"
            logfile.error "- Failed to parse message"
            logfile.error "- "+errtext
            'if len(message)>50
            '    logfile.write message[..50]+"..."
            'else
            '    logfile.write message
            'end if

            ' Send error message to LSP Client
            respond_error( ERR_PARSE_ERROR, errtext )

            Return
        end if

        ' Debugging
        'Local debug:String = JSON.stringify(J)
        'logfile.write( "STRINGIFY:" )
        'logfile.write( "  "+debug )

        ' Check for a method
        local node:JNode = J.find("method")
        if not node
            logfile.error "- No method specified"
            ' Send error message to LSP Client
            respond_error( ERR_METHOD_NOT_FOUND, "No method specified" )
            Return
        end if

        ' Get method
        Local methd:String = node.tostring()
        Logfile.debug( "- RPC METHOD: "+methd )
        if methd = ""
            logfile.error "- Method is empty"
            ' Send error message to LSP Client
            respond_error( ERR_INVALID_REQUEST, "Method cannot be empty" )
            Return
        end if

        ' Validation
        if not LSP.initialized and methd<>"initialize"
            logfile.error "- Server is not initialized"
            respond_error( ERR_SERVER_NOT_INITIALIZED, "Server is not initialized" )
            return
        end if

        ' Transpose JNode into Blitzmax Object
        'Logfile.debug( "- Transposing..." )
        Local request:TMessage
        Try
            local typestr:string = "TMethod_"+methd
            typestr = typestr.replace( "/", "_" )
            typestr = typestr.replace( "$", "pid" ) ' Protocol Implementation Dependent
            Logfile.debug( "- BMX METHOD: "+typestr )
            ' Transpose RPC
            request = TMessage( J.transpose( typestr ))
            if not request
                Logfile.debug( "- Transpose to '"+typestr+"' failed")
                respond_error( ERR_METHOD_NOT_FOUND, "Method is not available" )
                Return
            end if               
        Catch exception:String
            logfile.critical( "  "+exception )
            respond_error( ERR_INTERNAL_ERROR, exception )
            return
        End Try

        debugstop
        ' Execute the request
        'Logfile.debug( "- Executing" )
        try
            request.execute()
        catch exception:string
            logfile.critical( "  "+exception )
            respond_error( ERR_INTERNAL_ERROR, exception )
            return           
        end try

        Logfile.debug( "- Execution complete" )

    End Function

    Function OnEnd()
        logfile.debug( "Running onEnd() function")
        instance.Close()
		Logfile.Close()
    End Function
    
End Type

rem
Function StdIO_Read_Thread()
    'LockMutex( stdIO_read )
    'UnlockMutex( stdIO_read )
End Function

Function StdIO_Write_Thread()
    'LockMutex( stdIO_write )
    'UnlockMutex( stdIO_write )
End Function
end rem

function respond( content:string )
    Local response:String = "Content-Length: "+Len(content)+EOL
    response :+ EOL
    response :+ content
    '
    Logfile.debug( response )
    StandardIOStream.WriteString( response )
    StandardIOStream.Flush()
end function

function respond_error( code:string, message:string )
    local response:JNode = JSON.create()
    response.set( "id", "null" )
    response.set( "jsonrpc", "2.0" )
    response.set( "error", [["code",code],["message","~q"+message+"~q"]] )
    respond( response.stringify() )
end Function

'   Run the Application
logfile.debug "Starting LSP..."

try
    LSP = New TLSP_Stdio()
    exit_( LSP.run() )
catch exception:string
    logfile.critical( exception )
end try
