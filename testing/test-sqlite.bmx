SuperStrict

'	SQLITE TEST

Import bah.database
Import bah.dbsqlite
Import crypto.MD5digest

Include "../bin/TWorkspaceCache.bmx"
Include "../bin/TDBDocument.bmx"
'Include "../bin/TTextDocument.bmx"

Type TSymbolTable
End Type

' DUMMY TEXT DOCUMENT DURING THIS TEST

Type TTextDocument

	Field uri:String
	Field file_size:Int
	Field file_date:Long
	Field file_checksum:String
		
	Field content:String

	Method New( filename:String )
		uri = filename
		file_size = FileSize( filename )
		file_date = FileTime( filename )
		content = loadfile( filename )
		file_checksum = computeChecksum( content )
	End Method

	Method computeChecksum:String( data:String )
		Local digest:TMessageDigest = GetMessageDigest("MD5")
		If digest ; Return digest.Digest( data )
		Return ""
	End Method

End Type

' DUMMY WORKSPACE SCANNER

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



Function LoadFile:String(filename:String)
	Local file:TStream = ReadStream( filename )
	If Not file Return ""
	'Print "- File Size: "+file.size()+" bytes"
	Local content:String = ReadString( file, file.size() )
	CloseStream file
	Return content
End Function

'DebugStop
Const WORKSPACE_FOLDER:String = "/home/si/dev/example/"
Local cache:TWorkspaceCache = New TWorkspaceCache( WORKSPACE_FOLDER )

'DebugStop

' Insert a dummy file
cache.addfile( New TTextDocument( "/home/si/dev/another/test.bmx" ))

' Request known files from cache
Local cachedfiles:TMap = cache.getfiles()

' Get actual files from workspace
Local filesystem:String[]
workspace_scan2( "/home/si/dev/example", filesystem )

' Now we have a list of existing files and a list of known files..
'DebugStop

For Local filename:String = EachIn filesystem
	' Is file known
	Local file:TTextDocument = New TTextDocument( filename )
	If cachedfiles.contains( filename )
		Local document:TDBDocument = TDBDocument( cachedfiles[filename] )
		If file.file_size <> document.size Or file.file_date <> document.date Or file.file_checksum <> document.checksum
			Print filename
			Print "- File has changed, scan it."
			cache.addFile( file )
			' Add it to the workspace here too.
		End If
		' Remove from cachedfiles as we've processed it.
		cachedfiles.remove( filename )
	Else
		Print filename
		Print "- New file - Add to DB and scan"
		cache.addFile( file )
		' Add it to the workspace here too.
	End If
Next

' Files remaining in cachedfiles list exist in database, but not on disk
For Local file:String = EachIn cachedfiles.keys()
	'If Not TDBDocument(known[file]).flag
	Print file
	Print "- This one has been deleted"
	cache.DeleteFile( file )
Next




