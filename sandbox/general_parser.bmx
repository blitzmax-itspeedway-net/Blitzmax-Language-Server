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

Type TGrammarNode
	Field alt:TGrammarNode
	Field suc:TGrammarNode
	Field terminal:Int
	Field sym:Int
End Type

Type AST
	Field name:String		' IMPORTANT - THIS IS USED TO CALL THE METHOD
	Field parent:AST		' Root node when NULL
	Field children:TList	' Leaf node when NULL
	Field token:TToken
	
	Method New( token:TToken )
		Self.token = token
	End Method
	
	Method addChild( child:TToken )
		If Not children children = New TList()
		children.addLast( child )
	End Method
	
End Type

Type AST_BinaryOperator Extends AST
	Field L:AST	' Left 
	Field R:AST	' Right
	
	Method New( L:AST, token:TToken, R:AST )
		Self.token = token
		Self.L = L
		Self.R = R
	End Method
	
End Type

' DUMMY LEXER

'Type TLexer
'
'	Field index:Int = -1
'	Field dummy:TToken[]
'
'	Method New( text:String )
'		'Self.source = text
'		dummy :+ [ New TToken( "number", "2" ) ]
'		dummy :+ [ New TToken( "symbol", "+" ) ]
'		dummy :+ [ New TToken( "symbol", "(" ) ]
'		dummy :+ [ New TToken( "number", "3" ) ]
'		dummy :+ [ New TToken( "symbol", "*" ) ]
'		dummy :+ [ New TToken( "number", "4" ) ]
'		dummy :+ [ New TToken( "symbol", ")" ) ]
'	End Method
'
'	Method getNext:TToken()
'		index :+ 1
'		Return dummy[index]
'	End Method
'	
'End Type



' A Visitor is a process that does something with the data
' A Compiler or Interpreter are the usual candidates, but
' you can use then to convert or process data in a natural way
' Here I am going to use them to build the Syntax and Definition trees
' but once built, you should be able to easily extend it to re-write "bcc"
' or generate Java, Javascript or even bytecode!

' The Visitor uses reflection to process the Abstract Syntax Tree
Type TVisitor

	Method visit( node:AST )
		DebugStop
		If Not node ThrowException( "Cannot visit null node" ) 
		'If node.name = "" invalid()	' Leave this to use "visit_" method
		
		' Use Reflection to call the visitor method (or an error)
		Local this:TTypeId = TTypeId.ForObject( Self )
		Local methd:TMethod = this.FindMethod( "visit_"+node.name )
		If Not methd exception( node )
		methd.invoke( this, [node] )
	End Method
	
	' This is called when node doesn't have a name...
	Method visit_( node:AST )
		ThrowException( "Node "+node.token.class+" has no name!" )
	End Method
	
	Method exception( node:AST )
		ThrowException( "Method visit_"+node.name+"() does not exist" )
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
	Local lexer:TLexer = New TBlitzMaxLexer( source )
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



