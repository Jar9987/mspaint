local HttpService = game:GetService("HttpService")
local baseURL = "https://raw.githubusercontent.com/notpoiu/mspaint/main"

export type gameMapping = {
    exclusions: table?,
    main: string
}

if not getgenv().ExecutorSupport then
    loadstring(game:HttpGet(baseURL .. "/executorTest.lua"))()
end

if not getgenv().BloxstrapRPC then
    local BloxstrapRPC = {}

    export type RichPresence = {
        details:     string?,
        state:       string?,
        timeStart:   number?,
        timeEnd:     number?,
        smallImage:  RichPresenceImage?,
        largeImage:  RichPresenceImage?
    }

    export type RichPresenceImage = {
        assetId:    number?,
        hoverText:  string?,
        clear:      boolean?,
        reset:      boolean?
    }

    function BloxstrapRPC.SendMessage(command: string, data: any)
        local json = HttpService:JSONEncode({
            command = command, 
            data = data
        })
        
        print("[BloxstrapRPC] " .. json)
    end

    function BloxstrapRPC.SetRichPresence(data: RichPresence)
        if data.timeStart ~= nil then
            data.timeStart = math.round(data.timeStart)
        end
        
        if data.timeEnd ~= nil then
            data.timeEnd = math.round(data.timeEnd)
        end
        
        BloxstrapRPC.SendMessage("SetRichPresence", data)
    end 

    getgenv().BloxstrapRPC = BloxstrapRPC
end

local mapping: gameMapping = HttpService:JSONDecode(game:HttpGet(baseURL .. "/mappings/" .. game.GameId .. ".json"))
local scriptPath = mapping.main

if mapping.exclusions and mapping.exclusions[tostring(game.PlaceId)] then
    scriptPath = mapping.exclusions[tostring(game.PlaceId)]
end

loadstring(game:HttpGet(baseURL .. scriptPath))()

