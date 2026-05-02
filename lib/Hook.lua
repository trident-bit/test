local Hook = {
    OriginalNamecall = nil,
    OriginalIndex = nil,
    PreviousFunctions = {},
    DefaultConfig = {
        FunctionPatches = true
    }
}

type table = {
    [any]: any
}

type MetaFunc = (Instance, ...any) -> ...any
type UnkFunc = (...any) -> ...any

--// Modules
local Modules
local Process
local Configuration
local Config
local Communication

local ExeENV = getfenv(1)

function Hook:Init(Data)
    Modules = Data.Modules
    Process = Modules.Process
    Communication = Modules.Communication or Communication
    Config = Modules.Config or Config
    Configuration = Modules.Configuration or Configuration
end

--// Hook middleman function
local HookMiddle = newcclosure(function(OriginalFunc, Callback, AlwaysTable: boolean?, ...)
    --// Invoke callback
    local ReturnValues = Callback(...)
    
    if ReturnValues then
        --// Unpack
        if not AlwaysTable then
            return Process:Unpack(ReturnValues)
        end
        
        --// Return packed
        return ReturnValues
    end
    
    --// Return packed original
    if AlwaysTable then
        return {OriginalFunc(...)}
    end
    
    --// Unpacked
    return OriginalFunc(...)
end)

local function Merge(Base: table, New: table)
    for Key, Value in next, New do
        Base[Key] = Value
    end
end

function Hook:Index(Object: Instance, Key: string)
    local identity = getthreadidentity()
    setthreadidentity(8)
    local returned = Object[Key]
    setthreadidentity(identity)
    return returned
end

function Hook:PushConfig(Overwrites)
    Merge(self, Overwrites)
end

--// getrawmetatable replacement
function Hook:ReplaceMetaMethod(Object: Instance, Call: string, Callback: MetaFunc): MetaFunc
    local Metatable = getrawmetatable(Object)
    local OriginalFunc = clonefunction(Metatable[Call])
    
    --// Replace function
    setreadonly(Metatable, false)
    Metatable[Call] = newcclosure(function(...)
        return HookMiddle(OriginalFunc, Callback, false, ...)
    end)
    setreadonly(Metatable, true)
    
    return OriginalFunc
end

--// hookfunction
function Hook:HookFunction(Func: UnkFunc, Callback: UnkFunc)
    local OriginalFunc
    local WrappedCallback = newcclosure(Callback)
    
    OriginalFunc = clonefunction(hookfunction(Func, function(...)
        return HookMiddle(OriginalFunc, WrappedCallback, false, ...)
    end))
    
    return OriginalFunc
end

--// hookmetamethod
function Hook:HookMetaCall(Object: Instance, Call: string, Callback: MetaFunc): MetaFunc
    local Metatable = getrawmetatable(Object)
    local Unhooked
    
    Unhooked = self:HookFunction(Metatable[Call], function(...)
        return HookMiddle(Unhooked, Callback, true, ...)
    end)
    
    return Unhooked
end

function Hook:HookMetaMethod(Object: Instance, Call: string, Callback: MetaFunc): MetaFunc
    local Func = newcclosure(Callback)
    
    --// getrawmetatable
    if Config and Config.ReplaceMetaCallFunc then
        return self:ReplaceMetaMethod(Object, Call, Func)
    end
    
    --// hookmetamethod
    return self:HookMetaCall(Object, Call, Func)
end

--// Function patches for detection prevention
function Hook:PatchFunctions()
    --// Check if disabled
    if Config and Config.NoFunctionPatching then return end
    
    local Patches = {
        --// Error detection patch
        [pcall] = function(OldFunc, Func, ...)
            local Response = {OldFunc(Func, ...)}
            local Success, Error = Response[1], Response[2]
            local IsC = iscclosure(Func)
            
            --// Patch c-closure error detection
            if Success == false and IsC then
                local NewError = Process:CleanCError(Error)
                Response[2] = NewError
            end
            
            --// Stack overflow detection patch
            if Success == false and not IsC and Error:find("C stack overflow") then
                local TraceTable = Error:split(":")
                local Caller, Line = TraceTable[1], TraceTable[2]
                local Count = Process:CountMatches(Error, Caller)
                
                if Count == 196 then
                    Communication:ConsolePrint(`C stack overflow patched, count: {Count}`)
                    Response[2] = Error:gsub(`{Caller}:{Line}: `, "", 196)
                end
            end
            
            return Process:Unpack(Response)
        end
    }
    
    --// Apply patches
    for Func, Patch in pairs(Patches) do
        self:HookFunction(Func, Patch)
    end
end

function Hook:BeginHooks()
    self:PatchFunctions()
    
    --// Hook __namecall
    self.OriginalNamecall = self:HookMetaMethod(game, "__namecall", function(...)
        return self:NamecallHook(...)
    end)
    
    --// Hook __index
    self.OriginalIndex = self:HookMetaMethod(game, "__index", function(...)
        return self:IndexHook(...)
    end)
end

function Hook:GetOriginalFunc(Func)
    return self.PreviousFunctions[Func] or Func
end

function Hook:NamecallHook(...)
    local Method = getnamecallmethod()
    local Remote = ...
    
    -- Check if this is a remote we should log
    if Process:RemoteAllowed(Remote, "Send", Method) then
        local Args = {...}
        table.remove(Args, 1) -- Remove 'self' argument
        
        local Data = {
            Method = Method,
            MetaMethod = "__namecall",
            TransferType = "Send",
            OriginalFunc = self.OriginalNamecall
        }
        
        local Result = Process:ProcessRemote(Data, Remote, select(2, ...))
        if Result then
            return Process:Unpack(Result)
        end
    end
    
    return self.OriginalNamecall(...)
end

function Hook:IndexHook(Object, Property)
    if Process:RemoteAllowed(Object, "Receive", Property) then
        local Original = self.OriginalIndex(Object, Property)
       
        if typeof(Original) == "RBXScriptSignal" then
            local proxy = newproxy(true)
            local mt = getmetatable(proxy)
            mt.__index = function(_, Index)
                if Index == "Connect" or Index "connect" then
                    return function(_, Callback)
                        return Original:Connect(function(...)
                            local Data = {
                                Method = Property,
                                MetaMethod = "__index",
                                TransferType = "Receive",
                                IsReceive = true
                            }
                            Process:ProcessRemote(Data, Object, ...)
                            return Callback(...)
                        end)
                    end
                end
                return Original[Index]
            end
            return proxy
        end
    end
    return self.OriginalIndex(Object, Property)
end

function Hook:LoadHooks(ActorCode: string, ChannelId: number)
    if typeof(run_on_actor) == "function" then
        local success, err = pcall(function()
            run_on_actor(ActorCode)
        end)
        if success then return end
        warn("[Alpha Spy] run_on_actor failed:", err)
    end
    
    local Closure, CompileErr = loadstring(ActorCode, "AlphaSpyActor")
    if not Closure then
        warn("[Alpha Spy] Actor code failed to compile:", CompileErr)
        return
    end
    
    local success, runErr = pcall(Closure)
    if not success then
        warn("[Alpha Spy] Actor runtime error:", runErr)
    end
end


function Hook:BeginService(Libraries, ExtraData, Args)
    local ChannelId = Args[1]
    
    Modules = Libraries
    Process = Libraries.Process
    Communication = Libraries.Communication or Communication
    Config = Libraries.Config or Config
    
    if Communication and ChannelId then
        Communication:SetChannel(ChannelId)
    end
    
    self:BeginHooks()
    
    print("[Alpha Spy] Actor hooks started on channel", ChannelId)
end

return Hook
