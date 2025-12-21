 -- ##########################################################################################################
-- #                                                                                                        #
-- # FLVSS / MLVSS lua for ETHOS V1.5.12 or above 															#
-- #																										#
-- # IMPORTANT! Update the MLVSS sensor to the latest firmware from frsky-rc.com web page before use        #
-- #                                                                                                        #
-- # hobby-rc.freeboxos.fr (2022)                                                                           #
-- #                                                                                                        #
-- ##########################################################################################################

local version = "1.2"

local function name(widget)
    return "FLVSS"
end

local function menu(widget)
	return{{"FLVSS v"..version, function() end}}
end

local locale = system.getLocale()

local w,h, checkTelemetry

local localeTexts = {
	cells = {en=" Cells", fr=" Eléments", de=" Zellen", es=" Es", no=" Celle(r)", nl=" Cel(len)"},
	noSensor = {en="No Sensor configured", fr="Pas de capteur configuré", de=" kein Sensor", es=" Es", no="Ingen Sensor", nl="Geen Sensor"},
	noData = {en="No Data received", fr="En attente télémétrie", de=" kein Data", es=" Es", no="Ingen Sensor", nl="Geen Sensor"},
	textColor = {en="Text Color", fr="Couleur Texte", de="Text Farbe", es=" Es", no="Tekstfarge", nl="Tekstkleur"},
	Name = {en="Lipo Sensor", fr="Capteur Lipo", de="Lipo Sensor", es=" Es", no="LiPo-sensor", nl="Lipo Sensor"},
	layout = {en="Use FULLSCREEN layout", fr="Sélectionner PLEIN ECRAN", de =" Texte", es =" Text"}
	}

local function localize(key)
	return localeTexts[key][locale] or localTexts[key]["en"] or key
end

local function create()

	local widget = {
			colorText = colorText,
			source = source,
			sensor = sensor,
			validLayout = false,
			value = value,
			}
	
	return widget
end

local function build(widget)

	widget.sensor = system.getSource(widget.source:name())
	
	local width = system.getVersion().lcdWidth
	local height = system.getVersion().lcdHeight
	w, h = lcd.getWindowSize()
		
		--{xLipo,yLipo,rLipo,thickLipo,xCell,yCell,rCell,thickCell,Cell ,DxCell,DyCell,Width,Height,fontNbCell,fontLipo ,fontCell,xName,yName,xLipoV,yLipoV,xNbCell,yNbCell,}

	if (width and w) == 800 and (height and h) == 480 then			--X20 series et mode plein écran
		widget.validLayout = true
		widget.screen = {150, h/2, 60, 35, 370, 130, 50, 15, true, 150, 200, 800, 480, FONT_STD, FONT_XXL, FONT_XL, 10, 440, 90, 350, 100, 440}
		
	elseif (width and w ) == 480 and (height and h) == 320 then		--X18 series et mode plein écran
		widget.validLayout = true	
		widget.screen = {100, h/2, 45, 25, 250, 100, 25, 10, true, 80, 120, 480, 320, FONT_STD, FONT_XXL, FONT_STD, 10, 300, 50, 250, 50, 300}
		
	elseif (width and w ) == 640 and (height and h) == 360 then		--X14 series et mode plein écran
		widget.validLayout = true
		widget.screen = {100, h/2, 45, 25, 280, 100, 40, 14, true, 120, 120, 640, 360, FONT_STD, FONT_XL, FONT_STD, 10, 330, 50, 270, 60, 330}

	elseif (width and w ) == 480 and (height and h) == 372 then		--X10 / X12 series et mode plein écran
		widget.validLayout = true
		-- widget.screen = {150, h/2, 60, 35, 370, 130, 50, 15, true, 150, 200, 480, 372, FONT_STD, FONT_XXL, FONT_XL, 10, 440, 90, 350, 100, 440}

	else
		widget.validLayout = false
	end	  
end	

