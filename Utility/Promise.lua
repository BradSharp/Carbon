-- A lightweight Promise implementation for RBX.Lua

-- Author:	Brad Sharp
-- License:	MIT
-- Date:	1/3/2021

local Core		= script:FindFirstAncestorWhichIsA("Configuration")

local Class		= require(Core.Utility.Class)
local Enum		= require(Core.Utility.Enum)
local Status	= Enum { "Running", "Resolved", "Rejected" }
local Promise	= Class()

local function run(executor, resolve, reject)
	local success, result = pcall(executor, resolve, reject)
	if not success then
		reject(result)
	end
end

local function passback(...)
	return ...
end

function Promise.new(executor, ...)
	
	local self = setmetatable({
		Status	= Status.Running,
		Result	= nil,
		__event	= Instance.new("BindableEvent") -- coroutine.resume is not viable, I do this with great reluctance
	}, Promise)

	local function resolve(...)
		self:__update(Status.Resolved, table.pack(...))
	end
	
	local function reject(error)
		self:__update(Status.Rejected, error)
	end
	
	local runner = coroutine.wrap(run)
	runner(executor, resolve, reject, ...)
	return self
	
end

function Promise:__update(status, result)
	if not self.Status == Status.Running then
		return
	end
	self.Status = status
	self.Result = result
	self.__event:Fire()
	self.__event:Destroy() -- TODO: Should we cache this instead?
end

function Promise:Await()
	if self.Status == Status.Running then
		self.__event.Event:Wait()
	end
	if self.Status == Status.Rejected then
		error(self.Result, 2)
	end
	return table.unpack(self.Result)
end

function Promise:Then(onResolve, onReject)
	onResolve, onReject = onResolve or passback, onReject or passback
	return Promise.new(function (resolve, reject)
		if self.Status == Status.Running then
			self.__event.Event:Wait()
		end
		if self.Status == Status.Rejected then
			reject(onReject(self.Result))
		else
			resolve(onResolve(table.unpack(self.Result)))
		end
	end)
end

function Promise:Catch(onReject)
	return self:Then(nil, onReject)
end

function Promise:Cancel()
	self:__update(Status.Rejected, "Promise was cancelled")
end

Promise.Status = Status

return Promise
