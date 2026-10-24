local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = workspace
local LocalPlayer = Players.LocalPlayer
local DrawingAPI = Drawing

local Config = {
    Font = Enum.Font.RobotoCondensed,
    TextSize = 20,
    RenderRate = 60,
    Rainbow = false,

    ESPStyle = "Highlight",

    FillTransparency = 0.5,
    OutlineTransparency = 0,
    OutlineColor = Color3.fromRGB(255, 255, 255),
    MatchColors = true,
    DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,

    AdornmentColor = Color3.fromRGB(255, 255, 255),
    AdornmentTransparency = 0.5,
    UseElementColorForAdornment = true,

    Tracers = true,
    TracerAnchor = "Bottom",
    TracerThickness = 2,
    TracerTransparency = 0,

    Arrows = true,
    ArrowStyle = "Image",
    ArrowRadius = 0.35,
    ArrowSize = 50,

    TriangleSize = 18,
    TriangleThickness = 1,
    TriangleFilled = true,
    TriangleTransparency = 0,
    TriangleAntiAliasing = false,

    ShowName = true,
    ShowHealth = false,
    ShowDistance = false,
    DistanceSuffix = " studs",
    MaxDistance = 5000,

    TeamCheck = false,
    VisibleCheck = false,
    AliveCheck = true,
}

local unloaded = false
local elements = {}
local hue = 0
local rainbowColor = Color3.new(1, 1, 1)
local camera = Workspace.CurrentCamera
local _uid = 0

local Anchors = {
    Top = Vector2.new(0.5, 0),
    Bottom = Vector2.new(0.5, 1),
    Center = Vector2.new(0.5, 0.5),
    TopLeft = Vector2.new(0, 0),
    TopRight = Vector2.new(1, 0),
    BottomLeft = Vector2.new(0, 1),
    BottomRight = Vector2.new(1, 1),
    Left = Vector2.new(0, 0.5),
    Right = Vector2.new(1, 0.5),
}

local function newId()
    _uid = _uid + 1
    return "sl_" .. _uid
end

local host
if gethui then
    local ok, h = pcall(gethui)
    if ok and h then host = h end
end
host = host or game:GetService("CoreGui")

local Gui = Instance.new("ScreenGui")
Gui.Name = "sl_esp_" .. tostring(math.random(100000, 999999))
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 2147483647
Gui.Parent = host

local AdornFolder = Instance.new("Folder")
AdornFolder.Name = "sl_adorn_" .. tostring(math.random(100000, 999999))
AdornFolder.Parent = Workspace

local function getPosition(obj)
    if obj:IsA("Model") then
        local ok, pivot = pcall(function() return obj:GetPivot() end)
        if ok then return pivot.Position end
        local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if pp then return pp.Position end
        return Vector3.zero
    end
    return obj.Position
end

local function getSize(obj)
    if obj:IsA("Model") then
        local ok, _, size = pcall(function() return obj:GetBoundingBox() end)
        if ok and size and size.Magnitude > 0 then return size end
        local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if pp then return pp.Size end
        return Vector3.new(4, 5, 2)
    end
    return obj.Size
end

