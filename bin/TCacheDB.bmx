
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
	'Field cacheVersion:Int = 0
	
	Public 
	
	Method New( rootPath:String, cachePath:String, cacheFile:String )
		Self.rootpath = rootpath
		Self.cachePath = cachePath
		Self.cacheFile = cacheFile
		'logfile.debug( "TCacheDB: "+rootPath+","+cachePath+","+cacheFile )
		'Self.cacheVersion = cacheVersion
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
			'Print( "CACHE FOLDER ALREADY EXISTS" )
		Case FILETYPE_FILE
			' This is an unrecoverable situation.
			' The folder cannot be created if a file exists!
			'Print( "CACHE FOLDER IS A FILE!" )
			UnlockMutex( lock )
			Return
		Default
			'Print( "CREATING CACHE FOLDER" )
			CreateDir( cachedir, True )
		End Select


		'	Open Database
		
		dbpath = cachedir + "/" + cacheFile
		
		'	DELETE THE TABLE ON UNSTABLE VERSIONS
		If appvermax=0 And (appvermin<4 Or (appvermin=4 And appbuild<87)) And FileType( dbpath ) = FILETYPE_FILE
			logfile.debug( "** Deleted file: "+dbpath )
			DeleteFile( dbpath )
		End If
		
		db = LoadDatabase( "SQLITE", dbpath )
		If Not db 
			'Print "Failed to load database"
			UnlockMutex( lock )
			Return
		Else
			'Print "DATABASE:~n- Exists"
		End If
		If Not db.isOpen() 
			UnlockMutex( lock )
			Return
		End If
		'Print "- Is Open"
		
		'	Build or Update tables

		Local table:TDBTable = db.getTableInfo("attr", False)
		If table.columns
			'Print "- Checking for updates"
			Self.updateDatabase()
		EndIf

		'Print "- Creating tables"
		Self.buildDatabase()
		
		UnlockMutex( lock )
	End Method

	Private
	
	' Allows the database to be built
	Method buildDB() Abstract

	' Allows the database to be updated if necessary
	Method upgrade( currentVerMax:Int, currentVerMin:Int ) ; End Method
	Method patch( currentVerMax:Int, currentVerMin:Int, currentBuild:Int ) ; End Method
	Method downgrade( currentVerMax:Int, currentVerMin:Int ) ; End Method
	
	' Upgrade cache or delete records so we start again.
	Method updateDatabase() Final
DebugStop
		' Get cache version and update
		Local SQL:String = ..
			"SELECT " +..
				"(SELECT value FROM attr WHERE key='blsvermax') AS vermax," +..
				"(SELECT value FROM attr WHERE key='blsvermin') AS vermin," +..
				"(SELECT value FROM attr WHERE key='blsbuild') AS build;"
'Print SQL
		Local query:TDatabaseQuery = db.executeQuery(SQL)
		'Local query:TDatabaseQuery = db.executeQuery("SELECT key,value FROM attr WHERE key='blsversion' or key='blsbuild';")			
		'query.nextRow()
		Local record:TQueryRecord = query.rowRecord()
		Local vermax:Int = Int(record.getStringbyName( "vermax" )) 
		Local vermin:Int = Int(record.getStringbyName( "vermin" )) 
		Local build:Int = Int(record.getStringbyName( "build" ))

logfile.debug( cacheFile + " at V"+vermax+"."+vermin+" build "+build )
'debugstop	
		If appvermax = vermax And appvermin = vermin	' No change to version
			If appbuild > build			' Running later build?
logfile.debug( cacheFile + " may require patch..." )
				patch( vermax, vermin, build )
			Else
logfile.debug( cacheFile + " is at latest version..." )
				Return
			End If
		ElseIf appvermax < vermax Or ( appvermax = vermax And appvermin < vermin ) ' Downgrade the version
logfile.debug( cacheFile + " requires downgrade..." )
			downgrade( vermax, vermin )
		Else							' Update the version
logfile.debug( cacheFile + " requires upgrade..." )
			upgrade( vermax, vermin )
		End If

		' Update table
		exec( "UPDATE attr SET blsvermax='"+appvermax+"',blsvermin='"+appvermin+"',blsbuild='"+appbuild+"';" ) 
		db.commit()				
	End Method

	' Build the database
	Method buildDatabase() Final

		'	attr table
		
		exec( "CREATE TABLE IF NOT EXISTS attr(" +..
				"key VARCHAR(10) NOT NULL PRIMARY KEY, " +..
				"value VARCHAR(10) NOT NULL DEFAULT ''" +..
				");" )
		exec( "INSERT INTO attr VALUES('blsvermax','"+appvermax+"');" )		
		exec( "INSERT INTO attr VALUES('blsvermin','"+appvermin+"');" )		
		exec( "INSERT INTO attr VALUES('blsbuild','"+appbuild+"');" )		
	
		'	Custom tables:
		buildDB()
		db.commit()
	End Method
	
	Method exec( sql:String ) Final
		db.executeQuery( sql )		
	End Method
	
End Type