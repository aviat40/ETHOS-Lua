-- ##########################################################################################################
-- #                                                                                                        #
-- # Xicoy lua for ETHOS V1.1.0 or above                                                                    #
-- #                                                                                                        #
-- # Turbine widget TeleX Xicoy telemetry module for FrSky	         			                            #
-- #                                                                                                        #
-- # hobby-rc.freeboxos.fr (2022)                                                                           #
-- #                                                                                                        #
-- ##########################################################################################################

-- Path to pictures on SD-CARD
local bitmapsPath = "./bitmaps/"
local version = "1.3"

local locale = system.getLocale()
--local w, h = lcd.getWindowSize()

local lowFuel= "./Fuelev.wav" -- audio file for fuel alert

local maskTurbine, maskBattery, maskTemp, maskRpm, maskPump, maskThro, turbineLogo, maskFuel

local fuelRemaining, percent
local switch = false

local localeTexts = {
	colors = {en="Mask/Text Colors", fr="Couleurs Icone/Texte", de="Hintergrund/Text Farbe", es="text1_es"},
	wrongScreenSize = {en="Wrong screen size", fr="Taille écran incompatible", de="Falsche Bildschirm", es="test5_es"},
	tankCapacity = {en="Tank capacity", fr="Capacité réservoir", de="Tank Inhalt", es="text6_es"},
	fuelAlarm = {en="Fuel warning", fr="Alerte carburant", de="Kraftstoff Warnung", es="text7_es"},
	haptic = {en="Low Fuel Haptic", fr="Vibreur alerte carburant", de="text9_de", es="text9_es"},
	switchPlay = {en="Fuel announce switch", fr="Inter lecture carburant", de="text10_de", es="text10_es"},
	}
	
local function localize(key)
	return localeTexts[key][locale] or localTexts[key]["en"] or key
end


local common = {colorMask=lcd.RGB(192, 0, 192),
				colorText=lcd.RGB(248, 252, 248),
				tankCapacity = 2000,
				fuelAlarm = 600,
				haptic = false,
				switchPlay = nil,
				}
 
local function name(widget)
    return "XICOY"
end

local function menu(widget)
	return{{"XICOY V"..version, function() end}}
end

local function create()
	sensors = {
		{appId=0x4400, label="EGTC", value="value_EGTC"},
		{appId=0x4401, label="RPM1", value="value_RPM1"},
		{appId=0x4402, label="THRT", value="value_THRT"},
		{appId=0x4403, label="VBAT", value="value_VBAT"},
		{appId=0x4404, label="PUMP", value="value_PUMP"},
		{appId=0x4405, label="FUEL", value="value_FUEL"},
		{appId=0x4406, label="STAT", value="value_STAT"},
		{appId=0x4414, label="RPM2", value="value_RPM2"},
		{appId=0x4415, label="TEMP", value="value_TEMP"},
		}	
	
	for i, sensor in ipairs(sensors) do
		sensors[sensor.label] = system.getSource({category=CATEGORY_TELEMETRY, appId=sensor.appId})
		sensors[sensor.value] = nil
	end
	
	return {
			sensors=sensors,
			fuelWarningCount = 1,
			}
end

function drawStatus(x, y, status)
	local msg_table_xicoy = {
		[0]  = "HighTemp",
		[1]  = "Trim Low",
		[2]  = "SetIdle!",
		[3]  = "Ready",
		[4]  = "Ignition",
		[5]  = "FuelRamp",
		[6]  = "Glow Test",
		[7]  = "Running",
		[8]  = "Stop",
		[9]  = "FlameOut",
		[10] = "SpeedLow",
		[11] = "Cooling",
		[12] = "Ignit.Bad",
		[13] = "Start.Fail",
		[14] = "AccelFail",
		[15] = "Start On",
		[16] = "UserOff",
		[17] = "Failsafe",
		[18] = "Low RPM",
		[19] = "Reset",
		[20] = "RXPwFail",
		[21] = "PreHeat",
		[22] = "Battery!",
		[23] = "Time Out",
		[24] = "Overload",
		[25] = "Ign.Fail",
		[26] = "Burner On",
		[27] = "Starting",
		[28] = "SwitchOv",
		[29] = "Cal.Pump",
		[30] = "PumpLimi",
		[31] = "NoEngine",
		[32] = "PwrBoost",
		[33] = "Run-Idle",
		[34] = "Run-Max ",
		[35] = "Restart ",
		[36] = "No Status",
		[37] = "NO SENSOR"
	}	
	local statString = msg_table_xicoy[tonumber(status)] 
	lcd.drawText(x, y, statString, CENTERED)
