---
--- Created by DDenry.
--- DateTime: 2017/11/7 15:40
---
local Vector3 = CS.UnityEngine.Vector3
local LeanTouch = CS.Lean.LeanTouch
local Camera = CS.UnityEngine.Camera
local GameObject = CS.UnityEngine.GameObject
local Time = CS.UnityEngine.Time
local Input = CS.UnityEngine.Input

local cameraX = GameObject.Find("Root/Models").transform:Find("CameraX").gameObject:GetComponent("Camera")
local cameraY = GameObject.Find("Root/Models").transform:Find("CameraY").gameObject:GetComponent("Camera")
local camera = GameObject.Find("Root/Models").transform:Find("Camera/Camera").gameObject:GetComponent("Camera")
local speed = 0.1
local radius = 20
local minScale = 5
local maxScale = 50

local right = Vector3(0, 0, 1)
local up = Vector3(0, 1, 0)

function OnFingerTap(finger)
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

    RotateCamera()

    --LeanTouch.RotateObject(self.transform, LeanTouch.DragDelta.x * speed, cameraX)
    --LeanTouch.RotateObject(self.transform, LeanTouch.DragDelta.y * speed, cameraY)
end

function OnMultiDrag(drag)
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

function OnTwistDegrees(degrees)
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
    local targetRadius = radius * 1 / LeanTouch.PinchScale

    if targetRadius < minScale then
        targetRadius = minScale
    elseif targetRadius > maxScale then
        targetRadius = maxScale
    end

    radius = CS.UnityEngine.Mathf.Lerp(radius, targetRadius, 0.5)

    RotateCamera()
end

function onenable()
    print("LeanTouch_Move&Rotate Enable!")
    LeanTouch.OnFingerDrag = OnFingerTap
    LeanTouch.OnMultiDrag = OnMultiDrag
    --
    LeanTouch.OnTwistDegrees = OnTwistDegrees

    --重置方向向量
    right = Vector3(0, 0, 1)
    up = Vector3(0, 1, 0)

    --
    radius = 20

    RotateCamera()
end

function RotateCamera()
    --
    local newPosition = self.transform.position
    local mouseX = Input.GetAxis("Mouse X")
    local mouseZ = Input.GetAxis("Mouse Y")

    newPosition = newPosition + right * mouseX - up * mouseZ
    newPosition:Normalize()
    right = Vector3.Cross(up, newPosition)
    up = Vector3.Cross(newPosition, right)
    right:Normalize()
    up:Normalize()
    newPosition:Normalize()
    self.transform.position = newPosition * radius
    self.transform:LookAt(Vector3.zero, up)
end

function start()
    print("LeanTouch_Move&Rotate Start!")
end

function update()

end

function ondisable()
    print("LeanTouch_Move&Rotate Disable!")
    LeanTouch.OnFingerDrag = nil
    LeanTouch.OnMultiDrag = nil
    LeanTouch.OnFingerTap = nil
end

function ondestroy()
    print("LeanTouch_Move&Rotate Destroy!")
end