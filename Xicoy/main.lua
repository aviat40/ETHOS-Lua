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
local imagePath = "/scripts/Xicoy/bitmaps/"
local version = "1.1"

local locale = system.getLocale()

local mask_turbine, mask_battery, mask_temp, mask_rpm, mask_pump, mask_thro, turbine_logo, mask_fuel

local fuel_remaining, percent
local flag_haptic, switch

local translations = {en="Xicoy", fr="Xicoy", de="Xicoy", es="Xicoy"}
local text1 = {en="Mask/Text Colors", fr="Couleurs Icone/Texte", de="Hintergrund/Text Farbe", es="text1_es"}
local text5 = {en="Wrong screen size", fr="Taille écran incompatible", de="Falsche Bildschirm", es="test5_es"}
local text6 = {en="Tank capacity(ml)", fr="Capacité réservoir(ml)", de="Tank Inhalt(ml)", es="text6_es"}
local text7 = {en="Fuel warning(ml)", fr="Alerte carburant(ml)", de="Kraftstoff Warnung", es="text7_es"}
local text9 = {en="Low Fuel Haptic", fr="Vibreur alerte carburant", de="text9_de", es="text9_es"}
local text10 = {en="Fuel announce switch", fr="Inter lecture carburant", de="text10_de", es="text10_es"}


local common = {color_mask=lcd.RGB(192, 0, 192),
				color_text=lcd.RGB(248, 252, 248),
				tank_capacity = 2000,
				fuel_alarm = 600,
				haptic = false,
				switch_play = nil,
				}
 
local function name(widget)
    return translations[locale] or tranlations["en"]
end

local function menu(widget)
	return{{"Xicoy v"..version, function() end}}
end

local function create()
	flag_haptic = false
	switch = false
	
	return {
			value_VBAT=nil, value_EGTC=nil, value_RPM1=nil, value_PUMP=nil, value_THRT=nil, 
			value_RPM2=nil, value_TEMP=nil, value_STAT=nil, value_FUEL=nil,
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
		[37] = "No Sensor"
	}	
	status_str = msg_table_xicoy[tonumber(status)]
   
	lcd.drawText(x, y, status_str, CENTERED)
	
end

local function getPercentColor(percent_col, fuel, tank)
    if percent_col < (math.floor((fuel / tank)*100)) then
        return 0xFF, 0, 0
    else
       g = math.floor(0xDF * percent_col / 100)
       r = 0xDF - g
       return r, g, 0
    end
end

local function play(widget)
	if common.switch_play ~= nil then
		if (common.switch_play:state() ~= switch) and (common.switch_play:state() == true) then
			system.playNumber(fuel_remaining, UNIT_MILLILITER, 0)
		end
		switch = common.switch_play:state()
	end
end


local function drawGaugeV(widget)
	
	box_top = 5
	box_height = h - box_top - 5
	box_left = 310
	box_width = w - box_left - 5
		
			--Gauge Background
	lcd.color(WHITE)
	lcd.drawFilledRectangle(box_left, box_top, box_width, box_height)
			-- Gauge color
	lcd.color(lcd.RGB(getPercentColor(percent, common.fuel_alarm, common.tank_capacity)))
			-- Gauge bar
	gauge_height = math.floor(((box_height) / 100) * percent)
	lcd.drawFilledRectangle(box_left, (box_height-gauge_height)+5, box_width, gauge_height)
			-- Gauge frame outline
	lcd.color(BLACK)
	lcd.drawRectangle(box_left, box_top, box_width, box_height,2)
			-- Gauge percentage
	lcd.font(FONT_XS)
	if (percent > 5) then
		lcd.drawText(box_left + box_width / 2, box_height - gauge_height + 5, math.floor(percent).."%", CENTERED)
	else
		lcd.font(FONT_XS_BOLD)
		lcd.color(RED)
		lcd.drawText(box_left + box_width / 2, box_top + box_height / 2 , "FUEL", CENTERED)
	end
	
	
	if (fuel_remaining < common.fuel_alarm) and (common.haptic == true) and (flag_haptic == false) then
		system.playHaptic("- . -") 
		flag_haptic = true
	end	
