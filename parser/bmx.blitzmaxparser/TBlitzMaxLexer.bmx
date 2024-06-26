
'	BlitzMax Lexer
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

'	CHANGE LOG
'	V1.0	07 AUG 21	Initial version
'	V1.1	16 AUG 21	Fixed issue that made all defined tokens TK_Identifiers!
'	V1.2	18 AUG 21	Added support for REM..(ENDREM|END REM)
'	V1.3	20 AUG 21	Fixed bug where remarks can contain "end rem"!

Const TK_EMPTY:Int = $FFFE		' Used to represent optional token matches

Type TBlitzMaxLexer Extends TLexer

	Method New( Text:String )
		Super.New( Text )
		'Print "Starting MAXLexer"

		' Define internal symbols
		'SYM_LINECOMMENT	= "'"
		'SYM_ALPHAEXTRA	= "_"	' Additional Characters allowed in ALPHA
		
		' Add tokens to definition
		RestoreData bmx_compound_symbols
		readCompoundSymbols()

		RestoreData bmx_reservedwords
		readTokens()

		RestoreData bmx_symbols
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

'	Method tokenise()
'DebugStop
'		Local token:TToken	' = nextToken()
'		'nextChar()			' Move to first character
'		previous = New TToken( TK_Invalid, "", 0,0, "" ) ' Beginning of file (Stops NUL)
'		Repeat
'			token = nextToken()
'If token ; Print token.reveal()
'DebugStop
'			If token ; tokens.addlast( token )
'			previous = token
'		Until token And token.id = TK_EOF
'		' Set the token cursor to the first element
'		'tokpos = tokens.firstLink()
'		cursor = 0
'	End Method
	
	' Language specific tokeniser
	Method GetNextToken:TToken()
		Local char:String = peekchar()
		Local line:Int = linenum
		Local pos:Int = linepos
		'
		Select True
		Case char = "~q"	' Quote indicates a string
			Return New TToken( TK_QString, ExtractString(), line, pos, "QSTRING" )
		Case char = "'"		' Line comment
			Return New TToken( TK_Comment, ExtractLineComment(), line, pos, "COMMENT" )
		Case Instr( SYM_NUMBER, char ) > 0	' Number
			Return New TToken( TK_Number, ExtractNumber(), line, pos, "NUMBER" )
		Case Instr( SYM_ALPHA+"_", char )>0       	' Alphanumeric Identifier
			Local Text:String = ExtractIdent( SYM_ALPHA+SYM_NUMBER+"_" )
			' Check if this is a named-token or just an alpha
			Local symbol:TSymbol = TSymbol( defined.valueforkey( Lower(Text) ) )
			If symbol
'If Lower(text) = "end" DebugStop
				If previous.id = TK_END
'DebugStop
					Select symbol.id
					Case TK_ENUM, TK_EXTERN, TK_FUNCTION, TK_IF, TK_INTERFACE, TK_METHOD, TK_REM, TK_SELECT, TK_STRUCT, TK_TRY, TK_TYPE, TK_WHILE
						Local sym:TSymbol = TSymbol( defined.valueforkey( "end"+Lower(Text) ) )
						previous.id = sym.id
						previous.class = sym.class
						previous.value :+ " "+Text
						Return Null					
					EndSelect
					
					' If we get here, then maybe it is just an "end" statement!
				End If
				
				' REM is a special case, multi-line statement
				If symbol.id = TK_REM ; Return New TToken( symbol.id, ExtractRemark(), line, pos, symbol.class )

				' Return the symbol
				Return New TToken( symbol.id, Text, line, pos, symbol.class )
			End If
			Return New TToken( TK_ALPHA, Text, line, pos, "ALPHA" )
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
	
		' Pops next character moving the cursor forward
    Method PopChar:String()
		If cursor>=source.length Return ""
        Local char:String = source[cursor..cursor+1]
		linepos :+ 1
		cursor :+ 1
		If char="~n"
			linenum :+ 1
			linepos = 1
		End If
        Return char
    End Method
	
	Method ExtractRemark:String()
        Local remark:String
'DebugStop
		Local match:TRegExMatch = findnext("(?im)^[ \t]*(ENDREM|END[ \t]*REM)(?![a-zA-Z0-9_])", True)
		If Not match Return ""
		' Have we found anything?
		'For Local i:Int = 0 Until match.SubCount()
		'	Print i + ": " + match.SubExp(i) + " at "+match.substart(i)+"-"+match.subend(i)
		'Next
		Local start:Int = match.substart(0)
		'Local finish:Int = match.subEnd(0)+1
		remark = Replace( getchunk( start ),"~r","")
		'Local ignore:String = getchunk( match.subEnd(1)+1 )		' Skip closing identifier	

'DebugLog( "/*"+remark+"*/" )
'DebugStop
		Return remark
	End Method
	
End Type

' Blitzmax Tables

