---
--- Created by DDenry.
--- DateTime: 2018/2/8 17:35
---
local Application = CS.UnityEngine.Application
local Vuforia = CS.Vuforia
local GameObject = CS.UnityEngine.GameObject
local SceneManager = CS.UnityEngine.SceneManagement.SceneManager
local XLuaLoader = GameObject.Find("XLuaLoader").gameObject:GetComponent(typeof(CS.XLuaLoader))
local CameraBG = GameObject.Find("Root").transform:Find("Models/Camera BG").gameObject
function start()
    print("ErrorController_Start!")
    --关闭所有Lua脚本
    local rootGameObjects = SceneManager.GetActiveScene():GetRootGameObjects()
    for i = 0,rootGameObjects.Length - 1 do
        local xluBehaviours = rootGameObjects[i]:GetComponentsInChildren(typeof(CS.XLuaBehaviour))
        for j = 0,xluBehaviours.Length - 1 do
            --
            xluBehaviours[j].enabled = false
        end
    end
end

--
function ondisable()
    print("ErrorController_Disable!")
    --
    if _Global:GetData("RunningType") == "Single" then
        BackButton:GetComponent("Button").onClick:AddListener(function()
            Application.Quit()
        end)
    else
        BackButton:GetComponent("Button").onClick:AddListener(function()
            XLuaLoader:Back()
        end)
    end

    --TODO:关闭场景中相机
    if Vuforia.VuforiaBehaviour.Instance ~= nil then
        Vuforia.VuforiaBehaviour.Instance.gameObject:SetActive(false)
    end

    if CameraBG.activeSelf then
        CameraBG:SetActive(false)
    end
    --
    local errorContent = "Error!"
    if _Global:GetData("ErrorContent") ~= nil then
        errorContent = _Global:GetData("ErrorContent")
        --判断错误类型
        if string.find(errorContent,"404 Not Found") ~= nil then
            errorContent = "重要资源文件缺失，请退出！"
        elseif string.find(errorContent,"UnknownEventName:") ~= nil then
            errorContent = "发现未知异常，请退出！"
        end
    else errorContent = "未捕捉到错误详情，请退出~"
    end

    --显示错误详情
    PromptPanel.transform:Find("Main Title/Main Title Text").gameObject:GetComponent("Text").text = errorContent
    PromptPanel.gameObject:SetActive(true)
    PreLoad.gameObject:GetComponentInChildren(typeof(CS.UnityEngine.UI.Text)).text = "Failed"
end