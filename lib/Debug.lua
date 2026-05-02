--[[
    Alpha Spy - Debug Module
    Provides tools for bypass development and call interception
--]]

type table = {
    [any]: any
}

local Debug = {
    InterceptQueue = {},
    ModifiedCalls = {},
    CallHistory = {},
    StackTraces = {},
    Breakpoints = {},
    HookInfo = {},
    Stats = {
        TotalCalls = 0,
        BlockedCalls = 0,
        ModifiedCalls = 0,
        CallsPerRemote = {}
    }
}

--// Modules
local Process
local Hook
local Communication
local Flags

--// Services
local HttpService

function Debug:Init(Data)
    local Modules = Data.Modules
    local Services = Data.Services
    
    Process = Modules.Process
    Hook = Modules.Hook
    Communication = Modules.Communication
    Flags = Modules.Flags
    HttpService = Services.HttpService
    
    print("[Debug] Module initialized")
end

--// Call Interception
function Debug:InterceptCall(Remote, Method, Args, CallerInfo)
    if not Flags:GetFlagValue("DebugIntercept") then return nil end
    
    local InterceptData = {
        Remote = Remote,
        Method = Method,
        OriginalArgs = Args,
        CallerInfo = CallerInfo,
        Timestamp = tick(),
        Id = HttpService:GenerateGUID(false)
    }
    
    table.insert(self.InterceptQueue, InterceptData)
    
    --// Check if modification is enabled
    if Flags:GetFlagValue("DebugModifyArgs") then
        local ModifiedArgs = self:ModifyArguments(InterceptData)
        if ModifiedArgs then
            self.Stats.ModifiedCalls += 1
            return ModifiedArgs
        end
    end
    
    return nil
end

function Debug:ModifyArguments(InterceptData)
    local Remote = InterceptData.Remote
    local Method = InterceptData.Method
    local Args = InterceptData.OriginalArgs
    
    --// Check for registered modifiers
    local Modifier = self.ModifiedCalls[Remote]
    if Modifier then
        if Modifier.Method == Method then
            local Success, Result = pcall(function()
                return Modifier.Callback(Args)
            end)
            
            if Success then
                print(`[Debug] Modified args for {Remote.Name}.{Method}`)
                return Result
            else
                warn(`[Debug] Modifier error: {Result}`)
            end
        end
    end
    
    return nil
end

function Debug:RegisterModifier(Remote, Method, Callback)
    self.ModifiedCalls[Remote] = {
        Method = Method,
        Callback = Callback
    }
    print(`[Debug] Registered modifier for {Remote.Name}.{Method}`)
end

function Debug:RemoveModifier(Remote)
    self.ModifiedCalls[Remote] = nil
    print(`[Debug] Removed modifier for {Remote.Name}`)
end

--// Call History & Logging
function Debug:LogCall(Data)
    if not Flags:GetFlagValue("DebugLogStack") then return end
    
    local CallData = {
        Remote = Data.Remote,
        Method = Data.Method,
        Args = Process:DeepCloneTable(Data.Args),
        Timestamp = Data.Timestamp,
        StackTrace = debug.traceback(),
        CallerScript = Data.CallingScript,
        CallerFunction = Data.CallingFunction
    }
    
    table.insert(self.CallHistory, CallData)
    
    --// Limit history
    if #self.CallHistory > 1000 then
        table.remove(self.CallHistory, 1)
    end
    
    --// Update stats
    self.Stats.TotalCalls += 1
    
    local RemoteName = tostring(Data.Remote)
    self.Stats.CallsPerRemote[RemoteName] = (self.Stats.CallsPerRemote[RemoteName] or 0) + 1
end

function Debug:GetCallHistory(RemoteFilter: Instance?): table
    if not RemoteFilter then
        return self.CallHistory
    end
    
    local Filtered = {}
    for _, Call in self.CallHistory do
        if Call.Remote == RemoteFilter then
            table.insert(Filtered, Call)
        end
    end
    
    return Filtered
end

function Debug:ClearHistory()
    table.clear(self.CallHistory)
    print("[Debug] Call history cleared")
end

--// Breakpoint System
function Debug:SetBreakpoint(Remote, Method, Condition)
    if not self.Breakpoints[Remote] then
        self.Breakpoints[Remote] = {}
    end
    
    self.Breakpoints[Remote][Method] = {
        Condition = Condition or function() return true end,
        HitCount = 0
    }
    
    print(`[Debug] Breakpoint set for {Remote.Name}.{Method}`)
end

function Debug:RemoveBreakpoint(Remote, Method)
    if self.Breakpoints[Remote] then
        self.Breakpoints[Remote][Method] = nil
        print(`[Debug] Breakpoint removed for {Remote.Name}.{Method}`)
    end
