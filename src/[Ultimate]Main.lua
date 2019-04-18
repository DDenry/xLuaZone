---
--- Created by DDenry.
--- DateTime: 2017/6/19 22:18
---

local BasePackage = require('[BasePackage]')
local util = require 'xlua.util'
local yield_return = (require 'cs_coroutine').yield_return

local SSMessageManager = CS.SubScene.SSMessageManager.Instance

local COMMON = {}
local DEBUG = {}
local CALLBACK = {}
local PROCESS = {}
local PROCEDURE = {}
local MEDIA = {}
local AUDIO = {}
local VIDEO = {}
local USERINTERFACE = {}
local WEBVIEW = {}
local VUFORIA = {}
local APPTYPE = {
    DEBUG = 0,
    RELEASE = 1
}

--[[
    任务流程：

]]

local _id = 0

--Entity Task
local Task = {
    id = -1,
    name = "",
    runnable = nil,
    priority = nil,
    callback = nil
}

--实例化Task
function Task:new(...)

    --没有参数
    if select("#", ...) == 0 then
        --抛出错误异常
        COMMON.Console("LogError", "ERROR", "TASK CREATE FAILED!")

        return o
    elseif select("#", ...) > 0 then
        --id自增
        _id = _id + 1
        self.id = _id
    end

    --带有name参数
    if select("#", ...) >= 1 then
        if select(1, ...) ~= nil then
            self.name = select(1, ...)
            --
            LogInfo("TASK CREATE " .. self.id, self.name)
        end
    end

    --带有name,runnable参数
    if select("#", ...) >= 2 then
        if select(2, ...) ~= nil then
            self.runnable = select(2, ...)
        end
    end

    --带有name,runnable,callback
    if select("#", ...) >= 3 then
        if select(3, ...) ~= nil then
            self.callback = select(3, ...)
        end
    end

    --带有name,runnable,callback,priority参数
    if select("#", ...) >= 4 then
        if select(4, ...) ~= nil then
            self.priority = select(4, ...)
        end
    end

    local o = {
        id = self.id,
        name = self.name,
        runnable = self.runnable,
        callback = self.callback,
        priority = self.priority
    }

    --元表保护
    self.__metatable = "Sorry, u cannot do this!"

    --元表
    setmetatable(o, self)
    self.__index = self

    return o
end

--任务队列
PROCESS.TaskQueue = {}

PROCESS.TaskPrepared = {}

--需要执行的task
PROCESS.ExecutedTask = {
    id = nil,
    name = ""
}

--构建协程执行Task
function Task:PostInQueue()
    --合法的Task
    if self.id ~= nil then

        --将该Task压入执行队列
        LogInfo("POST TASK " .. self.id, self.name)

        PROCESS.TaskQueue[#PROCESS.TaskQueue + 1] = {
            task = self,
            --任务状态
            state = "Pending"
        }
        --执行Task
        PROCESS.Execute()
    else
        LogError("Illegal Task Cannot be Executed!")
    end
end

--
local TaskDoneListener = CS.EzComponents.StringEvent()

--任务结束回调
function PROCESS.TaskDone(event)
    PROCESS.ListenProcess({ PROCESS.ExecutedTask.name }, event, "DONE")
end

