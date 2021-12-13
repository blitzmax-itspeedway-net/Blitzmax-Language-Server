
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

' Task Identifiers
Const TASK_PARSE:Int = 1

Rem UNIQUE TASKS

	PRIORITY 1 is HIGHEST, 5 is LOWEST

	A unique task is a task with an identifier and a subject.
	They are added to the queue using the unique value of TRUE which inserts them only if
	there is not another task with the same identifier and subject
	
	This is useful because when we need to parse a document we can add a Unique:Parse:URI task
	and the queue will only add one if there is not already one in the queue.
	
	The advantage of this is that ONCHANGE events are added to the queue. The handler for onchange knows
	that the AST and the diagnostcs beed to be updated, so adds a task for each.
	The queue continues to process onchange events and only when there are no more, does it move onto the
	parse task of which it will find only 1. We dont need to parse after every keypress.

End Rem

Type TTask

	Const BLOCKING:Int = 0
	Const THREADING:Int = 1

	Field priority:Int = 3		' Used by Priority Queue
	Field unique:Int = False
	
	Field name:String			' Optional task name (Used by Priority Queue when "unique is TRUE")
'	Field complete:Int = False	' Optional completion status

	' Blocking and Threaded task options
	Field operation:Int = BLOCKING
	Field thread:TThread
	
	Method New( operation:Int )
		Self.operation = operation
	End Method
	
	' Revision 1
	Method execute() 
		logfile.debug( "TTASK.EXECUTE() IS DEPRECIATED - " + name )
	End Method

	Method postv1()
		logfile.debug( "TTASK.POSTV1() IS DEPRECIATED - " + name )
		client.pushTaskQueue( Self )
	End Method

	' 12 December 21
	Method run() Final
		Select operation
		Case BLOCKING
			launch()
		Case THREADING
			thread = CreateThread( Launcher, Self )
			DetachThread( thread )
		End Select
	End Method

	' Custom Tasks implement this method
	Method launch() Abstract

	' Post message to Task Queue
	Method post( unique:Int = False )
		taskQueue.push( Self, unique )
	End Method
	
	' Threaded launcher
	Function Launcher:Object( data:Object )
		Local this:TTask = TTask( data )
		If Not this ; Return Null
		this.launch()
	End Function

	' This method recieves responses from client if you send any requests within the task
	' Used for progress bars and Request/Response tasks
	Method response( message:TMessage ) ; End Method
	
End Type

Rem commented out 9/12/21, SJD
Type TTestTask Extends TTask

	Method New()
		name = "TASKTASK"
		priority = 5
	End Method

	Method execute()
		logfile.debug( "TEST TASK RAN SUCCESSFULLY" )
	End Method
	
End Type
End Rem

Rem EXAMPLE ON CREATING A THREADED OR BLOCKING TASK

Type TBlockingTask Extends TTask

	Method New()
		Super.New( BLOCKING )
	End Method
	
	Method Launch()
		Print( "BLOCKING TASK "+id+" LAUNCHED" )
		Delay( 7000 )
		Print( "BLOCKING TASK "+id+" FINISHED" )		
	End Method
	
End Type

Type TThreadedTask Extends TTask

	Method New()
		Super.New( THREADING )
	End Method

	Method Launch()
		Print( "THREADED TASK "+id+" LAUNCHED" )
		Delay( 7000 )
		Print( "THREADED TASK "+id+" FINISHED" )		
	End Method
	
End Type

END REM