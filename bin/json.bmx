
'   JSON PARSER
'   (c) Copyright Si Dunford, Jule 2021, All Right Reserved

'   JSON Specification:
'   https://www.json.org/json-en.html

' THis is the JSON Parse
Type JSON

    Public

    ' Error Text, Line and Character
    Global errLine:Int = 0
    Global errPos:Int = 0
	Global errNum:Int = 0
    Global errText:String = ""

    ' Create JSON object from a string
    'Method New( text:String )
    '    root = parsetext( text )
    'End Method

    ' Create a JSON object from a Blitzmax Object (Reflection)
    'Method New( obj:Object )
		'root = reflect( obj )
    'End Method

	' Confirm if there is an error condition
	Method error:Int()
		Return ( errNum > 0 ) 
	End Method
	
    ' Convert text into a JSON object
    Function Parse:JNode( text:String )
        if not JSON.instance JSON.instance = new JSON()
        Return JSON.instance.parseText( text )
    End Function

    ' Convert JSON into a string
    Function Stringify:String( j:JNode )
		If j Return j.stringify()
		Return ""
    End Function

    ' Convert an Object into a string
    'Function Stringify:String( o:Object )
    'End Function

    ' Convert JSON to an Object
    Function Transpose:Object( J:JNode, typestr:string )
        if J J.transpose( typestr )
    End Function
    
    Private

    ' ##### PARSER

    Const SYM_WHITESPACE:String = " ~t~n~r"
    Const SYM_ALPHA:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghjklmnopqrstuvwxyz"
    Const SYM_NUMBER:String = "0123456789"

    global instance:JSON
    Field tokens:TQueue<JToken> = New TQueue<JToken>
    Field unparsed:String
	'Field root:JNode		' The parsed content of this JSON
	
    Field linenum:Int = 1
    Field linepos:Int = 1

    ' Parse string into a JSON object
    Method parsetext:JNode( text:String )