end

local function getPercentColor(percentColor, fuel, tank)
    if percentColor < (math.floor((fuel / tank)*100)) then
        return 0xFF, 0, 0
    else
       g = math.floor(0xDF * percentColor / 100)
       r = 0xDF - g
       return r, g, 0
    end
end

local function play(widget)
	if common.switchPlay ~= nil then
		if (common.switchPlay:state() ~= switch) and (common.switchPlay:state() == true) then
			system.playNumber(fuelRemaining, UNIT_MILLILITER, 0)
		end
		switch = common.switchPlay:state()
	end
end


local function drawGaugeV(widget)
	w, h = lcd.getWindowSize()
	
	if (w == 388) and (h == 316) then
		boxTop = 5
		boxHeight = h - boxTop - 5
		boxLeft = 310
		boxWidth = w - boxLeft - 5
	else
		boxTop = 5
		boxHeight = h - boxTop - 5
		boxLeft = 600
		boxWidth = w - boxLeft - 5
	end
		--Gauge Background
	lcd.color(WHITE)
	lcd.drawFilledRectangle(boxLeft, boxTop, boxWidth, boxHeight)
		-- Gauge color
	lcd.color(lcd.RGB(getPercentColor(percent, common.fuelAlarm, common.tankCapacity)))
		-- Gauge bar
	gaugeHeight = math.floor(((boxHeight) / 100) * percent)
	lcd.drawFilledRectangle(boxLeft, (boxHeight-gaugeHeight)+5, boxWidth, gaugeHeight)
		-- Gauge frame outline
	lcd.color(BLACK)
	lcd.drawRectangle(boxLeft, boxTop, boxWidth, boxHeight,2)
		-- Gauge percentage
	lcd.font(FONT_XS)
	if (percent > 5) then
		lcd.drawText(boxLeft + boxWidth / 2, boxHeight - gaugeHeight + 5, math.floor(percent).."%", CENTERED)
	else
		lcd.font(FONT_XS_BOLD)
		lcd.color(RED)
		lcd.drawText(boxLeft + boxWidth / 2, boxTop + boxHeight / 2 , "FUEL", CENTERED)
	end
	
end

local function drawGaugeH(widget)
	boxTop = 40
	boxHeight = h - boxTop - 5
	boxLeft = 5
	boxWidth = w - boxLeft - 5
		
			--Gauge Background
	lcd.color(WHITE)
	lcd.drawFilledRectangle(boxLeft, boxTop, boxWidth, boxHeight)
			-- Gauge color
	lcd.color(lcd.RGB(getPercentColor(percent, common.fuelAlarm, common.tankCapacity)))
			-- Gauge bar
	gauge_width = math.floor(((boxWidth) / 100) * percent)
	lcd.drawFilledRectangle(boxLeft, boxTop, gauge_width , boxHeight)
			-- Gauge frame outline
	lcd.color(BLACK)
	lcd.drawRectangle(boxLeft, boxTop, boxWidth, boxHeight,2)
			-- Gauge percentage
	lcd.font(FONT_L)
	if (percent > 5) then
		lcd.drawText((boxLeft + boxWidth) / 2, boxTop + (boxHeight/2) -10, math.floor(percent).."%", CENTERED)
	else
		lcd.font(FONT_L_BOLD)
		lcd.color(RED)
		lcd.drawText((boxLeft + boxWidth) / 2, boxTop + (boxHeight/2) -10 , "FUEL", CENTERED)
	end