--执行Task队列的任务
function PROCESS.Execute()
    local haveDoneCount = 0
    --
    local pendingTasks = {}

    for i, item in pairs(PROCESS.TaskQueue) do
        local task = item.task
        if item.state == "Pending" then
            --
            pendingTasks[#pendingTasks + 1] = task
        elseif item.state == "Processing" then
            --
            LogInfo("Task " .. i .. " is processing, waiting!")
            return
        elseif item.state == "Done" then
            --
            haveDoneCount = haveDoneCount + 1
        end
    end

    LogInfo("Total " .. (#PROCESS.TaskQueue - haveDoneCount) .. ((((#PROCESS.TaskQueue - haveDoneCount) > 1) and " tasks") or " task") .. " in current queue!")

    local _task

    --选出PendingTask中优先级最高的task
    if #pendingTasks <= 1 then
        _task = pendingTasks[1]
    else
        for i = 1, #pendingTasks - 1 do
            if pendingTasks[i].priority <= pendingTasks[i + 1].priority then
                _task = pendingTasks[i]
            else
                _task = pendingTasks[i + 1]
            end
        end
    end

    --
    if _task ~= nil then
        if _task.runnable ~= nil then
            LogInfo("EXECUTE TASK " .. _task.id, _task.name)
            LogInfo("TASK PRIORITY is " .. _task.priority)

            PROCESS.ExecutedTask = {
                id = _task.id,
                name = _task.name
            }

            --添加Task的进度监听
            if PROCESS.TaskPrepared[_task.name] == nil then
                PROCESS.TaskPrepared[_task.name] = {
                    leader = nil,
                    event = {},
                    neededResponseCount = 0,
                    totalAddedCount = 0,
                    callBack = _task.callback
                }
            end

            --修改任务状态
            PROCESS.TaskQueue[_task.id].state = "Processing"

            --
            LogInfo("EXECUTE TASK " .. PROCESS.TaskQueue[_task.id].task.id, PROCESS.TaskQueue[_task.id].task.name)
            --
            if type(_task.runnable) == "table" then
                local cases = {}
                for i, case in pairs(_task.runnable) do
                    --
                    PROCESS.ListenProcess({ _task.name }, "Task " .. _task.id .. "'s case " .. i, "ADD")

                    --添加Case进度监听
                    PROCESS.TaskPrepared["Task " .. _task.id .. "'s case " .. i] = {
                        leader = _task.name,
                        event = {},
                        neededResponseCount = 0,
                        totalAddedCount = 0
                    }
                    --
                    cases[#cases + 1] = case
                end

                --执行
                for i, case in pairs(cases) do
                    assert(coroutine.resume(coroutine.create(function()
                        --每相隔1frame执行
                        yield_return(1)
                        --
                        cases[i]()
                    end)))
                end
            else
                --
                PROCESS.ListenProcess({ _task.name }, "task " .. _task.id, "ADD")
                --
                assert(coroutine.resume(coroutine.create(function()
                    --每相隔1frame执行
                    yield_return(1)
                    --
                    _task.runnable()
                end)))
            end
        end
    end
end

--析构
function Task:Destructor()
    --self.id = nil
    self.name = nil
    self.runnable = nil
    self.callback = nil
    self.priority = nil
    --self.__index.name = nil
    self.__index.runnable = nil
    self.__index.callback = nil
    self.__index.priority = nil

    LogInfo("TASK DESTRUCTOR", self.id)
    --
    self = nil
    --调用Lua垃圾回收
    COMMON.CollectGarbage()
end

--
local Application = CS.UnityEngine.Application
local RuntimePlatform = CS.UnityEngine.RuntimePlatform
local Screen = CS.UnityEngine.Screen
local GameObject = CS.UnityEngine.GameObject
local Debug = CS.UnityEngine.Debug
local Color = CS.UnityEngine.Color
local Image = CS.UnityEngine.UI.Image
local Transform = CS.UnityEngine.Transform
local Quaternion = CS.UnityEngine.Quaternion
local Vector2 = CS.UnityEngine.Vector2
local Vector3 = CS.UnityEngine.Vector3
local Object = CS.UnityEngine.Object
local Destroy = Object.Destroy
local Resources = CS.UnityEngine.Resources
local PlayerPrefs = CS.UnityEngine.PlayerPrefs
local File = CS.System.IO.File
local FileInfo = CS.System.IO.FileInfo
local JSON = CS.SimpleJSON.JSON
local Vuforia = CS.Vuforia
local VuforiaBehaviour = Vuforia.VuforiaBehaviour
local VuforiaConfiguration = Vuforia.VuforiaConfiguration
local Input = CS.UnityEngine.Input
local Time = CS.UnityEngine.Time
--
local MainStoryboard = GameObject.Find("Main Storyboard")
local EzStoryboardPlayer = MainStoryboard:GetComponent("EzStoryboardPlayer")

--Configs
local Configs = GameObject.Find("Configs")
local UniWebView_FirstPage = Configs.transform:Find("UniWebView_FirstPage").gameObject
local UniWebView_MulModelPage = Configs.transform:Find("UniWebView_MulModelPage").gameObject
local CallbackFromWebToUnity_MulModelPage
--Root
local Root = GameObject.Find("Root")
--Root->UI
local UI = Root.transform:Find("UI").gameObject

--Root->UI->Main UI Canvas
local MainUICanvas = UI.transform:Find("Main UI Canvas").gameObject
local TitlePanel = MainUICanvas.transform:Find("Title Panel").gameObject
local H5Load = MainUICanvas.transform:Find("H5Load").gameObject
local Panel = MainUICanvas.transform:Find("Title Panel/Panel").gameObject
local MainTitle = MainUICanvas.transform:Find("Title Panel/Main Title").gameObject
local MainTitleText = MainTitle.transform:Find("Main Title Text").gameObject:GetComponent("Text")
local MainSubtitle = MainUICanvas.transform:Find("Title Panel/Main Subtitle").gameObject
local MainText = MainSubtitle.transform:Find("Main Text").gameObject:GetComponent("Text")
local MainSubtitleText = MainSubtitle.transform:Find("Main Subtitle Text").gameObject:GetComponent("Text")
local ButtonShowModel = MainUICanvas.transform:Find("Title Panel/Main Subtitle/ButtonShowModel").gameObject:GetComponent("Button")
local MulModelList = MainUICanvas.transform:Find("MulModelList").gameObject
local TitleImage = MainUICanvas.transform:Find("Title Panel").gameObject:GetComponent("Image")

--Overlay Canvas
local OverlayCanvas = UI.transform:Find("Overlay Canvas").gameObject
local PreLoad = OverlayCanvas.transform:Find("PreLoad").gameObject
local Loading = OverlayCanvas.transform:Find("Loading").gameObject
local UniWebViewPanelButton = OverlayCanvas.transform:Find("UniWebViewPanel").gameObject:GetComponent("Button")

--Root->Models
local Models = Root.transform:Find("Models").gameObject
local Contents = Models.transform:Find("Contents").gameObject
local Prefab_ModelLoader = Contents.transform:Find("Prefab-ModelLoader").gameObject

local PageList = MainUICanvas.transform:Find("PageList").gameObject
local PageListScrollRect = PageList.transform:Find("TileView/ScrollRect").gameObject
local CustomTileView = PageList.transform:Find("TileView").gameObject:GetComponent(typeof(CS.SubScene.CustomTileView))
local CustomTileViewDataSource = PageList.transform:Find("TileView").gameObject:GetComponent(typeof(CS.SubScene.CustomTileViewDataSource))
--
local StudioDataManager = CS.SceneStudio.StudioDataManager.Instance
local CallbackFromWebToUnity
local CameraBG = Models.transform:Find("Camera BG").gameObject
local CameraModel = Models.transform:Find("Camera").gameObject
local CameraAR

--子应用返回到主应用时发送消息
local XLuaLoader = GameObject.Find("XLuaLoader").gameObject:GetComponent(typeof(CS.XLuaLoader))
--local PageInfoManager = GameObject.Find("Main Storyboard"):GetComponent(typeof(CS.SubScene.PageInfoManager))
local PageInfoManager = CS.SubScene.PageInfoManager.Instance

--Configs
local DataSetLoader = Configs.transform:Find("DataSetLoader").gameObject:GetComponent(typeof(CS.EzComponents.Vuforia.DataSetLoader))

--Back Button
local ButtonBackPanelButton = GameObject.Find("Root/UI/Main UI Canvas/Title Panel/BackButtonPanel"):GetComponent("Button")
--
local ButtonExtendArea = MainUICanvas.transform:Find("Title Panel/ButtonExtendArea").gameObject:GetComponent("Button")

--List Button Group
local ListButtonGroup = MainUICanvas.transform:Find("Title Panel/List Button").gameObject
--VR Button
local ButtonVR = MainUICanvas.transform:Find("Title Panel/List Button/VR Button").gameObject:GetComponent("Button")
--AR Button
local ButtonAR = MainUICanvas.transform:Find("Title Panel/List Button/AR Button").gameObject:GetComponent("Button")

local Exiting = GameObject.Find("Root/UI/Overlay Canvas").transform:Find("Exiting").gameObject
local ButtonExit = Exiting.transform:Find("BG/Confirm").gameObject:GetComponent("Button")
local ButtonCancel = Exiting.transform:Find("BG/Cancel").gameObject:GetComponent("Button")

--获取设备屏幕分辨率
local screenHeight = CS.UnityEngine.Screen.height
local screenWidth = CS.UnityEngine.Screen.width

--应用版本类型(Default is APPTYPE.DEBUG)
local appVersionType = APPTYPE.DEBUG

--配置文件参数
local trackerType = "Once"
local sceneType = "AR&VR"

--默认主题色为酸橙绿
local themeColor = {
    r = 50 / 255.0,
    g = 205 / 255.0,
    b = 50 / 255.0,
    a = 1
}
local autoShowPoint = false
local haveViewTransfer = false
local defaultView = "Fake"

local currentMarkerGameObject

--RootPath
local rootPath
local wwwHeadPath
local wwwAssetPath

--ChildAppId
local childAppId
local versionType
local childAppName

--
local vuforiaXmlPath
local vuforiaDatPath

-- -1代表退出子应用 0代表返回到AR 1代表返回到VR
local backType = -1
local loadedType = 0

--
local loadedModel = false
local isSingleType = false
local pageListType
local pageListType_H5 = "pageListType_H5"
local pageListType_UIWidget = "pageListType_UIWidget"

local listenerRegisteredId = {}
local listenerRegistered = {}

local urlParameters = {}
local doType
local urlHead
local pageIndex
local assetBundle_url
local sceneName
local pageName
local assetBundleName
local modelName
local haveMulModel
--
local sectionNum = 0
local canControl = false
--
local sectionMode = "Single"

--
local table_MarkerToModel = {}

local defaultOrderHtml

local backGroundColor = {
    r = TitleImage.color.r,
    g = TitleImage.color.g,
    b = TitleImage.color.b,
    a = TitleImage.color.a
}

--AUDIO
AUDIO.audioSource = Root.transform:Find("Functions/AudioPlayerController"):GetComponent("AudioSource")

--VIDEO Variable
MEDIA.UI = MainUICanvas.transform:Find("MediaUI").gameObject
--videoPlayer
VIDEO.mediaQuad = Root.transform:Find("TmpSave/MediaQuad")

VIDEO.videoPlayer = Root.transform:Find("Functions/VideoPlayerController"):GetComponent("VideoPlayer")

VIDEO.renderFullScreenRawImage = MEDIA.UI.transform:Find("VideoRender"):GetComponentInChildren(typeof(CS.UnityEngine.UI.RawImage))
VIDEO.renderFullScreenButton = MEDIA.UI.transform:Find("VideoRender"):GetComponent("Button")
VIDEO.quitFullScreenButton = MEDIA.UI.transform:Find("VideoRender/QuitFullScreen"):GetComponent("Button")

--progressSlider
MEDIA.progressSlider = MEDIA.UI.transform:Find("NavigationBar/ProgressBar/Slider"):GetComponent("Slider")
--
MEDIA.fillContent = MEDIA.progressSlider.gameObject.transform:Find("Fill Area/Fill"):GetComponent("Image")
--CurrentTimeStamp
MEDIA.currentTimeStamp = MEDIA.UI.transform:Find("NavigationBar/ProgressBar/CurrentTimeStamp"):GetComponent("Text")
--TotalTimeStamp
MEDIA.totalTimeStamp = MEDIA.UI.transform:Find("NavigationBar/ProgressBar/TotalTimeStamp"):GetComponent("Text")
--buttonPlay
MEDIA.buttonPlay = MEDIA.UI.transform:Find("NavigationBar/ButtonController/ButtonPlay"):GetComponent("Button")
--buttonPause
MEDIA.buttonPause = MEDIA.UI.transform:Find("NavigationBar/ButtonController/ButtonPause"):GetComponent("Button")

MEDIA.switchPanel = MEDIA.UI.transform:Find("SwitchPanel")
MEDIA.previousButton = MEDIA.switchPanel.transform:Find("Previous"):GetComponent("Button")
MEDIA.nextButton = MEDIA.switchPanel.transform:Find("Next"):GetComponent("Button")

--
function onenable()
    LogInfo("MainController_Enable!")

    --释放无用资源
    Resources.UnloadUnusedAssets()

    --判断ARCamera licenseKey是否为空
    if (VuforiaConfiguration.Instance.Vuforia.LicenseKey:trim() == "") then
        --
        LogError("Vuforia's license key is empty!")
    end

    --TODO:修改参数
    PlayerPrefs.SetString("subApp_childApp", "SHOW")
end

--
function start()
    LogInfo("MainController_Start!")

    --Require
    if BasePackage then
        print("Require [BasePackage] succeed!")
    else
        print("Require [BasePackage] failed!")
    end

    --设置垃圾自动回收
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul")

    --获取运行方式
    if _Global:GetData("RunningType") ~= nil then
        if _Global:GetData("RunningType") == "Single" then
            --子应用单独运行
            isSingleType = true
            LogInfo("RunningType is single!")
        else
            LogInfo("RunningType is not single!")
            --带主应用版本
            isSingleType = false
        end
    else
        LogInfo("RunningType is not single!")
        isSingleType = false
    end

    --获取到主应用传递来的路径
    rootPath = EzStoryboardPlayer.Path

    --
    PROCESS.Try2FindChildAppId()

    package.path = package.path .. ';' .. rootPath .. "?.lua"

    print("package.path", package.path)

    --设置资源的绝对路径
    _Global:SetData("AbsolutePath", EzStoryboardPlayer.Path)

    COMMON.RegisterListener(TaskDoneListener, PROCESS.TaskDone)

    --创建应用Task并执行
    Task     :new("NecessaryConfig", {
        function()
            --判断UI显示方式（适配）
            COMMON.Function2XPCall(PROCESS.SetUIAdapter)

            --判断平台
            COMMON.Function2XPCall(PROCESS.FindVersionType)

            --设置wwwAssetPath
            COMMON.Function2XPCall(PROCESS.SetWWWAssetPath)

            --添加按钮监听
            PROCESS.RegisterUIButtonListener()

            --监听SSMessageManager.LoadModel的回调
            COMMON.RegisterListener(SSMessageManager.LoadModel, CALLBACK.PageListSelected)

            --
            TaskDoneListener:Invoke("Set UI&path")
        end,
        function()
            --加载必需文件subapp_config.json
            local COROUTINE_LoadSubAppConfig = coroutine.create(function(...)
                --
                COMMON.Function2XPCall(PROCESS.TextLoader, wwwAssetPath .. "subapp_config.json")
                --
                local callback = select(1, ...)
                --
                coroutine.yield(callback:Invoke("Load subapp_config"))
            end)
            --
            assert(coroutine.resume(COROUTINE_LoadSubAppConfig, TaskDoneListener))
            --
            COROUTINE_LoadSubAppConfig = nil
        end,
        function()
            --加载可需文件scene_cofnig.json
            local COROUTINE_LoadSceneConfig = coroutine.create(function(...)
                --
                COMMON.Function2XPCall(PROCESS.TextLoader, wwwAssetPath .. "scene_config.json")
                --
                local callback = select(1, ...)
                --
                coroutine.yield(callback:Invoke("Load scene_config"))
            end)
            --
            assert(coroutine.resume(COROUTINE_LoadSceneConfig, TaskDoneListener))
            --
            COROUTINE_LoadSceneConfig = nil
        end
    }
    , nil, 0):PostInQueue()

    --准备场景
    Task           :new("PrepareScene",
            function()
                --设置场景类型
                PROCESS.SwitchScene()
            end, function()
                --显示可操作界面
                PROCESS.ShowOperateUI()
            end, 0):PostInQueue()

end

function LogInfo(...)
    local title = ""
    local message
    --包含参数
    if select("#", ...) > 0 then
        --默认唯一参数时是message
        if select("#", ...) == 1 then
            message = select(1, ...)
            --默认两个参数时，第一个为title，第二个为message
        elseif select("#", ...) == 2 then
            title = select(1, ...)
            message = select(2, ...)
        end
        --Unity Console输出
        COMMON.ConsoleLogInfo("Log", title, message)
    end
end

function LogWarning(...)
    local title = ""
    local message
    --包含参数
    if select("#", ...) > 0 then
        --默认唯一参数时是message
        if select("#", ...) == 1 then
            message = select(1, ...)
            --默认两个参数时，第一个为title，第二个为message
        elseif select("#", ...) == 2 then
            title = select(1, ...)
            message = select(2, ...)
        end
        --Unity Console输出
        COMMON.ConsoleLogInfo("LogWarning", title, message)
    end
end

function LogError(...)
    local title = ""
    local message
    --包含参数
    if select("#", ...) > 0 then
        --默认唯一参数时是message
        if select("#", ...) == 1 then
            message = select(1, ...)
            --默认两个参数时，第一个为title，第二个为message
        elseif select("#", ...) == 2 then
            title = select(1, ...)
            message = select(2, ...)
        end
        --Unity Console输出
        COMMON.ConsoleLogInfo("LogError", title, message)
    end
end

--记录log数据
local log_bytes = ""

---System-Procedure-Functions

--Console Output
function COMMON.ConsoleLogInfo(type, title, message)

    --判断应用版本类型，是否需要输出
    if appVersionType == APPTYPE.RELEASE then
        return
    end

    type = tostring(type)
    title = tostring(title)
    message = tostring(message)

    log_bytes = log_bytes .. " \n" .. "[" .. os.date("%c") .. "]" .. ((type ~= nil and type) or "") .. ((title ~= nil and title) or "") .. ((message ~= nil and message) or "")

    if type == "Log" then
        if title == "" then
            Debug.Log(message)
        else
            Debug.Log(title .. ":       " .. message)
        end
    elseif type == "LogWarning" then
        if title == "" then
            Debug.LogWarning(message)
        else
            Debug.LogWarning(title .. ":        " .. message)
        end
    elseif type == "LogError" then
        if title == "" then
            Debug.LogError(message)
        else
            Debug.LogError(title .. ":      " .. message)
        end
    end
end

--Lua垃圾回收
function COMMON.CollectGarbage()
    LogInfo("<<<<<< Before Collect", collectgarbage("count") .. "K")
    --回收垃圾
    collectgarbage("collect")
    CS.System.GC.Collect()

    LogInfo(">>>>>> After Collect", collectgarbage("count") .. "K")
end

--将函数转换为xpcall调用
function COMMON.Function2XPCall(_function, ...)
    --
    if select("#", ...) > 0 then
        --一个参数
        if select("#", ...) == 1 then
            xpcall(_function, COMMON.ErrorHandler, select(1, ...))
            --两个参数
        elseif select("#", ...) == 2 then
            xpcall(_function, COMMON.ErrorHandler, select(1, ...), select(2, ...))
        end
        --无参数
    else
        xpcall(_function, COMMON.ErrorHandler)
    end
end

--错误处理
function COMMON.ErrorHandler(errorMessage)
    --Unity抛出错误
    Debug.LogError(errorMessage)
end

--注册监听
function COMMON.RegisterListener(self, callBack)

    LogInfo("Registered Listener", self)

    --
    listenerRegisteredId[#listenerRegisteredId + 1] = self

    --将监听添加至listenerRegistered表
    listenerRegistered[#listenerRegistered + 1] = callBack

    --添加监听
    self:AddListener(callBack)

    LogInfo("Current #listenerRegistered", #listenerRegistered)
end

--注销监听
function COMMON.UnregisterListener(...)
    local arg_num = select("#", ...)

    --判断注销监听方式
    --注销所有监听
    if arg_num == 0 then
        for i, listener in pairs(listenerRegisteredId) do
            listener:RemoveAllListeners()
        end

        --
        listenerRegisteredId = {}
        --清空listenerRegistered
        listenerRegistered = {}

        LogInfo("COMMON.UnregisterListener", "All listeners have unregistered!")

        --注销特定listener的所有监听
    elseif arg_num == 1 then
        --获取event
        local event = select(1, ...)

        --
        for i, listener in pairs(listenerRegisteredId) do
            --
            if listenerRegisteredId[i] == event then
                --
                listener:RemoveListener(listenerRegistered[i])
                --
                table.remove(listenerRegisteredId, i)
                --
                table.remove(listenerRegistered, i)
            end
        end

        LogInfo("COMMON.UnregisterListener", type(event) .. "'s all listeners have unregistered!")

        --注销特定listener的特定监听
    elseif arg_num == 2 then
        --获取event
        local event = select(1, ...)
        --获取要移除的listener
        local fun = select(2, ...)

        --
        for i, listener in pairs(listenerRegisteredId) do
            --找到相应的event以及对应的fun
            if listenerRegisteredId[i] == event and listenerRegistered[i] == fun then
                --移除指定的listener
                listener:RemoveListener(fun)
                --
                table.remove(listenerRegisteredId, i)
                --
                table.remove(listenerRegistered, i)
                --
                break
            end
        end

        LogInfo("COMMON.UnregisterListener", type(event) .. "'s " .. type(fun) .. " has unregistered!")
    end
end

--判断UI显示方式(屏幕转向)
function PROCESS.SetUIAdapter()
    --判断当前屏幕转向
    LogInfo("Screen.orientation", Screen.orientation)

    --单独运行时设置为自动旋转
    if isSingleType then
        Screen.orientation = CS.UnityEngine.ScreenOrientation.AutoRotation
        Screen.autorotateToLandscapeLeft = true
        Screen.autorotateToLandscapeRight = true
    end

    --TODO:适配分辨率
    if screenHeight < screenWidth then
        screenHeight = screenHeight + screenWidth
        screenWidth = screenHeight - screenWidth
        screenHeight = screenHeight - screenWidth
    end

    --屏幕比大于2.0
    if screenHeight / screenWidth >= 2.5 then
        LogInfo("ScreenAdapter", "Value of height/width is " .. screenHeight / screenWidth)
        --设置默认偏移量
        local offset = 50
        --TODO:添加要适配的UI组件
        local Viewport = PageList.transform:Find("TileView/ScrollRect/Viewport").gameObject
        local ToolMenu = GameObject.Find("Root/UI/Main UI Canvas/Tools Panel/ToolMenu")
        local Tool_Menu = ToolMenu.transform:Find("Tool Menu").gameObject
        local UIAdapter = {
            PreLoad, Viewport, ToolMenu, Tool_Menu, Panel
        }
        --TODO:判断当前UI扩展或者偏移
        for i, view in pairs(UIAdapter) do
            if view.name == "PreLoad" then
                view.transform:Find("Text"):GetComponent("RectTransform").offsetMin = CS.UnityEngine.Vector2(offset, view.transform:Find("Text"):GetComponent("RectTransform").offsetMin.y)
                view.transform:Find("Text"):GetComponent("RectTransform").offsetMax = CS.UnityEngine.Vector2(-offset, view.transform:Find("Text"):GetComponent("RectTransform").offsetMax.y)
            elseif view.name == "Viewport" then
                view:GetComponent("RectTransform").offsetMin = CS.UnityEngine.Vector2(offset, view:GetComponent("RectTransform").offsetMin.y)
                view:GetComponent("RectTransform").offsetMax = CS.UnityEngine.Vector2(-offset, view:GetComponent("RectTransform").offsetMax.y)
            elseif view.name == "ToolMenu" then
                view:GetComponent("RectTransform").offsetMax = CS.UnityEngine.Vector2(-offset, view:GetComponent("RectTransform").offsetMax.y)
            elseif view.name == "Tool Menu" then
                view:GetComponent("RectTransform").offsetMax = CS.UnityEngine.Vector2(offset, view:GetComponent("RectTransform").offsetMax.y)
                view:GetComponent("VerticalLayoutGroup").padding.left = offset
            elseif view.name == "Panel" then
                view:GetComponent("RectTransform").offsetMax = CS.UnityEngine.Vector2(offset - offset * view:GetComponent("RectTransform").anchorMax.x, view:GetComponent("RectTransform").offsetMax.y)
            end
        end
    end

end

--根据所得路径判断平台
function PROCESS.FindVersionType()
    local runTimePlatform = Application.platform

    LogInfo("RuntimePlatform", runTimePlatform)

    --运行平台为Android
    if runTimePlatform == RuntimePlatform.Android then
        runTimePlatform = "Android"
        --运行平台为IPhone
    elseif runTimePlatform == RuntimePlatform.IPhonePlayer then
        runTimePlatform = "iOS"
        --运行平台为WindowsEditor
    elseif runTimePlatform == RuntimePlatform.WindowsEditor then
        runTimePlatform = "WindowsEditor"
    end

    --全部转换为小写
    runTimePlatform = tostring(runTimePlatform):lower()

    --根据路径判断android或者ios
    versionType = rootPath:find("android")

    --排除Android平台
    if versionType == nil then
        --
        versionType = rootPath:find("ios")
        --判断是否为IOS平台
        if (versionType ~= nil) then
            --设置平台为ios
            versionType = "iOS"
            --设置iOS平台file协议
            wwwHeadPath = "file://"

            --路径传入错误
        else
            --
            Debug.LogError("The Path is Not Allowed,Please Check Out The Gained Path!")
        end
        --Android平台
    else
        versionType = "Android"
        --设置Android平台file协议
        wwwHeadPath = "file:///"
    end

    --将versionType转换为全小写
    versionType = versionType:lower()

    --判断运行平台与路径平台是否一致
    if runTimePlatform ~= versionType then
        --运行平台与路径平台不一致
        LogWarning("Path-VersionType is not same as RuntimePlatform!")
    end
    --
    LogInfo("VersionType (from path) is " .. versionType)

    --设置全局变量versionType
    _Global:SetData("versionType", versionType)
end

--设置wwwAssetPath
function PROCESS.SetWWWAssetPath()
    --根据平台及所传路径判断 file： 协议格式
    if rootPath:sub(1, 1) == "/" then
        LogInfo("RootPath begins of '/'")
        --
        wwwHeadPath = "file://"
    end

    --如果是单独运行的Android版本
    if isSingleType and versionType == "android" then
        --设置wwwAssetPath="jar:file:///"
        wwwAssetPath = rootPath
        --设置wwwAssetPath="file:///storage ......"
    else
        wwwAssetPath = wwwHeadPath .. rootPath
    end

    --储存WWW加载资源根路径
    _Global:SetData("wwwAssetPath", wwwAssetPath)
end

--根据所传路径找到appid
function PROCESS.Try2FindChildAppId()
    LogInfo("Enter Function 'PROCESS.Try2FindChildAppId'")
    --判断路径最后一位是否为'/'
    local _rootPath = rootPath
    if _rootPath:sub(_rootPath:len()) == '/' then
        _rootPath = _rootPath:sub(0, _rootPath:len() - 1)
    end
    --
    _rootPath = _rootPath:reverse()
    local childAppId_versionType = _rootPath:sub(0, _rootPath:find("/") - 1):reverse()
    local _childAppId = childAppId_versionType:sub(0, childAppId_versionType:find("_") - 1)
    local _versionType = childAppId_versionType:sub(childAppId_versionType:find("_") + 1)

    LogInfo("FromPath", _childAppId)
    LogInfo("FromPath", _versionType)
end

--判断文件是否存在，存在则加载内容
function PROCESS.TextLoader(filePath)
    --[[
        subapp_config.json ->childAppId_childAppName
        scene_config.json ->sceneType
                            AllPageInfo.json
                            marker.json
                                       -> Prepared!
    ]]
    LogInfo("FilePath", filePath)
    local _filePath = filePath:gsub(wwwHeadPath, "")
    --获取文件信息
    local fileInfo = FileInfo(_filePath)
    local fileExists = false
    local www = CS.UnityEngine.WWW(filePath)

    yield_return(www)

    if www.error == nil then
        LogInfo("File " .. fileInfo.Name .. "Exists!")
        fileExists = true
    else
        fileExists = false
        LogWarning("File " .. fileInfo.Name .. " Not Exists!")
    end

    --子应用配置文件
    if fileInfo.Name == "subapp_config.json" then
        if fileExists then
            CALLBACK.ConfigJSONLoaded(www.text)
        else
            --必要文件缺失，终止程序
            SSMessageManager:ReceiveMessage("ThrowErrorException", fileInfo.Name .. ":" .. www.error)
        end
        --场景配置文件
    elseif fileInfo.Name == "scene_config.json" then
        if fileExists then
            --scene_config.json回调
            CALLBACK.SceneConfigLoaded(www.text)
        else
            --抛出警告
            Debug.LogWarning(fileInfo.Name .. ":" .. www.error)
        end
        --识别图文件(marker.json)
    elseif fileInfo.Name == "marker.json" then
        if fileExists then
            CALLBACK.MarkerJSONLoaded(www.text)
        else
            --设置相应场景类型所需回调
            PROCESS.ListenProcess({ sceneType }, "LoadMarkerJson", "FAILED")
            --必要文件缺失，终止程序
            SSMessageManager:ReceiveMessage("ThrowErrorException", fileInfo.Name .. ":" .. www.error)
        end
        --AllPageInfo.json
    elseif fileInfo.Name == "AllPageInfo.json" then
        --
        PageListScrollRect.transform:Find("Viewport/PageItem/IconContainer/Signal"):GetComponent("Image").color = themeColor

        if fileExists then
            --AllPageInfo.json存在 回调
            CALLBACK.ExistAllPageInfo()
        else
            --抛出警告
            LogWarning(fileInfo.Name, www.error)
            --AllPageInfo.json不存在 回调
            CALLBACK.NotExistAllPageInfo()
        end
        --
    else
        SSMessageManager:ReceiveMessage("ThrowErrorException", fileInfo.Name .. ":" .. www.error)
    end
end

--加载Config文件
function PROCESS.LoadConfigJson()
    --加载subapp_config.json
    coroutine.resume(coroutine.create(function()
        PROCESS.TextLoader(wwwAssetPath .. "subapp_config.json")
    end))
end

--自动计算模型中点
function PROCESS.AutoCalculateCenter(parent)
    local position = parent.position
    local rotation = parent.rotation
    local scale = parent.localScale
    parent.position = Vector3.zero
    parent.rotation = Quaternion.Euler(Vector3.zero)
    parent.localScale = Vector3.one

    local center = Vector3.zero
    local renders = parent:GetComponentsInChildren(typeof(CS.UnityEngine.MeshRenderer), true)

    print(">>>>>>>>>>>>>>" .. tostring(renders.Length))

    for i = 0, renders.Length - 1 do
        center = center + renders[i].bounds.center
    end

    local transformGroup = parent:GetComponentsInChildren(typeof(CS.UnityEngine.Transform), true)

    center = center / transformGroup.Length

    local bounds = CS.UnityEngine.Bounds(center, Vector3.zero)

    for i = 0, renders.Length - 1 do
        bounds:Encapsulate(renders[i].bounds)
    end

    parent.position = Vector3.zero
    parent.rotation = Quaternion.Euler(Vector3.zero)
    parent.localScale = Vector3.one

    for i = 0, transformGroup.Length - 1 do
        transformGroup[i].position = transformGroup[i].position - bounds.center
    end

end

--Exist AllPageInfo.json
function CALLBACK.ExistAllPageInfo()
    --注册AllPageInfoLoaded回调监听
    COMMON.RegisterListener(PageInfoManager.OnAllPageInfoLoaded, CALLBACK.AllPageInfoLoaded)

    --加载书页信息(From AllPageInfo.json)
    PageInfoManager:LoadAllPageInfo()

end

--Don't exist AllPageInfo.json
function CALLBACK.NotExistAllPageInfo()
    --子应用单独运行(AllPageInfo.json不存在！)
    if isSingleType then
        --
        WEBVIEW.SetPageListType_H5()
        --子应用非单独运行
    else
        --注册AllPageInfoLoaded回调监听
        COMMON.RegisterListener(PageInfoManager.OnAllPageInfoLoaded, CALLBACK.AllPageInfoLoaded)

        --加载书页信息(From PersistentPage.Load)
        PageInfoManager:LoadAllPageInfo(1)
    end
end

--AllPageInfoLoaded
function CALLBACK.AllPageInfoLoaded()
    --注销该监听
    COMMON.UnregisterListener(PageInfoManager.OnAllPageInfoLoaded, CALLBACK.AllPageInfoLoaded)

    --设定PageList的展现方式
    pageListType = pageListType_UIWidget

    --设置PageList显示方式
    _Global:SetData("pageListType", pageListType)

    --注册PageListSelect监听
    COMMON.RegisterListener(CustomTileView.OnPageSelect, CALLBACK.PageListSelected)

    --设置相应场景类型所需回调
    PROCESS.ListenProcess({ sceneType }, "LoadAllPageInfo", "DONE")

    --注册UIWidget全部数据加载完毕监听
    COMMON.RegisterListener(CustomTileViewDataSource.OnTileViewDataLoaded, function()
        --注销该监听
        COMMON.UnregisterListener(CustomTileViewDataSource.OnTileViewDataLoaded)

        --
        local dataSource = CustomTileViewDataSource:GetComponent(typeof(CS.SubScene.CustomTileView)).DataSource

        LogInfo("TileView loaded totally " .. dataSource.Count .. " items")
    end)

    --开始填充已加载完毕的数据
    PageList:SetActive(true)

end

--加载场景配置文件
function CALLBACK.SceneConfigLoaded(sceneConfigJson)
    LogInfo("SceneConfig", sceneConfigJson)

    local sceneConfigTxt = JSON.Parse(sceneConfigJson)

    --获取配置参数（容错）
    for i = 0, (sceneConfigTxt.Count - 1) do

        if (string.find(tostring(sceneConfigTxt[i]), "trackerType") ~= nil) then
            --Tracker模式
            if (sceneConfigTxt[i][0] ~= nil) then
                _, _, _, trackerType = string.find(tostring(sceneConfigTxt[i][0]), "([\"'])(.-)%1")
            end
        elseif (string.find(tostring(sceneConfigTxt[i]), "sceneType") ~= nil) then
            --场景类型
            if (sceneConfigTxt[i][0] ~= nil) then
                _, _, _, sceneType = string.find(tostring(sceneConfigTxt[i][0]), "([\"'])(.-)%1")
            end

            --是否自动打开标注点
            if (sceneConfigTxt[i][1] ~= nil) then
                _, _, _, autoShowPoint = string.find(tostring(sceneConfigTxt[i][1]), "([\"'])(.-)%1")
                _Global:SetData("autoShowPoint", autoShowPoint)
            else
                _Global:SetData("autoShowPoint", false)
            end

            --主题颜色 themeColor
            if (sceneConfigTxt[i][2] ~= nil) then
                local _, _, _, _color = tostring(sceneConfigTxt[i][2]):find("([\"'])(.-)%1")
                local r = _color:sub(1, _color:find(',') - 1)
                local g = _color:sub(_color:find(',') + 1, _color:find(',', _color:find(',') + 1) - 1)
                local b = _color:sub(_color:find(',', _color:find(',') + 1) + 1, _color:find(',', _color:find(',', _color:find(',') + 1) + 1) - 1)
                local a = _color:reverse():sub(1, _color:reverse():find(',') - 1):reverse()

                --主题颜色
                themeColor.r = r / 255.0
                themeColor.g = g / 255.0
                themeColor.b = b / 255.0
                themeColor.a = a / 255.0
            end
        elseif tostring(sceneConfigTxt[i]):find("haveViewTransfer") ~= nil then
            --是否有视图切换的功能
            if (sceneConfigTxt[i][0] ~= nil) then
                _, _, _, haveViewTransfer = tostring(sceneConfigTxt[i][0]):find("([\"'])(.-)%1")
                --判断参数是否合法
                if not haveViewTransfer:toboolean() then
                    haveViewTransfer = false
                end
            end

            --浏览视图模式
            if (sceneConfigTxt[i][1] ~= nil) then
                _, _, _, defaultView = tostring(sceneConfigTxt[i][1]):find("([\"'])(.-)%1")
                --
                if defaultView ~= "Fake" and defaultView ~= "Real" and defaultView ~= "Divided" then
                    defaultView = "Fake"
                end
            end
        elseif (string.find(tostring(sceneConfigTxt[i]), "position_") ~= nil) then
            local _modelCamera = CameraModel.transform:Find("Camera").gameObject:GetComponent("Camera")

            local _position = Vector3.zero

            --获取配置文件中相机的position
            if (sceneConfigTxt[i][0] ~= nil) then
                _, _, _, _position.x = string.find(tostring(sceneConfigTxt[i][0]), "([\"'])(.-)%1")
            end
            if (sceneConfigTxt[i][1] ~= nil) then
                _, _, _, _position.y = string.find(tostring(sceneConfigTxt[i][1]), "([\"'])(.-)%1")
            end
            if (sceneConfigTxt[i][2] ~= nil) then
                _, _, _, _position.z = string.find(tostring(sceneConfigTxt[i][2]), "([\"'])(.-)%1")
            end

            --设置相机position
            CameraModel.transform:Find("Camera").gameObject.transform.localPosition = _position
            LogInfo("ModelCamera's position has set to :(" .. _position.x .. "," .. _position.y .. "," .. _position.z .. ")")

            --判断是否存在模型的缩放最值参数
            if (sceneConfigTxt[i][3] ~= nil) then
                local tmp_minScale
                _, _, _, tmp_minScale = string.find(tostring(sceneConfigTxt[i][3]), "([\"'])(.-)%1")
                --SetData
                _Global:SetData("minScale", tonumber(tmp_minScale))
                LogInfo("Model_MinScale", tmp_minScale)
            end
            if (sceneConfigTxt[i][4] ~= nil) then
                local tmp_maxScale
                _, _, _, tmp_maxScale = string.find(tostring(sceneConfigTxt[i][4]), "([\"'])(.-)%1")
                --SetData
                _Global:SetData("maxScale", tonumber(tmp_maxScale))
                LogInfo("Model_MaxScale", tmp_maxScale)
            end

            --
            if (sceneConfigTxt[i][5] ~= nil) then
                local _farClipPlane
                _, _, _, _farClipPlane = string.find(tostring(sceneConfigTxt[i][5]), "([\"'])(.-)%1")
                --设置相机深度 Far
                _modelCamera.farClipPlane = _farClipPlane
                LogInfo("Camera's farClipPlane has set to " .. _modelCamera.farClipPlane)
            end
        elseif (string.find(tostring(sceneConfigTxt[i]), "intensity") ~= nil) then
            --获取配置文件中的光照强度值
            if (sceneConfigTxt[i][0] ~= nil) then
                --默认光照强度
                local intensity = 1
                _, _, _, intensity = string.find(tostring(sceneConfigTxt[i][0]), "([\"'])(.-)%1")
                --设置场景光照亮度
                local Light = GameObject.Find("Root/Models/Directional light"):GetComponent("Light")
                Light.intensity = intensity
                LogInfo("Light's intensity has set to " .. intensity)
            end
        elseif (string.find(tostring(sceneConfigTxt[i]), "sectionNumber") ~= nil) then
            --如果配置文件中有剖切参数
            if (sceneConfigTxt[i][0] ~= nil) then
                _, _, _, sectionNum = string.find(tostring(sceneConfigTxt[i][0]), "([\"'])(.-)%1")
            end
            if (sceneConfigTxt[i][1] ~= nil) then
                _, _, _, canControl = string.find(tostring(sceneConfigTxt[i][1]), "([\"'])(.-)%1")
                --string to boolean
                canControl = canControl:toboolean()
            end
            --设置剖切滑杆的最值
            if (sceneConfigTxt[i][2] ~= nil) then
                local maxValue
                _, _, _, maxValue = string.find(tostring(sceneConfigTxt[i][3]), "([\"'])(.-)%1")
                --
                _Global:SetData("maxValue", tonumber(maxValue))
            end
            if (sceneConfigTxt[i][3] ~= nil) then
                local minValue
                _, _, _, minValue = string.find(tostring(sceneConfigTxt[i][2]), "([\"'])(.-)%1")
                --
                _Global:SetData("minValue", tonumber(minValue))
            end
            --
            if (sceneConfigTxt[i][4] ~= nil) then
                --
                local _sectionMode
                _, _, _, _sectionMode = string.find(tostring(sceneConfigTxt[i][2]), "([\"'])(.-)%1")
                --
                if _sectionMode == "Single" or _sectionMode == "Combine" then
                    sectionMode = _sectionMode
                end
            end
        end
    end

    --AR&VR模式下不兼容追踪
    if sceneType == "AR&VR" then
        trackerType = "Once"

        LogWarning("Compatibility", "Track always cannot matched with scene type " .. sceneType)
    end

    --
    LogInfo("sceneMode", sectionMode)
    LogInfo("haveViewTransfer", haveViewTransfer)
    LogInfo("defaultView", defaultView)

    --
    _Global:SetData("themeColor", themeColor)
    --
    _Global:SetData("haveViewTransfer", haveViewTransfer)
    _Global:SetData("defaultView", defaultView)

    --(配置文件中的切面参数)切面数量(0：剖切按钮不显示)
    _Global:SetData("sectionNum", sectionNum)
    --是否可调控切面位置
    _Global:SetData("canControl", canControl)
    --
    _Global:SetData("sectionMode", sectionMode)
end

--ConfigJSON加载完成后回调
function CALLBACK.ConfigJSONLoaded(configJson)
    LogInfo("ConfigJSON", configJson)

    --解析配置文件，获取AppName
    local configTxt = JSON.Parse(configJson)

    --获取childAppId,childAppName
    _, _, _, childAppId = string.find(tostring(configTxt[0]), "([\"'])(.-)%1")
    LogInfo("childAppId:" .. childAppId)

    --储存childAppId
    _Global:SetData("childAppId", childAppId)

    --获取childAppName
    _, _, _, childAppName = string.find(tostring(configTxt[1]), "([\"'])(.-)%1")

    --设置子应用名称
    MainTitleText.text = childAppName
    MainText.text = childAppName

    --获取子应用进度
    COMMON.Progress = PlayerPrefs.GetString(childAppId .. "UseProgress", "")

    LogInfo("UseProgress", COMMON.Progress)
end

--识别物与模型对应的JSON回调
function CALLBACK.MarkerJSONLoaded(markerJson)

    LogInfo("MarkerJSON:" .. markerJson)

    --解析配置文件
    local markerTxt = JSON.Parse(markerJson)
    --markerTxt.Count 元素数量
    --遍历
    for i = 0, markerTxt.Count - 1 do
        --
        local table_MarkerJson = {}

        --将相应的识别图与模型匹配
        --获取projectPath
        _, _, _, table_MarkerJson[1] = string.find(tostring(markerTxt[i][0]), "([\"'])(.-)%1")
        --截取掉空格
        table_MarkerJson[1] = table_MarkerJson[1]:trim()
        --获取sceneGuid
        _, _, _, table_MarkerJson[2] = string.find(tostring(markerTxt[i][1]), "([\"'])(.-)%1")
        --获取sceneName
        _, _, _, table_MarkerJson[3] = string.find(tostring(markerTxt[i][2]), "([\"'])(.-)%1")
        --获取pageName
        _, _, _, table_MarkerJson[4] = string.find(tostring(markerTxt[i][3]), "([\"'])(.-)%1")
        --获取modelName
        _, _, _, table_MarkerJson[5] = string.find(tostring(markerTxt[i][4]), "([\"'])(.-)%1")
        --markerName
        _, _, _, table_MarkerJson[6] = string.find(tostring(markerTxt[i][5]), "([\"'])(.-)%1")
        --sortingName
        _, _, _, table_MarkerJson[7] = string.find(tostring(markerTxt[i][6]), "([\"'])(.-)%1")
        --haveModels
        _, _, _, table_MarkerJson[8] = string.find(tostring(markerTxt[i][7]), "([\"'])(.-)%1")

        --
        table_MarkerToModel[#table_MarkerToModel + 1] = table_MarkerJson
    end

    --Vuforia xml文件路径
    vuforiaXmlPath = childAppId .. ".xml"
    vuforiaDatPath = childAppId .. ".dat"

    --
    if isSingleType then
        DataSetLoader.Path = Application.persistentDataPath .. "/" .. vuforiaXmlPath
        --
        VUFORIA.CopyVuforiaFile()
    else
        DataSetLoader.Path = rootPath .. vuforiaXmlPath

        LogInfo("VuforiaXmlPath:" .. DataSetLoader.Path)

        --加载识别图
        DataSetLoader:LoadDataSet()
        DataSetLoader:ActiveDataSet()
        --
        VUFORIA.FindDynamicTarget()
    end
end

--PageListSelect回调
function CALLBACK.PageListSelected(url)
    LogInfo("PageListSelected_CallBack:" .. url)

    --选择事件
    --创建应用Task并执行
    Task     :new("Procedure",
            function()
                --判断URL回调类型
                --TODO:替换协议head
                if url == "uniwebview://hide" then
                    --隐藏第二页
                    CallbackFromWebToUnity_MulModelPage._webView:Hide(false, CS.UniWebViewTransitionEdge.Top)
                    --隐藏背板
                    UniWebViewPanelButton.gameObject:SetActive(false)
                else
                    if loadedModel then
                        --释放已加载的模型
                        CALLBACK.ModelUnloaded()
                    end
                    --解析url
                    PROCESS.URLInterpreter(url)

                    --设置解析后的参数
                    PROCESS.SetParameters()

                    --执行相应功能
                    PROCESS.StartAimedFunction()

                end
            end
    , nil, 1):PostInQueue()
end

--执行相应的功能
function PROCESS.StartAimedFunction()

    doType = "media"

    LogInfo("DoType", doType)

    if doType == "do" then
        --模型浏览
        PROCEDURE.StartScanModelScene()

    elseif doType == "media" then
        --
        TaskDoneListener:Invoke("MediaAction")

        --播放媒体资源
        MEDIA.Prepare()
    else
        doType = "model"
    end

end

--更新子应用的书页被读取进度
function PROCESS.UpdateUseProgress()
    --获取到书页数量
    local dataSource = CustomTileViewDataSource:GetComponent(typeof(CS.SubScene.CustomTileView)).DataSource

    if COMMON.Progress == "" then
        for i = 1, dataSource.Count do
            COMMON.Progress = COMMON.Progress .. "0"
        end
    else
        --判断服务器端进度与实际进度
        if COMMON.Progress:len() ~= dataSource.Count then
            LogWarning("UseProgress", "COMMON.Progress and CustomTileView.DataSource.Count are not matched!")
        end
    end

    --如果存在页面下标
    if pageIndex ~= nil then
        for i = 1, COMMON.Progress:len() do
            if (tonumber(pageIndex) + 1) == i then
                local _before = COMMON.Progress:sub(1, i - 1)
                local _after = COMMON.Progress:sub(i + 1)
                COMMON.Progress = _before .. "1" .. _after
                break
            end
        end
    end

    --
    pageIndex = nil

    --
    PlayerPrefs.SetString(childAppId .. "UseProgress", COMMON.Progress)
    LogInfo("UseProgress", "Progress update to " .. COMMON.Progress)
end

--加载PageListType_H5
function WEBVIEW.SetPageListType_H5()
    --
    pageListType = pageListType_H5

    --设置PageList显示方式
    _Global:SetData("pageListType", pageListType)

    --设置屏幕参数
    if (screenHeight > screenWidth) then
        screenHeight = screenWidth
    end

    --设置UniWebView的本地模型首页html路径
    defaultOrderHtml = wwwAssetPath .. "first.html"

    --
    if versionType == "android" then
        wwwAssetPath = rootPath
        --设置UniWebView的本地模型首页html路径
        -- "jar:file:///data/app/com.Chujiao.Beta-1/base/apk!/assets/Valve_android/"
        local str = rootPath:sub(1, rootPath:len() - 1)
        local _pos = str:len() - str:reverse():find("/") + 1
        defaultOrderHtml = "file:///android_asset/" .. str:sub(_pos + 1) .. "/first.html"
    end
    LogInfo("defaultOrderHtml:" .. defaultOrderHtml)

    --设置UniWebView相关属性
    WEBVIEW.SetUniWebViewConfig()

    --设置相应场景类型所需回调
    PROCESS.ListenProcess({ sceneType }, "LoadAllPageInfo", "DONE")
end

--
function WEBVIEW.SetUniWebViewConfig()
    --添加UniWebView脚本
    UniWebView_FirstPage:AddComponent(typeof(CS.CallbackFromWebToUnity))
    --
    CallbackFromWebToUnity = UniWebView_FirstPage:GetComponent(typeof(CS.CallbackFromWebToUnity))

    --设置加载完毕
    CallbackFromWebToUnity.OnPageFinished:AddListener(WEBVIEW.OnPageFinished)
    --设置加载失败
    CallbackFromWebToUnity.OnPageErrorReceived:AddListener(WEBVIEW.OnPageErrorReceived)
    --设置回调监听
    CallbackFromWebToUnity.OnReceived:AddListener(CALLBACK.PageListSelected)
end

--
function WEBVIEW.OnPageFinished(content)
    LogInfo("defaultOrderHtml_PageFinished!")
    local statusCode = content:sub(1, content:find("@") - 1)
    local url = content:sub(content:find("@") + 1)
    LogInfo("statusCode:" .. statusCode)
    LogInfo("url:" .. url)
    --隐藏H5加载界面
    H5Load:SetActive(false)
end

--[[
    errorCode:-1  net::ERR_FILE_NOT_FOUND
    errorCode:-10 net::ERR_UNKNOWN_URL_SCHEME
]]
--
function WEBVIEW.OnPageErrorReceived(content)
    LogInfo("defaultOrderHtml_PageErrorReceived:")
    local errorCode = content:sub(1, content:find("@") - 1)
    local errorMessage = content:sub(content:find("@") + 1)
    --抛出警告
    Debug.LogWarning("H5Error:" .. errorCode .. ":" .. errorMessage)
    --显示错误页
    --CallbackFromWebToUnity:LoadFromFile("http://www.chu-jiao.com",0,0,math.ceil(screenHeight*100/750))
    --隐藏H5加载界面
    H5Load:SetActive(false)
end

--根据场景类型设置场景属性
function PROCESS.SwitchScene()
    --
    if sceneType ~= "AR&VR" and sceneType ~= "OnlyAR" and sceneType ~= "OnlyVR" then
        sceneType = "AR&VR"
    end

    LogInfo("SceneType is :" .. sceneType)

    --sceneType
    _Global:SetData("sceneType", sceneType)

    --添加Case进度监听
    PROCESS.TaskPrepared[sceneType] = {
        leader = PROCESS.ExecutedTask.name,
        event = {},
        neededResponseCount = 0,
        totalAddedCount = 0,
        callBack = nil
    }

    --处理相应的UI变化
    if sceneType == "OnlyVR" then

        ButtonVR.gameObject:SetActive(false)
        ButtonAR.gameObject:SetActive(false)

        --
        PROCESS.TaskPrepared[sceneType].callBack = function()
            ButtonVR.onClick:Invoke()
        end

    elseif sceneType == "OnlyAR" then

        ButtonVR.gameObject:SetActive(false)
        ButtonAR.gameObject:SetActive(false)

        --
        if trackerType ~= nil then
            if trackerType == "Once" then
            elseif trackerType == "Always" then
            else
                trackerType = "Once"
            end
            LogInfo("TrackerType is :" .. trackerType)
        end
    elseif sceneType == "AR&VR" then

    end

    --需要加载marker.json
    if sceneType ~= "OnlyVR" then

        --TODO:需要在DataSetLoader.cs中添加OnLoaded事件
        --[[
            --识别图加载完成后回调
            --加载完成后find所有DynamicTarget
            COMMON.RegisterListener(DataSetLoader.onLoaded,VUFORIA.FindDynamicTarget)
        ]]

        --需要实例化CameraAR
        if Vuforia.VuforiaBehaviour.Instance == nil then
            --
            Vuforia.VuforiaARController.Instance:RegisterVuforiaInitializedCallback(function()
                Vuforia.VuforiaARController.Instance:UnregisterVuforiaInitializedCallback()

            end)

            Vuforia.VuforiaARController.Instance:RegisterVuforiaStartedCallback(function()
                --
                Vuforia.VuforiaARController.Instance:UnregisterVuforiaStartedCallback()
                --
                if not Vuforia.CameraDevice.Instance:IsActive() then
                    SSMessageManager:ReceiveMessage("ThrowErrorException", "设备相机异常，请退出！")
                    print("Please ensure you have an alive camera device!")
                end
                --
                if Vuforia.VuforiaARController.Instance.HasStarted then
                end
            end)

            --
            CameraAR = GameObject.Instantiate(Resources.Load("prefabs/ARCamera"))
            CameraAR.name = "ARCamera"
        else
            --Vuforia.CameraDevice.Instance:Init()
            CameraAR = VuforiaBehaviour.Instance:GetComponent("Camera").gameObject
        end

        --设置ARCamera渲染层不包括Model
        if CameraAR ~= nil and CameraAR:GetComponent("Camera") ~= nil then

            --设置AR渲染层不包括Model层(layer 8)
            CameraAR:GetComponent("Camera").cullingMask = (1 << 0)
            LogInfo("Have set ARCamera's cullingMask 'Default'(except Model)")

            --AR相机自动对焦
            VUFORIA.CameraAutoFocus = GameObject.Find("MainController").transform:Find("LuaController_CameraAutoFocus").gameObject

            VUFORIA.CameraAutoFocus:SetActive(true)
        end

        --加载marker.json
        local COROUTINE_LoadMarkerInfo = coroutine.create(function()
            --设置相应场景类型所需回调
            PROCESS.ListenProcess({ sceneType }, "LoadMarkerJson", "ADD")
            --加载Marker.json
            PROCESS.TextLoader(wwwAssetPath .. "marker.json")
        end)
        --
        assert(coroutine.resume(COROUTINE_LoadMarkerInfo))
        --
        COROUTINE_LoadMarkerInfo = nil
    end

    --需要加载书页列表信息
    if sceneType ~= "OnlyAR" then
        --判断书页加载方式
        local COROUTINE_LoadPageInfo = coroutine.create(function()
            --设置相应场景类型所需回调
            PROCESS.ListenProcess({ sceneType }, "LoadAllPageInfo", "ADD")
            --
            COMMON.Function2XPCall(PROCESS.TextLoader, wwwAssetPath .. "AllPageInfo.json")
        end)
        --启动协程
        assert(coroutine.resume(COROUTINE_LoadPageInfo))
        --销毁
        COROUTINE_LoadPageInfo = nil
    end
end

--进度监听
function PROCESS.ListenProcess(tasks, event, action)
    for i = 1, #tasks do

        PROCESS.TaskPrepared[tasks[i]].totalAddedCount = PROCESS.TaskPrepared[tasks[i]].totalAddedCount + 1
        PROCESS.TaskPrepared[tasks[i]].event[#PROCESS.TaskPrepared[tasks[i]].event + 1] = event

        LogInfo("ListenProcess", tasks[i] .. "'s event is '" .. event .. "', action is " .. action)

        --判断事件类型
        if action == "ADD" then
            PROCESS.TaskPrepared[tasks[i]].neededResponseCount = PROCESS.TaskPrepared[tasks[i]].neededResponseCount + 1
        elseif action == "DONE" then
            PROCESS.TaskPrepared[tasks[i]].neededResponseCount = PROCESS.TaskPrepared[tasks[i]].neededResponseCount - 1
        elseif action == "FAILED" then
            PROCESS.TaskPrepared[tasks[i]].neededResponseCount = -1
            --抛出错误异常，程序不可再执行
            SSMessageManager:ReceiveMessage("ThrowErrorException", event .. " Error!")
        else
            LogError("function 'ListenProcess' used incorrectly!")
        end

        --判断事件是否结束
        if PROCESS.TaskPrepared[tasks[i]].totalAddedCount > 0 then
            if PROCESS.TaskPrepared[tasks[i]].neededResponseCount == 0 then
                --
                LogInfo("PROCESS", tasks[i] .. " is done !")

                if tasks[i] == PROCESS.ExecutedTask.name then
                    --标识该Task结束
                    PROCESS.TaskQueue[PROCESS.ExecutedTask.id].state = "Done"
                    --析构该任务
                    PROCESS.TaskQueue[PROCESS.ExecutedTask.id].task:Destructor()
                    --
                    PROCESS.ExecutedTask = nil
                    --执行下一个Task
                    PROCESS.Execute()
                end

                --事件完毕后回调
                if PROCESS.TaskPrepared[tasks[i]].callBack ~= nil then
                    --执行回调
                    PROCESS.TaskPrepared[tasks[i]].callBack()
                end

                --减少领导工作数量
                if PROCESS.TaskPrepared[tasks[i]].leader ~= nil then
                    PROCESS.ListenProcess({ PROCESS.TaskPrepared[tasks[i]].leader }, "Case " .. tasks[i] .. " is Done!", "DONE")
                end
            end
        end
    end
end

--
function DEBUG.BugTrackReporter()
    local process_count = 0
    for i, item in pairs(PROCESS.TaskPrepared) do
        process_count = process_count + 1
    end
end

--独立运行子应用时需要此操作
function VUFORIA.CopyVuforiaFile()
    --复制Vuforia配置文件到绝对路径
    assert(coroutine.resume(coroutine.create(function()
        LogInfo('Copy vuforia files\' coroutine start!')
        local www = CS.UnityEngine.WWW(wwwAssetPath .. vuforiaXmlPath)
        yield_return(www)
        if www.error == nil then
            --
            LogInfo("Vuforia", "Copying " .. childAppId .. ".xml")
            --拷贝.xml文件
            File.WriteAllBytes(Application.persistentDataPath .. "/" .. vuforiaXmlPath, www.bytes)
            --
            LogInfo("Vuforia", childAppId .. ".xml Copyed!")
            local www = CS.UnityEngine.WWW(wwwAssetPath .. vuforiaDatPath)
            yield_return(www)

            if www.error == nil then
                LogInfo("Vuforia", "Copying " .. childAppId .. ".dat")
                --拷贝.dat
                File.WriteAllBytes(Application.persistentDataPath .. "/" .. vuforiaDatPath, www.bytes)
                --
                LogInfo("Vuforia", childAppId .. ".dat Copyed!")
                LogInfo("Vuforia", "VuforiaXmlPath:" .. DataSetLoader.Path)

                --加载识别图
                DataSetLoader:LoadDataSet()
                DataSetLoader:ActiveDataSet()

                --
                VUFORIA.FindDynamicTarget()
            else
                LogError("copyDat_error", www.error)
            end
        else
            LogError("copyXml_error", www.error)
        end
    end)))
end

--find所有DynamicTarget
function VUFORIA.FindDynamicTarget()
    --获取场景中所有GameObject
    local arr_DynamicTargets = GameObject.FindObjectsOfType(typeof(CS.Vuforia.ImageTargetBehaviour))

    LogInfo("arr_DynamicTargets.Length:" .. arr_DynamicTargets.Length)

    --判断Tracker识别类型(Once/Always)
    if trackerType == "Once" then
        --遍历GameObject找到识别图
        for i = 0, (arr_DynamicTargets.Length - 1) do
            --找到识别图
            if (string.find(arr_DynamicTargets[i].gameObject.name, "DynamicTarget") ~= nil) then

                --给识别图添加监听脚本
                arr_DynamicTargets[i].gameObject:AddComponent(typeof(CS.EzComponents.Vuforia.UnityTrackableEventHandler))

                --注册监听
                local onFound = arr_DynamicTargets[i].gameObject:GetComponent(typeof(CS.EzComponents.Vuforia.UnityTrackableEventHandler)).onFound

                COMMON.RegisterListener(onFound, function()
                    CALLBACK.TrackingFound(arr_DynamicTargets[i])
                end)

            end
        end
    elseif trackerType == "Always" then
        --遍历GameObject找到识别图
        for i = 0, (arr_DynamicTargets.Length - 1) do
            --找到识别图
            if (string.find(arr_DynamicTargets[i].gameObject.name, "DynamicTarget") ~= nil) then
                --
                arr_DynamicTargets[i].gameObject.transform.localScale = Vector3.one

                --给识别图添加监听脚本
                arr_DynamicTargets[i].gameObject:AddComponent(typeof(CS.CustomTrackableEventHandler))
                --
                arr_DynamicTargets[i].gameObject:AddComponent(typeof(Vuforia.TurnOffBehaviour))

                print("" .. arr_DynamicTargets[i].gameObject:GetComponent(typeof(Vuforia.ImageTargetBehaviour)).ImageTarget.Name)
                --获取到识别图的大小
                print(arr_DynamicTargets[i].gameObject:GetComponent(typeof(Vuforia.ImageTargetBehaviour)).ImageTarget:GetSize())

                --注册onFound监听
                local onFound = arr_DynamicTargets[i].gameObject:GetComponent(typeof(CS.CustomTrackableEventHandler)).onFound

                COMMON.RegisterListener(onFound, function()
                    CALLBACK.TrackingFound(arr_DynamicTargets[i])
                end)

                --注册onLost监听
                local onLost = arr_DynamicTargets[i].gameObject:GetComponent(typeof(CS.CustomTrackableEventHandler)).onLost

                COMMON.RegisterListener(onLost, function()
                    CALLBACK.TrackingLost(arr_DynamicTargets[i])
                end)
            end
        end
    end

    --
    LogInfo("Add Script to DynamicTargets!")

    --
    VUFORIA.dynamicTargetsArray = arr_DynamicTargets

    --MarkerJson处理完成
    --设置相应场景类型所需回调
    PROCESS.ListenProcess({ sceneType }, "LoadMarkerJson", "DONE")
end

--TrackingFound回调
function CALLBACK.TrackingFound(DynamicTarget)

    currentMarkerGameObject = DynamicTarget

    LogInfo(DynamicTarget.name .. " Found!")

    --标识是否需要加载相应模型
    local needLoad = true
    --
    if trackerType ~= nil then
        if trackerType == "Once" then

        elseif trackerType == "Always" then

            --判断是否已经加载出相应的模型
            if DynamicTarget.transform:Find("MakerAll") ~= nil then

                LogInfo("Current tracker has loaded model!")

                --无需再次加载
                needLoad = false

                --判断是否已经播放相应的视频
            elseif DynamicTarget.transform:Find("MediaQuad") ~= nil then

                LogInfo("Current tracker has loaded media!")

                --无需再次加载
                needLoad = false
            end
        end
    else
        LogWarning("trackerType is nil!")
        needLoad = false
    end

    --
    for i = 1, #table_MarkerToModel do
        --遍历列表寻找识别物匹配的模型
        if string.gsub(DynamicTarget.name, "DynamicTarget", "") == "-" .. table_MarkerToModel[i][6] then
            --解析Marker信息
            --sceneName
            sceneName = ((table_MarkerToModel[i][3] == nil) and "") or table_MarkerToModel[i][3]
            --pageName
            pageName = ((table_MarkerToModel[i][4] == nil) and "") or table_MarkerToModel[i][4]
            --设置模型名称name
            modelName = ((table_MarkerToModel[i][5] == nil) and "") or table_MarkerToModel[i][5]
            --
            haveMulModel = ((table_MarkerToModel[i][8] == nil) and "") or table_MarkerToModel[i][8]
            --
            sectionNum = ((table_MarkerToModel[i][7] == nil) and "") or ((string.len(tostring(table_MarkerToModel[i][7])) > 1 and "") or table_MarkerToModel[i][7])

            --如果显示模式为UIWidget
            if pageListType == pageListType_UIWidget then
                --标识
                local value
                --将DataSource中的数据IsSelected全部设为false
                for j = 0, CustomTileView.DataSource.Count - 1 do
                    CustomTileView.DataSource[j].IsSelected = false
                    --判断识别图场景名称所对应的下标
                    if sceneName == CustomTileView.DataSource[j].SceneName then
                        value = j
                    end
                end

                --将创建出来的书页标识设为隐藏
                for k = 0, CustomTileView:GetVisibleComponents().Count - 1 do
                    CustomTileView:GetVisibleComponents()[k].SelectedSignal:SetActive(false)
                end

                --如果当前标识存在则显示
                if value ~= nil then
                    --
                    if CustomTileView:GetItemComponent(value) ~= nil then
                        CustomTileView:GetItemComponent(value).SelectedSignal:SetActive(true)
                    end

                    --设置当前书页为选中状态
                    CustomTileView.DataSource[value].IsSelected = true
                else
                    COMMON.LogError("AllPageInfo.json 与 Marker.json 文件内容有误！")
                end
            end

            --需要加载模型
            if needLoad then
                --pagelist://model?url1=p2-20/assetbundle&url2=modelName&url3=&url4=3
                local url = "pagelist://doType?sceneName=" .. sceneName .. "&pageName=" .. pageName .. "&modelName=" .. modelName .. "&haveMulModel=" .. haveMulModel .. "&sectionNum=" .. sectionNum

                --加载模型
                CALLBACK.PageListSelected(url)
            else
                --设置相应的模型名称
                MainSubtitleText.text = (modelName ~= nil and modelName) or ""

                if doType ~= nil and doType == "media" then
                    --Resume Media
                    MEDIA.Resume()
                end
            end

            --找到便退出循环
            break
        end

        --未找到相应模型
        if i == #table_MarkerToModel then
            LogError("There's no data about " .. DynamicTarget.name .. " in marker.json")
        end
    end
end

--TrackingLost回调
function CALLBACK.TrackingLost(DynamicTarget)

    local DynamicTargetName = DynamicTarget.name

    LogInfo(DynamicTargetName .. " Lost!")

    --丢失当前marker
    if currentMarkerGameObject ~= nil and currentMarkerGameObject.name == DynamicTargetName then

        --判断是否当前是全屏播放状态
        if not VIDEO.renderFullScreenRawImage.transform.gameObject.activeInHierarchy then
            --
            if DynamicTarget.gameObject.transform:Find("MediaQuad") ~= nil then
                --
                MEDIA.LostTarget()
            end

            --
            if Loading.activeSelf then
                Loading:SetActive(false)
            end

            MainSubtitleText.text = ""

            currentMarkerGameObject = nil
        end
    end
end

--模型浏览模式
function PROCEDURE.StartScanModelScene()
    LogInfo("Set model-scanned scene~")

    --显示Loading界面
    local COROUTINE_ShowLoadingProcess = coroutine.create(function()
        --显示加载Loading
        Loading:SetActive(true)

        LogInfo("Model Loading ……")

        --判断是否为H5显示方式
        if pageListType == pageListType_H5 then
            --
            if loadedModel then
                --隐藏第二页模型
                CallbackFromWebToUnity_MulModelPage._webView:Hide(false, CS.UniWebViewTransitionEdge.Top)
                UniWebViewPanelButton.gameObject:SetActive(false)
            else
                --隐藏书页UniWebView
                if CallbackFromWebToUnity._webView ~= nil then
                    CallbackFromWebToUnity._webView:Hide(false)
                end
            end
        else
            --隐藏列表页
            PageListScrollRect:SetActive(false)
        end

        --注册StudioData加载回调监听
        --StudioData LoadedFinish
        COMMON.RegisterListener(StudioDataManager.LoadFinished, function()

            --注销回调监听
            COMMON.UnregisterListener(StudioDataManager.LoadFinished)

            --尝试性的垃圾回收
            COMMON.CollectGarbage()

            --模型加载完毕
            assert(coroutine.resume(coroutine.create(CALLBACK.ModelLoaded), TaskDoneListener))
        end)

        --此处是超级耗时的操作
        assert(coroutine.resume(coroutine.create(function()
            --延迟一帧
            yield_return(1)

            --开始加载Studio数据
            StudioDataManager:LoadFromMobile(wwwAssetPath .. sceneName .. "/")
        end)))
    end)

    --
    assert(coroutine.resume(COROUTINE_ShowLoadingProcess))

    --
    if coroutine.status(COROUTINE_ShowLoadingProcess) == "suspended" then
        COROUTINE_ShowLoadingProcess = nil
    end

    --开启协程
    assert(coroutine.resume(coroutine.create(function()
        --开启模型显示
        Prefab_ModelLoader:SetActive(true)

        --隐藏MainTitle
        MainTitle:SetActive(false)
        --显示子标题模型名称
        MainSubtitle:SetActive(true)

        --modelName未设置
        if (modelName ~= nil) then
            if (modelName:trim() ~= "") then
                MainSubtitleText.text = modelName
            else
                MainSubtitleText.text = ""
                LogWarning("There's no modelName!")
            end
        else
            MainSubtitleText.text = ""
            LogWarning("There's no modelName!")
        end

        --隐藏AR/VR按钮
        ListButtonGroup:SetActive(false)

        --隐藏AR/VR扩展按钮
        ButtonExtendArea.gameObject:SetActive(false)

        --带有AR功能的场景
        if sceneType ~= "OnlyVR" then
            --单次识别模式
            if trackerType == "Once" then
                --关闭识别
                DataSetLoader:DeactivateDataSet()
            end
        end

        --仅支持VR场景
        if sceneType == "OnlyVR" then
            --标题栏颜色
            backGroundColor.a = 0
            TitleImage.color = backGroundColor

        elseif sceneType == "AR&VR" then
            --标题栏颜色
            backGroundColor.a = 0
            TitleImage.color = backGroundColor

            --
            if defaultView == "Real" then
                --打开AR相机
                VuforiaBehaviour.Instance.enabled = true
                --打开自动对焦
                VUFORIA.CameraAutoFocus:SetActive(true)
                --关闭虚景相机
                CameraBG:SetActive(false)
            elseif defaultView == "Fake" then
                --关闭AR相机
                VuforiaBehaviour.Instance.enabled = false
                --关闭自动对焦
                VUFORIA.CameraAutoFocus:SetActive(false)
                --打开虚景相机
                CameraBG:SetActive(true)
            end

            --AR模式
            if loadedType == 0 then

                if trackerType == "Once" then

                    --判断defaultView模式
                    if defaultView == "Divided" then
                        --打开AR相机
                        VuforiaBehaviour.Instance.enabled = true
                        --打开自动对焦
                        VUFORIA.CameraAutoFocus:SetActive(true)
                        --关闭虚景相机
                        CameraBG:SetActive(false)
                    end

                elseif trackerType == "Always" then
                    --标题栏颜色
                    backGroundColor.a = 80 / 255
                    TitleImage.color = backGroundColor

                    --打开AR相机
                    VuforiaBehaviour.Instance.enabled = true
                    --打开自动对焦
                    VUFORIA.CameraAutoFocus:SetActive(true)
                    --关闭虚景相机
                    CameraBG:SetActive(false)
                end
                --VR
            elseif loadedType == 1 then
                --打开实景
                if defaultView == "Divided" then
                    --
                    VuforiaBehaviour.Instance.enabled = false
                    --关闭自动对焦
                    VUFORIA.CameraAutoFocus:SetActive(false)
                    --
                    CameraBG:SetActive(true)
                end
            end
        end
    end)))

    --更新子应用进度
    PROCESS.UpdateUseProgress()
end

--添加按钮监听
function PROCESS.RegisterUIButtonListener()
    --ButtonBack 退回到上一级
    COMMON.RegisterListener(ButtonBackPanelButton.onClick, PROCESS.ControlBack)

    --ButtonVR
    COMMON.RegisterListener(ButtonVR.onClick, function()
        --
        if sceneType == "AR&VR" then
            ButtonVR.gameObject:SetActive(false)
            ButtonAR.gameObject:SetActive(true)
        end

        --打开VR相机
        CameraBG:SetActive(true)

        --AR相机开启的情况下关闭相机
        if sceneType ~= "OnlyVR" then
            --关闭AR相机
            VuforiaBehaviour.Instance.enabled = false

            --关闭自动对焦
            VUFORIA.CameraAutoFocus:SetActive(false)

            --CS.Vuforia.VideoBackgroundManager.Instance:SetVideoBackgroundEnabled(false)
            --CameraAR:SetActive(false)

            --关闭识别
            DataSetLoader:DeactivateDataSet()
        end

        --标题栏颜色
        backGroundColor.a = 1
        TitleImage.color = backGroundColor

        --标注加载方式
        loadedType = 1

        --设置UniWebView的URL
        if pageListType == pageListType_H5 then
            if (CallbackFromWebToUnity._webView ~= nil) then
                CallbackFromWebToUnity._webView:Show()
            else
                --显示加载H5的Loading界面
                H5Load:SetActive(true)
                CallbackFromWebToUnity:LoadFromFile(defaultOrderHtml, 0, 0, math.ceil(screenHeight * 100 / 750))
            end
            --非单独运行版本
        else
            PageListScrollRect:SetActive(true)
            H5Load:SetActive(false)
        end
    end)

    --ButtonAR
    COMMON.RegisterListener(ButtonAR.onClick, function()
        --
        if sceneType == "AR&VR" then
            ButtonAR.gameObject:SetActive(false)
            ButtonVR.gameObject:SetActive(true)
        end

        --打开AR相机
        VuforiaBehaviour.Instance.enabled = true

        --打开自动对焦
        VUFORIA.CameraAutoFocus:SetActive(true)

        --Vuforia.CameraDevice.Instance:Start()
        --CameraAR:SetActive(true)

        --延迟激活识别
        assert(coroutine.resume(coroutine.create(function()
            yield_return(CS.UnityEngine.WaitForSeconds(1.0))
            DataSetLoader:ActiveDataSet()
        end)))

        --关闭VR相机
        CameraBG:SetActive(false)

        --标题栏颜色
        backGroundColor.a = 80 / 255
        TitleImage.color = backGroundColor
        --标注加载方式
        loadedType = 0
        --判断PageList是否为H5加载方式
        if pageListType == pageListType_H5 then
            if (CallbackFromWebToUnity._webView ~= nil) then
                --隐藏FirstPageHtml
                CallbackFromWebToUnity._webView:Hide()
            end
        else
            PageListScrollRect:SetActive(false)
        end
    end)

    --ButtonExtendArea
    COMMON.RegisterListener(ButtonExtendArea.onClick, function()
        --
        if (ButtonVR.gameObject.activeSelf) then
            ButtonVR.onClick:Invoke()
        else
            ButtonAR.onClick:Invoke()
        end
    end)

    --ButtonExit
    COMMON.RegisterListener(ButtonExit.onClick, function()
        --
        if sceneType ~= "OnlyVR" then
            --释放Vuforia
            --DataSetLoader:DeactivateDataSet()
            DataSetLoader:DestroyDataSet()
        end
        --
        if pageListType == pageListType_H5 and CallbackFromWebToUnity._webView ~= nil then
            CallbackFromWebToUnity:destroy()
        end
        --隐藏退出面板
        Exiting:SetActive(false)
        --
        if isSingleType then
            Application.Quit()
        else
            --
            COMMON.CollectGarbage()
            --退出程序到子应用
            XLuaLoader:Back()
        end
        --
        LogInfo("ChildApp exit!")
    end)

    --ButtonCancel
    COMMON.RegisterListener(ButtonCancel.onClick, function()
        --
        if sceneType ~= "OnlyVR" then
            --AR开启的情况下
            if CameraAR.activeSelf then
                DataSetLoader:ActiveDataSet()
            end
        end
        --判断PageList是否为H5加载方式
        if pageListType == pageListType_H5 then
            --H5页面显示的情况
            if not ButtonVR.gameObject.activeSelf then
                CallbackFromWebToUnity._webView:Show()
            end
        end
    end)
end

--显示应用操作UI
function PROCESS.ShowOperateUI()
    --显示标题栏
    TitlePanel:SetActive(true)
    --隐藏遮罩
    PreLoad:SetActive(false)
    --初始化Media工具
    COMMON.Function2XPCall(MEDIA.InitMediaTool)
end

--模型加载完毕后回调
function CALLBACK.ModelLoaded(...)
    --
    LogInfo("Model loaded!")

    --标识模型加载成功
    loadedModel = true

    --判断加载方式(VR/AR)
    backType = loadedType

    --获取模型
    local MakerAll = GameObject.Find("Root/Models/Contents/Prefab-ModelLoader/MakerAll")

    --[自动计算模型中心点]
    --PROCESS.AutoCalculateCenter(MakerAll.transform)

    --
    if trackerType == "Once" or loadedType == 1 then

        --设置所加载的模型Layer为model层
        for i = 0, MakerAll:GetComponentsInChildren(typeof(CS.SceneStudio.ObjectData)).Length - 1 do
            MakerAll:GetComponentsInChildren(typeof(CS.SceneStudio.ObjectData))[i].gameObject.layer = 8
        end

        --判断是否要打开第二页
        if pageListType == pageListType_H5 then
            if haveMulModel ~= nil and haveMulModel ~= "" then
                if UniWebView_MulModelPage:GetComponent(typeof(CS.CallbackFromWebToUnity)) == nil then
                    UniWebView_MulModelPage:AddComponent(typeof(CS.CallbackFromWebToUnity))
                end
                --
                CallbackFromWebToUnity_MulModelPage = UniWebView_MulModelPage:GetComponent(typeof(CS.CallbackFromWebToUnity))
                --给第二页添加回调监听
                CallbackFromWebToUnity_MulModelPage.OnReceived:AddListener(CALLBACK.PageListSelected)
            end
        end

        --LuaController_Tool.lua
        LuaController_Tool:SetActive(true)

    elseif trackerType == "Always" and loadedType == 0 then

        --返回键直接退出应用
        backType = -1

        if currentMarkerGameObject ~= nil then
            --
            local _MakerAll = GameObject.Instantiate(MakerAll, currentMarkerGameObject.transform)
            --
            _MakerAll.name = "MakerAll"

            _MakerAll.transform.localScale = Vector3(1 / 200, 1 / 200, 1 / 200)

            --
            for i = 0, GameObject.Find("Root/Models/Contents/Prefab-ModelLoader/MakerAll").transform.childCount - 1 do
                Destroy(GameObject.Find("Root/Models/Contents/Prefab-ModelLoader/MakerAll").transform:GetChild(i).gameObject)
            end

            --
            Loading:SetActive(false)
        end
    end

    --模型加载完毕回调
    local callback = select(1, ...)

    coroutine.yield(callback:Invoke("Model Loaded"))
end

--模型释放后回调
function CALLBACK.ModelUnloaded()
    --初始化model参数Table
    urlParameters = {}

    --重置特定切面参数
    if _Global:GetData("_sectionNum") ~= nil then
        _Global:ReleseData("_sectionNum")
    end

    --TODO:清除工具里的动画信息
    CS.SceneStudio.AnimationManager.Instance:ClearAllAnimationClipData()

    local MakerAll = GameObject.Find("Root/Models/Contents/Prefab-ModelLoader/MakerAll")
    --
    for i = 0, MakerAll.transform.childCount - 1 do
        Destroy(MakerAll.transform:GetChild(i).gameObject)
    end

    MakerAll.transform.localPosition = Vector3.zero
    MakerAll.transform.localRotation = Quaternion.Euler(Vector3.zero)
    MakerAll.transform.localScale = Vector3.one

    --
    COMMON.CollectGarbage()

    Resources.UnloadUnusedAssets()

    LogInfo("Model Unloaded!")

    --隐藏模型显示
    Prefab_ModelLoader:SetActive(false)

    --隐藏Panel
    Panel:SetActive(false)

    --隐藏模型相机
    CameraModel:SetActive(false)

    --关闭手势操作
    Contents:GetComponent(typeof(CS.XLuaBehaviour)).enabled = false

    --LuaController_Tool.lua
    LuaController_Tool:SetActive(false)

    --是否已加载模型置为否
    loadedModel = false
end

--解析URL,分离所需参数
function PROCESS.URLInterpreter(url)
    --pagelist://doType?#index|sceneName=assetBundlePath&modelName=modelName&haveModels=htmlPath&sectionNum=sectionNum
    local url_head_pos = url:find('://')
    local url_head = url:sub(1, url_head_pos - 1)
    --获取到urlHead
    urlParameters['urlHead'] = url_head
    local sub_url_head = url:gsub(url_head .. "://", "")
    local do_type = sub_url_head:sub(1, sub_url_head:find('?') - 1)

    --获取到doType
    urlParameters['doType'] = do_type

    --?sceneName='sceneName'&pageName='pageName'&modelName='modelName'&haveMulModel='haveMulModel'&sectionNum='sectionNum'
    local sub_do_type = sub_url_head:gsub(do_type, ""):sub(2)
    --判断是否存在#index
    if sub_do_type:find('#') ~= nil then
        urlParameters['pageIndex'] = sub_do_type:sub(2, sub_do_type:find("|") - 1)
        --
        sub_do_type = sub_do_type:sub(sub_do_type:find("|") + 1)
    end
    --
    for i, parameter in pairs(sub_do_type:split('&')) do
        --argument=sceneName='sceneName'
        local parameter_name = parameter:sub(1, parameter:find("=") - 1)
        urlParameters[parameter_name] = parameter:sub(parameter:find("=") + 1)
    end
end

--给模型浏览场景所需参数赋值
function PROCESS.SetParameters()
    local count = 0
    for i, parameter in pairs(urlParameters) do
        count = count + 1
        LogInfo("parameter " .. i, parameter)
    end

    if count > 0 then
        doType = (urlParameters['doType'] ~= nil and urlParameters['doType']) or nil
        urlHead = (urlParameters['urlHead'] ~= nil and urlParameters['urlHead']) or nil
        pageIndex = (urlParameters['pageIndex'] ~= nil and urlParameters['pageIndex']) or nil
        sceneName = (urlParameters['sceneName'] ~= nil and urlParameters['sceneName']) or nil
        pageName = (urlParameters['pageName'] ~= nil and urlParameters['pageName']) or nil
        modelName = (urlParameters['modelName'] ~= nil and urlParameters['modelName']) or nil
        haveMulModel = (urlParameters['haveMulModel'] ~= nil and urlParameters['haveMulModel']) or nil
        sectionNum = (urlParameters['sectionNum'] ~= nil and (((string.len(tostring(urlParameters['sectionNum'])) > 1) and "") or urlParameters['sectionNum'])) or sectionNum
    end
    --
    _Global:SetData("sceneName", sceneName)
    --
    _Global:SetData("selectedPageName", pageName)

    --
    _Global:SetData("_sectionNum", sectionNum)
    --
    _Global:SetData("haveMulModel", haveMulModel)
end

--处理UniWebView回调的Message
function PROCESS.HandleURL(message)
    --pagelist://post?sceneName="sceneName"&pageName="pageName"&haveMulModel="haveMulModel"&sectionNum="sectionNum"
    --uniwebview://post?url1=assetBundlePath&url2=modelName&url3=htmlPath&url4=sectionNum
    --uniwebview://post?url1=p2-20/assetbundle&url2=modelName&url3=&url4=3
    --回调名称
    post_type = string.sub(message, string.find(message, "/") + 2, string.find(message, "?") - 1)
    local sub_path = string.sub(message, string.find(message, "?") + 1)
    --获取第一个参数(模型AssetBundle路径)
    local sub_first = string.sub(sub_path, string.find(sub_path, "=") + 1)
    assetBundle_url = string.sub(sub_first, 1, string.find(sub_first, "&") - 1)
    --书页
    pageName = string.sub(assetBundle_url, 1, string.find(assetBundle_url, "/") - 1)
    --书页
    _Global:SetData("pageName", pageName)
    --bundle名字
    assetBundleName = string.sub(assetBundle_url, string.find(assetBundle_url, "/") + 1)
    --获取第二个参数(模型名称)
    local sub_second = string.sub(sub_first, string.find(sub_first, "=") + 1)
    modelName = string.sub(sub_second, 1, string.find(sub_second, "&") - 1):DecodeURI()
    --获取第三个参数(要显示的html地址)
    local sub_third = string.sub(sub_second, string.find(sub_second, "=") + 1)

    if not (string.sub(sub_third, 1, 1) == "&") then
        haveMulModel = string.sub(sub_third, 1, string.find(sub_third, "&") - 1)
    else
        haveMulModel = ""
    end
    LogInfo("haveMulModel", haveMulModel)

    --设置第二页H5路径
    _Global:SetData("haveMulModel", haveMulModel)

    --获取第四个参数(该模型的剖切面数)
    local sub_forth = string.sub(sub_third, string.find(sub_third, "=") + 1)
    --
    if (sub_forth ~= nil) and (sub_forth ~= "") then
        sectionNum = sub_forth
        LogInfo("PageList_SectionNum:" .. sectionNum)
        _Global:SetData("_sectionNum", sectionNum)
    else
        LogWarning("There's no parameters 'PageList_SectionNum'!")
    end
end

--控制返回流程
function PROCESS.ControlBack()
    --
    COMMON.CollectGarbage()

    --从模型浏览界面返回
    if backType ~= -1 then

        --隐藏多模型列表按钮
        GameObject.Find("Root/UI/Main UI Canvas/Title Panel").transform:Find("UpperRight/MulModelListButton").gameObject:GetComponent("Button").gameObject:SetActive(false)

        --重置模型scale
        GameObject.Find("Root/Models").transform.localScale = Vector3.one

        --释放加载的模型
        if loadedModel then
            CALLBACK.ModelUnloaded()
        end
        --销毁CallbackFromWebToUnity_MulModelPage
        if pageListType == pageListType_H5 then
            if ((CallbackFromWebToUnity_MulModelPage ~= nil) and (CallbackFromWebToUnity_MulModelPage._webView ~= nil)) then
                CallbackFromWebToUnity_MulModelPage:destroy()
            end
        elseif pageListType == pageListType_UIWidget then
            if MulModelList.activeSelf then
                --隐藏多模型列表
                MulModelList:SetActive(false)
            end
        end

        --隐藏多模型下拉按钮
        if ButtonShowModel.gameObject.activeSelf then
            ButtonShowModel.gameObject:SetActive(false)
        end

        --显示标题栏
        MainTitle:SetActive(true)

        --隐藏模型标题
        MainSubtitle:SetActive(false)

        --显示AR/VR按钮
        ListButtonGroup:SetActive(true)

        --
        CustomTileView:DeselectItemAt(CustomTileView:GetSelectedIndex())
    end

    --释放资源
    Resources.UnloadUnusedAssets()

    --退出子应用
    if backType == -1 then
        --显示确认退出面板
        Exiting:SetActive(true)

        --AR界面则关闭识别
        if sceneType ~= "OnlyVR" then
            if CameraAR.activeSelf then
                DataSetLoader:DeactivateDataSet()
            end
        end
        --VR界面则隐藏H5
        if pageListType == pageListType_H5 and CallbackFromWebToUnity._webView ~= nil then
            --隐藏H5
            CallbackFromWebToUnity._webView:Hide()
        end
        --退回到AR
    elseif backType == 0 then
        --
        ButtonAR.onClick:Invoke()

        backType = -1
        --退回到VR
    elseif backType == 1 then
        --
        ButtonVR.onClick:Invoke()
        backType = -1
    end
end

--
function DEBUG.TaskInfo()
    for i, item in pairs(PROCESS.TaskPrepared) do
        LogError(i, item.neededResponseCount)
    end
end

---Media-Functions

local Media = {
    --_id
    _id = -1,
    --资源名称
    name = "",
    --资源类型
    type = "",
    --
    anchorMin = Vector2.zero,
    anchorMax = Vector2.one,
    --url
    url = {},
    index = 1,
    --progress
    progress = tonumber(0.0),
    --loop
    isLoop = false,
    --
    tip = nil
}

function Media:new(name, type, anchorMin, anchorMax, url, ...)

    local arguments = {
        self.index, self.progress, self.isLoop, self.tip
    }

    if select("#", ...) > 0 then
        for i = 1, i < select("#", ...) do
            arguments[i] = select(i, ...)
        end
    end

    --
    MEDIA._id = MEDIA._id + 1

    self._id = MEDIA._id
    self.name = name
    self.type = type
    self.anchorMin = anchorMin
    self.anchorMax = anchorMax
    self.url = url
    self.index = arguments[1]
    self.progress = arguments[2]
    self.isLoop = arguments[3]
    self.tip = arguments[4]

    local o = {
        _id = self._id,
        name = self.name,
        type = self.type,
        anchorMin = self.anchorMin,
        anchorMax = self.anchorMax,
        url = self.url,
        index = self.index,
        progress = self.progress,
        isLoop = self.isLoop,
        tip = self.tip
    }

    --元表保护
    self.__metatable = "Sorry, u cannot do this!"

    --元表
    setmetatable(o, self)
    self.__index = self

    return o
end

--标识当前多媒体资源
--MEDIA.currentType = "None"
MEDIA.currentMedia = nil

MEDIA.mediaArray = {}

MEDIA.canAutoResume = false

MEDIA.currentMediaId = 1

--初始化MediaTool
function MEDIA.InitMediaTool()
    --初始化公共控件
    MEDIA.InitCommonComponents()
    --初始化AudioSource
    AUDIO.InitAudioPlayer()
    --初始化VideoPlayer
    VIDEO.InitVideoPlayer()
end

--初始化Media公共组件
function MEDIA.InitCommonComponents()
    --初始化多媒体导航栏
    MEDIA.InitNavigationBar()

    --多媒体导航栏播放按钮事件
    COMMON.RegisterListener(MEDIA.buttonPlay.onClick, function()
        --
        MEDIA.buttonPlay.gameObject:SetActive(false)
        MEDIA.buttonPause.gameObject:SetActive(true)

        --区分音频还是视频
        if MEDIA.currentMedia.type == "AUDIO" then
            AUDIO.PlayAudio()
        elseif MEDIA.currentMedia.type == "VIDEO" then
            VIDEO.PlayVideo()
        end

    end)
    --多媒体导航栏暂停按钮事件
    COMMON.RegisterListener(MEDIA.buttonPause.onClick, function()
        --[[        --TODO:区分音频还是视频
                if MEDIA.currentType == "Audio" then
                    AUDIO.PauseAudio()
                elseif MEDIA.currentType == "Video" then
                    VIDEO.PauseVideo()
                end]]

        if MEDIA.currentMedia.type == "AUDIO" then
            AUDIO.PauseAudio()
        elseif MEDIA.currentMedia.type == "VIDEO" then
            VIDEO.PauseVideo()
        end
    end)
    --退出全屏按钮
    COMMON.RegisterListener(VIDEO.quitFullScreenButton.onClick, function()
        --打开追踪
        DataSetLoader:ActiveDataSet()
        --
        VIDEO.renderFullScreenRawImage.transform.parent.gameObject:SetActive(false)
        --
        MEDIA.switchPanel.gameObject:SetActive(false)
        --
        MEDIA.LostTarget()
    end)

    --PreviousButton
    COMMON.RegisterListener(MEDIA.previousButton.onClick, function()
        --
        MEDIA.nextButton.gameObject:SetActive(true)

        --
        if MEDIA.currentMedia ~= nil then
            if #MEDIA.currentMedia.url > 1 then

                MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMediaId].index = MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMediaId].index - 1

                if MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMediaId].index == 1 then
                    --
                    MEDIA.previousButton.gameObject:SetActive(false)
                end

                --TODO:播放上一个
                VIDEO.PlayVideo(MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMediaId])
            end
        end

    end)

    COMMON.RegisterListener(MEDIA.nextButton.onClick, function()
        --
        MEDIA.previousButton.gameObject:SetActive(true)
        --
        if MEDIA.currentMedia ~= nil then
            if #MEDIA.currentMedia.url > 1 then

                MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMediaId].index = MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMediaId].index + 1

                if MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMediaId].index == #MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMediaId].url then
                    --
                    MEDIA.nextButton.gameObject:SetActive(false)
                end

                --TODO:播放下一个
                VIDEO.PlayVideo(MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMediaId])
            end
        end
    end)
end

MEDIA.videoUpdateProgress = false
MEDIA.audioUpdateProgress = false

--初始化Media导航栏
function MEDIA.InitNavigationBar()
    --填充进度条颜色
    MEDIA.fillContent.color = themeColor

    --给滑动条添加EventTrigger
    MEDIA.progressSlider.gameObject:AddComponent(typeof(CS.UnityEngine.EventSystems.EventTrigger))
    local eventTrigger = MEDIA.progressSlider.gameObject:GetComponent(typeof(CS.UnityEngine.EventSystems.EventTrigger))

    --设置滑动条
    local __entry = CS.UnityEngine.EventSystems.EventTrigger.Entry()
    __entry.eventID = CS.UnityEngine.EventSystems.EventTriggerType.BeginDrag
    __entry.callback:AddListener(function()
        MEDIA.audioUpdateProgress = AUDIO.needUpdateProcess
        MEDIA.videoUpdateProgress = VIDEO.needUpdateProcess
    end)
    eventTrigger.triggers:Add(__entry)

    local entry = CS.UnityEngine.EventSystems.EventTrigger.Entry()
    entry.eventID = CS.UnityEngine.EventSystems.EventTriggerType.Drag
    --拖动回调
    entry.callback:AddListener(function()

        --将Slider Value应用到播放器进度
        if MEDIA.currentMedia.type == "AUDIO" then

            AUDIO.needUpdateProcess = false

            --设置进度条value到audioSource播放time
            AUDIO.audioSource.time = (MEDIA.progressSlider.value > AUDIO.audioSource.clip.length and AUDIO.audioSource.clip.length) or MEDIA.progressSlider.value
            MEDIA.currentTimeStamp.text = MEDIA.CalculateTime(MEDIA.progressSlider.value)

        elseif MEDIA.currentMedia.type == "VIDEO" then

            VIDEO.needUpdateProcess = false

            --设置进度条value到videoPlayer播放time
            VIDEO.videoPlayer.time = MEDIA.progressSlider.value
            MEDIA.currentTimeStamp.text = MEDIA.CalculateTime(MEDIA.progressSlider.value)
        end
        --
        MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id].progress = MEDIA.progressSlider.value
    end)
    eventTrigger.triggers:Add(entry)

    local _entry = CS.UnityEngine.EventSystems.EventTrigger.Entry()
    _entry.eventID = CS.UnityEngine.EventSystems.EventTriggerType.EndDrag
    _entry.callback:AddListener(function()
        AUDIO.needUpdateProcess = MEDIA.audioUpdateProgress
        VIDEO.needUpdateProcess = MEDIA.videoUpdateProgress
    end)
    eventTrigger.triggers:Add(_entry)
