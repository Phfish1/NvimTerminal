-----------------------------------------------------------
-- => Variables
-----------------------------------------------------------

local buf_ids = {}
local term_height = 7


-----------------------------------------------------------
-- => AutoCMD Events
-----------------------------------------------------------

-- This autocmd 'TermOpen' runs whenever you open a new terminal!
vim.api.nvim_create_autocmd('TermOpen', {
    group = vim.api.nvim_create_augroup('custom-term-open', {
        clear = true,
    }),

    -- Changes the default terminal behaviour
    callback = function(args)
        vim.opt.number = false
        vim.opt.relativenumber = false
        
        -- starts terminal in input mode by default
        vim.cmd("startinsert")
        
        
        -- insert the job_id of the terminal to buf_ids
        table.insert(buf_ids, { buf = args.buf, winid = vim.fn.win_getid() } )
        
        -- Debug:
        --vim.api.nvim_buf_set_lines(5, 0, -1, false, { tostring(args.buf), "opens!" })
    end,
})

vim.api.nvim_create_autocmd('TermClose', {
    group = vim.api.nvim_create_augroup('custom-term-close', {
        clear = true,
    }),

    callback = function(args)
        -- Remove the table entry that contains the closed terminals vim.bo.channel job_id
        bufnr = args.buf
        for k, v in pairs(buf_ids) do
            if v["buf"] == bufnr then
                table.remove(buf_ids, k)
            end
        end

        -- Debug:
        --vim.api.nvim_buf_set_lines(5, 0, -1, false, { tostring(bufnr), "closes!", tostring(v) })
    end
})

-----------------------------------------------------------
-- => Extra functions
-----------------------------------------------------------

local function enterTerminal(win_id)
    vim.api.nvim_set_current_win(win_id)

    vim.cmd("startinsert")
end


-----------------------------------------------------------
-- => KeyMap functions
-----------------------------------------------------------


local openTerminal = function()
    vim.cmd.new()
    vim.cmd.term()
    vim.cmd.wincmd("J")
    vim.api.nvim_win_set_height(0, term_height)

    return true
end


local function executeCommand(enter_terminal)
    local opened_terminal = false
    if table.getn(buf_ids) == 0 then
        opened_terminal = openTerminal()

        -- Makes you NOT jump into the terminal
        vim.cmd("wincmd p")
        
        if not enter_terminal then
            vim.api.nvim_input("<esc>")
        end
    end

    -- Get the job_id 
    bufnr = buf_ids[table.getn(buf_ids)]["buf"]
    job_id = vim.api.nvim_buf_get_var(bufnr, "terminal_job_id")

    -------------------
    --- Needs update to be able to do user input (EOF error)
    -------------------

    -- Construct and send terminal input data
    cmd_str = getCmdStr()

    
    -- !!! THIS NEEDS UPDATING !!!
    --      Does not terminate the previous process!

    -- First "", to send space to last chansend, trailing "" to set newline
    vim.fn.chansend( job_id, { "", cmd_str, "" })

    -- Ensure autoscroll functonality
    vim.api.nvim_buf_call(bufnr, function()
        vim.cmd("norm G")
    end)

    if enter_terminal then
        local winid = buf_ids[table.getn(buf_ids)]["winid"]
        enterTerminal(winid)
    end
end


local function closeTerminal()
    if table.getn(buf_ids) == 0 then
        print("No open terminals")
        return
    end

    -- Gets the terminal buffer and from it the job_id
    bufnr = buf_ids[table.getn(buf_ids)]["buf"]
    job_id = vim.api.nvim_buf_get_var(bufnr, "terminal_job_id")

    -- Closes job and buffer
    vim.fn.jobstop(job_id)
    vim.api.nvim_buf_delete(bufnr, { force = true })
end


local function resizeTerminal(new_height, direction)
    if table.getn(buf_ids) == 0 then
        print("No open terminals")
        return
    end

    local winid = buf_ids[table.getn(buf_ids)]["winid"]

    if direction == "DEFAULT" then
        new_height = term_height
    elseif direction == "UP" then
        new_height = vim.api.nvim_win_get_height(winid) + new_height
    elseif direction == "DOWN" then
        new_height = vim.api.nvim_win_get_height(winid) - new_height
    end

    vim.api.nvim_win_set_height(winid, new_height)
end


-----------------------------------------------------------
-- => Mappings
-----------------------------------------------------------

-- Opens new terminal
vim.keymap.set("n", "<leader>n", function()
    openTerminal()
end) 

-- Sends keystroke to newest open terminal
vim.keymap.set("n", "<leader>m", function()
    executeCommand(false)
end)

-- Send keystroke AND enter newest open terminal
vim.keymap.set("n", "<leader>M", function()
    executeCommand(true)
end)

-- Closes the newst open terminal
vim.keymap.set("n", "<leader>N", function()
    closeTerminal()
end)


-----------------------------------------------------------
-- => Height mappings
-----------------------------------------------------------

--- !!!!!!!
---  Look into Hydra.nvim for MUCH better keymaps!
--- !!!!!!!

-- Resizes terminal to default height
vim.keymap.set("n", "<leader>tr", function()
    resizeTerminal(0, "DEFAULT")
end)

-- Resizez terminal down
vim.keymap.set("n", "<leader>tj", function()
    resizeTerminal(1, "DOWN")
end)

-- Resizez terminal up
vim.keymap.set("n", "<leader>tk", function()
    resizeTerminal(1, "UP")
end)
