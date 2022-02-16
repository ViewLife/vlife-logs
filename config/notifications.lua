Notify = {}

Notify.Success = function(target, text)
    if GetResourceState('screenshot-basic') == "started" then
        exports.Prefech_Notify:Notify({ title = "Success!", message = text, color = "#93CAED", target = target, timeout = 15 })
    else
        print("Prefech_Notify is not installed.")
    end
end

Notify.Error = function(target, text)
    if GetResourceState('screenshot-basic') == "started" then
        exports.Prefech_Notify:Notify({ title = "Error!", message = text, color = "#93CAED", target = target, timeout = 15 })
    else
        print("Prefech_Notify is not installed.")
    end
end

Notify.Custom = function(target, title, text)
    if GetResourceState('screenshot-basic') == "started" then
        exports.Prefech_Notify:Notify({ title = title, message = text, color = "#93CAED", target = target, timeout = 15 })
    else
        print("Prefech_Notify is not installed.")
    end
end