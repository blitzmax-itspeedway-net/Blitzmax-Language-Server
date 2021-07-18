
'   JSON PARSER
'   (c) Copyright Si Dunford, June 2021, All Right Reserved

'   JSON Specification:
'   https://www.json.org/json-en.html

'   Internally all JSON variables are stored as JSON
'   JSONs use the following types to store Blitzmax variables:
'
'   JSON    BLITZMAX
'   ----------------
'   array   JSON[]
'   number  String
'   object  TMap
'   string  String

Rem		CHANGELOG
		V0.0	Basic JSON Parser
		V0.1	Added Transpose into TypeStr using reflection
				Added find() and set()
		V0.2	Moved parser into JSON_Parser
				Merged JSON and JNode
				JNode is now depreciated, but not yet removed
		V0.3	Added error()
EndRem

' JSON Parser and Stringifier
Type JSON

    Public

	'V0.2 - Made these local
    ' Error Text, Line and Character
    Field errLine:Int = 0
    Field errPos:Int = 0
	Field errNum:Int = 0
    Field errText:String = ""

    ' Create JSON object from a string
    'Method New( text:String )
    '    root = parsetext( text )
    'End Method

    ' Create a JSON object from a Blitzmax Object (Reflection)
    'Method New( obj:Object )
		'root = reflect( obj )
    'End Method

	'V0.2 - Depreciated: Use JSON.isInvalid() instead
	' Confirm if there is an error condition
	'Method error:Int()
	'	Return ( errNum > 0 ) 
	'End Method
	
    ' Convert text into a JSON object
    Function Parse:JSON( text:String )
		Local parser:JSON_Parser = New JSON_Parser()
        'If Not JSON.instance JSON.instance = New JSON()
        Return parser.parse( text )
    End Function

	' V0.2 - Depreciated: Use "J.Stringify()" instead.
    ' Convert JSON into a string
    'Function Stringify:String( j:JNode )
	'	If j Return j.stringify()
	'	Return ""
    'End Function

	' V0.2 - Depreciated: Use "J.Transpose( typestr:string )" instead.
    ' Convert JSON to an Object
    'Function Transpose:Object( J:JNode, typestr:String )
    '    If J J.transpose( typestr )
    'End Function

	' V0.2 - Depreciated: Use "New JSON()"
    ' Helper Functions
    'Function Create:JNode()
    '    Return New JNode( "object", New TMap() )
    'End Function

