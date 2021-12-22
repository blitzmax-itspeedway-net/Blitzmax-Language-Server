
'   LANGUAGE SERVER EXTENSION FOR BLITZMAX NG
'   (c) Copyright Si Dunford, Dec 2021, All Right Reserved

Type TTaskQueue

	Const SLEEP_DURATION:Int = 5000		' How long the thread sleeps between messages (ms)

	Field queue:TList = Null
	Field thread:TThread = Null
	Field mutex:TMutex = Null
	Field quitflag:Int
	Field sleep:TCondVar = Null
	
	Method New()
		queue = New TList()
		mutex = CreateMutex()
		sleep = CreateCondVar()
		quitflag = False 
		thread = CreateThread( ThreadFunction, Self )
	End Method
	
	Method push( task:TTask, unique:Int = False )
		If Not task ; Return
		task.unique = unique
		'
		LockMutex( mutex )
		'
		' PRIORITY QUEUE (12/11/21)
		Local link:TLink = queue.lastlink()
		While link 
			Local item:TTask = TTask( link.value )
			' Check Uniqueness
			If task.unique And task.name=item.name
				logfile.debug( "TTaskQueue: Unique task already exists "+task.name )
				' Task already exists with this name and identifier, so drop it.
				UnlockMutex( mutex )
				sleep.signal()			' Wake the sleeping thread
				Return				
			End If
			' Check Priority
			If item.priority<=task.priority
				logfile.debug( "TTaskQueue: Inserting "+task.name+", Priority "+task.priority )
				queue.insertAfterLink( task, link )
				UnlockMutex( mutex )
				sleep.signal()			' Wake the sleeping thread
				Return
			EndIf
			link = link.prevLink
		Wend
DebugStop
		' Queue is empty, or task goes at top...
		logfile.debug( "TTaskQueue: Inserting "+task.name+", Priority "+task.priority )
		queue.addFirst( task )
		UnlockMutex( mutex )
		sleep.signal()			' Wake the sleeping thread
	End Method
	
	Method stop()
		If quitflag ; Return	' Only do this once!
		quitFlag = True			' Set the quit flag
		sleep.signal()			' wake the sleeping thread
		WaitThread( thread )	' wait until thread finished
	End Method
	
	Function ThreadFunction:Object( data:Object )
		Local this:TTaskQueue = TTaskQueue( data )
		If Not this ; Return Null
		'
		Local running:Int = True
		Local wait:TMutex = CreateMutex()
		'
		LockMutex( wait )
		logfile.debug( "TTaskQueue Thread Starting" )
		Repeat
			LockMutex( this.mutex )
			Local task:TTask = TTask( this.queue.removeFirst() )
			UnlockMutex( this.mutex )
			If task ; task.run()

			If this.queue.isEmpty()
				'logfile.debug( "TTaskQueue Thread sleeping" )
				this.sleep.timedWait( wait, SLEEP_DURATION ) 
				'logfile.debug( "TTaskQueue Thread awake" )
			End If
			
		Until CompareAndSwap( this.quitflag, running, False ) 
		logfile.debug( "TTaskQueue Thread Exiting" )
		'UnlockMutex( wait )
	End Function

End Type

Rem HOW TO USE THE TASK QUEUE

Local queue:TTaskQueue = New TTaskQueue()

Repeat
	Cls

	If KeyHit( KEY_0 )
		queue.push( New TThreadedTask() )
	End If

	If KeyHit( KEY_1 )
		queue.push( New TBlockingTask() )
	End If
	
	Flip
Until AppTerminate()

Print "CLOSING"
queue.Close()
Print "FINISHED"

END REM