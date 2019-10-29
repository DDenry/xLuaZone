---
--- Created by DDenry.
--- DateTime: 2017/8/31 13:02
---
local Vector3 = CS.UnityEngine.Vector3
local LeanTouch = CS.Lean.LeanTouch
local minScale = 0.1
local maxScale = 2
local _modelCamera = CS.UnityEngine.GameObject.Find("Root/Models/Camera/Camera"):GetComponent("Camera")
local _cameraFar = _modelCamera.farClipPlane

function onenable()
    print("LeanTouch_Scale Enable!")

    if not(_Global:GetData("minScale") == nil) then
        minScale = tonumber(_Global:GetData("minScale"))
        maxScale = tonumber(_Global:GetData("maxScale"))
        print("Model_MinScale:" .. minScale)
        print("Model_MaxScale:" .. maxScale)
    end

    LeanTouch.OnTwistDegrees = OnTwistDegrees
end

--
function OnTwistDegrees(degrees)
    local over = false
    for i = 0,LeanTouch.Fingers.Count-1 do
        if LeanTouch.Fingers[i].IsOverGui then
            over = true;
            break
        end
    end
    if over then
        return
    end
    --
    LeanTouch.ScaleObject(self.transform,1/LeanTouch.PinchScale)

    if(self.transform.localScale.x <= minScale)then
        self.transform.localScale = Vector3(minScale,minScale,minScale)
    end
    if(self.transform.localScale.x >= maxScale)then
        self.transform.localScale = Vector3(maxScale,maxScale,maxScale)
    end
end

function start()
    print("LeanTouch_Scale Start!")
end

function ondisable()
    print("LeanTouch_Scale Disable!")
    LeanTouch.OnTwistDegrees = nil
end

function ondestroy()
    print("LeanTouch_Scale Destroy!")
end