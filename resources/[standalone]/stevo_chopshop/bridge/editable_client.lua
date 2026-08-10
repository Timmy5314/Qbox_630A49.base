local config = require('config')

---@param text string
function Bridge.Client.ShowTextUI(text)
  SetTimeout(1, function()
    
    if (config.textUI == "auto" and GetResourceState("ox_lib") == "started") or config.textUI == "ox_lib" then
      exports["ox_lib"]:showTextUI(text, {
        position = "left-center"
      })
    else
      error("We do not support it or you don't have a TextUI system!")
    end
  end)
end

function Bridge.Client.HideTextUI()

  if (config.textUI == "auto" and GetResourceState("ox_lib") == "started") or config.textUI == "ox_lib" then
    exports["ox_lib"]:hideTextUI()
  else
    error("We do not support it or you don't have a TextUI system!")
  end
end

---@param title string
---@param msg string
---@param type? "success" | "warning" | "error"
---@param time? number
function Bridge.Client.Notify(title, msg, type, time)
  title = title or 'Dealerships'
  type = type or "success"
  time = time or 5000

  if (config.notify == "auto" and GetResourceState("ox_lib") == "started") or config.notify == "ox_lib" then
    exports["ox_lib"]:notify({
      title = title,
      description = msg,
      type = type
    })
  else
    exports.qbx_core:Notify(msg, type, time)
  end
end

---@param coords vector3
---@param icon string 
---@param label string 
---@param func function
---@return string
function Bridge.Client.AddZone(coords, icon, label, func, id)
  local zone


  if (config.target == "auto" and GetResourceState("ox_target") == 'started') or config.target == "ox_target" then
    zone = exports.ox_target:addSphereZone({
      coords = vec3(coords.x, coords.y, coords.z+1.0),
      radius = 2.0,
      debug = false,
      options = {
          {
            icon = icon,
            label = label,
              onSelect = func,
              distance = 2.5,
          },
          
      }
    })
  else 
    error("We do not support it or you don't have a targeting system!")
  end


  return zone
end


---@param zone string
function Bridge.Client.RemoveZone(zone)

  if (config.target == "auto" and GetResourceState("ox_target") == 'started') or config.target == "ox_target" then
    exports.ox_target:removeZone(zone)
  end
end

---@param type "cash" | "bank" | "money" | string
function Bridge.Client.GetBalance(type)
  return exports.qbx_core:GetPlayerData().money[type] or 0
end


RegisterNetEvent("stevo_chopshops:client:notify", function(...)
  Bridge.Client.Notify(...)
end)