end

local function drawGaugeH(widget)
	
	box_top = 40
	box_height = h - box_top - 5
	box_left = 5
	box_width = w - box_left - 5
		
			--Gauge Background
	lcd.color(WHITE)
	lcd.drawFilledRectangle(box_left, box_top, box_width, box_height)
			-- Gauge color
	lcd.color(lcd.RGB(getPercentColor(percent, common.fuel_alarm, common.tank_capacity)))
			-- Gauge bar
	gauge_width = math.floor(((box_width) / 100) * percent)
	lcd.drawFilledRectangle(box_left, box_top, gauge_width , box_height)
			-- Gauge frame outline
	lcd.color(BLACK)
	lcd.drawRectangle(box_left, box_top, box_width, box_height,2)
			-- Gauge percentage
	lcd.font(FONT_L)
	if (percent > 5) then
		lcd.drawText((box_left + box_width) / 2, box_top + (box_height/2) -10, math.floor(percent).."%", CENTERED)
	else
		lcd.font(FONT_L_BOLD)
		lcd.color(RED)
		lcd.drawText((box_left + box_width) / 2, box_top + (box_height/2) -10 , "FUEL", CENTERED)
	end
	
	
	if (fuel_remaining < common.fuel_alarm) and (common.haptic == true) and (flag_haptic == false) then
		system.playHaptic("- . -") 
		flag_haptic = true
	end	
end

local function paint(widget)
	
	w, h = lcd.getWindowSize()
	lcd.color(common.color_text)
	if (w == 388) and (h == 316) then
		-- Mask
		lcd.color(common.color_mask)
		lcd.drawBitmap(120, 2, turbine_logo, 100, 50)
		lcd.drawMask(5, 5, mask_turbine)
		lcd.drawMask(5, 260, mask_battery)
		lcd.drawMask(15, 160, mask_temp)
		lcd.drawMask(5, 120, mask_rpm)
		lcd.drawMask(5, 210, mask_pump)
		lcd.drawMask(150, 205, mask_thro)
		lcd.drawMask(140, 260, mask_fuel)

		-- Datas Turbine
		lcd.color(common.color_text)
		lcd.font(FONT_L)
		
		if widget.value_RPM1 ~= nil then
			lcd.drawText(80, 115, widget.value_RPM1, LEFT)
		else 
			lcd.drawText(80, 115, "...")
		end
		
		if widget.value_EGTC ~= nil then
			lcd.drawText(80, 160, widget.value_EGTC, LEFT)
		else 
			lcd.drawText(80, 160, "...")
		end
		
		if widget.value_PUMP ~= nil then
			lcd.drawText(60, 205, widget.value_PUMP, LEFT)
		else
			lcd.drawText(60, 205, "...")
		end
		
		if widget.value_THRT ~= nil then
			lcd.drawText(185, 205,widget.value_THRT.."%",LEFT)
		else
			lcd.drawText(185, 205, "..")
		end

		
		if widget.value_VBAT ~= nil then
			lcd.font(FONT_L_BOLD)
			lcd.drawNumber(50, 265, (tonumber(widget.value_VBAT)/10),UNIT_VOLT,1,LEFT)
		else
			lcd.font(FONT_L)
			lcd.drawText(50, 265, "..")
		end
				
		-- Second Shaft Datas Turbine
		if (widget.value_RPM2 ~= nil) then
			lcd.font(FONT_L)
			lcd.drawText(170, 115, " / "..widget.value_RPM2, LEFT)
			lcd.drawText(150, 160, " / "..widget.value_TEMP, LEFT)
		else
			lcd.font(FONT_L)
			lcd.drawText(170, 115, " / ".."...", LEFT)
			lcd.drawText(150, 160, " / ".."..", LEFT)
		end	
		
		-- Turbine Status
		lcd.font(FONT_L_BOLD)
		drawStatus( 130, 80, widget.value_STAT)
		
		-- Fuel Quantity
		if (widget.value_FUEL ~= "0") then
			if (fuel_remaining < common.fuel_alarm) then
				lcd.color(RED)
			end
			lcd.font(FONT_XL)
			lcd.drawNumber(190,260, fuel_remaining,UNIT_MILLILITER)
		else 
			lcd.drawText(190,260,"....")
		end
		-- Fuel Gauge Vertical
		drawGaugeV(widget)
	elseif (w == 300) and (h == 88) then
		-- Fuel Quantity
		if (widget.value_FUEL ~= "0") then
			if (fuel_remaining < common.fuel_alarm) then
				lcd.color(RED)
			end
			lcd.font(FONT_XL)
			lcd.drawNumber(w/2,0, fuel_remaining,UNIT_MILLILITER,0, CENTERED)
		else
			lcd.drawText(w/2,0,"....")
		end
		-- Fuel Gauge Horizontal
		drawGaugeH(widget)
	else
		lcd.font(FONT_STD)
		lcd.drawText(w/2, h/2, text5[locale] or text5["en"], CENTERED)
	end
