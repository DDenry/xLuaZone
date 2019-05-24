---
--- Created by DDenry.
--- DateTime: 2019/4/30 11:03
---

local LoadBundle = coroutine.resume(coroutine.create(
        function()
            --更新脚本bundle地址
            local uri = "file://D:/Project/Code/MiniProgram/Assets/AssetBundle/assetsbundle"

            print("Script assetsbundle's path is " .. uri)

            local webRequest = CS.UnityEngine.Networking.UnityWebRequestAssetBundle.GetAssetBundle(uri)

            yield_return(webRequest:Send())
        end))