-----------------------------------------------------------
-- => Variables
-----------------------------------------------------------

local buf_ids = {}


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
        table.insert(buf_ids, args.buf)
        
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
            if v == bufnr then
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


local function getBufferWindowId(bufnr)
    local windows = vim.api.nvim_list_wins()
    
    for _,win_id in ipairs(windows) do
        local win_buf = vim.api.nvim_win_get_buf(win_id)
        if win_buf == bufnr then
            return win_id
        end
    end
    return nil
end


-----------------------------------------------------------
-- => KeyMap functions
-----------------------------------------------------------


local openTerminal = function()
    vim.cmd.new()
    vim.cmd.term()
    vim.cmd.wincmd("J")
    vim.api.nvim_win_set_height(0, 7)
end


local function executeCommand(enter_terminal)
    if table.getn(buf_ids) == 0 then
        openTerminal()

        -- Makes you NOT jump into the terminal
        vim.cmd("wincmd p")
        
        if not enter_terminal then
            vim.api.nvim_input("<esc>")
        end
    end

    -- Get the job_id 
    bufnr = buf_ids[table.getn(buf_ids)]
    job_id = vim.api.nvim_buf_get_var(bufnr, "terminal_job_id")

    -------------------
    --- Needs update to be able to do user input (EOF error)
    -------------------

    -- Construct and send terminal input data
    cmd_str = getCmdStr()
    vim.fn.chansend( job_id, { cmd_str, "" })

    -- Ensure autoscroll functionality
    vim.api.nvim_buf_call(bufnr, function()
        vim.cmd("norm G")
    end)

    if enter_terminal then
        win_id = getBufferWindowId(bufnr)
        vim.api.nvim_set_current_win(win_id)
        vim.cmd("startinsert")
    end
end


local function closeTerminal()
    if table.getn(buf_ids) == 0 then
        print("No open terminals")
        return
    end

    bufnr = buf_ids[table.getn(buf_ids)]
    job_id = vim.api.nvim_buf_get_var(bufnr, "terminal_job_id")

    vim.fn.jobstop(job_id)
    vim.api.nvim_buf_delete(bufnr, { force = true })
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

