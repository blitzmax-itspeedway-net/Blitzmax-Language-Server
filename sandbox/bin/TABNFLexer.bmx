
'	ABNF Lexer
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	COMPOUND SYMBOLS

Const TK_HEXDIGIT:Int		= 512	'	%x

'	IDENTIFIERS

Const TK_Group:Int 			= 610	'	()
Const TK_Optional:Int 		= 611	'	[]
Const TK_Repeater:Int 		= 612	'	*
Const TK_NonTerminal:Int	= 613	'	<NAME>

Type TABNFLexer Extends TLexer

	Method New( text:String )
		Super.New( text )
		Print "Starting ABNF XLexer"
		
		' Define internal symbols
		'SYM_LINECOMMENT	= ";"
		'SYM_ALPHAEXTRA	= "-"	' Additional Characters allowed in ALPHA

		' Add compound symbols to definition
		RestoreData abnf_compound_symbols
		readCompoundSymbols()
		
		' Add tokens to definition
		RestoreData abnf_symbols
		readSymbols()

	End Method

	' Read symbols and add as tokens
	Method readTokens()
		Local id:Int, class:String
		ReadData id, class
		Repeat
			defined.insert( class, New TSymbol( id, class, class ) )
			ReadData id, class
		Until id = 0
	End Method

	' Read CompoundSymbols and add as tokens
	Method readCompoundSymbols()
		Local id:Int, value:String, class:String
		ReadData id, value, class
		Repeat
			defined.insert( value, New TSymbol( id, class, value ) )
			ReadData id, value, class
		Until id = 0
	End Method

	' Read symbols and add as tokens
	Method readSymbols()
		Local id:Int, value:String, class:String
		ReadData id, value, class
		Repeat
			lookup[Asc(value)]=class
			ReadData id, value, class
		Until id = 0
	End Method
	
	' Language specific tokeniser
	Method GetNextToken:TToken()
		Local char:String = peekchar()
		Local line:Int = linenum
		Local pos:Int = linepos
		'
		Select True
		Case char = "~q"	' Quote indicates a string
			Return New TToken( TK_QString, ExtractString(), line, pos, "qstring" )
		Case char = "<"		' indicates start of an identifier
'DebugStop
			PopChar()	' Skip LTH symbol
			Local text:String = ExtractIdent()
			char = peekchar()
			If char <> ">" Return New TToken( TK_Invalid, char, line, pos, "invalid" )
			popchar()	' Skip GTH symbol
			Return New TToken( TK_NonTerminal, text, line, pos, "non-terminal" )
		Case char = ";"			' Line comment
			Return New TToken( TK_Comment, ExtractLineComment(), line, pos, "comment" )
		Case Instr( SYM_NUMBER, char ) > 0	' Number
			Return New TToken( TK_Number, ExtractNumber(), line, pos, "number" )
		Case Instr( SYM_ALPHA, char )>0       	' Alphanumeric Identifier
			Local text:String = ExtractIdent( SYM_ALPHA+"-" )
			' Check if this is a named-token or just an alpha
			Local symbol:TSymbol = TSymbol( defined.valueforkey( Lower(text) ) )
			If symbol Return New TToken( TK_Identifier, text, line, pos, symbol.class )
			Return New TToken( TK_Alpha, text, line, pos, "alpha" )
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
End Type

' ABNF Tables

' Compound Symbols
#abnf_compound_symbols
'		ID				VALUE	CLASS
DefData TK_HEXDIGIT,    "%x",	"hexdigit"
DefData 0,"#","#"

' Single Symbols
' A single symbol uses it's ASCII code unles overwritten here
#abnf_symbols
'		ID				VALUE	CLASS
DefData TK_dquote,		"~q",	"dquote"
DefData TK_percent,		"%",	"percent"
DefData TK_lparen,		"(",	"lparen"		'	Group start
DefData TK_rparen,		")",	"rparen"		'	Group finish
DefData TK_asterisk,	"*",	"asterisk"		'	Repeat
DefData TK_solidus,		"/",	"solidus"		'	Selections
DefData TK_semicolon,	";",	"semicolon"		'	Line comment
DefData TK_equals,		"=",	"equals"
DefData TK_lcrotchet,	"[",	"lcrotchet"		'	Options start
DefData TK_rcrotchet,	"]",	"rcrotchet"		'	Options finish

DefData 0,"#","#"

Rem
DefData TK_exclamation, "!",	"exclamation"	'	(Double)
DefData TK_dquote,		"~q",	"dquote"
DefData TK_hash,		"'",	"hash"			'	(Float)
DefData TK_dollar,		"$",	"dollar"		'	(String)
DefData TK_percent,		"%",	"percent"		'	(Int)
DefData TK_ampersand,	"&",	"ampersand"
DefData TK_squote,		"'",	"squote"		' 	(line comment)
DefData TK_lparen,		"(",	"lparen"
DefData TK_rparen,		")",	"rparen"
DefData TK_asterisk,	"*",	"asterisk"
DefData TK_plus,		"+",	"plus"
DefData TK_comma,		",",	"comma"
DefData TK_hyphen,		"-",	"hyphen"
DefData TK_period,		".",	"period"
DefData TK_solidus,		"/",	"solidus"
DefData TK_colon,		":",	"colon"		
DefData TK_semicolon,	";",	"semicolon"	
DefData TK_lessthan,	"<",	"lessthan"
DefData TK_equals,		"=",	"equals"
DefData TK_greaterthan,	">",	"greaterthan"
DefData TK_question,	"?",	"question"
DefData TK_at,			"@",	"atsym"	
DefData TK_lcrotchet,	"[",	"lcrotchet"
DefData TK_backslash,	"\",	"backslash"
DefData TK_rcrotchet,	"]",	"rcrotchet"	
DefData TK_circumflex,	"^",	"circumflex"
DefData TK_underscore,	"_",	"underscore"
DefData TK_backtick,	"`",	"backtick"	
DefData TK_lbrace,		"{",	"lbrace"
DefData TK_pipe,		"|",	"pipe"
DefData TK_rbrace,		"}",	"rbrace"	
DefData TK_tilde,		"~~",	"tilde"
End Rem
