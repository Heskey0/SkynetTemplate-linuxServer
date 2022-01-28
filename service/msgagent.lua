local skynet = require "skynet"
local sprotoloader = require "common.sprotoloader"
local print_r = require "common.print_r"
require "common.util"
ErrorCode = require "game.config.ErrorCode"
local Dispatcher = require "game.util.Dispatcher"

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = skynet.tostring,
}

local gate
local userid, subid
local user_info
local c2s_sproto
local CMD = {}

--execute on login
local registerAllModule = function( user_info )
	Dispatcher:Init()
	local handlers = {
		--[[
			1.在此处添加Handler路径
			2.Handler只需返回sproto中的对应的response表
		--]]

		--[[
			"game.account.Account",
			"game.gm.GM",
		--]]
	}
	for i,v in ipairs(handlers) do
		local handler = require(v)
		if handler then
			Dispatcher:RegisterSprotoHandler(handler)
			if handler.PublicClassName and handler.PublicFuncs then
				Dispatcher:RegisterPublicFuncs(handler.PublicClassName, handler.PublicFuncs)
				if handler.PublicFuncs.Init then
					handler.PublicFuncs.Init(user_info, Dispatcher)
				end
			end
		end
	end
end

--execute public func
function CMD.execute( source, className, funcName, ... )
	local func = Dispatcher:GetPublicFunc(className, funcName)
	if func then
		return func(...)
	end
	return nil
end

--call by gated on login
function CMD.login(source, uid, sid, secret, platform, server_id)
	-- you may use secret to make a encrypted data stream
	skynet.error(string.format("%s is login", uid))
	gate = source
	userid = uid
	subid = sid
	user_info = {user_id=uid, platform=platform, server_id=server_id, agent=skynet.self()}
	print('Cat:msgagent.lua[50] user_info.agent', user_info.agent)

	c2s_sproto = sprotoloader.load(1)
	registerAllModule(user_info)
end

local function logout()
	Dispatcher:CallAllPublicFunc("Logout")
	if gate then
		skynet.call(gate, "lua", "logout", userid, subid)
	end
	skynet.exit()
end

function CMD.logout(source)
	-- NOTICE: The logout MAY be reentry
	skynet.error(string.format("%s is logout", userid))
	logout()
end

--call by gated on disconnected
function CMD.afk(source)
	local world = skynet.uniqueservice ("world")
	skynet.call(world, "lua", "role_leave_game", user_info.cur_role_id)
end

local is_game_play_proto = function ( tag )
	return tag >= 100 and tag <= 199
end



skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
		skynet.ret(skynet.pack(f(source, ...)))
	end)

	skynet.dispatch("client", function(_,_, msg)
		local tag, msg = string.unpack(">I4c"..#msg-4, msg)
			--收到请求=> 解析=> 分发
			local proto_info = c2s_sproto:query_proto(tag)
			if proto_info and proto_info.name then
				local content = c2s_sproto:request_decode(tag, msg)
				-- print_r(content)
				local response
				local handler = Dispatcher:GetSprotoHandler(proto_info.name)
				if handler then
					response = handler(content)
				end
				local ok, response_str = pcall(c2s_sproto.response_encode, c2s_sproto, tag, response)
				if ok then
					skynet.ret(response_str)
				else
					skynet.error("msgagent handle proto failed!", proto_info.name)
					skynet.ignoreret()
				end
			else
				skynet.error("recieve wrong proto string : ", msg)
				skynet.ignoreret()
			end
	end)
end)
