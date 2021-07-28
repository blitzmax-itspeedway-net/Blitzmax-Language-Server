
'	Generic Lexer
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	VERSION:	1.4
'
'	V1.0  -- JUL 21  Initial version using Queue<TSymbol> and String Tokens. 
'	V1.1  24 JUL 21  Replaced Queue<TSymbol> with a TList
'	V1.2  26 JUL 21  TSymbol renamed to TToken as thats what it holds!
'	V1.3  27 JUL 21  Reworked Tokens to use integer indexes
'	V1.4  28 JUL 21  Symbol lookup using string[] instead of TMap

'	TODO:
'	Speed this up by using a lookup table for single character symbols instead of a TMAP

Include "const-symbols.bmx"

Type TLexer

	Private
			
	Field source:String, reserved:String
	Field linenum:Int, linepos:Int	' Source 
	Field cursor:Int				' Lexer (Char cursor)
	Field tokpos:TLink				' Current token cursor
	
	Field tokens:TList = New TList()
	Field defined:TMap = New TMap()	' List of known tokens. Key is token, Value is class
	Field lookup:String[128]
	
	' Language specific elements
	'Field include_comments:Int = False
	'Field linecomment_symbol:String = "'"
	'Field valid_symbols:String = ""
	'Field compound_symbols:String = ""	' Must be separated by a non-symbol
	
	Public
	
	Method New( source:String, reserved:String="" )
		Self.source = source
		Self.reserved = reserved
		cursor = 0
		linenum = 1 ; linepos = 0
		tokens.clear()
	End Method 

	Method defineToken( token:String, class:String )
		defined.insert( token, class )
	End Method

	Method run()
		Try
			tokenise()
		Catch Exception:String
			Print "## EXCEPTION"
			Print Exception
		End Try
	End Method

	' Produce a token table to help debugging
	Method reveal:String()
		Local result:String = "POSITION  ID    CLASS       VALUE~n"
		For Local token:TToken = EachIn tokens
			result :+ token.reveal()+"~n"
		Next
		Return result
	End Method

    ' Gets the next token from the list
    Method getNext:TToken()	' ignorelist:String="" )
        'If tokpos=Null Or tokens.isempty() Return New TToken( "EOF","", linenum, linepos)
        If tokpos=Null Return New TToken( TK_EOF,"", linenum, linepos, "EOF")
		Local tok:Object = tokpos.value
		tokpos = tokpos.nextlink
        Return TToken(tok)
    End Method

    ' Pops the first token from the stack
    'Method Pop:TToken()	' ignorelist:String="" )
    '    If tokens.isempty() Return New TToken( "EOF","", linenum, linepos)
    '    Return tokens.dequeue()
    'End Method

    ' Peeks the top of the token Stack
    Method Peek:TToken( expectedclass:String="" )
        'If tokens.isempty() Return New TToken( "EOF","", linenum, linepos)

        If tokpos=Null Return New TToken( TK_EOF,"", linenum, linepos, "EOF")
		If expectedclass="" Return TToken( tokpos.value )
		Local peek:TToken = TToken( tokpos.value )
		If peek.class=expectedclass Return peek
        Return Null
    End Method

    ' Peeks the top of the token Stack
    Method Peek:TToken( expectedclass:String[] )
        'If tokens.isempty() Return New TToken( "EOF","", linenum, linepos)
        If tokpos=Null Return New TToken( TK_EOF,"", linenum, linepos, "EOF")
		If expectedclass=[] Return TToken( tokpos.value )
		Local peek:TToken = TToken( tokpos.value )
		For Local expected:String = EachIn expectedclass
			If peek.class=expected Return peek
		Next
        Return Null
    End Method

    ' Matches the next token otherwise throws an error
    Method Expect:TToken( expectedclass:String, expectedvalue:String="" )
		Local tok:TToken = TToken( tokpos.value )
		If tok.class = expectedclass
			If expectedvalue = "" Or tok.value = expectedvalue 
				tokpos = tokpos.nextlink
				Return tok
			End If
		End If
		ThrowException( "Unexpected token '"+tok.value+"'", tok.line, tok.pos )
    End Method

    ' Matches the given token and throws it away (Useful for comments)
    Method skip:String( expectedclass:String )
		Local tok:TToken = TToken( tokpos.value )
		Local skipped:String
		While tok.class = expectedclass
			skipped :+ tok.value
			tokpos = tokpos.nextlink
			tok = TToken( tokpos.value )
		Wend
		Return skipped
    End Method

	' Identifies if we have any token remaining
	Method isAtEnd:Int()
		Return (tokpos = Null )
	End Method	
	
	Private
	
	Method tokenise()
