--[[
    Alpha Spy - ReGui (Simplified UI Framework)
    A lightweight UI framework for Alpha Spy
--]]

local ReGui = {
    Themes = {},
    DefaultTheme = "DarkTheme"
}

--// Services
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

--// Check if mobile
function ReGui:IsMobileDevice(): boolean
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

--// Define theme
function ReGui:DefineTheme(Name: string, Config: table)
    self.Themes[Name] = Config
end

--// Create window
function ReGui:Window(Config: table)
    local Theme = self.Themes[Config.Theme] or self.Themes[self.DefaultTheme] or {}
    local Size = Config.Size or UDim2.fromOffset(700, 450)
    
    --// ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AlphaSpyUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    --// Try to parent to CoreGui
    pcall(function()
        ScreenGui.Parent = CoreGui
    end)
    
    if not ScreenGui.Parent then
        ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    --// Main frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = Size
    MainFrame.Position = UDim2.fromScale(0.5, 0.5)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    --// Title bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 30)
    TitleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    --// Title label
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(1, 0, 1, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = Config.Title or "Alpha Spy"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 14
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.Parent = TitleBar
    
    --// Draggable
    local Dragging = false
    local DragStart = nil
    local StartPos = nil
    
    TitleBar.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = true
            DragStart = Input.Position
            StartPos = MainFrame.Position
        end
    end)
    
    TitleBar.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(Input)
        if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
            local Delta = Input.Position - DragStart
            MainFrame.Position = UDim2.new(
                StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
            )
        end
    end)
    
    --// Content frame
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, 0, 1, -30)
    ContentFrame.Position = UDim2.new(0, 0, 0, 30)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame
    
    --// Window object
    local Window = {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        ContentFrame = ContentFrame,
        Theme = Theme
    }
    
    function Window:SetVisible(Visible: boolean)
        ScreenGui.Enabled = Visible
    end
    
    function Window:SetTheme(ThemeName: string)
        self.Theme = ReGui.Themes[ThemeName] or self.Theme
    end
    
    function Window:PopupModal(Config: table)
        local Modal = Instance.new("Frame")
        Modal.Name = "Modal"
        Modal.Size = UDim2.fromScale(0.8, 0.6)
        Modal.Position = UDim2.fromScale(0.5, 0.5)
        Modal.AnchorPoint = Vector2.new(0.5, 0.5)
        Modal.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        Modal.BorderSizePixel = 0
        Modal.ZIndex = 100
        Modal.Parent = MainFrame
        
        local ModalObj = {
            Frame = Modal
        }
        
        function ModalObj:ClosePopup()
            Modal:Destroy()
        end
        
        function ModalObj:Label(Data: table)
            local Label = Instance.new("TextLabel")
            Label.Name = "Label"
            Label.Size = UDim2.new(1, -20, 0, 50)
            Label.BackgroundTransparency = 1
            Label.Text = Data.Text or ""
            Label.TextColor3 = Color3.fromRGB(200, 200, 200)
            Label.TextSize = 12
            Label.TextWrapped = Data.TextWrapped or false
            Label.RichText = Data.RichText or false
            Label.Parent = Modal
            return Label
        end
        
        function ModalObj:Button(Data: table)
            local Button = Instance.new("TextButton")
            Button.Name = "Button"
            Button.Size = UDim2.new(0, 100, 0, 30)
            Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            Button.Text = Data.Text or "Button"
            Button.TextColor3 = Color3.fromRGB(255, 255, 255)
            Button.TextSize = 12
            Button.Parent = Modal
            
            if Data.Callback then
                Button.MouseButton1Click:Connect(Data.Callback)
            end
            
            return Button
        end
        
        function ModalObj:Separator()
            local Line = Instance.new("Frame")
            Line.Name = "Separator"
            Line.Size = UDim2.new(1, -20, 0, 1)
            Line.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            Line.BorderSizePixel = 0
            Line.Parent = Modal
        end
        
        function ModalObj:Row()
            local Row = Instance.new("Frame")
            Row.Name = "Row"
            Row.Size = UDim2.new(1, -20, 0, 35)
            Row.BackgroundTransparency = 1
            Row.Parent = Modal
            
            local RowObj = {
                Frame = Row
            }
            
            function RowObj:Button(Data: table)
                return ModalObj:Button(Data)
            end
            
            function RowObj:Expand()
                -- Placeholder
            end
            
            return RowObj
        end
        
        return ModalObj
    end
    
    function Window:List(Config: table)
        local List = Instance.new("Frame")
        List.Name = "List"
        List.Size = UDim2.new(1, 0, 1, 0)
        List.BackgroundTransparency = 1
        List.Parent = ContentFrame
        
        local ListLayout = Instance.new("UIListLayout")
        ListLayout.FillDirection = Config.FillDirection or Enum.FillDirection.Horizontal
        ListLayout.Padding = UDim.new(0, Config.UiPadding or 5)
        ListLayout.Parent = List
        
        local ListObj = {
            Frame = List
        }
        
        function ListObj:Canvas(Config: table)
            local Canvas = Instance.new("ScrollingFrame")
            Canvas.Name = "Canvas"
            Canvas.Size = Config.Size or UDim2.new(0.3, 0, 1, 0)
            Canvas.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            Canvas.BorderSizePixel = 0
            Canvas.ScrollBarThickness = 5
            Canvas.CanvasSize = UDim2.new(0, 0, 0, 0)
            Canvas.Parent = List
            
            local CanvasObj = {
                Frame = Canvas,
                Elements = {}
            }
            
            function CanvasObj:TreeNode(Data: table)
                local Node = Instance.new("TextButton")
                Node.Name = "TreeNode"
                Node.Size = UDim2.new(1, -10, 0, 25)
                Node.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                Node.Text = Data.Title or "Node"
                Node.TextColor3 = Color3.fromRGB(200, 200, 200)
                Node.TextSize = 12
                Node.TextXAlignment = Enum.TextXAlignment.Left
                Node.Parent = Canvas
                
                local NodeObj = {
                    Button = Node,
                    Children = {}
                }
                
                function NodeObj:Remove()
                    Node:Destroy()
                end
                
                return NodeObj
            end
            
            function CanvasObj:Selectable(Data: table)
                local Selectable = Instance.new("TextButton")
                Selectable.Name = "Selectable"
                Selectable.Size = UDim2.new(1, -20, 0, 20)
                Selectable.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                Selectable.Text = Data.Text or ""
                Selectable.TextColor3 = Color3.fromRGB(180, 180, 180)
                Selectable.TextSize = 11
                Selectable.TextXAlignment = Data.TextXAlignment or Enum.TextXAlignment.Center
                Selectable.Parent = Canvas
                
                if Data.Callback then
                    Selectable.MouseButton1Click:Connect(Data.Callback)
                end
                
                local SelectObj = {
                    Button = Selectable
                }
                
                function SelectObj:Remove()
                    Selectable:Destroy()
                end
                
                return SelectObj
            end
            
            function CanvasObj:ClearChildElements()
                for _, Child in ipairs(Canvas:GetChildren()) do
                    if Child:IsA("GuiObject") then
                        Child:Destroy()
                    end
                end
            end
            
            return CanvasObj
        end
        
        function ListObj:TabSelector(Config: table)
            local TabsFrame = Instance.new("Frame")
            TabsFrame.Name = "TabsFrame"
            TabsFrame.Size = Config.Size or UDim2.new(0.7, 0, 1, 0)
            TabsFrame.BackgroundTransparency = 1
            TabsFrame.Parent = List
            
            local TabButtons = Instance.new("Frame")
            TabButtons.Name = "TabButtons"
            TabButtons.Size = UDim2.new(1, 0, 0, 30)
            TabButtons.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            TabButtons.BorderSizePixel = 0
            TabButtons.Parent = TabsFrame
            
            local TabContent = Instance.new("Frame")
            TabContent.Name = "TabContent"
            TabContent.Size = UDim2.new(1, 0, 1, -30)
            TabContent.Position = UDim2.new(0, 0, 0, 30)
            TabContent.BackgroundTransparency = 1
            TabContent.Parent = TabsFrame
            
            local TabSelectorObj = {
                Frame = TabsFrame,
                TabButtons = TabButtons,
                TabContent = TabContent,
                Tabs = {},
                ActiveTab = nil
            }
            
            function TabSelectorObj:CreateTab(Data: table)
                local TabButton = Instance.new("TextButton")
                TabButton.Name = Data.Name or "Tab"
                TabButton.Size = UDim2.new(0, 80, 1, 0)
                TabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                TabButton.Text = Data.Name or "Tab"
                TabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
                TabButton.TextSize = 12
                TabButton.Parent = TabButtons
                
                local TabFrame = Instance.new("Frame")
                TabFrame.Name = Data.Name .. "Content"
                TabFrame.Size = UDim2.new(1, 0, 1, 0)
                TabFrame.BackgroundTransparency = 1
                TabFrame.Visible = false
                TabFrame.Parent = TabContent
                
                local TabObj = {
                    Button = TabButton,
                    Frame = TabFrame,
                    Name = Data.Name
                }
                
                TabButton.MouseButton1Click:Connect(function()
                    for _, Tab in ipairs(TabSelectorObj.Tabs) do
                        Tab.Frame.Visible = false
                        Tab.Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                    end
                    TabFrame.Visible = true
                    TabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    TabSelectorObj.ActiveTab = TabObj
                end)
                
                if Data.Focused ~= false then
                    TabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    TabFrame.Visible = true
                    TabSelectorObj.ActiveTab = TabObj
                end
                
                table.insert(TabSelectorObj.Tabs, TabObj)
                
                function TabObj:RemoveTab(Tab)
                    Tab.Frame:Destroy()
                    Tab.Button:Destroy()
                    for i, t in ipairs(TabSelectorObj.Tabs) do
                        if t == Tab then
                            table.remove(TabSelectorObj.Tabs, i)
                            break
                        end
                    end
                end
                
                function TabObj:CompareTabs(Tab1, Tab2)
                    return Tab1 == Tab2
                end
                
                --// Tab content methods
                function TabObj:Label(Data: table)
                    local Label = Instance.new("TextLabel")
                    Label.Name = "Label"
                    Label.Size = UDim2.new(1, -10, 0, 20)
                    Label.BackgroundTransparency = 1
                    Label.Text = Data.Text or ""
                    Label.TextColor3 = Data.TextColor3 or Color3.fromRGB(200, 200, 200)
                    Label.TextSize = 12
                    Label.TextWrapped = Data.TextWrapped or false
                    Label.RichText = Data.RichText or false
                    Label.Parent = TabFrame
                    return Label
                end
                
                function TabObj:Separator(Data: table)
                    local Line = Instance.new("Frame")
                    Line.Name = "Separator"
                    Line.Size = UDim2.new(1, -20, 0, 1)
                    Line.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    Line.BorderSizePixel = 0
                    Line.Parent = TabFrame
                    
                    if Data and Data.Text then
                        local Text = Instance.new("TextLabel")
                        Text.Name = "SeparatorText"
                        Text.Size = UDim2.new(0, 100, 0, 15)
                        Text.Position = UDim2.new(0, 5, 0, -7)
                        Text.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                        Text.Text = Data.Text
                        Text.TextColor3 = Color3.fromRGB(150, 150, 150)
                        Text.TextSize = 10
                        Text.Parent = Line
                    end
                    
                    return Line
                end
                
                function TabObj:Row(Config: table)
                    local Row = Instance.new("Frame")
                    Row.Name = "Row"
                    Row.Size = UDim2.new(1, -10, 0, 30)
                    Row.BackgroundTransparency = 1
                    Row.Parent = TabFrame
                    
                    local RowObj = {
                        Frame = Row,
                        Buttons = {}
                    }
                    
                    function RowObj:Button(Data: table)
                        local Button = Instance.new("TextButton")
                        Button.Name = "Button"
                        Button.Size = UDim2.new(0, 80, 0, 25)
                        Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                        Button.Text = Data.Text or "Button"
                        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                        Button.TextSize = 12
                        Button.Parent = Row
                        
                        if Data.Callback then
                            Button.MouseButton1Click:Connect(Data.Callback)
                        end
                        
                        table.insert(RowObj.Buttons, Button)
                        return Button
                    end
                    
                    function RowObj:Expand()
                        -- Layout buttons
                        local Padding = 5
                        local TotalWidth = Row.AbsoluteSize.X - Padding * 2
                        local ButtonWidth = (TotalWidth - (#RowObj.Buttons - 1) * Padding) / #RowObj.Buttons
                        
                        for i, Button in ipairs(RowObj.Buttons) do
                            Button.Size = UDim2.new(0, ButtonWidth, 0, 25)
                            Button.Position = UDim2.new(0, Padding + (i - 1) * (ButtonWidth + Padding), 0, 0)
                        end
                    end
                    
                    return RowObj
                end
                
                function TabObj:Checkbox(Data: table)
                    local CheckboxFrame = Instance.new("Frame")
                    CheckboxFrame.Name = "Checkbox"
                    CheckboxFrame.Size = UDim2.new(1, -10, 0, 25)
                    CheckboxFrame.BackgroundTransparency = 1
                    CheckboxFrame.Parent = TabFrame
                    
                    local CheckBox = Instance.new("TextButton")
                    CheckBox.Name = "CheckBox"
                    CheckBox.Size = UDim2.new(0, 20, 0, 20)
                    CheckBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    CheckBox.Text = Data.Value and "✓" or ""
                    CheckBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                    CheckBox.TextSize = 14
                    CheckBox.Parent = CheckboxFrame
                    
                    local Label = Instance.new("TextLabel")
                    Label.Name = "Label"
                    Label.Size = UDim2.new(1, -30, 1, 0)
                    Label.Position = UDim2.new(0, 25, 0, 0)
                    Label.BackgroundTransparency = 1
                    Label.Text = Data.Label or ""
                    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
                    Label.TextSize = 12
                    Label.TextXAlignment = Enum.TextXAlignment.Left
                    Label.Parent = CheckboxFrame
                    
                    local Checked = Data.Value or false
                    
                    CheckBox.MouseButton1Click:Connect(function()
                        Checked = not Checked
                        CheckBox.Text = Checked and "✓" or ""
                        if Data.Callback then
                            Data.Callback(Checked)
                        end
                    end)
                    
                    return CheckboxFrame
                end
                
                function TabObj:CodeEditor(Config: table)
                    local EditorFrame = Instance.new("Frame")
                    EditorFrame.Name = "CodeEditor"
                    EditorFrame.Size = Config.Fill and UDim2.new(1, -10, 1, -40) or UDim2.new(1, -10, 0, 200)
                    EditorFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                    EditorFrame.BorderSizePixel = 0
                    EditorFrame.Parent = TabFrame
                    
                    local TextBox = Instance.new("TextBox")
                    TextBox.Name = "TextBox"
                    TextBox.Size = UDim2.new(1, -10, 1, -10)
                    TextBox.Position = UDim2.new(0, 5, 0, 5)
                    TextBox.BackgroundTransparency = 1
                    TextBox.Text = Config.Text or ""
                    TextBox.TextColor3 = Color3.fromRGB(200, 200, 200)
                    TextBox.TextSize = Config.FontSize or 12
                    TextBox.TextXAlignment = Enum.TextXAlignment.Left
                    TextBox.TextYAlignment = Enum.TextYAlignment.Top
                    TextBox.ClearTextOnFocus = false
                    TextBox.MultiLine = true
                    TextBox.TextWrapped = false
                    TextBox.Parent = EditorFrame
                    
                    local EditorObj = {
                        Frame = EditorFrame,
                        TextBox = TextBox
                    }
                    
                    function EditorObj:GetText()
                        return TextBox.Text
                    end
                    
                    function EditorObj:SetText(Text: string)
                        TextBox.Text = Text
                    end
                    
                    return EditorObj
                end
                
                function TabObj:Console(Config: table)
                    local ConsoleFrame = Instance.new("ScrollingFrame")
                    ConsoleFrame.Name = "Console"
                    ConsoleFrame.Size = Config.Fill and UDim2.new(1, -10, 1, -40) or UDim2.new(1, -10, 0, 200)
                    ConsoleFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                    ConsoleFrame.BorderSizePixel = 0
                    ConsoleFrame.ScrollBarThickness = 5
                    ConsoleFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
                    ConsoleFrame.Parent = TabFrame
                    
                    local TextLabel = Instance.new("TextLabel")
                    TextLabel.Name = "ConsoleText"
                    TextLabel.Size = UDim2.new(1, -10, 0, 0)
                    TextLabel.AutomaticSize = Enum.AutomaticSize.Y
                    TextLabel.Position = UDim2.new(0, 5, 0, 5)
                    TextLabel.BackgroundTransparency = 1
                    TextLabel.Text = Config.Text or ""
                    TextLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
                    TextLabel.TextSize = 11
                    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                    TextLabel.TextYAlignment = Enum.TextYAlignment.Top
                    TextLabel.RichText = Config.RichText or false
                    TextLabel.Parent = ConsoleFrame
                    
                    local ConsoleObj = {
                        Frame = ConsoleFrame,
                        Label = TextLabel,
                        Lines = {}
                    }
                    
                    function ConsoleObj:AppendText(Text: string)
                        table.insert(self.Lines, Text)
                        
                        if Config.MaxLines and #self.Lines > Config.MaxLines then
                            table.remove(self.Lines, 1)
                        end
                        
                        TextLabel.Text = table.concat(self.Lines, "\n")
                        
                        if Config.AutoScroll then
                            ConsoleFrame.CanvasPosition = Vector2.new(0, ConsoleFrame.AbsoluteCanvasSize.Y)
                        end
                    end
                    
                    function ConsoleObj:Clear()
                        table.clear(self.Lines)
                        TextLabel.Text = ""
                    end
                    
                    function ConsoleObj:GetValue()
                        return TextLabel.Text
                    end
                    
                    return ConsoleObj
                end
                
                return TabObj
            end
            
            return TabSelectorObj
        end
        
        return ListObj
    end
    
    return Window
end

--// Default theme
ReGui:DefineTheme("DarkTheme", {
    BaseTheme = "DarkTheme",
    TextSize = 12
})

return ReGui
