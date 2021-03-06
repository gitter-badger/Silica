
local floor, ceil = math.floor, math.ceil

local function readstring( handle )
	local v = handle.read()
	local s = ""
	while v ~= 0 do
		s = s .. string.char( v )
		v = handle.read()
	end
	return s
end
local function writestring( handle, text )
	for i = 1, #text do
		handle.write( text:byte( i ) )
	end
end

local no_char_map = {
	width = 5;
	{ true,  true,  true,  true, true };
	{ true, false, false, false, true };
	{ true, false, false, false, true };
	{ true, false, false, false, true };
	{ true, false, false, false, true };
	{ true,  true,  true,  true, true };
}

class "BitmapFont" extends "Font" {
	
}

function BitmapFont:getHeight()
	return self.height
end

function BitmapFont:getWidth( text )
	local w = 0
	for i = 1, #text do
		local scale = self.scale
		local char = text:byte( i )
		local bitmap
		if self.characters[char] then
			bitmap = self.characters[char]
		else
			bitmap = no_char_map
			scale = self.desiredHeight / 6
		end
		w = w + bitmap.width * scale + self.spacing * scale
	end
end

local function renderCharacterScaledDown( setPixel, character, _x, _y, cw, ch, scale, colour )
	_x = _x - 1
	_y = _y - 1
	for x = 1, cw do
		for y = 1, ch do
			if character[y] and character[y][x] then
				setPixel( ceil( _x + x * scale - .5 ), ceil( _y + y * scale - .5 ), colour )
			end
		end
	end
end

function BitmapFont:render( canvas, text, x, y, colour )
	y = y - 1
	x = x - 1
	text = text == nil and "" or tostring( text )
	local buffer = canvas.buffer
	local width, height = canvas.width, canvas.height
	local TRANSPARENT = Graphics.colours.TRANSPARENT
	local function setPixel( x, y, colour )
		if colour ~= TRANSPARENT and x >= 1 and y >= 1 and x <= width and y <= height then
	        buffer[ ( y - 1 ) * width + x ] = colour
	    end
	end
	for i = 1, #text do
		local scale = self.scale
		local char = text:byte( i )
		local bitmap
		if self.characters[char] then
			bitmap = self.characters[char]
		else
			bitmap = no_char_map
			scale = self.desiredHeight / 6
		end
		local cwidth = bitmap.width * scale
		if scale < 1 then
			renderCharacterScaledDown( setPixel, bitmap, x, y, bitmap.width, self.height, scale, colour )
		else
			for _y = 1, self.desiredHeight do
				for _x = 1, ceil( cwidth ) do
					local bx, by = ceil( _x / scale ), ceil( _y / scale )
					local char_is_on = bitmap[by] and bitmap[by][bx]
					if char_is_on then
						setPixel( floor( x + _x + .5 ), floor( y + _y + .5 ), colour ) -- oh no, not this...
					end
				end
			end
		end
		x = x + cwidth + self.spacing * self.scale
	end
end

local function bhasbit( n, i )
	return floor( n / 2 ^ ( 8 - i ) ) % 2 == 1
end

function BitmapFont.decodeCharacter( bytes, width, height )
	local character = {}
	local s = ceil( height / 8 )
	local function hasbit( x, y )
		local byte = ( x - 1 ) * s + ceil( y / 8 )
		local index = y % 8
		if index == 0 then index = 8 end
		local s = ""
		for i = 1, 8 do
			s = s .. ( bhasbit( bytes[byte], i ) and 1 or 0 )
		end
		return bhasbit( bytes[byte], index )
	end
	character.width = width
	for y = 1, height do
		character[y] = {}
		for x = 1, width do
			character[y][x] = hasbit( x, y )
		end
	end
	return character
end

function BitmapFont.encodeCharacter( character, width, height )
	local bytes = {}
	for x = 1, width do
		local byte = {}
		local function close()
			if #byte == 0 then return end
			local n = 0
			for i = 1, #byte do
				n = n * 2 + byte[i]
			end
			byte = {}
			bytes[#bytes + 1] = n
		end
		local function append( b )
			byte[#byte + 1] = b and 1 or 0
			if #byte == 8 then
				close()
			end
		end
		for y = 1, ceil( height / 8 ) * 8 do
			if character[y] then
				append( character[y][x] )
			else
				append()
			end
		end
		close()
	end
	return bytes
end

function BitmapFont.encodeSet( characters, height )
	local bytes = {}
	for k, v in pairs( characters ) do
		local width = v.width or ( v[1] and #v[1] or 0 )
		bytes[#bytes + 1] = k
		bytes[#bytes + 1] = width
		for _, byte in ipairs( BitmapFont.encodeCharacter( v, width, height ) ) do
			bytes[#bytes + 1] = byte
		end
	end
	return bytes
end

function BitmapFont.decodeSet( bytes, height )
	local hf = ceil( height / 8 )
	local characters = {}
	while bytes[1] do
		local character = bytes[1]
		local width = bytes[2]
		table.remove( bytes, 1 )
		table.remove( bytes, 1 )
		local bitmapcount = hf * width
		characters[character] = BitmapFont.decodeCharacter( bytes, width, height )
		for i = 1, bitmapcount do
			table.remove( bytes, 1 )
		end
	end
	return characters
end

function BitmapFont.encodeFile( file, characters, height, metadata )
	local h = fs.open( file, "wb" )
	if h then
		for k, v in pairs( metadata or {} ) do
			h.write( 0 )
			writestring( h, tostring( k ) )
			h.write( 0 )
			writestring( h, tostring( v ) )
			h.write( 0 )
		end
		h.write( 1 )
		h.write( height )
		for _, byte in ipairs( BitmapFont.encodeSet( characters, height ) ) do
			h.write( byte )
		end
		h.close()
		return true
	end
end

function BitmapFont.decodeFile( file )
	local h = fs.open( file, "rb" )
	if h then
		local metadata = {}
		local v = h.read()
		while v == 0 do
			local key, value = readstring( h ), readstring( h )
			metadata[key] = value
			v = h.read()
		end
		local height = h.read()
		local bytes = {}
		for byte in h.read do
			bytes[#bytes + 1] = byte
		end
		local characters = BitmapFont.decodeSet( bytes, height )
		return characters, height, metadata
	end
end

function BitmapFont.convertFile( input, output, charsetStart, height, metadata )
	local newchar = colours.red
	local filled = colours.white
	local image = paintutils.loadImage( input )
	local n = charsetStart or 0

	local chars = { [n] = {} }
	for x = 1, #image[1] do
		if image[1][x] == newchar then
			n = n + 1
			chars[n] = {}
		else
			for y = 1, #image do
				chars[n][y] = chars[n][y] or {}
				chars[n][y][#chars[n][y] + 1] = image[y][x] == filled
			end
		end
	end

	return BitmapFont.encodeFile( output, chars, height, metadata )
end
