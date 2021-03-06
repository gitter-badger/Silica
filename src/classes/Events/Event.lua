
class "Event" {
	
	relativeView = nil; -- the view that the event is relative of
	eventType = nil;

	MOUSE_UP = "mouse_up";
	MOUSE_DOWN = "mouse_click";
	MOUSE_DRAG = "mouse_drag";
	MOUSE_SCROLL = "mouse_scroll";
	KEY_DOWN = "key";
	KEY_UP = "key_up";
	CHAR = "char";
	TIMER = "timer";
	TERMINATE = "terminate";
	MENU_CHANGED = "interface_menu_changed";
	INTERFACE_LOADED = "interface_loaded";
	KEYBOARD_SHORTCUT = "interface_keyboard_shortcut";

}

local eventClasses = {}

--[[
	@static
	@desc Registers an Event subclass to a event type name (e.g. DownMouseEvent links with "mouse_down")
	@param [class] _class -- the class that was constructed
]]
function Event.register( eventType, subclass )
	eventClasses[eventType] = subclass
end

--[[
	@static
	@desc Registers an Event subclass after it has just been constructed
	@param [class] _class -- the class that was constructed
]]
function Event.constructed( _class )
	if _class.eventType then
		Event.register( _class.eventType, _class )
	end
end

--[[
	@static
	@desc Creates an event with the arguments in a table from os.pullEvent or similar function
	@param [table] arguments -- the event arguments
	@returns [Event] event
]]
function Event.create( arguments )
	if #arguments >= 1 then
		local eventType = arguments[1]
		local eventClass = eventClasses[eventType]

		if eventClass then
			return eventClass( arguments )
		else
			return Event( arguments )
		end
	end
end

--[[
	@constructor
	@desc Create an event using a table of the values returned from os.pullEvent. Generally called by Event.create.
	@param [table] arguments -- the event arguments
	@return [type] returnedValue -- description
]]
function Event:init( arguments )
	if #arguments >= 1 then
		self.eventType = arguments[1]
	end
end

--[[
	@instance
	@desc Make the event relative to the supplied view
	@param [View] view -- the view to be relative to
]]
function Event:makeRelative( view )
	self.relativeView = view
end
