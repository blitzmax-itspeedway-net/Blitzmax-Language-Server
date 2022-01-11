
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	This is a type that manages the module cache file
'	All SQL actions are processed here, not in the code.

Rem DB SCHEMA

MODULES
---------
modname			VARCHAR(255)	PRIMARY KEY			' "brl.graphics" for example
uri				VARCHAR(255)						' "brl.mod/graphics.mod" for example

SYMBOLS
-------
id 				INTEGER 		PRIMARY KEY AUTOINCREMENT
modname			VARCHAR(255)						' Same as MODULES.modname
uri				VARCHAR(255)						' File containing the symbol
name 			VARCHAR(255)						' Symbol name
kind			INTEGER			DEFAULT 0			' Kind of symbol
start_line		INTEGER			NOT NULL DEFAULT 0
start_char		INTEGER			NOT NULL DEFAULT 0
end_line		INTEGER			NOT NULL DEFAULT 0
end_char		INTEGER			NOT NULL DEFAULT 0

EndRem

Type TModuleCache Extends TCacheDB

	Private
	
	Const CACHE_PATH:String = ".bls-cache"
	Const CACHE_FILE:String = "module.cache"
	Const CACHE_VERSION:Int = 2
	
	Public 
	
	Method New()
		Super.New( BlitzMaxPath()+"/mod", CACHE_PATH, CACHE_FILE, CACHE_VERSION )
'DebugStop
		initialise()
	End Method

	Private
	
	Method upgrade( currentVersion:Int )
		If currentVersion<2 ; update_from_v1()	' Version 1 had a typo in field name modpath
	End Method
	
	' Update from cache V1
	Method update_from_v1()
		' Version 1 had a misspelling in the modpath column name, so we need to rebuild this table
		' Not ideal, but version 1 didn't use it, so it won't make any difference.
		exec( "DROP TABLE modules;" )
		exec( "DROP TABLE symbols;" )
		'buildDB()
	End Method
	
	' Build the database
	Method buildDB()

		'	text documents

		exec( "CREATE TABLE IF NOT EXISTS modules(" +..
				"modname VARCHAR(255) NOT NULL PRIMARY KEY, " +..
				"uri VARCHAR(255) NOT NULL DEFAULT ''" +..
				");" )

		'	symbols
		
		exec( "CREATE TABLE IF NOT EXISTS symbols(" +..
				"id INTEGER PRIMARY KEY AUTOINCREMENT, " +..
				"modname VARCHAR(255) NOT NULL DEFAULT '', " +..
				"uri VARCHAR(255) NOT NULL DEFAULT '', " +..
				"name VARCHAR(255) NOT NULL DEFAULT '', " +..
				"kind INT NOT NULL DEFAULT 0, " +..
				"start_line INTEGER NOT NULL DEFAULT 0, " +..
				"start_char INTEGER NOT NULL DEFAULT 0, " +..
				"end_line INTEGER NOT NULL DEFAULT 0, " +..
				"end_char INTEGER NOT NULL DEFAULT 0 " +..
				");" )
		
	End Method

	Public
	
	' #
	' ##### MODULE TABLE SERVICES
	' #
	
	' UPDATE or INSERT a file record
	Method addModule( modname:String, uri:TURI )
'DebugStop
		LockMutex( lock )
		Local sql:String = "UPDATE modules SET modname='"+modname+"',uri='"+uri.toString()+"' WHERE modname='"+modname+"';"
'Print sql
'Print uri.tostring()
'Print uri.path
		Local query:TDatabaseQuery = db.executeQuery( sql )
		Local affected:Int = query.rowsAffected()
		If query.rowsAffected()=0
			exec( "INSERT INTO modules(modname,uri) "+ ..
				  "VALUES('"+modname+"','"+uri.toString()+"');" )
			'Print( "FILE INSERTED" )
		'Else
		'	Print( "FILE UPDATED" )
		End If
		UnlockMutex( lock )
	End Method

	' Delete a file from cache
	Method DeleteModule( modname:String )
		LockMutex( lock )
		exec( "DELETE FROM modules WHERE modname='"+modname+"';" )
		exec( "DELETE FROM symbols WHERE modname='"+modname+"';" )
		UnlockMutex( lock )
	End Method

	' Get all known modules
	Method getModules:TMap()
		LockMutex( lock )
		Local query:TDatabaseQuery = db.executeQuery( "SELECT modname,uri FROM modules;" )
		' iterate over the retrieved rows
