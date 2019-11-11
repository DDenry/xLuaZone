---
--- Created by DDenry.
--- DateTime: 2019/11/7 15:29
---

local yield_return = (require 'cs_coroutine').yield_return

local defaultPosition, defaultRotation, defaultScale

local audioSource, animator

local audioLength

local Target, Reset, Cancel, Audio, Animator, OnceMore, Exit, ScreenShot

local mediaStruct = {
    from = 0, to = 0, actionId = 1
}

Target = self.transform:Find("yiyuanneibu").gameObject
Reset = self.transform:Find("Canvas/OnceMore/Bottom/Confirm").gameObject
Cancel = self.transform:Find("Canvas/OnceMore/Bottom/Cancel").gameObject
ScreenShot = self.transform:Find("Canvas/ScreenShot")
Audio = self.transform:Find("AudioSource").gameObject
Animator = Target.transform:Find("shou_1").gameObject
OnceMore = self.transform:Find("Canvas/OnceMore").gameObject
Exit = self.transform:Find("Canvas/Exit").gameObject

function mediaStruct:new(from, to, actionId)

    self.from = from
    self.to = to
    self.actionId = actionId

    local o = {
        from = self.from,
        to = self.to,
        actionId = self.actionId
    }

    --元表保护
    self.__metatable = "Sorry, u cannot do this!"

    --元表
    setmetatable(o, self)
    self.__index = self

    return o
end

--
local mediaGroup = {
    mediaStruct:new(0, 6.9, 2),
    mediaStruct:new(7, 13, 3),
    mediaStruct:new(13.5, 22.5, 1),
    mediaStruct:new(23, 31.5, 4),
    mediaStruct:new(32, 37, 5),
    mediaStruct:new(37.5, 45.5, 2),
    mediaStruct:new(46, 55, 5)
}

defaultPosition = Target.transform.localPosition
defaultRotation = Target.transform.localRotation
defaultScale = Target.transform.localScale

audioSource = Audio:GetComponent("AudioSource")
audioLength = audioSource.clip.length

animator = Animator:GetComponent("Animator")

function onenable()
    print("Hospital-Introduce OnEnable")
    begin()
end

function start()
    ScreenShot:GetComponent("Button").onClick:AddListener(function()
        CS.UnityEngine.ScreenCapture.CaptureScreenshot(CS.System.DateTime.Now:ToFileTimeUtc() .. ".jpg")
    end)

    Reset:GetComponent("Button").onClick:AddListener(function()
        reset()
        begin()
    end)

    Cancel:GetComponent("Button").onClick:AddListener(function()
        exit()
    end)

    Exit:GetComponent("Button").onClick:AddListener(function()
        exit()
    end)
end

function reset()
    Target.transform.localPosition = defaultPosition
    Target.transform.localRotation = defaultRotation
    Target.transform.localScale = defaultScale
end

function exit()
    self.gameObject:SetActive(false)
    reset()
    CS.UnityEngine.GameObject.Find("Configs/DataSetLoader"):GetComponent(typeof(CS.EzComponents.Vuforia.DataSetLoader)):ActiveDataSet()
end

function begin()

    OnceMore:SetActive(false)

    audioSource:Play()

    animator.enabled = true

    animator:Play("-1")

    assert(coroutine.resume(coroutine.create(function()
        while (audioSource.isPlaying) do

            local duration = 0.5

            for i, media in ipairs(mediaGroup) do
                if audioSource.time > media['from'] and audioSource.time < media['to'] then
                    animator:Play("-1")
                    animator:Update(1)
                    yield_return(1)
                    animator:Play(tostring(media['actionId']))
                    duration = tonumber(media['to'] - media['from'])
                end
            end

            yield_return(CS.UnityEngine.WaitForSeconds(duration + 0.05))
        end
    end)))
end

function update()
    if audioSource ~= nil and audioSource.isPlaying then
        if audioLength - audioSource.time < 0.5 then
            print("Audio played once completely!")
            animator:Play(0)
            finish()
        end
    end

    if CS.UnityEngine.Input.GetKeyDown(CS.UnityEngine.KeyCode.Space) then
        print(audioSource.time)
    end
end

function finish()
    audioSource:Stop()
    OnceMore:SetActive(true)
    animator.enabled = false
end