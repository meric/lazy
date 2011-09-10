local class = require "class"
local lazy_mt = {}
local lazy = setmetatable({}, lazy_mt)

thunk = class() 
-- http://en.wikipedia.org/wiki/Thunk_(functional_programming)

function thunk:init(fn, args)
  self.fn, self.args, self.eval, self.value = fn, args, false, nil
end

function thunk:__call()
  if not self.eval then
    self.value, self.eval = self.fn(unpack(self.args)), true
  end
  return self.value
end

function thunk:__eq(other) return lazy.run(self) == lazy.run(other) end
function thunk:__add(other) return lazy.run(self) + lazy.run(other) end
function thunk:__sub(other) return lazy.run(self) - lazy.run(other) end
function thunk:__mul(other) return lazy.run(self) * lazy.run(other) end
function thunk:__div(other) return lazy.run(self) / lazy.run(other) end
function thunk:__mod(other) return lazy.run(self) % lazy.run(other) end
function thunk:__pow(other) return lazy.run(self) ^ lazy.run(other) end
function thunk:__len() return #lazy.run(self) end

-- force a value; Can only force lazy values
function lazy.run(t)
  assert(type(t)=="table" and t.__class == thunk)
  while type(t)=="table" and t.__class == thunk do
    t=t()
  end
  return t
end

-- All functions in lazy table are now lazy functions
function lazy_mt:__newindex(name, fn)
  if type(fn) == "function" then
    local function lazyfn(...) return thunk(fn, {...}) end
    rawset(self, name, lazyfn)
  end
end

function lazy.lazy(v) return v end -- create lazy value
local l = lazy.lazy -- e.g. l(5) to use 5 in a lazy fn argument

assert(lazy.lazy(5) == lazy.lazy(5) == true)

-- lazy if-then-elseif-else
function lazy.cond(cond, a, ...)
  if not a then return cond end
  if lazy.run(cond) then return a end
  return lazy.cond(...)
end

function lazy.add(a, b) return a + b end -- lazy add two numbers

-- "and"; capitalized because and is a keyword
function lazy.AND(a, ...)
  a = lazy.run(a)
  return a and (... and lazy.AND(...)) or a
end

assert(lazy.run(lazy.AND(l(false), l(true))) == false)
assert(lazy.run(lazy.AND(l(true), l(true))) == true)
assert(lazy.run(lazy.AND(l(true), l(true), l(false))) == false)

function lazy.eq(a, b) return a == b end -- lazy equal

assert(lazy.run(lazy.cond(lazy.lazy(false), 
                lazy.add(lazy.lazy(1), lazy.lazy(2)),
                lazy.lazy(false),
                lazy.add(lazy.lazy(3), lazy.lazy(4)),
                lazy.add(lazy.lazy(5), lazy.lazy(6))))==11)

function lazy.cons(a, b) return {a, b} end -- pair; used to make lists
function lazy.tail(l) return lazy.run(l)[2] end -- tail of cons
function lazy.head(l) return lazy.run(l)[1] end -- head of cons
function lazy.ref(name) return _ENV[name] end -- lazy reference a global

-- get nth value of a list
function lazy.nth(list1, n)
  return lazy.cond(lazy.eq(n, lazy.lazy(1)), 
                   lazy.head(list1), 
                   lazy.nth(lazy.tail(list1), 
                     lazy.add(n, lazy.lazy(-1))))
end

-- infinite sequence of 0's
natural = lazy.cons(0, lazy.ref("natural"))

assert(lazy.run(lazy.nth(natural, lazy.lazy(5))) == 0)

function lazy.zipWith(lazyfn, lazy1, lazy2)
  local l1, l2 = lazy.head(lazy1), lazy.head(lazy2)
  local t1, t2 = lazy.tail(lazy1), lazy.tail(lazy2)
  return lazy.cons(lazyfn(l1,l2), 
           lazy.cond(lazy.AND(t1,t2), 
             lazy.zipWith(lazyfn,t1,t2), 
             lazy.lazy(nil)))
end

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

return lazy