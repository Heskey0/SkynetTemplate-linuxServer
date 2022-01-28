local skynet = require "skynet"
local mysql = require "skynet.db.mysql"
require "skynet.manager"
require "common.util"

--[[
用法:
local dbserver = skynet.localname(".your db name")
local is_succeed = skynet.call(dbserver, "lua", "insert", "insert into Table(Id) values(1)")
--]]
local db

local function ping()
	while true do
		if db then
			db:query("select l;")
		end
		skynet.sleep(3600*1000)
	end
end

local CMD = {}

function CMD.open( conf )
	db = mysql.connect(conf)
	skynet.fork(ping)

	skynet.register(conf.name or "."..conf.database)
end

function CMD.close( conf )
	if db then
		db:disconnect()
		db = nil
	end
end

function CMD.insert( sql )
	local result = db:query(sql)
	if result.errno then
		skynet.error(result.err)
		return false
	end
	return true
end

function CMD.delete( sql )
	local result = db:query(sql)
	if result.errno then
		skynet.error(result.err)
		return false
	end
	return true
end

function CMD.select( sql )
	local result = db:query(sql)
	if result.errno then
		skynet.error(result.err)
		return false
	end
	return true, result
end

function CMD.update( sql )
	local result = db:query(sql)
	if result.errno then
		skynet.error(result.err)
		return false
	end
	return true 
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], "can't not find cmd :"..(cmd or "empty"))
		if session == 0 then
			f(...)
		else
			skynet.ret(skynet.pack(f(...)))
		end
	end)
end)