local function makeElement(obj, text, color)
    local e = {
        obj = obj,
        text = text,
        color = color,
        active = true,
    }

    e.hl = Instance.new("Highlight")
    e.hl.DepthMode = Config.DepthMode
    e.hl.Adornee = obj
    e.hl.FillTransparency = 1
    e.hl.OutlineTransparency = 1
    e.hl.Enabled = false
    e.hl.Parent = Gui

    local size = getSize(obj)
    e.adorns = {}

    e.adorns.box = Instance.new("BoxHandleAdornment")
    e.adorns.box.Adornee = obj
    e.adorns.box.Size = size
    e.adorns.box.AlwaysOnTop = true
    e.adorns.box.ZIndex = 10
    e.adorns.box.Color3 = color
    e.adorns.box.Transparency = 0.5
    e.adorns.box.Visible = false
    e.adorns.box.Parent = AdornFolder

    e.adorns.sphere = Instance.new("SphereHandleAdornment")
    e.adorns.sphere.Adornee = obj
    e.adorns.sphere.Radius = size.X * 1.085
    e.adorns.sphere.AlwaysOnTop = true
    e.adorns.sphere.ZIndex = 10
    e.adorns.sphere.Color3 = color
    e.adorns.sphere.Transparency = 0.5
    e.adorns.sphere.Visible = false
    e.adorns.sphere.Parent = AdornFolder

    e.adorns.cylinder = Instance.new("CylinderHandleAdornment")
    e.adorns.cylinder.Adornee = obj
    e.adorns.cylinder.Height = size.Y * 2
    e.adorns.cylinder.Radius = size.X * 1.085
    e.adorns.cylinder.CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0)
    e.adorns.cylinder.AlwaysOnTop = true
    e.adorns.cylinder.ZIndex = 10
    e.adorns.cylinder.Color3 = color
    e.adorns.cylinder.Transparency = 0.5
    e.adorns.cylinder.Visible = false
    e.adorns.cylinder.Parent = AdornFolder

    e.label = Instance.new("TextLabel")
    e.label.Size = UDim2.fromOffset(200, 50)
    e.label.AnchorPoint = Vector2.new(0.5, 0.5)
    e.label.BackgroundTransparency = 1
    e.label.Font = Config.Font
    e.label.TextSize = Config.TextSize
    e.label.Text = text
    e.label.TextColor3 = color
    e.label.TextStrokeTransparency = 0
    e.label.RichText = true
    e.label.Visible = false
    e.label.Parent = Gui

    e.tracer = nil
    e.tracerType = nil
    do
        local ok, p = pcall(function()
            local path = Instance.new("Path2D")
            path.Thickness = Config.TracerThickness
            path.Color3 = color
            path.Transparency = Config.TracerTransparency
            path.Closed = false
            path.Visible = false
            path.Parent = Gui
            return path
        end)
        if ok and p then
            e.tracer = p
            e.tracerType = "Path2D"
        else
            local f = Instance.new("Frame")
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.BorderSizePixel = 0
            f.BackgroundColor3 = color
            f.Visible = false
            f.Parent = Gui
            e.tracer = f
            e.tracerType = "Frame"
        end
    end

    e.arrow = Instance.new("ImageLabel")
    e.arrow.Size = UDim2.new(0, Config.ArrowSize, 0, Config.ArrowSize)
    e.arrow.SizeConstraint = Enum.SizeConstraint.RelativeYY
    e.arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    e.arrow.BackgroundTransparency = 1
    e.arrow.BorderSizePixel = 0
    e.arrow.Image = "rbxassetid://16368985219"
    e.arrow.ImageColor3 = color
    e.arrow.Visible = false
    e.arrow.Parent = Gui

    if DrawingAPI then
        local ok, tri = pcall(function() return DrawingAPI.new("Triangle") end)
        if ok and tri then
            tri.Visible = false
            e.triangle = tri
        end
    end

    return e
end

local function destroyElement(e)
    if e.hl then e.hl:Destroy() end
    if e.adorns then
        for _, a in pairs(e.adorns) do
            if a then a:Destroy() end
        end
    end
    if e.label then e.label:Destroy() end
    if e.tracer then pcall(function() e.tracer:Destroy() end) end
    if e.arrow then e.arrow:Destroy() end
    if e.triangle then pcall(function() e.triangle:Remove() end) end
    elements[e.obj] = nil
end

local function hideElement(e)
    e.hl.Enabled = false
    e.label.Visible = false
    if e.tracer then e.tracer.Visible = false end
    e.arrow.Visible = false
    if e.triangle then e.triangle.Visible = false end
    if e.adorns then
        for _, a in pairs(e.adorns) do
            if a then a.Visible = false end
        end
    end
end

