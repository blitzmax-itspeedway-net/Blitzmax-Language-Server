
'	Generic Lexer
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	VERSION:	1.7
'
'	CHANGE LOG
'	V1.0    20 JUL 21	Initial version using Queue<TSymbol> and String Tokens. 
'	V1.1    24 JUL 21	Replaced Queue<TSymbol> with a TList
'	V1.2    26 JUL 21	TSymbol renamed to TToken as thats what it holds!
'	V1.3    27 JUL 21	Reworked Tokens to use integer indexes
'	V1.4    28 JUL 21	Symbol lookup using string[] instead of TMap
'	V1.4.1  29 JUL 21	Removed argument "reserved" from new as it is not required
'	V1.5	 7 AUG 21	Added support for language specific tokeniser
'	V1.6	18 AUG 21	Added findNext() and getChunk(), skip(count:int), adjust(), fastfwd()
'	V1.7	26 AUG 21	Fixed issue with escaped characters including Hexcodes.

'	TODO:
'	Use TStringMap instead of TMap

'	SYMBOLS

Const SYM_WHITESPACE:String  = " ~t~r"
Const SYM_SPACE:String       = " "
Const SYM_EOL:String         = "~n"
Const SYM_DQUOTE:String      = "~q"
Const SYM_NUMBER:String      = "0123456789"
Const SYM_HEXDIG:String		 = SYM_NUMBER+"ABCDEF"
Const SYM_LOWER:String       = "abcdefghijklmnopqrstuvwxyz"
Const SYM_UPPER:String       = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
Const SYM_ALPHA:String       = SYM_LOWER+SYM_UPPER

'	GENERIC TOKENS

Const TK_TAB:Int 			= 9
Const TK_LF:Int 			= 10
Const TK_CR:Int 			= 13
Const TK_EOL:Int 			= TK_CR
Const TK_EOF:Int 			= $FFFF

'	SINGLE CHARACTER TOKENS

Const TK_exclamation:Int 	= 33	'	!
Const TK_dquote:Int 		= 34	'	"
Const TK_hash:Int 			= 35	'	#
Const TK_dollar:Int			= 36	'	$
Const TK_percent:Int		= 37	'	%
Const TK_ampersand:Int		= 38	'	&	
Const TK_squote:Int 		= 39	'	'
Const TK_lparen:Int			= 40	'	(
Const TK_rparen:Int			= 41	'	)
Const TK_asterisk:Int		= 42	'	*
Const TK_plus:Int			= 43	'	+
Const TK_comma:Int			= 44	'	,
Const TK_hyphen:Int			= 45	'	-
Const TK_period:Int			= 46	'	.
Const TK_solidus:Int		= 47	'	/
Const TK_colon:Int			= 58	'	:
Const TK_semicolon:Int		= 59	'	;
Const TK_lessthan:Int		= 60	'	<
Const TK_equals:Int			= 61	'	=
Const TK_greaterthan:Int	= 62	'	>
Const TK_question:Int		= 63	'	?
Const TK_at:Int				= 64	'	@
Const TK_lcrotchet:Int		= 91	'	[
Const TK_backslash:Int		= 92	'	\
Const TK_rcrotchet:Int		= 93	'	]
Const TK_circumflex:Int		= 94	'	^
Const TK_underscore:Int		= 95	'	_
Const TK_backtick:Int		= 96	'	`
Const TK_lbrace:Int			= 123	'	{
Const TK_pipe:Int			= 124	'	|
Const TK_rbrace:Int			= 125	'	}
Const TK_tilde:Int 			= 126	'	~

'	STANDARD IDENTIFIERS

Const TK_Invalid:Int 		= 600	'	Any token flagged as invalid
Const TK_Comment:Int 		= 601	'	Line Comment
Const TK_Alpha:Int			= 602	'	Unidentified identifier
Const TK_Identifier:Int		= 603	'	Identifier identifier
Const TK_QString:Int		= 604	'	Quoted String
Const TK_Number:Int			= 605	' 	Number

'	BASE LEXER

Type TCharStream
	Field source:String
	Field linenum:Int, linepos:Int	' Source 
	Field cursor:Int				' Stream cursor
	
    ' Skips leading whitespace and returns next character
    Method _DEPRECIATED_PeekChar:String( IgnoredSymbols:String = SYM_WHITESPACE )