'DebugStop
		UnlockMutex( lock )
		
		Local list:TMap = New TMap()
'Local count:Int = 0
		While query.nextRow()
			Local record:TQueryRecord = query.rowRecord()
'count :+ 1
			Local modname:String = record.getStringByName( "modname" )
			Local item:TMap = New TMap()
			item.insert( "modname", modname ) 
			item.insert( "uri", record.getStringByName( "uri" ) )
			'item.insert( "filesize", string(record.getIntbyName( "fileSize" ) ) )) 
			'item.insert( "filedate", record.getStringbyName( "filedate" ) )
			'item.insert( "checksum", record.getStringByName( "checksum" ) )
			list.insert( modname, item )
		Wend
'Print "Records="+count
		Return list
	End Method

	' #
	' ##### SYMBOL TABLE SERVICES
	' #
	
	' Add symbols from a document
	Method addSymbols( modname:String, uri:TURI, symbols:TSymbolTable )
		If Not symbols Or Not modname Return
		Local sql:String
		Local fileuri:String = uri.toString()
		LockMutex( lock )
		' Remove old symbols
		exec( "DELETE FROM symbols WHERE modname='"+modname+"';" )
		
		For Local symbol:TSymbolTableRow = EachIn symbols.data
			Try
				If Not symbol.location Or Not symbol.location.range Or Not symbol.location.range.start Or Not symbol.location.range.ends ; Continue
				sql = "INSERT INTO symbols( modname,uri,name,kind,start_line,start_char,end_line,end_char) "+ ..
					  "VALUES(" +..
						"'"+modname+"'," +..
						"'"+fileuri+"'," +..
						"'"+symbol.name+"'," +..
						symbol.kind+"," +..
						symbol.location.range.start.line+"," +..
						symbol.location.range.start.character+"," +..
						symbol.location.range.ends.line+"," +..
						symbol.location.range.ends.character+");"
				exec( sql )
			Catch e:String
				' Ignore and continue
			End Try
		Next
		UnlockMutex( lock )
	End Method
	
	' Get a WorkspaceSymbol[] JSON array from the cache
	Method getSymbols:JSON[]( criteria:String )
		Local SQL:String = ..
			"SELECT modname,modpath,name,kind,start_line,start_char,end_line,end_char " +..
			"FROM symbols"
		If criteria = ""
			SQL :+ ";"
		Else
			SQL :+ " WHERE name LIKE '%"+criteria+"%';"
		End If
		
		LockMutex( lock )
		Local query:TDatabaseQuery = db.executeQuery( SQL )
		UnlockMutex( lock )
		
		Local data:JSON[] = []
		While query.nextRow()
			Local record:TQueryRecord = query.rowRecord()
			Local symbol:JSON = New JSON()
			symbol.set( "name", record.getStringByName( "name" ) )
			symbol.set( "kind", record.getIntbyName( "kind" ) )
			'symbol.set( "tags", [] )
			symbol.set( "location|uri", New TURI( record.getStringByName( "modpath" ) ).tostring() )
			symbol.set( "location|range|start|line", record.getIntbyName( "start_line" ) )
			symbol.set( "location|range|start|character", record.getIntbyName( "start_char" ) )
			symbol.set( "location|range|end|line", record.getIntbyName( "end_line" ) )
			symbol.set( "location|range|end|character", record.getIntbyName( "end_char" ) )
			data :+ [symbol]
			'logfile.debug( symbol.stringify() )
		Wend
		Return data
	End Method

	
End Type