
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, July 2021, All Right Reserved

' StdIO based LSP
Type TLSP_Stdio Extends TLanguageServer
	Field StdIn:TStream

    Method New( threads:Int = 4 )
        'Publish( "info", "LSP for BlitzMax NG" )
        'Publish( "info", "V"+Version+"."+build )
        'Log.write( "Initialised")
        ' Set up instance and exit function
        instance = Self
        OnEnd( TLanguageServer.ExitProcedure )
        ' Debugstop
        ThreadPoolSize = threads
		ThreadPool = TThreadPoolExecutor.newFixedThreadPool( ThreadPoolSize )
        '
        ' Observations
        'Subscribe( [""] )
    End Method

    Method run:Int()
		'textDocument = New TTextDocument_Handler

        Local quit:Int = False     ' Local loop state

		' V0.3, Start event listener
		'listen()

        ' Open StandardIn
        StdIn = ReadStream( StandardIOStream )
        If Not StdIn
            logfile.critical( "Failed To open StdIN" )
            Return 1
        End If

        ' Start threads
        Receiver = CreateThread( ReceiverThread, Self )
        Sender = CreateThread( SenderThread, Self )
		
        'ThreadPool = TThreadPoolExecutor.newFixedThreadPool( ThreadPoolSize )
'DebugStop
        ' Start Message Loop
		'Local this:TMessage
        Repeat

			Rem 31/8/21, Depreciated the ThreadPool
            ' Fill thread pool
            While ThreadPool.threadsWorking < ThreadPool.maxThreads            
                ' Get next task from queue
				'Local task:TMessage = queue.getNextTask()
				Local task:TMSG = queue.getNextTask()
				If Not task Exit
				' Process the event handler
				ThreadPool.execute( New TRunnableTask( task, Self ) )
            Wend
			EndRem
			
			' Get the next task
			'Local message:TMessage = client.popTaskQueue()
			Local task:TTask = client.popTaskQueue()
			
			' Message is only returned if it needs to be emitted (Launched)
			If task ; task.execute()	'.send()
			
            Delay(100)
        'Until endprocess
        Until CompareAndSwap( lsp.QuitMain, quit, True )
        logfile.debug( "Mainloop - Exit" )
        
        ' Clean up and exit gracefully
        AtomicSwap( QuitReceiver, False )   ' Inform thread it must exit
        DetachThread( Receiver )
        logfile.debug( "Receiver thread closed" )

        AtomicSwap( QuitSender, False )     ' Inform thread it must exit
        'PostSemaphore( queue.sendCounter )  ' Wake the thread from it's slumber
        DetachThread( Sender )
        logfile.debug( "Sender thread closed" )

		' Close the workspaces
        Workspaces.shutdown()

        ThreadPool.shutdown()
        logfile.debug( "Worker thread pool closed" )

		' V0.3, Stop event listener
		'unlisten()
		client.Close()

        Return exitcode
    End Method
    
    ' Observations
' DEPRECIATED 25/10/21
'    Method Notify( event:String, data:Object, extra:Object )
    '    Select event
    '    Case "receive"
    '        MessageReceiver( string( data ) )
    '    case "send"
    '        MessageSender( string( data ) )
    '    End Select
'    End Method

    ' Read messages from the client
    Method getRequest:String()
        Local quit:Int = False     ' Local loop state
        Local line:String   ', char:String
        Local content:String
        Local contentlength:Int
		Local contenttype:String = "utf-8"

        'Publish( "log", "DEBG", "STDIO.GetRequest()")
        ' Read messages from StdIN
        Repeat
            Try
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
                    'Publish( "log", "DEBG", "Received "+contentlength+" bytes:~n"+content )
                    logfile.debug( "TLSP_Stdio.getRequest() received "+contentlength+" bytes" )
                    Return content
                Else
                    logfile.debug( "Skipping: "+line )
                End If
            Catch Exception:String
                logfile.critical( Exception )
            End Try
        'Until endprocess
        Until CompareAndSwap( lsp.QuitMain, quit, True )
    End Method

End Type
