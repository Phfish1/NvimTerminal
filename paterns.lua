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
        "cd '$FILEDIR' && ",
        "python $FILEPATH"
    },
    lua = {
        "cd $FILEDIR && ",
        "echo 'are you editing nvim?'",
    }

}


-----------------------------------------------------------
-- => Main function
-----------------------------------------------------------

function getCmdStr()
    local filetype = vim.bo.filetype 
    local filepath = vim.api.nvim_buf_get_name(0)
    local filedir = string.gsub(filepath, "/[^/]+$", "")

    local cmd_str = ""

    -- This executes if the filetype is not found in our 'database'
    if not execute_paterns[filetype] then
        return ""
    end


    -- Matches $<VARIABLE> in the 'database' and replaces it with variable
    for i, v in ipairs(execute_paterns[filetype]) do
        cmd_str = cmd_str .. v:gsub("%$(%u+)", function(match)
            if match == "FILEPATH" then
                return filepath
            elseif match == "FILEDIR" then
                return filedir
            end
            return nil
        end)
    end

    return cmd_str
end


