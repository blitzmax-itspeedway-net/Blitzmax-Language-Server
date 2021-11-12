SuperStrict

Global taskqueue:TList = New TList()

Type TTask
	Field priority:Int = 3
	Field name:String
	
	Method New( name:String )
	Self.name = name
	End Method

	Method New( name:String, priority:Int )
	Self.priority = priority
	Self.name = name
	End Method
	
End Type

Function add( task:TTask )
	If Not task Return
	add( task, task.priority )
End Function

Function add( task:TTask, priority:Int )
	If Not task Return
	task.priority = priority
	Local link:TLink = taskqueue.lastlink()
	While link 
		Local item:TTask = TTask( link.value )
		If item.priority<=priority
			taskqueue.insertAfterLink( task, link )
			Return
		EndIf
		link = link.prevLink
	Wend
	taskqueue.addFirst( task )
End Function

Function show()
	For Local task:TTask = EachIn taskqueue
		Print task.priority+" "+task.name
	Next
End Function

DebugStop
add( New TTask( "A" ) )
add( New TTask( "B" ) )
add( New TTask( "C" ) )
add( New TTask( "C#", 1 ) )
add( New TTask( "D" ) )
add( New TTask( "E" ),4 )
add( New TTask( "F" ) )
add( New TTask( "F#" ),2 )
add( New TTask( "G" ) )
add( New TTask( "H" ) )
show()