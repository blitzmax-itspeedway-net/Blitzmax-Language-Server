SuperStrict
Import Brl.Map
Import "test.base.bmx"
Import "sub/test.sub.bmx"

Type TTest Extends TTestBase
    Field funcHook:int(x:int)
    Field funcHookB()
    Field ..
    name ..
    :String        ..
    = "language"

    Field arr:Int[] = [1,2,3]


    Method Create:TTest(  a:int .. 'my comment
                        , b:int .. 'other comment
                        , c:int(d:int, e:int) .. 'third comment
                        , f:int(g:int, h:int(i:int, j:int)))
                        
        Local createLocalA:Int = 10
        Local createLocalB.. 'a string
              :String = "hello"

        Global createGlobalA:Int = 10
        Global createGlobalB.. 'a string
              :String = "hello"
    End Method
End type

