SuperStrict
'	GENERAL PARSER

Framework brl.retro
'Import brl.collections
'Import brl.map
Import brl.reflection
'
Include "bin/loadfile().bmx"
Include "bin/TException.bmx"
'
Include "bin/TToken.bmx"
Include "bin/TABNF.bmx"

Include "bin/TSymbolTable.bmx"
Include "bin/TBlitzMaxLexer.bmx"
Include "bin/TBlitzMaxParser.bmx"

Type AST_BinaryOperator Extends AST
	Field L:AST	' Left 
	Field R:AST	' Right
	
	Method New( L:AST, token:TToken, R:AST )
		Self.token = token
		Self.L = L
		Self.R = R
	End Method
	
End Type



Type TLangServ Extends TVisitor

	Field parser:TParser
	Field tree:AST
	
	Method New( parser:TParser )
		Self.parser = parser
	End Method
	
	Method run()
		' Perform the actual Parsing here
		tree = parser.parse()
		' Now call the visitor to process the tree
		visit( tree )
	End Method
	
	' Not sure how to debug this yet...!
	' Maybe dump the syntax tree and definition table?
	Method reveal:String()
	End Method
	
	' ABSTRACT METHODS
	' Not all of them are required by the Language server, but "bcc" will need them
	
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
	
End Type
		
'Local token:TToken = goal.entry

Rem
Now we need To read the node tree, obtain symbols from lexer compar To make sure syntax is correct
Create the AST, Syntz table (For document) And defnintion tree..

Phew!
End Rem

'	CREATE TEST NODE TREE
'	(As we have no BlitzMax BNF Defintion to read from we will do all this manually)

'function name ":" 


' DEMO CODE ONLY

' Lets manually build a tree with the expression 2+(3*4)

' Create a node for the number tokens (Which would come from the lexer)
'Local Number2:AST = New AST( New TToken( "number", "2",0,0 ) )
'Local Number3:AST = New AST( New TToken( "number", "3",0,0 ) )
'Local Number4:AST = New AST( New TToken( "number", "4",0,0 ) )

' Built the Abstract Syntax Tree
'Local addnode:AST_BinaryOperator = New AST_BinaryOperator( ..
'	Number2, ..
'	New TToken( "symbol","+",0,0 ), ..
'	New AST_BinaryOperator( ..
'		Number3, ..
'		New TToken( "symbol", "*",0,0 ), ..
'		Number4 ))

' Now lets test parsing 

Try
	'DebugStop
	Local source:String = loadFile( "samples/1) Simple Blitzmax.bmx" )
	'Local source:String = loadFile( "samples/1) Simple Blitzmax.bmx" )
	Local lexer:TLexer = New TBlitzMaxLexer( source )
DebugStop
	Local parser:TParser = New TBlitzMaxParser( lexer )
	
	lexer.run()
	Print( lexer.reveal() )
	
	parser.testabnf( "program" )
	
	parser.parse()
	Print parser.reveal()
	'Local langserv:TLangServ = New TLangServ( parser )

	'langserv.run()
	'Print langserv.reveal()

Catch exception:TException
	Print "## Exception: "+exception.toString()+" ##"
End Try



