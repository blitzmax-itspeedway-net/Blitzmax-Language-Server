
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	This is a type that manages the workspace cache file
'	All SQL actions are processed here, not in the code.

Rem DB SCHEMA

ATTR
----
key				VARCHAR(10)		PRIMARY KEY
value			VARCHAR(10)

DOCUMENTS
---------
uri				VARCHAR(255)	PRIMARY KEY
filesize		INTEGER			DEFAULT 0
filedate		INTEGER			DEFAULT 0
checksum		VARCHAR(32)		

SYMBOLS
-------
id 				INTEGER 		PRIMARY KEY AUTOINCREMENT
uri 			VARCHAR(255)
name 			VARCHAR(255)
kind			INTEGER			DEFAULT 0
line_start		INTEGER			DEFAULT 0
line_end		INTEGER			DEFAULT 0
containerName	VARCHAR(255)

EndRem

Type TWorkspaceCache

	Private
	
	Const CACHEPATH:String = ".bls-cache"
	Const CACHEFILE:String = "workspace.cache"
	Const CACHEVERSION:Int = 2
	
	Field db:TDBConnection
	Field dbpath:String
	Field lock:TMutex
	
	Public 
	
	Method New( rootpath:String )
		Local sql:String

		lock = CreateMutex()
		LockMutex( lock )

		'	Create the cache folder
		
		Local cachedir:String = rootpath + "/" + CACHEPATH
		' Create folders and cache file
		Select FileType( cachedir  )
		Case FILETYPE_DIR
			' This is what we want...
			Print( "CACHE FOLDER ALREADY EXISTS" )
		Case FILETYPE_FILE
			' This is an unrecoverable situation.
			' The folder cannot be created if a file exists!
			Print( "CACHE FOLDER IS A FILE!" )
			UnlockMutex( lock )
			Return
		Default
			Print( "CREATING CACHE FOLDER" )
			CreateDir( cachedir, True )
		End Select

		'	Open Database
		
		dbpath = cachedir + "/" + CACHEFILE
		db = LoadDatabase( "SQLITE", dbpath )
		If Not db 
			Print "Failed to load database"
			UnlockMutex( lock )
			Return
		Else
			Print "DATABASE:~n- Exists"
		End If
		If Not db.isOpen() 
			UnlockMutex( lock )
			Return
		End If
		Print "- Is Open"
		
		'	Build or Update tables

		Local table:TDBTable = db.getTableInfo("attr", False)
		If table.columns
			Print "- Checking for updates"
			update()
		Else
			Print "- Creating tables"
			Self.buildDatabase()
			'build()
		End If
		
		UnlockMutex( lock )
	End Method

	Private
	
	' Upgrade cache or delete records so we start again.
	Method update()
		' Get cache version and update
		Local query:TDatabaseQuery = db.executeQuery("SELECT value FROM attr WHERE key='version';")			
		Local record:TQueryRecord = query.rowRecord()
		Local version:Int = record.getint(1)
		If version >= CACHEVERSION ; Return ' No update necessary
		'
		If version <2 ; update_from_v1()	' Version 1 had a mistake in the column names

		' Update the version attribute
		exec( "UPDATE attr SET value="+CACHEVERSION+";" ) 
	End Method
	
	' Update from cache V1
	Method update_from_v1()
		' Version 1 had a mistake in the column names, so we need to rebuild this table
		' Not ideal, but version 1 didn't use it, so it won't make any difference.
		exec( "DROP TABLE symbols;" )
		buildDatabase()
	End Method
	
	' Build the database
	Method buildDatabase()

		'	attr table
		
		exec( "CREATE TABLE IF NOT EXISTS attr(" +..
				"key VARCHAR(10) NOT NULL PRIMARY KEY, " +..
				"value VARCHAR(10) NOT NULL DEFAULT ''" +..
				");" )
		
		'	text documents

		exec( "CREATE TABLE IF NOT EXISTS documents(" +..
				"uri VARCHAR(255) NOT NULL PRIMARY KEY, " +..
				"filesize INTEGER NOT NULL DEFAULT 0, " +..
				"filedate INTEGER NOT NULL DEFAULT 0, " +..
				"checksum VARCHAR(32) NOT NULL DEFAULT ''" +..
				");" )

		'	symbols
		
		exec( "CREATE TABLE IF NOT EXISTS symbols(" +..
				"id INTEGER PRIMARY KEY AUTOINCREMENT, " +..
				"uri VARCHAR(255) NOT NULL DEFAULT '', " +..
				"name VARCHAR(255) NOT NULL DEFAULT '', " +..
				"kind INT NOT NULL DEFAULT 0, " +..
				"start_line INTEGER NOT NULL DEFAULT 0, " +..
				"start_char INTEGER NOT NULL DEFAULT 0, " +..
				"end_line INTEGER NOT NULL DEFAULT 0, " +..
				"end_char INTEGER NOT NULL DEFAULT 0 " +..
				");" )
		
		' 	Insert initial data
		
		exec( "INSERT INTO attr VALUES('version',"+CACHEVERSION+");" )
		
	End Method
	
	Method exec( sql:String )
		db.executeQuery( sql )		
	End Method

	Public
	
	' #
	' ##### FILE TABLE SERVICES
	' #
	
	' UPDATE or INSERT a file record
	Method addDocument( document:TTextDocument )