end

function Debug:CheckBreakpoint(Remote, Method, Args)
    local RemoteBreakpoints = self.Breakpoints[Remote]
    if not RemoteBreakpoints then return false end
    
    local Breakpoint = RemoteBreakpoints[Method]
    if not Breakpoint then return false end
    
    Breakpoint.HitCount += 1
    
    local Success, ShouldBreak = pcall(function()
        return Breakpoint.Condition(Args)
    end)
    
    if Success and ShouldBreak then
        print(`[Debug] BREAKPOINT HIT: {Remote.Name}.{Method} (Hit #{Breakpoint.HitCount})`)
        return true
    end
    
    return false
end

--// Hook Inspection
function Debug:InspectHook(Remote, Method)
    local Info = {
        Remote = Remote,
        Method = Method,
        IsHooked = false,
        HookType = nil,
        OriginalFunction = nil
    }
    
    --// Check if hooked via our system
    if Hook.hookedRemotes and Hook.hookedRemotes[Remote] then
        Info.IsHooked = true
        Info.HookType = "AlphaSpy"
    end
    
    --// Try to get original function info
    local Success, Func = pcall(function()
        return Remote[Method]
    end)
    
    if Success then
        Info.OriginalFunction = Func
        Info.FunctionInfo = debug.info(Func, "nS")
    end
    
    return Info
end

function Debug:GetAllHookInfo(): table
    local Info = {}
    
    for Remote, Methods in Hook.hookedRemotes or {} do
        for Method, _ in Methods do
            table.insert(Info, self:InspectHook(Remote, Method))
        end
    end
    
    return Info
end

--// Bypass Utilities
function Debug:GenerateBypassScript(Remote, Method, Pattern): string
    local Script = `-- Generated bypass script for {Remote.Name}.{Method}\n`
    Script ..= `local Remote = game:GetService("ReplicatedStorage"):WaitForChild("{Remote.Name}")\n\n`
    
    if Pattern == "block" then
        Script ..= `-- Block pattern\n`
        Script ..= `local Old; Old = hookfunction(Remote.{Method}, function(...)\n`
        Script ..= `    print("[Blocked]", ...)`
        Script ..= `    return -- Block the call\n`
        Script ..= `end)\n`
    elseif Pattern == "spoof" then
        Script ..= `-- Spoof pattern\n`
        Script ..= `local Old; Old = hookfunction(Remote.{Method}, function(...)\n`
        Script ..= `    print("[Spoofed]", ...)`
        Script ..= `    return "Spoofed Return Value"\n`
        Script ..= `end)\n`
    elseif Pattern == "log" then
        Script ..= `-- Log pattern\n`
        Script ..= `local Old; Old = hookfunction(Remote.{Method}, function(...)\n`
        Script ..= `    print("[Logged]", ...)`
        Script ..= `    return Old(...)\n`
        Script ..= `end)\n`
    end
    
    return Script
end

function Debug:DumpRemoteInfo(Remote): table
    local Info = {
        Name = Remote.Name,
        ClassName = Remote.ClassName,
        Parent = tostring(Remote.Parent),
        FullName = Remote:GetFullName(),
        DebugId = Remote:GetDebugId(),
        Attributes = {},
        Methods = {}
    }
    
    for AttrName, AttrValue in pairs(Remote:GetAttributes()) do
		Info.Attributes[AttrName] = AttrValue
	end
    
    local ClassData = Process.RemoteClassData[Remote.ClassName]
    if ClassData then
        Info.Methods.Send = ClassData.Send
        Info.Methods.Receive = ClassData.Receive
    end
    
    return Info
end

function Debug:GetStats(): table
    return Process:DeepCloneTable(self.Stats)
end

function Debug:ResetStats()
    self.Stats = {
        TotalCalls = 0,
        BlockedCalls = 0,
        ModifiedCalls = 0,
        CallsPerRemote = {}
    }
    print("[Debug] Stats reset")
end

--// Export for UI
function Debug:ExportCallHistory(): string
    local Export = {}
    
    for _, Call in self.CallHistory do
        table.insert(Export, {
            Remote = tostring(Call.Remote),
            Method = Call.Method,
            Timestamp = Call.Timestamp,
            Args = Call.Args
        })
    end
    
    return HttpService:JSONEncode(Export)
end

--// Real-time monitoring
function Debug:StartMonitoring(Interval: number)
    Interval = Interval or 1
    
    coroutine.wrap(function()
        while true do
            wait(Interval)
            
            local Stats = self:GetStats()
            print(`[Debug Monitor] Calls: {Stats.TotalCalls} | Modified: {Stats.ModifiedCalls}`)
        end
    end)()
end

return Debug
