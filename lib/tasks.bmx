SuperStrict

'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

Import brl.threads

' Task Identifiers
'Const TASK_PARSE:Int = 1

'Import "application.bmx"
'Import "messages.bmx"

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

Type TTaskdata
	Field threadpool:TSemaphore
	Field task:TTask
	
	Method New( task:TTask, threadpool:TSemaphore )
		Self.threadpool = threadpool
		Self.task = task
	End Method
	
End Type

Type TTask

	Public
	'Protected

	Field name:String			' Optional task name (Used by Priority Queue when "unique is TRUE")
	Field id:String				' Optional task ID (Used by Cancel() )

	Field priority:Int = 3		' Used by Priority Queue
	Field unique:Int = False
	Field threaded:Int = True	' Threaded by default
	
'	Field complete:Int = False	' Optional completion status

	Private
	
	' Blocking and Threaded task options
	Field thread:TThread
	
	Public	
	
	Method New( threaded:Int = False )
		Self.threaded = threaded
	End Method

	' 12 December 21
	Method start( threadpool:TSemaphore ) Final
		If threaded
			Local data:TTaskData = New TTaskData( Self, threadpool )
			thread = CreateThread( Launcher, data )
			DetachThread( thread )
		Else
			Run()
			threadpool.post()
		End If
	End Method
	
	' Custom Tasks implement this method
	Method Run() Abstract
	
	' Threaded task launcher
	Function Launcher:Object( data:Object )
		Local this:TTaskData = TTaskData( data )
		If Not this ; Return Null
		this.task.Run()
		this.threadpool.post()
	End Function
	
End Type

Rem
Type TMessageTask Extends TTask

	Field methd:String
	'Field params:JSON	' Request
	'Field result:JSON	' Result (typically in response to server request)
	
	Field message:TMessage
	
End Type

Type TTask_Request Extends TMessageTask
	
	Method New( message:TLSPMessage )
		Self.message = message

		id    = message.id
		methd = message.methd
		name  = message.name
		
		' Message data contains the request in JSON
'		If message.params; params = request.data.find( "params" )
	End Method

	Method run()
	
		Trace.info( "Task "+name+": Starting" )
		Application.handle( message )
		Trace.info( "Task "+name+": Completed" )
	
		' Confirm that a message response has been sent
		
		If 
	
	End Method
	
End Type

Type TTask_Response Extends TMessageTask

	
	Method New( request:TServerRequest, response:TLSPMessage )
		id    = request.id
		methd = request.methd
		name  = request.name
		
		' Message data contains the request/response in JSON
		If request.data; params = request.data.find( "params" )
		If response.data; result = response.data.find( "result" )
		
	End Method

	Method run()
	
		Trace.info( "Task "+name+": Starting" )
		Application.handle( message )
		Trace.info( "Task "+name+": Completed" )

		' No response required
	
	End Method
	
End Type

Type TTask_Notification Extends TMessageTask
	
	Method New( notification:TLSPMessage )
		'id    = message.name
		methd = notification.methd
		name  = notification.name
		
		' Message data contains the request in JSON
		If notification.data; params = notification.data.find( "params" )
	End Method

	Method run()
	
		Trace.info( "Task "+name+": Starting" )
		Application.handle( message )
		Trace.info( "Task "+name+": Completed" )

		' No response required	
	End Method
	
End Type
end rem