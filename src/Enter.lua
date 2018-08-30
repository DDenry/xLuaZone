---
--- Created by DDenry.
--- DateTime: 2018/1/2 15:39
---
local SceneManager = CS.UnityEngine.SceneManagement.SceneManager
local GameObject = CS.UnityEngine.GameObject
local Destroy = CS.UnityEngine.Object.Destroy
local SSMessageManager = CS.SubScene.SSMessageManager.Instance
local yield_return = (require 'cs_coroutine').yield_return
--
function start()
    assert(coroutine.resume(coroutine.create(function()
        --[[
                local webRequest = CS.UnityEngine.Networking.UnityWebRequest.Get("http://gzdl.chu-jiao.com/Loading%3F.jpg?¿¿¿" .. math.random())

                yield_return(webRequest:Send())

                --
                if webRequest.error == nil then
                    local texture2D = CS.UnityEngine.Texture2D(80, 80, CS.UnityEngine.TextureFormat.PVRTC_RGBA4, false, true)
                    if texture2D:LoadImage(webRequest.downloadHandler.data) then
                        local rawImage = GameObject.Find("Root/UI/Overlay Canvas/PreLoad"):GetComponent("RawImage")
                        rawImage.texture = texture2D
                        --隐藏文字信息
                        rawImage.transform:Find("Text"):GetComponent("Text").text = ""
                    end
                else
                    print("Error", webRequest.error)
                end
                ]]

        --设置Loading图案
        local www = CS.UnityEngine.WWW("http://gzdl.chu-jiao.com/Loading.jpg?¿¿¿" .. math.random())

        yield_return(www)

        if www.error == nil then
            local rawImage = GameObject.Find("Root/UI/Overlay Canvas/PreLoad"):GetComponent("RawImage")
            rawImage.texture = www.texture
            --隐藏文字信息
            rawImage.transform:Find("Text"):GetComponent("Text").text = ""
        end
        --
        www = nil

        --去除Camera上的AudioListener
        local audioListeners = GameObject.FindObjectsOfType(typeof(CS.UnityEngine.AudioListener))

        --如果场景中存在两个及以上AudioListener
        if audioListeners.Length > 1 then
            for i = 0, audioListeners.Length - 1 do
                if audioListeners[i].name ~= "Main Storyboard" then
                    --去除除了MainStoryboard上的AudioListener
                    Destroy(audioListeners[i]:GetComponent("AudioListener"))
                end
            end
        end

        --
        if SceneManager.sceneCount == 1 and SceneManager.GetActiveScene().name == "scene" then
            --设置自应用运行方式为single
            _Global:SetData("RunningType", "Single")

            local rootGameObjects = SceneManager.GetActiveScene():GetRootGameObjects()
            for i = 0, rootGameObjects.Length - 1 do
                if rootGameObjects[i].name == "MainController" then
                    --
                    rootGameObjects[i]:SetActive(true)
                    break
                end
            end
        else
            print("Scene named 'scene' no found! ")
        end

    end)))
end

function ondestroy()
    if _Global:GetData("RunningType") ~= nil then
        _Global:ReleseData("RunningType")
    end
    --
    SSMessageManager:ReceiveMessage("Clear")
    --
    collectgarbage("collect")
    CS.System.GC.Collect()
end