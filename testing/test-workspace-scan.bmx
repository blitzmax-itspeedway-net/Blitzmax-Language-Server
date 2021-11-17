SuperStrict

Import Text.regex
Import bmx.json

'Include "../bin/language-server-protocol.bmx"

'Type TASTErrorMessage
'End Type

Local start:Int, finish:Int

Local uri:TURI = New TURI( "file:///home/si/dev/Blitzmax-Language-Server/" )
Print uri.tostring()
Print uri.folder()

' Create a Queue Thread
' If client.has( "window|workDoneProgress" ) to make sure that progress is supported 
' Allocate GUID for progress bar
'	Create a Progress Bar for Indexing task
'	{ method:"window/workDoneProgress/create",params:{token:"GUID",kind:"begin",title:"Indexing Workspace","message":uri.toString(),"percentage":0}}
' Add Scan Task
' Scan Task adds DocumentLoad Tasks to Queue
'	Percentage = 1, total tasks
' DocumentLoad task:
'	Checks if valid symbol table in cache.
'		Load the symbol table. 
'		Add Document of type "DOCUMENT_SYMTABLE"
'	No symbol cache: Add Parse Task
'		Creates Task to load Symbol Table and Exits
'	Otherwise:
'		Checks is AST in cache & loads it
'		Otherwise
'run Lexer / Parser To Create AST
'	(Or load AST)

' Load symbol Table Task
'	Imports Symbol Table into Workspace Cache

'	END Progress Bar for Indexing task
'	{ method:$/progress,params:{token:"GUID",kind:"end","message":"complete in Xminutes, seconds etc"}}



Type TWS
	
	' Threaded scanner
	Field scanThread:TThread
	Field scanThreadExit:Int = False

	Function WorkSpaceScanner:Object( data:Object )
		Const FSM_SCAN_FILES:Int = 0
		Local workspace:TWorkspace = TWorkspace( data )
		Local quit:Int = False
		Local fsm:Int = FSM_SCAN_FILES
		Local filelist:String[]

		' Create Progress counter

		' Scan the workspace folder obtaining files.
		dir_scanner( workspace.uri.folder(), filelist )

		If CompareAndSwap( workspace.scanThreadExit, quit, True )
			' Cancel Progress Bar
			Return
		End If

		Repeat
			Select fwm
			Case FSM_SCAN_FILES
				fsm = FSM_
			End Select
		Until CompareAndSwap( workspace.scanThreadExit, quit, True )

		' #####
		Function dir_scanner:String[]( folder:String, list:String[] Var )
		Local dir:Byte Ptr = ReadDir( folder )
		If Not dir Return Null
		Repeat
			Local filename:String = NextFile( dir )
			If filename="" Exit
			If filename="." Or filename=".." Continue
			Select FileType( folder+"/"+filename )
			Case FILETYPE_DIR
				workspace_scan2( folder + "/" + filename, list )
			Case FILETYPE_FILE
				If Lower(ExtractExt(filename))="bmx" ; list :+ [ folder+"/"+filename ]
			End Select
		Forever
		CloseDir dir
		End Function

	End Function
	
	
End Type

Local this:TWS = New TWS()
test.scanThread = CreateThread( TWS.WorkspaceScanner, this )


'Local strlist:String[]
'start = MilliSecs()
'strlist = workspace_scan( "/home/si/dev" )
'finish = MilliSecs()
'Print "TIME: "+ (finish-start)+"ms"
'For Local file:String = EachIn strlist
'	Print( "* "+file )
'Next

strlist = []
start = MilliSecs()
'workspace_scan2( "/home/si/dev", strlist )
workspace_scan2( uri.folder(), strlist )
finish = MilliSecs()
Print "TIME: "+ (finish-start)+"ms"
For Local file:String = EachIn strlist
	Print( "* "+file )
Next

Print "THREAD RUNNING"...

' To force quit prematurely; 
AtomicSwap( scanThreadExit, True )   ' Inform thread it must exit
DetachThread( scanThread )

Local strtlist:TList = New TList()
start = MilliSecs()
workspace_scan3( "/home/si/dev", strtlist )
finish = MilliSecs()
Print "TIME: "+ (finish-start)+"ms"
'For Local file:String = EachIn strtlist
'	Print( "* "+file )
'Next

strlist = []
start = MilliSecs()
workspace_scan4( "/home/si/dev", strlist )
finish = MilliSecs()
Print "TIME: "+ (finish-start)+"ms"
'For Local file:String = EachIn strlist
'	Print( "* "+file )
'Next

Function workspace_scan:String[]( folder:String )
	Local files:String[]
	Local dir:Byte Ptr = ReadDir( folder )
	If Not dir Return []
	Repeat
		Local filename:String = NextFile( dir )
		If filename="" Exit
		If filename="." Or filename=".." Continue
		Select FileType( folder+"/"+filename )
		Case FILETYPE_DIR
			files :+ workspace_scan( folder + "/" + filename )
		Case FILETYPE_FILE
			If Lower(ExtractExt(filename))="bmx" ; files :+ [folder+"/"+filename]
		End Select
	Forever
	CloseDir dir
	Return files
End Function

Function workspace_scan2:String[]( folder:String, list:String[] Var )
	Local dir:Byte Ptr = ReadDir( folder )
	If Not dir Return Null
	Repeat
		Local filename:String = NextFile( dir )
		If filename="" Exit
		If filename="." Or filename=".." Continue
		Select FileType( folder+"/"+filename )
		Case FILETYPE_DIR
			workspace_scan2( folder + "/" + filename, list )
		Case FILETYPE_FILE
			If Lower(ExtractExt(filename))="bmx" ; list :+ [ folder+"/"+filename ]
		End Select
	Forever
	CloseDir dir
