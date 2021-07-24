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
Import brl.collections
Import brl.map

Include "loadfile().bmx"

Include "bin/TBlitzMaxLexer.bmx"

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



Type JSONLexer Extends TLexer

	Method New( text:String )
		Super.New( text )
		Print "Starting JSONLexer"

		' Define Lexer options
		linecomment_symbol = ""			' We don't have comments in JSON
		valid_symbols      = "{}[]:,"
	End Method

	Method LexAlpha:TSymbol( text:String, line:Int, pos:Int )
		Return New TSymbol( "alpha", text, line, pos )
	End Method

	Method LexInvalid:TSymbol( text:String, line:Int, pos:Int )
		Return New TSymbol( "invalid", text, line, pos )
	End Method

	Method LexNumber:TSymbol( text:String, line:Int, pos:Int )
		Return New TSymbol( "number", text, line, pos )
	End Method
	
	Method LexQuotedString:TSymbol( text:String, line:Int, pos:Int )
		Return New TSymbol( "string", text, line, pos )
	End Method

	Method LexSymbol:TSymbol( text:String, line:Int, pos:Int )
		Return New TSymbol( text, text, line, pos )
	End Method
	
End Type


Type TSymbol
	Field class:String, value:String, line:Int, pos:Int

    Method New( class:String, value:String, line:Int, pos:Int )
        'print( "## "+symbol+", "+value+", "+line+", "+pos )
        Self.class = class
        Self.value = value
        Self.line = line
        Self.pos = pos 
    End Method

	Method reveal:String()
		Return (line+","+pos)[..9] + class[..12] + value
	End Method
	
End Type

Type TParser
	Field lexer:TLexer
	
	Method New( lexer:TLexer )
		Self.lexer = lexer
	End Method
	
	Method run()	
	End Method
	
	Method reveal:String()
	End Method
	
	Private
	
	' Expect the given symbol and if not, raise an exception
	Method expect( symbol:String )
		If False
			Throw "Unexpected symbol"
		End If
	End Method
	
End Type

Type JSONParser Extends TParser
	Method New( lexer:TLexer )
		Super.New( lexer )
		Print "Starting JSONParser"
	End Method
	
	
	
End Type

'	A LANGUAGE SYNTAX IS CURRENTLY UNAVAILABLE
'	THIS IS THEREFORE HARDCODED AT THE MOMENT
'	IT WILL BE RE-WRITTEN WHEN SYNTAX IS DONE

Type BlitzMaxParser Extends TParser

	Field strictmode:Int = 0

	Method New( lexer:TLexer )
		Super.New( lexer )
		Print "Starting BlitzMaxParser"
	End Method

	' It all starts, as they say, with a story...	
	Method run()
DebugStop
		Try
			'Repeat
			'	Local blockcomments:String = skip( "comment" )
			
			
			Rem
			Need To:
			get block comments that preceed the Next block
			
			
			getformalblock
		
			' Optional STRICT or SUPERSTRICT
			Do_Strict_Mode()
			' Optional Framework
			Do_Framework()
			' Optional Imports
			Do_Import()
			
			End Rem
		Catch Exception:String
			Print Exception
		End Try
		
	End Method
	
	Private
	
	Method Do_Strict_Mode()
		lexer.skip( "comment" )
		Local sym:TSymbol = lexer.peek( "reserved" )
		If Not sym Return
		Select sym.value
		Case "strict"		;	strictmode = 1
		Case "superstrict"	;	strictmode = 2
		End Select
		If strictmode>0 lexer.getnext()
	End Method
	
	Method Do_Framework()
		lexer.skip( "comment" )
		Local sym:TSymbol = lexer.peek( "reserved" )
		If Not sym Return
		If sym.value="framework"
			lexer.getnext()	' framework
			lexer.expect( "alpha" )
			lexer.expect( "symbol",".")
			lexer.expect( "alpha" )
		End If
	End Method

	Method Do_Imports()
		lexer.skip( "comment" )
		Local sym:TSymbol = lexer.peek( "reserved" )
		If Not sym Return
		If sym.value="import"
			lexer.getnext()	' framework
			lexer.expect( "alpha" )
			lexer.expect( "symbol",".")
			lexer.expect( "alpha" )
		End If
	End Method	
	
End Type

'DebugStop
Local lexer:TLexer, parser:TParser

'	TEST THE LEXER AGAINST JSON

'lexer = New JSONLexer( loadfile( "samples/example.json" ) )
'lexer.run()
'Print( lexer.reveal() )
'DebugStop

'	TEST THE PARSER AGAINST JSON

'Create a syntax tree
'parser = New JSONParser( lexer )
'parser.run()
'Print( parser.reveal() )


'	TEST THE LEXER AGAINST BLITZMAX

' Load a test file
lexer = New BlitzMaxLexer( loadfile( "samples/capabilites.bmx" ) )
'lexer = New BlitzMaxLexer( loadfile( "samples/problematic-code.bmx" ) )
lexer.run()
Print( lexer.reveal() )
debugstop
'	TEST THE PARSER AGAINST BLITZMAX

'Create a syntax tree
'DebugStop
parser = New BlitzMaxParser( lexer )
parser.run()
Print( parser.reveal() )

' Load language grammar
'Local grammar:String = Loadfile( "blitzmax-grammar.txt" )

'local parser:TParser = new TBlitzMaxParser( lexer, grammar )

Print "COMPLETE"


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





