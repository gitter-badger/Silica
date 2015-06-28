
class "SeparatorMenuItem" extends "MenuItem" {
	text = nil;

	height = 3;
	width = 51;

	textColour = Graphics.colours.LIGHT_GREY;

    pressedTextColour = Graphics.colours.WHITE;

    disabledTextColour = Graphics.colours.LIGHT_GREY;

}

--[[
	@constructor
	@desc Initialise a application container instance
	@param [table] properties -- the properties for the view
]]
function SeparatorMenuItem:init( ... )
	self.super.super:init( ... )
end

function SeparatorMenuItem:initCanvas()
	self.super:initCanvas()
    self.backgroundObject = self.canvas:insert( Separator( 5, 2, self.width - 8, 1 ) )
end

function SeparatorMenuItem:setIsPressed( isPressed )
    self.isPressed = false
end

function SeparatorMenuItem:setWidth( width )
    self.width = width
    self.backgroundObject.width = width - 8
end

function SeparatorMenuItem:setHeight( height )
    self.height = height
    self.backgroundObject.height = 1
end