end

--根据数据解析当前所需Media资源
function MEDIA.AnalysisMedia(root)

    local mediaArray = {}

    MEDIA._id = 0

    --TODO:Demo级别 根据识别名称生成相应Tip
    if currentMarkerGameObject.name == "DynamicTarget-P114" then

        mediaArray[#mediaArray + 1] = Media:new("audio1", "AUDIO", Vector2(550 / 4604.0, 4654 / 6305.0), Vector2(3975 / 4604.0, 5204 / 6305.0), { "audio1.mp3" })
        mediaArray[#mediaArray + 1] = Media:new("韩信点兵", "VIDEO", Vector2(1438 / 4604.0, 2454 / 6305.0), Vector2(3093 / 4604.0, 4109 / 6305.0), { "video.mp4" })
        mediaArray[#mediaArray + 1] = Media:new("audio2", "AUDIO", Vector2(550 / 4604.0, 846 / 6305.0), Vector2(3975 / 4604.0, 1419 / 6305.0), { "audio2.mp3" })

    elseif currentMarkerGameObject.name == "DynamicTarget-P118" then

        mediaArray[#mediaArray + 1] = Media:new("video", "VIDEO", Vector2(1431 / 4604.0, 1710 / 6305.0), Vector2(3097 / 4604.0, 3369 / 6305.0), { "video.mp4" })

    elseif currentMarkerGameObject.name == "DynamicTarget-P121" then

        mediaArray[#mediaArray + 1] = Media:new("audio", "AUDIO", Vector2(550 / 4604.0, 1885 / 6305.0), Vector2(3975 / 4604.0, 3150 / 6305.0), { "audio.mp3" })

    elseif currentMarkerGameObject.name == "DynamicTarget-P127" then
        mediaArray[#mediaArray + 1] = Media:new("video", "VIDEO", Vector2(1450 / 4604.0, 570 / 6305.0), Vector2(3090 / 4604.0, 2217 / 6305.0), { "video1.mp4", "video2.mp4", "video3.mp4", "video4.mp4", "video5.mp4" })
    end

    print("This marker needed " .. #mediaArray .. " media tips!")

    if #mediaArray > 1 then

        MEDIA.canAutoResume = false

    elseif #mediaArray == 1 and #mediaArray[1].url == 1 then

        MEDIA.canAutoResume = true

    end

    --将Media数组保存
    MEDIA.mediaArray[currentMarkerGameObject.name] = mediaArray

    print("Media canAutoResume is " .. tostring(MEDIA.canAutoResume))

    for i, media in pairs(mediaArray) do
        --设置www路径头
        for j, assetUrl in pairs(media.url) do

            assetUrl = wwwAssetPath .. sceneName .. "/" .. assetUrl

            media.url[j] = assetUrl
        end

        --判断MediaType
        if media.type == "AUDIO" then
            --
            MEDIA.NailAudioTip(root, media)

        elseif media.type == "VIDEO" then
            --
            MEDIA.NailVideoTip(root, media)
        end

        print("Media >>>" .. media.name .. " - " .. #media.url .. " url!")
    end

end

--准备Media
function MEDIA.Prepare()

    if currentMarkerGameObject ~= nil then
        --获取到识别到的ImageSize
        local size = currentMarkerGameObject:GetComponent(typeof(Vuforia.ImageTargetBehaviour)).ImageTarget:GetSize()

        --根据识别图大小设置视频窗口大小
        VIDEO.mediaQuad.gameObject.transform.localScale = size

        --在识别图下生成mediaQuad
        if currentMarkerGameObject.transform:Find("MediaQuad") == nil then

            local mediaQuad = GameObject.Instantiate(VIDEO.mediaQuad, currentMarkerGameObject.transform)

            mediaQuad.name = "MediaQuad"

            --生成Canvas
            local canvas = GameObject("3DCanvas"):AddComponent(typeof(CS.UnityEngine.Canvas))

            --
            canvas.renderMode = CS.UnityEngine.RenderMode.WorldSpace

            --
            canvas.worldCamera = CameraAR:GetComponentInChildren(typeof(CS.UnityEngine.Camera))

            canvas.transform:SetParent(mediaQuad.transform)

            canvas.transform.localRotation = Quaternion.Euler(Vector3.zero)

            canvas.transform.localScale = Vector3.one

            local canvasRect = canvas.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform)) and canvas.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform)) or canvas.gameObject:AddComponent(typeof(CS.UnityEngine.RectTransform))

            USERINTERFACE.InitRectTransform(canvasRect)

            canvasRect.sizeDelta = Vector2.one

            local graphicRaycaster = canvas.transform.gameObject:AddComponent(typeof(CS.UnityEngine.UI.GraphicRaycaster))

            graphicRaycaster.ignoreReversedGraphics = false

            --TODO:根据多媒体信息数量生成Tip
            MEDIA.AnalysisMedia(canvas)

            mediaQuad.gameObject:SetActive(true)

        else
            LogInfo(currentMarkerGameObject.name .. " has loaded its media!")

            --判断当前marker media数量
            if #MEDIA.mediaArray[currentMarkerGameObject.name] == 1 and #MEDIA.mediaArray[currentMarkerGameObject.name][1].url == 1 then

                MEDIA.canAutoResume = true
                --
                MEDIA.currentMedia = MEDIA.mediaArray[currentMarkerGameObject.name][1]

                MEDIA.buttonPlay.onClick:Invoke()
            else
                MEDIA.canAutoResume = false

                --TODO:播放背景音乐

            end
        end
    end
end

--
function MEDIA.Resume()
    print("This media group has " .. #MEDIA.mediaArray[currentMarkerGameObject.name] .. " tips")

    if #MEDIA.mediaArray[currentMarkerGameObject.name] > 1 then

        MEDIA.canAutoResume = false

        --Resume Twinkle
        for i, media in pairs(MEDIA.mediaArray[currentMarkerGameObject.name]) do
            if media.type == "AUDIO" then
                --Resume Twinkle
                AUDIO.TwinkleTip(media)
            end
        end

    elseif #MEDIA.mediaArray[currentMarkerGameObject.name] == 1 and #MEDIA.mediaArray[currentMarkerGameObject.name][1].url == 1 then

        MEDIA.canAutoResume = true

    end

    if MEDIA.canAutoResume then

        MEDIA.currentMediaId = 1

        if MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id].type == "AUDIO" then

            AUDIO.PlayAudio(MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id])

        elseif MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id].type == "VIDEO" then

            VIDEO.PlayVideo(MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id])

        end
    end
end

--钉音频
function MEDIA.NailAudioTip(parent, media)

    print("NailAudioTip >>> " .. media.name)

    local audioTip = GameObject("AudioTip"):AddComponent(typeof(CS.UnityEngine.RectTransform))

    --
    media.tip = audioTip

    audioTip.transform:SetParent(parent.transform)

    --audioTip.transform.localRotation = Quaternion.Euler(Vector3.zero)

    USERINTERFACE.InitRectTransform(audioTip)

    --根据计算好的位置设置锚点
    audioTip.anchorMin = Vector2(media.anchorMin.x, media.anchorMin.y)
    audioTip.anchorMax = Vector2(media.anchorMax.x, media.anchorMax.y)

    --提示框占比
    --audioTip.sizeDelta = Vector2(0, 0)

    --生成音频边界Image
    local image = audioTip.gameObject:AddComponent(typeof(CS.UnityEngine.UI.Image))
    --设置音频边框
    image.sprite = Resources.Load("Media/border", typeof(CS.UnityEngine.Sprite))
    --设置Image Type
    --image.type = Image.Type.Sliced
    --image.fillCenter = true
    image.type = Image.Type.Simple

    --设置边框颜色为主题颜色
    image.color = themeColor
    image.raycastTarget = true

    local twinkleImage = GameObject("TwinkleCover"):AddComponent(typeof(CS.UnityEngine.RectTransform))

    twinkleImage.transform:SetParent(image.transform)

    USERINTERFACE.InitRectTransform(twinkleImage)

    --
    local cover = twinkleImage.gameObject:AddComponent(typeof(Image))

    cover.sprite = Resources.Load("Media/audio-light", typeof(CS.UnityEngine.Sprite))

    cover.type = Image.Type.Simple

    cover.preserveAspect = true

    --图片闪烁提示
    AUDIO.TwinkleTip(media)

    --添加按钮
    local button = audioTip.gameObject:AddComponent(typeof(CS.UnityEngine.UI.Button))

    button.transition = CS.UnityEngine.UI.Selectable.Transition.None

    button.onClick:AddListener(function()

        print("Audio button click~")

        --
        if AUDIO.audioSource.isPlaying and MEDIA.currentMedia == media then
            print("Current audio is playing now!")
        else

            MEDIA.Dispatch()

            --MEDIA.currentType = "Audio"

            print("This media's id is " .. media._id)

            MEDIA.currentMediaId = media._id

            --播放音频
            AUDIO.PlayAudio(media)
        end
    end)

    if MEDIA.canAutoResume then
        button.onClick:Invoke()
    end
end

--钉视频
function MEDIA.NailVideoTip(parent, media)
    print("NailVideoTip >>> " .. media.name)

    local videoTip = GameObject("VideoTip"):AddComponent(typeof(CS.UnityEngine.RectTransform))

    --
    media.tip = videoTip

    videoTip.transform:SetParent(parent.transform)

    videoTip.transform.localRotation = Quaternion.Euler(Vector3.zero)

    USERINTERFACE.InitRectTransform(videoTip)

    --根据计算好的位置设置锚点
    videoTip.anchorMin = media.anchorMin
    videoTip.anchorMax = media.anchorMax

    --提示框占比
    videoTip.sizeDelta = Vector2.zero

    --生成按钮
    local videoRenderedRawImage = GameObject("VideoRenderedRawImage"):AddComponent(typeof(CS.UnityEngine.RectTransform))
    videoRenderedRawImage.transform:SetParent(videoTip.gameObject.transform)

    videoRenderedRawImage.transform.localRotation = Quaternion.Euler(Vector3.zero)

    USERINTERFACE.InitRectTransform(videoRenderedRawImage)

    videoRenderedRawImage.sizeDelta = Vector2.zero

    local rawImage = videoRenderedRawImage.gameObject:AddComponent(typeof(CS.UnityEngine.UI.RawImage))
    rawImage.texture = Resources.Load("video", typeof(CS.UnityEngine.Texture))
    rawImage.color = Color.white
    rawImage.raycastTarget = true

    --TODO:是否需要上下切换按钮
    if #media.url > 1 then
        print("Media " .. media.name .. " have " .. #media.url .. " " .. media.type .. " medias at the same position!")
    end

    --local aspectRatioFitter = videoRenderedRawImage.gameObject:AddComponent(typeof(CS.UnityEngine.UI.AspectRatioFitter))
    --aspectRatioFitter.aspectMode = CS.UnityEngine.UI.AspectRatioFitter.AspectMode.FitInParent

    local button = videoTip.gameObject:AddComponent(typeof(CS.UnityEngine.UI.Button))

    button.transition = CS.UnityEngine.UI.Selectable.Transition.None

    button.onClick:AddListener(function()
        --记录按下时间
        local tempTime = Time.realtimeSinceStartup

        if VIDEO.videoPlayer.isPlaying and MEDIA.currentMedia == media then
            print("Current video is playing~")

            if tempTime - VIDEO.PressDownStamp < 0.5 then
                print("Double click!")

                --将画面渲染设置为RenderImage
                VIDEO.renderRawImage = VIDEO.renderFullScreenRawImage

                --打开全屏视频
                VIDEO.renderFullScreenRawImage.transform.parent.gameObject:SetActive(true)

                MEDIA.switchPanel.gameObject:SetActive((#MEDIA.currentMedia.url > 1 and true) or false)

                --关闭追踪
                DataSetLoader:DeactivateDataSet()

            end

            VIDEO.PressDownStamp = tempTime
        else
            MEDIA.Dispatch()

            MEDIA.currentMediaId = media._id

            --播放视频
            VIDEO.PlayVideo(media)
        end
    end)

    if MEDIA.canAutoResume then
        button.onClick:Invoke()
    end

end

--根据视频帧数/视频帧率计算时间
function MEDIA.CalculateTime(time)

    if math.ceil(time) == time then
        time = math.ceil(time)
    else
        time = math.ceil(time) - 1
    end

    local hour = time / 3600

    if math.ceil(hour) == hour then
        hour = math.ceil(hour)
    else
        hour = math.ceil(hour) - 1
    end

    local minute = time / 60

    if math.ceil(minute) == minute then
        minute = math.ceil(minute)
    else
        minute = math.ceil(minute) - 1
    end

    local second = (time - minute * 60)

    local length
    --
    if hour == 0 then
        length = string.format("%02d:%02d", minute, second)
    else
        length = string.format("%02d:%02d:%02d", hour, minute, second)
    end

    return length
end

--重置多媒体功能
function MEDIA.Reset()
    --初始化
    MEDIA.progressSlider.value = 0

    MEDIA.currentTimeStamp.text = MEDIA.CalculateTime(0)

    if AUDIO.audioSource.clip ~= nil then
        AUDIO.Reset()
    end

    if VIDEO.videoPlayer.url ~= nil then
        VIDEO.Reset()
    end


end

function MEDIA.Dispatch()

    if AUDIO.audioSource.isPlaying then
        AUDIO.PauseAudio()
    end

    if VIDEO.videoPlayer.isPlaying then
        VIDEO.PauseVideo()
    end

end

--更新音频进度标识量
AUDIO.needUpdateProcess = false

--Audio播放初始化
function AUDIO.InitAudioPlayer()
    --
    AUDIO.audioSource.playOnAwake = false
    --设置loop=false
    AUDIO.audioSource.loop = false
    --
    AUDIO.audioSource.mute = false
end

function AUDIO.AudioPrepared()
    --
    AUDIO.audioSource.gameObject:SetActive(true)

    --计算音频时长
    MEDIA.totalTimeStamp.text = MEDIA.CalculateTime(math.ceil(AUDIO.audioSource.clip.length))

    MEDIA.progressSlider.maxValue = math.ceil(AUDIO.audioSource.clip.length)

    MEDIA.buttonPlay.gameObject:SetActive(false)

    MEDIA.buttonPause.gameObject:SetActive(true)

    AUDIO.audioSource.loop = MEDIA.currentMedia.isLoop

    --AUDIO.audioSource.time = AUDIO.currentProgress
    AUDIO.audioSource.time = MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id].progress

    print("[MEDIA]" .. MEDIA.currentMedia.type .. "=>" .. MEDIA.currentMedia.name .. ":MEDIA.currentMediaId=" .. MEDIA.currentMedia._id .. "'s progress is " .. MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id].progress)

    --播放模式下显示UI
    MEDIA.UI:SetActive(true)

    AUDIO.audioSource:Play()
    --
    AUDIO.needUpdateProcess = true

    --播放动图
    AUDIO.AnimateAct(MEDIA.currentMedia)

end

AUDIO.lightSignal = Resources.Load("Media/audio-light", typeof(CS.UnityEngine.Sprite))
AUDIO.darkSignal = Resources.Load("Media/audio-dark", typeof(CS.UnityEngine.Sprite))

function AUDIO.TwinkleTip(media)

    local twinkleCoroutine = coroutine.create(function()

        local image = media.tip.transform:Find("TwinkleCover"):GetComponent("Image")

        while image.sprite ~= nil and currentMarkerGameObject ~= nil do

            if AUDIO.audioSource.isPlaying then

                if MEDIA.currentMedia == media then

                    coroutine.yield()

                    break
                end
            end

            image.sprite = (image.sprite == AUDIO.darkSignal and AUDIO.lightSignal) or AUDIO.darkSignal

            yield_return(CS.UnityEngine.WaitForSeconds(0.5))
        end

    end)

    assert(coroutine.resume(twinkleCoroutine))
end

AUDIO.animateActArray = {
    Resources.Load("Media/audio-progress/1", typeof(CS.UnityEngine.Sprite)),
    Resources.Load("Media/audio-progress/2", typeof(CS.UnityEngine.Sprite)),
    Resources.Load("Media/audio-progress/3", typeof(CS.UnityEngine.Sprite)),
    Resources.Load("Media/audio-progress/4", typeof(CS.UnityEngine.Sprite)),
    Resources.Load("Media/audio-progress/5", typeof(CS.UnityEngine.Sprite)),
    Resources.Load("Media/audio-progress/6", typeof(CS.UnityEngine.Sprite)),
    Resources.Load("Media/audio-progress/7", typeof(CS.UnityEngine.Sprite))
}

function AUDIO.AnimateAct(media)

    local animateActCoroutine = coroutine.create(function()

        local image = media.tip.transform:Find("TwinkleCover"):GetComponent("Image")

        local index = 1

        while image.sprite ~= nil and currentMarkerGameObject ~= nil do

            if AUDIO.audioSource.isPlaying then

                if MEDIA.currentMedia == media then
                    index = index + 1
                else
                    coroutine.yield()

                    --TODO:Reset此Media
                    print("TODO >>>>>> Need do something~")

                    break
                end
            else
                if AUDIO.audioSource.time == 0.0 then

                    coroutine.yield()

                    break
                end
            end

            if index > #AUDIO.animateActArray then
                index = 1
            end

            image.sprite = AUDIO.animateActArray[index]

            yield_return(CS.UnityEngine.WaitForSeconds(0.1))

        end
    end)

    assert(coroutine.resume(animateActCoroutine))
end

--播放音频
function AUDIO.PlayAudio(...)

    local media

    if select("#", ...) > 0 then

        media = select(1, ...)

        --
        local AUDIO_COROUTINE = coroutine.create(function()

            print("URL:" .. media.url[media.index])

            --设置音频路径
            local www = CS.UnityEngine.WWW(media.url[media.index])

            yield_return(www)

            if www.error == nil then

                AUDIO.audioSource.clip = www:GetAudioClip()

                --
                MEDIA.currentMedia = media

                --
                AUDIO.AudioPrepared()

                --音频播放结束后重置AudioSource
                --yield_return(CS.UnityEngine.WaitForSeconds(seconds))

                --停止背景音
                --AUDIO.audioSource.gameObject:SetActive(false)
            else
                print("[WWWAudioError]:" .. www.error)
            end
        end)

        assert(coroutine.resume(AUDIO_COROUTINE))
    else
        AUDIO.AudioPrepared()
    end
end

AUDIO.currentProgress = 0.0

function AUDIO.PauseAudio()

    AUDIO.audioSource:Pause()

    --AUDIO.currentProgress = AUDIO.audioSource.time
    MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id].progress = MEDIA.progressSlider.value

    local media = MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id]

    print("Save media " .. media.name .. " >>> " .. MEDIA.currentMedia._id .. "'s progress is " .. media.progress)

    --
    AUDIO.audioSource.gameObject:SetActive(false)

    AUDIO.needUpdateProcess = false

    MEDIA.buttonPlay.gameObject:SetActive(true)

    MEDIA.buttonPause.gameObject:SetActive(false)
