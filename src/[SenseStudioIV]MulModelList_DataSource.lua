---
--- Created by DDenry.
--- DateTime: 2018/4/9 10:52
---

local GameObject = CS.UnityEngine.GameObject
local Destroy = CS.UnityEngine.Object.Destroy
local Vector2 = CS.UnityEngine.Vector2
local Vector3 = CS.UnityEngine.Vector3
local PageInfoManager = CS.SubScene.PageInfoManager.Instance
local allPageInfo = PageInfoManager.AllPageInfo
local SSMessageManager = CS.SubScene.SSMessageManager.Instance
local Input = CS.UnityEngine.Input
local Time = CS.UnityEngine.Time
local Color = CS.UnityEngine.Color

local yield_return = (require 'cs_coroutine').yield_return

local PROCESS = {}

local loadedItems

local defaultTextColor = {
    r = 118 / 255.0,
    g = 118 / 255.0,
    b = 118 / 255.0,
    a = 1
}

--
local unSelectedColor = {
    r = 230 / 255,
    g = 230 / 255,
    b = 230 / 255,
    a = 1
}

local Shadow = self.transform:Find("Shadow").gameObject
local ShadowButton = Shadow:GetComponent("Button")

local selectedColor = _Global:GetData("themeColor")

local currentSelectedItem

function onenable()
    print("MulModelList_Enable!")
    --初始化
    loadedItems = {}

    --点击背板隐藏多模型列表
    ShadowButton.onClick:AddListener(function()
        Shadow:SetActive(false)
        self.transform:Find("ListView").gameObject:SetActive(false)
    end)

    --获取所选PageName
    local selectedPageName = ((_Global:GetData("selectedPageName") ~= nil) and _Global:GetData("selectedPageName")) or ""
    --生成列表项
    local Coroutine_GenerateItems = coroutine.create(function()
        PROCESS.GenerateItems(selectedPageName)
    end)
    --执行协程
    assert(coroutine.resume(Coroutine_GenerateItems))
    --
    if coroutine.status(Coroutine_GenerateItems) == "suspended" then
        Coroutine_GenerateItems = nil
    end
end

--生成列表项
function PROCESS.GenerateItems(selectedPageName)
    print("GeneratingItemsOfPageName:", selectedPageName)
    --
    local value

    if allPageInfo:TryGetValue(selectedPageName) then

        _, value = allPageInfo:TryGetValue(selectedPageName)

        --生成列表
        for i = 0, value.Count - 1 do
            local _item = GameObject.Instantiate(DefaultItem, DefaultItem.transform.parent.transform)

            loadedItems[#loadedItems + 1] = _item

            --第一项默认为选中状态
            if i == 0 then
                _item:GetComponent("Image").color = selectedColor
                _item.transform:Find("Text").gameObject:GetComponent("Text").color = Color.white
                --
                currentSelectedItem = _item
            end

            --_item.transform:SetParent(DefaultItem.transform.parent)
            _item.transform:Find("Text"):GetComponent("Text").text = "   " .. value[i].ModelName .. "   "

            --多模型列表点击
            _item:GetComponent("Button").onClick:AddListener(function()
                --
                if currentSelectedItem ~= _item then
                    --重置所有Item为未选中状态
                    for j, _item in ipairs(loadedItems) do
                        _item:GetComponent("Image").color = unSelectedColor
                        _item.transform:Find("Text"):GetComponent("Text").color = defaultTextColor
                    end
                    --自身Item变为选中
                    _item:GetComponent("Image").color = selectedColor
                    _item.transform:Find("Text"):GetComponent("Text").color = Color.white

                    --pagelist://do?#index|projectPath=projectPath&sceneGuid=sceneGuid&sceneName=assetBundlePath&modelName=modelName&haveModels=htmlPath&sectionNum=sectionNum

                    local url = "pagelist://do?"

                    local projectPath = ""

                    local sceneName = ""

                    local sceneGuid = ""

                    local autoShow = false

                    if value[i].ProjectPath ~= nil then
                        projectPath = value[i].ProjectPath
                    end

                    if value[i].SceneName ~= nil then
                        sceneName = value[i].SceneName
                    end

                    if value[i].SceneGuid ~= nil then
                        sceneGuid = value[i].SceneGuid
                    end

                    if value[i].AutoShowPoint ~= nil then
                        autoShow = value[i].AutoShowPoint
                    end

                    local _url = url .. "#-1|projectPath=" .. projectPath .. "&sceneGuid=" .. sceneGuid .. "&sceneName=" .. sceneName .. "&pageName=" .. value[i].PageName .. "&modelName=" .. value[i].ModelName .. "&haveMulModel=False&sectionNum=" .. value[i].SortingName .. "&autoShow=" .. tostring(autoShow)

                    print("MulModelList_PageSelected:" .. _url)

                    --加载相应模型
                    SSMessageManager:ReceiveMessage("LoadModel", _url)
                end

                --隐藏List
                self.transform:Find("ListView").gameObject:SetActive(false)
                --隐藏Shadow
                self.transform:Find("Shadow").gameObject:SetActive(false)

                --
                currentSelectedItem = _item
            end)
        end

        --隐藏默认Item
        DefaultItem:SetActive(false)

        --数据加载完毕后显示List
        self.transform:Find("ListView").gameObject:SetActive(true)
        self.transform:Find("Shadow").gameObject:SetActive(true)

        --所有项注册自动滑动方法
        for i, _item in ipairs(loadedItems) do
            assert(coroutine.resume(coroutine.create(function()
                AutoSlide(_item.transform:Find("Text"):GetComponent("RectTransform"))
            end)))
        end
    end
end

function AutoSlide(rectTransform)
    if self.gameObject.activeSelf then
        --
        if rectTransform ~= nil then
            --需要滑动
            if rectTransform.sizeDelta.x > 0 then
                if self.transform:Find("Shadow").gameObject.activeSelf then
                    --从左向右滑动
                    if rectTransform.anchoredPosition.x <= -rectTransform.sizeDelta.x then
                        rectTransform.anchoredPosition = Vector2(0, rectTransform.anchoredPosition.y)
                    else
                        rectTransform.anchoredPosition = Vector2(rectTransform.anchoredPosition.x - 10, rectTransform.anchoredPosition.y)
                    end
                    --回归到最初位置
                else
                    rectTransform.anchoredPosition = Vector2(0, rectTransform.anchoredPosition.y)
                end
            else
                --
                yield_return(CS.UnityEngine.WaitForSeconds(1.0))
            end
            --
            yield_return(CS.UnityEngine.WaitForSeconds(1))

            --递归
            assert(coroutine.resume(coroutine.create(function()
                if rectTransform ~= nil then
                    AutoSlide(rectTransform)
                end
            end)))
        end
    end
end

function update()
end

function ondisable()
    print("MulModelList_Disable!")
    --清除已经加载的数据
    for i, _item in pairs(loadedItems) do
        Destroy(loadedItems[i])
    end
    --显示默认Item
    DefaultItem:SetActive(true)
end