'DebugStop
		Local token:TToken	' = nextToken()
		Repeat
'DebugStop
			token = nextToken()
			'If token.id <> TK_Comment	' Line comment
			tokens.addlast( token )
			'End If
		Until token.class = "EOF"
		' Set the token cursor to the first element
		tokpos = tokens.firstLink()
	End Method
	
	Method nextToken:TToken()
'DebugStop
		'Local name:String
		'Local token:TToken
		Local char:String = PeekChar()
		' Save the token position
		Local line:Int = linenum
		Local pos:Int = linepos
		' Identify the token
		Select True
		Case char = ""		' End of file
			Return New TToken( TK_EOF, "", line, pos, "EOF" )
		Case char = "~n"	' End of line
			popChar()
			Return New TToken( TK_EOL, "CR", line, pos, "EOL" )
		Case char = "~q"	' Quote indicates a string
			Return New TToken( TK_QuotedString, ExtractString(), line, pos, "string" )
		Case char = SYM_LINECOMMENT				' Line comment
			Return New TToken( TK_Comment, ExtractLineComment(), line, pos, "comment" )
		Case Instr( SYM_NUMBER+"-", char ) > 0	' Number
			Return New TToken( TK_Number, ExtractNumber(), line, pos, "number" )
		Case Instr( SYM_ALPHA, char )>0       	' Alphanumeric Identifier
			Local text:String = ExtractIdent()
			Local symbol:TSymbol = TSymbol( defined.valueforkey( Lower(text) ) )
			If symbol Return New TToken( TK_Identifier, text, line, pos, "identifier" )
			Return New TToken( TK_Alpha, text, line, pos, "alpha" )
		Case char < " "	Or char > "~~"		' Throw away control codes
			' Do nothing...
		'Case Instr( valid_symbols, char, 1 )            ' Single character symbol
		Default								' A Symbol
			PopChar()   ' Move to next character
			' Check for Compound symbol
			Local compound:String = char+peekChar()
			Local symbol:TSymbol = TSymbol( defined.valueforkey( compound ) )
			If symbol Return New TToken( symbol.id, symbol.name, line, pos, "symbol" )
			' Lookup symbol definition
				'symbol = TSymbol( defined.valueforkey( char ) )
				'If symbol Return New TToken( symbol.id, char, line, pos, "symbol" ) 
			Local ascii:Int = Asc(char)
			'Local name:String = lookup[ascii]
			'If name<>"" Return New TToken( ascii, name, line, pos, "symbol" ) 
			' Default to ASCII code
			Return New TToken( ascii, char, line, pos, "symbol" )
		EndSelect		
	End Method
	
    ' Skips leading whitespace and returns next character
    Method PeekChar:String( IgnoredSymbols:String = SYM_WHITESPACE )
'DebugStop
		If cursor>=source.length Return ""
        Local char:String = source[cursor..cursor+1]
        While Instr( IgnoredSymbols, char )
		'repeat
            'If cursor>=source.length Return ""
            'char = source[cursor..cursor+1]
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
			' Next character:
			char = source[cursor..cursor+1]
        'Until Not Instr( IgnoredSymbols, char )
		Wend
        Return char
    End Method

	' Pops next character moving the cursor forward
    Method PopChar:String( IgnoredSymbols:String = SYM_WHITESPACE )
'DebugStop
        'Local char:String
		If cursor>=source.length Return ""
        Local char:String = source[cursor..cursor+1]
		' Ignore leading whitespace
        While Instr( IgnoredSymbols, char )
		'Local IgnoredSymbols:String = ""
		'
		'If ignoreWhitespace IgnoredSymbols = whitespace
		
        'Repeat
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
            'Default
            '    linepos :+ 1
            '    cursor :+ 1
            End Select
        'Until Not Instr( IgnoredSymbols, char )
		Wend
		' Move the cursor forward
		If char="~n"
			linenum :+ 1
			linepos = 1
			cursor :+ 1
		Else
			linepos :+ 1
			cursor :+ 1
		End If
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
	

End Type

' A Simple Symbol
Type TSymbol
	Field id:Int		' Symbol identifier
	Field name:String	' Symbol name
	Field text:String	' Actual text from source code (String, comment etc)
	
	Method New( id:Int, name:String, text:String )
		Self.id = id
		Self.name = name
		Self.text = text
	End Method
End Type
