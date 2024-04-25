-- ##########################################################################################################
-- #                                                                                                        #
-- # Xicoy lua for ETHOS V1.5.7 or above                                                                    #
-- #                                                                                                        #
-- # Turbine widget TeleX Xicoy telemetry module for FrSky	         			                            #
-- #                                                                                                        #
-- # hobby-rc.freeboxos.fr (2024)                                                                           #
-- #                                                                                                        #
-- ##########################################################################################################

-- Path to pictures on SD-CARD
local bitmapsPath = "./bitmaps/"
local version = "1.4"

local locale = system.getLocale()

local audioPath = system.getAudioVoice()

local maskBattery, maskTemp, maskRpm, maskPump, maskThro, turbineLogo, maskFuel, maskTurbine, maskTimer

local fuelRemaining = 0
local switch = false

local localeTexts = {
	colors = {en="Mask/Text Colors", fr="Couleurs Icone/Texte", de="Hintergrund/Text Farbe", es="text1_es"},
	wrongScreenSize = {en="Wrong screen size", fr="Taille écran incompatible", de="Falsche Bildschirm", es="test5_es"},
	tankCapacity = {en="Tank capacity", fr="Capacité réservoir", de="Tank Inhalt", es="text6_es"},
	fuelAlarm = {en="Fuel warning", fr="Alerte carburant", de="Kraftstoff Warnung", es="text7_es"},
	fileAlarm = {en="File Name", fr="Fichier alarme", de="Name De", es="text8_es"},
	haptic = {en="Low Fuel Haptic", fr="Vibreur alerte carburant", de="text9_de", es="text9_es"},
	switchPlay = {en="Fuel announce switch", fr="Inter lecture carburant", de="text10_de", es="text10_es"},
	turbine = {en="Xicoy model", fr="Modèle Xicoy", de ="texte_de", es="texte_es"},
	layout = {en="Wrong layout", fr="Mauvais écran", de =" Texte", es =" Text"}
	}
	
local function localize(key)
	return localeTexts[key][locale] or localTexts[key]["en"] or key
end
 
local function name(widget)
    return "XICOY"
end

local function menu(widget)
	return{{"XICOY V"..version, function() end}}
end

local EGTC = 0x4400
local RPM1 = 0x4401
local THRT = 0x4402
local VBAT = 0x4403
local PUMP = 0x4404
local FUEL = 0x4405
local STAT = 0x4406
local RPM2 = 0x4414
local TEMP = 0x4415

local function create()

	local sensors = {
		-- [INTERFACE] = {test ,optional ,source=nil, value=nil, rect={x, y, w, h}, font=nil, color, display, unit, decimal, max}
		[EGTC] = {unit = UNIT_CELSIUS},
		[RPM1] = {unit = UNIT_RPM, max = 300000},
		[THRT] = {unit = UNIT_PERCENT},
		[VBAT] = {display = function(data) if data ~= nil then return ( data / 10 ) else return 10	end end, unit = UNIT_VOLT, decimal = 2},
		[PUMP] = {},
		[FUEL] = {unit = UNIT_MILLILITER},
		[STAT] = {},
		[RPM2] = {unit = UNIT_RPM, max = 10000},
		[TEMP] = {unit = UNIT_CELSIUS},
	}
	
	for appId, sensor in pairs(sensors) do
		sensor.source = system.getSource({category=CATEGORY_TELEMETRY, appId=appId})
		if sensor.source == nil then
			newSensor = model.createSensor()
			newSensor:appId(appId)
			newSensor:physId(0x12)
			newSensor:name(string.format("%x", appId))
			newSensor:maximum(sensor.max)
			--newSensor:unit(sensor.unit)
			--newSensor:decimals(3)
		end
	end
		
	return {
		sensors=sensors,
		fuelWarningCount = 1,
		turbineType = 1,
		colorMask=lcd.RGB(192, 0, 192),
		colorText=lcd.RGB(248, 252, 248),
		tankCapacity = 2000,
		fuelAlarm = 600,
		fileName = nil,
		haptic =  false,
		switchPlay = nil,
		validLayout = false,
	}
end