end

local function paint(widget)
	w, h = lcd.getWindowSize()
	lcd.color(common.colorText)
	if (w == 388) and (h == 316) then
		-- Mask
		lcd.color(common.colorMask)
		lcd.drawBitmap(120, 2, turbineLogo, 100, 50)
		lcd.drawMask(5, 5, maskTurbine)
		lcd.drawMask(5, 260, maskBattery)
		lcd.drawMask(15, 160, maskTemp)
		lcd.drawMask(5, 120, maskRpm)
		lcd.drawMask(5, 210, maskPump)
		lcd.drawMask(150, 205, maskThro)
		lcd.drawMask(140, 260, maskFuel)
		-- Datas Turbine
		lcd.color(common.colorText)
		lcd.font(FONT_L)

			-- Affichage EGTC
		if widget.sensors["value_EGTC"] ~= nil then
			lcd.drawText(80, 160, widget.sensors["value_EGTC"], LEFT)
		else 
			lcd.drawText(80, 160, "....")
		end
			--Affichage RPM1
		if widget.sensors["value_RPM1"] ~= nil then
			lcd.drawText(80, 115, widget.sensors["value_RPM1"], LEFT)
		else 
			lcd.drawText(80, 115, "....")
		end
			--Affichage Throttle
		if widget.sensors["value_THRT"] ~= nil then
			lcd.drawText(185, 205,widget.sensors["value_THRT"].."%",LEFT)
		else
			lcd.drawText(185, 205, "..")
		end	
			--Affichage V batterie ECU
		if widget.sensors["value_VBAT"] ~= nil then
			lcd.font(FONT_L_BOLD)
			lcd.drawNumber(50, 265, (tonumber(widget.sensors["value_VBAT"])/10),UNIT_VOLT,1,LEFT)
		else
			lcd.font(FONT_L)
			lcd.drawText(50, 265, "..")
		end
			--Affichage Pump
		if widget.sensors["value_PUMP"] ~= nil then
			lcd.drawText(60, 205, widget.sensors["value_PUMP"], LEFT)
		else
			lcd.drawText(60, 205, "...")
		end			
			-- Second Shaft Datas Turbine
		if (widget.sensors["value_RPM2"] ~= nil) then
			lcd.font(FONT_L)
			lcd.drawText(170, 115, " / "..widget.sensors["value_RPM2"], LEFT)
			lcd.drawText(150, 160, " / "..widget.sensors["value_TEMP"], LEFT)
		else
			lcd.font(FONT_L)
			lcd.drawText(170, 115, " / ".."...", LEFT)
			lcd.drawText(150, 160, " / ".."..", LEFT)
		end			
			-- Turbine Status
		lcd.font(FONT_L_BOLD)
		drawStatus( 130, 80, widget.sensors["value_STAT"])	
			-- Fuel Quantity
		if (widget.sensors["value_FUEL"] ~= "0") then
			if (fuelRemaining < common.fuelAlarm) then
				lcd.color(RED)
			end
			lcd.font(FONT_XL)
			lcd.drawNumber(190,260, fuelRemaining,UNIT_MILLILITER)
		else 
			lcd.drawText(190,260,"....")
		end
		-- Fuel Gauge Vertical
		drawGaugeV(widget)
	
	elseif (w == 784) and (h == 316) then
		-- Mask
		lcd.color(common.colorMask)
		lcd.drawBitmap(300, 2, turbineLogo, 100, 50)
		lcd.drawMask(15, 5, maskTurbine)
		lcd.drawMask(350, 180, maskBattery)
		lcd.drawMask(15, 195, maskTemp)
		lcd.drawMask(15, 130, maskRpm)
		lcd.drawMask(15, 270, maskPump)
		lcd.drawMask(170, 270, maskThro)
		lcd.drawMask(350, 260, maskFuel)
		-- Datas Turbine
		lcd.color(common.colorText)
		lcd.font(FONT_XXL)

			-- Affichage EGTC
		if widget.sensors["value_EGTC"] ~= nil then
			lcd.drawText(80, 190, widget.sensors["value_EGTC"], LEFT)
		else 
			lcd.drawText(80, 190, "....")
		end
			--Affichage RPM1
		if widget.sensors["value_RPM1"] ~= nil then
			lcd.drawText(80, 120, widget.sensors["value_RPM1"], LEFT)
		else 
			lcd.drawText(80, 120, "......")
		end
			--Affichage Throttle
		if widget.sensors["value_THRT"] ~= nil then
			lcd.drawText(210, 260,widget.sensors["value_THRT"].."%",LEFT)
		else
			lcd.drawText(210, 260, "...")
		end	
			--Affichage V batterie ECU
		if widget.sensors["value_VBAT"] ~= nil then
			lcd.drawNumber(410, 175, (tonumber(widget.sensors["value_VBAT"])/10),UNIT_VOLT,1,LEFT)
		else
			lcd.drawText(410, 175, "..")
		end
			--Affichage Pump
		if widget.sensors["value_PUMP"] ~= nil then
			lcd.drawText(60, 260, widget.sensors["value_PUMP"], LEFT)
		else
			lcd.drawText(60, 260, "...")
		end			
			-- Second Shaft Datas Turbine
		if (widget.sensors["value_RPM2"] ~= nil) then
			lcd.drawText(230, 120, " / "..widget.sensors["value_RPM2"], LEFT)
			lcd.drawText(200, 190, " / "..widget.sensors["value_TEMP"], LEFT)
		else
			lcd.drawText(230, 120, " / ".."....", LEFT)
			lcd.drawText(200, 190, " /  ".."..", LEFT)
		end			
			-- Turbine Status
		drawStatus( 300, 60, widget.sensors["value_STAT"])	
			-- Fuel Quantity
		if (widget.sensors["value_FUEL"] ~= "0") then
			if (fuelRemaining < common.fuelAlarm) then
				lcd.color(RED)
			end
			lcd.drawNumber(400,260, fuelRemaining,UNIT_MILLILITER)
		else
			lcd.drawText(400,260,"....")
		end
		-- Fuel Gauge Vertical
		drawGaugeV(widget)	
	
	elseif (w == 300) and (h == 88) then
		-- Fuel Quantity
		if (widget.sensors["value_FUEL"] ~= "0") then
			if (fuelRemaining < common.fuelAlarm) then
				lcd.color(RED)
			end
			lcd.font(FONT_XL)
			lcd.drawNumber(w/2,0, fuelRemaining,UNIT_MILLILITER,0, CENTERED)
		else
			lcd.drawText(w/2,0,"....")
		end
		-- Fuel Gauge Horizontal
		drawGaugeH(widget)
	else
		lcd.font(FONT_STD)
		lcd.drawText(w/2, h/2, localize("wrongScreenSize"), CENTERED)
	end
