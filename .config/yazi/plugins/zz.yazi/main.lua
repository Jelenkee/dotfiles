local function entry()

    local value, event = ya.input {
        title = "Search with z",
        position = { "top-center", y = 3, w = 30 },
    }

    local child, err = Command("zz")
        :arg("-1")
        :arg(value)
        :stdout(Command.PIPED)
        :stderr(Command.INHERIT)
        :spawn()
        
    if not child then
        return ya.notify { title = "", content = "Failed zz", timeout = 2.0}
    end

    local output, err = child:wait_with_output()

    if not output then
        return ya.notify { title = "", content = "Failed zz output", timeout = 2.0}
    end

	local target = output.stdout:gsub("\n$", "")
	if target ~= "" then
		ya.manager_emit("cd", { target })
    else
        ya.notify { title = "", content = "Cannot find " .. value, timeout = 3.0, level = "warn"}
	end
end

return { entry = entry }