------------------------------------------------------------------------------------------
-- Calcul du pourcentage de la batterie en fonction de la tension et du nombre d'Eléments
------------------------------------------------------------------------------------------
local function getPercentLipo(lipoVoltage,nbCells)
	-- Table de % en fonction de 420 - 300 soit 120 valeurs à définir
	local array = {0,0,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5,5,5,6,6,6,6,6,6,7,7,7,7,7,7,8,8,8,8,8,8,9,9,9,9,9,9,10,11,12,13,14,15,16,17,18,19,20,22,24,26,28,30,32,35,38,40,42,45,48,50,52,55,58,60,62,64,66,68,70,72,74,76,78,80,81,82,83,84,85,85,86,86,87,88,89,89,90,91,92,93,94,95,96,97,98,99,100}
	-- Tableau FrSky
	--local array	= {0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,7,7,7,8,9,10,11,12,13,14,15,18,19,20,21,22,23,24,25,26,27,28,31,32,34,36,39,42,45,49,52,55,57,59,62,63,65,68,72,74,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100}
	if nbCells > 0 then
		local voltCell = (lipoVoltage * 100) / nbCells
		local delta = math.floor(voltCell - 300)
		if delta > 120 then delta = 120	end
		if delta < 1 then delta = 1 end
		return array[delta]
	end
end

------------------------------------------------------------------------------------------
-- Définition de la couleur en fonction du pourcentage de la batterie
------------------------------------------------------------------------------------------
local function getPercentColor(percent)
       green = math.floor(0xDF * percent / 100)
       red = 0xDF - green
       return red, green, 0
end

------------------------------------------------------------------------------------------
-- Affichage de la jauge annulaire en fonction des paramètres
------------------------------------------------------------------------------------------
local function drawGauge(center_x, center_y, radius, thickness, anglePercent, percent, displayPercent, voltage, widget)
	lcd.color(lcd.RGB(getPercentColor(percent)))
	lcd.drawAnnulusSector(center_x, center_y, radius, radius + thickness, 0, anglePercent)
	lcd.color(widget.colorText)
	lcd.drawCircle(center_x, center_y, radius)	
		-- Affiche % dans le cercle si TRUE sinon la tension
	if displayPercent then
		lcd.font(widget.screen[15])
		lcd.drawNumber(center_x-radius+5, center_y-(radius/2)+5, percent, UNIT_PERCENT, 0)
	else
		lcd.font(widget.screen[16])
		lcd.drawNumber(center_x-radius+5, center_y-(radius/2)+5, voltage, UNIT_VOLT, 2)	
	end
end

