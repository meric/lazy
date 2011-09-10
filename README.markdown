#Lazy lua implemented in lua 5.2#

Requires lua 5.2 beta!

##Example Usage:##
    -- To run this example,
    -- cd lazy; lua lazy.lua
    
    function lazy.ladd(a, b)
      print("ladd", lazy.run(a), lazy.run(b))
      return a + b
    end
    
    -- non lazy (returns literal)
    local run = lazy.run -- force a lazy value
    -- lazy (returns lazy; needs to be run-ed to force value)
    local l = l -- converts a value to a lazy value. l(5) makes a lazy 5
    local ladd = lazy.ladd -- like add but prints when run
    local cond = lazy.cond -- a lazy if-elseif-else construct
    local cons = lazy.cons -- pair; used to make lists
    local ref = lazy.ref -- lazy reference a global
    local tail = lazy.tail -- tail of a lazy pair
    
    print("--cond--")     
    assert(run(cond(l(false), 
            ladd(l(1), l(2)),
           l(false),
            ladd(l(3), l(4)),
            ladd(l(5), l(6))))==11)
            
    assert(run(cond(l(false), 
            ladd(l(1), l(2)),
           l(true),
            ladd(l(3), l(4)),
            ladd(l(5), l(6))))==7)
            
    assert(run(cond(l(true), 
            ladd(l(1), l(2)),
           l(false),
            ladd(l(3), l(4)),
            ladd(l(5), l(6))))==3)
    
    print("--fibonacci 10--")     
    -- infinite sequence of fibonacci numbers
    fibs = cons(l(0), cons(l(1), lazy.zipWith(ladd,
                                              ref("fibs"), 
                                              tail(lazy.ref("fibs")))))
    print(run(lazy.nth(fibs, l(10))))


##Output:##
    --cond--
    ladd	5	6
    ladd	3	4
    ladd	1	2
    --fibonacci 10--
    ladd	0	1
    ladd	1	1
    ladd	1	2
    ladd	2	3
    ladd	3	5
    ladd	5	8
    ladd	8	13
    ladd	13	21
    34


