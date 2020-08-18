local Helper = {}
local ThreadValue = game.ReplicatedStorage.Threads

Helper.NewThread = function(func,...)
	ThreadValue.Value = ThreadValue.Value + 1
	
	local a = coroutine.wrap(function(...)
		func(...)
		ThreadValue.Value = ThreadValue.Value - 1
	end)
	
	a(...)	
end

Helper.Round = function(n)
	return math.floor(n + 0.5)
end

return Helper