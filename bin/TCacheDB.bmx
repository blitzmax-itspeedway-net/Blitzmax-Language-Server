
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	This is a type that manages SQL cache files
'	It is designed to be extended, not used as-is

Rem DB SCHEMA

ATTR
----
key				VARCHAR(10)		PRIMARY KEY
value			VARCHAR(10)

EndRem

Type TCacheDB

	Private
	
	Field db:TDBConnection
	Field dbpath:String
	Field lock:TMutex
	
	Field rootpath:String
	Field cachePath:String = ".bls-cache"
	Field cacheFile:String = "cache.db"
	Field cacheVersion:Int = 0
	
	Public 
	
	Method New( rootPath:String, cachePath:String, cacheFile:String, cacheVersion:Int )
		Self.rootpath = rootpath
		Self.cachePath = cachePath
		Self.cacheFile = cacheFile
		Self.cacheVersion = cacheVersion
	End Method
	
	Method initialise()
		Local sql:String
'DebugStop

		lock = CreateMutex()
		LockMutex( lock )

		'	Create the cache folder
		
		Local cachedir:String = rootpath + "/" + cachePath
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
		
		dbpath = cachedir + "/" + cacheFile
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
			Self.updateDatabase()
		EndIf

		Print "- Creating tables"
		Self.buildDatabase()
		
		UnlockMutex( lock )
	End Method

	Private
	
	' Allows the database to be built
	Method buildDB() Abstract

	' Allows the database to be updated if necessary
	Method upgrade( currentVersion:Int ) ; End Method
	Method downgrade( currentVersion:Int ) ; End Method
	
	' Upgrade cache or delete records so we start again.
	Method updateDatabase() Final
		' Get cache version and update
		Local query:TDatabaseQuery = db.executeQuery("SELECT value FROM attr WHERE key='version';")			
		Local record:TQueryRecord = query.rowRecord()
		Local version:Int = record.getint(1)
		
		If version >= cacheVersion
			If version > cacheVersion ; downgrade( version )
			Return
		EndIf
				
		' Update the version
		upgrade( version )
		exec( "UPDATE attr SET value="+cacheVersion+";" ) 
	End Method

	' Build the database
	Method buildDatabase() Final

		'	attr table
		
		exec( "CREATE TABLE IF NOT EXISTS attr(" +..
				"key VARCHAR(10) NOT NULL PRIMARY KEY, " +..
				"value VARCHAR(10) NOT NULL DEFAULT ''" +..
				");" )
		exec( "INSERT INTO attr VALUES('bls',"+BLS_VERSION+");" )		
		exec( "INSERT INTO attr VALUES('version',"+cacheVersion+");" )		
	
		'	Custom tables:
		buildDB()
		
	End Method
	
	Method exec( sql:String ) Final
		db.executeQuery( sql )		
	End Method
	
End Type