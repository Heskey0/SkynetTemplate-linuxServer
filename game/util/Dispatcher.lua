local Dispatcher = {}

function Dispatcher:Init(  )
	self.sprotoHandlers = {}
	self.publicFuncs = {}
	self.sprotoServices = {}
end

--k:sproto_name		v:function
function Dispatcher:RegisterSprotoHandler( handler )
	for k,v in pairs(handler) do
		self.sprotoHandlers[k] = v
	end	
end

function Dispatcher:GetSprotoHandler( sprotoName )
	return self.sprotoHandlers[sprotoName]
end

--k:table_name		v:function_table
function Dispatcher:RegisterPublicFuncs( publicClassName, publicFuncs )
	self.publicFuncs[publicClassName] = publicFuncs
end

function Dispatcher:GetPublicFunc( publicClassName, funcName )
	return self.publicFuncs[publicClassName] and self.publicFuncs[publicClassName][funcName]
end

function Dispatcher:CallAllPublicFunc( funcName )
	for k,v in pairs(self.publicFuncs) do
		if v[funcName] then
			v[funcName]()
		end
	end
end

return Dispatcher