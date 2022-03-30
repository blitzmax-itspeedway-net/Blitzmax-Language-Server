
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	Performs a file scan of the modules.

Type TTaskModuleScan Extends TTask
		
	Field modpath:String
	Field cache:TModuleCache = Null
	
	Field ToDoList:TList = New TList()	' List of files we need to parse
	Field completed:TMap = New TMap()	' List of completed files
	
	Method New( cache:TModuleCache, priority:Int = QUEUE_PRIORITY_WORKSPACE_SCAN )
		Super.New( THREADED )
		Self.modpath = BlitzMaxPath() + "/mod"		
		Self.name = "ModuleScan{"+modpath+"}"
		Self.cache = cache
		Self.priority = priority

	End Method
	
	Method launch()
		Local start:Int = MilliSecs()
		Local finish:Int
		logfile.debug( "## MODULE SCAN - STARTED" )
'DebugStop
		client.logMessage( "BlitzMax module parsing started", EMessageType.info.ordinal() )
		' Request known files from cache
		Local cachedfiles:TMap = cache.getModules()

		' Obtain a list of modules
		Local mods:TList = EnumModules()
		
		' Loop through modules
'DebugStop
		For Local modname:String = EachIn mods
		
			' Extract path for the module
			Local name:String[] = modname.split(".")
			Local path:String = modpath+"/"+name[0]+".mod/"+name[1]+".mod"
'Print( modname + "    " + path )			
			' Confirm module contains a valid entrypoint
			Local entry:String = path + "/" + name[1] + ".bmx"
			Local uri:TURI = New TURI( entry )

			If FileType( entry ) = FILETYPE_FILE
				' Check if module needs to be parsed
				If cachedfiles.contains( modname )
					logfile.debug( "## MODULE SCAN: "+modname+" - Already processed" )
					' Remove processed module from list (We dont need to do it again)
					cachedfiles.remove( modname )
				Else
					logfile.debug( "## MODULE SCAN: "+modname+" - Added to TODO list" )
					' Insert module into DB
					cache.addmodule( modname, uri )
					' Parse the module
					'parseModule( modname, entry )
					' Add to to-do list
					Local ToDo:String[] = [ modname, entry ]
					ToDoList.addlast( ToDo )
				End If
			End If
		Next
		
		' Modules remaining in cachedfiles list exist in database, but not on disk
		For Local modname:String = EachIn cachedfiles.keys()
			logfile.debug( "## MODULE SCAN: "+modname+" - Removed deleted module" )
			cache.deleteModule( modname )
			' Update progress bar
			'progress :+ 1
			'client.progress_update( token, progress, total )
		Next
		
		' Parse files
		While Not ToDoList.isEmpty()
			Local ToDo:String[] = String[]( ToDoList.removeFirst() )
			Local modname:String = todo[0]
			Local filename:String = todo[1]
			' Parse the module
			logfile.debug( "## MODULE SCAN: PARSING " + modname + ":" + filename )
			parseModule( modname, filename )
			completed.insert( modname+":"+filename, "DONE" )
		Wend
		
		logfile.debug( "## MODULE SCAN - FINISHED" )
		finish=MilliSecs()
		client.logMessage( "BlitzMax module parsing complete in "+(finish-start)+"ms", EMessageType.info.ordinal() )
	End Method
	
	Method parseModule( modname:String, filename:String )
		Local start:Int, finish:Int
		logfile.debug( "TTaskModuleScan: "+ modname + "  " + filename )
		Local uri:TURI = New TURI( filename )
		
		Local content:String = loadfile( filename )
		If content = "" ; Return
		
		start = MilliSecs()
		Local lexer:TLexer = New TBlitzMaxLexer( content )
		'logfile.debug( "TTaskModuleScan: Lexer initialised" )
		Local parser:TParser = New TBlitzMaxParser( lexer )
		'logfile.debug( "TTaskModuleScan: Parser initialised" )
		Local ast:TASTNode = parser.parse_ast()
		'logfile.debug( "TTaskModuleScan: Module parsed" )
		
		' Parse the AST into a symbol table
		cache.addSymbols( modname, uri, New TSymbolTable( ast ) )
		logfile.debug( "TTaskModuleScan: Symbols added" )
		
		' Parse IMPORT and INCLUDE and add them to TODO list

		 

		logfile.debug( "TTaskModuleScan: *** IMPORT IGNORED" )
		logfile.debug( "TTaskModuleScan: *** INCLUDE IGNORED" )

' WORKING HERE
		Local walker:TASTWalker = New TASTWalker( ast )
		Local results:TList = walker.search( [ TK_INCLUDE, TK_IMPORT ] )
		
		For Local result:TASTNode = EachIn results
			debugstop
			DebugLog( result.reveal() )
		Next
		
		DebugStop
		
		finish = MilliSecs()	

		logfile.debug( "TTaskModuleScan: Parsed '"+modname+"' in "+(finish-start)+"ms" )
		client.logMessage( "Parsed module '"+modname+"' in "+(finish-start)+"ms", EMessageType.info.ordinal() )

		'logfile.debug( "TTaskModuleScan: *** CONFIG NOT UPDATED" )
		' Update config file
		'If config.has( "modules|modname|scan" )
		'	config.set( "modules|modname|scan", False )
		'End If
		
		logfile.debug( "TTaskModuleScan: "+ modname + " is finished" )
	End Method

	Method LoadFile:String( filename:String )
		Local file:TStream = ReadStream( filename )
		If Not file Return ""
		'Print "- File Size: "+file.size()+" bytes"
		Local content:String = ReadString( file, file.size() )
		CloseStream file
		Return content
	End Method
		
	Method progress( percent:Int )
	End Method

	' This method recieves responses from client if you send any requests.
	Method response( message:TMessage )
	End Method

	' Folder scanner
	' 29/DEC/21 - Moved to functions.bmx
'	Function dir_scanner( folder:String, list:String[] Var )
'		Local dir:Byte Ptr = ReadDir( folder )
'		If Not dir Return
'		Repeat
'			Local filename:String = NextFile( dir )
'			If filename="" Exit
'			If filename="." Or filename=".." Continue
'			Select FileType( folder+"/"+filename )
'			Case FILETYPE_DIR
'				dir_scanner( folder + "/" + filename, list )
'			Case FILETYPE_FILE
'				If Lower(ExtractExt(filename))="bmx" ; list :+ [ folder+"/"+filename ]
'			End Select
'		Forever
'		CloseDir dir
'	End Function

	Function getfolders( folder:String, list:String[] Var )
'		Local dir:Byte Ptr = ReadDir( folder )
'		If Not dir Return
'		Repeat
'			Local filename:String = NextFile( dir )
'			If filename="" Exit
'			If filename="." Or filename=".." Continue
'			Select FileType( folder+"/"+filename )
'			Case FILETYPE_DIR
'				dir_scanner( folder + "/" + filename, list )
'			Case FILETYPE_FILE
'				If Lower(ExtractExt(filename))="bmx" ; list :+ [ folder+"/"+filename ]
'			End Select
'		Forever
'		CloseDir dir
	End Function
End Type