DebugStop

        'Local node:TMap = New TMap()
        ' For convenience, and empty string is the same as {}
        If text.Trim()="" text = "{}"
        unparsed = text
    
        ' Tokenise the JSON string
        linenum = 1
        linepos = 1
        Tokenise()

		' Dump the tokens, just for debugging purposes
		'For Local t:JToken = EachIn tokens
		'	Print( t.symbol + "  =  "+String(t.value) )
		'Next
		
        ' Parse out the parent object
        If PopToken().symbol <> "{" Return InvalidNode( "Expected '{'" )
        Local node:JNode = ReadObject()
		If node.isInvalid() Return node
        If PopToken().symbol <> "}" Return InvalidNode( "Expected '}'" )
        ' There should be no more characters after the closing braces
        'print tokens.size
        If tokens.isEmpty() Return node
        Return InvalidNode( "Unexpected characters past end" )
    End Method

    ' Reads an Object creating a TMAP
    Method ReadObject:JNode()
        Local node:TMap = New TMap()
        Local token:JToken

		'DebugStop
		
        If PeekToken().symbol = "}" Return New JNode( "object", node )
        Repeat
            ' Only valid option is a string (KEY)
            token = PopToken()
            If token.symbol <> "string" Return InvalidNode( "Expected quoted string" )

			'DebugStop
			'WE ARE LOOKING HERE To CHECK THAT JSON IS DEQUOTED

            Local name:String = Dequote( token.value )
            'DebugLog( name )

            ' Only valid option is a colon
            If Not PopToken().symbol = ":" Return InvalidNode( "Expected ':'" )

            ' Get the value for this KEY
            token = PopToken()
            Select token.symbol
            Case "{"    ' OBJECT
                'PopToken()  ' Throw away the "{"
                Local value:JNode = ReadObject()
                If PopToken().symbol <> "}" Return InvalidNode( "Expected '}'")
                node.insert( name, New JNode( "object", value ) )
            Case "["    ' ARRAY
                'PopToken()  ' Throw away the "{"
                Local value:JNode = ReadArray()
                If PopToken().symbol <> "]" Return InvalidNode( "Expected ']'" )
                node.insert( name, New JNode( "array", value ) )
            Case "string"
                'token = PopToken()
                node.insert( name, New JNode( "string", Dequote(token.value) ) )
            Case "number"
                'token = PopToken()
                node.insert( name, New JNode( "number", token.value ) )
            Case "alpha"
                'token = PopToken()
                Local value:String = token.value
                If value="true" Or value="false" Or value="null"
                    node.insert( name, value )
                Else
                    Return InvalidNode( "Unknown identifier" )
                End If
            Default
                Return InvalidNode()
            End Select

            ' Valid options now are "}" or ","
            token = PeekToken()
            If token.symbol = "}"
                Return New JNode( "object", node )
            ElseIf token.symbol = ","
                PopToken()  ' Remove "," from token list
            Else
                PopToken()  ' Remove Token
                Return InvalidNode( "Unexpected symbol '"+token.value+"'" )
            End If
        Forever
    End Method

	Method dequote:String( text:String )
		If text.startswith( "~q" ) text = text[1..]
		If text.endswith( "~q" ) text = text[..(Len(text)-1)]
		Return text
	End Method

    ' Reads an Array creating a TList
    Method ReadArray:JNode()
        Local node:JNode[]
        Local token:JToken

		'DebugStop
		
        If PeekToken().symbol = "]" Return New JNode( "array", node )
        Repeat
            ' Get the value for this array element
            token = PopToken()
            Select token.symbol
            Case "{"    ' OBJECT
                Local value:JNode = ReadObject()
                If PopToken().symbol <> "}" Return InvalidNode( "Expected '}'" )
                node :+ [ New JNode( "object", value ) ]
            Case "["    ' ARRAY
                Local value:JNode = ReadArray()
                If PopToken().symbol <> "]" Return InvalidNode( "Expected ']'" )
                node :+ [ New JNode( "array", value ) ]
            Case "string"
                'token = PopToken()
                node :+ [ New JNode( "string", Dequote(token.value) ) ]
            Case "number"
                'token = PopToken()
                node :+ [ New JNode( "number", token.value ) ]
            Case "alpha"
                'token = PopToken()
                Local value:String = token.value
                If value="true" Or value="false" Or value="null"
                    node :+ [ New JNode( value, value ) ]
                Else
                    Return InvalidNode( "Unknown identifier '"+token.value+"'" )
                End If
            Default
                Return InvalidNode( "Unknown identifier" )
            End Select

            ' Valid options now are "]" or ","
            token = PeekToken()
            If token.symbol = "]"
                Return New JNode( "array", node )
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
        local token:JToken = tokens.dequeue()
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
    Method InvalidNode:JNode( message:String = "Invalid JSON" )
        'print( "Creating invalid node at "+linenum+","+linepos )
        'print( errtext )
        errNum  = 1
		errLine = linenum
        errPos  = linepos
        errText = message
        Return New JNode( "invalid", message )
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
        tokens.clear()
        ' Toker the unparsed text
        Local token:JToken = ExtractToken()
		'Print( token.symbol )
        While token.symbol <> "EOF"
            tokens.enqueue( token )    ' ListAddLast()
            token = ExtractToken()
			'Print( token.symbol )
        Wend
    End Method

    ' Extract the next Token from the string
    Method ExtractToken:JToken()
    Local char:String = PeekChar()
    Local name:String
    Local token:JToken
    ' Save the Token position
    local line:int = linenum
    local pos:int = linepos
        ' Identity the symbol
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
            Return New JToken( "alpha", ExtractIdent(), line, pos )
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
            End Select
        Until Not Instr( SYM_WHITESPACE, char )
        Return char
    End Method

    ' Skips leading whitespace and Pops next character
    Method PopChar:String()
        Local char:String
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
            Default
                linepos :+ 1
                unparsed = unparsed[1..]
            End Select
        Until Not Instr( SYM_WHITESPACE, char )
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
        Local text:String
        Local char:String = peekChar()
        While Instr( SYM_NUMBER+".", char ) And char<>""
            text :+ popChar()
            char = PeekChar()
        Wend
        Return text
    End Method

    Method ExtractString:String()