local function isTeammate(obj)
    if not Config.TeamCheck then return false end
    local model = obj:IsA("Model") and obj or obj.Parent
    if not model then return false end
    local plr = Players:GetPlayerFromCharacter(model)
    if not plr or plr == LocalPlayer then return false end
    if not plr.Team or not LocalPlayer.Team then return false end
    return plr.Team == LocalPlayer.Team
end

local function isVisible(obj)
    if not Config.VisibleCheck then return true end
    local model = obj:IsA("Model") and obj or obj.Parent
    if not model or not model:IsA("Model") then return true end
    local target = model:FindFirstChild("Head") or model.PrimaryPart
    if not target then return true end
    local filter = { model }
    if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = filter
    params.IgnoreWater = true
    return Workspace:Raycast(camera.CFrame.Position, target.Position - camera.CFrame.Position, params) == nil
end

local function isAlive(obj)
    if not Config.AliveCheck then return true end
    local model = obj:IsA("Model") and obj or obj.Parent
    if not model or not model:IsA("Model") then return true end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return true end
    return hum.Health > 0
end

local function updateTracerPath(e, fromPos, toPos, color)
    local ok = pcall(function()
        e.tracer:SetControlPoints({
            Path2DControlPoint.new(fromPos),
            Path2DControlPoint.new(toPos),
        })
    end)
    if ok then
        e.tracer.Color3 = color
        e.tracer.Thickness = Config.TracerThickness
        e.tracer.Transparency = Config.TracerTransparency
        e.tracer.Visible = true
    else
        e.tracer:Destroy()
        local f = Instance.new("Frame")
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.BorderSizePixel = 0
        f.BackgroundColor3 = color
        f.Visible = false
        f.Parent = Gui
        e.tracer = f
        e.tracerType = "Frame"
    end
end

local function updateTracerFrame(e, fromPos, toPos, color)
    local fx = fromPos.X.Offset
    local fy = fromPos.Y.Offset
    local tx = toPos.X.Offset
    local ty = toPos.Y.Offset
    local dx = tx - fx
    local dy = ty - fy
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then
        e.tracer.Visible = false
        return
    end
    local midX = (fx + tx) / 2
    local midY = (fy + ty) / 2
    local ang = math.deg(math.atan2(dy, dx))
    e.tracer.Position = UDim2.fromOffset(midX, midY)
    e.tracer.Size = UDim2.new(0, len, 0, math.max(Config.TracerThickness, 1))
    e.tracer.Rotation = ang
    e.tracer.BackgroundColor3 = color
    e.tracer.Visible = true
end

local function updateArrowImage(e, screenPos, color)
    local vp = camera.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local targetPos = getPosition(e.obj)
    local camSpace = camera.CFrame:VectorToObjectSpace(targetPos - camera.CFrame.Position)

    local isInverted = screenPos.Z <= 0
    local invert = (isInverted and -1 or 1)

    local dir
    if screenPos.Z > 0 then
        dir = Vector2.new(screenPos.X, screenPos.Y) - center
        if dir.Magnitude < 1e-4 then
            dir = Vector2.new(camSpace.X, -camSpace.Y)
        end
    else
        dir = Vector2.new(camSpace.X, -camSpace.Y)
    end

    if dir.Magnitude < 1e-4 then
        e.arrow.Visible = false
        return
    end

    local arctan = math.atan2(dir.Y, dir.X)
    local angle = math.deg(arctan) + 90
    local distance = Config.ArrowRadius * vp.Y

    local posX = center.X + (distance * math.cos(arctan) * invert)
    local posY = center.Y + (distance * math.sin(arctan) * invert)

    local margin = 30
    posX = math.clamp(posX, margin, vp.X - margin)
    posY = math.clamp(posY, margin, vp.Y - margin)

    e.arrow.Rotation = angle + 180 * (isInverted and 0 or 1)
    e.arrow.Position = UDim2.fromOffset(posX, posY)
    e.arrow.Size = UDim2.new(0, Config.ArrowSize, 0, Config.ArrowSize)
    e.arrow.ImageColor3 = color
    e.arrow.Visible = true
end

