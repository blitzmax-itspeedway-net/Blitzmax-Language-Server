SuperStrict
'	GENERAL PARSER

Framework brl.retro
'Import brl.collections
'Import brl.map
Import brl.reflection
'
Include "bin/loadfile().bmx"
Include "bin/TException.bmx"

'Include "../bin/json.bmx"

'	GENERIC LEXER AND PARSER
Include "bin/TToken.bmx"
Include "bin/TLexer.bmx"
Include "bin/TParser.bmx"

' 	ABNF GRAMMAR PARSER
Include "bin/TABNF.bmx"
Include "bin/TABNFLexer.bmx"
Include "bin/TABNFParser.bmx"

'	BLITZMAX PARSER
Include "bin/lexer-const-bmx.bmx"
Include "bin/TBlitzMaxLexer.bmx"
Include "bin/TBlitzMaxParser.bmx"

'	DELIVERABLES
Include "bin/AbstractSyntaxTree.bmx"
Include "bin/TSymbolTable.bmx"

'	TYPES AND FUNCTIONS

Type AST_BinaryOperator Extends TAbSynTree
	Field L:TAbSynTree	' Left 
	Field R:TAbSynTree	' Right
	
	Method New( L:TAbSynTree, token:TToken, R:TAbSynTree )
		Self.token = token
		Self.L = L
		Self.R = R
	End Method
	
End Type


Function Publish:Int( event:String, data:Object=Null, extra:Object=Null )
    Print "---> "+event
End Function



Type TLangServ Extends TVisitor

	Field parser:TParser
	Field tree:TAbSynTree
	
	Method New( parser:TParser )
		Self.parser = parser
	End Method
	
	Method run()
		' Perform the actual Parsing here
		parser.parse()
		tree = parser.ast
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
		
Function load_grammar:TABNF( filepath:String, verbose:Int = True )
	Try
		Local source:String, lexer:TLexer, parser:TParser
		Local bnf:TABNF
		Local start:Int, finish:Int
		
		'	First we Load And parse BlitzMax Grammar into abnf
		Print "STARTING BNF GRAMMAR PARSER:"
		source = loadFile( filepath )
		lexer  = New TABNFLexer( source )
		parser = New TABNFParser( lexer )	
		start  = MilliSecs()
		bnf    = TABNF( parser.parse() )	' Parse BNF to Grammar definition
		finish = MilliSecs()
		Print( "BNF LEXER+PARSE TIME: "+(finish-start)+"ms" )
		
		'	Save the Grammar Definition
		'abnf = parser.abnf
	'DebugStop
		If verbose
			Print "~nBNF TOKENS:"
			If parser.lexer
				Print parser.lexer.reveal()
			Else
				Print "NULL"
			End If
			Print "~nBNF STRUCTURE:"
			Print bnf.reveal()
		End If
		
		Return bnf

	Catch exception:TException
		Print "## Exception: "+exception.toString()+" ##"
	End Try		
End Function

Function test_file:Int( filepath:String, grammar:TABNF, state:Int, verbose:Int=False )
	Local source:String, lexer:TLexer, parser:TParser
	Local start:Int, finish:Int
	Local ast:TAbSynTree
	Local transpile:String = StripExt( filepath ) + ".transpile"

	Try		
		' 	Delete transpile file if it exists from previous run
		If FileType( transpile ) ; DeleteFile( transpile )
		
		'	Next we load and parse BlitzMax
		Print "STARTING BLITZMAX PARSER:"
		source = loadFile( filepath )
		'source = loadFile( "samples/1) Simple Blitzmax.bmx" )
		lexer  = New TBlitzMaxLexer( source )
	'DebugStop
		parser = New TBlitzMaxParser( lexer, grammar )		' NOTE LANGUAGE DEFINITION ARGUMENT HERE
		start  = MilliSecs()
	'DebugStop
		ast    = TAbSynTree( parser.parse() )
		finish = MilliSecs()
		Print( "BLITZMAX LEXER+PARSE TIME: "+(finish-start)+"ms" )

		If Not ast
			Print "Cannot transpile until syntax corrected"
			Return False
		End If

		' Pretty print the AST back into BlitzMax (.transpile file)
		Print "~nTRANSPILE AST TO BLITZMAX:"
			
		'Local transpiler:TBlitzMaxCompiler = New TBlitzMaxCompiler( tree )
		'Local blitzmax:String = transpiler.run()
		Print "~nTRANSPILER:"
		'Print blitzmax
		' Write transpiled code to file


		' Test language server AST parsing
		
		' ... be be continued...

	'	parser.testabnf( "program" )
		
		'parser.parse()
		'Print parser.reveal()
		'Local langserv:TLangServ = New TLangServ( parser )
		
		Return True
		
	Catch e:Object
		Local exception:TException = TException( e )
		Local runtime:TRuntimeException = TRuntimeException( e )
		Local text:String = String( e )
		Local typ:TTypeId = TTypeId.ForObject( e )
	'DebugStop
		If exception Print "## Exception: "+exception.toString()+" ##"
		If runtime Print "## Exception: "+runtime.toString()+" ##"
		If text Print "## Exception: '"+text+"' ##"
		Print "TYPE: "+typ.name
		Return False
	End Try

End Function

Function test_folder:Int( folder:String, grammar:TABNF, state:Int, verbose:Int=False )
	folder = StripSlash( folder )
	Local dir:String[] = LoadDir( folder )
	Print "~nTESTING FILES IN "+folder
	
	For Local filepath:String = EachIn dir
		If FileType(folder+"/"+filepath)=FILETYPE_FILE And ExtractExt(folder+"/"+filepath)="bmx"
			Print StripDir(filepath)+" - TESTING"
			If test_file( folder+"/"+filepath, grammar, state, verbose )
				Print StripDir(filepath)+" - SUCCESS"
			Else
				Print StripDir(filepath)+" - FAILURE"
			End If
		Else
			Print StripDir(filepath)+" - SKIPPED"
		End If
	Next
	
End Function

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

Local verbose:Int = True

'	LOAD BLITZMAX GRAMMER

Local grammar:TABNF = load_grammar( "samples/bmx-build.abnf", True )
Assert grammar, "Failed to load grammar definition"

' 	MAIN TESTING APPLICATION

test_file( "samples/positive/test.bmx", grammar, True, verbose )
'test_file( "samples/positive/hello world strict.bmx", grammar, True, verbose )
'test_file( "samples/positive/hello world.bmx", grammar, True, verbose )
'test_file( "samples/positive/function.bmx", grammar, True, verbose )
'test_folder( "samples/positive", grammar, True, verbose )
'test_folder( "samples/negative", grammar, False, verbose )

