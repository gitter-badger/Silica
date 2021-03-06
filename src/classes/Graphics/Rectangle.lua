
class "Rectangle" extends "GraphicsObject" {
	fillColour = Graphics.colours.LIGHT_GREY;
}

function Rectangle:init( x, y, width, height, fillColour ) -- @constructor( number x, number y, number width, number height, graphics.fillColour fillColour )
	self.super:init( x, y, width, height )
	self.fillColour = fillColour
end

--[[
    @instance
    @desc Gets the pixes to be filled
    @return [table] fill -- the pixels to fill
]]
function Rectangle:getFill()
	-- if self.fill then return self.fill end

	local fill = {}
	for x = 1, self.width do
		local fillX = {}
		for y = 1, self.height do
			fillX[y] = true
		end
		fill[x] = fillX
	end
	return fill
end
