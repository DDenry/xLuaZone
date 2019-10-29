---
--- Created by DDenry.
--- DateTime: 2017/6/19 19:07
---
--
--local Variable = require 'Tool_StaticVariable'
--
local yield_return = (require 'cs_coroutine').yield_return
local SSMessageManager = CS.SubScene.SSMessageManager.Instance

local COMMON = {}
local PROCESS = {}
local CALLBACK = {}
local StudioData = {}
local MENU = {}
local CROSS = {}

local GameObject = CS.UnityEngine.GameObject
local Transform = CS.UnityEngine.Transform
local Quaternion = CS.UnityEngine.Quaternion
local Vector2 = CS.UnityEngine.Vector2
local Vector3 = CS.UnityEngine.Vector3
local Vector4 = CS.UnityEngine.Vector4
local Object = CS.UnityEngine.Object
local Destroy = Object.Destroy
local JSON = CS.SimpleJSON.JSON
local Color = CS.UnityEngine.Color
local PlayerPrefs = CS.UnityEngine.PlayerPrefs
local Resources = CS.UnityEngine.Resources
local PreviewManager = CS.PreviewManager.Instance
--
local WWWAudioClipLoader = GameObject.Find("Configs/AudioSource"):GetComponent(typeof(CS.EzComponents.WWWAudioClipLoader))
local AudioSource = GameObject.Find("Configs/AudioSource"):GetComponent("AudioSource")
local DOTween = CS.DG.Tweening.ShortcutExtensions

--
local UI = GameObject.Find("Root/UI")
local toolCanvas = GameObject.Find("Root/UI/Main UI Canvas/Tools Panel")
local ToolMenu = toolCanvas.transform:Find("ToolMenu").gameObject
local toolMenu = ToolMenu.transform:Find("Tool Menu").gameObject
local MainUICanvas = GameObject.Find("Root/UI/Main UI Canvas")
local Panel = MainUICanvas.transform:Find("Title Panel/Panel").gameObject
local MulModelList = MainUICanvas.transform:Find("MulModelList").gameObject
local ButtonShowModel = MainUICanvas.transform:Find("Title Panel/Main Subtitle/ButtonShowModel").gameObject:GetComponent("Button")
local Tip = MainUICanvas.transform:Find("Title Panel/Main Subtitle/Tip").gameObject
local OverlayCanvas = UI.transform:Find("Overlay Canvas").gameObject
local Loading = OverlayCanvas.transform:Find("Loading").gameObject
local Contents = GameObject.Find("Root/Models/Contents")
local Models = GameObject.Find("Root/Models")
--爆炸粒子效果
local Explosion = Contents.transform:Find("Explosion").gameObject
--实景与背景切换开关
local SwitchButton = MainUICanvas.transform:Find("Title Panel/UpperRight/SwitchButton/Button").gameObject:GetComponent("Button")
local SwitchButtonText = MainUICanvas.transform:Find("Title Panel/UpperRight/SwitchButton/Button/Text").gameObject:GetComponent("Text")

--Prefab_Point
local PointCanvas = GameObject.Find("Root/UI/Points Canvas")
local Prefab_Point = PointCanvas.transform:Find("Prefab-Point").gameObject
local CallbackFromWebToUnity_MulModelPage
local CallbackFromUniWebView
local Coroutine_Cross

local CameraBG = GameObject.Find("Root/Models").transform:Find("Camera BG").gameObject
local CameraModel = GameObject.Find("Root/Models").transform:Find("Camera").gameObject

local FingerOperator_Model
local FingerOperator_Camera

--
--场景中储存shader的对象OnePlaneBSP_pre
local OnePlaneBSP_pre = GameObject.Find("Root/TmpSave/OnePlaneBSP_pre")

--有切面标识的材质
-- = GameObject.Find("Root/TmpSave/signal1"):GetComponent("MeshRenderer").material
--signal2 = GameObject.Find("Root/TmpSave/signal2"):GetComponent("MeshRenderer").material
--signal3 = GameObject.Find("Root/TmpSave/signal3"):GetComponent("MeshRenderer").material

--爆炸按钮
local PanelBoom = toolMenu.transform:Find("PanelGroup/PanelBoom").gameObject
local ButtonBoom = PanelBoom.transform:Find("ButtonBoom").gameObject:GetComponent("Button")
local ButtonBoomImage = PanelBoom.transform:Find("ButtonBoom/Icon").gameObject:GetComponent("Image")
local ButtonBoomText = PanelBoom.transform:Find("ButtonBoom/Text").gameObject:GetComponent("Text")
--爆炸替补
local PanelBoomSubstitute = toolMenu.transform:Find("PanelGroup/PanelBoomSubstitute").gameObject
--切面按钮
local PanelCross = toolMenu.transform:Find("PanelGroup/PanelCross").gameObject
local ButtonCross = PanelCross.transform:Find("ButtonCross").gameObject:GetComponent("Button")
local ButtonCrossImage = PanelCross.transform:Find("ButtonCross/Icon").gameObject:GetComponent("Image")
local ButtonCrossText = PanelCross.transform:Find("ButtonCross/Text").gameObject:GetComponent("Text")
--
local CrossOperator = PanelCross.transform:Find("CrossOperator").gameObject
local FunctionChoose = CrossOperator.transform:Find("SectionChoose/FunctionChoose").gameObject

--
local Section1On = CrossOperator.transform:Find("SectionChoose/BottomButton/Section1/Section1On"):GetComponent("Button")
local Section1Off = CrossOperator.transform:Find("SectionChoose/BottomButton/Section1/Section1Off"):GetComponent("Button")
local Section2On = CrossOperator.transform:Find("SectionChoose/BottomButton/Section2/Section2On"):GetComponent("Button")
local Section2Off = CrossOperator.transform:Find("SectionChoose/BottomButton/Section2/Section2Off"):GetComponent("Button")
local Section3On = CrossOperator.transform:Find("SectionChoose/BottomButton/Section3/Section3On"):GetComponent("Button")
local Section3Off = CrossOperator.transform:Find("SectionChoose/BottomButton/Section3/Section3Off"):GetComponent("Button")

--轴按钮以及文字Text
local PosYButton = FunctionChoose.transform:Find("Transform").gameObject:GetComponent("Button")
local PosYButtonText = PosYButton.transform:Find("Text").gameObject:GetComponent("Text")
local RotXButton = FunctionChoose.transform:Find("RotateX").gameObject:GetComponent("Button")
local RotXButtonText = RotXButton.transform:Find("Text").gameObject:GetComponent("Text")
local RotZButton = FunctionChoose.transform:Find("RotateY").gameObject:GetComponent("Button")
local RotZButtonText = RotZButton.transform:Find("Text").gameObject:GetComponent("Text")

local SliderPanel = ToolMenu.transform:Find("SliderPanel").gameObject
local Slider = SliderPanel.transform:Find("Slider").gameObject:GetComponent("Slider")
local TextValue = Slider.transform:Find("HandleSlideArea/Handle/Image/Text"):GetComponent("Text")

--切面替补
local PanelCrossSubstitute = toolMenu.transform:Find("PanelGroup/PanelCrossSubstitute").gameObject
--拆解按钮
local PanelPart = toolMenu.transform:Find("PanelGroup/PanelPart").gameObject
local ButtonPart = PanelPart.transform:Find("ButtonPart").gameObject:GetComponent("Button")
local ButtonPartImage = PanelPart.transform:Find("ButtonPart/Icon").gameObject:GetComponent("Image")
local ButtonPartText = PanelPart.transform:Find("ButtonPart/Text").gameObject:GetComponent("Text")
--拆解替补
local PanelPartSubstitute = toolMenu.transform:Find("PanelGroup/PanelPartSubstitute").gameObject
--标注点按钮
local PanelPoint = toolMenu.transform:Find("PanelPoint").gameObject
local ButtonPoint = PanelPoint.transform:Find("ButtonPoint").gameObject:GetComponent("Button")
local ButtonPointImage = PanelPoint.transform:Find("ButtonPoint/Icon").gameObject:GetComponent("Image")
local ButtonPointText = PanelPoint.transform:Find("ButtonPoint/Text").gameObject:GetComponent("Text")
--标注点替补
local PanelPointSubstitute = toolMenu.transform:Find("PanelPointSubstitute").gameObject

--多模型列表按钮
local ButtonMulModelList = GameObject.Find("Root/UI/Main UI Canvas/Title Panel").transform:Find("UpperRight/MulModelListButton").gameObject:GetComponent("Button")
--复位按钮
local ButtonReset = toolMenu.transform:Find("PanelReset/ButtonReset").gameObject:GetComponent("Button")
local ButtonResetImage = toolMenu.transform:Find("PanelReset/ButtonReset/Icon").gameObject:GetComponent("Image")
local ButtonResetText = toolMenu.transform:Find("PanelReset/ButtonReset/Text").gameObject:GetComponent("Text")

local ButtonReset0 = toolMenu.transform:Find("PanelReset/ButtonReset0").gameObject:GetComponent("Button")

--动画按钮
local ButtonAnimationPlay = toolCanvas.transform:Find("ButtonAnimationPlay").gameObject:GetComponent("Button")
--local ButtonAnimationPlayText = toolCanvas.transform:Find("ButtonAnimationPlay/Text").gameObject:GetComponent("Text")
local ButtonAnimationPause = toolCanvas.transform:Find("ButtonAnimationPause").gameObject:GetComponent("Button")
--local ButtonAnimationPauseText = toolCanvas.transform:Find("ButtonAnimationPause/Text").gameObject:GetComponent("Text")

--[DDenry]********************************************************************************
local CrossUI = toolCanvas.transform:Find("Cross_UI").gameObject

local MenuUI = CrossUI.transform:Find("Menu UI").gameObject
local OperatePanel = MenuUI.transform:Find("Operate Panel").gameObject
local BottomButton = MenuUI.transform:Find("Bottom Button").gameObject
--
--local SliderPanel = CrossUI.transform:Find("Slider Panel").gameObject
--local ShowPanel = CrossUI.transform:Find("Show Panel").gameObject

--[[--切面Section1状态按钮
local Section1On = BottomButton.transform:Find("Section1/Section1On").gameObject:GetComponent("Button")
local Section1Off = BottomButton.transform:Find("Section1/Section1Off").gameObject:GetComponent("Button")
--切面Section2状态按钮
local Section2On = BottomButton.transform:Find("Section2/Section2On").gameObject:GetComponent("Button")
local Section2Off = BottomButton.transform:Find("Section2/Section2Off").gameObject:GetComponent("Button")
--切面Section3状态按钮
local Section3On = BottomButton.transform:Find("Section3/Section3On").gameObject:GetComponent("Button")
local Section3Off = BottomButton.transform:Find("Section3/Section3Off").gameObject:GetComponent("Button")]]

--[[--轴按钮以及文字Text
local PosYButton = OperatePanel.transform:Find("Pos Panel/PosYButton").gameObject:GetComponent("Button")
local PosYButtonText = PosYButton.transform:Find("Text").gameObject:GetComponent("Text")
local RotXButton = OperatePanel.transform:Find("Rot Panel/RotXButton").gameObject:GetComponent("Button")
local RotXButtonText = RotXButton.transform:Find("Text").gameObject:GetComponent("Text")
local RotZButton = OperatePanel.transform:Find("Rot Panel/RotZButton").gameObject:GetComponent("Button")
local RotZButtonText = RotZButton.transform:Find("Text").gameObject:GetComponent("Text")]]

--位置和旋转
local PosPanelImage = OperatePanel.transform:Find("Bottom Panel/Pos/Panel").gameObject:GetComponent("Image")
local RotPanelImage = OperatePanel.transform:Find("Bottom Panel/Rot/Panel").gameObject:GetComponent("Image")

--隐藏切面的Toggle
local Toggle = OperatePanel.transform:Find("Top Panel/Toggle").gameObject:GetComponent("Toggle")
local ToggleText = Toggle.transform:Find("ToggleText").gameObject:GetComponent("Text")

