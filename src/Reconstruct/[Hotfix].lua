---
--- Created by DDenry.
--- DateTime: 2019/4/29 13:25
---

local Hotfix = {}

function Hotfix.RequireFailed()

    local uniqueLuaEnv = CS.com.MiniProgram.Hotfix.CustomLuaLoader.GetInstance().luaEnv

    uniqueLuaEnv:DoString("xlua.hotfix(CS.com.MiniProgram.Hotfix.CustomLuaLoader,'RequireFailed',function(self,filename)print('<Hotfix> :' .. filename .. ' required failed!')end)")

end

return Hotfix