end

local function wakeup(widget)	
	
	local sensor_EGTC = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4400})
	local sensor_RPM1 = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4401})	
	local sensor_THRT = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4402})
	local sensor_VBAT = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4403})
	local sensor_PUMP = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4404})
	local sensor_FUEL = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4405})
	local sensor_STAT = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4406})
	local sensor_RPM2 = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4414})
	local sensor_TEMP = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4415})
	
	local newValue_VBAT = nil
	local newValue_EGTC = nil
	local newValue_RPM1 = nil
	local newValue_PUMP = nil
	local newValue_THRT = nil
	local newValue_RPM2 = nil
	local newValue_TEMP = nil
	local newValue_STAT = nil
	local newValue_FUEL = nil
		
	-- VBAT Turbine
	--widget.value_VBAT = "82"			--Use for simulator	
	if sensor_VBAT ~= nil then
		newValue_VBAT = sensor_VBAT:stringValue()
	end
    if widget.value_VBAT ~= newValue_VBAT then
		widget.value_VBAT = newValue_VBAT
    end
	
	-- EGTC Turbine	
	if sensor_EGTC ~= nil then
		newValue_EGTC = sensor_EGTC:stringValue()
	end
    if widget.value_EGTC ~= newValue_EGTC then
		widget.value_EGTC = newValue_EGTC
    end
	-- RPM1 Turbine
	if sensor_RPM1 ~= nil then
		newValue_RPM1 = sensor_RPM1:stringValue()
	end
    if widget.value_RPM1 ~= newValue_RPM1 then
		widget.value_RPM1 = newValue_RPM1
    end
	-- PUMP Turbine
	if sensor_PUMP ~= nil then
		newValue_PUMP = sensor_PUMP:stringValue()
	end
    if widget.value_PUMP ~= newValue_PUMP then
		widget.value_PUMP = newValue_PUMP
    end
	-- THRT Turbine
	if sensor_THRT ~= nil then
		newValue_THRT = sensor_THRT:stringValue()
	end
    if widget.value_THRT ~= newValue_THRT then
		widget.value_THRT = newValue_THRT
    end
	-- RPM2 Second Shaft
	if sensor_RPM2 ~= nil then
		newValue_RPM2 = sensor_RPM2:stringValue()
	end
    if widget.value_RPM2 ~= newValue_RPM2 then
		widget.value_RPM2 = newValue_RPM2
    end
	-- TEMP Second Shaft
	if sensor_TEMP ~= nil then
		newValue_TEMP = sensor_TEMP:stringValue()
	end
    if widget.value_TEMP ~= newValue_TEMP then
		widget.value_TEMP = newValue_TEMP
    end
	-- Turbine Status
	if sensor_STAT == nil then
		widget.value_STAT = "37"					--Sensor Not detected
	else newValue_STAT = sensor_STAT:stringValue()
		if newValue_STAT == "0" then				--Sensor detected but no value
			widget.value_STAT = "36"
		elseif widget.value_STAT ~= newValue_STAT then
			widget.value_STAT = newValue_STAT
		end
	end

	-- Fuel
	if sensor_FUEL == nil then
		widget.value_FUEL = "0"
	else newValue_FUEL = sensor_FUEL:stringValue()
		if newValue_FUEL == "0" then
			widget.value_FUEL = "100"
		elseif widget.value_FUEL ~= newValue_FUEL then
			widget.value_FUEL = newValue_FUEL
		end
	end

	percent = tonumber(widget.value_FUEL)
	fuel_remaining = math.floor((percent * common.tank_capacity ) / 100)
	lcd.invalidate()
	play(widget)
	