task.spawn(function()
    local function getGameAddonPath(path: string)
        return string.match(path, "/places/(.-)%.lua")
    end
    local gameAddonPath = getGameAddonPath(scriptPath)

    repeat task.wait() until getgenv().mspaint_loaded == true

    local AddonTab

    -- Addons (this is BETA, expect stuff to change) --
    if typeof(isfolder) == "function" and typeof(isfile) == "function" then
        if isfolder("mspaint\\addons") then
            local function AddAddonElement(LinoriaElement, AddonName, Element)
                if not LinoriaElement then
                    warn("[mspaint] Element '" .. tostring(Element.Name) .. " (" .. tostring(Element.Type) .. ")' didn't load: Invalid Linoria element.")
                    return
                end

                if typeof(Element) ~= "table" then
                    warn("[mspaint] Element '" .. tostring(Element.Name) .. " (" .. tostring(Element.Type) .. ")' didn't load: Invalid data.")
                    return
                end 

                if typeof(Element.Type) ~= "string" then 
                    warn("[mspaint] Element '" .. tostring(Element.Name) .. " (" .. tostring(Element.Type) .. ")' didn't load: Invalid name.")
                    return 
                end

                if typeof(AddonName) ~= "string" then 
                    warn("[mspaint] Element '" .. tostring(Element.Name) .. " (" .. tostring(Element.Type) .. ")' didn't load: Invalid addon name.")
                    return 
                end

                if Element.Type:sub(1, 3) == "Add" then Element.Type = Element.Type:sub(4) end

                -- Elements with no Arguments
                if Element.Type == "Divider" then
                    return LinoriaElement:AddDivider()
                end

                if Element.Type == "DependencyBox" then
                    return LinoriaElement:AddDependencyBox()
                end

                if typeof(Element.Name) ~= "string" then 
                    warn("[mspaint] Element '" .. tostring(Element.Name) .. " (" .. tostring(Element.Type) .. ")' didn't load: Invalid name.")
                    return 
                end

                -- Elements with Arguments
                if typeof(Element.Arguments) == "table" then
                    if Element.Type == "Label" then
                        return LinoriaElement:AddLabel(table.unpack(Element.Arguments))
                    end

                    if Element.Type == "Toggle" then
                        return LinoriaElement:AddToggle(AddonName .. "_" .. Element.Name, Element.Arguments)
                    end
                    
                    if Element.Type == "Button" then
                        return LinoriaElement:AddButton(Element.Arguments)
                    end
                    
                    if Element.Type == "Slider" then
                        return LinoriaElement:AddSlider(AddonName .. "_" .. Element.Name, Element.Arguments)
                    end
                    
                    if Element.Type == "Input" then
                        return LinoriaElement:AddInput(AddonName .. "_" .. Element.Name, Element.Arguments)
                    end
                    
                    if Element.Type == "Dropdown" then
                        return LinoriaElement:AddInput(AddonName .. "_" .. Element.Name, Element.Arguments)
                    end
                    
                    if Element.Type == "ColorPicker" then
                        return LinoriaElement:AddColorPicker(AddonName .. "_" .. Element.Name, Element.Arguments)        
                    end
                    
                    if Element.Type == "KeyPicker" then
                        return LinoriaElement:AddKeyPicker(AddonName .. "_" .. Element.Name, Element.Arguments)
                    end
                end

                warn("[mspaint] Element '" .. tostring(Element.Name) .. " (" .. tostring(Element.Type) .. ")' didn't load: Invalid element type.")
            end
            local LastGroupbox = "Right" -- do not change this to something else then Right PLEASE

            for _, file in pairs(listfiles("mspaint\\addons")) do
                if file:sub(#file - 3) == ".lua" or file:sub(#file - 4) == ".luau" then
                    local success, errorMessage = pcall(function()
                        local fileContent = readfile(file)
                        local addon = loadstring(fileContent)()

                        if typeof(addon.Name) ~= "string" or typeof(addon.Elements) ~= "table" then
                            warn("Addon '" .. string.gsub(file, "mspaint/addons/", "") .. "' didn't load: Invalid Name/Elements.")
                            return 
                        end

                        if type(addon.Game) ~= "string" then
                            warn("Addon '" .. string.gsub(file, "mspaint/addons/", "") .. "' didn't load: Invalid GameId.")
                            return
                        end

                        if addon.Game ~= gameAddonPath then
                            warn("Addon '" .. string.gsub(file, "mspaint/addons/", "") .. "' didn't load: Wrong game.")
                            return
                        end

                        addon.Name = addon.Name:gsub("%s+", "")
                        if typeof(addon.Title) ~= "string" then
                            addon.Title = addon.Name;
                        end
                        
                        if not AddonTab then
                            AddonTab = getgenv().Library.Window:AddTab("Addons [BETA]")
                            AddonTab:UpdateWarningBox({
                                Visible = true,
                                Title = "WARNING",
                                Text = "This tab is for UN-OFFICIAL addons made for mspaint. We are not responsible for what addons you will use. You are putting yourself AT RISK since you are executing third-party scripts."
                            })
                        end

                        local AddonGroupbox = LastGroupbox == "Right" and AddonTab:AddLeftGroupbox(addon.Title) or AddonTab:AddRightGroupbox(addon.Title);
                        LastGroupbox = LastGroupbox == "Right" and "Left" or "Right";
                        if typeof(addon.Description) == "string" then
                            AddonGroupbox:AddLabel(addon.Description, true)
                        end

                        local function loadElements(linoriaMainElement, elements)
                            for _, element in pairs(elements) do
                                task.spawn(function()
                                    local linoriaElement = AddAddonElement(linoriaMainElement, addon.Name, element)
                                    if linoriaElement ~= nil and typeof(element.Elements) == "table" then
                                        loadElements(linoriaElement, element.Elements)
                                    end  
                                end)                      
                            end
                        end

                        loadElements(AddonGroupbox, addon.Elements)
                    end)

                    if not success then
                        warn("[mspaint] Failed to load addon '" .. string.gsub(file, "mspaint/addons/", "") .. "':", errorMessage)
                    end
                end
            end
        end
    end
end)