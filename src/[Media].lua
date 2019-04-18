---
--- Created by DDenry.
--- DateTime: 2019/4/17 11:26
---



local MEDIA = {}
local AUDIO = {}
local VIDEO = {}

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
    canAutoResume = false,
    --
    tip = nil
}

---id自增
MEDIA.AUTO_INCREMENT = 0

---构造Media结构体
function Media:new(name, type, anchorMin, anchorMax, url, ...)

    local arguments = {
        self.index, self.progress, self.isLoop, self.canAutoResume, self.tip
    }

    if select("#", ...) > 0 then
        for i = 1, i < select("#", ...) do
            arguments[i] = select(i, ...)
        end
    end

    --id自增
    MEDIA.AUTO_INCREMENT = MEDIA.AUTO_INCREMENT + 1

    self._id = MEDIA.AUTO_INCREMENT
    self.name = name
    self.type = type
    self.anchorMin = anchorMin
    self.anchorMax = anchorMax
    self.url = url
    self.index = arguments[1]
    self.progress = arguments[2]
    self.isLoop = arguments[3]
    self.canAutoResume = arguments[4]
    self.tip = arguments[5]

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
MEDIA.currentMedia = nil

MEDIA.mediaArray = {}

---初始化MediaTool
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
    MEDIA.buttonPlay.onClick:AddListener(function()
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
    MEDIA.buttonPause.onClick:AddListener(function()
        if MEDIA.currentMedia.type == "AUDIO" then
            AUDIO.PauseAudio()
        elseif MEDIA.currentMedia.type == "VIDEO" then
            VIDEO.PauseVideo()
        end
    end)

    --退出全屏按钮
    VIDEO.quitFullScreenButton.onClick:AddListener(function()
        --TODO:打开追踪

        --退出全屏播放(隐藏Full Screen UI)
        VIDEO.renderFullScreenRawImage.transform.parent.gameObject:SetActive(false)

        --隐藏全屏时切换按钮UI
        MEDIA.switchPanel.gameObject:SetActive(false)

        --丢失Marker
        MEDIA.LostTarget()
    end)

    --TODO:设置切换按钮为主题色
    MEDIA.previousButton.gameObject:GetComponent("Image").color = themeColor

    MEDIA.nextButton.gameObject:GetComponent("Image").color = themeColor

    --PreviousButton
    MEDIA.previousButton.onClick:AddListener(function()
        --下一个按钮显示
        MEDIA.nextButton.gameObject:SetActive(true)

        --当前多媒体资源存在
        if MEDIA.currentMedia ~= nil then
            --当前同位置资源数量>1
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
        if currentMarkerGameObject ~= nil then
            MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id].progress = MEDIA.progressSlider.value
        end
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

    elseif #mediaArray == 1 then

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
        VIDEO.mediaQuad.gameObject.transform.localScale = Vector3.one

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

            canvas.transform.localScale = Vector3.ones

            local canvasRect = canvas.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform)) and canvas.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform)) or canvas.gameObject:AddComponent(typeof(CS.UnityEngine.RectTransform))

            USERINTERFACE.InitRectTransform(canvasRect)

            --
            canvasRect.sizeDelta = Vector2(size.x, size.y)

            local graphicRaycaster = canvas.transform.gameObject:AddComponent(typeof(CS.UnityEngine.UI.GraphicRaycaster))

            graphicRaycaster.ignoreReversedGraphics = false

            --TODO:根据多媒体信息数量生成Tip
            MEDIA.AnalysisMedia(canvas)

            mediaQuad.gameObject:SetActive(true)

        else
            LogInfo(currentMarkerGameObject.name .. " has loaded its media!")

            --判断当前marker media数量
            if #MEDIA.mediaArray[currentMarkerGameObject.name] == 1 then

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
    if currentMarkerGameObject == nil then
        return
    end

    print("This media group has " .. #MEDIA.mediaArray[currentMarkerGameObject.name] .. " tips")

    --默认状态为不自动播放
    MEDIA.canAutoResume = false

    --Resume Twinkle
    for i, media in pairs(MEDIA.mediaArray[currentMarkerGameObject.name]) do

        if media.type == "AUDIO" then
            --Resume Twinkle
            AUDIO.TwinkleTip(media)
        elseif media.type == "VIDEO" then
            --
            VIDEO.TwinkleTip(media)

            --判断切换按钮状态
            if #media.url > 1 then
                --重置播放进度
                MEDIA.mediaArray[currentMarkerGameObject.name][media._id].progress = 0.0

                local _previous = media.tip.transform:Find("PreviousArrow").gameObject
                local _next = media.tip.transform:Find("NextArrow").gameObject
                if media.index == 1 then
                    --隐藏上一个按钮
                    _previous:SetActive(false)
                    --显示下一个按钮
                    _next:SetActive(true)
                elseif media.index == #media.url then
                    --隐藏下一个按钮
                    _next:SetActive(false)
                    --显示上一个按钮
                    _previous:SetActive(true)
                end
            end
        end
    end

    --允许自动播放的情况
    if #MEDIA.mediaArray[currentMarkerGameObject.name] == 1 then

        MEDIA.canAutoResume = true

        if #MEDIA.mediaArray[currentMarkerGameObject.name][1].url > 1 then
            local media = MEDIA.mediaArray[currentMarkerGameObject.name][1]
            --重置播放进度
            MEDIA.mediaArray[currentMarkerGameObject.name][1].progress = 0.0

            local _previous = media.tip.transform:Find("PreviousArrow").gameObject
            local _next = media.tip.transform:Find("NextArrow").gameObject

            if media.index == 1 then
                --隐藏上一个按钮
                _previous:SetActive(false)
                --显示下一个按钮
                _next:SetActive(true)
            elseif media.index == #media.url then
                --隐藏下一个按钮
                _next:SetActive(false)
                --显示上一个按钮
                _previous:SetActive(true)
            end
        end

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

    --[[    --边框
        local border = videoTip.gameObject:AddComponent(typeof(Image))
        border.sprite = Resources.Load("Media/border", typeof(CS.UnityEngine.Sprite))
        border.color = themeColor]]

    --生成按钮
    local videoRenderedRawImage = GameObject("VideoRenderedRawImage"):AddComponent(typeof(CS.UnityEngine.RectTransform))

    videoRenderedRawImage.transform:SetParent(videoTip.gameObject.transform)

    videoRenderedRawImage.transform.localRotation = Quaternion.Euler(Vector3.zero)

    USERINTERFACE.InitRectTransform(videoRenderedRawImage)

    videoRenderedRawImage.sizeDelta = Vector2.zero

    local rawImage = videoRenderedRawImage.gameObject:AddComponent(typeof(CS.UnityEngine.UI.RawImage))
    rawImage.texture = Resources.Load("Media/video-light", typeof(CS.UnityEngine.Texture))
    rawImage.color = Color.white
    rawImage.raycastTarget = true

    --是否需要上下切换按钮
    if #media.url > 1 then

        print("Media " .. media.name .. " have " .. #media.url .. " " .. media.type .. " medias at the same position!")

        --生成上一个按钮
        local previousARArrow = GameObject("PreviousArrow"):AddComponent(typeof(CS.UnityEngine.RectTransform))

        previousARArrow.transform:SetParent(videoTip.gameObject.transform)

        USERINTERFACE.InitRectTransform(previousARArrow)

        previousARArrow.anchorMin = Vector2(0, 0.5)
        previousARArrow.anchorMax = Vector2(0, 0.5)
        previousARArrow.pivot = Vector2(1, 0.5)
        previousARArrow.sizeDelta = Vector2(0.1, 0.1)
        previousARArrow.anchoredPosition3D = Vector2.zero

        local previousARImage = previousARArrow.gameObject:AddComponent(typeof(Image))

        previousARImage.sprite = Resources.Load("Media/arrow", typeof(CS.UnityEngine.Sprite))

        previousARImage.color = themeColor

        previousARImage.type = Image.Type.Simple

        previousARImage.preserveAspect = true

        --生成下一个按钮
        local nextARArrow = GameObject("NextArrow"):AddComponent(typeof(CS.UnityEngine.RectTransform))

        nextARArrow.transform:SetParent(videoTip.gameObject.transform)

        USERINTERFACE.InitRectTransform(nextARArrow)

        nextARArrow.localScale = Vector3(-1, 1, 1)
        nextARArrow.anchorMin = Vector2(1, 0.5)
        nextARArrow.anchorMax = Vector2(1, 0.5)
        nextARArrow.pivot = Vector2(1, 0.5)
        nextARArrow.sizeDelta = Vector2(0.1, 0.1)
        nextARArrow.anchoredPosition3D = Vector2.zero

        local nextARImage = nextARArrow.gameObject:AddComponent(typeof(Image))

        nextARImage.sprite = Resources.Load("Media/arrow", typeof(CS.UnityEngine.Sprite))

        nextARImage.color = themeColor

        nextARImage.type = Image.Type.Simple

        nextARImage.preserveAspect = true

        local previousARButton = previousARArrow.gameObject:AddComponent(typeof(CS.UnityEngine.UI.Button))
        previousARButton.transition = CS.UnityEngine.UI.Selectable.Transition.None

        --默认隐藏previousARButton
        previousARButton.gameObject:SetActive(false)

        local nextARButton = nextARArrow.gameObject:AddComponent(typeof(CS.UnityEngine.UI.Button))
        nextARButton.transition = CS.UnityEngine.UI.Selectable.Transition.None

        --切换到上一个资源
        previousARButton.onClick:AddListener(function()
            --显示下一个按钮
            nextARButton.gameObject:SetActive(true)

            --
            if MEDIA.currentMedia ~= nil then

                if #MEDIA.currentMedia.url > 1 then

                    MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMediaId].index = MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMediaId].index - 1

                    if MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMediaId].index == 1 then
                        --
                        previousARButton.gameObject:SetActive(false)
                    end

                    --播放上一个
                    VIDEO.PlayVideo(MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMediaId])
                end
            end

        end)

        --切换到下一个资源
        nextARButton.onClick:AddListener(function()
            --显示上一个按钮
            previousARButton.gameObject:SetActive(true)

            --
            if MEDIA.currentMedia == nil then
                MEDIA.currentMedia = media
            end

            if #MEDIA.currentMedia.url > 1 then

                MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMediaId].index = MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMediaId].index + 1

                if MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMediaId].index == #MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMediaId].url then
                    --
                    nextARButton.gameObject:SetActive(false)
                end

                --播放下一个
                VIDEO.PlayVideo(MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMediaId])
            end
        end)

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

                --判断当前切换按钮显示状态
                if MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id].index == 1 then
                    MEDIA.previousButton.gameObject:SetActive(false)
                    MEDIA.nextButton.gameObject:SetActive(true)
                elseif MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id].index == #MEDIA.currentMedia.url then
                    MEDIA.nextButton.gameObject:SetActive(false)
                    MEDIA.previousButton.gameObject:SetActive(true)
                else
                    MEDIA.previousButton.gameObject:SetActive(true)
                    MEDIA.nextButton.gameObject:SetActive(true)
                end

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

    --
    VIDEO.TwinkleTip(media)

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
    if currentMarkerGameObject ~= nil then
        AUDIO.audioSource.time = MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id].progress
    end

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

        while image.sprite ~= nil and currentMarkerGameObject ~= nil and not VIDEO.renderFullScreenRawImage.transform.gameObject.activeInHierarchy do

            if AUDIO.audioSource.isPlaying then

                if MEDIA.currentMedia == media then

                    coroutine.yield()

                    break
                end
            end

            image.sprite = (image.sprite == AUDIO.darkSignal and AUDIO.lightSignal) or AUDIO.darkSignal

            yield_return(CS.UnityEngine.WaitForSeconds(0.8))
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

        while image.sprite ~= nil and currentMarkerGameObject ~= nil and not VIDEO.renderFullScreenRawImage.transform.gameObject.activeInHierarchy do

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
    if currentMarkerGameObject ~= nil then

        MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id].progress = MEDIA.progressSlider.value

        local media = MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id]

        print("Save media " .. media.name .. " >>> " .. MEDIA.currentMedia._id .. "'s progress is " .. media.progress)

    end

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

    if currentMarkerGameObject ~= nil then
        VIDEO.videoPlayer.time = MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id].progress
    end

    VIDEO.videoPlayer.isLooping = MEDIA.currentMedia.isLoop

    print("[MEDIA]" .. MEDIA.currentMedia.type .. "=>" .. MEDIA.currentMedia.name .. ":MEDIA.currentMediaId=" .. MEDIA.currentMedia._id .. "'s progress is " .. VIDEO.videoPlayer.time)

    --播放视频的模式下显示UI
    MEDIA.UI:SetActive(true)

    --开始播放视频
    VIDEO.videoPlayer:Play()

    --
    VIDEO.needUpdateProcess = true
