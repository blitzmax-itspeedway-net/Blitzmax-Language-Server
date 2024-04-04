SuperStrict

'   TaskQueue Service for BlitzMax Language Server
'   (c) Copyright Si Dunford, JAN 2023, All Rights Reserved. 
'   VERSION: 1.0

Rem 
The Task Queue Service is an essential service that manages tasks as they are created 
and added for execution.

Each task that is added has some important properties that identify how and when it 
should be executed.

	priority	where to insert the task in the current queue
	threaded	run it as blocking or threaded
	unique		drop the task if another with the same name exists (name is required)

Some tasks can be cancelled and these require an ID

End Rem

Import bmx.observer
Import bmx.json

Import "messages.bmx"
Import "tasks.bmx"
Import "trace.bmx"

Observer.threaded()
Service_TaskQueue.initialise()

Type Service_TaskQueue Implements IObserver

	Global instance:Service_TaskQueue = Null

	Private
	
	Const SLEEP_DURATION:Int = 5000		' How long the thread sleeps between messages (ms)
	Const MAX_THREADS:Int = 4			' Maximum number of threads
	
	Field quitflag:Int		= False
	Field queue:TList		= Null	' The message queue
	Field mutex:TMutex		= Null	
	Field sleep:TCondVar	= Null
	Field thread:TThread	= Null	' The message queue thread
	
	Field poolsize:Int = 4
	Field threadpool:TSemaphore

	Protected
	
	Function initialise()
		If Not instance; instance = New Service_TaskQueue()
	End Function
		
	Public
	
	' Start Thread
	Function start()
		If Not instance; Throw( "Failed to start TaskQueue" )
		instance.thread	= CreateThread( Executor, instance )	
	End Function
		
	Method New()
		quitflag = False 
		queue = New TList()
		mutex = CreateMutex()
		sleep = CreateCondVar()
		threadpool = CreateSemaphore( poolsize )
		
		' Add observer events
		Observer.on( EV_TASK_ADD, Self )
		Observer.on( EV_TASK_CANCEL, Self )

	End Method
	
	' Adds a task to the task queue
'	Function add( task:TTask, unique:Int = False )
'		If Not instance; Start()
'		If Not task; Return
'		task.unique = unique
'		instance.addtask( task )
'	End Function 
	
'	Function Stop()
'		If Not instance; Return
'		If instance.quitflag ; Return	' Only do this once!
'		instance.quitFlag = True		' Set the quit flag
'		instance.sleep.signal()			' wake the sleeping thread
'		WaitThread( instance.thread )	' wait until thread finished
'	End Function 
	
'	Function cancel( ID:String )
'		If Not instance; Start()
'		instance.cancelTask( ID )
'	End Function
	
'	Function size:Int()
'		If Not instance; Start()
'		LockMutex( instance.mutex )
'		Local count:Int = instance.queue.count()
'		UnlockMutex( instance.mutex )
'		Return count
'	End Function
	
'	Function pop:TTask()
'		LockMutex( instance.mutex )
'		Local task:TTask = TTask( instance.queue.removeFirst() )
''		UnlockMutex( instance.mutex )
'	'	Return task
'	End Function

	Method debug:Int[]()
		Local result:Int[1]
		LockMutex( mutex )
		result[0] = queue.count()
		UnlockMutex( mutex )
		Return result
	End Method
		
	Method Observe( id:Int, data:Object )
		
		Select id
		Case EV_TASK_ADD
			Local task:TTask = TTask( data )
			If task; addtask( task )
		Case EV_TASK_CANCEL
			Local ID:String = String( data )
			If ID; canceltask( ID )
		End Select
		
	End Method
	
	Private
	
	' PRIORITY QUEUE
	Method addtask( task:TTask )
	
		LockMutex( mutex )
		
		' Check for unique task name
		If task.unique
			For Local t:TTask = EachIn queue
				If task.name = t.name; Return
			Next
		End If
	
		' Find where to insert task
		Local link:TLink = queue.lastlink()
		'DebugStop
		While link 
			'DebugStop
			Local item:TTask = TTask( link.value() )
			' Check Priority
			If item.priority<=task.priority
				Trace.debug( "TTaskQueue: Inserting "+task.name+", Priority "+task.priority )
				queue.insertAfterLink( task, link )
				UnlockMutex( mutex )
				sleep.signal()			' Wake the sleeping thread
				Return
			EndIf
			link = link.prevLink()
		Wend
'DebugStop
		' Queue is empty, or task goes at top...
		Trace.debug( "TTaskQueue: Inserting "+task.name+", Priority "+task.priority )
		queue.addFirst( task )
		UnlockMutex( mutex )
		sleep.signal()			' Wake the sleeping thread	
	End Method
	
	Method cancelTask( ID:String )
		If Not ID; Return
		'DebugStop
		LockMutex( mutex )
		For Local task:TTask = EachIn queue
			If task.id = ID
				queue.remove( task )
				Exit
			End If
		Next
		UnlockMutex( mutex )	
	End Method
	
	' This is the task queue thread
	' The thread goes to sleep when the queue is empty and when it awakes
	' it pops a task and runs it.
	' When the task completes, the thread goes back to sleep.
	' NOTE: If the task is threaded, it will launch that thread and will not wait.
	
	Function Executor:Object( data:Object )
		Local this:Service_TaskQueue = Service_TaskQueue( data )
		If Not this ; Return Null
		'
		'Local running:Int = True
		Local wait:TMutex = CreateMutex()
		LockMutex( wait )
		
		Trace.debug( "Task Executor Starting" )
		Repeat
		
			' Wait for an available semaphore
			Trace.debug( "Task Executor is waiting" )
			this.threadpool.wait()
		
			LockMutex( this.mutex )
			Local task:TTask = TTask( this.queue.removeFirst() )
			Local Empty:Int = this.queue.isEmpty()
			UnlockMutex( this.mutex )
			
			If task
				Trace.debug( "Task Executor running "+task.name+" ("+( ["BLOCKING","THREADED"][task.threaded] )+")" )
				task.start( this.threadpool )
				Trace.debug( "Task Executor finished "+task.name )
			End If
			
			If Empty
				Trace.debug( "Task Executor going to sleep" )
				this.sleep.wait( wait )
				Trace.debug( "Task Executor is awake" )
			EndIf

		Forever
	End Function

End Type