#bmx_reservedwords
'		ID				 CLASS
'DefData TK_ALIAS,        "alias"		' ## WHAT IS THIS ##
DefData TK_AND,          "and"
DefData TK_ASC,          "asc"			' Should this be a function?
DefData TK_ASSERT,       "assert"
DefData TK_BYTE,         "byte"
DefData TK_CASE,         "case"
DefData TK_CATCH,        "catch"
DefData TK_CHR,          "chr"			' Should this be a function?
DefData TK_CONST,        "const"
DefData TK_CONTINUE,     "continue"
DefData TK_DEFDATA,      "defdata"
DefData TK_DEFAULT,      "default"		' Should we use ELSE instead of DEFAULT?
'DefData TK_DELETE,       "delete"		' It this actually used? Why is it a keyword?
DefData TK_DOUBLE,       "double"
DefData TK_EACHIN,       "eachin"		' Should this be a function?
DefData TK_ELSE,         "else"
DefData TK_ELSEIF,       "elseif"
DefData TK_END,          "end"
DefData TK_ENDENUM,      "endenum"
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
DefData TK_ENUM,         "enum"
DefData TK_EXIT,         "exit"
DefData TK_EXPORT,       "export"		' Must be a better was of doing this!
DefData TK_EXTENDS,      "extends"
DefData TK_EXTERN,       "extern"
DefData TK_FALSE,        "false"		' Should this be a constant?
DefData TK_FIELD,        "field"
DefData TK_FINAL,        "final"
DefData TK_FINALLY,      "finally"
DefData TK_FLOAT,        "float"
DefData TK_FOR,          "for"
DefData TK_FOREVER,      "forever"
DefData TK_FRAMEWORK,    "framework"	' Compiler directive
DefData TK_FUNCTION,     "function"
DefData TK_GLOBAL,       "global"
DefData TK_GOTO,         "goto"			' Should this be depreciated?
DefData TK_IF,           "if"
DefData TK_IMPLEMENTS,   "implements"
DefData TK_IMPORT,       "import"		' Compiler directive
DefData TK_INCBIN,       "incbin"
DefData TK_INCBINLEN,    "incbinlen"
DefData TK_INCBINPTR,    "incbinptr"
DefData TK_INCLUDE,      "include"		' Compiler directive
DefData TK_INT,          "int"
DefData TK_INTERFACE,    "interface"
DefData TK_LEN,          "len"			' Should this be a function?
DefData TK_LOCAL,        "local"
DefData TK_LONG,         "long"
DefData TK_METHOD,       "method"
DefData TK_MOD,          "mod"			' Should this be a function?
DefData TK_MODULE,       "module"		' Compiler directive
DefData TK_MODULEINFO,   "moduleinfo"	' Compiler directive
DefData TK_NEW,          "new"
DefData TK_NEXT,         "next"
DefData TK_NODEBUG,      "nodebug"		' Compiler directive
DefData TK_NOT,          "not"
DefData TK_NULL,         "null"
DefData TK_OBJECT,       "object"
DefData TK_OPERATOR,     "operator"
DefData TK_OR,           "or"
DefData TK_PI,           "pi"			' Should this be a constant!
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
DefData TK_SAR,          "sar"			' Should this be a function?
DefData TK_SELECT,       "select"
DefData TK_SELF,         "self"
DefData TK_SHL,          "shl"			' Should this be a function?
DefData TK_SHORT,        "short"
DefData TK_SHR,          "shr"			' Should this be a function?
DefData TK_SIZEOF,       "sizeof"
DefData TK_SIZE_T,       "size_t"
DefData TK_STEP,         "step"
DefData TK_STRICT,       "strict"
DefData TK_STRING,       "string"
DefData TK_STRUCT,       "struct"
DefData TK_SUPER,        "super"		' Compiler directive
DefData TK_SUPERSTRICT,  "superstrict"	' Compiler directive
DefData TK_THEN,         "then"
DefData TK_THROW,        "throw"
DefData TK_TO,           "to"
DefData TK_TRUE,         "true"			' Should this be a constant?
DefData TK_TRY,          "try"
DefData TK_TYPE,         "type"
DefData TK_UINT,         "uint"
DefData TK_ULONG,        "ulong"
DefData TK_UNTIL,        "until"
DefData TK_VAR,          "var"
DefData TK_VARPTR,       "varptr"
DefData TK_WEND,         "wend"
DefData TK_WHERE,        "where"
DefData TK_WHILE,        "while"

DefData 0,"#"

' Compound Symbols
#bmx_compound_symbols

'		ID				VALUE	CLASS
DefData TK_CONTINUE,    "..",	"continued"
DefData TK_NOT_EQUAL,   "<>",	"inequal"	
DefData TK_LT_OR_EQUAL, "<=",	"lessequal"
DefData TK_GT_OR_EQUAL, ">=",	"greaterequal"
DefData TK_ASSIGN_PLUS, ":+",	"assignplus"
DefData TK_ASSIGN_MINUS,":-",	"assignminus"
DefData TK_ASSIGN_MUL,  ":*",	"assignmultiply"
DefData TK_ASSIGN_DIV,  ":/",	"assigndivide"
DefData TK_BITWISEAND,	":&",	"assignbitwiseand"
DefData TK_BITWISEOR,	":|",	"assignbitwiseor"
DefData TK_BITWISEXOR,	":~~",	"assignbitwisexor"

DefData 0,"#","#"

' Single Symbols
' A single symbol uses it's ASCII code unles overwritten here
#bmx_symbols

'		ID				VALUE	CLASS
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

DefData 0,"#","#"
