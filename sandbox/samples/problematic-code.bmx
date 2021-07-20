SuperStrict
Import Brl.Map
Import "test.base.bmx"
Import "sub/test.sub.bmx"

Type TTest Extends TTestBase
    Field funcHook:Int(x:Int)
    Field funcHookB()
    Field ..
    name ..
    :String        ..
    = "language"

    Field arr:Int[] = [1,2,3]


    Method Create:TTest(  a:Int .. 'my comment
                        , b:Int .. 'other comment
                        , c:Int(d:Int, e:Int) .. 'third comment
                        , f:Int(g:Int, h:Int(i:Int, j:Int)))
                        
        Local createLocalA:Int = 10
        Local createLocalB.. 'a string
              :String = "hello"

        Global createGlobalA:Int = 10
        Global createGlobalB.. 'a string
              :String = "hello"
    End Method
End Type

Local test:TTest = New TTest