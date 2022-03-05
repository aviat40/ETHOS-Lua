-- ##########################################################################################################
-- #                                                                                                        #
-- # FLVSS / MLVSS lua for ETHOS V1.1.0 or above 															#
-- #																										#
-- # IMPORTANT! Update the MLVSS sensor to the latest firmware from frsky-rc.com web page before use        #
-- #                                                                                                        #
-- # hobby-rc.freeboxos.fr (2022)                                                                           #
-- #                                                                                                        #
-- ##########################################################################################################

local version = "1.0"
local translations = {fr="Lua MLVSS/FLVSS", en="MLVSS/FLVSS Lua", de="MLVSS/FLVSS lua", es=" Es", no="MLVSS/FLVSS Luascript"}
local text = {en=" Cells", fr=" Eléments", de=" De", es=" Es", no=" Celle(r)"}
local text1 = {en="No Sensor", fr="Pas de capteur", de="De", es=" Es", no="Ingen Sensor"}
local text2 = {en="Text Color", fr="Couleur Texte", de="Text Farbe", es=" Es", no="Tekstfarge"}
local text3 = {en="Lipo Sensor", fr="Capteur Lipo", de="Lipo Sensor", es=" Es", no="LiPo-sensor"}
local text4 = {en="Desactivate Title", fr="Désactiver le titre", de="Titel deaktivieren", es=" Es", no="Skru av'Tittel'"}
local locale = system.getLocale()

--				 
local field = {
--{xLipo,yLipo,rLipo,thickLipo,xCell,yCell,rCell,thickCell,Cell,DxCell,DyCell,screenWidth,screenHeight,fontNbCell,fontLipo,fontCell,xName,yName}
	{45, 70, 35, 10, 210, 40, 25, 8, true, 70, 70, 388, 154, FONT_S, FONT_L_BOLD, FONT_XS, 100, 120},	-- Taille écran 388 * 132
	{70, 70, 35, 10, 0, 0, 0, 0, false, 0, 0, 256, 154, FONT_S, FONT_L_BOLD, FONT_XS, 150, 120},		-- Taille écran 256 * 132
	{55, 75, 40, 10, 250, 75, 30, 8, true, 95, 70, 784, 154, FONT_S, FONT_L_BOLD, FONT_XS, 110, 120},	-- Taille écran 784 * 132
	{60, 70, 40, 10, 40, 180, 30, 8, true, 87, 85, 256, 316, FONT_S, FONT_L_BOLD, FONT_XS, 170, 5},		-- Taille écran 256 * 294
	{70, 50, 35, 10, 0, 0, 0, 0, false, 0, 0, 256, 100, FONT_S, FONT_L_BOLD, FONT_XS, 180, 80},			-- Taille écran 256 * 100
	{60, 60, 40, 10, 60, 160, 30, 8, true, 87, 85, 388, 316, FONT_S, FONT_L_BOLD, FONT_XS,280 , 50},	-- Taille écran 388 * 316
	{90, 145, 60, 20, 370, 80, 50, 15, true, 150, 150, 784, 316, FONT_STD, FONT_XXL, FONT_XL, 150, 250},-- Taille écran 784 * 294
	{45, 44, 30, 10, 0, 0, 0, 0, false, 0, 0, 300, 88, FONT_S, FONT_L_BOLD, FONT_XS,200,40},			-- Taille écran 300 * 88
 }
 
local function name(widget)
	return translations[locale] or translations["en"]
end

local function menu(widget)
	return{{"FLVSS v"..version, function() end}}
end

local function create()
	return {colorText = lcd.RGB(0xE0, 0xE4, 0xE0),
			value = nil, 
			lipoSensor = nil
			}
end

------------------------------------------------------------------------------------------
-- Définition de la taille de l'écran sans le titre
------------------------------------------------------------------------------------------

local function getScreenSize()
	local width, height = lcd.getWindowSize()
	if 		width == 388 and height == 154 	then return 1 
	elseif 	width == 256 and height == 154 	then return 2 
	elseif	width == 784 and height == 154 	then return 3 
	elseif 	width == 256 and height == 316 	then return 4 
	elseif 	width == 256 and height == 100 	then return 5 
	elseif 	width == 388 and height == 316 	then return 6 
	elseif 	width == 784 and height == 316 	then return 7 
	elseif 	width == 300 and height == 88 	then return 8 
	else
		lcd.font(FONT_STD)
		lcd.drawText(width/2, height/2, text4[locale] or text1["en"], CENTERED)					--Message "Désactiver le titre"
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
		lcd.font(field[widget.screen][15])
		lcd.drawText(center_x+3, center_y-10, percent.."%", CENTERED)
	else
		lcd.font(field[widget.screen][16])
		lcd.drawText(center_x+3, center_y-7, voltage, CENTERED)	
	end
