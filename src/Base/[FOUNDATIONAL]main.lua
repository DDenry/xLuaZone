---
--- Created by DDenry.
--- DateTime: 2019/10/29 11:33
---

--- MiniProgram 业务基本流程

local util = require 'xlua.util'
local yield_return = (require 'cs_coroutine').yield_return

local COMMON = {}
local DEBUG = {}
local CALLBACK = {}
local PROCESS = {}
local PROCEDURE = {}
local VUFORIA = {}
local APPTYPE = {
    DEBUG = 0,
    RELEASE = 1
}

--定制化流程
local SPECIAL = {}

--
local Application = CS.UnityEngine.Application
local RuntimePlatform = CS.UnityEngine.RuntimePlatform
local Screen = CS.UnityEngine.Screen
local SceneManager = CS.UnityEngine.SceneManagement.SceneManager
local GameObject = CS.UnityEngine.GameObject
local Debug = CS.UnityEngine.Debug
local Transform = CS.UnityEngine.Transform
local Quaternion = CS.UnityEngine.Quaternion
local Vector2 = CS.UnityEngine.Vector2
local Vector3 = CS.UnityEngine.Vector3
local Object = CS.UnityEngine.Object
local Destroy = Object.Destroy
local Resources = CS.UnityEngine.Resources
local PlayerPrefs = CS.UnityEngine.PlayerPrefs
local JSON = CS.SimpleJSON.JSON
local Vuforia = CS.Vuforia
local VuforiaBehaviour = Vuforia.VuforiaBehaviour
local VuforiaConfiguration = Vuforia.VuforiaConfiguration
local Input = CS.UnityEngine.Input
local WWW = CS.UnityEngine.WWW
local File = CS.System.IO.File

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
        Debug.LogError("TASK CREATE FAILED!")

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
            Debug.Log("TASK CREATE | " .. self.name .. " -> " .. self.id)
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
        print("POST TASK | " .. self.name .. " -> " .. self.id)

        PROCESS.TaskQueue[#PROCESS.TaskQueue + 1] = {
            task = self,
            --任务状态
            state = "Pending"
        }
        --执行Task
        PROCESS.Execute()
    else
        Debug.LogError("Illegal Task Cannot be Executed!")
    end
