-- FINALMY | Painel de treinamento para experiencia propria
-- Instale como LocalScript em StarterPlayer > StarterPlayerScripts.
-- Funciona somente com NPCs do seu jogo marcados com CollectionService tag "TrainingTarget".

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("FINALMY")
if old then old:Destroy() end

local config = {esp = true, aim = false, fov = 140, smooth = 0.16, names = true}
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.Parent = "FINALMY", false, playerGui

local panel = Instance.new("Frame")
panel.Size, panel.Position = UDim2.fromOffset(310, 330), UDim2.new(0, 30, 0.3, 0)
panel.BackgroundColor3, panel.BorderSizePixel, panel.Parent =
    Color3.fromRGB(17, 19, 27), 0, gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", panel)
stroke.Color, stroke.Thickness = Color3.fromRGB(0, 230, 190), 1.5

local header = Instance.new("TextLabel")
header.Size, header.Position = UDim2.new(1, -20, 0, 44), UDim2.fromOffset(12, 0)
header.BackgroundTransparency, header.Text = 1, "FINALMY  |  TRAINING"
header.TextColor3, header.TextXAlignment = Color3.fromRGB(0, 230, 190), Enum.TextXAlignment.Left
header.Font, header.TextSize, header.Parent = Enum.Font.GothamBold, 15, panel

local layout = Instance.new("UIListLayout")
layout.Padding, layout.SortOrder = UDim.new(0, 8), Enum.SortOrder.LayoutOrder
local holder = Instance.new("Frame")
holder.Position, holder.Size = UDim2.fromOffset(12, 52), UDim2.new(1, -24, 1, -64)
holder.BackgroundTransparency, holder.Parent = 1, panel
layout.Parent = holder

local function button(text, order)
    local b = Instance.new("TextButton")
    b.Size, b.LayoutOrder = UDim2.new(1, 0, 0, 34), order
    b.BackgroundColor3, b.BorderSizePixel = Color3.fromRGB(39, 43, 56), 0
    b.TextColor3, b.Font, b.TextSize = Color3.fromRGB(240, 243, 250), Enum.Font.GothamMedium, 12
    b.Text, b.Parent = text, holder
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    return b
end

local espB = button("", 1)
local aimB = button("", 2)
local fovB = button("", 3)
local smoothB = button("", 4)
local namesB = button("", 5)
local hideB = button("OCULTAR PAINEL  [RightShift]", 6)
local status = Instance.new("TextLabel")
status.Size, status.LayoutOrder = UDim2.new(1, 0, 0, 26), 7
status.BackgroundTransparency, status.Text = 1, "Pronto."
status.TextColor3, status.Font, status.TextSize =
    Color3.fromRGB(150, 160, 178), Enum.Font.Gotham, 10
status.Parent = holder

local circle = Instance.new("Frame")
circle.AnchorPoint, circle.BackgroundTransparency = Vector2.new(0.5, 0.5), 1
circle.Visible, circle.Parent = false, gui
Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
local circleStroke = Instance.new("UIStroke", circle)
circleStroke.Color, circleStroke.Thickness = Color3.fromRGB(0, 230, 190), 1.5

local function refresh()
    espB.Text = "NPC ESP: " .. (config.esp and "ON" or "OFF")
    aimB.Text = "NPC AIM ASSIST: " .. (config.aim and "ON" or "OFF")
    fovB.Text = ("FOV: %d  (CLIQUE PARA ALTERAR)"):format(config.fov)
    smoothB.Text = ("SUAVIDADE: %.2f  (CLIQUE PARA ALTERAR)"):format(config.smooth)
    namesB.Text = "NOMES E DISTANCIA: " .. (config.names and "ON" or "OFF")
    circle.Visible = config.aim
    circle.Size = UDim2.fromOffset(config.fov * 2, config.fov * 2)
end

