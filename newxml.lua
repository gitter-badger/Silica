
local function fromXMLString( value )
	value = string.gsub(value, "&#x([%x]+)%;",
		function(h) 
			return string.char(tonumber(h,16))
		end);
	value = string.gsub(value, "&#([0-9]+)%;",
		function(h)
			return string.char(tonumber(h,10))
		end);
	value = string.gsub (value, "&quot;", "\"");
	value = string.gsub (value, "&apos;", "'");
	value = string.gsub (value, "&gt;", ">");
	value = string.gsub (value, "&lt;", "<");
	value = string.gsub (value, "&amp;", "&");
	return value;
end

local function lex( text, pos, line )
	local tokens = {}
	local pos, line = pos or 1, line or 1
	local function push( type, value )
		tokens[#tokens + 1] = {
			type = type;
			value = value;
			pos = pos;
			line = line;
		}
	end
	while pos <= #text do
		local c = text:sub( pos, pos )
		if c == "\n" then
			line = line + 1
			pos = pos + 1
		elseif c:find "%s" then
			pos = pos + #text:match( "%s+", pos )
		elseif c == "\"" or c == "'" then
			local e, f, l = false, false, line
			for i = pos + 1, #text do
				if e then
					e = false
				elseif text:sub( i, i ) == "\\" then
					e = true
				elseif text:sub( i, i ) == c then
					push( "string", fromXMLString( text:sub( pos + 1, i - 1 ) ) )
					pos = i + 1
					f = true
					break
				elseif text:sub( i, i ) == "\n" then
					line = line + 1
				end
			end
			if not f then
				return false, "[" .. l .. " (char:" .. pos .. ")]: expected '" .. c .. "' to close string"
			end
		elseif c:find "[a-zA-Z%-_]" then
			local v = text:match( "[a-zA-Z%d%-_]+", pos )
			push( "word", v )
			pos = pos + #v
		elseif text:find( "^#?%.?%d", pos ) then
			local v = text:match( "^#?%d*%.?%d+%%?", pos )
			pos = pos + #v
			local percentage = false
			if v:sub( -1 ) == "%" then
				v = v:sub( 1, -2 )
				percentage = true
			end
			if v:sub( 1, 1 ) == "#" then
				v = tonumber( v:sub( 2 ), 16 )
			else
				v = tonumber( v )
			end
			if percentage then
				v = v / 100
			end
			push( "number", v )
		elseif text:find( "<!%-%-.-%-%->", pos ) then
			pos = pos + #text:match( "<!%-%-.-%-%->", pos )
		else
			push( "symbol", c )
			pos = pos + 1
		end
	end
	print "done"
	return tokens
end

local function err( token, msg )
	return "[" .. token.line .. " (char:" .. token.pos .. ")]: " .. msg
end

local parser = {}
function parser:new( tokens )
	local t = setmetatable( {}, { __index = self } )
	t.tokens = tokens
	t.pos = 1
	t.last = tokens[1]
	t.exception = false
	return t
end

function parser:throw( message )
	if self.last then
		self.exception = "[line " .. self.last.line .. ", char " .. self.last.pos .. "]: " .. message
	else
		self.exception = "[unknown]: " .. message
	end
	return false, self.exception
end

function parser:thrown()
	return self.exception
end

function parser:peek()
	return self.tokens[self.pos]
end

function parser:next()
	self.pos = self.pos + 1
	self.last = self.tokens[self.pos] or self.last
	return self.tokens[self.pos]
end

function parser:test( type, value )
	local token = self:peek()
	return token and token.type == type and ( not value or token.value == value )
end

function parser:parseXMLInitialiser()
	local closing = false

	if self:test( "symbol", "/" ) then
		closing = true
		self:next()
	end

	if not self:test "word" then
		return self:throw "expected name of XML item"
	end

	local name = self:peek().value
	self:next()

	if closing then
		if self:test( "symbol", ">" ) then
			self:next()
		else
			return self:throw "expected '>' to close closing tag"
		end
	end

	return name, closing
end

function parser:parseXMLAttributes()
	local attributes = {}
	while true do
		if self:test "word" then
			local name = self:peek().value
			self:next()

			if self:test( "symbol", "=" ) or self:test( "symbol", ":" ) then
				local v = self:next()

				if v.type == "number" or v.type == "string" then
					attributes[name] = v.value
				elseif v.type == "word" then
					local word = v.value
					if word == "true" or word == "false" then
						word = word == "true"
					end
					attributes[name] = word
				else
					return self:throw( "unexpected " .. v.type .. " as attribute value" )
				end

				self:next()
			else
				attributes[name] = true
				self:next()
			end
		elseif self:test( "symbol", "/" ) then
			self:next()
			if not self:test( "symbol", ">" ) then
				return self:throw "expected '>' after '/' to close opening tag"
			end

			self:next()
			return attributes, false
		elseif self:test( "symbol", ">" ) then
			self:next()
			return attributes, true
		elseif not self:peek() then
			return attributes, false
		else
			return self:throw( "unexpected " .. self:peek().type .. " in attributes" )
		end
	end
end

function parser:parseXMLBody()
	local blocks = {}

	while self:peek() do
		while not self:test( "symbol", "<" ) do
			self:next()
		end

		self:next()
		local type, isClosing = self:parseXMLInitialiser()
		if self:thrown() then
			return false, self.exception
		end

		if isClosing then
			return blocks, type
		end

		local attributes, hasBody = self:parseXMLAttributes()
		if self:thrown() then
			return false, self.exception
		end

		local body, closer
		if hasBody then
			body, closer = self:parseXMLBody()
			if self:thrown() then
				return false, self.exception
			end
			if not closer then
				return self:throw( "expected '</" .. type .. ">' to close XML item, got nothing" )
			elseif closer ~= type then
				return self:throw( "expected '</" .. type .. ">' to close XML item, got '</" .. closer .. ">'" )
			end
		end

		blocks[#blocks + 1] = {
			type = type;
			attributes = attributes;
			body = body;
		}
	end

	return blocks
end

local test = [[ <a> <b x:true/> <c x=5% y="hello </a>"/>]]

local p = parser:new( lex( test ) )
local blocks, err = p:parseXMLBody()