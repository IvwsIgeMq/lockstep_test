
local MyApp = class("MyApp", cc.load("mvc").AppBase)
import(".Common")

function MyApp:onCreate()
    -- math.randomseed(os.time())
end

return MyApp
