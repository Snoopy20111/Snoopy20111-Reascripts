--[[
 * ReaScript Name: snoop_Snap End of Media Items
 * Description: Snaps end of media items to the closest grid division
 * Author: Logan Hardin
 * Author URl: https://loganhardin.xyz
 * Github Repository: https://github.com/Snoopy20111/snoop-ReaScripts
 * REAPER: 6.xx
 * Extensions: None
 * Version: 1.1
--]]
--[[
 * Changelog:
 * v1.1
	+Updated formatting
	+Implemented Undo/Redo block (copied in from Acendan, please check him out)
	-Removed UTIL from the script name, to look cleaner :)
 * v1.0
	+Initial Release
--]]

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- This script doesn't actually need the lua utilities, but it's still here
-- Load lua utilities
--snoop_CommonFunctions = reaper.GetResourcePath()..'/scripts/snoop-ReaScripts/Developer/snoop_CommonFunctions.lua'
--if reaper.file_exists( snoop_CommonFunctions ) then dofile( snoop_CommonFunctions ); if not snoop or snoop.version() < 1.0 then snoop.msg('This script requires a newer version of Snoops Common Functions. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"snoop_CommonFunctions"); return end else reaper.ShowConsoleMsg("This script requires Snoops Common Functions! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'Snoop'"); return end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function SnapToEnd(i)
	--Get Item, Position, Length, End Position, and the closest Grid Position to the end
	Item = reaper.GetSelectedMediaItem(0,i)
	Item_Start = reaper.GetMediaItemInfo_Value(Item, "D_POSITION")
	Item_Length = reaper.GetMediaItemInfo_Value(Item, "D_LENGTH")
	Item_End = Item_Start + Item_Length
	End_Grid_Division = reaper.BR_GetClosestGridDivision(Item_End)

	--Move media item such that the end is on that grid division
	reaper.SetMediaItemPosition(Item, End_Grid_Division - Item_Length, true)
end

function main()
	--for each media item selected
	for i=0, reaper.CountSelectedMediaItems(0)-1 do
		SnapToEnd(i)
	end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()