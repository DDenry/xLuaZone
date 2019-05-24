---
--- Created by DDenry.
--- DateTime: 2019/4/19 18:24
---

---进度条
local entranceProgress = FirstCanvas.transform:Find("Overlay/Loading/Slider"):GetComponent("Slider")

local Require = {}

---Require[]
Require.requires = self.gameObject:GetComponent(typeof(CS.com.MiniProgram.Hotfix.CustomLuaBehaviour)).luaScripts

Require.hasRequire = 0

Require.totalRequires = 0

Require.hasPreloaded = false

---随机数列的种子
math.randomseed(os.time())

---进度条速率
local delta = 0.1

function awake()
    ---向网络检测是否有脚本更新
end

Require.CSharpWeight = CS.Reconstruct.Scripts.Hotfix.LuaScriptHotfix.weight

function start()
    print("<[Preload].lua> has started!")

    --
    Require.totalRequires = Require.requires.Length + Require.CSharpWeight

end

function LuaLoadRequire()
    print("Lua load require group!")

    --获取热更后的脚本
    Require.requires = CS.Reconstruct.Scripts.System.SystemService:GetInstance().scriptRequires

    --
    Require.totalRequires = Require.requires.Length + Require.hasRequire

    ---防止时序问题，preload所有脚本
    for i = 0, Require.requires.Length - 1 do
        --CustomLuaLoader.Require
        CS.com.MiniProgram.Hotfix.CustomLuaLoader:GetInstance():RequireScript(Require.requires[i])
    end

    ---加载RequireGroup
    for i = 0, Require.requires.Length - 1 do

        Require[Require.requires[i].name] = Require.requires[i].value

        --需要自动加载
        if Require.requires[i].autoRequire then

            --lua require
            Require[Require.requires[i].name] = require(Require.requires[i].name)

            if Require[Require.requires[i].name] then

                Require.hasRequire = Require.hasRequire + 1

            end
            --无需自动加载
        else
            Require[Require.requires[i].name] = Require.requires[i].value
            --
            Require.hasRequire = Require.hasRequire + 1
        end
    end
end

function update()

    if not Require.hasPreloaded then

        --等待异步权重
        if CS.Reconstruct.Scripts.Hotfix.LuaScriptHotfix.weight ~= 0 then
            Require.hasRequire = Require.CSharpWeight - CS.Reconstruct.Scripts.Hotfix.LuaScriptHotfix.weight
        end

        --更新进度
        if entranceProgress.value < (Require.hasRequire / Require.totalRequires) then

            entranceProgress.value = entranceProgress.value + (delta * math.random(3)) * CS.UnityEngine.Time.deltaTime

            --进度条加载完毕
        elseif entranceProgress.value == 1.0 then

            print("[HOTFIX] Program preload logic has loaded!")

            Require.hasPreloaded = true

            --开启界面逻辑
            Require['[LogicMasterController].lua'] = require('[LogicMasterController].lua')

            Require['[LogicMasterController].lua'].Start()
        end

    end

end