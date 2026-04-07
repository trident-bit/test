--[[
    Alpha Spy - Return Spoofs Configuration
    
    This file allows you to spoof return values from RemoteFunctions.
    
    Format:
    [RemoteInstance] = {
        Method = "InvokeServer",
        Return = {Value1, Value2, ...}
    }
    
    You can also use a function for dynamic returns:
    [RemoteInstance] = {
        Method = "InvokeServer", 
        Return = function(OriginalFunc, ...)
            -- Modify or block arguments
            return {"Your", "Return", "Values"}
        end
    }
--]]

return {
    --// Example: Block a remote
    -- [game.ReplicatedStorage.Remotes.Example] = {
    --     Method = "InvokeServer",
    --     Return = {} -- Returns nothing (blocks the call)
    -- }
    
    --// Example: Spoof return value
    -- [game.ReplicatedStorage.Remotes.GetData] = {
    --     Method = "InvokeServer",
    --     Return = {"Spoofed Data!"}
    -- }
    
    --// Example: Dynamic return with function
    -- [game.ReplicatedStorage.Remotes.CheckAdmin] = {
    --     Method = "InvokeServer",
    --     Return = function(OriginalFunc, ...)
    --         print("Intercepted admin check!")
    --         return {true} -- Always return true for admin
    --     end
    -- }
}
