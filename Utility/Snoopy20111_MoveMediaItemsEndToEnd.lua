--[[
 * ReaScript Name: Move Media Items End To End
 * Description: Move all selected media items in track order such that each starts where the previous ends, with optional spacing.
 * Author: Logan Hardin
 * Author URl: https://loganhardin.xyz
 * Github Repository: https://github.com/Snoopy20111/Snoopy20111-Reascripts
 * REAPER: 6.xx
 * Extensions: None
 * Version: 1.0
 * Changelog:
	+Initial Release
--]]

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

--Fill in with any non-standard functions to confirm support before running
function isSupported()
	return true
end


function main()

    --Get user input
    local ret_input, user_input = reaper.GetUserInputs("Move Edited Items End To End", 2, "Snap to next Grid Position (y/n),Time Buffer" .. ",extrawidth=125","y,0.5")
    
    if not ret_input then return end
    
    snap_to_grid_input, text_input = user_input:match("([^,]+),([^,]+)") --plugs the input values to these variables

	--Data conditioning to have usable values
	if (snap_to_grid_input == "y") then
		snap_to_grid = true
	else
		snap_to_grid = false
	end

	time_buffer = tonumber(text_input)
	
	media_items_count = reaper.CountSelectedMediaItems(0)

	--Declare an array to keep track of the initial items, start, and end
	Media_Items_Array = {}
	
	--Fill the array out, lua is weird about this
	for i=0, media_items_count do
		Media_Items_Array[i] = {}
		for j=0,5 do                                 
			Media_Items_Array[i][j] = 0
		end
	end
	
	--Fill in data for initial locations
	--Row index: 0 for items, 1 for track, 2 for pre-script start, 3 for pre-script end, 4 for current start, 5 for current end
	--We make this split because sometimes we need to know one or the other during logic.
	for i=0, media_items_count - 1 do
		Media_Items_Array[i][0] = reaper.GetSelectedMediaItem(0,i)
		Media_Items_Array[i][1] = reaper.GetMediaItemTrack(reaper.GetSelectedMediaItem(0,i))
		Media_Items_Array[i][2] = reaper.GetMediaItemInfo_Value(Media_Items_Array[i][0], "D_POSITION")
		Media_Items_Array[i][3] = Media_Items_Array[i][2] + reaper.GetMediaItemInfo_Value(Media_Items_Array[i][0], "D_LENGTH")
		Media_Items_Array[i][4] = reaper.GetMediaItemInfo_Value(Media_Items_Array[i][0], "D_POSITION")
		Media_Items_Array[i][5] = Media_Items_Array[i][4] + reaper.GetMediaItemInfo_Value(Media_Items_Array[i][0], "D_LENGTH")
	end
	
	--Finally, define a location for our "goalpost"
	Moveto_Marker = 0
	--and define our "bias" for accepting silence in-between items, in seconds
	Bias = 0.1
	
	--ACTION LOOP
	--For each media item selected
	for i=0, media_items_count - 1 do
		
		--reaper.ShowConsoleMsg("\n")
		
		------------------------
		--Big If ElseIf block!--
		------------------------
		
		--if this is the only item selected or the first item, act accordingly
		if (media_items_count == 1)
		or (i == 0)then
			--reaper.ShowConsoleMsg("First / Only Item")
			--reaper.ShowConsoleMsg("\n")

			--If snap to grid is active, move to the nearest gridline and update locations, otherwise do nothing
			if (snap_to_grid == true) then
				reaper.SetMediaItemPosition(Media_Items_Array[i][0], reaper.BR_GetClosestGridDivision(Media_Items_Array[i][2]), true)
				Media_Items_Array[i][4] = reaper.GetMediaItemInfo_Value(Media_Items_Array[i][0], "D_POSITION")
				Media_Items_Array[i][5] = Media_Items_Array[i][4] + reaper.GetMediaItemInfo_Value(Media_Items_Array[i][0], "D_LENGTH")
			end
		
		
		
		--else if the item's track is equal to the item BEFORE, AND item's start is greater than previous item's end...
		elseif (Media_Items_Array[i][1] == Media_Items_Array[i-1][1])
		and (Media_Items_Array[i][2] - Media_Items_Array[i-1][3] <= Bias) then
			--reaper.ShowConsoleMsg("Following Item")
			--reaper.ShowConsoleMsg("\n")
			
			local following_offset = Media_Items_Array[i][2] - Media_Items_Array[i-1][2]
			local move_to_location = Media_Items_Array[i-1][4] + following_offset

			--With following items, we don't bother with Snap To Grid
			reaper.SetMediaItemPosition(Media_Items_Array[i][0], move_to_location, true)
			
			--Update current data
			Media_Items_Array[i][4] = reaper.GetMediaItemInfo_Value(Media_Items_Array[i][0], "D_POSITION")
			Media_Items_Array[i][5] = Media_Items_Array[i][4] + reaper.GetMediaItemInfo_Value(Media_Items_Array[i][0], "D_LENGTH")
		
		
		
		--if this is the last item in the list, act accordingly
		--note: includes a condition to prevent last items from not following their preceding item
		elseif (i == (media_items_count - 1))then
			--reaper.ShowConsoleMsg("Last Item")
			--reaper.ShowConsoleMsg("\n")

			local move_to_location = Media_Items_Array[i-1][5] + time_buffer

			--If snap to grid is active, move to the nearest gridline and update locations, otherwise move as normal
			if (snap_to_grid == true) then
				reaper.SetMediaItemPosition(Media_Items_Array[i][0], reaper.BR_GetNextGridDivision(move_to_location), true)
			else
				reaper.SetMediaItemPosition(Media_Items_Array[i][0], move_to_location, true)
			end
			
			--Update current data
			Media_Items_Array[i][4] = reaper.GetMediaItemInfo_Value(Media_Items_Array[i][0], "D_POSITION")
			Media_Items_Array[i][5] = Media_Items_Array[i][4] + reaper.GetMediaItemInfo_Value(Media_Items_Array[i][0], "D_LENGTH")



		--elseif this item is on a new track, act accordingly
		elseif (Media_Items_Array[i][1] ~= Media_Items_Array[i-1][1]) then
			--reaper.ShowConsoleMsg("New Track Item")
			--reaper.ShowConsoleMsg("\n")
			
			local move_to_location = Media_Items_Array[i-1][5] + time_buffer
			
			--If snap to grid is active, move to the nearest gridline and update locations, otherwise move normally
			if (snap_to_grid == true) then
				reaper.SetMediaItemPosition(Media_Items_Array[i][0], reaper.BR_GetNextGridDivision(move_to_location), true)
			else
				reaper.SetMediaItemPosition(Media_Items_Array[i][0], move_to_location, true)
			end
			
			--Update current data
			Media_Items_Array[i][4] = reaper.GetMediaItemInfo_Value(Media_Items_Array[i][0], "D_POSITION")
			Media_Items_Array[i][5] = Media_Items_Array[i][4] + reaper.GetMediaItemInfo_Value(Media_Items_Array[i][0], "D_LENGTH")



		--else if the item's track is equal to the item AFTER, AND item's end is greater than previous item's start...
		elseif (Media_Items_Array[i][1] == Media_Items_Array[i+1][1])
		and (Media_Items_Array[i][2] - Media_Items_Array[i-1][3] >= Bias) then
			--reaper.ShowConsoleMsg("Preceding Item")
			--reaper.ShowConsoleMsg("\n")
			
			local move_to_location = Media_Items_Array[i-1][5] + time_buffer

			--If snap to grid is active, move to the nearest gridline and update locations, otherwise move as normal
			if (snap_to_grid == true) then
				reaper.SetMediaItemPosition(Media_Items_Array[i][0], reaper.BR_GetNextGridDivision(move_to_location), true)
			else
				reaper.SetMediaItemPosition(Media_Items_Array[i][0], move_to_location, true)
			end
			
			--Update current data
			Media_Items_Array[i][4] = reaper.GetMediaItemInfo_Value(Media_Items_Array[i][0], "D_POSITION")
			Media_Items_Array[i][5] = Media_Items_Array[i][4] + reaper.GetMediaItemInfo_Value(Media_Items_Array[i][0], "D_LENGTH")
		


		--elseif this item doesn't overlap the items before or after, move to end of last item + buffer
		--This WILL cause out-of-bounds issues if it's not caught by previous lines
		elseif ((Media_Items_Array[i-1][3] - Media_Items_Array[i][2] < ((-1) * Bias))
		and (Media_Items_Array[i+1][2] - Media_Items_Array[i][3] > Bias)
		and (Media_Items_Array[i][1] == Media_Items_Array[i+1][1]))
		or (Media_Items_Array[i][1] ~= Media_Items_Array[i+1][1]) then
			--reaper.ShowConsoleMsg("Orphan or New Track Item")
			--reaper.ShowConsoleMsg("\n")
			
			local move_to_location = Media_Items_Array[i-1][5] + time_buffer

			--If snap to grid is active, move to the nearest gridline and update locations, otherwise move as normal
			if (snap_to_grid == true) then
				reaper.SetMediaItemPosition(Media_Items_Array[i][0], reaper.BR_GetNextGridDivision(move_to_location), true)
			else
				reaper.SetMediaItemPosition(Media_Items_Array[i][0], move_to_location, true)
			end
			
			--Update current data
			Media_Items_Array[i][4] = reaper.GetMediaItemInfo_Value(Media_Items_Array[i][0], "D_POSITION")
			Media_Items_Array[i][5] = Media_Items_Array[i][4] + reaper.GetMediaItemInfo_Value(Media_Items_Array[i][0], "D_LENGTH")
		end
		
		
		
		--reaper.ShowConsoleMsg("i = ")
		--reaper.ShowConsoleMsg(i)
		--reaper.ShowConsoleMsg("\n")
		
		--reaper.ShowConsoleMsg("Item Start: ")
		--reaper.ShowConsoleMsg(Media_Items_Array[i][2])
		--reaper.ShowConsoleMsg("\n")
		--reaper.ShowConsoleMsg("Item End: ")
		--reaper.ShowConsoleMsg(Media_Items_Array[i][3])
		--reaper.ShowConsoleMsg("\n")
    end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if (isSupported()) then

	reaper.PreventUIRefresh(1)
	reaper.Undo_BeginBlock()
	main()
	reaper.Undo_EndBlock("snoop_Move Media Items End To End",-1)
	reaper.PreventUIRefresh(-1)
	reaper.UpdateArrange()
else
	reaper.MB("Required functions unavailable. Please install or update SWS extension", "Error", 0)
end