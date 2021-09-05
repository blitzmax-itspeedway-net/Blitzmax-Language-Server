
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, July 2021, All Right Reserved

Include "TLSP_Stdio.bmx"
Include "TLSP_TCP.bmx"

Global LSP:TLSP

' This will be based on arguments in the future, but for now we only support STDIO
LSP = New TLSP_StdIO()

Type TLSP Extends TObserver
    Global instance:TLSP

    Field exitcode:Int = 0

	Field initialized:Int = False   	' Set by "iniialized" message
    Field shutdown:Int = False      	' Set by "shutdown" message
	Field setTrace:String = "off"		' Set by $/setTrace
	
    'Field client:TClient = New TClient()		' Moved to a global

	' Create a document manager
	'Field textDocument:TTextDocument_Handler	' Do not initialise here: Depends on lsp.

    ' Threads
    Field QuitMain:Int = True       ' Atomic State - Set by "exit" message

    Field Receiver:TThread
    Field QuitReceiver:Int = True   ' Atomic State

    Field Sender:TThread
    Field QuitSender:Int = True     ' Atomic State

    Field ThreadPool:TThreadPoolExecutor
    Field ThreadPoolSize:Int
    Field sendMutex:TMutex = CreateMutex()

    
	' System
	Field capabilities:JSON = New JSON()	' Empty object
	Field handlers:TMap = New TMap
	
    Method run:Int() Abstract
    Method getRequest:String() Abstract     ' Waits for a message from client

    Method Close() ; End Method

	'V0.0
    Function ExitProcedure()
        'Publish( "debug", "Exit Procedure running" )
        Publish( "exitnow" )
        instance.Close()
        'Logfile.Close()
    End Function

	'V0.1
    ' Thread based message receiver
    Function ReceiverThread:Object( data:Object )
        Local lsp:TLSP = TLSP( data )
        Local quit:Int = False     ' Local loop state

        ' Read messages from Language Client
        Repeat

            Local node:JSON
                       
            ' Get inbound message from Language Client
            Local content:String = lsp.getRequest()

            ' Parse message into a JSON object
			'Publish( "debug", "Parse starting" )
            Local J:JSON = JSON.Parse( content )
			'Publish( "debug", "Parse finished" )
            ' Report an error to the Client using stdOut
            If Not J Or J.isInvalid()
				Local errtext:String
				If J.isInvalid()
					errtext = "ERROR("+J.errNum+") "+J.errText+" at {"+J.errLine+","+J.errpos+"}"
				Else
					errtext = "ERROR: Parse returned null"
				End If
                ' Send error message to LSP Client
				Publish( "debug", errtext )
                Publish( "send", Response_Error( ERR_PARSE_ERROR, errtext ) )
                Continue
            End If
			'Publish( "debug", "Parse successful" )
			
            ' Debugging
            'Local debug:String = JSON.stringify(J)
            'logfile.write( "STRINGIFY:" )
            'logfile.write( "  "+debug )

			' V0.3 Event Creation
			New TMessage( "RECEIVE-FROM-CLIENT", J ).emit()		' Send Message Received event	
   
Rem V0.2 depreciated
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
                
            ' Transpose JNode into Blitzmax Object
            Local request:TMessage
            Try
                Local typestr:String = "TMethod_"+methd
                typestr = typestr.Replace( "/", "_" )
                typestr = typestr.Replace( "$", "dollar" ) ' Protocol Implementation Dependent
                'Publish( "log", "DEBG", "BMX METHOD: "+typestr )
                ' Transpose RPC
                request = TMessage( J.transpose( typestr ))
				' V0.2 - This is no longer a failure as we may have a handler
                'If Not request
                '    Publish( "log", "DEBG", "Transpose to '"+typestr+"' failed")
                '    Publish( "send", Response_Error( ERR_METHOD_NOT_FOUND, "Method is not available" ))
                '    Continue
                'Else
                '    ' Save JNode into message
                '    request.J = J
                'End If
				' V0.2, Save the original J node
				If request 
                    request.J = J
                    Publish( "debug", "Transposed successfully" )
                End If
                'If Not request Publish( "debug", "Transpose to '"+typestr+"' failed")
            Catch exception:String
                Publish( "send", Response_Error( ERR_INTERNAL_ERROR, exception ))
            End Try

			' V0.2
			' If Transpose fails, then all is not lost
			If Not request
				Publish( "debug", "Creating V0.2 message object")
				request = New TMessage( methd, J )
			End If
    
            ' A Request is pushed to the task queue
            ' A Notification is executed now
            If request.contains( "id" )
                ' This is a request, add to queue
                Publish( "debug", "Pushing request to queue")
                Publish( "pushtask", request )
                'lsp.queue.pushTaskQueue( request )
                Continue
            Else
                ' This is a Notification, execute it now and throw away any response
                Try
                    Publish( "debug", "Notification "+methd+" starting" )
                    request.run()
                    Publish( "debug", "Notification "+methd+" completed" )
                Catch exception:String
                    Publish( "send", Response_Error( ERR_INTERNAL_ERROR, exception ))    
                End Try
            End If
