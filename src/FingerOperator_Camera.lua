---
--- Created by DDenry.
--- DateTime: 2017/11/7 15:40
---
local Vector3 = CS.UnityEngine.Vector3
local LeanTouch = CS.Lean.LeanTouch
local GameObject = CS.UnityEngine.GameObject
local Input = CS.UnityEngine.Input

local FingerOperator = {}

local Models = GameObject.Find("Root/Models")
local oriRadius
local radius
local minRadius
local maxRadius

local right = Vector3(0, 0, 1)
local up = Vector3(0, 1, 0)

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

    FingerOperator.OperateCamera("Rotate")
end

--双指移动
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
    --LeanTouch.MoveObject(camera.transform, LeanTouch.DragDelta, nil)
end

--
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
    local targetRadius = radius * 1 / LeanTouch.PinchScale

    if targetRadius < minRadius then
        targetRadius = minRadius
    elseif targetRadius > maxRadius then
        targetRadius = maxRadius
    end

    --
    radius = CS.UnityEngine.Mathf.Lerp(radius, targetRadius, 0.5)

    --
    FingerOperator.OperateCamera("Scale")
end

function onenable()
    print("FingerOperator_Camera Enable!")
    --回收垃圾
    collectgarbage("collect")

    --
    LeanTouch.OnFingerDrag = FingerOperator.OnFingerTap
    LeanTouch.OnMultiDrag = FingerOperator.OnMultiDrag
    --
    LeanTouch.OnTwistDegrees = FingerOperator.OnTwistDegrees

    --重置方向向量
    right = Vector3(0, 0, 1)
    up = Vector3(0, 1, 0)

    --计算相机与模型的距离
    radius = Vector3.Distance(self.transform.localPosition, Models.transform.localPosition) * Models.transform.localScale.x
    oriRadius = radius

    minRadius = radius - 50
    maxRadius = radius + 20
end

--
function FingerOperator.OperateCamera(type)
    --
    local newPosition = self.transform.position

    --旋转模型
    if type == "Rotate" then
        radius = Vector3.Distance(self.transform.localPosition, Models.transform.localPosition) * Models.transform.localScale.x
        local mouseX = Input.GetAxis("Mouse X")
        local mouseZ = Input.GetAxis("Mouse Y")

        --距离缩进后手势灵敏度
        newPosition = (newPosition + right * mouseX - up * mouseZ) * (CS.System.Math.Pow(radius, 3) / CS.System.Math.Pow(oriRadius, 3))
    end

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
    print("FingerOperator_Camera Start!")
end

function ondisable()
    print("FingerOperator_Camera Disable!")
    LeanTouch.OnFingerDrag = nil
    LeanTouch.OnMultiDrag = nil
    LeanTouch.OnFingerTap = nil

    --回收垃圾
    collectgarbage("collect")
end

function ondestroy()
    print("FingerOperator_Camera Destroy!")
    FingerOperator = {}
    --回收垃圾
    collectgarbage("collect")
end