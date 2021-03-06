
class "Interface" {
	name = nil;
	container = nil;
}

--[[
	@constructor
	@desc Creates and loads an interface with the given name
	@param [string] interfaceName -- the file name of the interface
]]
function Interface:init( interfaceName, extend )
	self.name = interfaceName
	extend = extend or ApplicationContainer

	-- TODO: dynamic path resolving for interfaces and other files
	local path = "/src/interface/" .. interfaceName .. ".sml"
	if fs.exists( path ) then
		local nodes, err = XML.fromFile( path )
		if not nodes then
			error( path .. err, 0 )
		end
		local err = self:initContainer( nodes[1], extend )
		if err then
			error( "Interface XML invaid: " .. self.name .. ".sml. Error: " .. err, 0 )
		end
	else
		error( "Interface file not found: " .. interfaceName .. ".sml", 0 )
	end

end

--[[
	@instance
	@desc Creates the container from the interface file
]]
function Interface:initContainer( nodes, extend )
	if not nodes then
		return "Format invalid."
	end

	local containerClass = class.get( nodes.type )

	if not containerClass then
		return "Container class not found: " .. nodes.type
	elseif not containerClass:typeOf( extend ) then
		return "Container class does not extend '" .. extend.className .. "': " .. nodes.type
	end

	local container = containerClass( nodes.attributes )
	if not container then
		return "Failed to initialise " .. nodes.type .. ". Identifier: " .. tostring( nodes.attributes.identifier )
	end

	local function insertTo( childNode, parentContainer )
		local childClass = class.get( childNode.type )

		if not containerClass then
			return "Class not found: " .. childNode.type
		elseif not containerClass:typeOf( View ) then
			return "Class does not extend 'View': " .. childNode.type
		end

		local child = childClass( childNode.attributes )
		if not child then
			return "Failed to initialise " .. childNode.type .. ". Identifier: " .. tostring( childNode.attributes.identifier )
		end

		parentContainer:insert( child )

		if childNode.body and #childNode.body > 0 then
			if not containerClass:typeOf( Container ) then
				return "Class does not extend 'Container' but has children: " .. childNode.type
			else
				for i, _childNode in ipairs( childNode.body ) do
					insertTo( _childNode, child )
				end
			end
		end
	end

	for i, childNode in ipairs( nodes.body ) do
		insertTo( childNode, container )
	end

	self.container = container
	self.container.event:handleEvent( LoadedInterfaceEvent( self.container ) )
end