local function build(widget)

	-- Si Xicoy, pas besoin d'afficher RPM2 / TEMP ( Il faut relancer le widget pour la prose en compte )
	if widget.turbineType == 1 then
		widget.sensors[RPM2].optional = true
		widget.sensors[TEMP].optional = true
	end
	
	local width = system.getVersion().lcdWidth
	local height = system.getVersion().lcdHeight
    local w, h = lcd.getWindowSize()
	
	-- Size for Gauge
	local boxTop = 5
	local boxHeight = h - boxTop - 5
	local boxLeft = 0.75 * w
	local boxWidth = w - boxLeft - 5
	widget.gauge = { boxTop, boxHeight, boxLeft, boxWidth }

	if (width and w) == 800 and (height and h) == 480 then		--X20 series and full screen
		widget.validLayout = true										
	--FONT_BOLD / FONT_ITALIC / FONT_L / FONT_L_BOLD / FONT_S /FONT_S_BOLD /FONT_STD / FONT_XL / FONT_XS / FONT_XS_BOLD / FONT_XXL / FONT_XXS
				--{X, Y, Width, Height}
		widget.sensors[EGTC].rect = {70, 190, 120, 45}
		widget.sensors[RPM1].rect = {70, 125, 240, 45}
		widget.sensors[THRT].rect = {200, 260, 115, 45}
		widget.sensors[VBAT].rect = {385, 190, 100, 45}
		widget.sensors[PUMP].rect = {70, 260, 80, 45}
		widget.sensors[FUEL].rect = {370, 260, 150, 45}
		widget.sensors[STAT].rect = {250, 70, 250, 50}
		widget.sensors[RPM2].rect = {330, 125, 190, 45}
		widget.sensors[TEMP].rect = {210, 190, 100, 45}		
				--{x,y, font}	
		widget.modelName = { 200, 10 , FONT_XXL}			--OK
				--{x, y, name}
		widget.masks = {
			{110, 65, maskTurbine},
			{5, 135, maskRpm},
			{15, 195, maskTemp},	
			{15, 270, maskPump},				
			{330, 195, maskBattery},					
			{160, 270, maskThro},
			{330, 265, maskFuel},
			{110, 380, maskTimer},
			}
			-- widget.sensors[xxxx].font = FONT_XXX si on veut avoir une police différente par sensor
		midFont = FONT_XXL
			--si valable pour la majorité : sensor.font = FONT_XL ou alors : sensor.font = midFont
		for appId, sensor in pairs(widget.sensors) do		
			sensor.font = midFont
		end
			--{x, y, width, height, font)
		widget.timer = { 200, 350, 220, 100, lcd.loadFont("xxxxl.fnt")}
		
	elseif (width and w ) == 480 and (height and h) == 320 then		--X18 series and full screen
		widget.validLayout = true									
	--FONT_BOLD / FONT_ITALIC / FONT_L / FONT_L_BOLD / FONT_S /FONT_S_BOLD /FONT_STD / FONT_XL / FONT_XS / FONT_XS_BOLD / FONT_XXL / FONT_XXS
			--{x, y, width, height}
		widget.sensors[EGTC].rect = {60, 165, 70, 30}
		widget.sensors[RPM1].rect = {60, 115, 140, 30}
		widget.sensors[THRT].rect = {150, 220, 55, 30}
		widget.sensors[VBAT].rect = {265, 165, 60, 30}
		widget.sensors[PUMP].rect = {60, 220, 50, 30}
		widget.sensors[FUEL].rect = {240, 220, 100, 30}
		widget.sensors[STAT].rect = {140, 70, 130, 30}
		widget.sensors[RPM2].rect = {220, 115, 120, 30}
		widget.sensors[TEMP].rect = {160, 165, 60, 30}		
			--{x, y, font}
		widget.modelName = { 150, 10 , FONT_XL}  -- OK
			--{x, y, name}
		widget.masks = {
			{50, 65, maskTurbine},
			{5, 120, maskRpm},
			{15, 165, maskTemp},	
			{15, 220, maskPump},				
			{230, 165, maskBattery},					
			{120, 220, maskThro},
			{205, 215, maskFuel},
			{60, 260, maskTimer},
			}
		-- widget.sensors[xxxx].font = FONT_XXX si on veut avoir une police différente par sensor
		midFont = FONT_XL
		--si valable pour la majorité : sensor.font = FONT_XL ou alors : sensor.font = midFont
		for appId, sensor in pairs(widget.sensors) do		
			sensor.font = midFont
		end
			--{x, y, width, height, font)
		widget.timer = { 130, 260, 130, 50, lcd.loadFont("xxxl.fnt")}

	elseif (width and w ) == 640 and (height and h) == 360 then		--X14 series and full screen
		widget.validLayout = true									
		--FONT_BOLD / FONT_ITALIC / FONT_L / FONT_L_BOLD / FONT_S /FONT_S_BOLD /FONT_STD / FONT_XL / FONT_XS / FONT_XS_BOLD / FONT_XXL / FONT_XXS
			--{x, Y, width, height}
		widget.sensors[EGTC].rect = {60, 170, 100, 40}
		widget.sensors[RPM1].rect = {60, 120, 180, 40}
		widget.sensors[THRT].rect = {170, 230, 80, 40}
		widget.sensors[VBAT].rect = {300, 170, 80, 40}
		widget.sensors[PUMP].rect = {60, 230, 70, 40}
		widget.sensors[FUEL].rect = {300, 230, 130, 40}
		widget.sensors[STAT].rect = {140, 70, 180, 40}
		widget.sensors[RPM2].rect = {280, 120, 150, 40}
		widget.sensors[TEMP].rect = {170, 170, 80, 40}		
			--{x,y, font}
		widget.modelName = { 150, 10 , FONT_XL}
			--{x, y, name}
		widget.masks = {
			{50, 65, maskTurbine},
			{5, 125, maskRpm},
			{15, 175, maskTemp},	
			{15, 235, maskPump},				
			{260, 170, maskBattery},					
			{140, 235, maskThro},
			{260, 235, maskFuel},
			{100, 290, maskTimer},
			}
			-- widget.sensors[xxxx].font = FONT_XXX si on veut avoir une police différente par sensor
		midFont = FONT_XL
			--si valable pour la majorité : sensor.font = FONT_XL ou alors : sensor.font = midFont
		for appId, sensor in pairs(widget.sensors) do		
			sensor.font = midFont
		end
			--{x, y, w, h, font)
		widget.timer = { 160, 280, 160, 70, lcd.loadFont("xxxl.fnt")}
			
	elseif (width and w ) == 480 and (height and h) == 272 then		--X10 / X12 series and full screen
		widget.validLayout = true										
	--FONT_BOLD / FONT_ITALIC / FONT_L / FONT_L_BOLD / FONT_S /FONT_S_BOLD /FONT_STD / FONT_XL / FONT_XS / FONT_XS_BOLD / FONT_XXL / FONT_XXS
			--{X, Y, Width, Height}
		widget.sensors[EGTC].rect = {60, 150, 70, 30}
		widget.sensors[RPM1].rect = {60, 110, 140, 30}
		widget.sensors[THRT].rect = {150, 190, 55, 30}
		widget.sensors[VBAT].rect = {265, 150, 60, 30}
		widget.sensors[PUMP].rect = {60, 190, 50, 30}
		widget.sensors[FUEL].rect = {250, 190, 100, 30}
		widget.sensors[STAT].rect = {135, 70, 130, 30}
		widget.sensors[RPM2].rect = {220, 110, 120, 30}
		widget.sensors[TEMP].rect = {160, 150, 60, 30}		
			--{x,y, font}
		widget.modelName = { 150, 10 , FONT_XL}
			--{x, y, name}
		widget.masks = {
			{50, 55, maskTurbine},
			{5, 115, maskRpm},
			{15, 150, maskTemp},	
			{15, 190, maskPump},				
			{230, 150, maskBattery},					
			{120, 190, maskThro},
			{210, 185, maskFuel},
			{80, 215, maskTimer},
			}
		-- widget.sensors[xxxx].font = FONT_XXX si on veut avoir une police différente par sensor
		midFont = FONT_XL
		--si valable pour la majorité : sensor.font = FONT_XL ou alors : sensor.font = midFont
		for appId, sensor in pairs(widget.sensors) do		
			sensor.font = midFont
		end
		--{x, y, w, h, font) w and h are used for lcd.invalidate
		widget.timer = { 135, 220, 130, 50, lcd.loadFont("xxxl.fnt")}
	else
		widget.validLayout = false
	end	  