local function paint(widget)
	if widget.validLayout == true then
		if widget.sensor ~= nil and checkTelemetry:state() == true then
			local cellsCount = widget.sensor:value({options=OPTION_CELLS_COUNT})
			if cellsCount then
				-- local percentLipo = getPercentLipo(25.2,6)		-- Pour les tests
				local percentLipo = getPercentLipo(widget.sensor:value(),widget.sensor:value({options=OPTION_CELL_COUNT}))
					-- Calcul de la valeur angulaire en fonction du pourcentage
				local angleLipo = math.floor(percentLipo / 100 * 360)
			
					-- Affichage Jauge Tension Lipo
				drawGauge(widget.screen[1], widget.screen[2] , widget.screen[3], widget.screen[4], angleLipo, percentLipo, true, widget.sensor:stringValue(), widget)
					-- Affichage nombre d'éléments LIPO
				lcd.font(widget.screen[14])		-- Taille de la police fontNbCell
				lcd.drawText(widget.screen[21], widget.screen[22] , widget.sensor:stringValue({options=OPTION_CELLS_COUNT})..localize("cells"))
					-- Affichage du nom du capteur Lipo
				lcd.drawText(widget.screen[17],widget.screen[18],widget.sensor:name())
					-- Affichage de la Tension globale du Lipo avec une couleur en fonction de la tension
				lcd.font(widget.screen[15])	
				lcd.color(lcd.RGB(getPercentColor(percentLipo)))
				lcd.drawText(widget.screen[19], widget.screen[20], widget.sensor:stringValue())
		
			-- if widget.screen[9] == true then													-- Affichage des éléments ?
				-- Affichage des jauges Tension par éléments
				xCell = widget.screen[5]												-- X de la première jauge Cell
				yCell = widget.screen[6]												-- Y de la première jauge Cell				
				for i = 1, cellsCount do
					-- local percentCell = getPercentLipo(4.20,1)				-- Pour les tests
					local percentCell = getPercentLipo(widget.sensor:value({options=OPTION_CELL_INDEX(i)}), 1)
					local angleCell = percentCell/100*360				
					if xCell >= widget.screen[12] then 										-- Comparaison avec la largeur de l'écran pour passer à la ligne
						xCell = widget.screen[5]												-- On test si la position de X est supérieur à la largeur de l'écran
						yCell = yCell + widget.screen[11] 									-- On décale de DyCell vers le bas pour une deuxième ligne
					end
					drawGauge(xCell, yCell, widget.screen[7],widget.screen[8], angleCell, percentCell, false, widget.sensor:value({options=OPTION_CELL_INDEX(i)}),widget)
					xCell = xCell + widget.screen[10] 										-- Sinon on décale de DxCell vers la droite
				end	
			-- end
			end
			
		elseif widget.sensor ~= nil then
			lcd.font(FONT_XL)
			lcd.color(RED)
			local textSize=lcd.getTextSize(localize("noData"))
			lcd.drawText((w/2-(textSize/2)),h/2,localize("noData"))
		else 
			lcd.font(FONT_XL)
			lcd.color(RED)
			local textSize=lcd.getTextSize(localize("noSensor"))
			lcd.drawText((w/2-(textSize/2)),h/2,localize("noSensor"))
		end
	else
		lcd.font(FONT_XL)
		lcd.color(RED)
		local textSize=lcd.getTextSize(localize("layout"))
		lcd.drawText((w/2-(textSize/2)),h/2,localize("layout"))
	end
end

local function wakeup(widget)
	
	checkTelemetry = system.getSource({category = SYSTEM_TELEMETRY_ACTIVE})
	
	if widget.validLayout == true then	
		local newValue
		if widget.sensor == nil then
			widget.sensor = system.getSource(widget.source:name())
		end

		if widget.sensor ~= nil then
			newValue = widget.sensor:value()
		end
		
		newTelemState = checkTelemetry:state()
		if newTelemState and not previousTelemState then
    		changeState = true
		end	
		previousTelemState = newTelemState 
		
        if widget.value ~= newValue or changeState == true then 
			widget.value = newValue
			lcd.invalidate()
		end	
		-- lcd.invalidate()
		
	end	
end

local function configure(widget)
	-- Color choice
	line = form.addLine(localize("textColor"))
	form.addColorField(line, nil, function() return widget.colorText end, function(newValue) widget.colorText = newValue end); 
	-- Source choice
    line = form.addLine(localize("Name"))
    form.addSourceField(line, nil, function() return widget.source end, function(newValue) widget.source = newValue end);
end

local function setDefaults(widget)
   	if widget.colorText == nil then widget.colorText = lcd.RGB(0xE0, 0xE4, 0xE0) end 
	if widget.source == nil then widget.source = ("Lipo") end
end

local function read(widget)
	widget.colorText = storage.read("colorText")
	widget.source = storage.read("source")
	
	setDefaults(widget)
end

local function write(widget)
	storage.write("colorText", widget.colorText)
	storage.write("source" ,widget.source)
end

local function init()
	system.registerWidget({key="flvss",name=name, create=create, title=false, paint=paint, build=build, configure=configure, wakeup=wakeup, menu=menu, read=read, write=write})
end

return{init=init}