'    Public 

    Field class:String

	' V2.0, replaces JSON.Create()
    Method New()
        'logfile.write "Creating new JNode '"+class+"'='"+string(value)
        Self.class = "object"
        Self.value = New TMap()
    End Method

    Method New( class:String, value:Object )
        'logfile.write "Creating new JNode '"+class+"'='"+string(value)
        Self.class = class
        Self.value = value
    End Method
	
	Method error:String()
		Return errtext+" ["+errnum+"] at "+errline+":"+errpos
	End Method
	
    Method toString:String()
		Return String(value)
	End Method

    Method toInt:Int()
		Return Int(String(value))
	End Method

    Method toArray:JSON[]()
		Local J:JSON[] = JSON[](value)
		If J Return J
		Return [New JSON( "invalid", "Node is not an array" )]
	End Method
	
    Method isValid:Int()
		Return ( class <> "invalid" )
	End Method

    Method isInvalid:Int()
		Return ( class = "invalid" )
	End Method

	' Get "string" value of a JNode object's child
	Method operator []:String( key:String )
        If class = "object"
			Local map:TMap = TMap( value )
			If map
				Local J:JSON = JSON( map.valueforkey(key) )
				If J Return String( J.value )
			End If
		End If
		Return ""
	End Method

	' Get "string" value of a JNode array
	Method operator []:JSON( key:Int )
		If class = "array"
			Local items:JSON[] = JSON[]( value )
			If items
				Local J:JSON = items[key]
				If J Return J
			End If
		End If
		Return Null
	End Method
	
    Method Stringify:String()
	
		'DebugStop
		
		Local text:String
		'If Not j Return "~q~q"
		Select class    ' JSON NODE TYPES
		Case "object"
			Local map:TMap = TMap( value )
			text :+ "{"
			If map
				For Local key:String = EachIn map.keys()
                    Local j:JSON = JSON( map[key] )
					text :+ "~q"+key+"~q:"+j.stringify()+","
				Next
				' Strip trailing comma
				If text.endswith(",") text = text[..(Len(text)-1)]
			End If
			text :+ "}"
        Case "array"
			text :+ "["
            For Local J:JSON = EachIn JSON[](value)
                text :+ J.stringify()+","
            Next
			' Strip trailing comma
			If text.endswith(",") text = text[..(Len(text)-1)]
			text :+ "]"
		Case "number"
			text :+ String(value)
		Case "string"
			text :+ "~q"+String(value)+"~q"
		Case "keyword"
			text :+ String(value)
		Case "invalid"
			text :+ "#ERR#"
		Default
			Publish( "log", "DEBG", "INVALID SYMBOL: '"+class+"', ''" )
		End Select
		Return text
	End Method

    ' Transpose a JSON object into a Blitzmax Object using Reflection 
    Method transpose:Object( typestr:String )
        Publish( "log", "DEBG", "Transpose('"+typestr+"')" )
        ' We can only transpose an object into a Type
        If class<>"object" Return Null
        Local typeid:TTypeId = TTypeId.ForName( typestr )
        If Not typeid
            Publish( "log", "DEBG", "- '"+typestr+"' is not a Blitzmax Type" )
            Return Null
        End If
        Local invoke:Object = typeid.newObject()
        If Not invoke Return Null
    
        ' Add Field names and types to map
        Local fields:TMap = New TMap()
        For Local fld:TField = EachIn typeid.EnumFields()
            fields.insert( fld.name(), fld.typeid.name() )
        Next
    
        ' Extract MAP (of JSONs) from value
        Local map:TMap = TMap( value )
        If Not map Return Null
        'logfile.write( "Map extracted from value successfully" )
        'for local key:string = eachin map.keys()
        '    logfile.write "  "+key+" = "+ JNode(map[key]).toString()
        'next

        ' Transpose fields into object
        For Local fldname:String = EachIn fields.keys()
            Local fldtype:String = String(fields[fldname]).tolower()
            'debuglog( "Field: "+fldname+":"+fldtype )
            'logfile.write "- Field: "+fldname+":"+fldtype
            Local fld:TField = typeid.findField( fldname )
            If fld
                'logfile.write "-- Is not null"
                Try
                    Select fldtype	' BLITZMAX TYPES
                    Case "string"
                        Local J:JSON = JSON(map[fldname])
                        If J fld.setString( invoke, J.tostring() )
                    Case "int"
                        Local J:JSON = JSON(map[fldname])
                        If J fld.setInt( invoke, J.toInt() )
                        'if J 
                        '    local fldvalue:int = J.toInt()
                        '    logfile.write fldname+":"+fldtype+"=="+fldvalue
                        '    fld.setInt( invoke, fldvalue )
                        '    logfile.write "INT FIELD SET"
                        'end if
                    Case "json"
                        ' This is a direct copy of JSON
                        Local J:JSON = JSON(map[fldname])
                        fld.set( invoke, J )
                    Default
                        Publish( "log", "ERRR", "Blitzmax type '"+fldtype+"' cannot be transposed()" )
                    End Select
                Catch Exception:String
                    Publish( "log", "CRIT", "Transpose exception" )
                    Publish( "log", "CRIT", Exception )
                End Try
            'else
                'logfile.write "-- Is null"
            End If
        Next
        Return invoke
    End Method


