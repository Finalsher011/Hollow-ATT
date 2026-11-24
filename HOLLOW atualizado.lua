-- HOLLOW.lua | LocalScript | Roblox Studio
-- Uso: StarterPlayer > StarterPlayerScripts
-- Marque NPCs de treino com a tag "TrainingTarget" usando CollectionService.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local config = {
    esp = true,
    aim_assist = false,
    fov = 150,
    smoothing = 0.15,
    aim_key = Enum.UserInputType.MouseButton2,
}

local aiming = false
local gui = Instance.new("ScreenGui")
gui.Name = "HOLLOW"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(290, 300)
panel.Position = UDim2.new(0, 35, 0.3, 0)
panel.BackgroundColor3 = Color3.fromRGB(17, 18, 27)
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(0, 220, 190)
outline.Thickness = 1.4
outline.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -18, 0, 42)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "HOLLOW  |  TRAINING"
title.TextColor3 = Color3.fromRGB(0, 230, 195)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Parent = panel

local function make_button(label, y)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -24, 0, 34)
    b.Position = UDim2.fromOffset(12, y)
    b.BackgroundColor3 = Color3.fromRGB(39, 42, 55)
    b.TextColor3 = Color3.fromRGB(240, 242, 250)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    b.Text = label
    b.AutoButtonColor = true
    b.Parent = panel
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local esp_button = make_button("", 52)
local aim_button = make_button("", 94)
local fov_button = make_button("", 136)
local smooth_button = make_button("", 178)
local close_button = make_button("HIDE MENU", 220)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -24, 0, 24)
status.Position = UDim2.fromOffset(12, 264)
status.BackgroundTransparency = 1
status.Text = "RMB: hold to aim at tagged training NPCs"
status.TextColor3 = Color3.fromRGB(160, 165, 180)
status.Font = Enum.Font.Gotham
status.TextSize = 9
status.Parent = panel

local fov_circle = Instance.new("Frame")
fov_circle.Name = "FOV"
fov_circle.AnchorPoint = Vector2.new(0.5, 0.5)
fov_circle.BackgroundTransparency = 1
fov_circle.Visible = false
fov_circle.Parent = gui
Instance.new("UICorner", fov_circle).CornerRadius = UDim.new(1, 0)
local fov_stroke = Instance.new("UIStroke")
fov_stroke.Color = Color3.fromRGB(0, 230, 195)
fov_stroke.Thickness = 1.5
fov_stroke.Transparency = 0.15
fov_stroke.Parent = fov_circle

local function refresh_ui()
    esp_button.Text = "NPC ESP: " .. (config.esp and "ON" or "OFF")
    aim_button.Text = "NPC AIM ASSIST: " .. (config.aim_assist and "ON" or "OFF")
    fov_button.Text = ("AIM FOV: %d  (click to cycle)"):format(config.fov)
    smooth_button.Text = ("SMOOTHING: %.2f  (click to cycle)"):format(config.smoothing)
    fov_circle.Visible = config.aim_assist
    fov_circle.Size = UDim2.fromOffset(config.fov * 2, config.fov * 2)
end

local function update_circle()
    local viewport = camera.ViewportSize
    fov_circle.Position = UDim2.fromOffset(viewport.X / 2, viewport.Y / 2)
end

esp_button.Activated:Connect(function()
    config.esp = not config.esp
    refresh_ui()
end)

aim_button.Activated:Connect(function()
    config.aim_assist = not config.aim_assist
    refresh_ui()
end)

fov_button.Activated:Connect(function()
    config.fov = config.fov + 25
    if config.fov > 300 then config.fov = 75 end
    refresh_ui()
end)

smooth_button.Activated:Connect(function()
    config.smoothing = config.smoothing + 0.05
    if config.smoothing > 0.50 then config.smoothing = 0.05 end
    refresh_ui()
end)

close_button.Activated:Connect(function()
    panel.Visible = false
end)

-- Arrastar pelo cabeçalho
local dragging, drag_input, drag_start, start_pos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        drag_start = input.Position
        start_pos = panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - drag_start
        panel.Position = UDim2.new(
            start_pos.X.Scale, start_pos.X.Offset + delta.X,
            start_pos.Y.Scale, start_pos.Y.Offset + delta.Y
        )
    end
end)

local esp_by_model = {}

local function remove_esp(model)
    local item = esp_by_model[model]
    if item then
        if item.highlight then item.highlight:Destroy() end
        if item.billboard then item.billboard:Destroy() end
        esp_by_model[model] = nil
    end
end

local function add_esp(model)
    if esp_by_model[model] or not model:IsA("Model") then return end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local adornee = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not adornee then return end

    local highlight = Instance.new("Highlight")
    highlight.Adornee = model
    highlight.FillColor = Color3.fromRGB(0, 210, 180)
    highlight.OutlineColor = Color3.fromRGB(220, 255, 250)
    highlight.FillTransparency = 0.78
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = gui

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = adornee
    billboard.Size = UDim2.fromOffset(190, 42)
    billboard.StudsOffset = Vector3.new(0, 2.6, 0)
    billboard.AlwaysOnTop = false
    billboard.Parent = gui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(220, 255, 250)
    label.TextStrokeTransparency = 0.25
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.Parent = billboard

    esp_by_model[model] = {
        highlight = highlight,
        billboard = billboard,
        label = label,
    }
end

local function get_targets()
    local result = {}
    for _, model in ipairs(CollectionService:GetTagged("TrainingTarget")) do
        if model:IsA("Model") and model:IsDescendantOf(workspace) then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local part = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and part then
                table.insert(result, {model = model, humanoid = humanoid, part = part})
            end
        end
    end
    return result
end

local function closest_target()
    local center = camera.ViewportSize / 2
    local best, best_distance = nil, config.fov
    for _, target in ipairs(get_targets()) do
        local screen, visible = camera:WorldToViewportPoint(target.part.Position)
        if visible and screen.Z > 0 then
            local distance = (Vector2.new(screen.X, screen.Y) - center).Magnitude
            if distance < best_distance then
                best, best_distance = target.part, distance
            end
        end
    end
    return best
end

UIS.InputBegan:Connect(function(input, processed)
    if not processed and input.UserInputType == config.aim_key then
        aiming = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == config.aim_key then
        aiming = false
    end
end)

RunService.RenderStepped:Connect(function()
    update_circle()

    local targets = get_targets()
    local active = {}
    for _, target in ipairs(targets) do
        active[target.model] = true
        if config.esp then
            add_esp(target.model)
            local item = esp_by_model[target.model]
            if item then
                local character = player.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                local target_root = target.model:FindFirstChild("HumanoidRootPart") or target.part
                local distance = root and (root.Position - target_root.Position).Magnitude or 0
                item.label.Text = string.format("%s  |  %dm  |  HP %d",
                    target.model.Name, math.floor(distance), math.floor(target.humanoid.Health))
            end
        else
            remove_esp(target.model)
        end
    end

    for model in pairs(esp_by_model) do
        if not active[model] then remove_esp(model) end
    end

    if config.aim_assist and aiming then
        local target = closest_target()
        if target then
            local desired = CFrame.lookAt(camera.CFrame.Position, target.Position)
            camera.CFrame = camera.CFrame:Lerp(desired, config.smoothing)
        end
    end
end)

refresh_ui()
print("[HOLLOW] Training interface loaded. Tag NPCs with TrainingTarget.")