end

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
	--[37] = "NO SENSOR"
}	

local function drawStatus(x, y, status)
	local statuString = msg_table_xicoy[status] 
	lcd.drawText(x, y, statuString)
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
		--Monostable pour la lecture de quantité de carburant
local function fuelPlay(widget)
	if widget.switchPlay ~= nil then
		newSwitchState = widget.switchPlay:state()
		if newSwitchState and not previousSwitchState then
    		system.playNumber(fuelRemaining, UNIT_MILLILITER, 0)
		end
		previousSwitchState = newSwitchState
	end
end

local function drawGaugeV(widget)
		--Gauge Background
	lcd.color(WHITE)
	lcd.drawFilledRectangle(widget.gauge[3], widget.gauge[1], widget.gauge[4], widget.gauge[2])
		-- Gauge color
	lcd.color(lcd.RGB(getPercentColor(widget.sensors[FUEL].value, widget.fuelAlarm, widget.tankCapacity)))
		-- Gauge bar
	gaugeHeight = math.floor(((widget.gauge[2]) / 100) * widget.sensors[FUEL].value)
	lcd.drawFilledRectangle(widget.gauge[3], (widget.gauge[2]-gaugeHeight)+5, widget.gauge[4], gaugeHeight)
		-- Gauge frame outline
	lcd.color(BLACK)
	lcd.drawRectangle(widget.gauge[3], widget.gauge[1], widget.gauge[4], widget.gauge[2],2)
