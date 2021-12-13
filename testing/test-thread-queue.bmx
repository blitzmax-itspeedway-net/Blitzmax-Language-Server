SuperStrict

Type TTaskQueue

	Field queue:TList
	Field thread:TThread
	Field mutex:TMutex
	Field quitflag:Int
	Field sleep:TCondVar
	
	Method New()
		queue = New TList()
		mutex = CreateMutex()
		sleep = CreateCondVar()
		quitflag = False 
		thread = CreateThread( ThreadFunction, Self )
	End Method
	
	Method push( task:TTask, unique:String = "" )
		If Not task ; Return
		If unique<>"" ; task.unique = True
		'
		LockMutex( mutex )
		'
		' PRIORITY QUEUE (12/11/21)
		Local link:TLink = queue.lastlink()
		While link 
			Local item:TTask = TTask( link.value )
			' Check Uniqueness
			If task.unique And task.name=item.name
				Print( "TTaskQueue: Unique task already exists "+task.name )
				' Task already exists with this name and identifier, so drop it.
				UnlockMutex( mutex )
				sleep.signal()			' Wake the sleeping thread
				Return				
			End If
			' Check Priority
			If item.priority<=task.priority
				Print( "TTaskQueue: Inserting "+task.name+", Priority "+task.priority )
				queue.insertAfterLink( task, link )
				UnlockMutex( mutex )
				sleep.signal()			' Wake the sleeping thread
				Return
			EndIf
			link = link.prevLink
		Wend
		' Queue is empty, or task goes at top...
		Print( "TTaskQueue: Inserting "+task.name+", Priority "+task.priority )
		queue.addFirst( task )
		UnlockMutex( mutex )
		sleep.signal()			' Wake the sleeping thread
	End Method
	
	Method Close()
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
		Print "TQueue Thread Starting"
		Repeat
			LockMutex( this.mutex )
			Local task:TTask = TTask( this.queue.removeFirst() )
			UnlockMutex( this.mutex )
			If task ; task.run()

			If this.queue.isEmpty()
				Print "TQueue Thread sleeping"
				this.sleep.timedWait( wait, 5000 ) 
				Print "TQueue Thread awake"
			End If
			
		Until CompareAndSwap( this.quitflag, running, False ) 
		Print "TQueue Thread Exiting"
		'UnlockMutex( wait )
	End Function

End Type

Type TTask

	Const BLOCKING:Int = 0
	Const THREADING:Int = 1

	Field operation:Int = BLOCKING
	Field thread:TThread

	Field name:String			' Optional task name (Used by Priority Queue when "unique is TRUE")
	Field priority:Int = 3		' Used by Priority Queue
	Field unique:Int = False	

	Method New( name:String, operation:Int )
		Self.name = name
		Self.operation = operation
		Print( "TASK "+name+" CREATED" )
	End Method

	Method run() Final
		Select operation
		Case BLOCKING
			launch()
		Case THREADING
			thread = CreateThread( Launcher, Self )
			DetachThread( thread )
		End Select
	End Method

	Method launch() Abstract
	
	Function Launcher:Object( data:Object )
		Local this:TTask = TTask( data )
		If Not this ; Return Null
		this.launch()
	End Function
	
End Type

Type TBlockingTask Extends TTask

	Method New( name:String )
		Super.New( name, BLOCKING )
	End Method
	
	Method Launch()
		Print( "BLOCKING TASK "+name+" LAUNCHED" )
		Delay( 7000 )
		Print( "BLOCKING TASK "+name+" FINISHED" )		
	End Method
	
End Type

Type TThreadedTask Extends TTask

	Method New( name:Int )
		Super.New( name, THREADING )
	End Method

	Method Launch()
		Print( "THREADED TASK "+name+" LAUNCHED" )
		Delay( 7000 )
		Print( "THREADED TASK "+name+" FINISHED" )		
	End Method
	
End Type

Graphics 800,600

Local queue:TTaskQueue = New TTaskQueue()
Local counter:Int = 0

Repeat
	Cls
	DrawText( "0 - Create Threaded Task", 0,0 )
	DrawText( "1 - Create Blocking Task", 0,15 )
	If KeyHit( KEY_0 )
		counter :+ 1
		queue.push( New TThreadedTask( counter ) )
	End If
	If KeyHit( KEY_1 )
		counter :+ 1
		queue.push( New TBlockingTask( counter ) )
	End If
	
	Flip
Until AppTerminate()

Print "CLOSING"
queue.Close()
Print "FINISHED"



