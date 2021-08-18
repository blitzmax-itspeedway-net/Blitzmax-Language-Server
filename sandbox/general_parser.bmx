SuperStrict
'	GENERAL PARSER

Framework brl.retro
'Import brl.collections
'Import brl.map
Import brl.reflection
Import Text.RegEx

'
Include "bin/loadfile().bmx"
Include "bin/TException.bmx"

'Include "../bin/json.bmx"

'	GENERIC LEXER AND PARSER
Include "bin/TToken.bmx"
Include "bin/TLexer.bmx"
Include "bin/TParser.bmx"

'	BLITZMAX PARSER
Include "bin/lexer-const-bmx.bmx"
Include "bin/TBlitzMaxLexer.bmx"
Include "bin/TBlitzMaxParser.bmx"

'	DELIVERABLES
Include "bin/AbstractSyntaxTree.bmx"
Include "bin/TBlitzMaxAST.bmx"
Include "bin/TSymbolTable.bmx"

'	OUTPUT
Include "bin/TBlitzMaxPrettyPrint.bmx"

'	TYPES AND FUNCTIONS

Function Publish:Int( event:String, data:Object=Null, extra:Object=Null )
    Print "---> "+event
End Function

Type TLangServ Extends TVisitor

	Field parser:TParser
	Field tree:TASTNode
	
	Method New( parser:TParser )
		Self.parser = parser
	End Method
	
	Method run()
		' Perform the actual Parsing here
		parser.parse()
		tree = parser.ast
		' Now call the visitor to walk and process the tree
		visit( tree )
	End Method
	
	' Not sure how to debug this yet...!
	' Maybe dump the syntax tree and definition table?
	Method reveal:String()
	End Method
	
	' ABSTRACT METHODS
	' Not all of them are required by the Language server, but "bcc" will need them
	
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
		
Function test_file:Int( filepath:String, verbose:Int=False )
	Local source:String, lexer:TLexer, parser:TParser
	Local start:Int, finish:Int
	Local ast:TASTNode
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
		parser = New TBlitzMaxParser( lexer )
		start  = MilliSecs()
	'DebugStop
		ast    = parser.parse()
		finish = MilliSecs()
		Print( "BLITZMAX LEXER+PARSE TIME: "+(finish-start)+"ms" )

		If Not ast
			Print "Cannot transpile until syntax corrected"
			Return False
		End If

		' Pretty print the AST back into BlitzMax (.transpile file)
		Print "~nTRANSPILE AST TO BLITZMAX:"
		
		Local blitzmax:TBlitzMaxPrettyPrint = New TBlitzMaxPrettyPrint( ast )
		Local source:String = blitzmax.run()
		Print "------------------------------------------------------------"
		Print source
		Print "------------------------------------------------------------"
		
		'Local transpiler:TBlitzMaxCompiler = New TBlitzMaxCompiler( tree )
		'Local blitzmax:String = transpiler.run()
		'Print "~nTRANSPILER:"
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

Function test_folder:Int( folder:String, verbose:Int=False )
	folder = StripSlash( folder )
	Local dir:String[] = LoadDir( folder )
	Print "~nTESTING FILES IN "+folder
	
	For Local filepath:String = EachIn dir
		If FileType(folder+"/"+filepath)=FILETYPE_FILE And ExtractExt(folder+"/"+filepath)="bmx"
			Print StripDir(filepath)+" - TESTING"
			If test_file( folder+"/"+filepath, verbose )
				Print StripDir(filepath)+" - SUCCESS"
			Else
				Print StripDir(filepath)+" - FAILURE"
			End If
		Else
			Print StripDir(filepath)+" - SKIPPED"
		End If
	Next
	
End Function

Local verbose:Int = True

' 	MAIN TESTING APPLICATION

test_file( "samples/test.bmx", verbose )
'test_file( "samples/framework.bmx", verbose )
'test_file( "samples/hello world strict.bmx", verbose )
'test_file( "samples/hello world.bmx", verbose )
'test_file( "samples/function.bmx", verbose )
'test_file( "samples/capabilities.bmx", verbose )

'test_file( "samples/blocks.bmx", verbose )
'test_file( "samples/nested blocks.bmx", verbose )

'test_folder( "samples/", verbose )
'test_folder( "samples/", verbose )

