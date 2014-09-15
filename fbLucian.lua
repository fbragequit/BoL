-- fbLucian by fbragequit
-- http://botoflegends.com/forum/topic/33672-scriptfree-fblucian-simple-lucian-rework/
if myHero.charName ~= "Lucian" then return end
local version = "0.41"

-- Honda7's autoupdate
local AUTOUPDATE = true

local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/fbragequit/BoL/master/fbLucian.lua".."?rand="..math.random(1, 10000)
local VERSION_PATH = "/fbragequit/BoL/master/fbLucian.version".."?rand="..math.random(1, 10000)
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME

local function ScriptMsg(msg) print("<font color=\"#00ff00\"><b>fbLucian:</b></font> <font color=\"#FFFFFF\">"..msg.."</font>") end

if AUTOUPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, VERSION_PATH)
	if ServerData then
		local ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
		if ServerVersion then
			if tonumber(version) < ServerVersion then
				ScriptMsg("New version available: "..ServerVersion)
				ScriptMsg("Updating, please don't press F9")
				DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function() ScriptMsg("Successfully updated ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end) end, 3)
			else
				ScriptMsg("You've got the latest version ("..version..")")
			end
		end
	else
		ScriptMsg("Error downloading version info")
	end
end
--

require 'VPrediction'

local QRange, QSpeed, QWidth, QDelay, QMaxRange = 622, math.huge, 55, 0.35, 1100
local WRange, WSpeed, WWidth, WDelay = 1000, 1600, 80, 0.3
local AARange = 622

local Player, EnemyHeroes = GetMyHero(), GetEnemyHeroes()
local Target, VP, SOWi, SxOrb, Menu, Minions, DrawLeft, DrawRight, DrawTop
local QCasting, WCasting, ECasting, PassiveBuff = false, false, false, false
local SOWLoaded, SxOrbLoaded, MMALoaded, RebornLoaded, RevampedLoaded = false, false, false, false, false
local QRangeSqr, WRangeSqr = QRange * QRange, WRange * WRange

local function Weaving()
	if Menu.Weave and (QCasting or WCasting or ECasting or PassiveBuff) then
		return true
	end
	return false
end

local function CastQ(unit)
	if GetDistanceSqr(unit, Player) <= QRangeSqr then
		CastSpell(_Q, unit)
	else
		local Position, HitChance = VP:GetPredictedPos(unit, QDelay, QSpeed, Player, false)
		local V, Vn, Vr, Tx, Ty, Tz, Distance, Radius, TopX, TopY, TopZ, LeftX, LeftY, LeftZ, RightX, RightY, RightZ, Left, Right, Top, Poly, Minion, Champion, i

		V = Vector(Position) - Vector(Player)

		Vn = V:normalized()
		Distance = GetDistance(Position, Player)
		Tx, Ty, Tz = Vn:unpack()
		TopX = Position.x - (Tx * Distance)
		TopY = Position.y - (Ty * Distance)
		TopZ = Position.z - (Tz * Distance)

		Vr = V:perpendicular():normalized()
		Radius = GetDistance(Target, Target.minBBox)
		Tx, Ty, Tz = Vr:unpack()
		LeftX = Position.x + (Tx * Radius)
		LeftY = Position.y + (Ty * Radius)
		LeftZ = Position.z + (Tz * Radius)
		RightX = Position.x - (Tx * Radius)
		RightY = Position.y - (Ty * Radius)
		RightZ = Position.z - (Tz * Radius)

		Left = WorldToScreen(D3DXVECTOR3(LeftX, LeftY, LeftZ))
		Right = WorldToScreen(D3DXVECTOR3(RightX, RightY, RightZ))
		Top = WorldToScreen(D3DXVECTOR3(TopX, TopY, TopZ))
		Poly = Polygon(Point(Left.x, Left.y), Point(Right.x, Right.y), Point(Top.x, Top.y))

		for i, Champion in pairs(EnemyHeroes) do
			local ToScreen = WorldToScreen(D3DXVECTOR3(Champion.x, Champion.y, Champion.z))
			local ToPoint = Point(ToScreen.x, ToScreen.y)
			if Poly:contains(ToPoint) and GetDistanceSqr(Champion, Player) <= QRangeSqr then
				CastSpell(_Q, Champion)
			end
		end

		for i, Minion in pairs(Minions.objects) do
			local ToScreen = WorldToScreen(D3DXVECTOR3(Minion.x, Minion.y, Minion.z))
			local ToPoint = Point(ToScreen.x, ToScreen.y)
			if Poly:contains(ToPoint) and GetDistanceSqr(Minion, Player) <= QRangeSqr then
				CastSpell(_Q, Minion)
			end
		end

		if Menu.Drawing.QHelper then
			DrawLeft, DrawRight, DrawTop = Left, Right, Top
			-- making copies for the draw function
		end
	end
end

local function CastW(unit)
	local CastPosition, HitChance, Position = VP:GetLineCastPosition(unit, WDelay, WWidth, WRange, WSpeed, Player, true)
	if CastPosition and HitChance >= 1 and GetDistanceSqr(CastPosition, Player) <= WRangeSqr then
		CastSpell(_W, CastPosition.x, CastPosition.z)
	end
end

local function OrbLoad()
	if _G.MMA_Loaded then
		MMALoaded = true
		ScriptMsg("Found MMA")
	elseif _G.AutoCarry then
		if _G.AutoCarry.Helper then
			RebornLoaded = true
			ScriptMsg("Found SAC: Reborn")
		else
			RevampedLoaded = true
			ScriptMsg("Found SAC: Revamped")
		end
	elseif _G.Reborn_Loaded then
		DelayAction(OrbLoad, 1)
	elseif FileExist(LIB_PATH .. "SxOrbWalk.lua") then
		require 'SxOrbWalk'
		SxOrb = SxOrbWalk()
		SxOrb:LoadToMenu(Menu)
		SxOrbLoaded = true
		ScriptMsg("Loaded SxOrb")
	elseif FileExist(LIB_PATH .. "SOW.lua") then
		require 'SOW'
		SOWi = SOW(VP)
		Menu:addParam("info0", "", SCRIPT_PARAM_INFO, "")
		Menu:addParam("info1", "SOW settings", SCRIPT_PARAM_INFO, "")
		SOWi:LoadToMenu(Menu)
		SOWLoaded = true
		ScriptMsg("Loaded SOW")
	else
		ScriptMsg("Using AllClass TS")
	end
end

local function OrbTarget()
	local T
	if MMALoaded then T = _G.MMA_Target end
	if RebornLoaded then T = _G.AutoCarry.Crosshair.Attack_Crosshair.target end
	if RevampedLoaded then T = _G.AutoCarry.Orbwalker.target end
	if SxOrbLoaded then T = SxOrb:GetTarget() end
	if SOWLoaded then T = SOWi:GetTarget() end
	if T and T.type == Player.type then return T end
	return TS.target
end

local function OrbReset()
	if MMALoaded then
		_G.MMA_ResetAutoAttack()
	elseif RebornLoaded then
		AutoCarry.Orbwalker:ResetAttackTimer()
	elseif SxOrbLoaded then
		SxOrb:ResetAA()
	elseif SOWLoaded then
		SOW:resetAA()
	end
end

local function Killsteal()
	local i, Champion
	for i, Champion in pairs(EnemyHeroes) do
		if ValidTarget(Champion) then
			if GetDistanceSqr(Champion, Player) <= QRangeSqr and getDmg("Q", Champion, Player) > Champion.health then
				CastQ(Champion)
			end
			if GetDistanceSqr(Champion, Player) <= WRangeSqr and getDmg("W", Champion, Player) > Champion.health then
				CastW(Champion)
			end
		end
	end
end

function OnLoad()
	VP = VPrediction()
	TS = TargetSelector(TARGET_LESS_CAST_PRIORITY, QMaxRange, DAMAGE_PHYSICAL)
	Minions = minionManager(MINION_ENEMY, QRange, Player, MINION_SORT_MAXHEALTH_ASC)
	DelayAction(OrbLoad, 1)

	Menu = scriptConfig("fbLucian", "fbLucian")
	Menu:addSubMenu("Combo", "Combo")
	Menu.Combo:addParam("HoldKey", "OnHold Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Menu.Combo:addParam("Q", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Menu.Combo:addParam("W", "Use W", SCRIPT_PARAM_ONOFF, true)
	Menu:addSubMenu("Harass", "Harass")
	Menu.Harass:addParam("HoldKey1", "OnHold Key #1", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
	Menu.Harass:addParam("HoldKey2", "OnHold Key #2", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("N"))
	Menu.Harass:addParam("ToggleKey", "Toggle Key", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("B"))
	Menu.Harass:addParam("ManaLimiter", "Mana Limiter", SCRIPT_PARAM_SLICE, 0, 0, 100, 0)
	Menu.Harass:addParam("Q", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Menu.Harass:addParam("W", "Use W", SCRIPT_PARAM_ONOFF, false)
	Menu:addSubMenu("Drawing", "Drawing")
	Menu.Drawing:addParam("AA", "AA & Q Range", SCRIPT_PARAM_ONOFF, false)
	Menu.Drawing:addParam("QHelper", "Q Helper", SCRIPT_PARAM_ONOFF, true)
	Menu.Drawing:addParam("QMax", "Q Full Range", SCRIPT_PARAM_ONOFF, false)
	Menu.Drawing:addParam("WRange", "W Range", SCRIPT_PARAM_ONOFF, false)
	Menu:addParam("Weave", "Weave", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("KS", "Killsteal", SCRIPT_PARAM_ONOFF, true)
	Menu:addTS(TS)
end

function OnTick()
	TS:update()
	Minions:update()

	Target = OrbTarget()
	if not Target then return end

	if Menu.KS then
		Killsteal()
	end

	if Weaving() then return end

	if Menu.Combo.HoldKey then
		if Menu.Combo.Q then
			CastQ(Target)
		end
		if Menu.Combo.W then
			CastW(Target)
		end
	end
	if (Menu.Harass.HoldKey1 or Menu.Harass.HoldKey2 or Menu.Harass.ToggleKey) and (Player.mana >= Player.maxMana * (Menu.Harass.ManaLimiter / 100)) then
		if Menu.Harass.Q then
			CastQ(Target)
		end
		if Menu.Harass.W then
			CastW(Target)
		end
	end
end

function OnProcessSpell(unit, spell)
	if unit == Player then
		if spell.name == "LucianQ" then
			QCasting = true
			DelayAction(function() QCasting = false end, spell.windUpTime + 0.28)
			-- weaving is screwed without the extra delay on Q, likely due to the spells history
			-- .28 is the lowest value that worked consistently well for me in testing
		end
		if spell.name == "LucianW" then
			WCasting = true
			DelayAction(function() WCasting = false end, spell.windUpTime)
		end
		if spell.name == "LucianE" then
			ECasting = true
			DelayAction(function() ECasting = false OrbReset() end, spell.windUpTime)
		end
	end
end

function OnGainBuff(unit, buff)
	if unit == Player and buff.name == "lucianpassivebuff" then
		PassiveBuff = true
	end
end

function OnLoseBuff(unit, buff)
	if unit == Player and buff.name == "lucianpassivebuff" then
		PassiveBuff = false
	end
end

function OnDraw()
	if Menu.Drawing.QHelper and DrawLeft and DrawRight and DrawTop then
		DrawLine(DrawLeft.x, DrawLeft.y, DrawRight.x, DrawRight.y, 1, 0xFFFF0000)
		DrawLine(DrawLeft.x, DrawLeft.y, DrawTop.x, DrawTop.y, 1, 0xFFFF0000)
		DrawLine(DrawRight.x, DrawRight.y, DrawTop.x, DrawTop.y, 1, 0xFFFF0000)
		DrawLeft, DrawRight, DrawTop = nil
	end
	if Menu.Drawing.QMax then
		DrawCircle(Player.x, Player.y, Player.z, QMaxRange, 0xFFFF0000)
	end
	if Menu.Drawing.WRange then
		DrawCircle(Player.x, Player.y, Player.z, WRange, 0xFFFF0000)
	end
	if Menu.Drawing.AA then
		DrawCircle(Player.x, Player.y, Player.z, AARange, 0xFF00FF00)
	end
end
