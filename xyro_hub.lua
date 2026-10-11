local url = "https://raw.githubusercontent.com/USERNAME/xyro-hub/main/xyro.lua"

local success, result = pcall(function()
    return game:HttpGet(url)
end)

if success and result and #result > 0 then
    local fn, err = loadstring(result)
    if fn then
        fn()
    else
        warn("[Xyro Hub] Load error: " .. tostring(err))
    end
else
    warn("[Xyro Hub] Failed to fetch script from GitHub")
end