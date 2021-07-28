'
'	
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved
'	Based on JSON parser for Blitzmax, also by Si Dunford.

Rem ISSUES
* Line numbers are not consistent
* Print statements need to be removed
End Rem

Rem STATUS

* Create extendable Lexer
	DONE: Identifies WHITESPACE, NUMBER, ALPHA and 7BIT
	DONE: Lexer currently tokenises JSON as required
	DONE: Optional Compound symbols ( "<>", ">=", "<=" etc )
	TODO: Add comment to Lexer
		- DONE: Line comments (')
		- TODO: Multiline comments REM..ENDREM
	DONE: Add multiline separator (".." in blitzmax)
	DONE: Add custom definitions
	DONE: Symbol identifier should use an exentable definition
	DONE: Separate out JSON / BLITZMAX differences into JSONLexer & BlitzMaxLexer

* Create extendable Parser
	TODO
	
End Rem

Framework brl.retro
'Import brl.collections
'Import brl.linklist
Import brl.map
Import brl.reflection

Include "bin/loadfile().bmx"
Include "bin/TException.bmx"

Include "bin/TToken.bmx"
Include "bin/TSymbolTable.bmx"
Include "bin/TBlitzMaxLexer.bmx"
Include "bin/TBlitzMaxParser.bmx"

' Create Blitzmax Tables
RestoreData bmx_expressions
Global expressions:String = ReadTable()
RestoreData bmx_reservedwords
Global reservedwords:String = ReadTable()

Function ReadTable:String()
	Local word:String, words:String = ""
	ReadData( word )
	While word<>"#"
		words :+ "["+word+"]"
		ReadData( word )
	Wend	
	'Print Lower(words).Replace("[","~q").Replace("]","~q,")			' To create lowercase DefData! :)
	Return words
End Function





Type AST
End Type

'DebugStop
Local lexer:TLexer, parser:TParser

'	TEST THE LEXER AGAINST BLITZMAX

' Load a test file
DebugStop
lexer = New TBlitzMaxLexer( loadfile( "samples/capabilites.bmx" ) )
'lexer = New BlitzMaxLexer( loadfile( "samples/problematic-code.bmx" ) )
lexer.run()
Print( lexer.reveal() )
DebugStop

'	TEST THE PARSER AGAINST BLITZMAX

'Create a syntax tree
'DebugStop
parser = New TBlitzMaxParser( lexer )
parser.parse()

' Dump the Symbol table and Definition Table
Print( parser.reveal() )

' Load language grammar
'Local grammar:String = Loadfile( "blitzmax-grammar.txt" )

'local parser:TParser = new TBlitzMaxParser( lexer, grammar )

Print "COMPLETE"