--[[--Slider
local Slider = SliderPanel.transform:Find("Slider").gameObject:GetComponent("Slider")
local TextName = SliderPanel.transform:Find("Text Panel/TextName").gameObject:GetComponent("Text")
local TextValue = SliderPanel.transform:Find("Text Panel/TextValue").gameObject:GetComponent("Text")
local ShowedValue = SliderPanel.transform:Find("Text Panel/Value Panel/ShowedValue").gameObject:GetComponent("Text")

--Slider微调按钮，+/-
local UpButton = SliderPanel.transform:Find("UpButton").gameObject:GetComponent("Button")
local DownButton = SliderPanel.transform:Find("DownButton").gameObject:GetComponent("Button")

--输入框
local InputField = SliderPanel.transform:Find("Text Panel/Value Panel").gameObject:GetComponent("InputField")

--底部显示切面位移以及旋转信息
local ShowPos = ShowPanel.transform:Find("ShowPos").gameObject:GetComponent("Text")
local ShowRot = ShowPanel.transform:Find("ShowRot").gameObject:GetComponent("Text")]]

--爆炸操作/拆解
local BoomUI = toolCanvas.transform:Find("Boom_UI").gameObject
local PartUI = toolCanvas.transform:Find("Part_UI").gameObject

--爆炸按钮
local ButtonExplosive = BoomUI.transform:Find("Explosive").gameObject:GetComponent("Button")
local ButtonExplosiveText = BoomUI.transform:Find("Explosive/Text").gameObject:GetComponent("Text")
local ButtonRestored = BoomUI.transform:Find("Restored").gameObject:GetComponent("Button")
local ButtonRestoredText = BoomUI.transform:Find("Restored/Text").gameObject:GetComponent("Text")

--拆解按钮
local ButtonNext = PartUI.transform:Find("next").gameObject:GetComponent("Button")
local ButtonNextText = ButtonNext.gameObject.transform:Find("Text"):GetComponent("Text")
local ButtonReplay = PartUI.transform:Find("replay").gameObject:GetComponent("Button")
local ButtonReplayText = ButtonReplay.gameObject.transform:Find("Text"):GetComponent("Text")
local ButtonBack = PartUI.transform:Find("back").gameObject:GetComponent("Button")
local ButtonBackText = ButtonBack.gameObject.transform:Find("Text"):GetComponent("Text")

--[FindAllNeededObjects]  *****************

local UniWebView_MulModelPage = GameObject.Find("Configs/UniWebView_MulModelPage")
--
local UniWebViewPanelButton = GameObject.Find("Root/UI").transform:Find("Overlay Canvas/UniWebViewPanel").gameObject:GetComponent("Button")
--拆解状态显示Text
local step_text = PartUI.transform:Find("step_text").gameObject:GetComponent("Text")

--
local defaultViewTransform = {}
local haveViewPort = false
local animation

--记录拆解步骤索引
local currentIndex = 0
--
local step = 0

--普通颜色
COMMON.normalColor = {
    r = 172 / 255,
    g = 172 / 255,
    b = 172 / 255,
    a = 1
}

--不可点击状态
COMMON.nonClickable = {
    r = 1,
    g = 1,
    b = 1,
    a = 1
}

--选中状态颜色
COMMON.selectedColor = _Global:GetData("themeColor")

--
local textHalfTransparentColor = {
    r = 1, g = 1, b = 1, a = 0.5
}
local textNoTransparentColor = {
    r = 1, g = 1, b = 1, a = 1
}

--设置切面Pos范围
local RangePos = {
    minValue = -8,
    maxValue = 8
}

--设置切面Rot范围
local RangeRot = {
    minValue = -180,
    maxValue = 180
}
--
local UniWebView_Point = GameObject.Find("Configs/UniWebView_Point")
local childAppId = _Global:GetData("childAppId")
local versionType = _Global:GetData("versionType")
local sceneType = _Global:GetData("sceneType")
local pageListType
local pageListType_H5 = "pageListType_H5"
local pageListType_UIWidget = "pageListType_UIWidget"

--
local wwwAssetPath = _Global:GetData("wwwAssetPath")

local BoomStep = -1
local SelfOwnedAnimationStep = -1
--
--local screenHeight = CS.UnityEngine.Screen.height
local screenWidth = CS.UnityEngine.Screen.width

local animationGameObject = {}
local animationGameObjectId = {}
--
local table_point = {}
local table_prefab_point_normal = {}
local table_prefab_point_step = {}
local table_prefab_point = {}

--剖切菜单互斥按钮
local menuDeselectButton = {
    PosYButton,
    RotXButton,
    RotZButton
}
--切面参数[显示切面数量，是否可自调(默认为否，不显示切面菜单)]
local sectionArguments = {
    sectionNum = 0,
    canControl = false
}

local OriObject
local SectionXY
local SectionXZ
local SectionYZ

--标识当前操作切面
local currentSection = 0

--标识当前操作类型[PosX,PosY,PosZ,RotX,RotY,RotZ]
--[transform/rotate+/rotate-]
local currentSignal = ""

--标识Slider的操作类型(true表示吸附，false表示不吸附)
local operateType = true
--
local tmp_value = 0.0
local sliderPosValue = 0.0

--切面模式状态
local updateCrossState = false

--
local Quad1Pos = {
    x, y, z
}
--
local Quad1Rot = {
    x, z, y
}

--
local Quad2Pos = {
    x, y, z
}
--
local Quad2Rot = {
    x, y, z
}

--
local Quad3Pos = {
    x, y, z
}
--
local Quad3Rot = {
    x, y, z
}

local Quad1Info = {
    Quad1Pos, Quad1Rot
}

local Quad2Info = {
    Quad2Pos, Quad2Rot
}

local Quad3Info = {
    Quad3Pos, Quad3Rot
}

--
local QuadArr = {
    Quad1Info, Quad2Info, Quad3Info
}

--设定记录Pos及Rot标识
local PosY = 0.0
local RotX = 0.0
local RotY = 0.0
local RotZ = 0.0

local Quad1
local Quad2
local Quad3
local meshRenderer1
local meshRenderer2
local meshRenderer3
--
function onenable()
    print("SubController_Enable!")
    Resources.UnloadUnusedAssets()

    print(">>>>>> Tool_Enable:", collectgarbage("count") .. "K")
    --
    if Variable then
        print("Required Tool_StaticVariable.lua in SubController!")
    else
        print("Give up the method 'require()' temporarily!")
    end

    --初始化数据table
    PROCESS.InitDataTable()

    --模型
    OriObject = GameObject.Find("Root/Models/Contents/Prefab-ModelLoader/MakerAll")

    --遍历ObjectId
    StudioData.FindStudioObjectData()

    --加载标注点
    local COROUTINE_LoadPointData = coroutine.create(StudioData.LoadPointData)
    assert(coroutine.resume(COROUTINE_LoadPointData))
end

--
function start()
    print("SubController_Start!")

    --设置垃圾自动回收
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul")

    --获取pageListType
    if _Global:GetData("pageListType") ~= nil then
        if _Global:GetData("pageListType") == pageListType_H5 then
            pageListType = pageListType_H5
        elseif _Global:GetData("pageListType") == pageListType_UIWidget then
            pageListType = pageListType_UIWidget
        end
    else
        --
        pageListType = pageListType_UIWidget
    end

    --添加监听
    COMMON.RegisterListener()
end

--获取模型中所有挂ObjectData脚本的物体
function StudioData.FindStudioObjectData()
    print("FindStudioObjectData!")
    --local objects = GameObject.FindObjectsOfType(typeof(CS.SceneStudio.ObjectData))
    local objects = CS.SceneStudio.SceneObjectsManager.Instance.Objects
    if objects.Length > 0 then
        --遍历模型物体和ID
        for i = 0, objects.Length - 1 do
            animationGameObject[i] = objects[i].gameObject
            animationGameObjectId[i] = objects[i].gameObject:GetComponent(typeof(CS.SceneStudio.ObjectData)).ID

            --获取视口位置
            if objects[i].gameObject:GetComponent(typeof(CS.SceneStudio.ViewPortData)) ~= nil then
                --视口配置信息存在
                haveViewPort = true

                --存在视口文件，则读取(仅读取旋转信息)
                defaultViewTransform['localRotation'] = {
                    x = -objects[i].gameObject.transform.localRotation.x,
                    y = -objects[i].gameObject.transform.localRotation.y,
                    z = -objects[i].gameObject.transform.localRotation.z,
                    w = objects[i].gameObject.transform.localRotation.w
                }
            end

            --将id和gameObject对应
            _Global:SetData(animationGameObjectId[i], objects[i].gameObject)
            _Global:SetData("position_" .. animationGameObjectId[i], objects[i].gameObject.transform.localPosition)
            _Global:SetData("rotation_" .. animationGameObjectId[i], objects[i].gameObject.transform.localRotation)
            _Global:SetData("scale_" .. animationGameObjectId[i], objects[i].gameObject.transform.localScale)
        end
    end
    --
    print("Match ID and models Accomplished!")
end

--加载标注点信息
function StudioData.LoadPointData()
    --
    print("Load PointData Enter!")

    CS.SceneStudio.PersistentInfoPoints:Load(projectPath + pointFile.Substring(2))

    if OriObject:GetComponentsInChildren(typeof(CS.SceneStudio.PointData)).Length > 0 then
        for i = 0, OriObject:GetComponentsInChildren(typeof(CS.SceneStudio.PointData)).Length - 1 do
            --获取所有标注点
            table_point[i] = OriObject:GetComponentsInChildren(typeof(CS.SceneStudio.PointData))[i]
        end

        --添加WebView
        UniWebView_Point:AddComponent(typeof(CS.CallbackFromWebToUnity))

        --获取标注点WebView回调
        CallbackFromUniWebView = UniWebView_Point:GetComponent(typeof(CS.CallbackFromWebToUnity))

        --注册WebView回调监听
        CallbackFromUniWebView.OnReceived:AddListener(ClosePointWebView)

        --普通标注点数量
        local point_normal_number = 0
        --步骤标注点数量
        local point_step_number = 0

        --生成相应的标注点Prefab
        for i = 0, #table_point do
            --获取场景中的预置件
            local Prefab_Point_Tmp = CS.UnityEngine.Object.Instantiate(Prefab_Point)
            Prefab_Point_Tmp.name = "Prefab_Point:" .. i
            Prefab_Point_Tmp.transform:SetParent(Prefab_Point.transform.parent)
            --
            Prefab_Point_Tmp:GetComponent(typeof(CS.EzComponents.UnityUI.TransformPointTracker)).TargetTransform = table_point[i].transform
            Prefab_Point_Tmp:GetComponent(typeof(CS.EzComponents.DepthCulling)).TargetTransform = table_point[i].transform
            Prefab_Point_Tmp:GetComponent(typeof(CS.EzComponents.TransformSetter)).Value = table_point[i].transform
            Prefab_Point_Tmp:GetComponent(typeof(CS.EzComponents.TransformSetter)):Set()

            --显示标注点名称
            if (table_point[i].name ~= nil) and (table_point[i].name:trim() ~= "") then
                --判断是否为步骤标注点
                if (string.sub(table_point[i].name, 1, 1) ~= "#") then
                    --
                    Prefab_Point_Tmp:GetComponent(typeof(CS.EzComponents.StringSetter)).Value = "   " .. table_point[i].name .. "   "

                else
                    Prefab_Point_Tmp:GetComponent(typeof(CS.EzComponents.StringSetter)).Value = string.gsub(table_point[i].name, "#", "")
                end
            else
                Prefab_Point_Tmp:GetComponent(typeof(CS.EzComponents.StringSetter)).Value = "PointInfo"
            end
            --
            Prefab_Point_Tmp:GetComponent(typeof(CS.EzComponents.StringSetter)):Set()

            local sceneName = _Global:GetData("sceneName")
            --设置标注点默认H5页
            local point_url = wwwAssetPath .. sceneName .. "/" .. table_point[i]:GetComponent(typeof(CS.SceneStudio.ObjectData)).ID .. ".html"

            --如果存在相对应的标注点Html则添加跳转监听
            local www = CS.UnityEngine.WWW(point_url)
            yield_return(www)
            if www.error == nil then
                Prefab_Point_Tmp:GetComponent(typeof(CS.EzComponents.QuickEvent)).onEvent:AddListener(
                --点击标注点打开WebView
                        function()
                            if _Global:GetData("RunningType") == "Single" and versionType == "android" then
                                point_url = "file:///android_asset/" .. childAppId .. "_" .. versionType .. "/" .. sceneName .. "/" .. table_point[i]:GetComponent(typeof(CS.SceneStudio.ObjectData)).ID .. ".html"
                            else
                                point_url = wwwAssetPath .. sceneName .. "/" .. table_point[i]:GetComponent(typeof(CS.SceneStudio.ObjectData)).ID .. ".html"
                            end

                            --打开WebView
                            CallbackFromUniWebView:LoadFromFile(point_url, 0, 0, 0)

                            --如果音频动画不为nil
                            if (AudioSource.clip ~= nil) then
                                --暂停音频播放
                                AudioSource:Pause()
                            end
                        end)
                --不存在Html的标注点
            else
                --设置Button颜色为不可点击
                local tmp_color = { r = 50 / 255, g = 50 / 255, b = 50 / 255, a = 1 }
                Prefab_Point_Tmp.transform:Find("GameObject/L/L UP/GameObject/Button").gameObject:GetComponent("Image").color = tmp_color
                Prefab_Point_Tmp.transform:Find("GameObject/L/L DOWN/GameObject/Button").gameObject:GetComponent("Image").color = tmp_color
                Prefab_Point_Tmp.transform:Find("GameObject/R/R UP/GameObject/Button").gameObject:GetComponent("Image").color = tmp_color
                Prefab_Point_Tmp.transform:Find("GameObject/R/R DOWN/GameObject/Button").gameObject:GetComponent("Image").color = tmp_color
            end

            --区分步骤标注点与普通标注点
            if (string.sub(table_point[i].name, 1, 1) == "#") then
                --储存步骤标注点
                point_step_number = point_step_number + 1
                --取消步骤标注点的相机深度检测
                Destroy(Prefab_Point_Tmp.gameObject:GetComponent(typeof(CS.EzComponents.DepthCulling)))
                table_prefab_point_step[point_step_number] = Prefab_Point_Tmp
            else
                --储存普通标注点
                point_normal_number = point_normal_number + 1
                table_prefab_point_normal[point_normal_number] = Prefab_Point_Tmp
            end
            --将所有标注点存入 table_prefab_point
            table_prefab_point[i] = Prefab_Point_Tmp
        end
    else
        print("There's no point data!")
    end

    --判断是否有普通标注点
    if #table_prefab_point_normal > 0 then
        --设置标准点按钮可点击
        MENU.functionsList['POINT'] = true

    else
        --不存在标注点
        MENU.functionsList['POINT'] = false
    end

    --为所有标注点绑定滑动事件
    for i, pointPrefab in pairs(table_prefab_point) do
        --绑定标注点自动滑动
        assert(coroutine.resume(coroutine.create(function()
            if pointPrefab ~= nil then
                AutoSlide(pointPrefab)
            end
        end)))
    end

    --数据加载完毕
    StudioData.DataLoadedCompleted()
