--TODO: Here's patch codes.
---2019年1月9日 14点37分
local GameObject = CS.UnityEngine.GameObject
local content = "The solution will come out soon while the bug checked out has fixed!"
local Debug = CS.UnityEngine.Debug
local version_patch = "1.1"

---
--- 补丁版本号：1.1
--- 该版本兼容场景版本号1.0/1.1的场景
---

local yield_return = (require 'cs_coroutine').yield_return
local GameObject = CS.UnityEngine.GameObject

local luaBehaviours = {
    ['Camera_AutoFocus'] = nil,
    ['Enter'] = nil,
    ['Main'] = nil,
    ['Function'] = nil,
    ['Error'] = nil,
    ['FingerOperator_Camera'] = nil,
    ['FingerOperator_Model'] = nil,
    ['MulModelList_DataSource'] = nil
}


--显示错误提示，退出子应用
local ErrorShow = function()
    --
    local overlayCanvas = GameObject.Find("Root/UI/Overlay Canvas")
    overlayCanvas.transform:Find("ErrorUI").gameObject:SetActive(true)
    overlayCanvas.transform:Find("PreLoad").gameObject:SetActive(true)
    overlayCanvas.transform:Find("PreLoad/Text").gameObject:SetActive(true)
    overlayCanvas.transform:Find("PreLoad/Text"):GetComponent("Text").text = content
end

--TODO:从指定地址加载bundle
local LoadBundle = coroutine.resume(coroutine.create(
        function()
            --更新脚本bundle地址
            local uri = "file://D:/Project/Code/MiniProgram/Assets/AssetBundle/assetsbundle"

            print("Script assetsbundle's path is " .. uri)

            local webRequest = CS.UnityEngine.Networking.UnityWebRequestAssetBundle.GetAssetBundle(uri)

            yield_return(webRequest:Send())

            local assetBundle = CS.UnityEngine.Networking.DownloadHandlerAssetBundle.GetContent(webRequest)

            --[同步]LoadAllAssets()
            --[异步]从assetBundle中加载所需资源
            local assets = assetBundle:LoadAllAssetsAsync()

            yield_return(assets)

            print("AssetsBundle Loaded,included " .. assets.allAssets.Length .. " assets!")

            --
            local rootGameObjects = CS.UnityEngine.SceneManagement.SceneManager:GetActiveScene():GetRootGameObjects()

            for i = 0, rootGameObjects.Length - 1 do
                if rootGameObjects[i].name == "LuaController_Enter" then
                    if rootGameObjects[i]:GetComponent(typeof(CS.XLuaBehaviour)) ~= nil then
                        --Enter.lua
                        luaBehaviours['Enter'] = rootGameObjects[i]:GetComponent(typeof(CS.XLuaBehaviour))
                    end
                elseif rootGameObjects[i].name == "Root" then
                    if rootGameObjects[i].transform:Find("Models/Contents"):GetComponent(typeof(CS.XLuaBehaviour)) ~= nil then
                        --FingerOperator_Model.lua
                        luaBehaviours['FingerOperator_Model'] = rootGameObjects[i].transform:Find("Models/Contents"):GetComponent(typeof(CS.XLuaBehaviour))
                    end

                    if rootGameObjects[i].transform:Find("Models/Camera"):GetComponent(typeof(CS.XLuaBehaviour)) ~= nil then
                        --FingerOperator_Camera.lua
                        luaBehaviours['FingerOperator_Camera'] = rootGameObjects[i].transform:Find("Models/Camera"):GetComponent(typeof(CS.XLuaBehaviour))
                    end

                    if rootGameObjects[i].transform:Find("UI/Main UI Canvas/MulModelList"):GetComponent(typeof(CS.XLuaBehaviour)) ~= nil then
                        --FingerOperator_Camera.lua
                        luaBehaviours['MulModelList_DataSource'] = rootGameObjects[i].transform:Find("UI/Main UI Canvas/MulModelList"):GetComponent(typeof(CS.XLuaBehaviour))
                    end

                elseif rootGameObjects[i].name == "MainController" then
                    if rootGameObjects[i].transform:Find("LuaBehavior_Main"):GetComponent(typeof(CS.XLuaBehaviour)) ~= nil then
                        luaBehaviours['Main'] = rootGameObjects[i].transform:Find("LuaBehavior_Main"):GetComponent(typeof(CS.XLuaBehaviour))
                    end

                    if rootGameObjects[i].transform:Find("LuaController_Function"):GetComponent(typeof(CS.XLuaBehaviour)) ~= nil then
                        luaBehaviours['Function'] = rootGameObjects[i].transform:Find("LuaController_Function"):GetComponent(typeof(CS.XLuaBehaviour))
                    end

                    if rootGameObjects[i].transform:Find("LuaController_ErrorHandler"):GetComponent(typeof(CS.XLuaBehaviour)) ~= nil then
                        luaBehaviours['Error'] = rootGameObjects[i].transform:Find("LuaController_ErrorHandler"):GetComponent(typeof(CS.XLuaBehaviour))
                    end

                    if rootGameObjects[i].transform:Find("LuaController_CameraAutoFocus"):GetComponent(typeof(CS.XLuaBehaviour)) ~= nil then
                        luaBehaviours['Camera_AutoFocus'] = rootGameObjects[i].transform:Find("LuaController_CameraAutoFocus"):GetComponent(typeof(CS.XLuaBehaviour))
                    end
                end
            end

            for i = 0, assets.allAssets.Length - 1 do
                --
                local _name = assets.allAssets[i].name:sub(1, assets.allAssets[i].name:find(".lua") - 1)

                if luaBehaviours[_name] ~= nil then

                    luaBehaviours[_name].luaScript = assets.allAssets[i]

                    print("Xlua script " .. assets.allAssets[i].name .. " has updated!")
                else
                    Debug.LogWarning("Xlua script " .. assets.allAssets[i].name .. " has no matched!")
                end

            end

            --
            assetBundle:Unload(false)

            --开启程序
            self.enter:SetActive(true)
        end
))

--
print("Checked Patch Version:" .. version_patch)

--判断版本号，是否需要应用该补丁
if self.version ~= nil then
    --
    local V = tonumber(self.version:sub(1, self.version:find(".")))
    local C = tonumber(self.version:sub(self.version:find(".") + 1))

    local v = tonumber(version_patch:sub(1, version_patch:find(".")))
    local c = tonumber(version_patch:sub(version_patch:find(".") + 1))

    --判断大版本号
    if V == v then
        --判断小版本号
        if C - c <= 0 then
            --程序在运行过程中检测到补丁
            if self.enter.activeSelf then
                --显示错误提示
                ErrorShow()
                --
            else
                print("Do something~")
                --
                assert(LoadBundle)
            end
            --正常执行程序
        else
            print("Current patch is not matched with this scene!")
            --程序入口
            self.enter:SetActive(true)
        end
    else
        print("Current patch is not matched with this scene!")
        --程序入口
        self.enter:SetActive(true)
    end
    --
else
    --显示错误提示
    ErrorShow()
end