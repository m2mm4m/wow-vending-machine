local _GLOBALNAME,self=...

self.WoWClients=self.WoWClients or {}
function self:DetectWoWClient()
	local clients={}
	WinGet()
	self.WoWClients=clients
end
