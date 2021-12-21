
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	Creates a threaded message receiver that posts to the Task queue

Type TTaskReceiver Extends TTask

	Field parent:TClient = Null
	Field sleeper:TMutex = Null			' Lock used while task is running
	Field sleep:TCondVar = Null			' Thread sleeper

	Method New( parent:TClient )
		Super.New( THREADED )
		logfile.debug( "TTaskReceiver.new()" )
		name        = "Receiver"	
		priority    = QUEUE_PRIORITY_HIGH	
		sleeper     = CreateMutex()	
		sleep 		= CreateCondVar()
		Self.parent = parent
	End Method
	
	Method launch()
		logfile.debug( "## TTaskReceiver - STARTED" )
		
		Local running:Int = True    ' Local loop state
		
		Repeat
			' Get inbound message from Language Client
            'Local content:String = client.getRequest()
'DebugLog( "TTaskReceiver - Reading client" )
            Local content:String = client.read()
'DebugLog( "TTaskReceiver - content received" )

            ' Parse message into a JSON object
            Local J:JSON = JSON.Parse( content )

            ' Report an error to the Client using stdOut
            If Not J Or J.isInvalid()
				Local errtext:String
				logfile.error( content )
				If J.isInvalid()
					errtext = "ERROR("+J.errNum+") "+J.errText+" at {"+J.errLine+","+J.errpos+"}"
				Else
					errtext = "ERROR: Parse returned null"
				End If
                ' Send error message to LSP Client
				logfile.debug( errtext )
                Continue
            End If

			' J is message freshly arrived from IDE

			Local message:TMessage = New TMessage( J )
			Local methd:String = message.methd

			logfile.debug( "- ID:      "+message.id )
			logfile.debug( "- METHOD:  "+message.methd )
			logfile.debug( "- CLASS:   "+message.classname() )
		
			Select message.class
			Case TMessage._REQUEST
			
				' Check server has initialised
				Select True
				Case lsp.state = lsp.STATE_INITIALISED And methd="initialize"
					logfile.critical( "## Server already initialized~n"+J.stringify() )
					lsp.send( Response_Error( ERR_INVALID_REQUEST, "Server already initialized", message.id ) )
					Continue
				Case lsp.state <> lsp.STATE_INITIALISED And methd<>"initialize"
					logfile.critical( "## Server is not initialized~n"+J.stringify() )
					lsp.send( Response_Error( ERR_SERVER_NOT_INITIALIZED, "Server is not initialized", message.id ))
					Continue
				End Select
				
				' Add message to queue
				message.priority = QUEUE_PRIORITY_REQUEST
				message.post()
				
			Case TMessage._RESPONSE

				' Match with a Request
				Local request:TServerRequest = lsp.matchResponseToRequest( message.id )
				
				If request
					logfile.debug( "RESPONSE MATCHED TO~n"+request.J.prettify() )

					' Update the ServerRequest with Response
					request.addResponse( J )

					' Post the ServerRequest containing a response to the TaskQueue
					request.priority = QUEUE_PRIORITY_RESPONSE
					request.post()
				Else
					logfile.debug( "# REPONSE NOT MATCHED TO REQUEST" )
				End If
								
			Case TMessage._NOTIFICATION
			
				' Add message to queue
				message.priority = QUEUE_PRIORITY_NOTIFICATION
				message.post()
				
			Default
				logfile.critical( "## Invalid message~n"+J.Stringify() )
'DebugStop
				Continue
			End Select		
		Until CompareAndSwap( parent.quitflag, running, False )
		sleep.Signal()			' Wake the Task (see wait() method)
		logfile.debug( "## TTaskReceiver - FINISHED" )
	End Method

	' Block until launch() completes
	Method wait()
		sleeper.lock()			' Lock the receiver until finished
		sleep.wait(sleeper)		' Wait until condvar is awoken
	End Method

End Type

