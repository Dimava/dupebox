require("util")


Box = {}
Box.meta = {}
Box.prototype = {__class = "Box"}
Box.metaprototype = {__index = Box.prototype}
Box.protomt = {}
setmetatable(Box, Box.meta)
setmetatable(Box.prototype, Box.protomt)
if not _G.Pos then require("control/Pos") end


function Box.new(o)
	if o[1] and o[2] then return setmetatable({Pos(o[1]), Pos(o[2])}, Box.metaprototype) end
	if o.left_top and o.right_bottom then
		return setmetatable({Pos(o.left_top), Pos(o.right_bottom)}, Box.metaprototype)
	end
	error("Box.new: not an area: "..serpent.block(o))
end
function Box.meta:__call(...)
	return Box.new(...)
end

function Box:fromPos(pos, radius)
	pos = Pos(pos)
	radius = radius or 0
	return Box.new{{pos[1]-radius,pos[2]-radius},{pos[1]+radius,pos[2]+radius}}
end

function Box.prototype:ceil()
	return Box.new{{math.floor(self[1][1]), math.floor(self[1][2])},
					{math.ceil(self[2][1]), math.ceil(self[2][2])}}
end

function Box.prototype:floor()
	return Box.new{{math.ceil(self[1][1]), math.ceil(self[1][2])},
					{math.floor(self[2][1]), math.floor(self[2][2])}}
end

function Box.prototype:rel_in(pos)
	pos = Pos(pos)
	res = pos:add(self[1])
	if pos[1] < 0 then res[1] = self[2][1] + pos[1] end
	if pos[2] < 0 then res[2] = self[2][2] + pos[2] end
	return res
end

function Box.prototype:rel_in(pos)
	pos = Pos(pos)
	res = pos:add(self[1])
	if pos[1] > 0 then res[1] = self[2][1] + pos[1] end
	if pos[2] > 0 then res[2] = self[2][2] + pos[2] end
	return res
end

function Box.prototype:size()
	return Pos{self[2][1] - self[1][1], self[2][2] - self[1][2]}
end

function Box.prototype:grow(v1, v2)
	v2 = v2 or v1
	if type(v1) == "number" then v1 = Pos{v1, v2} v2 = v1 end
	return Box{self[1]:sub(v1), self[2]:add(v2)}
end


function Box.prototype:width()
	return self[2][1] - self[1][1]
end

function Box.prototype:height()
	return self[2][2] - self[1][2]
end

function Box.prototype:left_bottom()
	return Pos{self[1][1], self[2][2]}
end

function Box.prototype:right_top()
	return Pos{self[2][1], self[1][2]}
end

function Box.prototype:center()
	return Pos{(self[1][1] + self[2][1]) / 2, (self[1][2] + self[2][2]) / 2}
end

function Box.prototype:move(v)
	return Box{self[1]:add(v), self[2]:add(v)}
end

function Box.prototype:normalize()
	return Box{
		{math.min(self[1][1], self[2][1]), math.min(self[1][2], self[2][2])},
		{math.max(self[1][1], self[2][1]), math.max(self[1][2], self[2][2])},
	}
end

function Box.prototype:contains(pos)
	if not pos then error("pos is nil!") end
	pos = Pos(pos)
	return self[1][1] < pos[1] and pos[1] < self[2][1]
		and self[1][2] < pos[2] and pos[2] < self[2][2]
end
-- function Pos.prototype:add(o)
-- 	if not o.__class then o = Pos.new(o) end
-- 	if o.__class ~= "Pos" then error("Can't Pos.add("..o.__class..")") end
-- 	return Pos.new{self[1] + o[1], self[2] + o[2]}
-- end

-- function Pos.prototype:sub(o)
-- 	if not o.__class then o = Pos.new(o) end
-- 	if o.__class ~= "Pos" then error("Can't Pos.sub("..o.__class..")") end
-- 	return Pos.new{self[1] - o[1], self[2] - o[2]}
-- end

-- function Pos.prototype:neg()
-- 	return Pos.new{-self[1], -self[2]}
-- end

-- function Pos.prototype:mul(o)
-- 	if type then o = Pos.new(o) end
-- 	if type(o) ~= "number" then error("Can't Pos.mul("..serpent.block(o)..")") end
-- 	return Pos.new{self[1] * o, self[2] * o}
-- end

-- function Pos.prototype:addmul(o, m)
-- 	if type(m) ~= "number" then error("Can't Pos.mul("..serpent.block(m)..")") end
-- 	return Pos(o):mul(m):add(self)
-- end

-- function Pos.prototype:mod(x, y)
-- 	if type(x) ~= "number" then x = Pos(x) end
-- 	if type(x) == "table" and x.__class == "Pos" then x, y = x[1], x[2] end
-- 	if y == nil then y = x end
-- 	if type(x) ~= "number" or type(y) ~= "number" then
-- 		error("Can't Pos.mod("..serpent.block(x)..","..serpent.block(y)..",)")
-- 	end
-- 	return Pos{self[1] % x, self[2] % y}
-- end



