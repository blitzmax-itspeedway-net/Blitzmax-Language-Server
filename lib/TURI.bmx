
'	URI SUPPORT
'	(c) Copyright Si Dunford, October 2021, All Rights Reserved

' https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#uri

'TODO: add function "file:URI( path:string )" to deal with files that contain characters that are
' interpreted as regex (Like # for example)

' BASED ON:
'	https://github.com/microsoft/vscode-uri/blob/6fc6458aba65ea67458897d3331a37784c08e590/src/uri.ts#L589

Type TURI
	'	  foo://example.com:8042/over/there?name=ferret#nose
	'	  \_/   \______________/\_________/ \_________/ \__/
	'	   |           |            |            |        |
	'	scheme     authority       path        query   fragment
	'	   |   _____________________|__
	'	  / \ /                        \
	'	  urn:example:animal:ferret:nose
	
	'     file:///home/me/dev/xyz.bmx
	'     \_____/\__________________/
	'        |            |
	'     scheme         path
	
	'     D:\dev\xyz.bmx
	'     \____________/
	'            |
	'           path
	'     ** In this case, the scheme should be "file://"
	'
	
	Const REGEX:String = "^(([^:/?#]+?):)?(\/\/([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?"
	Field scheme:String, authority:String, path:String, query:String, fragment:String
	Field formatted:String	' cached
	
	' filesystem should be set to true when using local path-based filesystem 
	'	/home/me/dev/		<- Use TRUE here
	
	Method New( value:String, filesystem:Int = False )
	
	'Local this:TURI = Self

		If value.startswith("\") Or value.startswith("/") Or ..
			(Lower(value[..1])>="a" And Lower(value[..1])<="z" And value[1..3]=":\")
			scheme    = "file"
			authority = ""
			
			' Normalise slashes
			path = Replace( value, "\", "/" )

			' UNC paths
			If path[0..2]="//"
				Local idx:Int = Instr( path, "/", 2 )
				If idx = 0
					authority = path[2..]
					path = "/"
				Else
					authority = path[2..idx]
					path = path[idx..]
					If path="" ; path = "/"
				End If
			End If
			
			query     = ""
			fragment  = ""
		
		Else
	
			Local regex:TRegEx = TRegEx.Create( REGEX )
			Local match:TRegExMatch = regex.Find( value )
			If match 
				scheme    = match.SubExp(2)
				authority = match.SubExp(4)
				path      = match.SubExp(5)
				query     = match.SubExp(7)
				fragment  = match.SubExp(9)
			End If
			
			' Windows drive paths
			If authority.length=2 And (Lower(authority[..1])>="a" And Lower(authority[..1])<="z" And authority[1..2]=":")
				path = upper(authority) + path
				authority = ""
			End If
		End If
	End Method

	Method New( scheme:String, authority:String, path:String, query:String, fragment:String )
		Self.scheme    = scheme
		Self.authority = authority
		Self.path      = path
		Self.query     = query
		Self.fragment  = fragment
	End Method
	
	Method toString:String()
		If formatted ; Return formatted
		
		If scheme ; formatted :+ scheme + ":"
		If authority Or scheme = "file" ; formatted :+ "//"
		If authority
			Local index:Int = Instr( authority, "@" )
			If index>0
				Local user:String = authority[..index]
				authority = authority[(index+1)..]
				index = Instr( user, ":" )
				If index>0
					formatted :+ user
				Else
					formatted :+ user[..index] + ":" + user[index..]
				End If
				formatted :+ "@"
			End If
			authority = Lower( authority )
			index = Instr( authority, ":" )
			If index>0
				formatted :+ authority
			Else
				formatted :+ authority[..index] + authority[index..]
			End If
		End If
		If path  
			' Lower-Case windows drive letters in /C:/fff Or C:/fff
			If path.length >= 3 And path[0..1] = "/" And path[2..3] = ":"
				Local code:String = path[1..2]
				If code >= "A" And code <= "Z" ; path = "/"+Lower(code)+":"+path[3..]
			ElseIf path.length >= 2 And path[1..2] = ":"
				Local code:String = path[0..1]
				If code >= "A" And code <= "Z" ; path = Lower(code)+":"+path[2..]
			End If
			' Encode the rest of the path
			formatted :+ encoder(path, True)
		End If
		If query ; formatted :+ "?" + encoder(query, False)
		If fragment ; formatted :+ "#" + fragment
		Return formatted		
	End Method
	
	Method encoder:String( Text:String, allowslash:Int = False )
		Return Text
	End Method
	
	' Path contains a filename, we dont always want this...
	Method folder:String()
		Return ExtractDir( path )
	End Method

	' Retrieve only the filename from the path
	Method filename:String()
		Return StripDir( path )
	End Method	
	
	'Function file:TURI( path:String )
	'	Local authority:String = ""
		
	'	' Normalise slashes
	'	path = Replace( path, "\", "/" )

	'	' UNC paths
	'	If path[0..2]="//"
	'		Local idx:Int = Instr( path, "/", 2 )
	'		If idx = 0
	'			authority = path[2..]
	'			path = "/"
	'		Else
	'			authority = path[2..idx]
	'			path = path[idx..]
	'			If path="" ; path = "/"
	'		End If
	'	End If
'
	'	Return New TURI( "file", authority, path, "", "" )
	'End Function
	
End Type