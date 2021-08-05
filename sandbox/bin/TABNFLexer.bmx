
'	ABNF Lexer
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	COMPOUND SYMBOLS

Const TK_HEXDIGIT:Int		= 512	'	%x

'	IDENTIFIERS

Const TK_Group:Int 			= 610	'	()
Const TK_Optional:Int 		= 611	'	[]
Const TK_Repeater:Int 		= 612	'	*

Type TABNFLexer Extends TLexer

	Field SYM_LINECOMMENT:String = ";"
	Field SYM_ALPHAEXTRA:String  = "-"	' Additional Characters allowed in ALPHA

	Method New( text:String )
		Super.New( text )
		Print "Starting ABNF XLexer"
		
		'DebugStop

		' Add compound symbols to definition
		RestoreData abnf_compound_symbols
		readCompoundSymbols()
		
		' Add tokens to definition
		RestoreData abnf_symbols
		readSymbols()

		'RestoreData abnf_terminals
		'readTokens()

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
