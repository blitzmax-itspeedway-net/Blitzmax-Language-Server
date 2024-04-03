
'   LANGUAGE SERVER FOR BLITZMAX NG
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'	This is a type that manages the workspace cache file
'	All SQL actions are processed here, not in the code.

Rem DB SCHEMA

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
start_line		INTEGER			NOT NULL DEFAULT 0
start_char		INTEGER			NOT NULL DEFAULT 0
end_line		INTEGER			NOT NULL DEFAULT 0
end_char		INTEGER			NOT NULL DEFAULT 0
definition		VARCHAR(255)	
description		VARCHAR(255)

EndRem

Type TWorkspaceCache Extends TCacheDB

	Private
	
	Const CACHE_PATH:String = ".bls-cache"
	Const CACHE_FILE:String = "workspace.cache"
	
	Public 
	
	Method New( rootpath:String )
		Super.New( rootpath, CACHE_PATH, CACHE_FILE )
		initialise()
	End Method

	Private
	
	Method upgrade( currentVerMax:Int, currentVerMin:Int )
		Trace.debug( "workspace.cache.upgrade:" )
		If  (currentVerMax=0 And currentVerMin<5) 		' Added definition field
			Trace.debug( "- Upgrading Tables" )
			exec( "DROP TABLE symbols;" )
		Else
			Trace.debug( "- Not required" )		
		End If
	End Method

	Method patch( currentVerMax:Int, currentVerMin:Int, currentBuild:Int )
		Trace.debug( "workspace.cache.patch:" )
		If  (currentVerMax=0 And currentVerMin<5)		' Added definition field
			Trace.debug( "- Patching Tables" )
			exec( "DROP TABLE symbols;" )
			exec( "DELETE FROM attr WHERE key='version' or key='blsversion';" ) ' Clean up old data
		Else
			Trace.debug( "- Not required" )		
		End If
	End Method
	
	' Build the database
	Method buildDB()

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
				"end_char INTEGER NOT NULL DEFAULT 0, " +..
				"definition VARCHAR(255) NOT NULL DEFAULT ''," +..
				"description VARCHAR(255) NOT NULL DEFAULT ''" +..
				");" )
		
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
		
		For Local symbol:TSymbolTableRow = EachIn symbols.symbols
			If Not symbol.location Or Not symbol.location.range Or Not symbol.location.range.start Or Not symbol.location.range.ends ; Continue
			sql = "INSERT INTO symbols( uri,name,kind,start_line,start_char,end_line,end_char,definition,description) "+ ..
				  "VALUES(" +..
					"'"+fileuri+"'," +..
					"'"+symbol.name+"'," +..
					symbol.kind+"," +..
					symbol.location.range.start.line+"," +..
					symbol.location.range.start.character+"," +..
					symbol.location.range.ends.line+"," +..
					symbol.location.range.ends.character+"," +..
					"'"+symbol.definition+"'," +..
					"'"+symbol.description+"');"
			exec( sql )
		Next
		UnlockMutex( lock )
	End Method
	
	' Get a WorkspaceSymbol[] JSON array from the cache
	' Using a name criteria to search with
	Method getSymbols:JSON[]( criteria:String )
		Local SQL:String = ..
			"SELECT uri,name,kind,start_line,start_char,end_line,end_char,definition,description " +..
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
			symbol.set( "definition", record.getStringByName( "definition" ) )
			symbol.set( "description", record.getStringByName( "description" ) )
			data :+ [symbol]
			'Trace.debug( symbol.stringify() )
		Wend
		Return data
		
	End Method
	
	' Retrieve a symbol from a specific location
	' textDocument/hover results
	Method getSymbolAt:JSON( position:JSON )
		Local SQL:String = ..
			"SELECT uri,name,kind,start_line,start_char,end_line,end_char " +..
			"FROM symbols"
		Try
			If position And position.isvalid()
				Local line:Int = position.find("line").toInt()+1	' Account for zero offset
				Local char:Int = position.find("character").toInt()	
				SQL :+ " WHERE start_line<="+line +..
					     " AND end_line>="+line +..
					     " AND start_char<="+char +..
					     " AND end_char>="+char
			End If
		Catch e:String
			' ignore it for now
		End Try
		
		SQL :+ ";"
		
Trace.debug( SQL )

		LockMutex( lock )
		Local query:TDatabaseQuery = db.executeQuery( SQL )
		UnlockMutex( lock )
		
		Local data:JSON[] = []
		' Get FIRST row
		query.nextRow()
		Local record:TQueryRecord = query.rowRecord()
		Local kind:Int = record.getIntbyName( "kind" )
		Local kindText:String 
		If kind < Len( SymbolKindText ) kindText = SymbolKindText[kind]
		Local value:String = "```"+kindText+" "+record.getStringByName( "name" )+"```" 
		Local result:JSON = New JSON()
		result.set( "contents|kind", "markdown" )
		result.set( "contents|value", value )
		result.set( "range|start|line", record.getIntbyName( "start_line" ) )
		result.set( "range|start|character", record.getIntbyName( "start_char" ) )
		result.set( "range|end|line", record.getIntbyName( "end_line" ) )
		result.set( "range|end|character", record.getIntbyName( "end_char" ) )
		Return result
		
	End Method
	
End Type