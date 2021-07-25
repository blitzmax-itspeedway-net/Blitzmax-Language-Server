
'	BlitzMax Lexer
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Include "TLexer.bmx"

Type TBlitzMaxLexer Extends TLexer

	Method New( text:String )
		Super.New( text )
		Print "Starting MAXLexer"
		
		' Define Lexer options
		linecomment_symbol = "'"
		valid_symbols      = "#$%()*+,-.:;<=>[]^"
		compound_symbols   = "<> >= <= :+ :- :* :/ .."
		
		' Language specific definitions
		Local data:String[]
		'DebugStop
		RestoreData bmx_expressions
		readKeywords()
		'define( "expression", loadTable() )
		RestoreData bmx_reservedwords
		readKeywords()
		RestoreData bmx_symbols
		readSymbols()
		'define( "reserved", loadTable() )

		' For debugging:
		include_comments = True
	End Method

	' Read symbols and add as tokens
	Method readKeywords()
		Local word:String 
		ReadData word 
		Repeat
			tokens.insert( word, word )
			ReadData word 
		Until word = "#"
	End Method

	' Read symbols and add as tokens
	Method readSymbols()
		Local symbol:String, class:String
		ReadData symbol, class
		Repeat
			tokens.insert( symbol, class )
			ReadData symbol, class 
		Until class = "#"
	End Method
	
	'Method LexAlpha:TSymbol( text:String, line:Int, pos:Int )
	'	Local criteria:String = "["+Lower(text)+"]"	' Case insensitive search criteria
	'	For Local token:String = EachIn tokens.keys()
'Print( String(tokens[token]) )
	'		If Instr( String(tokens[token]), criteria ) Return New TSymbol( token, Lower(text), line, pos )
	'	Next
	'	Return New TSymbol( "alpha", text, line, pos )
	'End Method
		
End Type

' Blitzmax Tables
#bmx_expressions
DefData "and","false","mod","new","not","null","or","pi","sar","self","shl","shr","sizeof","super","true","varptr"
DefData "#"

#bmx_reservedwords
DefData "alias","and","asc","assert"
DefData "byte"
DefData "case","catch","chr","const","continue"
DefData "defdata","default","delete","double"
DefData "eachin","else","elseif","end","endextern","endfunction","endif","endinterface","endmethod","endrem","endselect","endstruct","endtry","endtype","endwhile","exit","export","extends","extern"
DefData "false","field","final","finally","float","for","forever","framework","function"
DefData "global","goto"
DefData "if","implements","import","incbin","incbinlen","incbinptr","include","int","interface"
DefData "len","local","long"
DefData "method","mod","module","moduleinfo"
DefData "new","next","nodebug","not","null"
DefData "object","operator","or"
DefData "pi","private","protected","ptr","public"
DefData "readdata","readonly","release","rem","repeat","restoredata","return"
DefData "sar","select","self","shl","short","shr","sizeof","size_t","step","strict","string","struct","super","superstrict"
DefData "then","throw","to","true","try","type"
DefData "uint","ulong","until"
DefData "var","varptr"
DefData "wend","where","while"
DefData "#"

#bmx_symbols
' Single Symbols
DefData "!","exclamation",		"~q","dquote",		"#","hash"
DefData "$","dollar", 			"%","percent", 		"&","ampersand"
DefData "'","apostrope", 		"(","lparen", 		")","rparen"
DefData "*","asterisk", 		"+","plus", 		",","comma"
DefData "-","hyphen", 			".","period", 		"/","solidus"
DefData ":","colon", 			";","semicolon",	 "<","less"
DefData "=","equals", 			">","greater", 		"?","question"
DefData "@","atsym", 			"[","lcrotchet", 	"\","backslash"
DefData "]","rcrotchet", 		"^","circumflex", 	"_","underscore"
DefData "`","backtick", 		"{","lbrace", 		"|","pipe"
DefData "}","rbrace", 			"~~","tilde"

' Compound Symbols
DefData "<=","lessequal",		"<>","inequal",		">=","greaterequal"
DefData "..","continues",		":+","assignplus",	":-","assignminus"
DefData ":*","assignmultiply",	":/","assigndivide"

DefData "#","#"

