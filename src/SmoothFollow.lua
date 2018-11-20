---
--- Created by DDenry.
--- DateTime: 2018/10/17 15:29
---

---物体跟随
local target

--间隔距离
local distance = 5.0
--相距高度
local height = 3.0

--旋转阻尼
local rotationDamping = 0.0
--
local heightDamping = 0.0

--
function onenable()
    target = CS.UnityEngine.GameObject.Find("Cube/target")
end

--LateUpdate
function lateupdate()
    --Early out if we don't have a target
    if target.transform == nil then
        return
    end

    --Calculate the current rotation angles
    local wantedRotationAngle = target.transform.eulerAngles.y
    local wantedHeight = target.transform.position.y + height

    local currentRotationAngle = self.transform.eulerAngles.y
    local currentHeight = self.transform.position.y

    --当前高度设置为target.transform.y * 2
    currentHeight = target.transform.position.y * 2

    --Damp the rotation around the y-axis
    currentRotationAngle = CS.UnityEngine.Mathf.LerpAngle(currentRotationAngle, wantedRotationAngle, rotationDamping * CS.UnityEngine.Time.deltaTime)

    --Damp the height
    currentHeight = CS.UnityEngine.Mathf.Lerp(currentHeight, wantedHeight, heightDamping * CS.UnityEngine.Time.deltaTime)

    --Convert the angle into a rotation
    local currentRotation = CS.UnityEngine.Quaternion.Euler(0, currentRotationAngle, 0)

    --Set the position of the camera on the x-s plane to:
    --distance meters behind the target
    self.transform.position = target.transform.position
    self.transform.position = self.transform.position - currentRotation * CS.UnityEngine.Vector3.forward * distance

    --Set the height of the camera
    self.transform.position = CS.UnityEngine.Vector3(self.transform.position.x, currentHeight, self.transform.position.z)

    --Always look at the target
    self.transform:LookAt(target.transform)
end