end

function AUDIO.Reset()

    --当前进度归零
    AUDIO.audioSource.time = tonumber(0.0)

    print("BeforePause:" .. MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id].progress)

    --
    AUDIO.PauseAudio()

    if MEDIA.currentMedia.type == "AUDIO" then

        local media = MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id]

        print("RESET:" .. MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id].progress)

        --
        AUDIO.TwinkleTip(media)
    end
end

--更新视频进度标识量
VIDEO.needUpdateProcess = false

--Video播放初始化
function VIDEO.InitVideoPlayer()

    --添加Video prepared事件回调
    VIDEO.videoPlayer:prepareCompleted("+", VIDEO.VideoPrepared)

    --视频即将播放结束
    VIDEO.videoPlayer:loopPointReached("+", function()
        print("Video will played finished!")
    end)
end

function VIDEO.VideoPrepared()
    --
    local videoMillis = VIDEO.videoPlayer.frameCount / VIDEO.videoPlayer.frameRate

    --计算视频时长
    MEDIA.totalTimeStamp.text = MEDIA.CalculateTime(math.ceil(videoMillis))

    MEDIA.progressSlider.maxValue = math.ceil(videoMillis)

    MEDIA.buttonPlay.gameObject:SetActive(false)

    MEDIA.buttonPause.gameObject:SetActive(true)

    VIDEO.videoPlayer.time = MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id].progress

    VIDEO.videoPlayer.isLooping = MEDIA.currentMedia.isLoop

    print("[MEDIA]" .. MEDIA.currentMedia.type .. "=>" .. MEDIA.currentMedia.name .. ":MEDIA.currentMediaId=" .. MEDIA.currentMedia._id .. "'s progress is " .. VIDEO.videoPlayer.time)

    --播放视频的模式下显示UI
    MEDIA.UI:SetActive(true)

    --开始播放视频
    VIDEO.videoPlayer:Play()

    --
    VIDEO.needUpdateProcess = true
