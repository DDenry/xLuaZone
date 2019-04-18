---
--- Created by DDenry.
--- DateTime: 2019/4/17 12:11
---

local BasePackage = {}

BasePackage.UnityEngine = CS.UnityEngine
BasePackage.Application = BasePackage.UnityEngine.Application
BasePackage.Color = BasePackage.UnityEngine.Color
BasePackage.Transform = BasePackage.UnityEngine.Transform
BasePackage.GameObject = BasePackage.UnityEngine.GameObject
BasePackage.Vector2 = BasePackage.UnityEngine.Vector2
BasePackage.Vector3 = BasePackage.UnityEngine.Vector3
BasePackage.Object = BasePackage.UnityEngine.Object
BasePackage.Destroy = BasePackage.Object.Destroy
BasePackage.Resources = BasePackage.UnityEngine.Resources
BasePackage.PlayerPrefs = BasePackage.UnityEngine.PlayerPrefs
BasePackage.File = CS.System.IO.File
BasePackage.FileInfo = CS.System.IO.FileInfo
BasePackage.Input = BasePackage.UnityEngine.Input
BasePackage.Time = BasePackage.UnityEngine.Time

return BasePackage