'DebugStop
		Local peeker:Int = cursor
		If peeker>=source.length Return ""
        Local char:String = source[peeker..peeker+1]
        While Instr( IgnoredSymbols, char )
		'repeat
            'If cursor>=source.length Return ""
            'char = source[cursor..cursor+1]
            Select char
            Case "~r"   ' CR
				peeker :+1
            Case "~n"   ' LF
            '    linenum :+1
             '   linepos = 1
				peeker :+1
            Case " ","~t"
            '    linepos:+1
				peeker :+1
			'Case "\"	' ESCAPE CHARACTER
			'	char = source[cursor..(cursor+1)]
			'	If char="\u"	'HEX DIGIT
			'		char = source[cursor..(cursor+5)]					
			'		cursor :+ 6
			'	Else
			'		cursor :+ 2
			'	End If
            End Select
			' Next character:
			char = source[peeker..peeker+1]
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
		'
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
            Default
                linepos :+ 1
                cursor :+ 1
            End Select
        'Until Not Instr( IgnoredSymbols, char )
		Wend
		'
		' Move the cursor forward
		If char="~n"
			linenum :+ 1
			linepos = 1
			cursor :+ 1
		ElseIf char="\"	' ESCAPE CHARACTER
'DebugStop
			char = source[cursor..cursor+2]
			If char="\u"	'HEX DIGIT
				char = source[cursor..cursor+6]			
				cursor :+ 6
			Else
				cursor :+ 2
			End If
		Else
			linepos :+ 1
			cursor :+ 1
		End If
        Return char
    End Method
	
End Type

Type TLexer Extends TCharStream

	'Field SYM_LINECOMMENT:String = ""
	'Field SYM_ALPHAEXTRA:String  = ""	' Additional Characters allowed in ALPHA
			

	'Field lookahead:String			' Next character
	Field tokpos:TLink				' Current token cursor
	Field previous:TToken			' Previous token (For back-checking)
	
	Field tokens:TList = New TList()	' LIST OF TOKENS (TOKEN MAP)
	Field tokenkind:TToken				' CURRENT TOKEN
	
	Field defined:TMap = New TMap()		' List of defined tokens. Key is token, Value is class
	Field lookup:String[128]
	'Field tokentable:TStringMap = New TStringMap()	
	
	Method New( source:String )
		Self.source = source
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
		If tokens.isempty() Return "TOKEN STREAM IS EMPTY"
		Local result:String = "POSITION  ID    CLASS         VALUE~n"
		For Local token:TToken = EachIn tokens
			result :+ Replace(token.reveal(),"~n","\n")+"~n"
		Next
		Return result
	End Method

	' Set the token cursor to the first element
	Method reset()
		tokpos = tokens.firstLink()
	End Method
	
	' Gets the first token link
'	Method getFirstLink:TLink()
'		Return tokens.firstLink()
'	End Method

	' Gets the next token link
'	Method getNextLink:TLink( link:TLink )
'		If link=Null Return Null
'		Return link.nextlink
'	End Method

	' Gets the token at link
'	Method token:TToken( link:TLink )
'		If link Return TToken( link.value )
'		Return New TToken( TK_EOF,"", linenum, linepos, "EOF")
'	End Method
			
	' Scan token classes until we reach given
'	Method search:TLink( pos:TLink, class:Int )
'		While pos
'			Local token:TToken = TToken(pos.value)
'			If token.id = class Exit
'			pos = pos.nextlink
'		Wend
'		Return pos
'	End Method
	
	' Scan token classes until we reach given
'	Method find:TLink( pos:TLink, classes:Int[] )
'		While pos
'			Local token:TToken = TToken(pos.value)
'			If token.in(classes) Exit
'			pos = pos.nextlink
'		Wend
'		Return pos
'	End Method
	
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

    ' Peeks at a given position in the stack
    Method Peek:TToken( pos:TLink )
        If pos=Null Return New TToken( TK_EOF,"", linenum, linepos, "EOF")
		Return TToken( pos.value )
    End Method

    ' Matches the next token otherwise throws an error
	Method Expect:TToken( expectation:Int )
        If tokpos=Null ThrowException( "Unexpected end of file" )
		Local token:TToken = TToken( tokpos.value )
		tokpos = tokpos.nextlink
' 21/8/21, Changed returned token from NEXT token to THIS TOKEN
		If token.id = expectation Return token
'			If tokpos=Null Return New TToken( TK_EOF,"", linenum, linepos, "EOF")
'			Return TToken( tokpos.value )
'		End If
		ThrowException( "Unexpected token '"+token.value+"'", token.line, token.pos )
	End Method

    ' Matches the next token otherwise throws an error
	Method Expect:TToken( expectation:Int[] )
        If tokpos=Null ThrowException( "Unexpected end of file" )
		Local token:TToken = TToken( tokpos.value )
		tokpos = tokpos.nextlink