end

local function drawTimer(widget)
	local timer = system.getSource({category = CATEGORY_TIMER, member = 0})
	if timer ~= nil then
		local timerSec = timer:value() % 60
		local timerMin = math.floor((timer:value() - timerSec) / 60 )
		lcd.drawText(widget.timer[1], widget.timer[2],string.format("%02d : %02d", timerMin, timerSec ), widget.timer[5])
		--lcd.drawText(widget.timer[1], widget.timer[2],timer:stringValue(), widget.timer[5])
	else
		lcd.drawText(widget.timer[1], widget.timer[2],string.format("%02d : %02d", 0, 0 ), widget.timer[5])
	end
end

local function paint(widget)
	if widget.validLayout == true then
			--ModelName
		lcd.color(widget.colorText)
		lcd.drawText(widget.modelName[1],widget.modelName[2],model.name(),widget.modelName[3])
	
		lcd.color(widget.colorMask)
			-- Turbine logo
		lcd.drawBitmap(5, 5, turbineLogo, 100, 50)
			-- Masks
		for i, mask in ipairs(widget.masks) do
			lcd.drawMask(mask[1], mask[2], mask[3])
		end	
			-- Datas Turbine
		for appId, sensor in pairs(widget.sensors) do
			lcd.font(sensor.font)
			lcd.color(widget.colorText)
			if sensor.source ~= nil and sensor.optional == nil then
				if appId == STAT then
					-- if sensor.value == nil then
					-- 	sensor.value = 37
					-- end
					drawStatus(sensor.rect[1], sensor.rect[2], sensor.value)
				elseif appId == FUEL then
					fuelRemaining = math.floor((sensor.value * widget.tankCapacity ) / 100)
					if (fuelRemaining < widget.fuelAlarm) then
						lcd.color(RED)
					end
					lcd.drawNumber(sensor.rect[1], sensor.rect[2], fuelRemaining, sensor.unit, sensor.decimal)
				else
					lcd.drawNumber(sensor.rect[1], sensor.rect[2], sensor.value, sensor.unit, sensor.decimal)
				end
			end
		end
			-- timer
		drawTimer(widget)	
			-- Fuel Gauge Vertical
		drawGaugeV(widget)
	
	else
		lcd.font(FONT_STD)
		lcd.color(RED)
		lcd.drawText(0,0,localize("layout"))
	end
end

local function wakeup(widget)
	if widget.validLayout == true then	
		for appId, sensor in pairs(widget.sensors) do
			local newValue
			if sensor.source == nil then
				sensor.source = system.getSource({category=CATEGORY_TELEMETRY, appId=appId})
			end
			if sensor.source ~= nil then
				if sensor.display ~= nil then
					newValue = sensor.display(sensor.source:value())
				else		
					newValue = sensor.source:value()
				end
			end
			if sensor.value ~= newValue then
				sensor.value = newValue
				lcd.invalidate(sensor.rect[1], sensor.rect[2], sensor.rect[3], sensor.rect[4])
			end
		--Update fuel Gauge
			lcd.invalidate(widget.gauge[3], widget.gauge[1], widget.gauge[4], widget.gauge[2])
		--Update timer
			lcd.invalidate(widget.timer[1], widget.timer[2], widget.timer[3], widget.timer[4])
		end
		-- check if the switch is Pushed to annouce the Fuel volume
		fuelPlay(widget)
		--Check the fuelLevel and play / haptic if switch on
		if (fuelRemaining < widget.fuelAlarm) and (fuelRemaining ~= 0) then
			if (widget.fuelWarningCount ~= 0) then
				system.playFile(audioPath.."/"..widget.fileName)
				if widget.haptic == true then
					system.playHaptic("- . -") 
				end		
				widget.fuelWarningCount = widget.fuelWarningCount - 1
			end
		end	
		if (fuelRemaining == widget.tankCapacity ) then				-- Réinitialisation du compteur si Reset sans relancer la radio
			widget.fuelWarningCount = 1
		end
	end