end

VIDEO.lightSignal = Resources.Load("Media/video-light", typeof(CS.UnityEngine.Texture))
VIDEO.darkSignal = Resources.Load("Media/video-dark", typeof(CS.UnityEngine.Texture))

function VIDEO.TwinkleTip(media)

    local twinkleCoroutine = coroutine.create(function()

        local image = media.tip.transform:Find("VideoRenderedRawImage"):GetComponent("RawImage")

        while image.texture ~= nil and currentMarkerGameObject ~= nil and not VIDEO.renderFullScreenRawImage.transform.gameObject.activeInHierarchy do

            if VIDEO.videoPlayer.isPlaying then

                if MEDIA.currentMedia == media then

                    coroutine.yield()

                    break
                end
            end

            image.texture = (image.texture == VIDEO.darkSignal and VIDEO.lightSignal) or VIDEO.darkSignal

            yield_return(CS.UnityEngine.WaitForSeconds(0.8))
        end

    end)

    assert(coroutine.resume(twinkleCoroutine))
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
    if currentMarkerGameObject ~= nil then
        MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id].progress = MEDIA.progressSlider.value
    end

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
        if currentMarkerGameObject ~= nil then
            MEDIA.mediaArray[currentMarkerGameObject.name][MEDIA.currentMedia._id].progress = 0.0
        end

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