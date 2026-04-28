type table = {
    [any]: any
}

--// Module
local Files = {
    UseWorkspace = false,
    Folder = "Alpha Spy",
    RepoUrl = nil,
    FolderStructure = {
        ["Alpha Spy"] = {
            "assets",
            "templates",
        }
    }
}

--// Services
local HttpService: HttpService

function Files:Init(Data)
    local FolderStructure = self.FolderStructure
    local Services = Data.Services
    HttpService = Services.HttpService
    
    --// Check if folders need to be created
    self:CheckFolders(FolderStructure)
end

function Files:PushConfig(Config: table)
    for Key, Value in next, Config do
        self[Key] = Value
    end
end

function Files:UrlFetch(Url: string): string
    --// Request data
    local Final = {
        Url = Url:gsub(" ", "%%20"),
        Method = 'GET'
    }
    
    --// Send HTTP request
    local Success, Response = pcall(request, Final)
    
    --// Error check
    if not Success then
        warn("[!] HTTP request error! Check console (F9)")
        warn("> Url:", Url)
        error(Response)
        return ""
    end
    
    local Body = Response.Body
    local StatusCode = Response.StatusCode
    
    --// Status code check
    if StatusCode == 404 then
        warn("[!] The file requested has moved or been deleted.")
        warn(" >", Url)
        return ""
    end
    
    return Body, Response
end

function Files:MakePath(Path: string)
    local Folder = self.Folder
    return `{Folder}/{Path}`
end

function Files:LoadCustomAsset(Path: string): string?
    if not getcustomasset then return end
    if not Path then return end
    
    --// Check content
    local Content = readfile(Path)
    if #Content <= 0 then return end
    
    --// Load custom AssetId
    local Success, AssetId = pcall(getcustomasset, Path)
    if not Success then return end
    if not AssetId or #AssetId <= 0 then return end
    
    return AssetId
end

function Files:GetFile(Path: string, CustomAsset: boolean?): string?
    local RepoUrl = self.RepoUrl
    local UseWorkspace = self.UseWorkspace
    local LocalPath = self:MakePath(Path)
    local Content = ""
    
    --// Check if files should be fetched from workspace
    if UseWorkspace then
        Content = readfile(LocalPath)
    else
        --// Download with HTTP request
        Content = self:UrlFetch(`{RepoUrl}/{Path}`)
    end
    
    --// Custom asset
    if CustomAsset then
        self:FileCheck(LocalPath, function()
            return Content
        end)
        return self:LoadCustomAsset(LocalPath)
    end
    
    return Content
end

function Files:GetTemplate(Name: string): string
    return self:GetFile(`templates/{Name}.lua`)
end

function Files:FileCheck(Path: string, Callback)
    if isfile(Path) then return end
    
    --// Create and write template
    local Template = Callback()
    writefile(Path, Template)
end

function Files:FolderCheck(Path: string)
    if isfolder(Path) then return end
    makefolder(Path)
end

function Files:CheckPath(Parent: string, Child: string)
    return Parent and `{Parent}/{Child}` or Child
end

function Files:CheckFolders(Structure: table, Path: string?)
    for ParentName, Name in next, Structure do
        --// Check parent folder
        if typeof(Name) == "table" then
            local NewPath = self:CheckPath(Path, ParentName)
            self:FolderCheck(NewPath)
            self:CheckFolders(Name, NewPath)
		else
            local FolderPath = self:CheckPath(Path, Name)
            self:FolderCheck(FolderPath)
        end

function Files:TemplateCheck(Path: string, TemplateName: string)
    self:FileCheck(Path, function()
        return self:GetTemplate(TemplateName)
    end)
end

function Files:GetAsset(Name: string, CustomAsset: boolean?): string
    return self:GetFile(`assets/{Name}`, CustomAsset)
end

function Files:GetModule(Name: string, TemplateName: string): string
    local Path = `{Name}.lua`
    
    --// File will be created from template if needed
    if TemplateName then
        self:TemplateCheck(Path, TemplateName)
        
        --// Check if it loaded successfully
        local Content = readfile(Path)
        local Success = loadstring(Content)
        if Success then return Content end
        
        return self:GetTemplate(TemplateName)
    end
    
    return self:GetFile(Path)
end

function Files:LoadLibraries(Scripts: table, ...): table
    local Modules = {}
    
    for Name, Content in next, Scripts do
        --// Base64 format
        local IsBase64 = typeof(Content) == "table" and Content[1] == "base64"
        Content = IsBase64 and Content[2] or Content
        
        --// Tables (already loaded modules)
        if typeof(Content) ~= "string" and not IsBase64 then
            Modules[Name] = Content
            continue
        end
        
        --// Decode Base64
        if IsBase64 then
            Content = crypt.base64decode(Content)
            Scripts[Name] = Content
        end
        
        --// Compile library
        local Closure, Error = loadstring(Content, Name)
        assert(Closure, `Failed to load {Name}: {Error}`)
        
        Modules[Name] = Closure(...)
    end
    
    return Modules
end

function Files:LoadModules(Modules: {}, Data: {})
    for Name, Module in next, Modules do
        local Init = Module.Init
        if not Init then continue end
        
        --// Invoke :Init function
        Module:Init(Data)
    end
end

function Files:CreateFont(Name: string, AssetId: string): string?
    if not AssetId then return end
    
    --// Custom font JSON
    local FileName = `assets/{Name}.json`
    local JsonPath = self:MakePath(FileName)
    
    local Data = {
        name = Name,
        faces = {
            {
                name = "Regular",
                weight = 400,
                style = "Normal",
                assetId = AssetId
            }
        }
    }
    
    --// Write JSON
    local Json = HttpService:JSONEncode(Data)
    writefile(JsonPath, Json)
    
    return JsonPath
end

function Files:CompileModule(Scripts): string
    local Out = "local Libraries = {"
    
    for Name, Content in Scripts do
        if typeof(Content) ~= "string" then continue end
        Out ..= `    {Name} = (function()\n{Content}\nend)(),\n`
    end
    
    Out ..= "}"
    return Out
end

function Files:MakeActorScript(Scripts, ChannelId: number): string
    local ActorCode = self:CompileModule(Scripts)
    
    ActorCode ..= [[
        local ExtraData = {
            IsActor = true
        }
    ]]
    
    ActorCode ..= `Libraries.Hook:BeginService(Libraries, ExtraData, {ChannelId})`
    
    return ActorCode
end

return Files