local function updateArrowTriangle(e, screenPos, color)
    if not e.triangle then return end

    local vp = camera.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local targetPos = getPosition(e.obj)
    local camSpace = camera.CFrame:VectorToObjectSpace(targetPos - camera.CFrame.Position)

    local dir
    if screenPos.Z > 0 then
        dir = Vector2.new(screenPos.X, screenPos.Y) - center
        if dir.Magnitude < 1e-4 then
            dir = Vector2.new(camSpace.X, -camSpace.Y)
        end
    else
        dir = Vector2.new(camSpace.X, -camSpace.Y)
    end

    if dir.Magnitude < 1e-4 then
        e.triangle.Visible = false
        return
    end

    local angle = math.atan2(dir.Y, dir.X)
    local radius = Config.ArrowRadius * math.min(vp.X, vp.Y)
    local size = Config.TriangleSize

    local cosA = math.cos(angle)
    local sinA = math.sin(angle)

    local tipX = center.X + radius * cosA
    local tipY = center.Y + radius * sinA

    local backCenterX = tipX - cosA * size
    local backCenterY = tipY - sinA * size

    local halfBase = size / 2
    local perpX = -sinA * halfBase
    local perpY = cosA * halfBase

    local baseLX = backCenterX + perpX
    local baseLY = backCenterY + perpY
    local baseRX = backCenterX - perpX
    local baseRY = backCenterY - perpY

    if not Config.TriangleAntiAliasing then
        tipX = math.floor(tipX + 0.5)
        tipY = math.floor(tipY + 0.5)
        baseLX = math.floor(baseLX + 0.5)
        baseLY = math.floor(baseLY + 0.5)
        baseRX = math.floor(baseRX + 0.5)
        baseRY = math.floor(baseRY + 0.5)
    end

    e.triangle.PointA = Vector2.new(tipX, tipY)
    e.triangle.PointB = Vector2.new(baseLX, baseLY)
    e.triangle.PointC = Vector2.new(baseRX, baseRY)
    e.triangle.Filled = Config.TriangleFilled
    e.triangle.Thickness = Config.TriangleThickness
    e.triangle.Color = color
    e.triangle.Transparency = 1 - Config.TriangleTransparency
    e.triangle.Visible = true
end

