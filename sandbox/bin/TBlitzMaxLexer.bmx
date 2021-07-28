
'	BlitzMax Lexer
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Include "TLexer.bmx"

Type TBlitzMaxLexer Extends TLexer

	Method New( text:String )
		Super.New( text )
		Print "Starting MAXLexer"
		
		' Add tokens to definition
		RestoreData bmx_compound_symbols
		readCompoundSymbols()

		RestoreData bmx_reservedwords
		readTokens()

	End Method

	' Read symbols and add as tokens
	Method readTokens()
		Local id:Int, token:String
		ReadData id, token
		Repeat
			defined.insert( token, New TSymbol( id, token, token ) )
			ReadData id, token
		Until id = 0
	End Method

	' Read symbols and add as tokens
	Method readCompoundSymbols()
		Local id:Int, token:String, name:String
		ReadData id, token, name
		Repeat
			defined.insert( token, New TSymbol( id, name, token ) )
			ReadData id, token, name
		Until id = 0
	End Method
	
	' Read symbols and add as tokens
	'Method readSymbols()
	'	Local id:Int, char:String, name:String
	'	ReadData char, name
	'	Repeat
	'		defined.insert( char, New TSymbol( Asc(char), name, char )
	'		ReadData char, name
	'	Until name = "#"
	'End Method
	
	'Method LexAlpha:TToken( text:String, line:Int, pos:Int )
	'	Local criteria:String = "["+Lower(text)+"]"	' Case insensitive search criteria
	'	For Local token:String = EachIn tokens.keys()
'Print( String(tokens[token]) )
	'		If Instr( String(tokens[token]), criteria ) Return New TToken( token, Lower(text), line, pos )
	'	Next
	'	Return New TToken( "alpha", text, line, pos )
	'End Method
		
End Type

' Blitzmax Tables

#bmx_reservedwords
DefData TK_ALIAS,        "alias"
DefData TK_AND,          "and"
DefData TK_ASC,          "asc"
DefData TK_ASSERT,       "assert"
DefData TK_BYTE,         "byte"
DefData TK_CASE,         "case"
DefData TK_CATCH,        "catch"
DefData TK_CHR,          "chr"
DefData TK_CONST,        "const"
DefData TK_CONTINUE,     "continue"
DefData TK_DEFDATA,      "defdata"
DefData TK_DEFAULT,      "default"
DefData TK_DELETE,       "delete"
DefData TK_DOUBLE,       "double"
DefData TK_EACHIN,       "eachin"
DefData TK_ELSE,         "else"
DefData TK_ELSEIF,       "elseif"
DefData TK_END,          "end"
DefData TK_ENDEXTERN,    "endextern"
DefData TK_ENDFUNCTION,  "endfunction"
DefData TK_ENDIF,        "endif"
DefData TK_ENDINTERFACE, "endinterface"
DefData TK_ENDMETHOD,    "endmethod"
DefData TK_ENDREM,       "endrem"
DefData TK_ENDSELECT,    "endselect"
DefData TK_ENDSTRUCT,    "endstruct"
DefData TK_ENDTRY,       "endtry"
DefData TK_ENDTYPE,      "endtype"
DefData TK_ENDWHILE,     "endwhile"
DefData TK_EXIT,         "exit"
DefData TK_EXPORT,       "export"
DefData TK_EXTENDS,      "extends"
DefData TK_EXTERN,       "extern"
DefData TK_FALSE,        "false"
DefData TK_FIELD,        "field"
DefData TK_FINAL,        "final"
DefData TK_FINALLY,      "finally"
DefData TK_FLOAT,        "float"
DefData TK_FOR,          "for"
DefData TK_FOREVER,      "forever"
DefData TK_FRAMEWORK,    "framework"
DefData TK_FUNCTION,     "function"
DefData TK_GLOBAL,       "global"
DefData TK_GOTO,         "goto"
DefData TK_IF,           "if"
DefData TK_IMPLEMENETS,  "implements"
DefData TK_IMPORT,       "import"
DefData TK_INCBIN,       "incbin"
DefData TK_INCBINLEN,    "incbinlen"
DefData TK_INCBINPTR,    "incbinptr"
DefData TK_INCLUDE,      "include"
DefData TK_INT,          "int"
DefData TK_INTERFACE,    "interface"
DefData TK_LEN,          "len"
DefData TK_LOCAL,        "local"
DefData TK_LONG,         "long"
DefData TK_METHOD,       "method"
DefData TK_MOD,          "mod"
DefData TK_MODULE,       "module"
DefData TK_MODULEINFO,   "moduleinfo"
DefData TK_NEW,          "new"
DefData TK_NEXT,         "next"
DefData TK_NODEBUG,      "nodebug"
DefData TK_NOT,          "not"
DefData TK_NULL,         "null"
DefData TK_OBJECT,       "object"
DefData TK_OPERATOR,     "operator"
DefData TK_OR,           "or"
DefData TK_PI,           "pi"
DefData TK_PRIVATE,      "private"
DefData TK_PROTECTED,    "protected"
DefData TK_PTR,          "ptr"
DefData TK_PUBLIC,       "public"
DefData TK_READDATA,     "readdata"
DefData TK_READONLY,     "readonly"
DefData TK_RELEASE,      "release"
DefData TK_REM,          "rem"
DefData TK_REPEAT,       "repeat"
DefData TK_RESTOREDATA,  "restoredata"
DefData TK_RETURN,       "return"
DefData TK_SAR,          "sar"
DefData TK_SELECT,       "select"
DefData TK_SELF,         "self"
DefData TK_SHL,          "shl"
DefData TK_SHORT,        "short"
DefData TK_SHR,          "shr"
DefData TK_SIZEOF,       "sizeof"
DefData TK_SIZE_T,       "size_t"
DefData TK_STEP,         "step"
DefData TK_STRICT,       "strict"
DefData TK_STRING,       "string"
DefData TK_STRUCT,       "struct"
DefData TK_SUPER,        "super"
DefData TK_SUPERSTRICT,  "superstrict"
DefData TK_THEN,         "then"
DefData TK_THROW,        "throw"
DefData TK_TO,           "to"
DefData TK_TRUE,         "true"
DefData TK_TRY,          "try"
DefData TK_TYPE,         "type"
DefData TK_UNIT,         "uint"
DefData TK_UNLONG,       "ulong"
DefData TK_UNTIL,        "until"
DefData TK_VAR,          "var"
DefData TK_VARPTR,       "varptr"
DefData TK_WEND,         "wend"
DefData TK_WHERE,        "where"
DefData TK_WHILE,        "while"

