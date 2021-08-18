superstrict

type mytype1

    local x:int

    method get:string()
    end method

    method set:string()
    endmethod

    function xyz( a:int )
    endfunction

end type

function abc:int()

    function xyz( a:int )
    endfunction

end function

for local x:int = 1 to 10
    if x>2
        print "gtr"
    else
        print "lss"
    endif
next