end

function MEDIA.LostTarget()

    print("Media process => Have lost target!")

    if MEDIA.UI.activeSelf then

        --隐藏视频播放UI
        MEDIA.UI:SetActive(false)

        if MEDIA.currentMedia.type == "AUDIO" then

            --暂停音频播放
            AUDIO.PauseAudio()

        elseif MEDIA.currentMedia.type == "VIDEO" then

            --暂停视频播放
            VIDEO.PauseVideo()
        end

    end
end

VIDEO.PressDownStamp = 0.0

VIDEO.defaultTexture = Resources.Load("video", typeof(CS.UnityEngine.Texture))

--播放视频功能
function VIDEO.PlayVideo(...)

    local media

    if select("#", ...) > 0 then
        media = select(1, ...)
    end

    local rawImage

    if currentMarkerGameObject ~= nil then

        --判断是否是全屏状态
        if VIDEO.renderFullScreenRawImage.transform.gameObject.activeInHierarchy then
            rawImage = VIDEO.renderFullScreenRawImage
        else
            rawImage = currentMarkerGameObject.transform:Find("MediaQuad/3DCanvas/VideoTip"):GetComponentInChildren(typeof(CS.UnityEngine.UI.RawImage))
        end
    else
        LogError(sceneType + " model cannot support playing video temporarily!")
        return
    end

    --rawImage.texture = Resources.Load("video", typeof(CS.UnityEngine.Texture))

    VIDEO.renderRawImage = rawImage

    --设置播放路径
    if media ~= nil then
        --播放当前资源已存下表的资源链接
        VIDEO.videoPlayer.url = media.url[media.index]

        --
        MEDIA.currentMedia = media

    else
        VIDEO.videoPlayer.url = VIDEO.videoPlayer.url
    end

    VIDEO.videoPlayer:Prepare()
