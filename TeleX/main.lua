-- ##########################################################################################################
-- #                                                                                                        #
-- # Turbine lua for ETHOS V1.1.0 or above                                                                  #
-- #                                                                                                        #
-- # Turbine widget TeleX Xicoy telemetry module for FrSky	         			                            #
-- #                                                                                                        #
-- # hobby-rc.freeboxos.fr (2022)                                                                           #
-- #                                                                                                        #
-- ##########################################################################################################

-- Path to pictures on SD-CARD
local imagePath = "/scripts/Telex/bitmaps/"

local locale = system.getLocale()

local mask_turbine, mask_battery, mask_temp, mask_rpm, mask_pump, mask_thro, turbine_logo, mask_fuel

local fuel_remaining, percent
local flag_haptic, switch

local translations = {en="TeleX Lua", fr="Lua TeleX", de="TeleX Lua", es="Spain"}
local text1 = {en="Mask/Text Colors", fr="Couleurs Icone/Texte", de="Hintergrund/Text Farbe", es="text1_es"}
local text4 = {en="Remove Title Bar", fr="Supprimer le titre", de="Titel deaktivieren", es="text4_es"}
local text5 = {en="Wrong screen size", fr="Taille widget incompatible", de="Falsche Bildschirm", es="test5_es"}
local text6 = {en="Tank capacity(ml)", fr="Capacité réservoir(ml)", de="Tank Inhalt(ml)", es="text6_es"}
local text7 = {en="Fuel warning(ml)", fr="Alerte carburant(ml)", de="Kraftstoff Warnung", es="text7_es"}
local text9 = {en="Low Fuel Haptic", fr="Vibreur alerte carburant", de="text9_de", es="text9_es"}
local text10 = {en="Fuel announce switch", fr="Inter lecture carburant", de="text10_de", es="text10_es"}

local common_data = {}

local function name(widget)
    return translations[locale] or tranlations["en"]
end

local function create()
	flag_haptic = false
	switch = false
	
	return {color_mask=lcd.RGB(0, 0, 255),
			color_text=lcd.RGB(0, 0, 255),
			value_VBAT=nil, value_EGTC=nil, value_RPM1=nil, value_PUMP=nil, value_THRT=nil, value_RPM2=nil, value_TEMP=nil, value_STAT=nil, value_FUEL=nil,
			tank_capacity=2000, fuel_alarm=500,
			haptic=false, switch_play,
			common_data = common_data,
			}
end

function draw_status(x, y, status)
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
	}	
	status_str = msg_table_xicoy[tonumber(status)]
   
	lcd.drawText(x, y, status_str, CENTERED)
	
end

local function getPercentColor(percent_col, fuel_alarm, tank_capacity)
    if percent_col < (math.floor((fuel_alarm / tank_capacity)*100)) then
        return 0xFF, 0, 0
    else
       g = math.floor(0xDF * percent_col / 100)
       r = 0xDF - g
       return r, g, 0
    end
end

local function play(widget)
	if widget.common_data.switch_play ~= nil then
		if (widget.common_data.switch_play:state() ~= switch) and (widget.common_data.switch_play:state() == true) then
			system.playNumber(fuel_remaining, UNIT_MILLILITER, 0)
		end
		switch = widget.common_data.switch_play:state()
	end
end


local function drawgauge_v(widget)
	
	box_top = 5
	box_height = h - box_top - 5
	box_left = 310
	box_width = w - box_left - 5
		
			--Gauge Background
	lcd.color(WHITE)
	lcd.drawFilledRectangle(box_left, box_top, box_width, box_height)
			-- Gauge color
	lcd.color(lcd.RGB(getPercentColor(percent, widget.common_data.fuel_alarm, widget.common_data.tank_capacity)))
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
	
	
	if (fuel_remaining < widget.common_data.fuel_alarm) and (widget.common_data.haptic == true) and (flag_haptic == false) then
		system.playHaptic("- . -") 
		flag_haptic = true
	end	
end

