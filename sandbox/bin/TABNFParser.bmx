
'	ABNF Parser
'	(c) Copyright Si Dunford, July 2021, All Rights Reserved

Include "TParser.bmx"

'	This parser generates an ABNF Rule Tree

Type TABNFParser Extends TParser

	Rem
	Method New( lexer:TLexer )
		Super.New(lexer)

		' DEFINE AB

		'	We need to follow a grammar rule so until we have a way to
		'	parse one from a file, we have to create it manually here

		'	RULE:
		'	program = Application / Module
		'	application = [Strictmode] [Framework] [*Import] [*Include] Block
		'	module = [Strictmode] ModuleDef [*Import] [*Include] Block
		'	strictmode = "strict" / "superstrict"
'DebugStop		
		'	Create "PROGRAM" rule
		Local _application:TGNode = New TGnode()
		Local _module:TGNode = New TGnode()
		
		' Application has no successor and "Module" as alternative
		_application.terminal = False
		_application.alt = _module
		_application.suc = Null
		_application.sym = New TSymbol( 0, "application", "" )
		
		' Module has no successor and no alternative
		_module.terminal = False
		_module.alt = Null
		_module.suc = Null
		_module.sym = New TSymbol( 0, "module", "" )
		
		' Create rule
		abnf.add( "program", _application )		
		
		'	Create "STRICTMODE" rule
		Local _strict:TGNode = New TGnode()
		Local _superstrict:TGNode = New TGnode()
		Local _strictnull:TGNode = New TGnode()

		' Strictmode can be either "strict" or "superstrict" or null
		_strict.terminal = True
		_strict.alt = _superstrict
		_strict.suc = Null
		_strict.sym = New TSymbol( 0, "strict", "" )
		
		_superstrict.terminal = True
		_superstrict.alt = _strictnull
		_superstrict.suc = Null
		_superstrict.sym = New TSymbol( 0, "superstrict", "" )	
			
		_strictnull.terminal = True
		_strictnull.alt = Null
		_strictnull.suc = Null
		_strictnull.sym = New TSymbol( 0, "", "" )		
		
		' Create rule
		abnf.add( "strictmode", _strict )
		
		'	Create "Application" rule
		Local _strictmode:TGNode = New TGnode()
		Local _framework:TGNode = New TGnode()

		_strictmode.terminal = False
		_strictmode.alt = Null
		_strictmode.suc = _framework
		_strictmode.sym = New TSymbol( 0, "strictmode", "" )

		_framework.terminal = False
		_framework.alt = Null
		_framework.suc = Null
		_framework.sym = New TSymbol( 0, "framework", "" )
		
		' Create rule
		abnf.add( "application", _strictmode )		
		
	End Method
	End Rem
	
	' The story starts, as they say, with a beginning...
	Method parse( rulename:String = "" )
'DebugStop
		' First order of the day is to run the lexer...
		Local start:Int, finish:Int
		start = MilliSecs()
'DebugStop
		lexer.run()
		finish = MilliSecs()
		Print( "LEXER.TIME: "+(finish-start)+"ms" )
'		Print( lexer.reveal() )

		' Define where we are going to put the results...
		abnf = New TABNF

		Repeat
			Local peek:TToken = lexer.peek()
			
			' Skip leading comments and end of line tokens
			If peek.in( [TK_Comment,TK_EOL] ) 
				lexer.getnext()
				Continue
			End If
DebugStop	
			' Parse the rule definition
			Try
				' First token will be rule name (ALPHA)
				If peek.id = TK_ALPHA
					Print "RULE: "+peek.value
					lexer.getnext()				' Consume rulename token
					lexer.expect( TK_equals )	' Next symbol MUST be a "="
					' Generate rule definition
					Local ruledef:TGrammarNode = parse_sequence( [TK_EOF,TK_EOL] )
					abnf.add( peek.value, ruledef )
				Else
					ThrowParseError( "Invalid symbol '"+peek.value+"'", peek.line, peek.pos )
				End If						
			Catch Exception:Object
