SuperStrict

' This example has a number of validations
' * Calling functions and methods as statements
' * Referring to the global scope using "."
' * Missing semicolons between statements

Type TEST
    Method M() Print "M" End Method
End Type

Global X:TEST = New TEST

Func

Function Func()
    Local x:Int
    .X.M
End Function