end

--
function AutoSlide(Prefab_Point_Tmp)
    if Prefab_Point_Tmp ~= nil then
        --判断该标注点是否显示
        if Prefab_Point_Tmp.activeSelf then
            --判断深度检测是否显示
            if Prefab_Point_Tmp:GetComponentInChildren(typeof(CS.UnityEngine.UI.Text)) ~= nil then
                local rectTransform = Prefab_Point_Tmp:GetComponentInChildren(typeof(CS.UnityEngine.UI.Text)).gameObject:GetComponent("RectTransform")

                yield_return(1)

                --需要滑动
                if rectTransform.sizeDelta.x > 0 then
                    --从左向右滑动
                    if rectTransform.anchoredPosition.x <= -rectTransform.sizeDelta.x then
                        rectTransform.anchoredPosition = Vector2(0, rectTransform.anchoredPosition.y)
                    else
                        rectTransform.anchoredPosition = Vector2(rectTransform.anchoredPosition.x - 10, rectTransform.anchoredPosition.y)
                    end
                    --速率为每秒更新
                    yield_return(CS.UnityEngine.WaitForSeconds(1))
                else
                    --不需要滑动，居中显示
                    local _texts = Prefab_Point_Tmp:GetComponentsInChildren(typeof(CS.UnityEngine.UI.Text), true)
                    for i = 0, _texts.Length - 1 do
                        _texts[i].gameObject:GetComponent(typeof(CS.UnityEngine.UI.ContentSizeFitter)).enabled = false
                        _texts[i].gameObject:GetComponent("RectTransform").offsetMax = Vector2.zero
                    end
                    return
                end
            else
                --每5帧检测一次
                yield_return(5)
            end
        else
            --每5帧检测一次
            yield_return(CS.UnityEngine.WaitForSeconds(1))
        end

        --递归
        assert(coroutine.resume(coroutine.create(function()
            if Prefab_Point_Tmp ~= nil then
                AutoSlide(Prefab_Point_Tmp)
            end
        end)))
    else
        return
    end
end

--
function CALLBACK.OnPageFinished(content)
    print("mulModelHtml_Page Finished!")
    local statusCode = string.sub(content, 0, string.find(content, "@") - 1)
    local url = string.sub(content, string.find(content, "@") + 1)
    print("statusCode:" .. statusCode)
    print("url:" .. url)
    --显示背板
    UniWebViewPanelButton.gameObject:SetActive(true)
end

--
function CALLBACK.OnPageErrorReceived(content)
    print("mulModelHtml_Page ErrorReceived:")
    local errorCode = string.sub(content, 0, string.find(content, "@") - 1)
    local errorMessage = string.sub(content, string.find(content, "@") + 1)
    print("errorCode:" .. errorCode)
    print("errorMessage:" .. errorMessage)
end

--是否开始Animator动画
function StudioData.ShowAnimatorFunction(state)
    --
    animation.enabled = state

    --回到动画初始帧位置
    animation:Stop()

    if state then
        --播放键显示
        ButtonAnimationPlay.gameObject:SetActive(true)
        --暂停键隐藏
        ButtonAnimationPause.gameObject:SetActive(false)
    else
        --隐藏播放键
        ButtonAnimationPlay.gameObject:SetActive(false)
        --暂停键隐藏
        ButtonAnimationPause.gameObject:SetActive(false)
    end
end

function StudioData.HandleAnimation()

    --判断是否存在爆炸动画
    for i = 0, CS.SceneStudio.TimelinesManager.Instance.Timelines.Count - 1 do
        if CS.SceneStudio.TimelinesManager.Instance.Timelines[i].Name == "爆炸" then
            if CS.SceneStudio.TimelinesManager.Instance.Timelines[i].Groups.Count > 0 then
                --标记爆炸动画步骤
                BoomStep = i

                --设置 haveBoom = true
                MENU.functionsList['BOOM'] = true
            end
        end

        --判断是否存在自带动画
        if CS.SceneStudio.TimelinesManager.Instance.Timelines[i].Name == "自带动画" then
            if CS.SceneStudio.TimelinesManager.Instance.Timelines[i].Groups.Count > 0 then
                --标记自带动画步骤
                SelfOwnedAnimationStep = i

                --设置 haveSelfOwnedAnimation = true
                MENU.functionsList['SELF_ANIMATION'] = true
            end
        end
    end

    --判断剩余的动画
    if CS.SceneStudio.TimelinesManager.Instance.Timelines.Count > (((MENU.functionsList['BOOM'] and 1) or 0) + ((MENU.functionsList['SELF_ANIMATION'] and 1) or 0)) then
        --获取拆装步数
        step = CS.SceneStudio.TimelinesManager.Instance.Timelines.Count - (((MENU.functionsList['BOOM'] and 1) or 0) + ((MENU.functionsList['SELF_ANIMATION'] and 1) or 0))
        --
        if step <= 1 then
            --判断是否存在有意义的动画数据
            if CS.SceneStudio.TimelinesManager.Instance.Timelines[0].Groups.Count > 0 then
                --标记 havePart = true
                MENU.functionsList['PART'] = true
            end
        else
            --
            MENU.functionsList['PART'] = true
        end
    end

    --
    print("AnimationFunction:", (MENU.functionsList['BOOM'] and "Have Boom!") or "No Boom!")
    print("AnimationFunction", (MENU.functionsList['SELF_ANIMATION'] and "Have SelfOwnedAnimation!") or "No SelfOwnedAnimation!")
    print("AnimationFunction", (MENU.functionsList['PART'] and "Have Part!") or "No Part!")
end
--
function PROCESS.HandleLoadedData()
    --处理动画信息
    StudioData.HandleAnimation()

    --获取切面参数
    sectionArguments["sectionNum"] = ((_Global:GetData("_sectionNum") ~= nil) and tonumber(_Global:GetData("_sectionNum"))) or tonumber(_Global:GetData("sectionNum"))
    sectionArguments["canControl"] = ((_Global:GetData("canControl") == nil) and false) or _Global:GetData("canControl")
    print("Section model is :sectionNum=" .. sectionArguments["sectionNum"] .. " canControl=" .. tostring(sectionArguments["canControl"]))

    --判断是否存在滑杆最值参数
    if (_Global:GetData("minValue") ~= nil) then
        RangePos.minValue = _Global:GetData("minValue")
        RangePos.maxValue = _Global:GetData("maxValue")
        print("Slider values have set!")
        print("Slider_MinValue:" .. _Global:GetData("minValue"))
        print("Slider_MaxValue:" .. _Global:GetData("maxValue"))
    else
        _Global:SetData("minValue", -5)
        _Global:SetData("maxValue", 5)
    end

    --
    if sectionArguments["sectionNum"] == 0 then
        --
        MENU.functionsList['CROSS'] = false

    elseif sectionArguments["sectionNum"] > 0 then
        --开启剖切功能
        MENU.functionsList['CROSS'] = true
    else
        print("error!Invalid sectionArguments:" .. sectionArguments["sectionNum"])
    end
end

--准备功能菜单
function MENU.PrepareMenu()
    --遍历菜单列表,将数据解析结果与字符下标匹配
    for i, item in pairs(MENU.functionsList) do
        --自带动画
        if i == "SELF_ANIMATION" then
            if item then
                --如果存在自带动画，则默认为当前操作
                table.insert(MENU.functionsList['CURRENT_FUNCTION'], "SELF_ANIMATION")

                animation = OriObject:GetComponentInChildren(typeof(CS.UnityEngine.Animation))
                --设置Animation模式为Loop
                animation.wrapMode = CS.UnityEngine.WrapMode.Loop
                --
                StudioData.ShowAnimatorFunction(item)
            end
            --爆炸动画
        elseif i == "BOOM" then
            PanelBoom:SetActive(item)
            PanelBoomSubstitute:SetActive(not item)
            --拆装动画
        elseif i == "PART" then
            PanelPart:SetActive(item)
            PanelPartSubstitute:SetActive(not item)
            --剖切
        elseif i == "CROSS" then
            --
            PanelCross:SetActive(item)
            PanelCrossSubstitute:SetActive(not item)

            --存在剖切
            if item then
                --判断操作面板显示位置
                if not MENU.functionsList['BOOM'] or not MENU.functionsList['PART'] then
                    FunctionChoose:GetComponent("RectTransform").anchorMin = Vector2(FunctionChoose:GetComponent("RectTransform").anchorMin.x, -3)
                    FunctionChoose:GetComponent("RectTransform").anchorMax = Vector2(FunctionChoose:GetComponent("RectTransform").anchorMax.x, 0)
                else
                    FunctionChoose:GetComponent("RectTransform").anchorMin = Vector2(FunctionChoose:GetComponent("RectTransform").anchorMin.x, 1)
                    FunctionChoose:GetComponent("RectTransform").anchorMax = Vector2(FunctionChoose:GetComponent("RectTransform").anchorMax.x, 4)
                end

                --初始化剖切功能
                Coroutine_Cross = coroutine.create(function()
                    CROSS.InitCrossFunction()
                end)
                --
                assert(coroutine.resume(Coroutine_Cross))
                --
                Section1Off.interactable = true
                Section2Off.interactable = true
                Section3Off.interactable = true
                --
                if sectionArguments["sectionNum"] == 1 then
                    Section2Off.interactable = false
                    Section3Off.interactable = false
                elseif sectionArguments["sectionNum"] == 2 then
                    Section3Off.interactable = false
                end

                --根据参数设置切面功能
                if ((sectionArguments["canControl"] == nil) or (not sectionArguments["canControl"])) then
                    MenuUI:SetActive(false)
                elseif sectionArguments["canControl"] then
                    MenuUI:SetActive(true)
                end
                --不存在剖切
            else
                --
                ButtonCrossImage.color = COMMON.normalColor
                ButtonCrossText.color = COMMON.normalColor
            end
            --标注点
        elseif i == "POINT" then
            PanelPoint:SetActive(item)
            PanelPointSubstitute:SetActive(not item)

            --判断是否自动显示标注点
            if _Global:GetData("autoShowPoint") ~= nil then
                if _Global:GetData("autoShowPoint"):toboolean() then
                    print("Points will auto show!")
                    --打开标注点
                    ButtonPoint.onClick:Invoke()
                end
            end

            --虚实景切换
        elseif i == "VIEW_TRANSFER" then
            --只有AR&VR模式下才有该功能
            if sceneType == "AR&VR" then
                --判断是否显示背景切换按钮
                SwitchButton.gameObject:SetActive(item)
                --
                if _Global:GetData("defaultView") == "Real" then
                    SwitchButton.gameObject:GetComponent("Image").color = { r = 60 / 255, g = 120 / 255, b = 40 / 255, a = 1 }
                    SwitchButtonText.text = "实景"
                    SwitchButtonText.alignment = CS.UnityEngine.TextAnchor.MiddleRight
                    SwitchButtonText.gameObject.transform:SetSiblingIndex(0)
                else
                    SwitchButton.gameObject:GetComponent("Image").color = { r = 1, g = 1, b = 1, a = 90 / 255 }
                    SwitchButtonText.text = "虚景"
                    SwitchButtonText.alignment = CS.UnityEngine.TextAnchor.MiddleLeft
                    SwitchButtonText.gameObject.transform:SetSiblingIndex(1)
                end
            end
        end
    end

    print("FunctionMenu Prepared!")