end

local function paint(widget)
	widget.screen = getScreenSize()
	if widget.value ~= nil then 
		--local percentLipo = getPercentLipo(24.9,6)											-- Pour les tests
		local percentLipo = getPercentLipo(widget.value:value(),widget.value:value(OPTION_CELL_COUNT))
		
		-- Calcul de la valeur angulaire en fonction du pourcentage
		local angleLipo = math.floor(percentLipo/100*360)
		
		-- Affichage Jauge Tension Lipo
		drawGauge(field[widget.screen][1], field[widget.screen][2] , field[widget.screen][3],field[widget.screen][4], angleLipo, percentLipo, true, widget.value:stringValue(), widget)
		
		-- Affichage nombre d'éléments LIPO
		local xText = field[widget.screen][1] + field[widget.screen][3] + field[widget.screen][4] + 5
		local yText = field[widget.screen][2]
		lcd.font(field[widget.screen][14])														-- Taille de la police fontNbCell
		lcd.drawText(xText, yText-30 , widget.value:stringValue(OPTION_CELL_COUNT)..text[locale] or text["en"])
		-- Affichage du nom du capteur Lipo
		lcd.drawText(field[widget.screen][17],field[widget.screen][18],widget.value:name())
		
		-- Affichage de la Tension globale du Lipo avec une couleur en fonction de la tension
		lcd.font(field[widget.screen][15])	
		lcd.color(lcd.RGB(getPercentColor(percentLipo)))
		lcd.drawText(xText, yText, widget.value:stringValue())									-- Valeur de la Tension du Lipo
		
		if field[widget.screen][9] == true then													-- Affichage des éléments ?
			-- Affichage des jauges Tension par éléments
			local xCell = field[widget.screen][5]												-- X de la première jauge Cell
			local yCell = field[widget.screen][6]												-- Y de la première jauge Cell
															
			for cell = 1, widget.value:value(OPTION_CELL_COUNT) do
				--local percentCell = getPercentLipo(3.86,1)									-- Pour les tests
				local percentCell = getPercentLipo(widget.value:value(OPTION_CELL_INDEX(cell)),1)
				local angleCell = percentCell/100*360			
				if xCell >= field[widget.screen][12] then 										-- Comparaison avec la largeur de l'écran pour passer à la ligne
					xCell = field[widget.screen][5]												-- On test si la position de X est supérieur à la largeur de l'écran
					yCell = yCell + field[widget.screen][11] 									-- On décale de DyCell vers le bas pour une deuxième ligne
				end
				drawGauge(xCell, yCell, field[widget.screen][7],field[widget.screen][8], angleCell, percentCell, false, widget.value:stringValue(OPTION_CELL_INDEX(cell)),widget)
				xCell = xCell + field[widget.screen][10] 										-- Sinon on décale de DxCell vers la droite
			end	
		end		
	else
		lcd.drawText(field[widget.screen][17],field[widget.screen][18], text1[locale] or text1["en"], LEFT)		-- Message "pas de FLVSS"
	end
end

local function wakeup(widget)
	local sensor = system.getSource(widget.lipoSensor:name())
	local newValue = nil
	if sensor~=nil then
		newValue = sensor
	end
	if widget.value ~= newValue then 
		widget.value = newValue
		lcd.invalidate()
	end	
end

local function configure(widget)
	-- Color choice
	line = form.addLine(text2[locale] or text2["en"])
	form.addColorField(line, nil, function() return widget.colorText end, function(value) widget.colorText = value end); 
	-- Source choice
    line = form.addLine(text3[locale] or text3["en"])
    form.addSourceField(line, nil, function() return widget.lipoSensor end, function(value) widget.lipoSensor = value end)
end

local function read(widget)
	widget.colorText = storage.read("colorText")
	widget.lipoSensor = storage.read("lipoSensor")
end

local function write(widget)
	storage.write("colorText", widget.colorText)
	storage.write("lipoSensor" ,widget.lipoSensor)
end

local function init()
	system.registerWidget({key="flvss",name=name, create=create, paint=paint, configure=configure, wakeup=wakeup, menu=menu, read=read, write=write})
end

return{init=init}