end

function VIDEO.PauseVideo()
    --VIDEO.videoPlayer.playbackSpeed = 0.0

    VIDEO.videoPlayer:Pause()

    --VIDEO.videoProgress[currentMarkerGameObject.name] = MEDIA.progressSlider.value
    MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id].progress = MEDIA.progressSlider.value

    VIDEO.needUpdateProcess = false

    MEDIA.buttonPlay.gameObject:SetActive(true)

    MEDIA.buttonPause.gameObject:SetActive(false)

    --currentMarkerGameObject.transform:Find("MediaQuad/3DCanvas/VideoTip"):GetComponentInChildren(typeof(CS.UnityEngine.UI.RawImage)).texture = VIDEO.defaultTexture
end

function VIDEO.Reset()

    VIDEO.PauseVideo()

    --当前进度归零
    VIDEO.videoPlayer.time = 0.0

    if MEDIA.currentMedia.type == "VIDEO" then
        --VIDEO.videoProgress[currentMarkerGameObject.name] = 0.0
        MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id].progress = 0.0

        --视频第一帧图片
        if VIDEO.renderRawImage ~= nil then
            VIDEO.videoPlayer.frame = 1
            VIDEO.renderRawImage.texture = VIDEO.videoPlayer.texture
            --VIDEO.renderRawImage.texture = Resources.Load("video", typeof(CS.UnityEngine.Texture))
        end
    end
