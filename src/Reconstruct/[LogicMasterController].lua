---
--- Created by DDenry.
--- DateTime: 2019/4/29 10:56
---

local Logic = {}

print("<[LogicMasterController].lua> has required!")

---UILogic
Logic.UI = require('[UILogic].lua')

---ProcessLogic
Logic.ProcessController = require('[ProcessLogic].lua')

---DataHandler
Logic.DataHandler = require('[DataHandler].lua')

function Logic.Start()

    --隐藏加载界面
    Logic.UI.HideLoading()

end

return Logic