'		##### JSON HELPER

    ' Set the value of a JSON
    Method set( value:String )
		If value.startswith("~q") And value.endswith("~q")
			' STRING
			Self.class = "string"
			Self.value = dequote(value)
		Else
			If value = "true" Or value = "false" Or value = "null"
				' KEYWORD (true/false/null)
				Self.class = "keyword"
				Self.value = value
			Else
				' Treat it as a string
				Self.class = "string"
				Self.value = value
			End If
		End If
    End Method

    Method set( value:Int )
        ' If existing value is NOT a number, overwrite it
		Self.class="number"
		Self.value = String(value)
    End Method

    Method Set( route:String, value:String )
		'_set( route, value, "string" )
		Local J:JSON = find( route, True )	' Find route and create if missing
		J.set( value )
    End Method

    Method Set( route:String, value:Int )
		'_set( route, value, "number" )
		Local J:JSON = find( route, True )	' Find route and create if missing
		J.set( value )
    End Method

    Method Set( route:String, values:String[][] )
		Local J:JSON = find( route, True )	' Find route and create if missing
		For Local value:String[] = EachIn values
			'_set( route+"|"+value[0], value[1], "string" )
			If value.length=2
				Local node:JSON = J.find( value[0], True )
				node.set( value[1] )
			End If
		Next
    End Method

	' V0.2
	' Set a route to an existing JSON
    Method Set( route:String, node:JSON )
		Local J:JSON = find( route, True )	' Find route and create if missing
		J.class = node.class
		J.value = node.value
    End Method

	' V0.1
	Method find:JSON( route:String, createme:Int = False )
        ' Ignore empty route
        route = Trim(route)
        If route="" Return Null
		' Split up the path
        Return find( route.split("|"), createme )
	End Method
	
	Method find:JSON( path:String[], createme:Int = False )
	'DebugStop
		If path.length=0		' Found!
			Return Self
		Else
			' If child is specified then I MUST be an object right?
			Local child:JSON, map:TMap
			If class="object" ' Yay, I am an object.
				If value=Null
					value = New TMap()
				End If
				map = TMap( value )
			Else 
				If Not createme Return Null	' Not found
				' I must now evolve into an object, destroying my previous identity!
				map = New TMap()
				class = "object"
				value = map
			End If
			' Does child exist?
			child = JSON( map.valueforkey( path[0] ) )
			If Not child 
				If Not createme Return Null ' Not found
				' Add a new child
				child = New JSON( "string", "" )
				map.insert( path[0], child )
			End If
			Return child.find( path[1..], createme )
		End If
	End Method

    Private

    Field value:Object
	
End Type

'V0.2
Type JSON_Parser

    Private

    ' ##### PARSER

    Const SYM_WHITESPACE:String = " ~t~n~r"
	Const SYM_SPACE:String = " "
    Const SYM_NUMBER:String = "0123456789"
    Const SYM_LOWER:String = "abcdefghijklmnopqrstuvwxyz"
    Const SYM_UPPER:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    Const SYM_ALPHA:String = SYM_LOWER+SYM_UPPER
	Const SYM_7BIT:String = SYM_SPACE+"!#$%&'()*+,-./"+SYM_NUMBER+":;<=>?@"+SYM_UPPER+"[]^_`"+SYM_LOWER+"{|}"

    'Global instance:JSON
    Field tokens:TQueue<JToken> = New TQueue<JToken>
    Field unparsed:String
	
    Field linenum:Int = 1
    Field linepos:Int = 1

	Public 
	
    ' Parse string into a JSON object
    Method Parse:JSON( text:String )

        'Local node:TMap = New TMap()
        ' For convenience, and empty string is the same as {}
        If text.Trim()="" text = "{}"
        unparsed = text
    
        ' Tokenise the JSON string
        linenum = 1
        linepos = 1
		'Publish( "debug", "Tokenising..." )
        Tokenise()
		'Publish( "debug", "Tokenising finished" )

		' Dump the tokens, just for debugging purposes
		'For Local t:JToken = EachIn tokens
		'	Print( t.symbol + "  =  "+String(t.value) )
		'Next
		
        ' Parse out the parent object
        If PopToken().symbol <> "{" Return InvalidNode( "Expected '{'" )
        Local node:JSON = ReadObject()
		If node.isInvalid() Return node
        If PopToken().symbol <> "}" Return InvalidNode( "Expected '}'" )
        ' There should be no more characters after the closing braces
        'print tokens.size
        If tokens.isEmpty() Return node
        Return InvalidNode( "Unexpected characters past end" )
    End Method

	Private
	
    ' Reads an Object creating a TMAP
    Method ReadObject:JSON()
        Local node:TMap = New TMap()
        Local token:JToken

		'DebugStop
		
        If PeekToken().symbol = "}" Return New JSON( "object", node )
        Repeat
            ' Only valid option is a string (KEY)
            token = PopToken()
            If token.symbol <> "string" Return InvalidNode( "Expected quoted string" )

