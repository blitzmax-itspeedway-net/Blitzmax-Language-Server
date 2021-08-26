SuperStrict
'	GENERAL PARSER

Framework brl.retro
'Import brl.collections
'Import brl.map
Import brl.reflection
Import Text.RegEx

'Import bmx.lexer
Import bmx.parser

'
Include "bin/loadfile().bmx"
'Include "bin/TException.bmx"

'Include "../bin/json.bmx"

'	GENERIC LEXER AND PARSER
'Include "bin/TToken.bmx"
'Include "bin/TLexer.bmx"
'Include "bin/TParser.bmx"

'	BLITZMAX PARSER
Include "bin/lexer-const-bmx.bmx"
Include "bin/TBlitzMaxLexer.bmx"
Include "bin/TBlitzMaxParser.bmx"

'	DELIVERABLES
'Include "bin/AbstractSyntaxTree.bmx"
Include "bin/TBlitzMaxAST.bmx"
Include "bin/TSymbolTable.bmx"
Include "bin/TLanguageServerVisitor.bmx"

'	OUTPUT / TRANSPILE
Include "bin/TTranspiler.bmx"
Include "bin/TTranspileBlitzMax.bmx"
Include "bin/TTranspileCPP.bmx"
Include "bin/TTranspileJava.bmx"

'	TYPES AND FUNCTIONS

Function Publish:Int( event:String, data:Object=Null, extra:Object=Null )
    Print "---> "+event + "; "+String( data )
End Function

		
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
		ast    = parser.parse_ast()
		finish = MilliSecs()
		Print( "BLITZMAX LEXER+PARSE TIME: "+(finish-start)+"ms" )

		If Not ast
			Print "Cannot transpile until syntax corrected"
			Return False
		End If

		' SHOW AST STRICTURE
		Print "~nAST STRICTURE:"
		Print "------------------------------------------------------------"
		Print ast.reveal()
		Print "------------------------------------------------------------"


		' SHOW AST STRICTURE
		Print "~nLANGUAGE SERVER:"
		Print "------------------------------------------------------------"
		Local langserv:TLanguageServerVisitor = New TLanguageServerVisitor( ast )
		Print langserv.getOutline( StripDir(filepath) )
		Print "------------------------------------------------------------"

		' Pretty print the AST back into BlitzMax (.transpile file)
		Print "~nTRANSPILE AST TO BLITZMAX:"	

		Local blitzmax:TTranspileBlitzMax = New TTranspileBlitzMax( ast )
'DebugStop
		source = blitzmax.run()
		Print "------------------------------------------------------------"
		Print source
		Print "------------------------------------------------------------"

		' Pretty print the AST into C++
		Print "~nTRANSPILE AST TO C++:"
		
		Local cpp:TTranspileCPP = New TTranspileCPP( ast )
		source = cpp.run()
		Print "------------------------------------------------------------"
		Print source
		Print "------------------------------------------------------------"
		
		' Pretty print the AST into Java
		Print "~nTRANSPILE AST TO Java+:"
		
		Local java:TTranspileJava = New TTranspileJava( ast )
		source = java.run()
		Print "------------------------------------------------------------"
		Print source
		Print "------------------------------------------------------------"

		
		Return True
		
	Catch e:Object
		Local exception:TException = TException( e )
		Local blitzexception:TBlitzException = TBlitzException( e )
		Local runtime:TRuntimeException = TRuntimeException( e )
		Local text:String = String( e )
		Local typ:TTypeId = TTypeId.ForObject( e )
		If exception Print "## Exception: "+exception.toString()+" ##"
		If blitzexception Print "## BLITZ Exception: "+blitzexception.toString()+" ##"
		If runtime Print "## Exception: "+runtime.toString()+" ##"
		If text Print "## Exception: '"+text+"' ##"
		Print "TYPE: "+typ.name
DebugStop
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

