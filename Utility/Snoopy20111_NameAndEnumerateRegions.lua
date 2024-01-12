--[[
 * ReaScript Name: Name and Enumerate Regions
 * Description: Allows selecting a bunch of media items and making regions with a given name, enumerating each successive region
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
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()

	--Get user input; Inputs are Region Name, and the character or text used as a separator.
	local ret_input, user_input = reaper.GetUserInputs("Name & Enumerate Regions", 3, "Base Track Name,Separator Character,Minimum Number of Zeros" .. ",extrawidth=100","Region,_,2")
	if not ret_input then return end

	region_name_input, separator_char_input, min_zeros_input = user_input:match("([^,]+),([^,]+),([^,]+)") --plugs the input values to these variables

	--Some data conditioning, just to make sure values are workable
	if region_name_input == nil then
		region_name_input = "Region"
	end
	if separator_char_input == nil then
		separator_char_input = "_"
	end
	min_zeros_input = tonumber(min_zeros_input)
	if (min_zeros_input == nil) or (min_zeros_input < 0) then
		min_zeros_input = 0
	end

	selected_media_items_count = reaper.CountSelectedMediaItems(0)

	if (selected_media_items_count > 0) then
		--get the number of digits and determine how many zeros need to go first
		local padding_amount = #tostring(selected_media_items_count)
		--set minimum, if input
		if padding_amount < min_zeros_input then
			padding_amount = min_zeros_input
		end

		--Declare an array to keep track of the items and fill with all selected media items
		input_items_array = {}
		for i=1, selected_media_items_count do
			input_items_array[i] = reaper.GetSelectedMediaItem(0,i-1)
		end
		--Declare a second array for the "sorted" items, but fill with zeros
		media_items_array = {}
		for i=1, selected_media_items_count do
			media_items_array[i] = 0
		end
		
		--Sort the items based on their start position, to ensure left-to-right regions later
		--Selection Sort for "simplicity" and (probably) small set sizes...optimize this later
		iterator = 1
		size = selected_media_items_count
		while size > 0 do
			num_grabber = 0
			smallest_length = math.huge --infinity, so the first length in the array below will always be "smallest"
			
			--Go through every item in the input array and find the smallest
			for i=1, size do
				local current_length = reaper.GetMediaItemInfo_Value(input_items_array[i], "D_POSITION")
				if smallest_length > current_length then
					smallest_length = current_length
					num_grabber = i
				end
			end
			
			--once found, add it to the beginning of the new array, remove from the old, and go again
			media_items_array[iterator] = input_items_array[num_grabber]
			table.remove(input_items_array,num_grabber)
			size = size - 1
			iterator = iterator + 1
		end
		
		
		for i=1, selected_media_items_count do
			local number_of_zeros = padding_amount - #tostring(i)
			local num_zeros_string = ""
			for j=1, number_of_zeros do
				num_zeros_string = "0" .. num_zeros_string
			end
			enumerator_value = num_zeros_string .. tostring(i)
			
			--Get the item's start position, add the item length find the end point, and get the Track
			local item_start = reaper.GetMediaItemInfo_Value(media_items_array[i], "D_POSITION")
			local item_end = item_start + reaper.GetMediaItemInfo_Value(media_items_array[i], "D_LENGTH")
			local item_track = reaper.GetMediaItemTrack(media_items_array[i])
			local new_name = region_name_input .. separator_char_input .. enumerator_value
			
			--Make a region with that position, using the track's name
			local Region_Index = reaper.AddProjectMarker2(0, true, item_start, item_end, new_name, -1, 0)
			--assign the media item's track to be that region's render target
			reaper.SetRegionRenderMatrix(0, Region_Index, item_track, 1)
		end
	else
		reaper.ShowConsoleMsg("No media items selected!\n\nPlease select at least one media item with this mode, or use Time mode (t) with a time selection.\n")
	end
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()