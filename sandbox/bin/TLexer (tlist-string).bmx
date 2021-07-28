
'	Generic Lexer
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Type TLexer

	Private
	
	Const SYM_WHITESPACE:String = " ~t~r"
	Const SYM_SPACE:String = " "
    Const SYM_NUMBER:String = "0123456789"
    Const SYM_LOWER:String = "abcdefghijklmnopqrstuvwxyz"
    Const SYM_UPPER:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    Const SYM_ALPHA:String = SYM_LOWER+SYM_UPPER
	Const SYM_7BIT:String = SYM_SPACE+"!#$%&'()*+,-./"+SYM_NUMBER+":;<=>?@"+SYM_UPPER+"[]^_`"+SYM_LOWER+"{|}"
		
	Field source:String, reserved:String
	Field linenum:Int, linepos:Int	' Source 
	Field cursor:Int				' Lexer (Char cursor)
	Field tokpos:TLink				' Current token cursor
	
	Field tokens:TList = New TList()
	Field defined:TMap = New TMap()	' List of known tokens. Key is token, Value is class
	
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
		Local result:String
		For Local token:TToken = EachIn tokens
			result :+ token.reveal()+"~n"
		Next
		Return result
	End Method

    ' Gets the next token from the list
    Method getNext:TToken()	' ignorelist:String="" )
        'If tokpos=Null Or tokens.isempty() Return New TToken( "EOF","", linenum, linepos)
        If tokpos=Null Return New TToken( "EOF","", linenum, linepos)
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
?debug
If tokpos=Null
	Print "PEEK: Null"
Else
	Print "PEEK: "+TToken(tokpos.value).value+":"+TToken(tokpos.value).class
End If
?
        If tokpos=Null Return New TToken( "EOF","", linenum, linepos)
		If expectedclass="" Return TToken( tokpos.value )
		Local peek:TToken = TToken( tokpos.value )
		If peek.class=expectedclass Return peek
        Return Null
    End Method

    ' Peeks the top of the token Stack
    Method Peek:TToken( expectedclass:String[] )
        'If tokens.isempty() Return New TToken( "EOF","", linenum, linepos)
?debug
If tokpos=Null Print "PEEK: Null"
?
        If tokpos=Null Return New TToken( "EOF","", linenum, linepos)
		If expectedclass=[] Return TToken( tokpos.value )
		Local peek:TToken = TToken( tokpos.value )
		For Local expected:String = EachIn expectedclass
?debug
If tokpos=Null
	Print "PEEK: Null"
Else
	Print "PEEK: "+TToken(tokpos.value).value+":"+TToken(tokpos.value).class
End If
?
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
			If token.class<>"comment" Or include_comments
				tokens.addlast( token )
			End If
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
'If line>=3 And pos>=14 DebugStop
		' Identify the token		
		If char=""
			Return New TToken( "EOF", "", line, pos )
		ElseIf char="~n"
			popChar()
			Return New TToken( "EOL", "CR", line, pos )
		ElseIf char = linecomment_symbol						' Line Comment
			Return New TToken( "comment", ExtractLineComment(), line, pos )
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
	
	' EXTENDABLE LEXER METHODS
	
	Method LexAlpha:TToken( text:String, line:Int, pos:Int )
		Local token:String = String( defined.valueforkey( Lower(text) ))
		If token = ""
			Return New TToken( "alpha", text, line, pos )
		Else
			Return New TToken( token, text, line, pos )
		End If
	End Method

	Method LexInvalid:TToken( text:String, line:Int, pos:Int )
		Return New TToken( "invalid", text, line, pos )
	End Method

	Method LexNumber:TToken( text:String, line:Int, pos:Int )
		Return New TToken( "number", text, line, pos )
	End Method
	
	Method LexQuotedString:TToken( text:String, line:Int, pos:Int )
		Return New TToken( "string", text, line, pos )
	End Method

	Method LexSymbol:TToken( text:String, line:Int, pos:Int )
		Local token:String = String( defined.valueforkey( text ))
		If token = ""
			Return New TToken( "symbol", text, line, pos )
		Else
			Return New TToken( token, text, line, pos )
		End If
	End Method
	
End Type