' 21/8/21, Changed returned token from NEXT token to THIS TOKEN
		If token.in( expectation ) Return token
'			If tokpos=Null Return New TToken( TK_EOF,"", linenum, linepos, "EOF")
'			Return TToken( tokpos.value )
'		End If
		ThrowException( "Unexpected token '"+token.value+"'", token.line, token.pos )
	End Method	
Rem
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
End Rem

    ' Matches the given token and throws it away (Useful for comments)
Rem
    Method skipOLD:String( expectedclass:String )
		Local tok:TToken = TToken( tokpos.value )
		Local skipped:String
		While tok.class = expectedclass
			skipped :+ tok.value
			tokpos = tokpos.nextlink
			tok = TToken( tokpos.value )
		Wend
		Return skipped
    End Method
End Rem

	' Skip all tokens until we find given
	Method fastfwd:TToken( given:Int )
'DebugStop
		Local token:TToken = TToken( tokpos.value )
		While token.notin( [TK_EOF, given] )
			tokpos = tokpos.nextlink
			token  = TToken( tokpos.value )
		Wend
		Return token
	End Method
	
	' Identifies if we have any token remaining
	Method isAtEnd:Int()
		Return (tokpos = Null )
	End Method	
	
	Method tokenise()
'DebugStop
		Local token:TToken	' = nextToken()
		
		'nextChar()			' Move to first character
		previous = New TToken( TK_Invalid, "", 0,0, "" ) ' Beginning of file (Stops NUL)
		Repeat
			token = nextToken()
			tokens.addlast( token )
			previous = token
		Until token.id = TK_EOF
		' Set the token cursor to the first element
		tokpos = tokens.firstLink()
	End Method
	
	' Get the next available token
	' Updated in V1.5
	Method nextToken:TToken()
		' Save the token position
		'Local line:Int = linenum
		'Local pos:Int = linepos
		
		' Catch end of file, end of line and control codes
		' Pass everything else to language specific tokeniser
		Local char:String = source[cursor..cursor+1]	'PeekChar()
		Local ascii:Byte = source[cursor]
		Local ch:String = Chr(ascii)
DebugStop
		Select True
		Case char = ""		' End of file
			Return New TToken( TK_EOF, "EOF", linenum, linepos, "EOF" )
		Case char = "~r"
			' Ignored
			
		Case char = "~n"	' End of line
			Local token:TToken = New TToken( TK_EOL, "EOL", linenum, linepos, "EOL" )
			popChar()
			Return token
		Case char < " "	Or char > "~~"		' Throw away control codes
			' Do nothing...
		Default
			Return getNextToken() ' char, linenum, linepos )
		End Select	
	End Method
	
			
Rem
	' V1.4 nextToken - DEPRECIATED IN 1.5
	Method nextToken14:TToken( char:String )
		Local char:String = PeekChar()
		' Save the token position
		Local line:Int = linenum
		Local pos:Int = linepos
		'
		Select True
		Case char = ""		' End of file
			Return New TToken( TK_EOF, "EOF", line, pos, "EOF" )
		Case char = "~n"	' End of line
			popChar()
			Return New TToken( TK_EOL, "EOL", line, pos, "EOL" )
		Case char = "~q"	' Quote indicates a string
			Return New TToken( TK_QString, ExtractString(), line, pos, "qstring" )
		Case char = SYM_LINECOMMENT				' Line comment
			Return New TToken( TK_Comment, ExtractLineComment(), line, pos, "comment" )
		Case Instr( SYM_NUMBER, char ) > 0	' Number
			Return New TToken( TK_Number, ExtractNumber(), line, pos, "number" )
		Case Instr( SYM_ALPHA, char )>0       	' Alphanumeric Identifier
			Local text:String = ExtractIdent()
			Local symbol:TSymbol = TSymbol( defined.valueforkey( Lower(text) ) )
			If symbol Return New TToken( TK_Identifier, text, line, pos, symbol.class )
			Return New TToken( TK_Alpha, text, line, pos, "alpha" )
		Case char < " "	Or char > "~~"		' Throw away control codes
			' Do nothing...
		'Case Instr( valid_symbols, char, 1 )            ' Single character symbol
		Default								' A Symbol
			PopChar()   ' Move to next character
			' Check for Compound symbol
			Local compound:String = char+peekChar()
