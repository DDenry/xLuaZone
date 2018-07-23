---
--- Created by DDenry.
--- DateTime: 2017/11/7 15:40
---
local Vector3 = CS.UnityEngine.Vector3
local LeanTouch = CS.Lean.LeanTouch
local GameObject = CS.UnityEngine.GameObject

local cameraX = GameObject.Find("Root/Models").transform:Find("CameraX").gameObject:GetComponent("Camera")
local cameraY = GameObject.Find("Root/Models").transform:Find("CameraY").gameObject:GetComponent("Camera")
local camera = GameObject.Find("Root/Models").transform:Find("Camera/Camera").gameObject:GetComponent("Camera")
local speed = 0.1

local minScale = 0.1
local maxScale = 20

local FingerOperator = {}

function FingerOperator.OnTwistDegrees(degrees)
    local over = false
    for i = 0, LeanTouch.Fingers.Count - 1 do
        if LeanTouch.Fingers[i].IsOverGui then
            over = true;
            break
        end
    end
    if over then
        return
    end
    --
    LeanTouch.ScaleObject(self.transform, LeanTouch.PinchScale)

    if (self.transform.localScale.x <= minScale) then
        self.transform.localScale = Vector3(minScale, minScale, minScale)
    end
    if (self.transform.localScale.x >= maxScale) then
        self.transform.localScale = Vector3(maxScale, maxScale, maxScale)
    end
end

function FingerOperator.OnFingerTap(finger)
    local over = false
    for i = 0, LeanTouch.Fingers.Count - 1 do
        if LeanTouch.Fingers[i].IsOverGui then
            over = true
            break
        end
    end
    if over then
        return
    end
    if LeanTouch.Fingers.Count > 1 then
        return
    end
    --
    LeanTouch.RotateObject(self.transform, LeanTouch.DragDelta.x * speed, cameraX)
    LeanTouch.RotateObject(self.transform, LeanTouch.DragDelta.y * speed, cameraY)
end

function FingerOperator.OnMultiDrag(drag)
    local over = false
    for i = 0, LeanTouch.Fingers.Count - 1 do
        if LeanTouch.Fingers[i].IsOverGui then
            over = true
            break
        end
    end
    if over then
        return
    end
    --
    LeanTouch.MoveObject(self.transform, LeanTouch.DragDelta, camera)
end

function onenable()
    print("FingerOperator_Model Enable!")
    LeanTouch.OnFingerDrag = FingerOperator.OnFingerTap
    LeanTouch.OnMultiDrag = FingerOperator.OnMultiDrag
    LeanTouch.OnTwistDegrees = FingerOperator.OnTwistDegrees
end

function start()
    print("FingerOperator_Model Start!")
end

function ondisable()
    print("FingerOperator_Model Disable!")
    LeanTouch.OnFingerDrag = nil
    LeanTouch.OnMultiDrag = nil
    LeanTouch.OnTwistDegrees = nil
end

function ondestroy()
    print("FingerOperator_Model Destroy!")
    FingerOperator = {}
end