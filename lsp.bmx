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
Import brl.threads
Import brl.threadpool

Import pub.freeprocess
'debugstop
'   INCLUDE APPLICATION COMPONENTS

'DebugStop

Include "bin/TObserver.bmx"
Include "bin/TMessageQueue.bmx"
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
AppTitle = "Language Server for BlitzMax NG"
'DebugStop
'Global Version:String = "0.00 Pre-Alpha"
Local Logfile:TLogger = New TLogger()         ' Please use Observer
Global LSP:TLSP

'   DEBUG THE COMMAND LINE
Publish "log", "DEBG", "ARGS: ("+AppArgs.length+")"     '+(" ".join(AppArgs))
for local n:int=0 until appargs.length
    Publish "log", "DEBG", n+") "+AppArgs[n]
next
Publish "log", "DEBG", "CURRENTDIR: "+CurrentDir$()
Publish "log", "DEBG", "APPDIR:     "+AppDir

'   INCREMENT BUILD NUMBER

' @bmk include build.bmk
' @bmk incrementVersion build.bmx
Include "build.bmx"
Publish "log", "INFO", AppTitle
Publish "log", "INFO", "Version "+version+":"+build

'   MAIN APPLICATION

'DebugStop
Type TLSP Extends TObserver
    Global instance:TLSP

    Field exitcode:Int = 0

	Field initialized:Int = False   ' Set by "iniialized" message
    Field shutdown:Int = False      ' Set by "shutdown" message
    Field quit:Int = False          ' Set by "exit" message

    Field queue:TMessageQueue = New TMessageQueue()

    ' Threads
    Field Receiver:TThread
    Field QuitReceiver:Int = True   ' Atomic State
    Field Sender:TThread
    Field QuitSender:Int = True     ' Atomic State
    Field ThreadPool:TThreadPoolExecutor
    Field ThreadPoolSize:Int
    Field sendMutex:TMutex = CreateMutex()
    
    Method run:Int() Abstract
    Method getRequest:String() Abstract     ' Waits for a message from client

    Method Close() ; End Method
    
    Function ExitProcedure()
        Publish( "exitnow" )
        instance.Close()
        'Logfile.Close()
    End Function

    ' Thread based message receiver
    Function ReceiverThread:Object( data:Object )
        Local lsp:TLSP = TLSP( data )
        Local quit:Int = False          ' Always got to know when to quit!

        ' Read messages from Language Client
        Repeat

            Local node:JNode
                       
            ' Get inbound message from Language Client
            Local content:String = lsp.getRequest()

            ' Parse message into a JSON object
            Local J:JNode = JSON.Parse( content )
            ' Report an error to the Client using stdOut
            If Not J Or J.isInvalid()
                Local errtext:String = "ERROR("+JSON.errNum+") "+JSON.errText+" at {"+JSON.errLine+","+JSON.errpos+"}"
                ' Send error message to LSP Client
                Publish( "send", Response_Error( ERR_PARSE_ERROR, errtext ) )
                Continue
            End If
    
            ' Debugging
            'Local debug:String = JSON.stringify(J)
            'logfile.write( "STRINGIFY:" )
            'logfile.write( "  "+debug )
   
            ' Check for a method
            node = J.find("method")
            If Not node 
                Publish( "send", Response_Error( ERR_METHOD_NOT_FOUND, "No method specified" ))
                Continue
            End If
            Local methd:String = node.tostring()
            'Publish( "log", "DEBG", "RPC METHOD: "+methd )
            If methd = "" 
                Publish( "send", Response_Error( ERR_INVALID_REQUEST, "Method cannot be empty" ))
                Continue
            End If
            ' Validation
            If Not LSP.initialized And methd<>"initialize"
                Publish( "send", Response_Error( ERR_SERVER_NOT_INITIALIZED, "Server is not initialized" ))
                Continue
            End If
    
            ' Process "Immediate" notifications
            ' Now performed by TMessage class
            'If methd = "$/cancelRequest"
            '    node = J.find("id")
            '    if node Publish( "cancelrequest", node )
            '    return True
            'End If 
                
            ' Transpose JNode into Blitzmax Object
            Local request:TMessage
            Try
                Local typestr:String = "TMethod_"+methd
                typestr = typestr.Replace( "/", "_" )
                typestr = typestr.Replace( "$", "dollar" ) ' Protocol Implementation Dependent
                'Publish( "log", "DEBG", "BMX METHOD: "+typestr )
                ' Transpose RPC
                request = TMessage( J.transpose( typestr ))
                If Not request
                    Publish( "log", "DEBG", "Transpose to '"+typestr+"' failed")
                    Publish( "send", Response_Error( ERR_METHOD_NOT_FOUND, "Method is not available" ))
                    Continue
                Else
                    ' Save JNode into message
                    request.J = J
                End If
            Catch exception:String
                Publish( "send", Response_Error( ERR_INTERNAL_ERROR, exception ))
            End Try
    
            ' A Request is pushed to the task queue
            ' A Notification is executed now
            If request.contains( "id" )
                ' This is a request, add to queue
                Publish( "log", "DEBG", "Pushing request to queue")
                Publish( "pushtask", request )
                'lsp.queue.pushTaskQueue( request )
                Continue
            Else
                ' This is a Notification, execute it now and throw away any response
                Try
                    Publish( "log", "DEBG", "Running Notification "+methd )
                    request.run()
                Catch exception:String
                    Publish( "send", Response_Error( ERR_INTERNAL_ERROR, exception ))    
                End Try
            End If
        Until CompareAndSwap( lsp.QuitReceiver, quit, True )

    End Function

    ' Thread based message sender
