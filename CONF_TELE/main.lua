-- ##################################################################################
-- #																				#
-- # This Lua is used for ETHOS 1.6.x to set the Full capacity and the Fuel Factor	#
-- # within the JETMUNTS TELEMETRY sensor											#
-- # 																				#
-- # Check the device configuration / DIY and change the values when the sensor     #
-- # is connected																	#
-- #																				#
-- ##################################################################################


local LUA_VERSION = "1.0";
local locale = system.getLocale()


local localeTexts = {
	widgetName = {en="Module Conf.", fr="Config. Module", de="De", es="es"},
	tankCapacity = {en="Tank capacity", fr="Volume réservoir", de="Tank Inhalt", es="es"},
	fuelFactor = {en="FuelFactor", fr="Facteur Correction", de= "De", es="es"},
	}
	
local function localize(key)
	return localeTexts[key][locale] or localTexts[key]["en"] or key
end

local tankCapacity
local newValueTank
local fuelFactor
local newValueFF

local function name(widget)
  return localize("widgetName")
end

local function create(widget)
	local sensorTank = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4410})
	tankCapacity = sensorTank:value()
	newValueTank = sensorTank:value()
	
	local sensorFF = {}
	local sensorFF = system.getSource({category=CATEGORY_TELEMETRY, appId=0x4411})
	fuelFactor = sensorFF:value()
	newValueFF = sensorFF:value()

  	-- Fuel Tank capacity
	local line = form.addLine(localize("tankCapacity"))
	local tankField = form.addNumberField(line, nil, 0 , 9999,
		function() return tankCapacity end,
		function(value) tankCapacity=value
		end)
	tankField:default(2000)
	tankField:step(50)
	tankField:suffix(" ml")
	
	-- Pulses Config
	local line = form.addLine(localize("fuelFactor"))
	local FFField = form.addNumberField(line, nil, 0 , 9999,
		function() return fuelFactor end,
		function(value) fuelFactor=value
		end)
	FFField:default(400)
	FFField:step(1)

	return {}
end

local function wakeup(widget)
	if newValueTank ~= tankCapacity then
		local sensorTank={}
		sensorTank = sport.getSensor({appId = 0x4410})
		sensorTank:pushFrame({physId=0x1B, primId=0x31, appId=0x4410, value=tankCapacity})
		newValueTank = tankCapacity
	end
	
	if newValueFF ~= fuelFactor then
		local sensorFF={}
		sensorFF = sport.getSensor({appId = 0x4411})
		sensorFF:pushFrame({physId=0x1B, primId=0x31, appId=0x4411, value=fuelFactor})
		newValueFF = fuelFactor
	end

end

local icon = lcd.loadBitmap("telemetry.png");

local function init()
  if system.registerDeviceConfig then
   system.registerDeviceConfig({category = DEVICE_CATEGORY_DIY, name = name, bitmap = icon, version = LUA_VERSION, pages = { {name = name, create = create, wakeup = wakeup} }})
  else
    ssystem.registerSystemTool({name=name, icon=icon, create=create, wakeup=wakeup})
  end
end


return {init=init}