'		DebugStop
		LockMutex( lock )
		Local sql:String = "UPDATE documents SET filesize="+document.file_size+",filedate="+document.file_date+",checksum='"+document.file_checksum+"' WHERE uri='"+document.uri.path+"';"
		Local query:TDatabaseQuery = db.executeQuery( sql )
		Local affected:Int = query.rowsAffected()
		
'DebugStop		
		If query.rowsAffected()=0
		'If db.hasError()
'			Local error:TDatabaseError = db.error()
'			Print error.error
'			DebugStop
			exec( "INSERT INTO documents(uri,filesize,filedate,checksum) "+ ..
				  "VALUES('"+document.uri.path+"',"+document.file_size+","+document.file_date+",'"+document.file_checksum+"');" )
			Print( "FILE INSERTED" )
		Else
			Print( "FILE UPDATED" )
		End If
		UnlockMutex( lock )
	End Method

	' Delete a file from cache
	Method DeleteDocument( uri:String )
		LockMutex( lock )
		exec( "DELETE FROM documents WHERE uri='"+uri+"';" )
		exec( "DELETE FROM symbols WHERE uri='"+uri+"';" )
		UnlockMutex( lock )
	End Method

	' Get all known files from the database
	Method getDocuments:TMap()
		LockMutex( lock )
		Local query:TDatabaseQuery = db.executeQuery( "SELECT uri,filesize,filedate,checksum FROM documents;" )
		' iterate over the retrieved rows
'DebugStop
		UnlockMutex( lock )
		
		Local documents:TMap = New TMap()
		Local count:Int = 0
		While query.nextRow()
			Local record:TQueryRecord = query.rowRecord()
			count :+ 1
			Local document:TDBDocument = New TDBDocument( record )
			documents.insert( document.uri, document )
		Wend
		Print "Records="+count
		Return documents
	End Method

	' #
	' ##### SYMBOL TABLE SERVICES
	' #
	
	' Add symbols from a document
	Method addSymbols( uri:TUri, symbols:TSymbolTable )
		If Not symbols Or Not uri Return
		Local sql:String
		Local fileuri:String = uri.toString()
		LockMutex( lock )
		' Remove old symbols
		exec( "DELETE FROM symbols WHERE uri='"+fileuri+"';" )
		
		For Local symbol:TSymbolTableRow = EachIn symbols.data
			If Not symbol.location Or Not symbol.location.range Or Not symbol.location.range.start Or Not symbol.location.range.ends ; Continue
			sql = "INSERT INTO symbols( uri,name,kind,start_line,start_char,end_line,end_char) "+ ..
				  "VALUES(" +..
					"'"+fileuri+"'," +..
					"'"+symbol.name+"'," +..
					symbol.kind+"," +..
					symbol.location.range.start.line+"," +..
					symbol.location.range.start.character+"," +..
					symbol.location.range.ends.line+"," +..
					symbol.location.range.ends.character+");"
			exec( sql )
		Next
		UnlockMutex( lock )
	End Method
	
	' Get a WorkspaceSymbol[] JSON array from the cache
	Method getSymbols:JSON[]( criteria:String )
		Local SQL:String = ..
			"SELECT uri,name,kind,start_line,start_char,end_line,end_char " +..
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
			symbol.set( "location|uri", record.getStringByName( "uri" ) )
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