---
--- Created by DDenry.
--- DateTime: 2019/4/29 14:09
---

local UI = {}

UI.mainCanvas = FirstCanvas
UI.loading = UI.mainCanvas.transform:Find("Overlay/Loading").gameObject

---隐藏加载界面
function UI.HideLoading()

    UI.TransferVisibility(UI.loading)
end

---CanvasGroup/GameObject 的显隐
function UI.TransferVisibility(element)
    if element.gameObject:GetComponent(typeof(CanvasGroup)) ~= nil then

        local self = element.gameObject:GetComponent(typeof(CanvasGroup))

        if self.alpha == 1.0 then
            self.alpha = 0.0
        elseif self.alpha == 0.0 then
            self.alpha = 1.0
        end

        self.interactable = (self.alpha == 0.0 and { false } or { true })[1]
        self.blocksRaycasts = (self.alpha == 0.0 and { false } or { true })[1]

    else
        local self = element.gameObject
        if self.activeSelf then
            self:SetActive(false)
        else
            self:SetActive(true)
        end
    end

end

return UI