'TODO
    Function SenderThread:Object( data:Object )
        Local lsp:TLSP = TLSP( data )
        Local quit:Int = False          ' Always got to know when to quit!
        
        'DebugLog( "SenderThread()" )
        Repeat
            Try
                WaitSemaphore( lsp.queue.sendcounter )
                Publish( "LSP.queue.semaphore released" )
                ' Create a Response from message
                Local content:String = lsp.queue.popSendQueue()
                'Publish( "Sending..." )
                If content<>""  ' Only returns "" when thread exiting
                    Local response:String = "Content-Length: "+Len(content)+EOL
                    response :+ EOL
                    response :+ content
                    ' Log the response
                    Publish( "log", "DEBG", "Sending:\n"+response )
                    ' Send to client
                    LockMutex( lsp.sendMutex )
                    StandardIOStream.WriteString( response )
                    StandardIOStream.Flush()
                    UnlockMutex( lsp.sendMutex )
                End If
            Catch Exception:String 
                DebugLog( Exception )
                Publish( Exception )
            End Try
        Until CompareAndSwap( lsp.QuitSender, quit, True )
    End Function  

End Type

' RESERVED FOR FUTURE EXPANSION
Type TLSP_TCP Extends TLSP
    Method Run:Int() ; End Method
    Method getRequest:String() ; End Method
End Type

' StdIO based LSP
Type TLSP_Stdio Extends TLSP
	Field StdIn:TStream

    Method New( threads:Int = 4 )
        DebugLog( "# BlitzMax LSP" )
        DebugLog( "# V"+Version+":"+build )
        'Log.write( "Initialised")
        ' Set up instance and exit function
        instance = Self
        OnEnd( TLSP.ExitProcedure )
        ' Debugstop
        ThreadPoolSize = threads
		ThreadPool = TThreadPoolExecutor.newFixedThreadPool( ThreadPoolSize )
    End Method

    Method run:Int()
'DebugStop
        ' Open StandardIn
        StdIn = ReadStream( StandardIOStream )
        If Not StdIn
            Publish( "log", "CRIT", "Failed to open StdIN" )
            Return 1
        End If

        ' Start threads
        Receiver = CreateThread( ReceiverThread, Self )
        Sender = CreateThread( SenderThread, Self )
        'ThreadPool = TThreadPoolExecutor.newFixedThreadPool( ThreadPoolSize )
'DebugStop
        ' Start Message Loop
        Repeat
            ' Fill thread pool
            While ThreadPool.threadsWorking < ThreadPool.maxThreads            
                ' Get next task
                Local task:TMessage = queue.getNextTask()
                If Not task Exit
                ' Process the event handler
                ThreadPool.execute( New TRunnableTask( task, self ) )
            Wend
            Delay(100)
        Until quit

        ' Clean up and exit gracefully
        Publish( "quit", "DEBG", "Closing threads" )
        AtomicSwap( QuitReceiver, False )
        WaitThread( Receiver )
        AtomicSwap( QuitSender, False )
        WaitThread( Sender )
        ThreadPool.shutdown()
        '
        Publish( "log", "DEBG", "Exit Gracefully" )
        Return exitcode
    End Method
    
    ' Observations
    Method Notify( event:String, data:Object, extra:Object )
    '    Select event
    '    Case "receive"
    '        MessageReceiver( string( data ) )
    '    case "send"
    '        MessageSender( string( data ) )
    '    End Select
    End Method

    ' Read messages from the client
    Method getRequest:String()
        Local line:String   ', char:String
        Local content:String
        Local contentlength:Int
		Local contenttype:String = "utf-8"

        'Publish( "log", "DEBG", "STDIO.GetRequest()")
        ' Read messages from StdIN
        Repeat
            line = stdIn.ReadLine()
            If line.startswith("Content-Length:")
                contentlength = Int( line[15..] )
                'Publish( "log", "DEBG", "Content-Length:"+contentlength)
            ElseIf line.startswith("Content-Type:")
                contenttype = Int( line[13..] )
                ' Backward compatibility, utf8 is no longer supported
                If contenttype = "utf8" contenttype = "utf-8"
                'Publish( "log", "DEBG", "Content-Type:"+contenttype)
            ElseIf line=""
                'Publish( "log", "DEBG", "WAITING FOR CONTENT...")
                content = stdIN.ReadString$( contentlength )
                Publish( "log", "DEBG", "Received "+contentlength+" bytes:~n"+content )
                Return content
            Else
                Publish( "log", "DEBG", "Skipping: "+line )
            End If
        Until quit
    End Method

End Type

Function Response_Error:String( code:String, message:String )
    Publish( "log", "ERRR", message )
    Local response:JNode = JSON.Create()
    response.set( "id", "null" )
    response.set( "jsonrpc", "2.0" )
    response.set( "error", [["code",code],["message","~q"+message+"~q"]] )
    Return response.stringify()
End Function

'   Worker Thread
Type TRunnableTask Extends TRunnable
    Field handler:TMessage
    Field lsp:TLSP
    Method New( handler:TMessage, lsp:TLSP )
        Self.handler = handler
        self.lsp = lsp
    End Method
    Method run()
        If not handler return
        local response:string = handler.run()
        ' Send 
        'Publish( "log", "DEBG", "Pushing response "+response )
        Publish( "sendmessage", response )
        'lsp.queue.pushSendQueue( response )
        ' Close the request as complete
        handler.state = STATE_COMPLETE
    End Method
End Type

'   Run the Application
Publish( "log", "DEBG", "Starting LSP..." )

Try
    LSP = New TLSP_Stdio( Int(CONFIG["threadpool"]) )
    exit_( LSP.run() )
Catch exception:String
    Publish( "log", "CRIT", exception )
End Try
