
class "FontWindowCanvas" extends "Canvas" { }

-- function WindowCanvas:drawTo( ... )
--     if self.isVisible then
--         local hasChanged = self.hasChanged
--         self.super:drawTo( ... )
--         if hasChanged then
--         	self.
--         end
--     end
--     return self
-- end



function FontWindowCanvas:draw( ... )
    if self.isVisible then
    	self.super:draw( ... )

        local font = BitmapFont( 'src/fonts/Auckland.sfont', 6 )
        font:render( self, "Hello!!!", 10, 10, 2 ^ math.random( 0, 15 ) )

        local font2 = BitmapFont( 'src/fonts/Auckland.sfont' )
        font2:render( self, "abcdefghijklmnopqrstuvwxyz", 10, 18, 2 ^ math.random( 0, 15 ) )

        local font2 = BitmapFont( 'src/fonts/Auckland.sfont' )
        font2:render( self, "ABCDEFGHIJKLMNOPQRSTUVWXYZ", 10, 28, 2 ^ math.random( 0, 15 ) )

        local font3 = BitmapFont( 'src/fonts/Auckland.sfont', 16 )
        font3:render( self, "1234567890O", 10, 38, 2 ^ math.random( 0, 15 ) )

        local font4 = BitmapFont( "src/fonts/Auckland.sfont", 32 )
        font4:render( self, "0123456789", 10, 55, 2 ^ math.random( 0, 15 ) )

        local font5 = BitmapFont( "src/fonts/Auckland.sfont", 50 )
        font5:render( self, "hello!!!", 10, 90, 2 ^ math.random( 0, 15 ) )

    	local y = self.height - 1
    	local width = self.width
    	local buffer = self.buffer
    	local transparent = Graphics.colours.TRANSPARENT
    	buffer[y * width + 1] = transparent
    	buffer[y * width + width] = transparent
    end
    return self
end