'Print String(token.line)[..5]+String(token.pos)[..5]+token.symbol
'If token.pos>240 DebugStop

			'DebugStop
			'WE ARE LOOKING HERE To CHECK THAT JSON IS DEQUOTED

            Local name:String = Dequote( token.value )
            'DebugLog( name )

            ' Only valid option is a colon
            If Not PopToken().symbol = ":" Return InvalidNode( "Expected ':'" )

            ' Get the value for this KEY
            token = PopToken()
            Select token.symbol	' TOKENS
            Case "{"    ' OBJECT
                'PopToken()  ' Throw away the "{"
                Local value:JSON = ReadObject()
				If value.isInvalid() Return value
                If PopToken().symbol <> "}" Return InvalidNode( "Expected '}'")
                node.insert( name, value )
				'node.insert( name, New JSON( "object", value ) )
            Case "["    ' ARRAY
                'PopToken()  ' Throw away the "{"
                Local value:JSON = ReadArray()
                If PopToken().symbol <> "]" Return InvalidNode( "Expected ']'" )
                node.insert( name, value ) 
                'node.insert( name, New JSON( "array", value ) )
            Case "string"
                'token = PopToken()
				node.insert( name, New JSON( "string", dequote(token.value) ) )
            Case "number"
                'token = PopToken()
                node.insert( name, New JSON( "number", token.value ) )
            Case "keyword"
                'token = PopToken()
                Local value:String = token.value
                If value="true" Or value="false" Or value="null"
                    node.insert( name, New JSON( "keyword", token.value ) )
                Else
                    Return InvalidNode( "Unknown identifier" )
                End If
            Default
                Return InvalidNode( "invalid symbol "+token.symbol+"/"+token.value)
            End Select

            ' Valid options now are "}" or ","
            token = PeekToken()
            If token.symbol = "}"
                Return New JSON( "object", node )
            ElseIf token.symbol = ","
                PopToken()  ' Remove "," from token list
            Else
                PopToken()  ' Remove Token
                Return InvalidNode( "Unexpected symbol '"+token.value+"'" )
            End If
        Forever
    End Method

    ' Reads an Array creating a TList
    Method ReadArray:JSON()
        Local node:JSON[]
        Local token:JToken

		'DebugStop
		
        If PeekToken().symbol = "]" Return New JSON( "array", node )
        Repeat
            ' Get the value for this array element
            token = PopToken()
            Select token.symbol
            Case "{"    ' OBJECT
                Local value:JSON = ReadObject()
				If value.isInvalid() Return value
                If PopToken().symbol <> "}" Return InvalidNode( "Expected '}'")
                node :+ [ value ]
            Case "["    ' ARRAY
                Local value:JSON = ReadArray()
                If PopToken().symbol <> "]" Return InvalidNode( "Expected ']'" )
                node :+ [ value ]	'New JSON( "array", value ) ]
            Case "string"
                'token = PopToken()
                node :+ [ New JSON( "string", Dequote(token.value) ) ]
            Case "number"
                'token = PopToken()
                node :+ [ New JSON( "number", token.value ) ]
            Case "keyword"
                'token = PopToken()
                Local value:String = token.value
                If value="true" Or value="false" Or value="null"
                    node :+ [ New JSON( value, value ) ]
                Else
                    Return InvalidNode( "Unknown identifier '"+token.value+"'" )
                End If
            Default
                Return InvalidNode( "Unknown identifier" )
            End Select

            ' Valid options now are "]" or ","
            token = PeekToken()
            If token.symbol = "]"
                Return New JSON( "array", node )
            ElseIf token.symbol = ","
                PopToken()  ' Remove "," from token list
            Else
                Return InvalidNode( "Unexpected symbol '"+token.symbol+"'" )
            End If
        Forever
    End Method

    ' Pops the first token from the stack
    Method PopToken:JToken()
        ' Whitespace is no longer tokenised
        'while not tokens.isempty() and PeekToken().in( SYM_WHITESPACE ) 
        '    PopToken()
        'wend
        If tokens.isempty() Return New JToken( "EOF","", linenum, linepos)
        Local token:JToken = tokens.dequeue()
        ' Reset the token position
        linenum = token.line
        linepos = token.pos
        Return token
    End Method

    ' Peeks the top of the Token Stack
    Method PeekToken:JToken()
        ' Whitespace is no longer tokenised
        'while not tokens.isempty() and PeekToken().in( SYM_WHITESPACE ) 
        '    PopToken()
        'wend
        If tokens.isempty() Return New JToken( "EOF","", linenum, linepos)
        Return tokens.peek()
    End Method

    ' Returns an invalid node object
    Method InvalidNode:JSON( message:String = "Invalid JSON" )
        'print( "Creating invalid node at "+linenum+","+linepos )
        'print( errtext )
		Local J:JSON = New JSON( "invalid", message )
        J.errNum  = 1
		J.errLine = linenum
        J.errPos  = linepos
        J.errText = message
        Return J
    End Method

    ' Returns an error condition
    'Method InvalidJSON:TMap( message:String = "Invalid JSON" )
    '    errNum  = 1