'DebugStop
				Local e:TException = TParseError( Exception )
				If Not e ; e = TException( Exception )
				If e
					Print "EXCEPTION: "+e.toString()
				Else
					Print "EXCEPTION OCCURRED"
				End If
				' Recover from syntax error
				error_recovery()
			End Try

			If peek.is( TK_EOF ) Exit

		Forever
		'Until peek.is( TK_EOF )
		
'DebugStop

	End Method
	
	' Dump the AST
	Method reveal:String()
'		Print "TABNFParser.reveal() has not been implemented"
		
		Local printer:TABNFPrintVisitor = New TABNFPrintVisitor()
		printer.run()
	End Method

	Private

	' Recover from syntax errors
	' Called by parse method during try-catch for TParseError()
	Method error_recovery()
'DebugStop	
		' In ABNF, we can simply ignore everything up to the end of a line.
		' The next line should start a new rule
		'Local token:TToken = lexer.peek()
		Repeat
			lexer.getnext()
		Until lexer.peek().in( [TK_EOL,TK_EOF] )
		'lexer.getnext()		' Consume the next token
		'Wend
		'Local token:TToken = lexer.peek()
		lexer.getnext()
	End Method
	
	'	PARSE A SEQUENCE
	Method parse_sequence:TGrammarNode( exitcondition:Int[]=[] )

		' Create the ABNF linked list pointers
		Local root:TGrammarNode		' First in list
		Local head:TGrammarNode		' Last in list
		Local node:TGrammarNode		' Currrent node
		
		' Create linked list for this rule
		Local token:TToken
		Repeat
			token = lexer.getnext()
			node  = parse_successor( head, token )
			
			If Not root
				If Not node ; throwParseError( "Incomplete defintion", token.line, token.pos )
				root = node
				head = node
			Else
				head.suc = node
				head = node
			End If
			
		Until Not node Or lexer.peek().in( exitcondition )
		
		Return root
	End Method
	
	'	PARSE A SUCCESSOR
	Method parse_successor:TGrammarNode( prev:TGrammarNode, token:TToken )

		Select token.id
		Case TK_EOL, TK_EOF			'	End of line/file
			Return Null	
		Case TK_ALPHA		'	Non-Terminal
			Return New TGrammarNode( False, token )
		Case TK_QString		' 	Terminal
			Return New TGrammarNode( True, token )
		Case TK_asterisk	'	* = Repeat
			Local root:TGrammarNode = New TGrammarNode( False, New TToken( TK_Repeat, "*", token.line, token.pos, "*" ) )
			root.opt = parse_asterisk( root, lexer.getNext() )
			Return root
		Case TK_lparen		'	( = Group
			Local root:TGrammarNode = New TGrammarNode( False, New TToken( TK_Group, "()", token.line, token.pos, "()" ) )
			root.opt = parse_sequence( [TK_EOF,TK_EOL,TK_rparen] )
			Return root
		Case TK_lcrotchet	'	[ = Optional
			Local root:TGrammarNode = New TGrammarNode( False, New TToken( TK_Optional, "[]", token.line, token.pos, "[]" ) )
			root.opt = parse_sequence( [TK_EOF,TK_EOL,TK_rcrotchet] )
			Return root
		Case TK_solidus,TK_pipe		'	|/ = Alternative
			' not valid as first symbol
			If prev = Null ; ThrowParseError( "Unexpected symbol '"+token.value+"'", token.line, token.pos )
			' Parse Alternatives 
			Local root:TGrammarNode = prev
			parse_alternate( root, lexer.getNext() )
			Return parse_successor( prev, lexer.getnext() )
		Case TK_comment		'	Ignore comment
			Return parse_successor( prev, token )
		Case TK_EOL
			Return Null
		Default
			ThrowParseError( "Unexpected symbol '"+token.value+"'", token.line, token.pos )
		End Select		
	End Method

	'	PARSE AN ALTERNATE
	Method parse_alternate( prev:TGrammarNode, token:TToken )
		Local node:TGrammarNode
		
		Select token.id
		Case TK_EOL, TK_EOF			'	End of line/file
			Return	
		Case TK_ALPHA		'	Non-Terminal
			node = New TGrammarNode( False, token )
		Case TK_QString		' 	Terminal
			node = New TGrammarNode( True, token )
		Case TK_asterisk	'	* = Repeat
			node = New TGrammarNode( False, New TToken( TK_Repeat, "*", token.line, token.pos, "*" ) )
			node.opt = parse_asterisk( node, lexer.getNext() )
		Case TK_lparen		'	( = Group
			node = New TGrammarNode( False, New TToken( TK_Group, "()", token.line, token.pos, "()" ) )
			node.opt = parse_sequence( [TK_EOF,TK_EOL,TK_rparen] )
		Case TK_lcrotchet	'	[ = Optional
			node = New TGrammarNode( False, New TToken( TK_Optional, "[]", token.line, token.pos, "[]" ) )
			node.opt = parse_sequence( [TK_EOF,TK_EOL,TK_rcrotchet] )
		Default
			ThrowParseError( "Unexpected symbol '"+token.value+"'", token.line, token.pos )
		End Select

		' Tie node to parent
		prev.alt = node
		
		' Are there more?
		If lexer.peek().in( [TK_solidus,TK_pipe] )
			lexer.getNext()	' Drop solidus/pipe
			parse_alternate( node, lexer.getNext() )
		EndIf

