SuperStrict

'	INITIALIZE MESSAGE HANDLER
'	(c) Si Dunford, July 2021, All Rights Reserved

'	SYNTAX:
'	onInitialize <filename>.bmx

'		VSCODE sends 
'			"rootUri" in the format "file:///home/si/dev/lsp"
'			"rootPath" in the format "/home/si/dev/lsp"

'		This version takes the "rootPath" variable so I don't need to mess about with URI's

'	RESULTS:
'	Cache should be created with files for each BMX file.

'TODO: Add decode of uri

Framework brl.retro
Import brl.map
'Import Text.RegEx

Print "# OnInitialize"
Print "# V0.0"
Print ""

If AppArgs.length<>2
	Print "- No filename specified"
	exit_(0)
End If

Local rootPath:String = AppArgs[1]

' Create a source tree
Local sourceTree:TMap = New TMap
Scanfolder( rootPath, sourceTree )

Print ""
For Local filepath:String = EachIn sourcetree.keys()
	Print filepath
Next

Function ScanFolder( path:String, tree:TMap )
	' Validate Folder
	If FileType(path)<>2 Return
	' Get folder content
	Local entries:String[] = LoadDir( path )
	' Loop through entries
	For Local entry:String = EachIn entries
		Local record:String = ""
		'
		Select FileType(path+"/"+entry)
		Case FILETYPE_FILE	'1
			Local ext:String = ExtractExt( entry )
			record = "["+ext+"]"
			Local action:String = "SKIP"
			If ext="bmx" action="PARSE"
			Print path[..32]+entry[..32]+record[..15]+action
		Case FILETYPE_DIR	'2
			record = "FOLDER"
			' Skip folders starting with "."
			If entry.startswith(".")
				Print path[..32]+entry[..32]+record[..15]+"SKIP"
			Else
				Print path[..32]+entry[..32]+record[..15]+"SCAN"
				scanfolder( path+"/"+entry, tree )
			End If
		Default
			' Not interested in other types
			record = "TYPE("+FileType(path+entry)+")"
			Print path[..32]+entry[..32]+record[..15]+"SKIP"
		End Select
	Next

End Function

Type TDocument
	Field filename:String	' Same as sourcetree[key]
	Field path:String
	Field modified:Int		' Has the file been modified (Requiring a re-scan?)
End Type
