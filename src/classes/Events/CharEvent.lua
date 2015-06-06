class "CharEvent" extends "Event" {
	eventType = Event.MOUSE_DOWN;
	char = nil;
}

--[[
	@instance
	@desc Creates a char event from the arguments
	@param [table] arguments -- the event arguments
]]
function CharEvent:init( arguments )
	self.super:init( arguments )

	if #arguments >= 2 then
		self.char = arguments[2]
	end
end