end

local function wakeup(widget)

	for i, sensor in ipairs(widget.sensors) do		
		if widget.sensors[sensor.label] == nil then
			widget.sensors[sensor.label] = system.getSource({category=CATEGORY_TELEMETRY, appId=sensor.appId})
		end
		if widget.sensors[sensor.label] ~= nil then
			widget.sensors[sensor.value] = widget.sensors[sensor.label]:stringValue()
		end
	end
	
	-- Status condition
	if widget.sensors["value_STAT"] == nil then 				--Le capteur n'est pas présent
		widget.sensors["value_STAT"] = "37"
	end
	if widget.sensors["value_STAT"] == "0" then				--Le capteur est présent mais pas de données
		widget.sensors["value_STAT"] = "36"
	end	
	-- Fuel
	if widget.sensors["value_FUEL"] == nil then
		widget.sensors["value_FUEL"] = "0"
	end
	percent = tonumber(widget.sensors["value_FUEL"])
	fuelRemaining = math.floor((percent * common.tankCapacity ) / 100)
	lcd.invalidate()
	play(widget)
	--Check the fuelLevel and play / haptic if switch on
	if (fuelRemaining < common.fuelAlarm) and (common.haptic == true) and (fuelRemaining ~= 0)then
		if (widget.fuelWarningCount ~= 0) then
			system.playFile	(lowFuel)
			system.playHaptic("- . -") 
			widget.fuelWarningCount = widget.fuelWarningCount - 1
		end
	end	
	if (fuelRemaining == common.tankCapacity ) then				-- Réinitialisation du compteur si Reset sans relancer la radio
		widget.fuelWarningCount = 1
	end
	