EndRem
        Until CompareAndSwap( lsp.QuitReceiver, quit, True )
        'Publish( "debug", "ReceiverThread - Exit" )
    End Function

	'V0.1
    ' Thread based message sender
    Function SenderThread:Object( data:Object )
        Local lsp:TLSP = TLSP( data )
        Local quit:Int = False          ' Always got to know when to quit!
        
        'DebugLog( "SenderThread()" )
        Repeat
            Try
                Publish( "debug", "TLSP.SenderThread going to sleep")
                WaitSemaphore( client.sendcounter )
                Publish( "debug", "TLSP.SenderThread is awake" )
                ' Create a Response from message
                Local content:String = client.popSendQueue()
                'Publish( "log", "DEBG", "Sending '"+content+"'" )
                If content<>""  ' Only returns "" when thread exiting
                    Local response:String = "Content-Length: "+Len(content)+EOL
                    response :+ EOL
                    response :+ content
                    ' Log the response
                    'Publish( "log", "DEBG", "Sending:~n"+response )
                    ' Send to client
                    LockMutex( lsp.sendMutex )
                    StandardIOStream.WriteString( response )
                    StandardIOStream.Flush()
                    UnlockMutex( lsp.sendMutex )
                    'Publish( "debug", "Content sent" )
                End If
            Catch Exception:String 
                'DebugLog( Exception )
                Publish( "log", "CRIT", Exception )
            End Try
        Until CompareAndSwap( lsp.QuitSender, quit, True )
        Publish( "debug", "SenderThread - Exit" )
    End Function  


	'V0.2
	' Add a Capability
	'Method addCapability( capability:String )
	'	capabilities :+ [capability]
	'End Method	

	'V0.2
	' Retrieve all registered capabilities
	'Method getCapabilities:String[][]()
	'	Local result:String[][]
	'	For Local capability:String = EachIn capabilities
	'		result :+ [[capability,"true"]]
	'	Next
	'	Return result
	'End Method

Rem 31/8/21 Depreciated
	'V0.2
	' Add Message Handler
	Method addHandler( handler:TMessageHandler, events:String[] )
		For Local event:String = EachIn events
			handlers.insert( event, handler )
		Next
	End Method

	'V0.2
	' Get a Message Handler
	Method getMessageHandler:TMessageHandler( methd:String )
		Return TMessageHandler( handlers.valueForkey( methd ) )
	End Method
EndRem

	'	V0.3 EVENT HANDLERS
	'	WE MUST RETURN MESSAGE IF WE DO NOT HANDLE IT
	'	RETURN NULL WHEN MESSAGE HANDLED OR ERROR HANDLED
	
	Method onExit:TMessage( message:TMessage )
		publish( "log", "DBG", "EVENT onExit()" )
		' QUIT MAIN LOOP
        AtomicSwap( QuitMain, False )
		message.state = STATE_COMPLETE
		'Return null
	End Method
	
	Method onInitialized:TMessage( message:TMessage )
		publish( "log", "DBG", "EVENT onInitialized()" )
		client.send( Response_Ok( message.getid() ) )
		'
		message.state = STATE_COMPLETE
		
		' Register for configuration changes
		client.RegisterForConfigChanges()
		
		Return Null
	End Method 

	Method onShutdown:TMessage( message:TMessage )
		publish( "log", "DBG", "EVENT onShutdown()" )
		shutdown = True

		' Send response to Client
        Local response:JSON = New JSON()
        response.set( "id", message.getid() )
        response.set( "jsonrpc", JSONRPC )
        response.set( "result", "null" )
		client.send( response )
		'
		message.state = STATE_COMPLETE
        'Return Null
	End Method
	
	' Trace notifications
	Method OnSetTraceNotification:TMessage( message:TMessage )
		publish( "log", "DBG", "EVENT onSetTraceNotification()" )
		' Set our value to match params:
		Local J:JSON = message.J.find( "params|value" )
		If J 
			Publish( "log","DBG", J.prettify() )
			setTrace = J.toString()
		End If
		' This is a notification, so we dont need a reply.
		'Return Null
	End Method
End Type