'DebugStop
			Local symbol:TSymbol = TSymbol( defined.valueforkey( compound ) )
			If symbol
				popChar()
				Return New TToken( symbol.id, symbol.value, line, pos, symbol.class )
			End If
			' Lookup symbol definition
				'symbol = TSymbol( defined.valueforkey( char ) )
				'If symbol Return New TToken( symbol.id, char, line, pos, "symbol" ) 
			Local ascii:Int = Asc(char)
			Local class:String = lookup[ascii]
			If class<>"" Return New TToken( ascii, char, line, pos, class ) 
			' Default to ASCII code
			Return New TToken( ascii, char, line, pos, "symbol" )
		EndSelect		
	End Method
End Rem
	
	' Langage specific tokeniser
	Method getNextToken:TToken() Abstract
	


    Method ExtractIdent:String( bodySymbols:String = SYM_ALPHA )
'DebugStop
        Local text:String
        Local char:String = peekChar()
        While Instr( bodySymbols, char ) And char<>""
            text :+ popChar()
            char = PeekChar("")
        Wend
        Return text
    End Method

	Method ExtractLineComment:String()
'DebugStop
		' Line comments extend until CRLF
        Local text:String
        Local char:String, peek:String
		popChar()   ' Throw away leading comment starting character 
		peek = peekchar( "~r" )
        While peek<>"~n" And peek<>""
			text :+ popchar( "~r" )		' Pop char but do not ignore whitespace
			peek = peekchar( "~r" )
		Wend
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
        Local text:String
        Local char:String
		char = popChar()   ' This is the leading Quote (Skip that)
		char = popChar()	' This is the first character (The one we want)
        While char<>"~q" And char<>""
			Select char.length
			Case 1
				text :+ char
			Case 2	' ESCAPE CHARACTER?
				Select char
				Case "\~q","\\","\/"	;	text :+ char[1..]
				Case "\b"				;	text :+ Chr($08)		' Backspace
				Case "\f"				;	text :+ Chr($0C)		' Formfeed
				Case "\n"				;	text :+ "~n"			' Newline
				Case "\r"				;	text :+ "~r"			' Carriage Return
				Case "\t"				;	text :+ "~t"			' Tab
				End Select
			Case 6	' HEXCODE
				Local hexcode:String = "$"+char[2..]
'DebugLog( char + " == " + hexcode )
				text :+ Chr( Int( hexcode ) )
			End Select
            char = PopChar( "" )		' Pop char, but do not ignore whitespace
        Wend
        Return text
    End Method
Rem
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
End Rem

	Method findNext:TRegExMatch( text:String, regex:Int = False )
		Local re:TRegEx
		If Not regex text = "(?i)"+text
		re = TRegEx.Create( text )
'DebugStop
		Try
			Local matches:TRegExMatch = re.find( source, cursor )
			If matches Return matches
		Catch e:TRegExException
			' Do nothing, its not important!
		End Try
		Return Null
	End Method

	Method findNext:TRegExMatch( text:String, alt:String )
		Local re:TRegEx = TRegEx.Create( "(?i)"+text+"|"+alt )
'DebugStop
		Try
			Local matches:TRegExMatch = re.find( source, cursor )
			If matches Return matches
			'Return [match.substart(0),match.subEnd(0)+1]
		Catch e:TRegExException
			' Do nothing, its not important!
		End Try
		Return Null
	End Method
		
	Method getChunk:String( pos:Int )
		Local start:Int=cursor
		pos = Min( pos, source.length )	' Bounds check 
		cursor = pos
		Return adjust(source[start..pos])
	End Method
	
	' Skips a fixed amount of characters
	Method skip( count:Int )
		Local start:Int=cursor
		Local pos:Int = Min( cursor+count, source.length)
		adjust(source[cursor..pos])
		cursor = pos
	End Method
	
	' Adjusts the cursor and line position based on a string
	Method adjust:String( content:String )
		For Local i:Int = 0 Until content.length
			If content[i..i+1]="~n"
                linenum :+1
                linepos = 1
			Else
				linepos :+1
			End If
		Next
		Return content
	End Method
	 
End Type

' A Simple Symbol
Type TSymbol
	Field id:Int		' Symbol identifier
	Field class:String	' Symbol name
	Field value:String	' Actual text from source code (String, comment etc)
	
	Method New( id:Int, class:String, value:String )
		Self.id = id
		Self.class = class
		Self.value = value
	End Method
End Type