end

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
            print("Task " .. i .. " is processing, waiting!")
            return
        elseif item.state == "Done" then
            --
            haveDoneCount = haveDoneCount + 1
        end
    end

    print("Total " .. (#PROCESS.TaskQueue - haveDoneCount) .. ((((#PROCESS.TaskQueue - haveDoneCount) > 1) and " tasks") or " task") .. " in current queue!")

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

            print("EXECUTE TASK | " .. _task.name .. " -> " .. _task.id)
            print("TASK PRIORITY is " .. _task.priority)

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
            print("EXECUTE TASK | " .. PROCESS.TaskQueue[_task.id].task.name .. " -> " .. PROCESS.TaskQueue[_task.id].task.id)
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

--进度监听
function PROCESS.ListenProcess(tasks, event, action)
    for i = 1, #tasks do

        PROCESS.TaskPrepared[tasks[i]].totalAddedCount = PROCESS.TaskPrepared[tasks[i]].totalAddedCount + 1
        PROCESS.TaskPrepared[tasks[i]].event[#PROCESS.TaskPrepared[tasks[i]].event + 1] = event

        print("ListenProcess \n " .. tasks[i] .. "'s event is '" .. event .. "', action is " .. action)

        --判断事件类型
        if action == "ADD" then
            PROCESS.TaskPrepared[tasks[i]].neededResponseCount = PROCESS.TaskPrepared[tasks[i]].neededResponseCount + 1
        elseif action == "DONE" then
            PROCESS.TaskPrepared[tasks[i]].neededResponseCount = PROCESS.TaskPrepared[tasks[i]].neededResponseCount - 1
        elseif action == "FAILED" then
            PROCESS.TaskPrepared[tasks[i]].neededResponseCount = -1
            --TODO:抛出错误异常，程序不可再执行
        else
            Debug.LogError("function 'ListenProcess' used incorrectly!")
        end

        --判断事件是否结束
        if PROCESS.TaskPrepared[tasks[i]].totalAddedCount > 0 then
            if PROCESS.TaskPrepared[tasks[i]].neededResponseCount == 0 then
                --
                print("PROCESS " .. tasks[i] .. " is done !")

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

    print("TASK DESTRUCTOR " .. self.id)
    --
    self = nil
    --调用Lua垃圾回收
    collectgarbage("collect")
    CS.System.GC.Collect()
end

--Root
local Root = GameObject.Find("Root")
local MainStoryboard = GameObject.Find("Main Storyboard")
local EzStoryboardPlayer = MainStoryboard:GetComponent("EzStoryboardPlayer")

--子应用返回到主应用时发送消息
local XLuaLoader = GameObject.Find("XLuaLoader").gameObject:GetComponent(typeof(CS.XLuaLoader))

--Configs
local Configs = GameObject.Find("Configs")

local DataSetLoader = Configs.transform:Find("DataSetLoader").gameObject:GetComponent(typeof(CS.EzComponents.Vuforia.DataSetLoader))

--获取设备屏幕分辨率
local screenHeight = CS.UnityEngine.Screen.height
local screenWidth = CS.UnityEngine.Screen.width

local rootPath

local model = "ONCE_TRACKING"

--
function onenable()

    --释放无用资源
    Resources.UnloadUnusedAssets()

    print("Screen: \n Height -> " .. screenHeight .. " | Width -> " .. screenWidth)

    --判断ARCamera licenseKey是否为空
    if (VuforiaConfiguration.Instance.Vuforia.LicenseKey:trim() == "") then
        --
        Debug.LogError("Vuforia's license key is empty!")
    end

end

local childAppId, versionType, wwwHeadPath

--
function start()

    --设置垃圾自动回收
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul")

    rootPath = EzStoryboardPlayer.Path

    PROCESS.Try2FindChildAppId()

    PROCESS:FindVersionType()

    print("[AppConfig] | " .. childAppId .. "_" .. versionType)

    --
    Task      :new("ConfigureAR", {
        function()
            PROCEDURE:ConfigureARPath()
        end
    }, nil, 0):PostInQueue()

    --创建应用Task并执行
    Task      :new("Prepare", {
        function()

            --设置任务流程
            PROCEDURE:Prepare()

            for i, fun in pairs(PROCEDURE.Node) do
                fun()
            end

            --Task Done
            PROCESS.TaskDone("Prepare")
        end
    }, nil, 0):PostInQueue()

end

function PROCESS.Try2FindChildAppId()
    --判断路径最后一位是否为'/'
    local _rootPath = rootPath
    if _rootPath:sub(_rootPath:len()) == '/' then
        _rootPath = _rootPath:sub(0, _rootPath:len() - 1)
    end
    --
    _rootPath = _rootPath:reverse()
    local childAppId_versionType = _rootPath:sub(0, _rootPath:find("/") - 1):reverse()
    childAppId = childAppId_versionType:sub(0, childAppId_versionType:find("_") - 1)
    --local _versionType = childAppId_versionType:sub(childAppId_versionType:find("_") + 1)
end
function PROCESS.FindVersionType()
    local runTimePlatform = Application.platform

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
        Debug.LogWarning("Path-VersionType is not same as RuntimePlatform!")
    end
end

local CameraAR

--任务结点
PROCEDURE.Node = {}

function PROCEDURE:Prepare()
    PROCEDURE.Node[#PROCEDURE.Node + 1] = PROCEDURE:PrepareARCamera()
    PROCEDURE.Node[#PROCEDURE.Node + 1] = PROCEDURE:PrepareDataSet()
end

function PROCEDURE:ConfigureARPath()

    DataSetLoader.Path = rootPath .. childAppId .. ".xml"

    if GameObject.Find("ARCamera") == nil then
        PROCEDURE:TransferFile()
    else
        PROCESS.TaskDone("ConfigureAR")
    end

end

function PROCEDURE:TransferFile()

    local xmlFile = childAppId .. ".xml"
    local datFile = childAppId .. ".dat"

    PROCEDURE:MoveFile(
            {
                rootPath .. xmlFile,
                rootPath .. datFile
            },
            {
                Application.persistentDataPath .. "/" .. xmlFile,
                Application.persistentDataPath .. "/" .. datFile
            }, function()
                --
                DataSetLoader.Path = Application.persistentDataPath .. "/" .. xmlFile
                --Task Done
                PROCESS.TaskDone("ConfigureAR")
            end)
end

function PROCEDURE:MoveFile(sources, destinies, ...)

    local callback = select(1, ...)

    local count = math.min(#sources, #destinies)

    if count > 0 then
        for i = 1, count do

            local source = sources[i]
            local destiny = destinies[i]

            print("Move\n" .. source .. "\n to \n" .. destiny)

            assert(coroutine.resume(coroutine.create(function()
                local www = WWW(source)

                yield_return(www)

                if www.error == nil then
                    File.WriteAllBytes(destiny, www.bytes)

                else
                    print("WWW.error : " .. www.error)
                    return
                end

                count = count - 1
            end)))
        end

        assert(coroutine.resume(coroutine.create(function()
            while (count ~= 0) do
                yield_return(CS.UnityEngine.WaitForSeconds(1.0))
            end

            --执行完毕
            if callback ~= nil then
                callback()
            end
        end)))
    end
end

function PROCEDURE:PrepareARCamera()
    if Vuforia.VuforiaBehaviour.Instance == nil then
        CameraAR = GameObject.Instantiate(Resources.Load("prefabs/ARCamera"))
        CameraAR.name = "ARCamera"
    else
        CameraAR = VuforiaBehaviour.Instance:GetComponent("Camera").gameObject
    end
end

function PROCEDURE:PrepareDataSet()
    --设置vuforia.xml路径
    --DataSetLoader.Path = "F:/Project/MiniProgram/Assets/Special/Vuforia/hospital.xml"

    assert(coroutine.resume(coroutine.create(function()

        while (not Vuforia.VuforiaARController.Instance.HasStarted) do
            yield_return(1)
        end

        print("[DataSetLoader] | Loaded!")

        DataSetLoader:LoadDataSet()
        DataSetLoader:ActiveDataSet()
        PROCEDURE:PrepareDynamicTargets()

    end)))

end

function PROCEDURE:PrepareDynamicTargets()
    --获取场景中所有GameObject
    local arr_DynamicTargets = GameObject.FindObjectsOfType(typeof(CS.Vuforia.ImageTargetBehaviour))
    --遍历GameObject找到识别图
    for i = 0, (arr_DynamicTargets.Length - 1) do
        --找到识别图
        if (string.find(arr_DynamicTargets[i].gameObject.name, "DynamicTarget") ~= nil) then

            --给识别图添加监听脚本
            arr_DynamicTargets[i].gameObject:AddComponent(typeof(CS.EzComponents.Vuforia.UnityTrackableEventHandler))
            --arr_DynamicTargets[i].gameObject:AddComponent(typeof(CS.CustomTrackableEventHandler))

            --注册监听
            local onFound = arr_DynamicTargets[i].gameObject:GetComponent(typeof(CS.EzComponents.Vuforia.UnityTrackableEventHandler)).onFound
            --local onFound = arr_DynamicTargets[i].gameObject:GetComponent(typeof(CS.CustomTrackableEventHandler)).onFound

            onFound:AddListener(function()
                PROCEDURE:OnFound(arr_DynamicTargets[i])
            end)
        end
    end
end

function PROCEDURE:OnFound(dynamicTarget)

    DataSetLoader:DeactivateDataSet()

    local index = 0

    _, index = dynamicTarget.name:find("DynamicTarget")

    local filter = dynamicTarget.name:sub(index + string.len("-") + 1)

    local target = Root.transform:Find(filter)

    if model == "ALWAYS_TRACKING" then
        target:SetParent(dynamicTarget.gameObject)
    end

    if not target.gameObject.activeSelf then
        --重置
        for i = 0, Root.transform.childCount - 1 do
            Root.transform:GetChild(i).gameObject:SetActive(false)
        end

        target.gameObject:SetActive(true)
    end
end

---Util
--trim
function string:trim()
    return (self:gsub("^%s*(.-)%s*$", "%1"))
end