DebugStop
	
	End Method
	
	'	REPEATING PATTERN
	Method parse_asterisk:TGrammarNode( root:TGrammarNode, token:TToken )
	
		Select token.id
		Case TK_EOL
			ThrowParseError( "Incomplete defintion", token.line, token.pos )
		Case TK_EOF			'	End of line/file
			ThrowParseError( "Unexpected end of file", token.line, token.pos )
		Case TK_ALPHA		'	Non-Terminal
			Return New TGrammarNode( False, token )
		Case TK_QString		' 	Terminal
			Return New TGrammarNode( True, token )
		Case TK_lparen		'	( = Group
			Local node:TGrammarNode = New TGrammarNode( False, New TToken( TK_Group, "()", token.line, token.pos, "()" ) )
			node.opt = parse_sequence( [TK_EOF,TK_EOL,TK_rparen] )
			Return node
		Case TK_lcrotchet	'	[ = Optional
			Local node:TGrammarNode = New TGrammarNode( False, New TToken( TK_Optional, "[]", token.line, token.pos, "[]" ) )
			node.opt = parse_sequence( [TK_EOF,TK_EOL,TK_rcrotchet] )
			Return node
		Default
			ThrowParseError( "Unexpected symbol '"+token.value+"'", token.line, token.pos )
		End Select		
	End Method

		
End Type

' This is a "Pretty Print" Visitor used to test the structure of an AST
' To use it, you muct have first declared visitor methods to return
' the appropriate content

Type TABNFPrintVisitor Extends TVisitor

	Field parser:TParser
	Field tree:AST
	Field start:String		' Starting point in ABNF notation
	
	Method New( parser:TParser, start:String="" )
		Self.parser = parser
		Self.start  = start
	End Method
	
	Method run()
		' Perform the actual Parsing here
		parser.parse( start )
		'tree = parser.abnf
		' Now call the visitor to process the tree
		'visit( tree )
	End Method
	
	' Not sure how to debug this yet...!
	' Maybe dump the syntax tree and definition table?
	Method reveal:String()
	End Method
	
	' ABSTRACT METHODS
Rem	
	Method visit_binaryoperator( node:AST_BinaryOperator )
		If Not node ThrowException( "Invalid node in binaryoperator" ) 
		Print "BINARY OPERATION"
	
		Select node.token.value
		Case "+"	; 'Local x:Int = visit( node.L ) + visit( node.R )
		Case "-"	
		Case "*"
		Case "/"
		End Select
		
	End Method
End Rem

End Type
