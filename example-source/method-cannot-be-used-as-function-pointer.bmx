'This works on BlitzMaxNG 3.45, but fails on latest BlitzMaxNG
'(Also a problem with TField.typeid and potentially others).
'20 March 2023, SJD

'THIS IS THE CORRECT BEHAVIOUR - You must use count()

SuperStrict

Local list:TObjectList = New TObjectList
list.addlast( New TAlien )

Print "AMOUNT: " + list.count

Type TAlien
End Type
