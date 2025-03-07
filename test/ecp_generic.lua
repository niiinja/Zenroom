print()
print "= ELLIPTIC CURVE ARITHMETIC OPERATIONS TESTS FOR GENERIC TRANSFORMATIONS"
print()

ECP = require_once('zenroom_ecp')

g1 = ECP.generator()
o = ECP.order()

-- octet serialization back and forth
a = ECP.hashtopoint(O.random(64))
-- print("ECP serialized length: "..#a:octet().." bytes")
-- print(a:octet())
b = ECP.new(a:octet())
assert(a == b)

-- test mod_inverse
i = INT.modrand(ECP.order())
inv = i:modinv(ECP.order())
assert(i:modmul(inv, ECP.order()) == BIG.new(1), 'Error in mod_inverse (gcd based)')

-- test additive homomorphic property
m = { } -- m int mod order
M = { } -- mG
-- aggregation results
local r = INT.new(0)
local R = ECP.infinity() 

for i=1,10,1 do
   m[i] = INT.modrand(o)
   r = r + m[i]
   M[i] = m[i] * g1
   R = R + M[i]
end
assert(R == r*g1, "Error in additive homomorphic property")


-- test zero-knowledge proof
wk = INT.modrand(o)
k = INT.modrand(o)
c = INT.modrand(o)
rk = wk:modsub(c * k, o)
-- rk = (wk - c*k) % o -- error when not using modsub
Aw1 = g1 * wk
Aw2 = (g1*k) * c + g1 * rk

assert(Aw1 == Aw2, 'Error in zero-knowledge proof')


print "OK"
print''
