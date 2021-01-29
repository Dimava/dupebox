require("util")


Pos = {}
Pos.meta = {}
Pos.prototype = {__class = "Pos"}
Pos.metaprototype = {__index = Pos.prototype}
setmetatable(Pos, Pos.meta)
if not _G.Box then require("control/Box") end

function Pos.new(o)
	if o[1] and o[2] then return setmetatable({o[1], o[2]}, Pos.metaprototype) end
	if o.x and o.y then return setmetatable({o.x, o.y}, Pos.metaprototype) end
	error("Pos.new: not a position: "..serpent.block(o))
end
function Pos.meta:__call(...)
	return Pos.new(...)
end

function Pos.prototype:add(o)
	if not o.__class then o = Pos.new(o) end
	if o.__class ~= "Pos" then error("Can't Pos.add("..o.__class..")") end
	return Pos{self[1] + o[1], self[2] + o[2]}
end

function Pos.prototype:sub(o)
	if not o.__class then o = Pos.new(o) end
	if o.__class ~= "Pos" then error("Can't Pos.sub("..o.__class..")") end
	return Pos{self[1] - o[1], self[2] - o[2]}
end

function Pos.prototype:neg()
	return Pos{-self[1], -self[2]}
end

function Pos.prototype:mul(o)
	if type(o) ~= "number" then error("Can't Pos.mul("..serpent.block(o)..")") end
	return Pos{self[1] * o, self[2] * o}
end

function Pos.prototype:div(o)
	if type(o) ~= "number" then error("Can't Pos.div("..serpent.block(o)..")") end
	return Pos{self[1] / o, self[2] / o}
end

function Pos.prototype:addmul(o, m)
	if type(m) ~= "number" then error("Can't Pos.mul("..serpent.block(m)..")") end
	return Pos(o):mul(m):add(self)
end

function Pos.prototype:mod(x, y)
	x = Pos.to_pos_arg(x, y)
	return Pos{self[1] % x[1], self[2] % x[2]}
end

function Pos.prototype:scale(x, y)
	x = Pos.to_pos_arg(x, y)
	return Pos{self[1] * x[1], self[2] * x[2]}
end

function Pos.prototype:dot(x, y)
	x = Pos.to_pos_arg(x, y)
	return self[1] * x[1] + self[2] * x[2]
end

function Pos.prototype:rbox(r, r2)
	r = Pos.to_pos_arg(r, r2)
	return Box{{self[1] - r[1], self[2] - r[2]}, {self[1] + r[1], self[2] + r[2]}}
end


function Pos.prototype:grow(r, r2)
	r = Pos.to_pos_arg(r, r2)
	return Box{{self[1] - r[1], self[2] - r[2]}, {self[1] + r[1], self[2] + r[2]}}
end


function Pos.prototype:round(o)
	if type(o) ~= "number" then o = 1 end
	return Pos{math.floor((self[1] / o) + 0.5) * o, math.floor((self[2] / o) + 0.5) * o}
end


function Pos.prototype:equals(o)
	if o.__class ~= "Pos" then o = Pos.new(o) end
	return self[1] == o[1] and self[2] == o[2]
end


function Pos.fromdir(direction)
	local dirtov = {[0]={0,-1},[2]={1,0},[4]={0,1},[6]={-1,0}}
	return Pos(dirtov[direction])
end

function Pos.to_pos_arg(x, y)
	if type(x) == "number" then
		y = y or x
		return Pos{x, y or x}
	end
	return Pos(x)
end