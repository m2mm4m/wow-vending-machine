local VM = VendingMachine

function VM:WarningStart()
	if self.WarningThread and not self.WarningThread:IsDead() then return end
	self:NewThread("WarningThread", function (self)
		while true do
			PlaySoundFile("Interface\\AddOns\\VendingMachine\\Sounds\\alarm.ogg", "Master")
			self:Sleep(2.5)
		end
	end, 20)
end

function VM:WarningStop()
	if not self.WarningThread or self.WarningThread:IsDead() then return end
	self.WarningThread:Dispose()
end

VM:NewThread("Warden", function (self)
	local pmap, pfloor, px, py, ptime, cmap, cfloor, cx, cy, ctime
	local playerSpeed
	cmap, cfloor, cx, cy = self:GetPlayerPos()
	ctime = GetTime()
	while true do
		pmap, pfloor, px, py, ptime = cmap, cfloor, cx, cy, ctime
		self:Sleep(self.freq)
		
		cmap, cfloor, cx, cy = self:GetPlayerPos()
		ctime = GetTime()
		local dist = self:CalcDistance(px, py, cx, cy, pmap, pfloor, cmap, cfloor) or 0
		playerSpeed = dist / (ctime - ptime)
		if cmap ~= pmap or playerSpeed > 3 * self:GetExpectedSpeed() then
			self:WarningStart()
			self:Suspend()
		end
	end
end, 15)

function VM.Warden:Reset()
	self:WarningStop()
end

VM.Warden.freq = 0.5
VM.Warden:Suspend()
