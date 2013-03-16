-- Handle the vim search emulation
-- Modeled on textadept's command_entry.lua
local M = {}

local search_hl_indic = _SCINTILLA.next_indic_number()

local function set_colours()
    buffer.indic_fore[search_hl_indic] = "0x00FFFF"
    buffer.indic_style[search_hl_indic] = _SCINTILLA.constants.INDIC_ROUNDBOX
end

M.state = {
    in_search_mode = false,
    backwards = false,
    pattern = nil,
}

local function do_search(backwards)
    gui.statusbar_text = "Search: "..state.pattern
    local saved_pos = buffer.current_pos
    buffer:search_anchor()

    local search_flags = (_SCINTILLA.constants.SCFIND_REGEXP +
			  _SCINTILLA.constants.SCFIND_POSIX)

    local searcher
    if backwards then
	searcher = function(...) return buffer:search_prev(...) end
    else
	searcher = function(...) return buffer:search_next(...) end
    end
    pos = searcher(search_flags, state.pattern)

    if pos < 0 then
      -- Didn't find searching in this direction, so search whole buffer.
      if backwards then
	  buffer.current_pos = buffer.length-1
      else
	  buffer.current_pos = 0
      end
      buffer:search_anchor()
      pos = searcher(search_flags, state.pattern)
    end

    if pos >= 0 then
	local saved_flags = buffer.search_flags
	buffer.search_flags = search_flags
	buffer.goto_pos(pos)
	-- Find all occurrences to highlight.
	buffer.indicator_current = search_hl_indic
	buffer:indicator_clear_range(0, buffer.length)

	-- Need to use search_in_target to find the actual search extents.
	buffer.target_start = 0
	buffer.target_end = buffer.length
	local occurences = 0
	local addsel = buffer.set_selection
	while buffer.search_in_target(state.pattern) >= 0 do
	    addsel(buffer.target_end-1, buffer.target_start)
	    addsel = buffer.add_selection
	    --[[  In the terminal, indicators currently don't work.  :-(
	    local match_len = buffer.target_end - buffer.target_start
	    buffer:indicator_fill_range(buffer.target_start, match_len)
	    -- Set the search range from the end of this match to the
	    -- end of the buffer.
	    ]]
	    buffer.target_start = buffer.target_end
	    buffer.target_end = buffer.length

	    occurences = occurences + 1
	end
	gui.statusbar_text = "Found " .. tostring(occurences) .. " : <" .. tostring(search_hl_indic) .. ">"
	-- Restore global search flags
	buffer.search_flags = saved_flags
    else
	buffer.current_pos = saved_pos
	gui.statusbar_text = "Not found"
    end
end

local function handle_search_command(command)
    if state.in_search_mode then
        state.pattern = command
	do_search(state.backwards)
	state.in_search_mode = false
	return false  -- make sure this isn't handled again
    end
end

local function handle_search_key(code)
    if state.in_search_mode and keys.KEYSYMS[code] == 'esc' then
        -- Make sure we cancel the search flag.

        state.in_search_mode = false
    end
end

events.connect(events.COMMAND_ENTRY_COMMAND, handle_search_command, 1)
events.connect(events.COMMAND_ENTRY_KEYPRESS, handle_search_key, 1)

local function start_common()
    state.in_search_mode = true
    gui.command_entry.entry_text = ""
    gui.command_entry.focus()
end

function M.start()
    state.backwards = false
    return start_common()
end

function M.start_rev()
    state.backwards = true
    return start_common()
end

function M.restart()
    do_search(state.backwards)
end

function M.restart_rev()
    do_search(not state.backwards)
end

local function search_word_common(backwards)
    -- Search for the word under the cursor
    -- TODO: quote properly, or better don't use regex'
    -- Uses ideas from editing.lua
    local pos = buffer.current_pos
    local s, e = buffer:word_start_position(pos, true), buffer:word_end_position(pos)
    local word = buffer:text_range(s, e)
    state.pattern = '\\<' .. word .. '\\>'
    do_search(backwards)
end

function M.search_word()
    search_word_common(false)
end

function M.search_word_rev()
    search_word_common(true)
end

return M