local function refresh(e)
    local obj = e.obj
    if not obj or not obj:IsDescendantOf(game) then
        if e.active then
            e.active = false
            destroyElement(e)
        end
        return
    end

    if isTeammate(obj) or not isAlive(obj) or not isVisible(obj) then
        hideElement(e)
        return
    end

    local pos = getPosition(obj)
    local screenPos, onScreen = camera:WorldToViewportPoint(pos)
    local dist = (camera.CFrame.Position - pos).Magnitude

    if Config.MaxDistance > 0 and dist > Config.MaxDistance then
        hideElement(e)
        return
    end

    local color = Config.Rainbow and rainbowColor or e.color
    local style = Config.ESPStyle

    e.hl.Enabled = false
    e.label.Visible = false
    if e.tracer then e.tracer.Visible = false end
    e.arrow.Visible = false
    if e.triangle then e.triangle.Visible = false end
    for _, a in pairs(e.adorns) do
        if a then a.Visible = false end
    end

    if onScreen then
        if style == "Highlight" then
            e.hl.Enabled = true
            e.hl.FillColor = color
            e.hl.OutlineColor = Config.MatchColors and color or Config.OutlineColor
            e.hl.FillTransparency = Config.FillTransparency
            e.hl.OutlineTransparency = Config.OutlineTransparency
        elseif style == "Adornment" then
            e.adorns.box.Visible = true
            e.adorns.box.Color3 = Config.UseElementColorForAdornment and color or Config.AdornmentColor
            e.adorns.box.Transparency = Config.AdornmentTransparency
        elseif style == "SphereAdornment" then
            e.adorns.sphere.Visible = true
            e.adorns.sphere.Color3 = Config.UseElementColorForAdornment and color or Config.AdornmentColor
            e.adorns.sphere.Transparency = Config.AdornmentTransparency
        elseif style == "CylinderAdornment" then
            e.adorns.cylinder.Visible = true
            e.adorns.cylinder.Color3 = Config.UseElementColorForAdornment and color or Config.AdornmentColor
            e.adorns.cylinder.Transparency = Config.AdornmentTransparency
        end

        if Config.Tracers and e.tracer then
            local vp = camera.ViewportSize
            local fromPos
            if Config.TracerAnchor == "Mouse" then
                local m = UserInputService:GetMouseLocation()
                fromPos = UDim2.fromOffset(m.X, m.Y)
            else
                local anchor = Anchors[Config.TracerAnchor] or Anchors.Bottom
                fromPos = UDim2.fromOffset(vp.X * anchor.X, vp.Y * anchor.Y)
            end
            local toPos = UDim2.fromOffset(screenPos.X, screenPos.Y)

            if e.tracerType == "Path2D" then
                updateTracerPath(e, fromPos, toPos, color)
            else
                updateTracerFrame(e, fromPos, toPos, color)
            end
        end

        e.label.Visible = true
        e.label.Position = UDim2.fromOffset(screenPos.X, screenPos.Y)
        e.label.TextColor3 = color
        e.label.TextSize = Config.TextSize
        e.label.Font = Config.Font

        local lines = {}
        if Config.ShowName then table.insert(lines, e.text) end
        if Config.ShowHealth then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum then
                lines[#lines + 1] = string.format("%d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth))
            end
        end
        if Config.ShowDistance then
            lines[#lines + 1] = string.format("[%d%s]", math.floor(dist), Config.DistanceSuffix)
        end
        e.label.Text = table.concat(lines, "\n")
    else
        if Config.Arrows then
            if Config.ArrowStyle == "Triangle" and e.triangle then
                updateArrowTriangle(e, screenPos, color)
            else
                updateArrowImage(e, screenPos, color)
            end
        end
    end
end

local accum = 0
local hbConn = RunService.Heartbeat:Connect(function(dt)
    if unloaded then return end
    accum = accum + dt
    if accum < 1 / Config.RenderRate then return end
    accum = 0
    for _, e in pairs(elements) do
        if e.active then
            local ok, err = pcall(refresh, e)
            if not ok then
                warn("[StarLight ESP] refresh error:", err)
            end
        end
    end
end)

local hueAccum = 0
local rainbowConn = RunService.RenderStepped:Connect(function(dt)
    if not Config.Rainbow then return end
    hueAccum = hueAccum + dt
    if hueAccum < 1 / 60 then return end
    hueAccum = 0
    hue = (hue + 1 / 400) % 1
    rainbowColor = Color3.fromHSV(hue, 0.8, 1)
end)

local camConn = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    camera = Workspace.CurrentCamera
end)

local API = {}
API.Config = Config
API.Anchors = Anchors
API.Styles = { "Highlight", "Adornment", "SphereAdornment", "CylinderAdornment" }
API.ArrowStyles = { "Image", "Triangle" }

function API:Add(object, text, color)
    if unloaded or not object then return end
    if not (object:IsA("BasePart") or object:IsA("Model")) then return end
    if elements[object] then return elements[object] end
    local e = makeElement(object, text or object.Name, color or Color3.fromRGB(255, 255, 255))
    elements[object] = e
    return e
end

function API:Remove(object)
    local e = elements[object]
    if e then
        e.active = false
        destroyElement(e)
    end
end

function API:Update(object, text, color)
    local e = elements[object]
    if not e then return end
    if text ~= nil then e.text = text end
    if color ~= nil then e.color = color end
end

function API:Unload()
    if unloaded then return end
    unloaded = true
    for _, e in pairs(elements) do
        e.active = false
        destroyElement(e)
    end
    elements = {}
    hbConn:Disconnect()
    rainbowConn:Disconnect()
    camConn:Disconnect()
    Gui:Destroy()
    if AdornFolder then AdornFolder:Destroy() end
end

if getgenv then
    getgenv().ESP = API
end

return API
