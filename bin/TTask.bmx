
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
	Field priority:Int = 3		' Used by Priority Queue
	Field identifier:Int = 0	' Used by Priority Queue when "unique is TRUE"
	Field subject:String		' Used by Priority Queue when "unique is TRUE"
	
	Field name:String			' Optional task name
	Field complete:Int = False	' Optional completion status
	
	Method execute() Abstract

End Type

Type TTestTask Extends TTask

	Method New()
		name = "TASKTASK"
		priority = 5
	End Method

	Method execute()
		logfile.debug( "TEST TASK RAN SUCCESSFULLY" )
	End Method
	
End Type