'DebugStop
        Local text:String = popChar()   ' This is the leading Quote
        Local char:String 
        Repeat
            char = PopChar()
            text :+ char
        Until char="~q" Or char=""
        Return text
    End Method


End Type

' Individual data elemement in a JSON tree
Type JNode

    Public 

    Field class:String

    Method New( class:String, value:Object )
        Self.class=class
        Self.value=value
    End Method
	
    Method toString:String()
		Return String(value)
	End Method

    Method isValid:Int()
		Return ( class <> "invalid" )
	End Method

    Method isInvalid:Int()
		Return ( class = "invalid" )
	End Method

	' Extract a JNode by key (Only works on objects)!
	Method operator []:JNode( key:String )
		If class="object" 
			Local map:TMap = TMap( value )
			If map Return JNode( map[key] )
		End If
		Return New JNode( "invalid", "" )
	End Method

    Method Stringify:String()
	
		'DebugStop
		
		Local text:String
		'If Not j Return "~q~q"
		Select class
		Case "object"
			Local map:TMap = TMap( value )
			text :+ "{"
			If map
			 
				For Local key:String = EachIn map.keys()
                    Local j:JNode = JNode( map[key] )
					text :+ "~q"+key+"~q:"+j.stringify()+","
				Next
				' Strip trailing comma
				If text.endswith(",") text = text[..(Len(text)-1)]
			End If
			text :+ "}"
		Case "number"
			text :+ String(value)
		Case "string"
			text :+ "~q"+String(value)+"~q"
		Default
			Print "INVALID SYMBOL: '"+class+"'"
		End Select
		Return text
	End Method

   ' Transpose a JNode object into a Blitzmax Object using Reflection 
   Method transpose:object( typestr:string )
    'DebugStop
        debuglog( "Transpose() start")
        print "JNode.Transpose()"
        ' Identify the Type that we are going to create
'        Local methd:String = root["method"].tostring()
'        If methd="" Return Null
'        Local typestr:String = "REQ_"+methd
        'logfile.write( "- Creating "+typestr )
        ' Create an object of type "typestr"
        debuglog "Creating type "+typestr
        print "- Creating type "+typestr
        Local typeid:TTypeId = TTypeId.ForName( typestr )
        If Not typeid
            debuglog( "- Not a valid type" )
            print "- Not a valid type" 
            Return Null
        End If
        Local invoke:Object = typeid.newObject()
        If Not invoke 
            debuglog( "- Failed to create object" )
            print "- Failed to create object"
            Return Null
        End If
    
        ' Enumerate object fields
        Local fields:TMap = New TMap()
        debuglog( "Object fields:" )
        print "- Enumerating objects"

        ' Add Field names and types to map
        For Local fld:TField = EachIn typeid.EnumFields()
            debuglog( "  "+fld.name() + ":" + fld.typeid.name() )
            print( "  "+fld.name() + ":" + fld.typeid.name() )
            fields.insert( fld.name(), fld.typeid.name() )
        Next
    
        ' Copy JSON fields into object
        For Local fldname:String = EachIn fields.keys()
            Local fldtype:String = String(fields[fldname]).tolower()
            debuglog( "Field: "+fldname+":"+fldtype )
            print "- Field: "+fldname+":"+fldtype
            Local fld:TField = typeid.findField( fldname )
            If fld
                print "-- Is not null"
                Select fldtype
                Case "string"
                    fld.setString( invoke, string(fields[fldname]) )
                Case "int"
                    fld.setInt( invoke, int(string(fields[fldname] )))
                Default
                    DebugLog( fldtype + " not currently supported by transform" )
                    print "-- "+fldtype+" not currently supported by transform()"
                End Select
            else
                print "-- Is null"
            End If
        Next		
        Return invoke
    End Method

    Private

    Field value:Object

End Type

Type JToken
    Field symbol:String, value:String, line:Int, pos:int

    Method New( symbol:String, value:String, line:int, pos:int )
        'print( "## "+symbol+", "+value+", "+line+", "+pos )
        Self.symbol = symbol
        Self.value = value
        Self.line = line
        Self.pos = pos 
    End Method
End Type