local function drawgauge_h(widget)
	
	box_top = 40
	box_height = h - box_top - 5
	box_left = 5
	box_width = w - box_left - 5
		
			--Gauge Background
	lcd.color(WHITE)
	lcd.drawFilledRectangle(box_left, box_top, box_width, box_height)
			-- Gauge color
	lcd.color(lcd.RGB(getPercentColor(percent, widget.common_data.fuel_alarm, widget.common_data.tank_capacity)))
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
	
	
	if (fuel_remaining < widget.common_data.fuel_alarm) and (widget.common_data.haptic == true) and (flag_haptic == false) then
		system.playHaptic("- . -") 
		flag_haptic = true
	end	
end

local function paint(widget)
	
	w, h = lcd.getWindowSize()
	lcd.color(widget.common_data.color_text)
	
	if (w == 388) and (h == 316) then
	
		turbine_logo = lcd.loadBitmap(imagePath.."logo1.png")
		-- Mask
		lcd.color(widget.common_data.color_mask)
		lcd.drawBitmap(120, 2, turbine_logo, 100, 50)
		lcd.drawMask(5, 5, mask_turbine)
		lcd.drawMask(5, 260, mask_battery)
		lcd.drawMask(15, 160, mask_temp)
		lcd.drawMask(5, 120, mask_rpm)
		lcd.drawMask(5, 210, mask_pump)
		lcd.drawMask(150, 205, mask_thro)
		lcd.drawMask(140, 260, mask_fuel)

		-- Datas Turbine	
		lcd.font(FONT_L)
		
		if widget.value_RPM1 ~= nil then
			lcd.drawText(80, 115, widget.value_RPM1, LEFT)
		end
		if widget.value_EGTC ~= nil then
			lcd.drawText(80, 160, widget.value_EGTC, LEFT)
		end
		
		if widget.value_PUMP ~= nil then
			lcd.drawText(60, 205, widget.value_PUMP, LEFT)
		end
		
		if widget.value_THRT ~= nil then
			lcd.drawText(185,205,widget.value_THRT.."%",LEFT)
		end

		lcd.font(FONT_L_BOLD)
		if widget.value_VBAT ~= nil then
			lcd.drawNumber(50, 265, (tonumber(widget.value_VBAT)/10),UNIT_VOLT,1,LEFT)
		end
				
		-- Second Shaft Datas Turbine
		if (widget.value_RPM2 ~= nil) then
			lcd.font(FONT_L)
			lcd.drawText(170, 115, " / "..widget.value_RPM2, LEFT)
			lcd.drawText(150, 160, " / "..widget.value_TEMP, LEFT)
		end	
		
		-- Turbine Status
		lcd.font(FONT_L_BOLD)
		draw_status( 130, 80, widget.value_STAT)
		-- Fuel Quantity
		if (fuel_remaining < widget.common_data.fuel_alarm) then
			lcd.color(RED)
		end
		lcd.font(FONT_XL)
		lcd.drawNumber(190,260, fuel_remaining,UNIT_MILLILITER)
		-- Fuel Gauge
		drawgauge_v(widget)
	
	elseif (w == 300) and (h == 88) then
		-- Fuel Quantity
		if (fuel_remaining < widget.common_data.fuel_alarm) then
			lcd.color(RED)
		end
		lcd.font(FONT_XL)
		lcd.drawNumber(w/2,0, fuel_remaining,UNIT_MILLILITER,0, CENTERED)
		drawgauge_h(widget)
	
	elseif (w == 388) and ( h == 294 ) then			-- thickness of title bar = 22 (280-22)=258
		lcd.font(FONT_STD)
		lcd.drawText(w/2, h/2, text4[locale] or text4["en"], CENTERED)
	else
		lcd.font(FONT_STD)
		lcd.drawText(w/2, h/2, text5[locale] or text5["en"], CENTERED)
	end
end


