SuperStrict

'	DOCUMENT PARSER AND INDEXER
'	(c) Si Dunford, July 2021, All Rights Reserved

'	SYNTAX:
'	parsedoc <filename>.bmx

'	RESULTS:
'	filename.idx
'	- Initially a text file for diagnostics

Framework brl.retro
'Import brl.list

'include "bin/parser.bmx" 


Print "# ScareParser"
Print "# V0.0"
Print ""

If AppArgs.length<>1 Or Instr( "|-h|-?|-help|/h|/?|/help|", "|"+Lower(AppArgs[1])+"|" )>0
	Print "Syntax:"
	Print ""
	Print "docparse [-h|-?|-help|/h|/?|/help] - HELP"
	Print "docparse <filename.bmx>            - Parse document"
	exit_(0)
End If

Local document:String = AppArgs[1]
If FileType(document) <> 2
	Print "File '"+document+"' does not exist"
	exit_(1)
End If





