
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
'DebugStop	
			' Parse the rule definition
			Try
				' First token will be rule name (ALPHA)
				If peek.id = TK_ALPHA
					lexer.getnext()		' Consume rulename token
					parse_rule( peek.value )
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
			
		Until token.is( TK_EOF )
		
'DebugStop

	End Method
	
	' Dump the AST
	Method reveal:String()
		Print "TABNFParser.reveal() has not been implemented"
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
	
	' PARSE AN INDIVIDUAL RULE
	Method parse_rule( name:String )
		Print "RULE: "+name
'DebugStop		
'Print lexer.peek().reveal()
		lexer.expect( TK_equals )	' Next symbol MUST be a "="

		' Create the ABNF linked list pointers
		Local head:TGrammarNode = New TGrammarNode( False, Null )
		Local tail:TGrammarNode	= head	' Current node
		
		' Create linked list for this rule
		Repeat
			tail = parse_next( tail )
		Until tail.token.in( [TK_EOL,TK_EOF] )

	End Method

	' Parse next token / group / option / repeat
	Method parse_next:TGrammarNode( parent:TGrammarNode, alt:TGrammarNode=Null, suc:TGrammarNode=Null )
		Local token:TToken = lexer.getNext()		
		Select token.id
		Case TK_ALPHA		' 	Non-Terminal
			parent.suc = New TGrammarNode( False, token, alt, suc )
			Return parent.suc
		Case TK_QString		' 	Terminal
			parent.suc = New TGrammarNode( True, token, alt, suc )
			Return parent.suc
		Case TK_asterisk	'	* = Repeat
			Return parse_repeat( parent, alt, suc )
		Case TK_lparen		'	( = Group
			Return parse_group( parent, alt, suc )
		Case TK_lcrotchet	'	[ = Optional
			Return parse_options( parent, alt, suc )
		Case TK_comment		'	Ignore comment
			Return parent
		Case TK_EOL
			Return New TGrammarNode( False, token, alt, suc )
		Default
			ThrowParseError( "Unexpected symbol '"+token.value+"'", token.line, token.pos )
		End Select		
	End Method

	' PARSE REPETITIVE
	Method parse_repeat:TGrammarNode( tail:TGrammarNode, alt:TGrammarNode, suc:TGrammarNode )
		' Create empty nodes for start and result
		Local start:TGrammarNode = New TGrammarNode( False, Null )
		Local result:TGrammarNode = New TGrammarNode( False, Null, alt, suc )
		' Connect start to the tail
		tail.suc = start
		' Get the next node
		Local node:TGrammarNode = parse_next( start, start, result )
		Return node		
	End Method
	
	' PARSE GROUP
	' This is just a sequence.
	Method parse_group:TGrammarNode( tail:TGrammarNode, alt:TGrammarNode, suc:TGrammarNode )
		Local token:TToken = lexer.getNext()			
		Repeat
			tail = parse_next( tail, alt:TGrammarNode, suc:TGrammarNode )
		Until tail.token.in( [TK_rparen,TK_EOF] )
		Return tail	
	End Method

	' PARSE OPTIONAL
	' alt points to alternatives
	' suc points to "success" node
	Method parse_options:TGrammarNode( parent:TGrammarNode, alt:TGrammarNode, suc:TGrammarNode  )
		' Create empty nodes for start and result
		Local start:TGrammarNode = New TGrammarNode( False, Null )
		Local result:TGrammarNode = New TGrammarNode( False, Null, alt, suc )
		Local tail:TGrammarNode = start
		parent.suc = start
		Repeat
			Local node:TGrammarNode = parse_next( tail, Null, result )
			tail.alt = node
		Until token.in( [TK_rcrotchet,TK_EOF] )
		Return tail
	End Method
		
End Type

' This is a "Pretty Print" Visitor used to test the structure of an AST
' To use it, you muct have first declared visitor methods in your parser to return
' the appropriate content

Type TPrettyPrintVisitor Extends TVisitor

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
		tree = parser.AST
		' Now call the visitor to process the tree
		visit( tree )
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
