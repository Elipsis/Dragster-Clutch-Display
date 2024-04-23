--[[
Dragster Clutching Display Script 2.0
Version 2.0
Date 2017-09-12 / 2024-02-29
Written by Elipsis

This script was written and tested for BizHawk.  Basically, it will track and display how the clutch is used throughout a run.  The format is as follows.

[InputNumber]: [Game Time Clutch Detected]
or in the case of multiple frames
[InputNumber]: [First Frame Clutch Detected] - [Last Frame Clutch Detected] ([Number of P1 Frames])
It will also alert on dropped inputs, which is a 1 frame press only when reading P2 inputs.

Set "timeDelay" variable to "true" to only display inputs after the run is over (for RTA attempts).  Or "false" for real-time feedback.

Outstanding issues:
The perfect start is still detecting as "Early" even though the value in memory watch is 0 instead of 170...

Todo:
Color code inputs based on whether or not they fall in the perfect frame window.



--]]

--CUSTOMIZE
timeDelay = true

--Initialize Globals
shifts = 0
clutchFrames = 0
shiftColor = {}
shiftDisplay = {}
clutchDown = false
buttonDown = false
debugDisplay = "First"


--Mathing for easy conversion of values to integers and decimals from the bytes in memory.
function hexToDecimal(byte)
    -- Convert number to hexadecimal string
    local hexString = string.format("%x", byte)
    -- Convert hexadecimal string to decimal
	--debugDisplay = "Converting " .. hexString .. " to decimal"
    local decimal = tonumber(hexString) / 100
    return decimal
end

function hexToInteger(byte)
	-- Convert number to hexadecimal string
	local hexString = string.format("%x", byte)
	local integer = tonumber(hexString)
	return integer
end

function getTime(playerSeconds, playerFraction)
	return hexToInteger(seconds) + hexToDecimal(fraction)
end

function formatTime(theTime)
	return string.format("%.2f", theTime)
end

while true do	

	--Read Memory
	seconds = memory.readbyte(0x33,"Main RAM")
	p2seconds = memory.readbyte(0x34, "Main RAM")
	fraction = memory.readbyte(0x35,"Main RAM")
	input = memory.readbyte(0x2D,"Main RAM")
	gear = memory.readbyte(0x4C,"Main RAM")
	activePlayer = memory.readbyte(0x0F,"Main RAM")
	
	--Debug Update
	--debugDisplay = string.format("%.2f", getTime(seconds, fraction))
	
	--Clutch Held
	if (input == 11 and clutchDown == true) then
		if (activePlayer == 1) then
			clutchFrames = clutchFrames + 1
			if(seconds == 170 and fraction == 170) then
				clutchEndString = "EARLY"
			else
				clutchEndTime = getTime(seconds, fraction)
				clutchEndString = formatTime(clutchEndTime)
			end
			--debugDisplay = ("Clutch input recorded." .. fraction)
		end
	end
	
	--Clutch is released
	if (input == 15) then				
		--P1 registered as down
		if(buttonDown == true and clutchDown == true) then
			--debugDisplay = "Clutchframes: " .. clutchFrames
			shifts = shifts + 1
			
			if (clutchFrames == 1) then
				shiftDisplay [shifts] = (shifts .. ": " .. clutchStartString)
				shiftColor [shifts] = "green"
				
			end
			
			if (clutchFrames > 1) then
				shiftDisplay [shifts] = (shifts .. ": " .. clutchStartString .. " - " .. clutchEndString .. " " .. clutchFrames .. " Frames!!")
				shiftColor [shifts] = "red"
			end
		end

		--P1 clutch did NOT register as down
		if(buttonDown == true and clutchDown == false) then
			shifts = shifts + 1
			shiftDisplay [shifts] = (shifts .. ": " .. "Dropped Clutch Input at " .. formatTime(getTime(seconds,fraction)) .. "!!")
			shiftColor [shifts] = "purple"
		end
		
		clutchFrames = 0
		clutchDown = false
		buttonDown = false
	end
	
	--New Clutch Press
	if (input == 11 and clutchDown == false) then
	
		if(activePlayer == 1) then
			clutchFrames = clutchFrames + 1
			if(seconds == 170 and fraction == 170) then
				clutchStartString = "EARLY"
			else
				clutchStartTime = getTime(seconds, fraction)
				clutchStartString = formatTime(clutchStartTime)
			end
			clutchDown = true
		end
		
		buttonDown = true
		
	end
	
	--Reinitialize on reset press
	if (input == 7) then
		shifts = 0
		clutchFrames = 0
		clutchDown = false
		buttonDown = false
		--debugDisplay = "First"
		shiftDisplay = {}
		shiftColor = {}
	end
	
	--Debug	
	--gui.text(0,300, debugDisplay, "white")
	
	--Output full array!
	if( (timeDelay == false) or (timeDelay == true and p2seconds >= 7) ) then
		for i,v in ipairs(shiftDisplay) do
			gui.text(0, i * 12 + 500, v , shiftColor[i])
		end
	end

	emu.frameadvance()
end