espB.Activated:Connect(function() config.esp = not config.esp; refresh() end)
aimB.Activated:Connect(function() config.aim = not config.aim; refresh() end)
fovB.Activated:Connect(function()
    config.fov = config.fov + 25
    if config.fov > 300 then config.fov = 75 end
    refresh()
end)
smoothB.Activated:Connect(function()
    config.smooth = config.smooth + 0.05
    if config.smooth > 0.50 then config.smooth = 0.05 end
    refresh()
end)
namesB.Activated:Connect(function() config.names = not config.names; refresh() end)
hideB.Activated:Connect(function() panel.Visible = false end)
UIS.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightShift and gui.Parent then
        panel.Visible = not panel.Visible
    end
end)

-- Arrastar painel pelo titulo
local dragging, dragStart, startPos = false, nil, nil
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, input.Position, panel.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

local espObjects = {}
local function clearESP(model)
    local obj = espObjects[model]
    if obj then obj.highlight:Destroy(); obj.billboard:Destroy(); espObjects[model] = nil end
end
local function addESP(model)
    if espObjects[model] or not model:IsA("Model") then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local part = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
    if not hum or not part then return end
    local h = Instance.new("Highlight")
    h.Adornee, h.FillColor, h.OutlineColor = model, Color3.fromRGB(0, 210, 180), Color3.fromRGB(220, 255, 250)
    h.FillTransparency, h.DepthMode, h.Parent = 0.8, Enum.HighlightDepthMode.Occluded, gui
    local bb = Instance.new("BillboardGui")
    bb.Adornee, bb.Size, bb.StudsOffset, bb.AlwaysOnTop, bb.Parent =
        part, UDim2.fromOffset(190, 32), Vector3.new(0, 2.7, 0), false, gui
    local label = Instance.new("TextLabel")
    label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
    label.TextColor3, label.TextStrokeTransparency = Color3.fromRGB(225, 255, 250), 0.25
    label.Font, label.TextSize, label.Parent = Enum.Font.GothamBold, 11, bb
    espObjects[model] = {highlight = h, billboard = bb, label = label}
end

local function targets()
    local list = {}
    for _, model in ipairs(CollectionService:GetTagged("TrainingTarget")) do
        if model:IsA("Model") and model:IsDescendantOf(workspace) then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local part = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and part then table.insert(list, {model = model, hum = hum, part = part}) end
        end
    end
    return list
end

local aiming = false
UIS.InputBegan:Connect(function(input, processed)
    if not processed and input.UserInputType == Enum.UserInputType.MouseButton2 then aiming = true end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then aiming = false end
end)

local connection
connection = RunService.RenderStepped:Connect(function()
    if not gui.Parent then
        connection:Disconnect()
        for model in pairs(espObjects) do clearESP(model) end
        return
    end
    local cam = workspace.CurrentCamera
    if not cam then return end
    circle.Position = UDim2.fromOffset(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local list, active = targets(), {}
    for _, t in ipairs(list) do
        active[t.model] = true
        if config.esp then
            addESP(t.model)
            local obj = espObjects[t.model]
            if obj then
                local text = t.model.Name
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local targetRoot = t.model:FindFirstChild("HumanoidRootPart") or t.part
                if config.names then
                    if root then text ..= (" | %dm"):format((root.Position - targetRoot.Position).Magnitude) end
                    text ..= (" | HP %d"):format(t.hum.Health)
                else
                    text = ""
                end
                obj.label.Text, obj.billboard.Enabled = text, config.names
            end
        else
            clearESP(t.model)
        end
    end
    for model in pairs(espObjects) do if not active[model] then clearESP(model) end end

    -- Assistencia de mira exclusivamente nos NPCs TrainingTarget do proprio projeto.
    if config.aim and aiming then
        local center, best, bestDist = cam.ViewportSize / 2, nil, config.fov
        for _, t in ipairs(list) do
            local p, visible = cam:WorldToViewportPoint(t.part.Position)
            if visible and p.Z > 0 then
                local d = (Vector2.new(p.X, p.Y) - center).Magnitude
                if d < bestDist then best, bestDist = t.part, d end
            end
        end
        if best then
            local desired = CFrame.lookAt(cam.CFrame.Position, best.Position)
            cam.CFrame = cam.CFrame:Lerp(desired, config.smooth)
        end
    end
    status.Text = ("NPCs de treino detectados: %d"):format(#list)
end)

refresh()
print("[FINALMY] UI carregada. RightShift oculta/reabre o painel.")
