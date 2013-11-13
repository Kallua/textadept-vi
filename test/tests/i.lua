test.open('words.txt')
local lineno = test.lineno
local colno = test.colno
local assertEq = test.assertEq
local log = test.log

assertEq(lineno(), 0) assertEq(colno(), 0)

test.key('i', 'x', 'y', 'z', 'escape')
assertEq(colno(), 2)
assertEq(buffer:get_line(0), 'xyzone two three four five\n')
test.key('j', 'i', 'z', 'y', 'x', 'escape')
assert(lineno(), 1) assertEq(colno(), 4)
assertEq(buffer:get_line(1), 'hezyxy bee cee dee ee eff\n')

test.key('j', '0', '.')
assertEq(buffer:get_line(2), 'zyxsome miscellaneous text')
assertEq(lineno(), 2) assertEq(colno(), 3)
