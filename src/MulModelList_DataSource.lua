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

local unSelectedColor = {
    r = 230 / 255,
    g = 230 / 255,
    b = 230 / 255,
    a = 1
}
local selectedColor = {
    r = 237 / 255,
    g = 237 / 255,
    b = 237 / 255,
    a = 1
}

function onenable()
    print("MulModelList_Enable!")
    --初始化
    loadedItems = {}
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
            end

            --_item.transform:SetParent(DefaultItem.transform.parent)
            _item.transform:Find("Text"):GetComponent("Text").text = "   " .. value[i].ModelName .. "   "
            
            _item:GetComponent("Button").onClick:AddListener(function()
                if _item:GetComponent("Image").color.r <= selectedColor.r then
                    --重置所有Item为未选中状态
                    for i, _item in ipairs(loadedItems) do
                        _item:GetComponent("Image").color = unSelectedColor
                    end
                    --自身Item变为选中
                    _item:GetComponent("Image").color = selectedColor

                    local url = "pagelist://post?";
                    local _url = url .. "sceneName=" .. value[i].SceneName .. "&pageName=" .. value[i].PageName .. "&modelName=" .. value[i].ModelName .. "&haveMulModel=False&sectionNum=" .. value[i].SortingName

                    --加载相应模型
                    SSMessageManager:ReceiveMessage("LoadModel", _url)
                end

                --隐藏List
                self.transform:Find("ListView").gameObject:SetActive(false)
                --隐藏Shadow
                self.transform:Find("Shadow").gameObject:SetActive(false)
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
    --
    if rectTransform ~= nil then
        if self.transform:Find("Shadow").gameObject.activeSelf then
            --需要滑动
            if rectTransform.sizeDelta.x > 0 then
                --从左向右滑动
                if rectTransform.anchoredPosition.x <= -rectTransform.sizeDelta.x then
                    rectTransform.anchoredPosition = Vector2(0, rectTransform.anchoredPosition.y)
                else
                    rectTransform.anchoredPosition = Vector2(rectTransform.anchoredPosition.x - 10, rectTransform.anchoredPosition.y)
                end
            end
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

function update()
    if self.transform:Find("Shadow").gameObject.activeSelf then
        if Input.GetKeyUp(CS.UnityEngine.KeyCode.Mouse0) then
            for i, _item in ipairs(loadedItems) do
                _item:GetComponent("Button").interactable = true
            end
        end
    end
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