end

function USERINTERFACE.InitRectTransform(rectTransform)

    rectTransform.anchorMin = Vector2.zero

    rectTransform.anchorMax = Vector2.one

    rectTransform.localScale = Vector3.one

    rectTransform.anchoredPosition3D = Vector3.zero

    rectTransform.sizeDelta = Vector2.zero

    rectTransform.localRotation = Quaternion.Euler(Vector3.zero)
end

--string.split()
function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c)
        fields[#fields + 1] = c
    end)
    return fields
end

--Update
function update()
    if appVersionType == APPTYPE.DEBUG then
        if Input.GetKeyDown(CS.UnityEngine.KeyCode.LeftControl) and Input.GetKeyDown(CS.UnityEngine.KeyCode.LeftAlt) then
            --
            DEBUG.TaskInfo()
        end
    end

    --播放视频
    if VIDEO.needUpdateProcess then
        --
        if VIDEO.renderRawImage ~= nil then
            VIDEO.renderRawImage.texture = VIDEO.videoPlayer.texture
            local aspectRatioFitter = VIDEO.renderRawImage.gameObject:GetComponent("AspectRatioFitter")
            if aspectRatioFitter ~= nil then
                aspectRatioFitter.aspectMode = CS.UnityEngine.UI.AspectRatioFitter.AspectMode.FitInParent
                if VIDEO.videoPlayer.texture ~= nil then
                    aspectRatioFitter.aspectRatio = VIDEO.videoPlayer.texture.width / VIDEO.videoPlayer.texture.height
                end
            end
        end

        --同步当前视频时间戳
        MEDIA.currentTimeStamp.text = MEDIA.CalculateTime(math.ceil(VIDEO.videoPlayer.time))

        --更新进度条
        MEDIA.progressSlider.value = VIDEO.videoPlayer.time

        --播放音频
    elseif AUDIO.needUpdateProcess then
        --同步当前音频时间戳
        MEDIA.currentTimeStamp.text = MEDIA.CalculateTime(math.ceil(AUDIO.audioSource.time))
        --更新进度条
        MEDIA.progressSlider.value = AUDIO.audioSource.time
    end

    --多媒体资源播放完毕
    if MEDIA.currentTimeStamp.text == MEDIA.totalTimeStamp.text and not AUDIO.audioSource.isPlaying and not VIDEO.videoPlayer.isPlaying then
        print("Media has played once!")
        --
        MEDIA.Reset()
    end
