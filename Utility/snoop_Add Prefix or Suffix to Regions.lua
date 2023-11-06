--[[
 * ReaScript Name: snoop_Add Prefix or Suffix to Regions
 * Description: 
 * Author: Logan Hardin
 * Author URl: https://loganhardin.xyz
 * Github Repository: https://github.com/Snoopy20111/snoop-ReaScripts
 * REAPER: 6.xx
 * Extensions: None
 * Version: 1.0
--]]
--[[
 * Changelog:
 * v1.0
	+Initial Release
    +A great deal of this was copied or modified from Acendan's work, please check him out)
--]]

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
snoop_CommonFunctions = reaper.GetResourcePath()..'/scripts/snoop-ReaScripts/Developer/snoop_CommonFunctions.lua'
if reaper.file_exists( snoop_CommonFunctions ) then dofile( snoop_CommonFunctions ); if not snoop or snoop.version() < 1.0 then snoop.msg('This script requires a newer version of Snoops Common Functions. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"snoop_CommonFunctions"); return end else reaper.ShowConsoleMsg("This script requires Snoops Common Functions! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'Snoops Common Functions"); return end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()

    -- Get num regions
    local ret, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
    if not ret or num_regions < 1 then snoop.msg("Project has no regions!"); return end
    local num_total = num_markers + num_regions --total number of markers and regions in the whole project

    --Get user input; choices are prefix/suffix, Whole Project (p) Time Selection (t) or Region Selection (s), and the text itself.
    local ret_input, user_input = reaper.GetUserInputs("Prefix/Suffix Regions", 3, "Prefix (p) or Suffix (s),Proj (p) Time (t) or Selection (s),Text to use" .. ",extrawidth=125","p,p,")
    
    if not ret_input then return end
    
    choice_input, section_input, text_input = user_input:match("([^,]+),([^,]+),([^,]+)") --plugs the input values to these variables

    --Some data conditioning, just to make sure you don't hand over nil values    
    if choice_input == nil then
        choice_input = "p"
    end
    if section_input == nil then
        section_input = "p"
    end
    if text_input == nil then
        text_input = ""
    end

    --Split by the section choice (defaults to whole project)
    if section_input == "s" then --do selected regions
        local selected_regions_table = snoop.getSelectedRegions()
        if selected_regions_table then --if the table of selected regions is valid and has a size (as in, there are selected regions)
            for _, regionidx in pairs(selected_regions_table) do --not sure how this syntax works, but for every region ID that EnumProjectMarkers will later accept in the table
                local i = 0
                while i < num_total do --for every marker and region in the whole project
                    local return_value, is_region, position, region_end, name, mrkr_rgn_index_num, color = reaper.EnumProjectMarkers3(0, i) --get the information of the marker
                    if is_region and mrkr_rgn_index_num == regionidx then --if it's a region, AND it's region ID is on the list...
                        prefixOrSuffix(i, return_value, is_region, position, region_end, name, mrkr_rgn_index_num, color) --add the prefix/suffix
                        break
                    end
                    i = i + 1 --increment
                end
            end
        else
            snoop.msg("No regions selected!\n\nPlease go to View > Region/Marker Manager to select regions.\n\n\nIf you are on mac... I copied most of this script from Acendan's enumerator script, and his says there's a bug on Macs that prevents it from working. Sorry :(")
        end
            
    elseif section_input == "t" then --do regions in time selection
        local start_time_sel, end_time_sel = reaper.GetSet_LoopTimeRange(0,0,0,0,0) --get the time selection, start and end. All the zeros mean: Reading, Not a loop, the time of the start & end of the project (both being zero means whole project), and don't autoseek.
        if start_time_sel ~= end_time_sel then --if start time isn't equal to the end time
            local i = 0
            while i < num_total do
                local return_value, is_region, position, region_end, name, mrkr_rgn_index_num, color = reaper.EnumProjectMarkers3(0, i) --get the information of the marker
                if is_region then --if the thing's a region...
                    if position >= start_time_sel and region_end <= end_time_sel then --and if the region is entirely within the bounds of the time selection...
                        prefixOrSuffix(i, return_value, is_region, position, region_end, name, mrkr_rgn_index_num, color) --add the prefix/suffix
                    end
                end
                i = i + 1 --increment
            end
        else
            snoop.msg("You need to make a time selection!")
        end         
    else --do all regions. Default
        local i = 0
         while i < num_total do --for every individual marker...
            local return_value, is_region, position, region_end, name, mrkr_rgn_index_num, color = reaper.EnumProjectMarkers3(0, i) --get the information of the marker
            if is_region then --if the thing's a region...
                prefixOrSuffix(i, return_value, is_region, position, region_end, name, mrkr_rgn_index_num, color) --add the prefix/suffix
            end
            i = i + 1 --increment
        end
    end
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function prefixOrSuffix(count, return_value, is_region, position, region_end, name, mrkr_rgn_index_num, color) --verbose, but cuts down lines above
    if choice_input == "s" then --if suffix
        reaper.SetProjectMarkerByIndex( 0, count, is_region, position, region_end, mrkr_rgn_index_num, name .. text_input, color)
    else --if prefix (default)
        reaper.SetProjectMarkerByIndex( 0, count, is_region, position, region_end, mrkr_rgn_index_num, text_input .. name, color)
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