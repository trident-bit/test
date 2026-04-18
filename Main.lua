--[[
    Alpha Spy SKIDDER 😡😡
    Author: trident
--]]

--// Base Configuration
local Configuration = {
    UseWorkspace = false,
    NoActors = false,
    FolderName = "Alpha Spy",
    RepoUrl = "https://raw.githubusercontent.com/trident-bit/test/main",
    ParserUrl = "",
    Directory = "Alpha Spy",
    DebugMode = false,
}

--// Load overwrites from parameters
local Parameters = {...}
local Overwrites = Parameters[1]
if typeof(Overwrites) == "table" then
    for Key, Value in Overwrites do
        Configuration[Key] = Value
    end
end

--// Service handler
local Services = setmetatable({}, {
    __index = function(self, Name: string): Instance
        local Service = game:GetService(Name)
        return cloneref(Service)
    end,
})

--// Files module
local Files = loadstring(game:HttpGet(`{Configuration.RepoUrl}/lib/Files.lua`))()
Files:PushConfig(Configuration)
Files:Init({
    Services = Services
})

local Folder = Files.FolderName
local Scripts = {
    --// User configurations
    Config = Files:GetModule(`{Folder}/Config`, "Config"),
    ReturnSpoofs = Files:GetModule(`{Folder}/Return spoofs`, "Return Spoofs"),
    Configuration = Configuration,
    Files = Files,
    
    --// Core Libraries
    Process = game:HttpGet(`{Configuration.RepoUrl}/lib/Process.lua`),
    Hook = game:HttpGet(`{Configuration.RepoUrl}/lib/Hook.lua`),
    Flags = game:HttpGet(`{Configuration.RepoUrl}/lib/Flags.lua`),
    Ui = game:HttpGet(`{Configuration.RepoUrl}/lib/Ui.lua`),
    Generation = game:HttpGet(`{Configuration.RepoUrl}/lib/Generation.lua`),
    Communication = game:HttpGet(`{Configuration.RepoUrl}/lib/Communication.lua`),
    Debug = game:HttpGet(`{Configuration.RepoUrl}/lib/Debug.lua`),
}

--// Services
local Players: Players = Services.Players

--// Load all modules
local Modules = Files:LoadLibraries(Scripts)
local Process = Modules.Process
local Hook = Modules.Hook
local Ui = Modules.Ui
local Debug = Modules.Debug

--// Initialize Debug Module if enabled
if Configuration.DebugMode and Debug then
    Debug:Init({
        Modules = Modules,
        Services = Services,
        Configuration = Configuration
    })
    print("[Alpha Spy] Debug mode enabled - Bypass tools loaded")
end

--// Check if supported
if not Process:CheckIsSupported() then
    return
end

--// Initialize UI
Ui:Init({
    Modules = Modules,
    Services = Services,
    Configuration = Configuration
})

--// Create main window
Ui:CreateMainWindow()
Ui:CreateWindowContent()

--// Setup Communication
local Communication = Modules.Communication
local ChannelId, Channel = Communication:CreateChannel()

--// Initialize modules
Process:Init({
    Modules = Modules,
    Services = Services
})

--// Setup communication callbacks
Communication:AddTypeCallbacks({
    ["QueueLog"] = function(Data)
        Ui:QueueLog(Data)
    end,
    ["Print"] = function(...)
        Ui:ConsoleLog(...)
    end,
    ["RemoteData"] = function(Id, RemoteData)
        Process:SetRemoteData(Id, RemoteData)
    end,
    ["AllRemoteData"] = function(Key, Value)
        Process:SetAllRemoteData(Key, Value)
    end,
    ["UpdateSpoofs"] = function(Content)
        local Spoofs = loadstring(Content)()
        Process:SetNewReturnSpoofs(Spoofs)
    end,
})

--// Initialize Generation module
Modules.Generation:Init({
    Modules = Modules,
    Configuration = Configuration
})

--// Start log processing service
Ui:BeginLogService()

--// Load hooks
local ActorCode = Files:MakeActorScript(Scripts, ChannelId)
Hook:LoadHooks(ActorCode, ChannelId)

--// Set communication channel
Ui:SetCommChannel(Channel)

--// Debug notification
if Configuration.DebugMode then
    Ui:ShowModal({
        "[DEBUG MODE ENABLED]",
        "",
        "Debug features active:",
        "- Hook inspection",
        "- Call interception",
        "- Argument modification",
        "- Return value spoofing",
        "- Stack trace analysis",
        "",
        "Use the Debug tab in the UI for bypass tools."
    })
end

print("Alpha Spy Loaded Successfully!")

return Modules