end

---System-Utils

--string to boolean
function string:toboolean()
    if self == "true" then
        return true
    else
        return false
    end
end

--urlDecode
function string:DecodeURI()
    self = string.gsub(self, '%%(%x%x)', function(h)
        return string.char(tonumber(h, 16))
    end)
    return self
end

--trim
function string:trim()
    return (self:gsub("^%s*(.-)%s*$", "%1"))
end

--
function ondisable()
    LogInfo("MainController_Disable!")
    --
    _Global:ReleseData("AbsolutePath")
    --
    if (_Global:GetData("childAppId") ~= nil) then
        _Global:ReleseData("childAppId")
    end
    --
    if (_Global:GetData("versionType") ~= nil) then
        _Global:ReleseData("versionType")
    end
    --
    if (_Global:GetData("pageName") ~= nil) and (_Global:GetData("pageName") ~= "") then
        _Global:ReleseData("pageName")
    end
    --
    if (_Global:GetData("minValue") ~= nil) then
        _Global:ReleseData("minValue")
    end
    if (_Global:GetData("maxScale") ~= nil) then
        _Global:ReleseData("maxScale")
    end
    if (_Global:GetData("minScale") ~= nil) then
        _Global:ReleseData("minScale")
    end
    if _Global:GetData("autoShowPoint") ~= nil then
        _Global:ReleseData("autoShowPoint")
    end
    if _Global:GetData("haveMulModel") ~= nil then
        _Global:ReleseData("haveMulModel")
    end
end

--
function ondestroy()
    LogInfo("MainController_Destroy!")
    --
    LogInfo("Total " .. Task.id .. " tasks executed!")

    --清空书页信息字典数据
    if PageInfoManager.AllPageInfo ~= nil then
        PageInfoManager.AllPageInfo:Clear()
    end

    --销毁任务队列
    for i, item in pairs(PROCESS.TaskQueue) do
        item.task.id = nil
        item.task.name = nil
        item.task.runnable = nil
        item.task.priority = nil
        item.task.callback = nil
        item.state = nil
    end

    --注销所有注册的监听
    COMMON.UnregisterListener()

    --销毁域
    DEBUG = nil
    CALLBACK = nil
    PROCEDURE = nil
    AUDIO = nil
    VIDEO = nil
    MEDIA = nil
    WEBVIEW = nil
    VUFORIA = nil
    PROCESS = nil

    --象征意义的垃圾回收
    COMMON.CollectGarbage()

    COMMON = nil
    APPTYPE = nil

    --释放资源
    Resources.UnloadUnusedAssets()
end

---Test

local buttonTest = GameObject.Find("Root/UI/Main UI Canvas").transform:Find("TestPanel/Button").gameObject:GetComponent("Button")
local buttonTest = GameObject.Find("Root/UI/Main UI Canvas").transform:Find("TestPanel/Button").gameObject:GetComponent("Button")
local inputFiledTest = GameObject.Find("Root/UI/Main UI Canvas").transform:Find("TestPanel/InputField").gameObject:GetComponent("InputField")
buttonTest.onClick:AddListener(function()
    TestUniWebViewOnPC(inputFiledTest.text)
end)
function TestUniWebViewOnPC(url)
    LogInfo(inputFiledTest.text)
    if (url ~= nil) and (url ~= "") then
        CALLBACK.PageListSelected(url)
    else
        CALLBACK.PageListSelected("uniwebview://true?sceneName=P32-25a&pageName=P32-25a&modelName=Model&haveMulModel=&sectionNum=")
    end
end