end

--场景中所有数据已加载完毕
function StudioData.DataLoadedCompleted()
    print("All the studio data has been loaded!")

    print("The scene " .. (haveViewPort and "have" or "don't have") .. " view port!")

    --解析数据
    PROCESS.HandleLoadedData()

    --准备菜单栏目
    MENU.PrepareMenu()

    --
    PROCESS.PrepareScene()
end

--准备基础场景
function PROCESS.PrepareScene()
    --获取到手势操作实例
    FingerOperator_Model = Contents.transform:GetComponent(typeof(CS.XLuaBehaviour))
    FingerOperator_Camera = CameraModel:GetComponent(typeof(CS.XLuaBehaviour))

    --模型调整为预设角度
    Contents.transform.localRotation = defaultViewTransform['localRotation']

    --将模型缩放至0.05(为适配工具校验大小为200)
    Models.transform.localScale = Vector3(0.05, 0.05, 0.05)

    --开启协程
    assert(coroutine.resume(coroutine.create(function()

        --开启模型相机
        CameraModel:SetActive(true)

        --相机动画时长为1.0s
        --等待相机动画结束后
        yield_return(CS.UnityEngine.WaitForSeconds(1.0))

        print("Camera's animation played completed!")

        --开启手势操作
        FingerOperator_Model.enabled = true

        --隐藏Loading界面
        Loading:SetActive(false)

        --判断是否显示多模型列表
        PROCESS.NeedShowMulModelListOrNot()
    end)))

    --显示返回键背景Panel
    Panel:SetActive(true)

    --显示功能菜单
    toolMenu:SetActive(true)

    --
    print("Current have " .. #MENU.functionsList['CURRENT_FUNCTION'] .. " function(s) in the menu~")
end

--
function PROCESS.NeedShowMulModelListOrNot()

    --需要显示多模型
    if (_Global:GetData("haveMulModel") ~= nil) and (_Global:GetData("haveMulModel") ~= "") and (_Global:GetData("haveMulModel") ~= "False") and (_Global:GetData("haveMulModel") ~= "false") then
        --显示多模型列表按钮
        ButtonMulModelList.gameObject:SetActive(true)

        if pageListType == pageListType_H5 then
            --显示H5
            PROCESS.ShowMulModelHtml()
        elseif pageListType == pageListType_UIWidget then
            --显示U3D 模型列表
            PROCESS.ShowMulModelList()
        end
    else
        print("There's no need to show mulModel!")
    end
end

--U3D 多模型列表
function PROCESS.ShowMulModelList()
    print("U3D 多模型列表~")
    --显示MulModelList
    MulModelList:SetActive(true)
end

--判断是否显示第二页H5
function PROCESS.ShowMulModelHtml()
    print("H5 多模型列表~")
    --判断是否显示第二页H5
    if (_Global:GetData("haveMulModel") ~= nil) and (_Global:GetData("haveMulModel") ~= "") then
        --local haveMulModel = WWWAssetPath .. _Global:GetData("haveMulModel")
        local haveMulModel
        if versionType == "android" then
            haveMulModel = "file:///android_asset/" .. childAppId .. "_" .. versionType .. "/" .. _Global:GetData("haveMulModel")
        else
            haveMulModel = wwwAssetPath .. _Global:GetData("haveMulModel")
        end
        print("haveMulModel:" .. haveMulModel)
        --显示多模型按钮
        ButtonShowModel.gameObject:SetActive(true)
        --
        --UniWebView_MulModelPage:AddComponent(typeof(CS.CallbackFromWebToUnity))
        CallbackFromWebToUnity_MulModelPage = UniWebView_MulModelPage:GetComponent(typeof(CS.CallbackFromWebToUnity))
        --显示mulModelHtml
        CallbackFromWebToUnity_MulModelPage:LoadFromFile(haveMulModel, 1, 0, 0, screenWidth, math.ceil(screenWidth * 260 / 1334))
        --
        CallbackFromWebToUnity_MulModelPage._webView:Reload()
        --
        CallbackFromWebToUnity_MulModelPage.OnPageFinished:AddListener(CALLBACK.OnPageFinished)
        --
        CallbackFromWebToUnity_MulModelPage.OnPageErrorReceived:AddListener(CALLBACK.OnPageErrorReceived)

        --显示背板
        UniWebViewPanelButton.gameObject:SetActive(true)
    else
        --判断是否需要显示Tip界面
        PROCESS.NeedShowTipUIOrNot()
    end
end

--判断是否显示Tip界面
function PROCESS.NeedShowTipUIOrNot()
    --判断是否存在多模型下拉按钮
    if ButtonShowModel.gameObject.activeSelf then
        print("NeedShowTipUIOrNot:" .. PlayerPrefs.GetString("subApp_" .. childAppId, "SHOW"))
        --判断是否是第一次进入子应用
        if PlayerPrefs.GetString("subApp_" .. childAppId) == "SHOW" then
            PlayerPrefs.SetString("subApp_" .. childAppId, "HIDE")
            --显示第二页模型列表的提示操作
            Tip:SetActive(true)
        end
    end
end

--string to boolean
function string:toboolean()
    if self == "true" then
        return true
    else
        return false
    end
end

--lua trim()函数
function string:trim ()
    return (self:gsub("^%s*(.-)%s*$", "%1"))
end

--标注点WebView回调监听
function ClosePointWebView(message)
    --关闭标注点WebView
    CS.UnityEngine.Object.Destroy(CallbackFromUniWebView._webView)

    --判断是否需要播放音频
    if (AudioSource.clip ~= nil) then
        --继续播放音频动画
        AudioSource:Play()
    end
end

--[[
	*初始化，遍历模型，并给每一个MeshRenderer的material添加切面shader
	*点击切面功能以后再复制相应模型
	]]
--
function PROCESS.InitDataTable()

    --菜单列表
    MENU.functionsList = {
        ['BOOM'] = false,
        ['PART'] = false,
        ['CROSS'] = false,
        ['POINT'] = false,
        ['VIEW_TRANSFER'] = _Global:GetData("haveViewTransfer"),
        ['SELF_ANIMATION'] = false,
        ['CURRENT_FUNCTION'] = {}
    }

    --初始化
    defaultViewTransform = {
        localPosition = Vector3.zero,
        localRotation = Quaternion.Euler(Vector3.zero),
        localScale = Vector3.one
    }

    --模型中所有可见的GameObject
    animationGameObject = {}
    --模型中所有可见GameObject的Id
    animationGameObjectId = {}

    --所有标注点信息table
    table_point = {}
    --
    table_prefab_point_normal = {}
    --
    table_prefab_point_step = {}
    --所有标注点Prefab
    table_prefab_point = {}
end

--
function CallBack_SelfOwnedAnimationStep()
    if ButtonAnimationPause.gameObject.activeSelf then
        PreviewManager:PreviewSceneStepData(SelfOwnedAnimationStep, CallBack_SelfOwnedAnimationStep)
    end
end

--标识播放步骤
local play_step = -1

--添加监听
function COMMON.RegisterListener()

    --切换背景
    SwitchButton.onClick:AddListener(function()
        local image = SwitchButton.gameObject:GetComponent("Image")
        local state = CameraBG.activeSelf
        --与实景状态互斥
        CameraBG:SetActive(not state)
        --实景状态
        if state then
            --打开相机
            CS.Vuforia.VuforiaBehaviour.Instance.enabled = true
        else
            --关闭相机
            CS.Vuforia.VuforiaBehaviour.Instance.enabled = false
        end

        --开关动画
        if state then
            --改变开关背景色
            image.color = { r = 60 / 255, g = 120 / 255, b = 40 / 255, a = 1 }
            SwitchButtonText.gameObject.transform:SetSiblingIndex(0)
        else
            --改变开关背景色
            image.color = { r = 1, g = 1, b = 1, a = 90 / 255 }
            SwitchButtonText.gameObject.transform:SetSiblingIndex(1)
        end

        --
        SwitchButtonText.text = state and "实景" or "虚景"
        SwitchButtonText.alignment = state and CS.UnityEngine.TextAnchor.MiddleRight or CS.UnityEngine.TextAnchor.MiddleLeft
    end)

    --多模型列表按钮
    ButtonMulModelList.onClick:AddListener(function()
        GameObject.Find("Root/UI/Main UI Canvas").transform:Find("MulModelList/Shadow").gameObject:SetActive(true)
        --显示多模型列表
        GameObject.Find("Root/UI/Main UI Canvas").transform:Find("MulModelList/ListView").gameObject:SetActive(true)
    end)

    --
    ButtonShowModel.onClick:AddListener(function()
        CallbackFromWebToUnity_MulModelPage._webView:Show(false, CS.UniWebViewTransitionEdge.Top)
        --
        UniWebViewPanelButton.gameObject:SetActive(true)
    end)

    --爆炸按钮点击
    ButtonBoom.onClick:AddListener(function()
        PROCESS.ToolMenuButtonClick(ButtonBoom, "BOOM")
    end)

    --切面按钮点击
    ButtonCross.onClick:AddListener(function()
        PROCESS.ToolMenuButtonClick(ButtonCross, "CROSS")
    end)

    --拆解按钮点击
    ButtonPart.onClick:AddListener(function()
        PROCESS.ToolMenuButtonClick(ButtonPart, "PART")
    end)

    --标注点按钮点击
    ButtonPoint.onClick:AddListener(function()
        PROCESS.ToolMenuButtonClick(ButtonPoint, "POINT")
    end)

    --复位按钮
    ButtonReset.onClick:AddListener(function()
        --
        PROCESS.ToolMenuButtonClick(ButtonReset, "RESET")
        --[[        ButtonResetImage.color = (ButtonResetImage.color.r == 1 and COMMON.selectedColor) or pointUnselectedColor
                ButtonResetText.color = (ButtonResetText.color.r == 1 and COMMON.selectedColor) or pointUnselectedColor
                ButtonReset0.gameObject:SetActive(not ButtonReset0.gameObject.activeSelf)
                --
                if sectionArguments["canControl"] then
                    if ButtonReset0.gameObject.activeSelf then
                        MenuUI:SetActive(false)
                    else
                        MenuUI:SetActive(true)
                    end
                end]]
    end)

    --复位按钮点击
    ButtonReset0.onClick:AddListener(function()
        --
        PROCESS.ToolMenuButtonClick(ButtonReset, "RESET")

        --场景视口复位
        PROCESS.ResetCameraView()
    end)

    --动画播放按钮
    ButtonAnimationPlay.onClick:AddListener(function()
        --
        ButtonAnimationPlay.gameObject:SetActive(not ButtonAnimationPlay.gameObject.activeSelf)
        ButtonAnimationPause.gameObject:SetActive(not ButtonAnimationPause.gameObject.activeSelf)
        --
        PreviewManager:PreviewSceneStepData(SelfOwnedAnimationStep, CallBack_SelfOwnedAnimationStep)
    end)

    --动画暂停按钮
    ButtonAnimationPause.onClick:AddListener(function()
        --
        ButtonAnimationPlay.gameObject:SetActive(not ButtonAnimationPlay.gameObject.activeSelf)
        ButtonAnimationPause.gameObject:SetActive(not ButtonAnimationPause.gameObject.activeSelf)
        --speed = 0 表示暂停动画播放
        animation:Stop()
        --暂停所有DOTween
        CS.DG.Tweening.DOTween.PauseAll()
    end)

    --[DDenry]********************************************************************************

    --切面按钮监听
    Section1On.onClick:AddListener(function()
        CROSS.ControlMenu(Section1On, Section1Off)
    end)
    Section1Off.onClick:AddListener(function()
        CROSS.ControlMenu(Section1Off, Section1On, 1)
    end)

    Section2On.onClick:AddListener(function()
        CROSS.ControlMenu(Section2On, Section2Off)
    end)
    Section2Off.onClick:AddListener(function()
        CROSS.ControlMenu(Section2Off, Section2On, 2)
    end)

    Section3On.onClick:AddListener(function()
        CROSS.ControlMenu(Section3On, Section3Off)
    end)
    Section3Off.onClick:AddListener(function()
        CROSS.ControlMenu(Section3Off, Section3On, 3)
    end)

    --菜单按钮监听
    --Pos
    PosYButton.onClick:AddListener(function()
        CROSS.ClickMenuButton(PosYButtonText, PosPanelImage, "Transform", QuadArr[currentSection][1].z)
    end)

    --Rot
    RotXButton.onClick:AddListener(function()
        CROSS.ClickMenuButton(RotXButtonText, RotPanelImage, "RotX", QuadArr[currentSection][2].x)
    end)
    RotZButton.onClick:AddListener(function()
        CROSS.ClickMenuButton(RotZButtonText, RotPanelImage, "RotZ", QuadArr[currentSection][2].y)
    end)

    --设置Toggle监听
    Toggle.onValueChanged:AddListener(function(value)
        SetSectionVisibility(value)
    end)

    --
    Slider.onValueChanged:AddListener(function(value)
        SliderValueChanged(value)
    end)

    --爆炸/还原按钮监听
    ButtonExplosive.onClick:AddListener(function()
        --
        ButtonExplosiveText.color = textHalfTransparentColor
        ButtonRestoredText.color = textNoTransparentColor

        --播放粒子效果
        if Explosion ~= nil then
            Explosion:SetActive(true)
        end

        --播放爆炸动画
        PreviewManager:PreviewSceneStepData(BoomStep)

        --爆炸时手机震动
        SSMessageManager:ReceiveMessage("Vibrate")
    end)

    --还原按钮
    ButtonRestored.onClick:AddListener(function()
        --
        ButtonExplosiveText.color = textNoTransparentColor
        ButtonRestoredText.color = textHalfTransparentColor

        --恢复模型至初始状态
        PROCESS.RestoredModel()

        --播放粒子效果
        if Explosion ~= nil then
            Explosion:SetActive(false)
        end
    end)

    --拆装下一步按钮监听
    ButtonNext.onClick:AddListener(function()
        PROCESS.NextStep()
    end)

    --拆装重放按钮监听
    ButtonReplay.onClick:AddListener(function()
        PreviewManager:PreviewSceneStepData(play_step)
    end)

    --拆装上一步按钮监听
    ButtonBack.onClick:AddListener(function()
        PROCESS.PreStep()
    end)

end

--拆装上一步
function PROCESS.PreStep()
    --
    currentIndex = currentIndex - 1

    --需要播放的真实步骤数
    play_step = play_step - 1

    --如果当前为非拆装步骤
    while (MENU.functionsList['BOOM'] and (play_step == BoomStep)) or (MENU.functionsList['SELF_ANIMATION'] and (play_step == SelfOwnedAnimationStep)) do
        play_step = play_step - 1
    end

    if currentIndex < step then
        ButtonNext.interactable = true
        ButtonNextText.color = textNoTransparentColor
    end

    if currentIndex == 0 then
        ButtonBack.interactable = false
        ButtonBackText.color = textHalfTransparentColor
        --
        ButtonReplay.interactable = false
        ButtonReplayText.color = textHalfTransparentColor

        --恢复模型至初始状态
        PROCESS.RestoredModel()
    else
        --停止场景中所有的Tween
        CS.DG.Tweening.DOTween.PauseAll()
        CS.DG.Tweening.DOTween.KillAll()

        --标识当前真实播放步骤
        --currentPlayIndex = play_step - 1

        --播放动画
        PreviewManager:PreviewSceneStepData(play_step)

        --判断是否有StepPoint
        for i = 1, #table_prefab_point_step do
            --步骤标注点与所绑定模型统一SetActive
            table_prefab_point_step[i]:SetActive(table_prefab_point_step[i]:GetComponent(typeof(CS.EzComponents.UnityUI.TransformPointTracker)).TargetTransform.gameObject.activeSelf)
        end

    end

    step_text.text = currentIndex .. "/" .. step
end

--拆装下一步
function PROCESS.NextStep()
    --需要播放的真实步骤数
    play_step = play_step + 1

    --点击以后自增
    currentIndex = currentIndex + 1

    --如果当前为非拆装步骤
    while (MENU.functionsList['BOOM'] and (play_step == BoomStep)) or (MENU.functionsList['SELF_ANIMATION'] and (play_step == SelfOwnedAnimationStep)) do
        play_step = play_step + 1
    end

    if currentIndex > 0 then
        --ButtonBack.gameObject:SetActive(true)
        ButtonBack.interactable = true
        ButtonBackText.color = textNoTransparentColor
        --
        ButtonReplay.interactable = true
        ButtonReplayText.color = textNoTransparentColor
    end

    if (currentIndex > (step - 1)) then
        --ButtonNext.gameObject:SetActive(false)
        ButtonNext.interactable = false
        ButtonNextText.color = textHalfTransparentColor
    end

    --停止场景中所有的Tween
    CS.DG.Tweening.DOTween.PauseAll()
    CS.DG.Tweening.DOTween.KillAll()

    --
    PreviewManager:PreviewSceneStepData(play_step)

    --判断是否有StepPoint
    for i = 1, #table_prefab_point_step do
        --步骤标注点与所绑定模型统一SetActive
        table_prefab_point_step[i]:SetActive(table_prefab_point_step[i]:GetComponent(typeof(CS.EzComponents.UnityUI.TransformPointTracker)).TargetTransform.gameObject.activeSelf)
    end

    --设置底部拆装文本内容
    step_text.text = currentIndex .. "/" .. step
end

--设置拆装过程中的按钮状态
function PROCESS.SetPartStepButtonState(PartStepButtonState, state)
    --
    if not state then
        ButtonBack.interactable = state
        ButtonBackText.color = textHalfTransparentColor
        ButtonReplay.interactable = state
        ButtonReplayText.color = textHalfTransparentColor
        ButtonNext.interactable = state
        ButtonNextText.color = textHalfTransparentColor
    else
        ButtonBack.interactable = PartStepButtonState[1]
        ButtonBackText.color = (PartStepButtonState[1] and textNoTransparentColor) or textHalfTransparentColor
        ButtonReplay.interactable = PartStepButtonState[2]
        ButtonReplayText.color = (PartStepButtonState[2] and textNoTransparentColor) or textHalfTransparentColor
        ButtonNext.interactable = PartStepButtonState[3]
        ButtonNextText.color = (PartStepButtonState[3] and textNoTransparentColor) or textHalfTransparentColor
    end

end

--
local EnumFunctionWeight = {
    ['NONE'] = 0,
    ['BOOM'] = 1,
    ['PART'] = 2,
    ['CROSS'] = 4,
    ['POINT'] = 8,
    ['VIEW_TRANSFER'] = 16,
    ['SELF_ANIMATION'] = 32
}

--实现Unity[Flags]标签功能
function FlagEnum(weight)
    local value = ""

    repeat
        for i, _weight in pairs(EnumFunctionWeight) do
            if weight >= _weight and weight < _weight * 2 then
                weight = weight - _weight
                value = value .. i .. "|"
            end
        end
    until weight == 0

    --
    print("===========", value)
end

--功能按钮组
MENU.ToolButtonGroup = {
    ['MU-BUTTONS'] = {
        ['BOOM'] = ButtonBoom,
        ['PART'] = ButtonPart,
        ['CROSS'] = ButtonCross
    },
    ['BOOM'] = ButtonBoom,
    ['PART'] = ButtonPart,
    ['CROSS'] = ButtonCross,
    ['POINT'] = ButtonPoint,
    ['RESET'] = ButtonReset
}

--重置功能按钮
function PROCESS.HandleMenuButton(type, button, mode)
    --
    if type == "ResetOthers" then
        --重置互斥按钮
        for i, _button in pairs(MENU.ToolButtonGroup['MU-BUTTONS']) do
            if _button ~= button then
                --反选互斥按钮
                PROCESS.HandleMenuButton("DeselectSelf", _button, i)
            end
        end

    elseif type == "SelectSelf" then
        button.transform:Find("Icon").gameObject:GetComponent("Image").color = COMMON.selectedColor
        button.transform:Find("Text").gameObject:GetComponent("Text").color = COMMON.selectedColor

        --标识当前操作至CURRENT_FUNCTION
        table.insert(MENU.functionsList['CURRENT_FUNCTION'], mode)

        --进行相应的功能操作
        PROCESS.CallToolFunction(mode)

    elseif type == "DeselectSelf" then
        button.transform:Find("Icon").gameObject:GetComponent("Image").color = COMMON.normalColor
        button.transform:Find("Text").gameObject:GetComponent("Text").color = COMMON.normalColor

        --删除当前操作记录
        for i, v in pairs(MENU.functionsList['CURRENT_FUNCTION']) do
            if v == mode then
                table.remove(MENU.functionsList['CURRENT_FUNCTION'], i)
                break
            end
        end

        --反选后的操作
        --[[
            /*
            *
            */
        ]]

        if mode == "RESET" then
            ButtonReset0.gameObject:SetActive(false)
        elseif mode == "POINT" then
            PROCESS.ShowPoint(false)
        elseif mode == "BOOM" then
            PROCESS.ResetBoomFunction()
        elseif mode == "PART" then
            PROCESS.ResetPartFunction()

        elseif mode == "CROSS" then
            --隐藏所有切面及模型替代
            CROSS.ResetCrossFunction()

            --判断是否有标注点，有则开放点击
            if MENU.functionsList['POINT'] then
                ButtonPoint.interactable = true
            end
        end

        --判断当前是否需要显示默认功能(自带动画)
        if MENU.functionsList['SELF_ANIMATION'] then
            --
            if table.concat(MENU.functionsList['CURRENT_FUNCTION'], "") == "SELF_ANIMATION" then
                StudioData.ShowAnimatorFunction(true)
            end
        end
    end

    print("FunctionsList:" .. table.concat(MENU.functionsList['CURRENT_FUNCTION'], "|"))
end

--功能菜单按钮点击
function PROCESS.ToolMenuButtonClick(button, mode)
    --判断当前功能选择
    --如果不是标注点功能
    if mode ~= "POINT" and mode ~= "RESET" then
        --功能按钮
        PROCESS.HandleMenuButton("ResetOthers", button, mode)

        --切面模式
        if mode == "CROSS" then
            --未选中切面模式
            if ButtonCrossImage.color.r == 1 then
                --如果有标注点则标注点按钮可点击
                if MENU.functionsList['POINT'] then
                    ButtonPoint.interactable = true
                end
            else
                --判断是否显示操作切面面板
                MenuUI:SetActive(sectionArguments["canControl"] and not ButtonReset0.gameObject.activeSelf)

                --如果有则关闭标注点
                if MENU.functionsList['POINT'] then
                    PROCESS.ShowPoint(false)
                    --
                    PROCESS.HandleMenuButton("DeselectSelf", ButtonPoint, "POINT")
                    --标注点按钮不可点击
                    ButtonPoint.interactable = false
                end
            end
        end
    end

    --判断当前操作是select或者deselect
    if table.concat(MENU.functionsList['CURRENT_FUNCTION'], "|"):find(mode) ~= nil then
        PROCESS.HandleMenuButton("DeselectSelf", button, mode)
    else
        PROCESS.HandleMenuButton("SelectSelf", button, mode)
    end
end

--[[DDenry]]
--标注点按钮,type=false关闭，type=true显示
function PROCESS.ShowPoint(type)
    --操作标注点
    for i = 1, #table_prefab_point_normal do
        table_prefab_point_normal[i].gameObject:SetActive(type)
    end
end

--模型还原
function PROCESS.RestoredModel()
    --停止场景中所有的Tween
    CS.DG.Tweening.DOTween.PauseAll()
    CS.DG.Tweening.DOTween.KillAll()

    --设置场景状态为工具第一步状态
    CS.SceneStudio.TimelinesManager.Instance.Timelines[0].Recorder:Apply()

    --如果存在步骤标注点
    if #table_prefab_point_step > 0 then
        for i = 1, #table_prefab_point_step do
            --隐藏所有步骤标注点
            table_prefab_point_step[i]:SetActive(false)
        end
    end
end

--相机视角复位
function PROCESS.ResetCameraView()
    --相机距离复位
    CameraModel.transform.localScale = Vector3.one

    --模型transform
    Contents.transform.localPosition = defaultViewTransform['localPosition']
    Contents.transform.localRotation = defaultViewTransform['localRotation']
    Contents.transform.localScale = defaultViewTransform['localScale']
end

--功能重置
function PROCESS.ResetBoomFunction()
    --模型复原
    PROCESS.RestoredModel()

    --UI重置
    BoomUI:SetActive(false)
    --
    ButtonExplosive.interactable = true
    ButtonExplosiveText.color = textNoTransparentColor

    ButtonRestored.interactable = false
    ButtonRestoredText.color = textHalfTransparentColor

    --粒子效果
    if Explosion ~= nil then
        Explosion:SetActive(false)
    end
end

--
function PROCESS.ResetPointFunction()
    if MENU.functionsList['POINT'] then
        PROCESS.ShowPoint(false)
    end
end
--
function PROCESS.ResetSelfAnimation()
    --
    if MENU.functionsList['SELF_ANIMATION'] then
        StudioData.ShowAnimatorFunction(false)
    end
end

--功能菜单重置
function PROCESS.ResetMenu()
    --重置所有菜单按钮
    for i, button in pairs(MENU.ToolButtonGroup) do
        if type(button) ~= "table" then
            button.gameObject.transform:Find("Icon"):GetComponent("Image").color = COMMON.normalColor
            button.gameObject.transform:Find("Text"):GetComponent("Text").color = COMMON.normalColor
        end
    end

    ButtonReset0.gameObject:SetActive(false)

    --隐藏菜单UI
    toolMenu:SetActive(false)
end

--
function PROCESS.ResetPartFunction()
    --
    PROCESS.RestoredModel()
    --
    PartUI:SetActive(false)
    --
    PROCESS.SetPartStepButtonState(nil, false)
    --默认下一步按钮可以点击
    ButtonNext.interactable = true
    ButtonNextText.color = textNoTransparentColor

    --步骤指示显示置空
    step_text.text = ""

    --当前步骤置零
    currentIndex = 0
    --
    play_step = -1

    if AudioSource ~= nil then
        --停止场景中的音频
        AudioSource.clip = ""
        AudioSource:Stop()
    end
end

--重置场景至初始状态
function PROCESS.ResetSceneState()
    --重置相机视角
    PROCESS.ResetCameraView()
    --重置功能
    PROCESS.ResetSceneFunction()
    --
    PROCESS.ResetMenu()
end

--重置场景功能
function PROCESS.ResetSceneFunction()
    print("Reset all functions of the scene!")
    --
    PROCESS.ResetBoomFunction()

    --
    PROCESS.ResetPartFunction()

    --调用重置切面功能
    CROSS.ResetCrossFunction()

    --TODO:重置自带动画
    PROCESS.ResetSelfAnimation()
    --TODO:重置标注点
    PROCESS.ResetPointFunction()
end

--Dispose
function PROCESS.DisposeBoomFunction()

end

function PROCESS.DisposePartFunction()
end
--
function PROCESS.DisposeCrossFunction()
    --如果实例的对象存在，则销毁
    if (SectionXY ~= nil) then
        SectionXY:Destructor()

        SectionXY = nil
        Quad1 = nil
    end

    if SectionXZ ~= nil then
        SectionXZ:Destructor()

        SectionXZ = nil
        Quad2 = nil
    end

    if SectionYZ ~= nil then
        SectionYZ:Destructor()

        SectionYZ = nil
        Quad3 = nil
    end
end

function PROCESS.DisposePointFunction()
    --销毁所有标注点
    if MENU.functionsList['POINT'] then
        for i = 0, #table_prefab_point do
            Destroy(table_prefab_point[i].gameObject)
        end
    end
end

function PROCESS.DisposeSelfAnimationFunction()
    --将animation置空
    if animation ~= nil then
        animation = nil
    end
end

function PROCESS.DisposeSceneTool()
    --
    PROCESS.DisposeCrossFunction()
    --
    PROCESS.DisposePointFunction()
    --
    PROCESS.DisposeSelfAnimationFunction()
end

function PROCESS.DisposeSceneState()
    --
    PROCESS.DisposeSceneTool()
    --
    _Global:SetData("haveMulModel", "")

    --重置模型scale
    GameObject.Find("Root/Models").transform.localScale = Vector3.one

    Contents.transform.localRotation = Quaternion.Euler(Vector3.zero)

    --
    SwitchButton.gameObject:SetActive(false)

    --关闭手势操作
    FingerOperator_Model.enabled = false

    --
    defaultViewTransform = {}
    --
    COMMON.ReleaseDictionary()
end

--
function COMMON.ReleaseDictionary()
    --释放dictionary
    for i = 0, #animationGameObjectId do
        _Global:ReleseData(animationGameObjectId[i])
        _Global:ReleseData("position_" .. animationGameObjectId[i])
        _Global:ReleseData("rotation_" .. animationGameObjectId[i])
        _Global:ReleseData("scale_" .. animationGameObjectId[i])
    end
end

--调用相应功能
function PROCESS.CallToolFunction(mode)
    --协同功能
    if mode == "RESET" then
        ButtonReset0.gameObject:SetActive(not ButtonReset0.gameObject.activeSelf)
        return
    end

    --TODO:标注点的操作
    if mode == "POINT" then
        --TODO:暂时先这么做
        PROCESS.ShowPoint(true)
        return
    end

    --存在自带动画功能
    if MENU.functionsList['SELF_ANIMATION'] then
        --隐藏播放按钮
        StudioData.ShowAnimatorFunction(false)
    end

    --互斥功能，模型状态复位
    PROCESS.RestoredModel()

    --爆炸功能
    if mode == "BOOM" then
        --如果模型含有爆炸动画
        BoomUI:SetActive(true)

        --切面功能
    elseif mode == "CROSS" then
        --如果有标注点则设置为不可点击
        if MENU.functionsList['POINT'] then
            ButtonPoint.interactable = false
        end

        --显示剖切UI
        CrossOperator:SetActive(true)

        --拆解功能
    elseif mode == "PART" then
        --
        step_text.text = currentIndex .. "/" .. step
        --显示拆装界面
        PartUI:SetActive(true)
    end
end

--切面按钮点击事件
--[[
    *selfButton 所点击按钮
    *otherButton 与所操作按钮互斥的按钮
    *type 标识是否显示操作UI

]]
function CROSS.ControlMenu(selfButton, otherButton, type)
    --显示OperatePanel
    if (type ~= nil) then
        --重置非操作切面按钮
        ResetSectionButton(type)

        --TODO:根据所选type设置面板位置(功能已实现，但被需求否决[微笑])
        --FunctionChoose:GetComponent("RectTransform").anchorMin = Vector2((type - 1) / 3, FunctionChoose:GetComponent("RectTransform").anchorMin.y)
        --FunctionChoose:GetComponent("RectTransform").anchorMax = Vector2(type / 3, FunctionChoose:GetComponent("RectTransform").anchorMax.y)

        --显示OperatePanel
        FunctionChoose:SetActive(true)
        --OperatePanel:SetActive(true)

        --调用SetCurrentSection重置变量值
        SetCurrentSection(type)
    else
        --隐藏操作面板
        FunctionChoose:SetActive(false)
        --TODO:目前模式为单切面模式
        SectionXY.section:SetActive(false)
        SectionXY.crossedGameObject:SetActive(false)
        SectionXZ.section:SetActive(false)
        SectionXZ.crossedGameObject:SetActive(false)
        SectionYZ.section:SetActive(false)
        SectionYZ.crossedGameObject:SetActive(false)
        OriObject:SetActive(true)
    end

    --操作按钮置反
    selfButton.gameObject:SetActive(not selfButton.gameObject.activeSelf)
    otherButton.gameObject:SetActive(not otherButton.gameObject.activeSelf)

    --重置所有菜单按钮选择
    ResetMenuButton()
end

--
--菜单按钮点击
function CROSS.ClickMenuButton(text, image, signal, value)
    --设置当前操作标识
    currentSignal = signal

    --
    tmp_value = value

    CROSS.CopyRotation2Parent()

    --重置所有菜单按钮
    ResetMenuButton()

    --设置点击按钮Text为selectedColor Hex:4285F4FF 66 133 244
    text.color = COMMON.selectedColor
    --所选归属栏显示被选中为pre_color
    image.color = COMMON.selectedColor

    --显示SliderPanel
    NotifySliderPanel(true, text.text, signal, value)
end


--[DDenry]设置切面Pos及Rot
function GetQuadsInfo()
    if sectionArguments["sectionNum"] > 0 then
        --切面Quad1
        QuadArr[1][1] = Quad1.transform.localPosition
        QuadArr[1][2] = Quad1.transform.localEulerAngles
    end
    if sectionArguments["sectionNum"] > 1 then
        --切面Quad2
        QuadArr[2][1] = Quad2.transform.localPosition
        QuadArr[2][2] = Quad2.transform.localEulerAngles
    end
    if sectionArguments["sectionNum"] > 2 then
        --切面Quad3
        QuadArr[3][1] = Quad3.transform.localPosition
        QuadArr[3][2] = Quad3.transform.localEulerAngles
    end
end

--[DDenry]
--设置当前切面并重置Pos以及Rot
function SetCurrentSection(section)
    --
    currentSection = section

    --TODO;
    assert(coroutine.resume(Coroutine_Cross))

    --获取切面的属性
    GetQuadsInfo()

    --设置切面Toggle值
    GetSectionVisibility()
end

--判断目前数值应该截几位
function SubToWhere(value)
    local where = 0
    --
    if (value >= 0.0 and value < 10.0) then
        where = 2
    elseif (value >= 10.0 and value < 100.0) then
        where = 3
    elseif value >= 100.0 then
        where = 4
    elseif (value < 0.0 and value > -10.0) then
        where = 3
    elseif (value <= -10.0 and value > -100.0) then
        where = 4
    elseif value >= -180.0 then
        where = 5
    end
    return where
end

--[DDenry]获取当前切面显示状态并设置Toggle
function GetSectionVisibility()
    --
    if currentSection == 1 then
        ToggleText.text = "1"
        Toggle.isOn = not Quad1.activeSelf
    elseif currentSection == 2 then
        ToggleText.text = "2"
        Toggle.isOn = not Quad2.activeSelf
    elseif currentSection == 3 then
        ToggleText.text = "3"
        Toggle.isOn = not Quad3.activeSelf
    end
end

--[DDenry]更新当前切面属性
function UpdateCurrentSection(value)
    --
    if currentSignal == "Transform" then
        QuadArr[currentSection][1].z = value
        PosY = value
    end

    if currentSignal == "RotX" then
        QuadArr[currentSection][2].x = value
        RotX = value
    elseif currentSignal == "RotY" then
        QuadArr[currentSection][2].z = value
        RotY = value
    elseif currentSignal == "RotZ" then
        QuadArr[currentSection][2].y = value
        RotZ = value
    end

    --通知切面移动或旋转
    NotifyQuadTransform()
end

--将当前切面状态的旋转角度复制到parent
function CROSS.CopyRotation2Parent()
    --
    if currentSection == 1 then

        if currentSignal == "Transform" then
            local _x = Quad1.transform.localEulerAngles.x
            local _y = Quad1.transform.localEulerAngles.y
            --
            --SectionXY.section.transform.localRotation = Quaternion.Euler(SectionXY.section.transform.localEulerAngles.x, SectionXY.section.transform.localEulerAngles.y + _y, 0)
            SectionXY.section.transform:Rotate(Vector3(_x, _y, 0))
            Quad1.transform.localEulerAngles = Vector3.zero
        elseif currentSignal == "RotX" then
            if Quad1.transform.localEulerAngles.x == 0 then
                local _y = Quad1.transform.localEulerAngles.y
                --
                --SectionXY.section.transform.localRotation = Quaternion.Euler(SectionXY.section.transform.localEulerAngles.x, SectionXY.section.transform.localEulerAngles.y + _y, 0)
                SectionXY.section.transform:Rotate(Vector3(0, _y, 0))
                Quad1.transform.localEulerAngles = Vector3.zero
            end
        elseif currentSignal == "RotZ" then
            if Quad1.transform.localEulerAngles.y == 0 then
                local _x = Quad1.transform.localEulerAngles.x
                --
                SectionXY.section.transform:Rotate(Vector3(_x, 0, 0))
                Quad1.transform.localEulerAngles = Vector3.zero
            end
        end
    elseif currentSection == 2 then
        if currentSignal == "Transform" then
            local _x = Quad2.transform.localEulerAngles.x
            local _y = Quad2.transform.localEulerAngles.y
            --
            SectionXZ.section.transform:Rotate(Vector3(_x, _y, 0))
            Quad2.transform.localEulerAngles = Vector3.zero
        elseif currentSignal == "RotX" then
            if Quad2.transform.localEulerAngles.x == 0 then
                local _y = Quad2.transform.localEulerAngles.y
                --
                SectionYZ.section.transform:Rotate(Vector3(0, _y, 0))
                Quad2.transform.localEulerAngles = Vector3.zero
            end
        elseif currentSignal == "RotZ" then
            if Quad2.transform.localEulerAngles.y == 0 then
                local _x = Quad2.transform.localEulerAngles.x
                --
                SectionYZ.section.transform:Rotate(Vector3(_x, 0, 0))
                Quad2.transform.localEulerAngles = Vector3.zero
            end
        end
    elseif currentSection == 3 then
        if currentSignal == "Transform" then
            local _x = Quad3.transform.localEulerAngles.x
            local _y = Quad3.transform.localEulerAngles.y
            --
            SectionYZ.section.transform:Rotate(Vector3(_x, _y, 0))
            Quad3.transform.localEulerAngles = Vector3.zero
        elseif currentSignal == "RotX" then
            if Quad3.transform.localEulerAngles.x == 0 then
                local _y = Quad3.transform.localEulerAngles.y
                --
                SectionXY.section.transform:Rotate(Vector3(0, _y, 0))
                Quad3.transform.localEulerAngles = Vector3.zero
            end
        elseif currentSignal == "RotZ" then
            if Quad3.transform.localEulerAngles.y == 0 then
                local _x = Quad3.transform.localEulerAngles.x
                --
                SectionYZ.section.transform:Rotate(Vector3(_x, 0, 0))
                Quad3.transform.localEulerAngles = Vector3.zero
            end
        end
    end
end

--[DDenry]通知所操作切面进行位移或者旋转
function NotifyQuadTransform()
    --
    if currentSection == 1 then
        if currentSignal == "Transform" then
            Quad1.transform:Translate(Vector3.forward * tonumber(sliderPosValue) * 0.05, CS.UnityEngine.Space.Self)
        elseif currentSignal == "RotX" then
            --Quad1.transform.localRotation = Quaternion.Euler(Slider.value, 0, 0)
            Quad1.transform:Rotate(tonumber(sliderPosValue), 0, 0)
        elseif currentSignal == "RotZ" then
            --Quad1.transform.localRotation = Quaternion.Euler(0, Slider.value, 0)
            Quad1.transform:Rotate(0, tonumber(sliderPosValue), 0)
        end

    elseif currentSection == 2 then

        --
        if currentSignal == "Transform" then
            Quad2.transform:Translate(Vector3.forward * tonumber(-sliderPosValue) * 0.05, CS.UnityEngine.Space.Self)
        end
        --
        if currentSignal == "RotX" then
            Quad2.transform.localRotation = Quaternion.Euler(QuadArr[2][2])
        elseif currentSignal == "RotY" then
            Quad2.transform.localRotation = Quaternion.Euler(QuadArr[2][2])
        elseif currentSignal == "RotZ" then
            Quad2.transform.localRotation = Quaternion.Euler(QuadArr[2][2])
        end

    elseif currentSection == 3 then

        if currentSignal == "Transform" then
            Quad3.transform:Translate(Vector3.forward * tonumber(sliderPosValue) * 0.05, CS.UnityEngine.Space.Self)
        end
        --
        if currentSignal == "RotX" then
            Quad3.transform.localRotation = Quaternion.Euler(QuadArr[3][2])
        elseif currentSignal == "RotY" then
            Quad3.transform.localRotation = Quaternion.Euler(QuadArr[3][2])
        elseif currentSignal == "RotZ" then
            Quad3.transform.localRotation = Quaternion.Euler(QuadArr[3][2])
        end
    end

    --更新显示面板内容
    --UpdateShowPanel()
end

--[DDenry]更新显示面板内容
function UpdateShowPanel()
    --获取切面的属性
    GetQuadsInfo()
end

--[DDenry]重置切面按钮,*type 表示当前操作的按钮
function ResetSectionButton(type)
    --切面1
    if type == 1 then
        Section2On.gameObject:SetActive(false)
        Section2Off.gameObject:SetActive(true)
        Section3On.gameObject:SetActive(false)
        Section3Off.gameObject:SetActive(true)
        --切面2
    elseif type == 2 then
        Section1On.gameObject:SetActive(false)
        Section1Off.gameObject:SetActive(true)
        Section3On.gameObject:SetActive(false)
        Section3Off.gameObject:SetActive(true)
        --切面3
    elseif type == 3 then
        Section1On.gameObject:SetActive(false)
        Section1Off.gameObject:SetActive(true)
        Section2On.gameObject:SetActive(false)
        Section2Off.gameObject:SetActive(true)
    end
end

--[DDenry]重置所有菜单按钮选择
function ResetMenuButton()

    --隐藏SliderPanel
    NotifySliderPanel(false)

    --遍历菜单中互斥的buttonText并置为normal
    for i, v in pairs(menuDeselectButton) do
        v.gameObject.transform:Find("Text"):GetComponent("Text").color = COMMON.normalColor
    end
end

--[DDenry]
--通知SliderPanel
--[[
    *state Slider要置为的状态
    *text 所点菜单按钮的内容
    *signal 标识按钮类型以及方向
    *value Pos或者Rot的值
]]
function NotifySliderPanel(state, text, signal, value)

    --判断是否显示Slider
    if state then
        --设置标注标量
        local flag = false

        --显示SliderPanel
        SliderPanel:SetActive(true)

        --移除监听
        Slider.onValueChanged:RemoveAllListeners()

        --判断类型type并设置Slider min/max value
        --if signal == "PosX" or signal == "PosY" or signal == "PosZ" then
        if signal == "Transform" then
            --记录当前菜单按钮类型 true为Pos
            flag = true
            --
            Slider.minValue = RangePos.minValue
            Slider.maxValue = RangePos.maxValue
            --
        else
            --
            flag = false
            Slider.minValue = RangeRot.minValue
            Slider.maxValue = RangeRot.maxValue
            --
        end

        value = tonumber(string.format("%.1f", value))

        --设置SliderValue
        Slider.value = value

        --添加监听
        Slider.onValueChanged:AddListener(function(value)
            SliderValueChanged(value)
        end)

        --如果是Pos操作，则置吸附状态为false
        if flag then
            operateType = false
        end

        --设置显示值
        TextValue.text = tostring(value)

        --隐藏Slider
    else
        SliderPanel:SetActive(false)
    end
end

--[DDenry]Slider监听
function SliderValueChanged(value)
    --
    sliderPosValue = value - tmp_value

    --设置Slider TextValue
    local str_value = string.format("%.1f", value)

    TextValue.text = str_value

    --更新当前切面属性
    UpdateCurrentSection(str_value)

    --调用Slider吸附方法
    CROSS.AdsorbRot(value)

    --
    tmp_value = value

end

--[DDenry]吸附预设角度
function CROSS.AdsorbRot(value)

    --判断当前滑杆儿操作
    --可吸附状态为true
    if operateType == true then
        --预设角度
        if value > -10 and value < 10 then
            Slider.value = 0.0
        elseif value > 80 and value < 100 then
            Slider.value = 90.0
        elseif value > 170 then
            Slider.value = 180.0
        elseif value > -100 and value < -80 then
            Slider.value = -90.0
        elseif value < -170 then
            Slider.value = -180.0
        end
    else
        --
        if currentSignal == "RotX" or currentSignal == "RotY" or currentSignal == "RotZ" then
            operateType = true
        end
    end

    if currentSection == 1 then
        if currentSignal == "RotX" then
            Quad1.transform.localRotation = Quaternion.Euler(Slider.value, 0, 0)
        elseif currentSignal == "RotZ" then
            Quad1.transform.localRotation = Quaternion.Euler(0, Slider.value, 0)
        end
    end

end

--[DDenry]
--设置切面是否显示
function SetSectionVisibility(value)
    --
    if currentSection == 1 then
        SectionXY.section:SetActive(not value)
        SectionXY.crossedGameObject:SetActive(not value)
    elseif currentSection == 2 then
        SectionXZ.section:SetActive(not value)
        SectionXZ.crossedGameObject:SetActive(not value)
    elseif currentSection == 3 then
        SectionYZ.section:SetActive(not value)
        SectionYZ.crossedGameObject:SetActive(not value)
    end

    --判断当前场景中切面显示状态
    JudgeState()
end

--[DDenry]判断当前场景中切面显示状态
function JudgeState()
    local state = nil
    if not (Quad1.activeSelf or Quad2.activeSelf or Quad3.activeSelf) then
        OriObject:SetActive(true)
        state = false
    else
        OriObject:SetActive(false)
        state = true
    end
end

--[DDenry]判断输入是否合法
function JudgeInput(value)
    --有值输入
    if value ~= nil then
        --当前是位移操作
        --if currentSignal == "PosX" or currentSignal == "PosY" or currentSignal == "PosZ" then
        if currentSignal == "Transform" then
            --如果输入不合法
            if value > RangePos.maxValue or value < RangePos.minValue then
                --
                InputField.text = 0.0
                Slider.value = 0.0
                --
            else
                Slider.value = value
            end
            --当前是旋转操作
        else
            --如果输入不合法
            if value > RangeRot.maxValue or value < RangeRot.minValue then
                --
                InputField.text = 0.0
                Slider.value = 0.0
                --
            else
                --标识为不要吸附
                operateType = false
                --修改Slider Value
                Slider.value = value

            end
        end
    end
end

--重置所有变量
function CROSS.ResetAllVariables()

    --标识当前操作切面
    currentSection = 0

    --标识当前操作类型[PosX,PosY,PosZ,RotX,RotY,RotZ]
    currentSignal = ""

    --标识Slider的操作类型(true表示吸附，false表示不吸附)
    operateType = true

    --
    tmp_value = 0.0
    sliderPosValue = 0.0

    --切面模式状态
    updateCrossState = false

    --设置切面Pos范围
    RangePos = {
        minValue = tonumber(_Global:GetData("minValue")),
        maxValue = tonumber(_Global:GetData("maxValue"))
    }

    --设置切面Rot范围
    RangeRot = {
        minValue = -180,
        maxValue = 180
    }

end

local Section = {
    name = "",
    position = {
        x = 0,
        y = 0,
        z = 0
    },
    rotation = {
        x = 0,
        y = 0,
        z = 0
    },
    crossedGameObject = nil,
    state = true,
    signal = false,
    section = nil
}

function Section:new(name, parent, oriObject, state, ...)
    local signal = false
    if select("#", ...) > 0 then
        signal = select(1, ...)
    end
    local o = {
        name = name,
        position = {
            x = 0,
            y = 0,
            z = 0
        },
        rotation = {
            x = 0,
            y = 0,
            z = 0
        },
        crossedGameObject = CS.UnityEngine.Object.Instantiate(oriObject, parent.transform),
        state = state
    }

    --
    o["crossedGameObject"].name = "GameObject" .. name

    --实例化切面
    o["section"] = Object.Instantiate(GameObject.Find("Root/TmpSave/Quad"))
    o["section"].name = name
    --
    o["section"].transform:SetParent(parent.transform)
    --
    if name == "XY" then
        o["section"].transform.localRotation = CS.UnityEngine.Quaternion.Euler(CS.UnityEngine.Vector3(0, 0, 0))
    elseif name == "XZ" then
        o["section"].transform.localRotation = CS.UnityEngine.Quaternion.Euler(CS.UnityEngine.Vector3(90, 0, 0))
    elseif name == "YZ" then
        o["section"].transform.localRotation = CS.UnityEngine.Quaternion.Euler(CS.UnityEngine.Vector3(0, 90, 0))
    end

    --o["section"].transform:Find("Quad").transform.localScale = Contents.transform.localScale * (-GameObject.Find("Root/Models/Camera/Camera").transform.localPosition.z)
    o["section"].transform:Find("Quad").transform.localScale = Vector3(220, 220, 220)
    o["section"]:SetActive(state)

    --设置元表保护机制
    self.__metatable = "Sorry, u cannot do this!"

    setmetatable(o, self)
    self.__index = self

    print("Section " .. name .. " instantiated!")

    return o
end

function Section:Destructor()
    if self.section ~= nil then
        Destroy(self.section)
        self.section = nil
    end

    if self.crossedGameObject ~= nil then
        Destroy(self.crossedGameObject)
        self.crossedGameObject = nil
    end

    self.name = nil
    self.position = nil
    self.rotation = nil
    self.section = nil
    self.crossedGameObject = nil
    self.state = nil
    self.signal = nil

    self.__index.name = nil
    self.__index.position = nil
    self.__index.section = nil
    self.__index.crossedGameObject = nil
    self.__index.state = nil
    self.__index.signal = nil

    self = nil
end

--为剖切功能生成替代品
local substitute

--
function CROSS.Prepare()
    print("Replacing Cross Shader")

    TextValue.color = COMMON.selectedColor
    --
    Section1On:GetComponent("Text").color = COMMON.selectedColor
    Section2On:GetComponent("Text").color = COMMON.selectedColor
    Section3On:GetComponent("Text").color = COMMON.selectedColor

    --生成substitute,并与OriObject保持相同transform
    if OriObject.transform.parent:Find("Substitute") == nil then
        substitute = GameObject("Substitute")
        substitute.transform:SetParent(OriObject.transform.parent)
    end

    --隐藏Substitute
    substitute:SetActive(false)

    --生成替代品以及切面XY
    SectionXY = Section:new("XY", substitute.transform, OriObject, true)
    Quad1 = SectionXY.section.transform:Find("Quad").gameObject

    --如果绑定了Animator，则去除
    if MENU.functionsList['SELF_ANIMATION'] then
        Destroy(SectionXY.crossedGameObject:GetComponentInChildren(typeof(CS.UnityEngine.Animator)))
        print("Removed animator on substitute")
    end

    --遍历模型MeshRenderer
    meshRenderer1 = SectionXY.crossedGameObject:GetComponentsInChildren(typeof(CS.UnityEngine.MeshRenderer))

    --给有MeshRenderer的GameObject绑定切面脚本
    local i = 0

    --meshRenderer.Length = 数组长度
    while (i < meshRenderer1.Length) do
        --遍历meshRender中的所有material
        for j = 0, meshRenderer1[i].materials.Length - 1 do
            meshRenderer1[i].materials[j].shader = OnePlaneBSP_pre:GetComponent(typeof(CS.UnityEngine.MeshRenderer)).material.shader
        end
        --变量i自增
        i = i + 1
    end

    --实例化替代模型以及切面
    if sectionArguments["sectionNum"] >= 2 then
        SectionXZ = Section:new("XZ", substitute.transform, SectionXY.crossedGameObject, true)
        Quad2 = SectionXZ.section.transform:Find("Quad").gameObject
        meshRenderer2 = SectionXZ.crossedGameObject:GetComponentsInChildren(typeof(CS.UnityEngine.MeshRenderer))
    end
    if sectionArguments["sectionNum"] == 3 then
        SectionYZ = Section:new("YZ", substitute.transform, SectionXY.crossedGameObject, true)
        Quad3 = SectionYZ.section.transform:Find("Quad").gameObject
        meshRenderer3 = SectionYZ.crossedGameObject:GetComponentsInChildren(typeof(CS.UnityEngine.MeshRenderer))
    end
    if sectionArguments["sectionNum"] > 3 or sectionArguments["sectionNum"] < 0 then
        print("error sectionNum!")
        OriObject:SetActive(true)
    end
end

local sectionMode = _Global:GetData("sectionMode")

--剖切模式
function CROSS.ShowSection(sectionMode)
    --单独显示
    if sectionMode == "Single" then
        --判断切面数量
        if sectionArguments["sectionNum"] == 3 then
            --
            if currentSection == 1 then
                SectionXY.section:SetActive(true)
                SectionXY.crossedGameObject:SetActive(true)
                SectionXZ.section:SetActive(false)
                SectionXZ.crossedGameObject:SetActive(false)
                SectionYZ.section:SetActive(false)
                SectionYZ.crossedGameObject:SetActive(false)
            elseif currentSection == 2 then
                SectionXY.section:SetActive(false)
                SectionXY.crossedGameObject:SetActive(false)
                SectionXZ.section:SetActive(true)
                SectionXZ.crossedGameObject:SetActive(true)
                SectionYZ.section:SetActive(false)
                SectionYZ.crossedGameObject:SetActive(false)
            elseif currentSection == 3 then
                SectionXY.section:SetActive(false)
                SectionXY.crossedGameObject:SetActive(false)
                SectionXZ.section:SetActive(false)
                SectionXZ.crossedGameObject:SetActive(false)
                SectionYZ.section:SetActive(true)
                SectionYZ.crossedGameObject:SetActive(true)
            else
                SectionXY.section:SetActive(false)
                SectionXY.crossedGameObject:SetActive(false)
                SectionXZ.section:SetActive(false)
                SectionXZ.crossedGameObject:SetActive(false)
                SectionYZ.section:SetActive(false)
                SectionYZ.crossedGameObject:SetActive(false)
            end
        end
        --
    elseif sectionMode == "Combine" then
        if sectionArguments["sectionNum"] == 1 then
            SectionXY.section:SetActive(true)
            SectionXY.crossedGameObject:SetActive(true)
        elseif sectionArguments["sectionNum"] == 2 then
            SectionXY.section:SetActive(true)
            SectionXY.crossedGameObject:SetActive(true)
            SectionXZ.section:SetActive(true)
            SectionXZ.crossedGameObject:SetActive(true)
        elseif sectionArguments["sectionNum"] == 3 then
            SectionXY.section:SetActive(true)
            SectionXY.crossedGameObject:SetActive(true)
            SectionXZ.section:SetActive(true)
            SectionXZ.crossedGameObject:SetActive(true)
            SectionYZ.section:SetActive(true)
            SectionYZ.crossedGameObject:SetActive(true)
        end
    end
end

--[DDenry]切面功能初始化
function CROSS.InitCrossFunction()
    --根据切面数量准备剖切工作
    CROSS.Prepare()

    print("Coroutine_Cross:Before")

    --挂载协程
    coroutine.yield()

    --**********************************************************
    print("Coroutine_Cross:After")

    while true do

        if currentSection == 1 then
            SectionXY.section:SetActive(true)
            SectionXY.crossedGameObject:SetActive(true)
            SectionXZ.section:SetActive(false)
            SectionXZ.crossedGameObject:SetActive(false)
            SectionYZ.section:SetActive(false)
            SectionYZ.crossedGameObject:SetActive(false)
        elseif currentSection == 2 then
            SectionXY.section:SetActive(false)
            SectionXY.crossedGameObject:SetActive(false)
            SectionXZ.section:SetActive(true)
            SectionXZ.crossedGameObject:SetActive(true)
            SectionYZ.section:SetActive(false)
            SectionYZ.crossedGameObject:SetActive(false)
        elseif currentSection == 3 then
            SectionXY.section:SetActive(false)
            SectionXY.crossedGameObject:SetActive(false)
            SectionXZ.section:SetActive(false)
            SectionXZ.crossedGameObject:SetActive(false)
            SectionYZ.section:SetActive(true)
            SectionYZ.crossedGameObject:SetActive(true)
        else
            SectionXY.section:SetActive(false)
            SectionXY.crossedGameObject:SetActive(false)
            SectionXZ.section:SetActive(false)
            SectionXZ.crossedGameObject:SetActive(false)
            SectionYZ.section:SetActive(false)
            SectionYZ.crossedGameObject:SetActive(false)
        end

        --显示切面UI
        --CrossUI:SetActive(true)

        --不显示原始模型
        OriObject:SetActive(false)

        --显示Substitute
        substitute:SetActive(true)

        --实时更新切面Shader
        updateCrossState = true

        --
        print("Coroutine_Cross!")

        coroutine.yield()
    end
end

--[DDenry]重置切面功能
function CROSS.ResetCrossFunction()
    --隐藏切面选择面板
    CrossOperator:SetActive(false)

    --重置所有变量
    CROSS.ResetAllVariables()

    --重置切面按钮
    ResetSectionButton(1)
    ResetSectionButton(2)
    ResetSectionButton(3)

    --update计算shader置否
    updateCrossState = false

    --隐藏CrossUI
    CrossOperator:SetActive(false)

    --隐藏OperatePanel
    FunctionChoose:SetActive(false)

    --隐藏SliderPanel
    SliderPanel:SetActive(false)

    --
    if substitute ~= nil then
        --隐藏所有切面以及替代模型
        substitute:SetActive(false)
    end

    --显示原始模型
    OriObject:SetActive(true)
end

--单面切C#脚本的Lua实现
function CROSS.OnePlaneCuttingController(tmp_Quad, renderer)
    --
    local tmp_vector3 = CS.UnityEngine.Vector3.one
    tmp_vector3.x = 0
    tmp_vector3.y = 0
    tmp_vector3.z = -1
    --
    local normal = tmp_Quad.transform:TransformVector(tmp_vector3)
    --
    local tmp_vector4 = CS.UnityEngine.Vector4.one
    tmp_vector4.x = normal.x
    tmp_vector4.y = normal.y
    tmp_vector4.z = normal.z
    tmp_vector4.w = 0
    --
    local tmp_position = tmp_Quad.transform.position
    --
    renderer.material:SetVector("_PlaneNormal", tmp_vector4)
    tmp_vector4.x = tmp_position.x
    tmp_vector4.y = tmp_position.y
    tmp_vector4.z = tmp_position.z
    tmp_vector4.w = 0
    renderer.material:SetVector("_PlanePosition", tmp_vector4)
end

--
function update()
    --切面模式
    if updateCrossState then

        --切面Shader，实时更新
        for j = 0, meshRenderer1.Length - 1 do
            --
            if sectionArguments["sectionNum"] >= 1 then
                if substitute.activeSelf then
                    CROSS.OnePlaneCuttingController(SectionXY.section.transform:Find("Quad"), meshRenderer1[j]:GetComponent("Renderer"))
                end
            end
            if sectionArguments["sectionNum"] >= 2 then
                if substitute.activeSelf then
                    CROSS.OnePlaneCuttingController(SectionXZ.section.transform:Find("Quad"), meshRenderer2[j]:GetComponent("Renderer"))
                end
            end
            if sectionArguments["sectionNum"] == 3 then
                if substitute.activeSelf then
                    CROSS.OnePlaneCuttingController(SectionYZ.section.transform:Find("Quad"), meshRenderer3[j]:GetComponent("Renderer"))
                end
            end
        end
    end
end

--
function ondisable()
    print("SubController_Disable")

    --
    PROCESS.ResetSceneState()

    --
    PROCESS.DisposeSceneState()

    collectgarbage("collect")
    --
    CS.System.GC.Collect()

    --
    print(">>>>>> Tool_Disable:", collectgarbage("count") .. "K")
end

--
function ondestroy()
    print("SubController_Destroy!")
    --
    CALLBACK = nil
    COMMON = nil
    PROCESS = nil
    StudioData = nil
    CROSS = nil
    MENU = nil
end