'	'	errLine = linenum
    '    errPos  = linepos
    '    errText = message
    '    Return Null
    'End Method

    '##### TOKENISER

    ' Tokenise an unparsed string
    Method Tokenise()
		'Publish( "debug", "Tokenise() - START" )
        tokens.clear()
        ' Toker the unparsed text
        Local token:JToken = ExtractToken()
		'Publish( "debug", "["+ token.line+","+token.pos+"] "+token.symbol )
        While token.symbol <> "EOF"
            tokens.enqueue( token )    ' ListAddLast()
            token = ExtractToken()
			'Publish( "debug", "["+ token.line+","+token.pos+"] "+token.symbol )
        Wend
		'Publish( "debug", "Tokenise() - END" )
    End Method

    ' Extract the next Token from the string
    Method ExtractToken:JToken()
    Local char:String = PeekChar()
    Local name:String
    Local token:JToken
    ' Save the Token position
    Local line:Int = linenum
    Local pos:Int = linepos
        ' Identify the symbol
        If char=""
            Return New JToken( "EOF", "", line, pos )
		ElseIf Instr( "{}[]:,", char, 1 )               ' Single character symbol
			PopChar()   ' Move to next character
            Return New JToken( char, char, line, pos )
        ElseIf char="~q"                            ' Quote indicates a string
            Return New JToken( "string", ExtractString(), line, pos )
        ElseIf Instr( SYM_NUMBER+"-", char )     	' Number
            Return New JToken( "number", ExtractNumber(), line, pos )
        ElseIf Instr( SYM_ALPHA, char )             ' Alphanumeric Identifier
            Return New JToken( "keyword", ExtractIdent(), line, pos )
        Else
            PopChar()   ' Throw it away!
            Return New JToken( "invalid", char, line, pos )
        End If
    End Method

    ' Skips leading whitespace and returns next character
    Method PeekChar:String()
        Local char:String
        Repeat
            If unparsed.length = 0 Return ""
            char = unparsed[..1]
            Select char
            Case "~r"   ' CR
                unparsed = unparsed[1..]
            Case "~n"   ' LF
                linenum :+1
                linepos = 1
                unparsed = unparsed[1..]
            Case " ","~t"
                linepos:+1
                unparsed = unparsed[1..]
			Case "\"	' ESCAPE CHARACTER
				char = unparsed[..2]
				If char="\u"	'HEX DIGIT
					char = unparsed[..6]					
					unparsed = unparsed[6..]
				Else
					unparsed = unparsed[2..]
				End If
            End Select
        Until Not Instr( SYM_WHITESPACE, char )
        Return char
    End Method

    ' Pops next character
    Method PopChar:String( ignoreWhitespace:Int = True )
        Local char:String
		Local IgnoredSymbols:String = ""
		'
		If ignoreWhitespace IgnoredSymbols = SYM_WHITESPACE
		
        Repeat
            If unparsed.length = 0 Return ""
            char = unparsed[..1]
            Select char
            Case "~r"   ' CR
                unparsed = unparsed[1..]
            Case "~n"   ' LF
                linenum :+ 1
                linepos = 1
                unparsed = unparsed[1..]
			Case "\"	' ESCAPE CHARACTER
				char = unparsed[..2]
				If char="\u"	'HEX DIGIT
					char = unparsed[..6]					
					unparsed = unparsed[6..]
				Else
					unparsed = unparsed[2..]
				End If
            Default
                linepos :+ 1
                unparsed = unparsed[1..]
            End Select
        Until Not Instr( IgnoredSymbols, char )
        Return char
    End Method

    Method ExtractIdent:String()
        Local text:String
        Local char:String = peekChar()
        While Instr( SYM_ALPHA, char ) And char<>""
            text :+ popChar()
            char = PeekChar()
        Wend
        Return text
    End Method

    Method ExtractNumber:String()
