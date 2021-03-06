
local _log, debug, last, need_ellipsis, count

local Lua_keywords = {}
Lua_keywords["if"] = true
Lua_keywords["elseif"] = true
Lua_keywords["else"] = true
Lua_keywords["while"] = true
Lua_keywords["for"] = true
Lua_keywords["repeat"] = true
Lua_keywords["until"] = true
Lua_keywords["do"] = true
Lua_keywords["then"] = true
Lua_keywords["function"] = true
Lua_keywords["return"] = true
Lua_keywords["break"] = true
Lua_keywords["end"] = true
Lua_keywords["local"] = true
Lua_keywords["not"] = true
Lua_keywords["true"] = true
Lua_keywords["false"] = true

local function _serialize( v, t )
	if type( v ) == "table" and pcall( function() if type( getmetatable( v ).__tostring ) ~= "function" then error "" end end ) then
		return tostring( v )
	elseif type( v ) == "table" then
		if not next( v ) then return "{}" end
		if t.serializing[v] then
			return "recursion"
		end
		if t.serialized[v] then
			return t.serialized[v]
		end
		t.serializing[v] = true
		local d = {}
		local s = "{ "
		for i, v in ipairs( v ) do
			d[i] = true
			s = s .. _serialize( v, t ) .. ", "
		end
		for k, v in pairs( v ) do
			if not d[k] then
				if type( k ) == "string" and not k:find "[^%w_]" and not Lua_keywords[k] then
					s = s .. k .. " = " .. _serialize( v, t ) .. ", "
				else
					s = s .. "[" .. _serialize( k, t ) .. "] = " .. _serialize( v, t ) .. ", "
				end
			end
		end
		t.serializing[v] = false
		return s:sub( 1, -3 ) .. " }"
	elseif type( v ) == "function" and not tostring( v ):find "^function: " then -- lua functions, tostring( tostring ) = "tostring", now "function: tostring"
		return "function: " .. tostring( v )
	elseif type( v ) == "function" or type( v ) == "thread" then
		return tostring( v )
	elseif type( v ) == "string" then
		return textutils.serialize( v:gsub( "\n", " " ) )
	else
		return textutils.serialize( v )
	end
end
local function timestamp()
	local t = tostring( os.clock() )
	if #t:match "%.(%d+)" == 1 then
		return "[" .. t .. "0]: "
	elseif not t:find "%." then
		return "[" .. t .. ".00]: "
	end
	return "[" .. t .. "]: "
end
local function writeContent( content, include_time )
	if _log then
		if last == content and debug.no_repeats then
			need_ellipsis = true
			count = ( count or 0 ) + 1
			return
		else
			if need_ellipsis then
				need_ellipsis = false
				_log.writeLine( " ... " .. count .. " repeats ..." )
			end
			count = nil
		end
		last = content
		if include_time then
			content = timestamp() .. content
		end
		_log.writeLine( content )
		_log.flush()
	end
end
local function _traceback(ignore, level)
	level = type(level) == "number" and level
	local errorLevel = 3 + (type(ignore) == "number" and ignore or 0)
	local errorDiff = errorLevel
	local errorPos, result = nil, {}
	repeat
		errorPos = select(2, pcall(error, "@", errorLevel)):match("^(.+): @$")
		if errorPos then
			result[#result + 1] = errorPos
			errorLevel = errorLevel + 1
			if errorLevel - errorDiff == level then return result end
		end
	until not errorPos
	return result
end

debug = {}
debug.no_repeats = true

function debug.traceback( level, as_string )
	local t = _traceback( level or 1 )
	for i = #t, 1, -1 do
		if t[#t] == "xpcall" then
			t[#t] = nil
			break
		end
		t[#t] = nil
	end
	if as_string then
		return table.concat( t, "\n in " )
	end
	return t
end

function debug.line( level )
	return tonumber( select( 2, pcall( error, "@", 2 + ( level or 1 ) ) ):match "^.+:(%d+): @$" ) or "unknown"
end

function debug.pos( level )
	return select( 2, pcall( error, "@", 2 + ( level or 1 ) ) ):match "^(.+): @$" or "unknown"
end

function debug.call( f )
	return xpcall( f, function( err )
		local t = _traceback( 2 )
		for i = #t, 1, -1 do
			if t[#t] == "xpcall" then
				t[#t] = nil
				break
			end
			t[#t] = nil
		end
		return table.concat( { tostring( err ), unpack( t ) }, "\n in " )
	end )
end

function debug.open( file )
	if _log then
		_log.close()
	end
	_log = fs.open( file, "w" )
end

function debug.close()
	if _log then
		writeContent " -- Closing log --"
		_log.close()
		_log = nil
	end
end

function debug.log( ... )
	local t = { ... }
	for i = 1, #t do
		t[i] = _serialize( t[i], { serializing = {}, serialized = {} } ):gsub( "\n", " " )
	end
	return writeContent( table.concat( t, ", " ), true )
end

function debug.logf( fmt, ... )
	local t = { ... }
	for i = 1, #t do
		pcall( function()
			t[i] = getmetatable( t[i] ).__tostring( t[i] )
		end )
	end
	return writeContent( string.format( fmt, unpack( t ) ):gsub( "\n", " " ), true )
end

function debug.logtraceback( level )
	local t = _traceback( level or 1 )
	for i = #t, 1, -1 do
		if t[#t] == "xpcall" then
			t[#t] = nil
			break
		end
		t[#t] = nil
	end
	return writeContent( "Traceback: " .. table.concat( t, "  in " ), true )
end

function debug.note( message )
	return writeContent( " -- " .. tostring( message ) .. " --" )
end

function debug.flag( message, level )
	return writeContent( "Info: " .. ("%q"):format( tostring( message ) ) .. "  in " .. debug.traceback( ( level or 1 ) + 1, true ):gsub( "\n", " " ), true )
end

function debug.warning( message, level )
	return writeContent( "WARNING: " .. ("%q"):format( tostring( message ) ) .. "  in " .. debug.traceback( ( level or 1 ) + 1, true ):gsub( "\n", " " ), true )
end

function debug.error( message, level )
	writeContent( "FATAL: " .. ("%q"):format( tostring( message ) ) .. "  in " .. debug.traceback( ( level or 1 ) + 1, true ):gsub( "\n", " " ), true )
	return error( message, level )
end

return debug