end

local function configure(widget)
	-- Xicoy Turbine Type
    line = form.addLine(localize("turbine"))
	local turbineField = form.addChoiceField(line, nil,
		{{"Xicoy", 1},{"Xicoy TP or H", 2}}, 
		function() return widget.turbineType end,
		function(value) widget.turbineType = value
		end)
		-- Colors
	line = form.addLine(localize("colors"))
	local slots = form.getFieldSlots(line,{0,70,"/",70})
	form.addColorField(line, slots[2],
		function() return widget.colorMask end,
		function(colorMask) widget.colorMask = colorMask 
		end)
	form.addStaticText(line, slots[3], "/")
	form.addColorField(line, slots[4], 
		function() return widget.colorText end,
		function(colorText) widget.colorText = colorText
		end)
		-- Fuel Tank capacity
	line = form.addLine(localize("tankCapacity"))
	local tankField = form.addNumberField(line, nil, 0, 9999,
		function() return widget.tankCapacity end,
		function(tankCapacity) widget.tankCapacity = tankCapacity
		end)
	tankField:default(2000)
	tankField:step(50)
	tankField:suffix(" ml")
		-- Fuel Tank low level
	line = form.addLine(localize("fuelAlarm"))
    local alarmField = form.addNumberField(line, nil, 0, widget.tankCapacity,
		function() return widget.sensors[FUEL].alarm end,
		function(newValue) widget.sensors[FUEL].alarm = newValue
		end)
	alarmField:default(600)
	alarmField:step(50)
	alarmField:suffix(" ml")
		-- File audio low level
	line = form.addLine(localize("fileAlarm"))
	local fileField = form.addFileField(line, nil, audioPath, "audio +ext",  
		function() return widget.fileName end, 
		function(newValue) widget.fileName = newValue
		end)
		-- Alarm Haptic
	line = form.addLine(localize("haptic"))
    local hapticField = form.addBooleanField(line, nil,
		function() return widget.haptic end,
        function(haptic) widget.haptic = haptic
        end)	
    	-- Source Play fuel value
    line = form.addLine(localize("switchPlay"))
    form.addSwitchField(line, nil, 
		function() return widget.switchPlay end,
		function(switchPlay) widget.switchPlay = switchPlay
		end)
end

local function read(widget)
	widget.colorMask = storage.read("colorMask")
	widget.colorText = storage.read("colorText")
	widget.tankCapacity = storage.read("tankCapacity") or 2000
	widget.fuelAlarm = storage.read("fuelAlarm") or 600
	widget.fileName = storage.read("fileName")
	widget.haptic = storage.read("haptic")
	widget.switchPlay = storage.read("switchPlay")
	widget.turbineType = storage.read("turbine") or 1
end

local function write(widget)
	storage.write("colorMask", widget.colorMask)
	storage.write("colorText", widget.colorText)
	storage.write("tankCapacity", widget.tankCapacity)
	storage.write("fuelAlarm", widget.fuelAlarm)
	storage.write("fileName", widget.fileName)
	storage.write("haptic", widget.haptic)
	storage.write("switchPlay", widget.switchPlay)
	storage.write("turbine", widget.turbineType) 
end

local function init()
	turbineLogo = lcd.loadBitmap(bitmapsPath.."xicoy.png")
	maskTurbine = lcd.loadMask(bitmapsPath.."turbine.png")
	maskBattery = lcd.loadMask(bitmapsPath.."battery.png")
	maskTemp = lcd.loadMask(bitmapsPath.."temp.png")
	maskRpm = lcd.loadMask(bitmapsPath.."rpm.png")
	maskPump = lcd.loadMask(bitmapsPath.."pump.png")
	maskThro = lcd.loadMask(bitmapsPath.."thro.png")
	maskFuel = lcd.loadMask(bitmapsPath.."fuel.png")
	maskTimer = lcd.loadMask(bitmapsPath.."timer.png")
	system.registerWidget({key="xicoy", name=name, create=create,  title=false, build=build, paint=paint, configure=configure, wakeup=wakeup, menu=menu, read=read, write=write})

end

return {init=init}