'DebugStop
        Local text:String
        Local char:String = peekChar()
		' Leading "-" (Negative number)
		If char="-"	
			text :+ popChar()
			char = peekChar()
		End If
		' Number
        While Instr( SYM_NUMBER, char ) And char<>""
            text :+ popChar()
            char = PeekChar()
        Wend
		' Decimal
		If char="."
			text :+ popChar()
            char = PeekChar()
			While Instr( SYM_NUMBER, char ) And char<>""
				text :+ popChar()
				char = PeekChar()
			Wend			
		End If
        Return text
    End Method

    Method ExtractString:String()
'DebugStop
        Local text:String = popChar()   ' This is the leading Quote
        Local char:String 
        Repeat
            char = PopChar( False )		' Pop char, but do not ignore whitespace
			Select char.length
			Case 1
				text :+ char
			Case 2	' ESCAPE CHARACTER?
				Select char
				Case "\~q","\\","\/"
					text :+ char[1..]
				Case "\n","\r","\t"
					text :+ "~~"+char[1..]
				Case "\b"
					text :+ Chr(08)
				Case "\f"
					text :+ Chr(12)
				End Select
			Case 6	' HEXCODE
				Local hexcode:String = "$"+char[2..]
				Print char + " == " + hexcode
				text :+ Chr( Int( hexcode ) )
			End Select
        Until char="~q" Or char=""
        Return text
    End Method

End Type

'V0.0
Type JToken
    Field symbol:String, value:String, line:Int, pos:Int

    Method New( symbol:String, value:String, line:Int, pos:Int )
        'print( "## "+symbol+", "+value+", "+line+", "+pos )
        Self.symbol = symbol
        Self.value = value
        Self.line = line
        Self.pos = pos 
    End Method
End Type

'V0.0
Function dequote:String( text:String )
	If text.startswith( "~q" ) text = text[1..]
	If text.endswith( "~q" ) text = text[..(Len(text)-1)]
	Return text
End Function

