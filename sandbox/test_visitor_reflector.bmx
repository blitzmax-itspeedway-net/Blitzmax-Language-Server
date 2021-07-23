SuperStrict

'	TEST REFELECTION METHOD CALLING

Type TWelcome

	Method english( name:String )
		Print "Hello "+name
	End Method

	Method french( name:String )
		Print "Bonjour "+name
	End Method
	
	Method reflector( language:String, name:String )
		Local this:TTypeId = TTypeId.ForObject( Self )
		Local methd:TMethod = this.FindMethod( language )
		If methd
			methd.invoke( this, [name] )
		Else
			Print( "Sorry, I don't know "+language+"!" )
		End If
		
	End Method
End Type

Local welcome:TWelcome = New TWelcome

welcome.reflector( "english", "Scaremonger" )
welcome.reflector( "french", "Scaremonger" )
welcome.reflector( "german", "Scaremonger" )