end

local function configure(widget)
	-- Colors
	line = form.addLine(localize("colors"))
	local slots = form.getFieldSlots(line,{0,70,"/",70})
	form.addColorField(line, slots[2],
		function() return common.colorMask end,
		function(colorMask) common.colorMask = colorMask 
		end)
	form.addStaticText(line, slots[3], "/")
	form.addColorField(line, slots[4], 
		function() return common.colorText end,
		function(colorText) common.colorText = colorText
		end)
	-- Fuel Tank capacity
	line = form.addLine(localize("tankCapacity"))
	local tankField = form.addNumberField(line, nil, 0, 9999,
		function() return common.tankCapacity end,
		function(tankCapacity) common.tankCapacity = tankCapacity
		end)
	tankField:default(2000)
	tankField:step(50)
	tankField:suffix(" ml")
	-- Fuel Tank low level
	line = form.addLine(localize("fuelAlarm"))
    local alarmField = form.addNumberField(line, nil, 0, common.tankCapacity,
		function() return common.fuelAlarm end,
		function(fuelAlarm) common.fuelAlarm = fuelAlarm
		end)
	alarmField:default(600)
	alarmField:step(50)
	alarmField:suffix(" ml")
	-- Alarm Haptic
	line = form.addLine(localize("haptic"))
    local hapticField = form.addBooleanField(line, nil,
		function() return common.haptic end,
        function(haptic) common.haptic = haptic
        end)	
    -- Source Play Number
    line = form.addLine(localize("switchPlay"))
    form.addSwitchField(line, nil, 
		function() return common.switchPlay end,
		function(switchPlay) common.switchPlay = switchPlay
		end)
end

local function read(widget)
	common.colorMask = storage.read("colorMask")
	common.colorText = storage.read("colorText")
	common.tankCapacity = storage.read("tankCapacity")
	common.fuelAlarm = storage.read("fuelAlarm")
	common.haptic = storage.read("haptic")
	common.switchPlay = storage.read("switchPlay")
end

local function write(widget)
	storage.write("colorMask", common.colorMask)
	storage.write("colorText", common.colorText)
	storage.write("tankCapacity", common.tankCapacity)
	storage.write("fuelAlarm", common.fuelAlarm)
	storage.write("haptic", common.haptic)
	storage.write("switchPlay", common.switchPlay)
end

local function init()
	maskTurbine = lcd.loadMask(bitmapsPath.."turbine.png")
	maskBattery = lcd.loadMask(bitmapsPath.."battery.png")
	maskTemp = lcd.loadMask(bitmapsPath.."temp.png")
	maskRpm = lcd.loadMask(bitmapsPath.."rpm.png")
	maskPump = lcd.loadMask(bitmapsPath.."pump.png")
	maskThro = lcd.loadMask(bitmapsPath.."thro.png")
	maskFuel = lcd.loadMask(bitmapsPath.."fuel.png")
	turbineLogo = lcd.loadBitmap(bitmapsPath.."xicoy.png")
	system.registerWidget({key="xicoy", name=name, create=create, title=false, paint=paint, configure=configure, wakeup=wakeup, menu=menu, read=read, write=write})
end

return {init=init}