end

local function configure(widget)
	-- Colors
	line = form.addLine(text1[locale] or text1["en"])
	local slots = form.getFieldSlots(line,{0,70,"/",70})
	form.addColorField(line, slots[2],
		function() return common.color_mask end,
		function(color_mask) common.color_mask = color_mask 
		end)
	form.addStaticText(line, slots[3], "/")
	form.addColorField(line, slots[4], 
		function() return common.color_text end,
		function(color_text) common.color_text = color_text
		end)
	-- Fuel Tank capacity
	line = form.addLine(text6[locale] or text6["en"])
	local tankField = form.addNumberField(line, nil, 0, 9999,
		function() return common.tank_capacity end,
		function(tank_capacity) common.tank_capacity = tank_capacity
		end)
	tankField:default(2000)
	tankField:step(50)
	-- Fuel Tank low level
	line = form.addLine(text7[locale] or text7["en"])
    local alarmField = form.addNumberField(line, nil, 0, common.tank_capacity,
		function() return common.fuel_alarm end,
		function(fuel_alarm) common.fuel_alarm = fuel_alarm
		end)
	alarmField:default(600)
	alarmField:step(50)
	-- Alarm Haptic
	line = form.addLine(text9[locale] or text9["en"])
    local hapticField = form.addBooleanField(line, nil,
		function() return common.haptic end,
        function(haptic) common.haptic = haptic
        end)	
    -- Source Play Number
    line = form.addLine(text10[locale] or text10["en"])
    form.addSwitchField(line, nil, 
		function() return common.switch_play end,
		function(switch_play) common.switch_play = switch_play
		end)
end

local function read(widget)
	common.color_mask = storage.read("color_mask")
	common.color_text = storage.read("color_text")
	common.tank_capacity = storage.read("tank_capacity")
	common.fuel_alarm = storage.read("fuel_alarm")
	common.haptic = storage.read("haptic")
	common.switch_play = storage.read("switch_play")
end

local function write(widget)
	storage.write("color_mask", common.color_mask)
	storage.write("color_text", common.color_text)
	storage.write("tank_capacity", common.tank_capacity)
	storage.write("fuel_alarm", common.fuel_alarm)
	storage.write("haptic", common.haptic)
	storage.write("switch_play", common.switch_play)
end

local function init()
	mask_turbine = lcd.loadMask(imagePath.."mask_turbine.png")
	mask_battery = lcd.loadMask(imagePath.."mask_battery.png")
	mask_temp = lcd.loadMask(imagePath.."mask_temp.png")
	mask_rpm = lcd.loadMask(imagePath.."mask_rpm.png")
	mask_pump = lcd.loadMask(imagePath.."mask_pump.png")
	mask_thro = lcd.loadMask(imagePath.."mask_thro.png")
	mask_fuel = lcd.loadMask(imagePath.."mask_fuel.png")
	turbine_logo = lcd.loadBitmap(imagePath.."logo1.png")
	system.registerWidget({key="xicoy", name=name, create=create, title=false, paint=paint, configure=configure, wakeup=wakeup, menu=menu, read=read, write=write})
end

return {init=init}