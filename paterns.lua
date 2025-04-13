-----------------------------------------------------------
-- => File description 
-----------------------------------------------------------
--  Get the name of the file
--      Get the extension
--  Search the extension up in the 'database'
--      Use the coresponding command in the 'database'
--  If no extension in 'database'
--      return false

-----------------------------------------------------------
-- => Database
-----------------------------------------------------------

local execute_paterns = {
    python = {
        "python $FILENAME"
    },
    lua = {
        "echo 'are you editing nvim?' && ",
        "echo 'yes you are'"
    }

}


-----------------------------------------------------------
-- => Main function
-----------------------------------------------------------

function getCmdStr()
    local filetype = vim.bo.filetype 
    local filename = vim.api.nvim_buf_get_name(0)
    local cmd_str = ""

    -- This executes if the filetype is not found in our 'database'
    if not execute_paterns[filetype] then
        return ""
    end


    for i, v in ipairs(execute_paterns[filetype]) do
        cmd_str = cmd_str .. v:gsub("$FILENAME", filename) 
    end

    return cmd_str
end


