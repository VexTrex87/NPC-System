local ThreadValue = game.ReplicatedStorage.Threads

NewThread = function(func,...)
	ThreadValue.Value = ThreadValue.Value + 1
	
	local a = coroutine.wrap(function(...)
		func(...)
		ThreadValue.Value = ThreadValue.Value - 1
	end)
	
	a(...)	
end

return NewThread