End Function

Function workspace_scan3:String[]( folder:String, list:TList )
	Local dir:Byte Ptr = ReadDir( folder )
	If Not dir Return Null
	Repeat
		Local filename:String = NextFile( dir )
		If filename="" Exit
		If filename="." Or filename=".." Continue
		Select FileType( folder+"/"+filename )
		Case FILETYPE_DIR
			workspace_scan3( folder + "/" + filename, list )
		Case FILETYPE_FILE
			If Lower(ExtractExt(filename))="bmx" ; list.addlast( folder+"/"+filename )
		End Select
	Forever
	CloseDir dir
End Function

Function workspace_scan4:String[]( folder:String, list:String[] Var )
	Local filename:String, path:String
	Local dir:Byte Ptr = ReadDir( folder )
	If Not dir Return Null
	Repeat
		filename = NextFile( dir )
		If filename="" Exit
		If filename="." Or filename=".." Continue
		path = folder+"/"+filename
		Select FileType( path )
		Case FILETYPE_DIR
			workspace_scan2( path, list )
		Case FILETYPE_FILE
			If Lower(ExtractExt(filename))="bmx" ; list :+ [ path ]
		End Select
	Forever
	CloseDir dir
End Function

Type TURI
	'	  foo://example.com:8042/over/there?name=ferret#nose
	'	  \_/   \______________/\_________/ \_________/ \__/
	'	   |           |            |            |        |
	'	scheme     authority       path        query   fragment
	'	   |   _____________________|__
	'	  / \ /                        \
	'	  urn:example:animal:ferret:nose
	
	Const REGEX:String = "^(([^:/?#]+?):)?(\/\/([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?"
	Field scheme:String, authority:String, path:String, query:String, fragment:String
	Field formatted:String	' cached
	
	Method New( value:String, FileUri:Int = False )
	
	'Local this:TURI = Self
	
		If FileURI
			scheme    = "file"
			authority = ""
			
			' Normalise slashes
			path = Replace( value, "\", "/" )

			' UNC paths
			If path[0..2]="//"
				Local idx:Int = Instr( path, "/", 2 )
				If idx = 0
					authority = path[2..]
					path = "/"
				Else
					authority = path[2..idx]
					path = path[idx..]
					If path="" ; path = "/"
				End If
			End If
			
			query     = ""
			fragment  = ""
		
		Else
	
			Local regex:TRegEx = TRegEx.Create( REGEX )
			Local match:TRegExMatch = regex.Find( value )
			If match 
				scheme    = match.SubExp(2)
				authority = match.SubExp(4)
				path      = match.SubExp(5)
				query     = match.SubExp(7)
				fragment  = match.SubExp(9)
			End If
		End If
	End Method

	Method New( scheme:String, authority:String, path:String, query:String, fragment:String )
		Self.scheme    = scheme
		Self.authority = authority
		Self.path      = path
		Self.query     = query
		Self.fragment  = fragment
	End Method
	
	Method toString:String()
		If formatted ; Return formatted
		
		If scheme ; formatted :+ scheme + ":"
		If authority Or scheme = "file" ; formatted :+ "//"
		If authority
			Local index:Int = Instr( authority, "@" )
			If index>0
				Local user:String = authority[..index]
				authority = authority[(index+1)..]
				index = Instr( user, ":" )
				If index>0
					formatted :+ user
				Else
					formatted :+ user[..index] + ":" + user[index..]
				End If
				formatted :+ "@"
			End If
			authority = Lower( authority )
			index = Instr( authority, ":" )
			If index>0
				formatted :+ authority
			Else
				formatted :+ authority[..index] + authority[index..]
			End If
		End If
		If path  
			' Lower-Case windows drive letters in /C:/fff Or C:/fff
			If path.length >= 3 And path[0..1] = "/" And path[2..3] = ":"
				Local code:String = path[1..2]
				If code >= "A" And code <= "Z" ; path = "/"+Lower(code)+":"+path[3..]
			ElseIf path.length >= 2 And path[1..2] = ":"
				Local code:String = path[0..1]
				If code >= "A" And code <= "Z" ; path = Lower(code)+":"+path[2..]
			End If
			' Encode the rest of the path
			formatted :+ encoder(path, True)
		End If
		If query ; formatted :+ "?" + encoder(query, False)
		If fragment ; formatted :+ "#" + fragment
		Return formatted		
	End Method
	
	Method encoder:String( Text:String, allowslash:Int = False )
		Return Text
	End Method
	
	' Path contains a filename, we dont always want this...
	Method folder:String()
		Return ExtractDir( path )
	End Method

	' Retrieve only the filename from the path
	Method filename:String()
		Return StripDir( path )
	End Method	
	
	
	'Function file:TURI( path:String )
	'	Local authority:String = ""
		
	'	' Normalise slashes
	'	path = Replace( path, "\", "/" )

	'	' UNC paths
	'	If path[0..2]="//"
	'		Local idx:Int = Instr( path, "/", 2 )
	'		If idx = 0
	'			authority = path[2..]
	'			path = "/"
	'		Else
	'			authority = path[2..idx]
	'			path = path[idx..]
	'			If path="" ; path = "/"
	'		End If
	'	End If
'
	'	Return New TURI( "file", authority, path, "", "" )
	'End Function
	
End Type


