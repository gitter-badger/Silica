
class "Application" {
	name = nil;
	path = nil;
	updateTimer = nil;
	lastUpdate = 0;
	arguments = {};
	isRunning = false;
	container = nil;
	event = nil;
	schedules = {};

	-- TODO: exit codes
	exitCode = {
		OKAY = 1;
		ERROR = 2;
		-- etc
	};
}

--[[
	@instance
	@desc Creates the application runtime for the Silica program. Call :run() on this to start it.
]]
function Application:init()
	self.event = ApplicationEventManager( self )
	self.container = ApplicationContainer( { x = 1; y = 1; width = 52; height = 19 } ) -- we'll make this auto-stretch later
	class.application = self
	self:event( Event.TIMER, self.onTimer )
end

--[[
	@instance
	@desc Update all application's views
]]
function Application:update()
	-- not exactally sure how to handle deltaTime for the first one. for now it's zero
	local lastUpdate = self.lastUpdate or 0
	local deltaTime = os.clock() - lastUpdate
	-- self.updateTimer = os.startTimer( 0.05 )
	self.lastUpdate = os.clock()

	self:checkScheduled( lastUpdate )

	self.container:update( deltaTime )
	self.container:draw()
	-- self.container:render( term )
end

--[[
	@instance
	@desc Schedules a function to be called at a specified time in the future
	@param [number] time -- in how many seconds the function should be run
	@param [function] func -- the function to call
	@param [class] _class -- the class to call the function on (optional)
	@param tag -- any unique value you want to be associated with the tag. will be passed as the only parameter (other than self)
	@return [number] scheduleId -- the ID of the scheduled task
]]
function Application:schedule( time, func, _class )
	table.insert( self.schedules, { os.clock() + time, func, _class } )
end

--[[
	@instance
	@desc Unschedule a scheduled task
	@param [number] scheduleId -- the ID of the scheduled task
	@return [boolean] didUnschedule -- whether the task was unscheduled. this is only false if the task no longer exists or never existed
]]
function Application:unschedule( scheduleId, arg2, arg3 )
	if self.schedules[scheduleId] then
		self.schedules[scheduleId] = nil
		return true
	else return false end
end

--[[
	@instance
	@desc Run any scheduled tasks that need to be run
	@param [number] lastUpdate -- the time of the last update
]]
function Application:checkScheduled( lastUpdate )
	local now = os.clock()
	for scheduleId, task in ipairs( self.schedules ) do
		if lastUpdate < task[1] and task[1] <= now then
			if task[3] then
				task[2](task[3], task[4])
			else
				task[2](task[4])
			end
			self.schedules[scheduleId] = nil
		end
	end
end

--[[
	@instance
	@desc Called when a timer is fired
	@param [TimerEvent] event -- the timer event
	@return [boolean] stopPropagation -- whether following handlers should not recieve this event
]]
function Application:onTimer( event )
	if event.timer and event.timer == self.updateTimer then
		self:update()
		return true
	end
end

--[[
	@instance
	@desc Runs the application runtime with the supplied arguments
	@param ... -- the arguments feed to the program (simply use ... for the arguments)
	@return [number] exitCode -- returns the exit code of the application
]]
function Application:run( ... )
	self.arguments = { ... }
	self.isRunning = true

	self:update()

	while self.isRunning do
		local args = { coroutine.yield() }
		local event = Event.create( args )
		self.event:handleEvent( event )
	end
end