DefData 0,"#"

' Compound Symbols
#bmx_compound_symbols

DefData TK_CONTINUE,    "..",	"continued"
DefData TK_NOT_EQUAL,   "<>",	"inequal"	
DefData TK_LT_OR_EQUAL, "<=",	"lessequal"
DefData TK_GR_OR_EQUAL, ">=",	"greaterequal"
DefData TK_ASSIGN_PLUS, ":+",	"assignplus"
DefData TK_ASSIGN_MINUS,":-",	"assignminus"
DefData TK_ASSIGN_MUL,  ":*",	"assignmultiply"
DefData TK_ASSIGN_DIV,  ":/",	"assigndivide"
DefData TK_BITWISEAND,	":&",	"assignbitwiseand"
DefData TK_BITWISEOR,	":|",	"assignbitwiseor"
DefData TK_BITWISEXOR,	":~~",	"assignbitwisexor"

' Single Symbols
' A single symbol uses it's ASCII code unles overwritten here
#bmx_symbols

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
DefData TK_period,		"-",	"period"
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

DefData 0,"#","#"

'DefData "!","exclamation",		"~q","dquote",		"#","hash"
'DefData "$","dollar", 			"%","percent", 		"&","ampersand"
'DefData "'","apostrope", 		"(","lparen", 		")","rparen"
'DefData "*","asterisk", 		"+","plus", 		",","comma"
'DefData "-","hyphen", 			".","period", 		"/","solidus"
'DefData ":","colon", 			";","semicolon",	"<","lessthan"
'DefData "=","equals", 			">","greaterthan", 	"?","question"
'DefData "@","atsym", 			"[","lcrotchet", 	"\","backslash"
'DefData "]","rcrotchet", 		"^","circumflex", 	"_","underscore"
'DefData "`","backtick", 		"{","lbrace", 		"|","pipe"
'DefData "}","rbrace", 			"~~","tilde"
'DefData "#","#"
