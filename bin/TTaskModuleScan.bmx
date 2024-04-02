
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
		Local modlist:String[]				' List of validated modules being added
		
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
					logfile.debug( "## MODULE SCAN: "+modname[..30]+" - Already processed" )
					' Remove processed module from list (We dont need to do it again)
					cachedfiles.remove( modname )
				Else
					logfile.debug( "## MODULE SCAN: "+modname[..30]+" ADD " + entry )
					' Insert module into DB
					'cache.addmodule( modname, uri )
					' Parse the module
					'parseModule( modname, entry )
					' Add module to validated list
					modlist :+ [ "('"+ modname +"','"+uri.toString() +"')" ]
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
		
		' Add modules to database
		logfile.debug( "## MODULE SCAN: Adding Modules to database" )
		cache.addmodules( modlist )
		
		' Parse files
		While Not ToDoList.isEmpty()
			Local ToDo:String[] = String[]( ToDoList.removeFirst() )
			Local modname:String = todo[0]
			Local filename:String = todo[1]
			' Parse the module
			Local fullname:String = Lower(modname+":"+filename)
			If completed.contains( fullname )
				logfile.debug( "## MODULE SCAN: " + modname[..30]+" - "+filename +" - Already scanned" )
			Else
'If modname = "text.format" ; DebugStop
				logfile.debug( "## MODULE SCAN: PARSING " + modname+":"+filename )
				parseModule( modname, filename )
				completed.insert( fullname, "DONE" )
				logfile.debug( "## MODULE SCAN: PARSE COMPLETE" )
			End If
		Wend
		
		logfile.debug( "## MODULE SCAN - FINISHED" )
		finish=MilliSecs()
		client.logMessage( "BlitzMax module parsing complete in "+(finish-start)+"ms", EMessageType.info.ordinal() )
	End Method
	
	Method parseModule( modname:String, filename:String )
'DebugStop
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
		'DebugStop
		Local ast:TASTNode = parser.parse_ast()
		'logfile.debug( "TTaskModuleScan: Module parsed" )
		
DebugStop;		' Parse the AST into a symbol table
		cache.addSymbols( modname, uri, New TSymbolTable( ast ) )
		logfile.debug( "TTaskModuleScan: Symbols added" )
		
		' Parse IMPORT and INCLUDE and add them to TODO list

		Local walker:TASTWalker = New TASTWalker( ast )
		Local results:TList = walker.searchByIDs( [ TK_INCLUDE, TK_IMPORT ] )
		
		' Loop through IMPORT's
		For Local result:TAST_Import = EachIn results
			'DebugStop
			'DebugLog( result.reveal() )
			' Add Includes and Imports to TODO list
			If result.localfile
				' Same module, different file
				' Ignore everything except blitzmax files
				If ExtractExt( result.filename.value ) = "bmx"
					'DebugStop
					'Local file:TPath = New TPath( result.filename.value )
					'Local name:String[] = result.filename.split(".")
					Local path:String = ExtractDir( filename )
					Local entry:String = joinPaths( path, result.filename.value )
					'Local epath:String = path + filename
					logfile.debug( "## MODULE SCAN: "+modname[..30]+" ADD " + entry )
					ToDoList.addlast( [ modname, entry ] )
				Else
					DebugLog( "  - Import ~q"+result.filename.value+"~q - SKIPPED" )
				End If
			Else
				'DebugStop
				' Different module
				Local modname:String = result.filename.value
				Local name:String[] = modname.split(".")
				Local path:String = modpath + "/" + name[0]+".Mod" + "/" + name[1]+".Mod"
				Local entry:String = path + "/" + name[1] + ".bmx"
				logfile.debug( "## MODULE SCAN: "+modname[..30]+" ADD " + entry )
				ToDoList.addlast( [ modname, entry ] )
			End If
		Next

		' Loop through INCLUDES's
		For Local result:TAST_Include = EachIn results
			DebugStop
			DebugLog( result.reveal() )
' NODE DOES NOT CONTAIN FILE NAME!
			' Add Includes and Imports to TODO list
			'If result.localfile
				' Same module, different file
				' todo.addlast( [ modname, result.filename.value ] )
			'Else
				' Different module
				'Local name:String[] = results.filename.split(".")
				'Local path:String = modpath+"/"+name[0]+".mod/"+name[1]+".mod"
				'Local entry:String = path + "/" + name[1] + ".bmx"
				' todo.addlast( [ modname, entry ] )
			'End If
		Next
		

		'logfile.debug( "TTaskModuleScan: *** IMPORT IGNORED" )
		'logfile.debug( "TTaskModuleScan: *** INCLUDE IGNORED" )
		
		'DebugStop
		
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