local function wakeup(widget)	
	
	sensor_EGTC = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4400})
	sensor_RPM1 = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4401})	
	sensor_THRT = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4402})
	sensor_VBAT = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4403})
	sensor_PUMP = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4404})
	sensor_FUEL = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4405})
	sensor_STAT = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4406})
	sensor_RPM2 = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4414})
	sensor_TEMP = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4415})
	
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
	if sensor_STAT ~= nil then
		newValue_STAT = sensor_STAT:stringValue()
		if newValue_STAT == "0" then
			widget.value_STAT = "36"
		elseif widget.value_STAT ~= newValue_STAT then
			widget.value_STAT = newValue_STAT
		end
	end
	-- Fuel
	if sensor_FUEL ~= nil then
		newValue_FUEL = sensor_FUEL:stringValue()
		if newValue_FUEL == "0" then
			widget.value_FUEL = "100"
		elseif widget.value_FUEL ~= newValue_FUEL then
			widget.value_FUEL = newValue_FUEL
		end
	end
	
	percent = tonumber(widget.value_FUEL)
	fuel_remaining = math.floor((percent * widget.common_data.tank_capacity ) / 100)
	lcd.invalidate()
	play(widget)
	
end

local function configure(widget)
	-- Colors
	line = form.addLine(text1[locale] or text1["en"])
	local slots = form.getFieldSlots(line,{0,70,"/",70})
	form.addColorField(line, slots[2],
		function() return widget.common_data.color_mask end,
		function(color_mask) widget.common_data.color_mask = color_mask 
		end)
	form.addStaticText(line, slots[3], "/")
	form.addColorField(line, slots[4], 
		function() return widget.common_data.color_text end,
		function(color_text) widget.common_data.color_text = color_text
		end)
	-- Fuel Tank capacity
	line = form.addLine(text6[locale] or text6["en"])
	form.addNumberField(line, nil, 0, 9999,
		function() return widget.common_data.tank_capacity end,
		function(value) widget.common_data.tank_capacity = value
		end);
	-- Fuel Tank low level
	line = form.addLine(text7[locale] or text7["en"])
    form.addNumberField(line, nil, 0, widget.common_data.tank_capacity,
		function() return widget.common_data.fuel_alarm end,
		function(value) widget.common_data.fuel_alarm = value
		end)	
	-- Alarm Haptic
	line = form.addLine(text9[locale] or text9["en"])
    local field_haptic = form.addBooleanField(line, nil,
		function() return widget.common_data.haptic end,
        function(value) widget.common_data.haptic = value
        end)	
    -- Source Play Number
    line = form.addLine(text10[locale] or text10["en"])
    form.addSwitchField(line, nil, 
		function() return widget.common_data.switch_play end,
		function(name) widget.common_data.switch_play = name
		end)
end

local function read(widget)
	widget.common_data.color_mask = storage.read("color_mask")
	widget.common_data.color_text = storage.read("color_text")
	widget.common_data.tank_capacity = storage.read("tank_capacity")
	widget.common_data.fuel_alarm = storage.read("fuel_alarm")
	widget.common_data.haptic = storage.read("haptic")
	widget.common_data.switch_play = storage.read("switch_play")
end

local function write(widget)
	storage.write("color_mask", widget.common_data.color_mask)
	storage.write("color_text", widget.common_data.color_text)
	storage.write("tank_capacity", widget.common_data.tank_capacity)
	storage.write("fuel_alarm", widget.common_data.fuel_alarm)
	storage.write("haptic", widget.common_data.haptic)
	storage.write("switch_play", widget.common_data.switch_play)
end

local function init()
	mask_turbine = lcd.loadMask(imagePath.."mask_turbine.png")
	mask_battery = lcd.loadMask(imagePath.."mask_battery.png")
	mask_temp = lcd.loadMask(imagePath.."mask_temp.png")
	mask_rpm = lcd.loadMask(imagePath.."mask_rpm.png")
	mask_pump = lcd.loadMask(imagePath.."mask_pump.png")
	mask_thro = lcd.loadMask(imagePath.."mask_thro.png")
	mask_fuel = lcd.loadMask(imagePath.."mask_fuel.png")
	system.registerWidget({key="telex", name=name, create=create, paint=paint, configure=configure, wakeup=wakeup, read=read, write=write})
end

return {init=init}