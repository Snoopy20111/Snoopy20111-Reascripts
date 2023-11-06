--[[
 * ReaScript Name: Snoop_CommonFunctions
 * Description: Pre-written functions, to help keep the other scripts shorter and easier to understand.
 * Author: Logan Hardin
 * Author URl: https://loganhardin.xyz
 * Github Repository: https://github.com/Snoopy20111/snoop-ReaScripts
 * REAPER: 6.xx
 * Extensions: None
 * Version: 1.0
 * 
 * About:
    #Lua Utilities
    By Logan Hardin

    This is the starting place and supporting stuff for my scripts in the future.
    Significant reference, paraphrasing, and outright copying from those below:
    - Acendan (Aaron Cendan, https://aaroncendan.me)
    - Cfillion (Christian Fillion, https://cfillion.ca/)
    - X-Raym (Raymond Radet, https://www.extremraym.com/)

    If you're here for reference on your own scripts, please check them out instead!

    ### Upper section - Templates
    * For easy starting places on future scripts.
    * Many of these are almost completely copied from Acendan's util script! I concede all credit.

    ### Lower section - Utilities
    * A stack of helper functions, made into a library for easy calling.
    * CTRL+F if you need to!
--]]
--[[
 * Changelog:
 * v1.01
  +Goofed the name metadata
 * v1.0
	+Initial Release
--]]

--[[

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ GLOBAL VARS ~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Get this script's name and directory
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local script_directory = ({reaper.get_action_context()})[2]:sub(1,({reaper.get_action_context()})[2]:find("\\[^\\]*$"))

-- Load lua utilities
snoop_CommonFunctions = reaper.GetResourcePath()..'/scripts/snoop-ReaScripts/Developer/snoop_CommonFunctions.lua'
if reaper.file_exists( snoop_CommonFunctions ) then dofile( snoop_CommonFunctions ); if not snoop or snoop.version() < 1.0 then snoop.msg('This script requires a newer version of Snoop's Common Functions. Please run:\n\nExtensions > ReaPack > Synchronize Packages',"snoop_CommonFunctions"); return end else reaper.ShowConsoleMsg("This script requires Snoop's Common Functions! Please install them here:\n\nExtensions > ReaPack > Browse Packages > 'ACendan Lua Utilities'"); return end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function main()

end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

--Often to put some small sub-functions here, little things that either reduce lines of text or are too specific to put in the common functions.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock(script_name,-1)

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()

]]


-------------------------------------------------------------------------------------------
-- Hereafter be library functions --

-- Establishes that this is a class
snoop = {}

-- function for finding the version of this script
function snoop.version()
    local file = io.open((reaper.GetResourcePath()..'/scripts/snoop-ReaScripts/Developer/snoop_CommonFunctions.lua'):gsub('\\','/'),"r") --reads in the given file, substituting a / for every \\ to keep things from being goofed up
    local vers_header = "* Version: " -- this is the set of symbols just before our version number
    io.input(file) --read the current file
    local t = 0
    for line in io.lines() do -- for every line (incrementing t)
        if line:find(vers_header) then -- check for the version header string
          t = line:gsub(vers_header,"") -- set t to the whole line with the version number, but remove the whole part that isn't the number, leaving just the version number
          break -- stop doing the thing
        end
    end
    io.close(file) -- close the file
    return tonumber(t) -- give back our answer
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~ Debug & Messages ~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function snoop.dbg(dbg) --makes printing to the log easier
    reaper.ShowConsoleMsg(tostring(dbg) .. "\n")
end

function snoop.msg(msg, title) --prints a message to a message box popup
    local title = title or "Snoop Info"
    reaper.MB(tostring(msg), title, 0)
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~ Regions ~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

--STOLEN FROM ACENDAN LUA UTILITIES SCRIPT

--Get selected regions (uses GetRegionManager)
function snoop.getSelectedRegions()
    local hWnd = snoop.getRegionManager() --gets a regerence to the Region Manager window object
    if hWnd == nil then return end  --if that reference is empty or doesn't work, cut the process here
  
    local container = reaper.JS_Window_FindChildByID(hWnd, 1071) --Gets a child of the Region Manager window, which happens to be the table of your selected regions
  
    sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(container) --Make two tables, which are copies of the above
    if sel_count == 0 then return end  --If those tables are empty, cut the process
  
    names = {} --New Array
    i = 0 --For Loop counter
    for index in string.gmatch(sel_indexes, '[^,]+') do  --for every item in the table
      i = i+1
      local sel_item = reaper.JS_ListView_GetItemText(container, tonumber(index), 1) --get the name, plus some extra character at the front
      if sel_item:find("R") ~= nil then --if the name value isn't null
        names[i] = tonumber(sel_item:sub(2)) --sets the given cell to the name, minus the first character
      end
    end
    
    -- Return array of the ID's of selected regions
    return names
  end

  -- Get a reference to the region manager window
  function snoop.getRegionManager()
    local title = reaper.JS_Localize("Region/Marker Manager", "common") --Gets name of Region Manager in whatever language you're using
    local arr = reaper.new_array({}, 1024) --Makes a new array
    reaper.JS_Window_ArrayFind(title, true, arr) --dumps all windows that match the title into the array
    local adr = arr.table() --Converts array into table, which is the same but can contain any data type in any individual cell
    for j = 1, #adr do
      local hwnd = reaper.JS_Window_HandleFromAddress(adr[j])
      -- verify window by checking if it also has a specific child.
      if reaper.JS_Window_FindChildByID(hwnd, 1056) then -- 1045:ID of clear button
        return hwnd
      end
    end
  end