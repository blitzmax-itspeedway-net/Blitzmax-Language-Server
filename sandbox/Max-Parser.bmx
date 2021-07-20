'
'	
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved
'	Based on JSON parser for Blitzmax, also by Si Dunford.

Rem ISSUES
* Line numbers are not consistent
End Rem

Rem STATUS

* Create extendable Lexer
	DONE: Identifies WHITESPACE, NUMBER, ALPHA and 7BIT
	DONE: Lexer currently tokenises JSON as required
	DONE: Optional Compound symbols ( "<>", ">=", "<=" etc )
	TODO: Add comment to Lexer
		- DONE: Line comments (')
		- TODO: Multiline comments REM..ENDREM
	TODO: Add multiline separator (".." in blitzmax)
	TODO: Add custom definitions
	TODO: Symbol identifier should use an exentable definition
	TODO: Separate out JSON / BLITZMAX differences into JSONLexer & BlitzMaxLexer

* Create extendable Parser
	TODO
	
End Rem

Framework brl.retro
Import brl.collections
Import brl.map

Include "loadfile().bmx"

Type TLexer

	Private
	
	Const SYM_WHITESPACE:String = " ~t~n~r"
	Const SYM_SPACE:String = " "
    Const SYM_NUMBER:String = "0123456789"
    Const SYM_LOWER:String = "abcdefghijklmnopqrstuvwxyz"
    Const SYM_UPPER:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    Const SYM_ALPHA:String = SYM_LOWER+SYM_UPPER
	Const SYM_7BIT:String = SYM_SPACE+"!#$%&'()*+,-./"+SYM_NUMBER+":;<=>?@"+SYM_UPPER+"[]^_`"+SYM_LOWER+"{|}"
		
	Field source:String, reserved:String
	Field linenum:Int, linepos:Int	' Source 
	Field cursor:Int				' Lexer
	
	Field symbols:TQueue<TSymbol> = New TQueue<TSymbol>
	Field tokens:TMap = New TMap()
	
	' Language specific elements
	Field include_comments:Int = False
	Field linecomment_symbol:String = "'"
	Field valid_symbols:String = ""
	Field compound_symbols:String = ""	' Must be separated by a non-symbol
	
	Public
	
	Method New( source:String, reserved:String="" )
		Self.source = source
		Self.reserved = reserved
		cursor = 0
		linenum = 1 ; linepos = 0
		symbols.clear()
	End Method 

	Method define( class:String, list:String )
		'Local list:String[] = sym.split(",")
		tokens.insert( class, list )
	End Method

	Method run()
'DebugStop
		Try
			tokenise()
		Catch Exception:String
			Print "## EXCEPTION"
			Print Exception
		End Try
	End Method
	
	Method reveal:String()
		Local result:String
		For Local symbol:TSymbol = EachIn symbols
			result :+ symbol.reveal()+"~n"
		Next
		Return result
	End Method
	
	Private
	
	Method tokenise()
'DebugStop
		Local symbol:TSymbol	' = nextSymbol()
		Repeat
'DebugStop
			symbol = nextSymbol()
			If symbol.class<>"comment" Or include_comments
				symbols.enqueue( symbol )
			End If
		Until symbol.class = "EOF"
	End Method
	
	Method nextSymbol:TSymbol()
'DebugStop
		'Local name:String
		'Local symbol:TSymbol
		' Save the symbol position
		Local line:Int = linenum
		Local pos:Int = linepos
		' Identify the symbol
		Local char:String = PeekChar()
		If char=""
			Return New TSymbol( "EOF", "", line, pos )
		ElseIf char = linecomment_symbol						' Line Comment
			Return New TSymbol( "comment", ExtractLineComment(), line, pos )
		ElseIf Instr( valid_symbols, char, 1 )               ' Single character symbol
			PopChar()   ' Move to next character
			' Check for Compound symbols
			If Instr( compound_symbols, char+peekChar() )
				Return LexSymbol( char+PopChar(), line, pos )
			Else
				Return LexSymbol( char, line, pos )
			End If
		ElseIf char="~q"                            ' Quote indicates a string
			Return LexQuotedString( ExtractString(), line, pos )
		ElseIf Instr( SYM_NUMBER+"-", char )     	' Number
			Return LexNumber( ExtractNumber(), line, pos )
		ElseIf Instr( SYM_ALPHA, char )             ' Alphanumeric Identifier
			Return LexAlpha( ExtractIdent(), line, pos )
		Else
			PopChar()   ' Throw it away!
			Return LexInvalid( char, line, pos )
		End If		
	End Method
	
    ' Skips leading whitespace and returns next character
    Method PeekChar:String( IgnoredSymbols:String = SYM_WHITESPACE )
'DebugStop
        Local char:String
        Repeat
            If cursor>=source.length Return ""
            char = source[cursor..cursor+1]
            Select char
            Case "~r"   ' CR
				cursor :+1
            Case "~n"   ' LF
                linenum :+1
                linepos = 1
				cursor :+1
            Case " ","~t"
                linepos:+1
				cursor :+1
			Case "\"	' ESCAPE CHARACTER
				char = source[cursor..(cursor+1)]
				If char="\u"	'HEX DIGIT
					char = source[cursor..(cursor+5)]					
					cursor :+ 6
				Else
					cursor :+ 2
				End If
            End Select
        Until Not Instr( IgnoredSymbols, char )
        Return char
    End Method

	' Pops next character moving the cursor forward
    Method PopChar:String( IgnoredSymbols:String = SYM_WHITESPACE )
'DebugStop
        Local char:String
		'Local IgnoredSymbols:String = ""
		'
		'If ignoreWhitespace IgnoredSymbols = whitespace
		
        Repeat
            If source.length = 0 Return ""
            char = source[cursor..cursor+1]
            Select char
            Case "~r"   ' CR
                cursor :+ 1
            Case "~n"   ' LF
                linenum :+ 1
                linepos = 1
                cursor :+ 1
			Case "\"	' ESCAPE CHARACTER
				char = source[cursor..cursor+1]
				If char="\u"	'HEX DIGIT
					char = source[cursor..cursor+5]			
					cursor :+ 6
				Else
					cursor :+ 2
				End If
            Default
                linepos :+ 1
                cursor :+ 1
            End Select
        Until Not Instr( IgnoredSymbols, char )
        Return char
    End Method

    Method ExtractIdent:String()
'DebugStop
        Local text:String
        Local char:String = peekChar()
        While Instr( SYM_ALPHA, char ) And char<>""
            text :+ popChar()
            char = PeekChar("")
        Wend
        Return text
    End Method

	Method ExtractLineComment:String()
'DebugStop
		' Line comments extend until CRLF
        Local text:String
        Local char:String
		popChar()   ' Throw away leading comment starting character 
        Repeat
            char = PopChar( "~r" )		' Pop char but do not ignore whitespace
			' We don't need to actually return them... do we?
			text :+ char
        Until char="~n" Or char=""
		'If text.endswith( "~n" ) text = text[..(text.length-1)]
		text = Trim( text )
        Return text
	End Method
	
    Method ExtractNumber:String()
'DebugStop
        Local text:String
        Local char:String = peekChar()
		' Leading "-" (Negative number)
		If char="-"	
			text :+ popChar()
			char = peekChar()
		End If
		' Number
        While Instr( SYM_NUMBER, char ) And char<>""
            text :+ popChar()
            char = PeekChar()
        Wend
		' Decimal
		If char="."
			text :+ popChar()
            char = PeekChar()
			While Instr( SYM_NUMBER, char ) And char<>""
				text :+ popChar()
				char = PeekChar()
			Wend			
		End If
        Return text
    End Method

    Method ExtractString:String()
'DebugStop
        Local text:String = popChar()   ' This is the leading Quote
        Local char:String 
        Repeat
            char = PopChar( "" )		' Pop char, but do not ignore whitespace
			Select char.length
			Case 1
				text :+ char
			Case 2	' ESCAPE CHARACTER?
				Select char
				Case "\~q","\\","\/"
					text :+ char[1..]
				Case "\n","\r","\t"
					text :+ "~~"+char[1..]
				Case "\b"
					text :+ Chr(08)
				Case "\f"
					text :+ Chr(12)
				End Select
			Case 6	' HEXCODE
				Local hexcode:String = "$"+char[2..]
				Print char + " == " + hexcode
				text :+ Chr( Int( hexcode ) )
			End Select
        Until char="~q" Or char=""
        Return text
    End Method
	
	' EXTENDABLE METHODS
	
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
		Return New TSymbol( "symbol", text, line, pos )
	End Method
	
End Type

Type JSONLexer Extends TLexer

	Method New( text:String )
		Super.New( text:String )
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

Type BlitzMaxLexer Extends TLexer

	Method New( text:String )
		Super.New( text:String )
		Print "Starting MAXLexer"
		
		' Define Lexer options
		linecomment_symbol = "'"
		valid_symbols      = "#$%()*+,-.:;<=>[]^"
		compound_symbols   = "<> >= <= :+ :- :* :/ .."
		
		' Language specific definitions
		RestoreData bmx_expressions
		define( "expression", ReadTable() )
		RestoreData bmx_reservedwords
		define( "reserved", ReadTable() )

		' For debugging:
		include_comments = True
	End Method

	Method ReadTable:String()
		Local word:String, words:String = ""
		ReadData( word )
		While word<>"#"
			words :+ "["+word+"]"
			ReadData( word )
		Wend	
		'Print Lower(words).Replace("[","~q").Replace("]","~q,")			' To create lowercase DefData! :)
		Return words
	End Method

	Method LexAlpha:TSymbol( text:String, line:Int, pos:Int )
		Local criteria:String = "["+Lower(text)+"]"	' Case insensitive search criteria
		For Local token:String = EachIn tokens.keys()
			If Instr( String(tokens[token]), criteria ) Return New TSymbol( token, Lower(text), line, pos )
		Next
		Return New TSymbol( "alpha", text, line, pos )
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
	
	' Return int for the moment, until we have something to return
	Method Parse:Int()
	
	End Method
End Type

Type BlitzMaxParser Extends TParser
End Type

'DebugStop
Local lexer:TLexer

' TEST THE LEXER AGAINST JSON
Local text:String = loadfile( "example.json" )
'lexer = New JSONLexer(text )
'lexer.run()
'Print( lexer.reveal() )

' TEST THE LEXER AGAINST BLITZMAX

' Load a test file
'lexer = New BlitzmaxLexer( loadfile( "samples/capabilites.bmx" ) )
lexer = New BlitzmaxLexer( loadfile( "samples/problematic-code.bmx" ) )
lexer.run()
Print( lexer.reveal() )

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





