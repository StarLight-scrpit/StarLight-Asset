local cloneref = cloneref or function(o) return o end

local Players      = cloneref(game:GetService("Players"))
local RunService   = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local Workspace    = cloneref(workspace)
local LocalPlayer  = Players.LocalPlayer

local DrawingAPI = Drawing

local _uid = 0
local function newId()
    _uid = _uid + 1
    return "e" .. _uid
end

local Anchors = {
    TopLeft     = Vector2.new(0.00, 0.00),
    Top         = Vector2.new(0.50, 0.00),
    TopRight    = Vector2.new(1.00, 0.00),
    Left        = Vector2.new(0.00, 0.50),
    Center      = Vector2.new(0.50, 0.50),
    Right       = Vector2.new(1.00, 0.50),
    BottomLeft  = Vector2.new(0.00, 1.00),
    Bottom      = Vector2.new(0.50, 1.00),
    BottomRight = Vector2.new(1.00, 1.00),
}

local Config = {
    Font = Enum.Font.RobotoCondensed,
    TextSize = 20,
    TextTransparency = 0,
    TextStrokeTransparency = 0,
    FadeTime = 0,

    FillTransparency = 0.75,
    OutlineTransparency = 0,
    OutlineColor = Color3.fromRGB(255, 255, 255),
    MatchColors = true,

    RenderRate = 60,
    Rainbow = false,

    ESPStyle = "Highlight",

    BoxThickness = 1,
    BoxTransparency = 0,
    BoxColor = Color3.fromRGB(255, 255, 255),
    UseElementColorForBox = true,

    Tracers = false,
    TracerAnchor = "Bottom",
    TracerThickness = 1,

    Arrows = false,
    ArrowStyle = "Image",
    ArrowRadius = 200,

    TriangleDistFromCenter = 80,
    TriangleHeight = 16,
    TriangleWidth = 16,
    TriangleFilled = true,
    TriangleTransparency = 0,
    TriangleThickness = 1,
    TriangleColor = Color3.fromRGB(255, 255, 255),
    TriangleAntiAliasing = false,

    ShowName = true,
    ShowHealth = false,
    ShowDistance = false,
    DistanceSuffix = " studs",
    DistanceSizeRatio = 1,
    MaxDistance = 300,

    ShowHealthBar = false,
    HealthBarWidth = 2,
    DynamicHealthColor = true,

    TeamCheck = false,
    VisibleCheck = false,
    AliveCheck = true,
}

local unloaded = false
local elements = {}
local hue = 0
local rainbowColor = Color3.new(1, 1, 1)
local camera = Workspace.CurrentCamera

local host
if gethui then
    local ok, h = pcall(gethui)
    if ok and h then host = h end
end
host = host or game:GetService("CoreGui")

local Gui = Instance.new("ScreenGui")
Gui.Name = "esp_" .. tostring(math.random(100000, 999999))
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = host

local TracerLayer = Instance.new("Frame")
TracerLayer.Size = UDim2.fromScale(1, 1)
TracerLayer.BackgroundTransparency = 1
TracerLayer.Visible = false
TracerLayer.ZIndex = 5
TracerLayer.Parent = Gui

local ArrowLayer = Instance.new("Frame")
ArrowLayer.Size = UDim2.fromScale(1, 1)
ArrowLayer.BackgroundTransparency = 1
ArrowLayer.Visible = false
ArrowLayer.ZIndex = 5
ArrowLayer.Parent = Gui

local ArrowProto = Instance.new("ImageLabel")
ArrowProto.Name = "arrow_proto"
ArrowProto.Image = "rbxassetid://16368985219"
ArrowProto.Size = UDim2.fromOffset(50, 50)
ArrowProto.AnchorPoint = Vector2.new(0.5, 0.5)
ArrowProto.BackgroundTransparency = 1
ArrowProto.ImageTransparency = 1

local ArrowAspect = Instance.new("UIAspectRatioConstraint")
ArrowAspect.AspectRatio = 1
ArrowAspect.Parent = ArrowProto

local function fade(inst, props)
    if Config.FadeTime <= 0 then
        for k, v in pairs(props) do inst[k] = v end
        return
    end
    TweenService:Create(inst, TweenInfo.new(Config.FadeTime, Enum.EasingStyle.Quad), props):Play()
end

local function rotateVect(v, deg)
    local a = math.rad(deg)
    local c, s = math.cos(a), math.sin(a)
    return Vector2.new(v.X * c - v.Y * s, v.X * s + v.Y * c)
end

local function horizontalRelative(pos)
    local camP = camera.CFrame.Position
    local look = camera.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude < 1e-4 then flat = Vector3.new(0, 0, -1) end
    local basis = CFrame.new(Vector3.zero, flat)
    local rel = basis:VectorToObjectSpace(pos - camP)
    return Vector2.new(rel.X, rel.Z)
end

local function healthColor(hum)
    if not hum then return Color3.fromRGB(0, 255, 0) end
    local r = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
    return Color3.fromRGB(math.floor((1 - r) * 255), math.floor(r * 255), 0)
end

local function makeElement(obj, text, color)
    local e = {
        obj = obj,
        text = text,
        color = color,
        active = true,
        visible = false,
    }

    e.hl = Instance.new("Highlight")
    e.hl.Name = newId()
    e.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    e.hl.Adornee = obj
    e.hl.FillTransparency = 1
    e.hl.OutlineTransparency = 1
    e.hl.Enabled = false
    e.hl.Parent = Gui

    e.box = Instance.new("Frame")
    e.box.Name = newId()
    e.box.BackgroundTransparency = 1
    e.box.BorderSizePixel = 0
    e.box.Visible = false
    e.box.Parent = Gui

    e.boxTop    = Instance.new("Frame"); e.boxTop.Parent = e.box
    e.boxBottom = Instance.new("Frame"); e.boxBottom.Parent = e.box
    e.boxLeft   = Instance.new("Frame"); e.boxLeft.Parent = e.box
    e.boxRight  = Instance.new("Frame"); e.boxRight.Parent = e.box
    for _, l in ipairs({ e.boxTop, e.boxBottom, e.boxLeft, e.boxRight }) do
        l.Name = newId()
        l.BorderSizePixel = 0
        l.BackgroundTransparency = 1
    end

    e.labelFrame = Instance.new("Frame")
    e.labelFrame.Name = newId()
    e.labelFrame.Size = UDim2.fromScale(1, 1)
    e.labelFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    e.labelFrame.BackgroundTransparency = 1
    e.labelFrame.Visible = false
    e.labelFrame.Parent = Gui

    e.label = Instance.new("TextLabel")
    e.label.Name = newId()
    e.label.Size = UDim2.fromScale(1, 1)
    e.label.BackgroundTransparency = 1
    e.label.Font = Config.Font
    e.label.TextSize = Config.TextSize
    e.label.Text = text
    e.label.TextColor3 = color
    e.label.TextTransparency = 1
    e.label.TextStrokeTransparency = Config.TextStrokeTransparency
    e.label.RichText = true
    e.label.Parent = e.labelFrame

    e.hpBg = Instance.new("Frame")
    e.hpBg.Name = newId()
    e.hpBg.BackgroundColor3 = Color3.new(0, 0, 0)
    e.hpBg.BackgroundTransparency = 0.4
    e.hpBg.BorderSizePixel = 0
    e.hpBg.Visible = false
    e.hpBg.Parent = Gui

    e.hpFill = Instance.new("Frame")
    e.hpFill.Name = newId()
    e.hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    e.hpFill.BorderSizePixel = 0
    e.hpFill.Parent = e.hpBg

    e.tracer = Instance.new("Frame")
    e.tracer.Name = newId()
    e.tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    e.tracer.BackgroundTransparency = 1
    e.tracer.Parent = TracerLayer

    e.tracerStroke = Instance.new("UIStroke")
    e.tracerStroke.Name = newId()
    e.tracerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    e.tracerStroke.Transparency = 1
    e.tracerStroke.Parent = e.tracer

    e.arrow = ArrowProto:Clone()
    e.arrow.Name = newId()
    e.arrow.Parent = ArrowLayer

    if DrawingAPI then
        local ok, tri = pcall(function() return DrawingAPI.new("Triangle") end)
        if ok and tri then
            tri.Visible = false
            e.tri = tri
        end
    end

    fade(e.hl, { FillTransparency = Config.FillTransparency, OutlineTransparency = Config.OutlineTransparency })
    fade(e.label, { TextTransparency = Config.TextTransparency, TextStrokeTransparency = Config.TextStrokeTransparency })
    fade(e.tracer, { BackgroundTransparency = 0 })
    fade(e.tracerStroke, { Transparency = 0 })
    fade(e.arrow, { ImageTransparency = 0 })

    return e
end

local function destroyElement(e)
    if e.hl then e.hl:Destroy() end
    if e.box then e.box:Destroy() end
    if e.labelFrame then e.labelFrame:Destroy() end
    if e.hpBg then e.hpBg:Destroy() end
    if e.tracer then e.tracer:Destroy() end
    if e.arrow then e.arrow:Destroy() end
    if e.tri then pcall(function() e.tri:Remove() end) end
    elements[e.obj] = nil
end

local function leaveElement(e)
    if not e.active then return end
    e.active = false
    e.visible = false

    fade(e.label, { TextTransparency = 1 })
    fade(e.tracer, { BackgroundTransparency = 1 })
    fade(e.tracerStroke, { Transparency = 1 })
    fade(e.hl, { FillTransparency = 1, OutlineTransparency = 1 })
    fade(e.arrow, { ImageTransparency = 1 })

    if e.tri then e.tri.Visible = false end

    e.box.Visible = false
    e.hpBg.Visible = false
    e.hpFill.Visible = false

    task.delay(Config.FadeTime + 0.05, function()
        if not e.active then destroyElement(e) end
    end)
end

local function hideElement(e)
    e.hl.Enabled = false
    e.labelFrame.Visible = false
    e.tracer.Visible = false
    e.arrow.Visible = false
    if e.tri then e.tri.Visible = false end
    e.box.Visible = false
    e.hpBg.Visible = false
    e.hpFill.Visible = false
    e.visible = false
end

local function projectBox(obj)
    local cf, size
    if obj:IsA("Model") then
        local ok, c, s = pcall(function() return obj:GetBoundingBox() end)
        if not ok then return nil end
        cf, size = c, s
    else
        cf, size = obj.CFrame, obj.Size
    end

    local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    for _, sx in ipairs({ -1, 1 }) do
        for _, sy in ipairs({ -1, 1 }) do
            for _, sz in ipairs({ -1, 1 }) do
                local world = (cf * CFrame.new(hx * sx, hy * sy, hz * sz)).Position
                local sp = camera:WorldToViewportPoint(world)
                if sp.Z <= 0 then return nil end
                if sp.X < minX then minX = sp.X end
                if sp.Y < minY then minY = sp.Y end
                if sp.X > maxX then maxX = sp.X end
                if sp.Y > maxY then maxY = sp.Y end
            end
        end
    end

    return minX, minY, maxX - minX, maxY - minY
end

local function isTeammate(obj)
    if not Config.TeamCheck or not obj then return false end
    local plr = Players:GetPlayerFromCharacter(obj:IsA("Model") and obj or obj.Parent)
    if not plr or plr == LocalPlayer then return false end
    if not plr.Team or not LocalPlayer.Team then return false end
    return plr.Team == LocalPlayer.Team
end

local function isVisible(obj)
    if not Config.VisibleCheck then return true end
    local char = obj:IsA("Model") and obj or obj.Parent
    if not char or not char:IsA("Model") then return true end

    local target = char:FindFirstChild("Head") or char.PrimaryPart
    if not target then return true end

    local filter = { char }
    if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = filter
    params.IgnoreWater = true

    return Workspace:Raycast(camera.CFrame.Position, target.Position - camera.CFrame.Position, params) == nil
end

local function isAlive(obj)
    if not Config.AliveCheck then return true end
    local char = obj:IsA("Model") and obj or obj.Parent
    if not char or not char:IsA("Model") then return true end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return true end
    return hum.Health > 0
end

local function refreshBox(e, obj, color)
    if Config.ESPStyle ~= "Box" then
        e.box.Visible = false
        return
    end

    local x, y, w, h = projectBox(obj)
    if not x then
        e.box.Visible = false
        return
    end

    local t = Config.BoxThickness
    local tr = Config.BoxTransparency
    local c = Config.UseElementColorForBox and color or Config.BoxColor

    e.box.Visible = true
    e.box.Position = UDim2.fromOffset(x, y)
    e.box.Size = UDim2.fromOffset(w, h)

    e.boxTop.Position    = UDim2.fromOffset(0, 0)
    e.boxTop.Size        = UDim2.new(1, 0, 0, t)
    e.boxBottom.Position = UDim2.new(0, 0, 1, -t)
    e.boxBottom.Size     = UDim2.new(1, 0, 0, t)
    e.boxLeft.Position   = UDim2.fromOffset(0, 0)
    e.boxLeft.Size       = UDim2.new(0, t, 1, 0)
    e.boxRight.Position  = UDim2.new(1, -t, 0, 0)
    e.boxRight.Size      = UDim2.new(0, t, 1, 0)

    for _, l in ipairs({ e.boxTop, e.boxBottom, e.boxLeft, e.boxRight }) do
        l.BackgroundColor3 = c
        l.BackgroundTransparency = tr
    end
end

local function refreshHealthBar(e, obj)
    if not Config.ShowHealthBar then
        e.hpBg.Visible = false
        return
    end

    local hum = obj:FindFirstChildOfClass("Humanoid")
    if not hum then
        e.hpBg.Visible = false
        return
    end

    local x, y, _, h = projectBox(obj)
    if not x then
        e.hpBg.Visible = false
        return
    end

    local barW = Config.HealthBarWidth
    e.hpBg.Visible = true
    e.hpBg.Position = UDim2.fromOffset(x - barW - 4, y)
    e.hpBg.Size = UDim2.fromOffset(barW, h)

    local r = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
    local fillH = h * r

    e.hpFill.Position = UDim2.fromOffset(0, h - fillH)
    e.hpFill.Size = UDim2.fromOffset(barW, fillH)
    e.hpFill.BackgroundColor3 = Config.DynamicHealthColor and healthColor(hum) or Color3.fromRGB(0, 255, 0)
end

local function refreshArrowImage(e, screen, pos, color)
    local vp = camera.ViewportSize
    local center = vp / 2

    if screen.Z > 0 then
        e.arrow.Visible = false
        return
    end

    local toObj = (pos - camera.CFrame.Position).Unit
    local dir = Vector2.new(screen.X, screen.Y) - center
    if camera.CFrame.LookVector:Dot(toObj) < 0 then
        dir = -dir
    end

    local ang = math.atan2(dir.Y, dir.X)
    local radius = math.min(vp.X, vp.Y) / 2 - math.clamp(400 - Config.ArrowRadius, 0, math.min(vp.X, vp.Y) / 2 - 30)
    local place = center + dir.Unit * radius

    e.arrow.Position = UDim2.fromOffset(place.X, place.Y)
    e.arrow.Rotation = math.deg(ang) - 90
    e.arrow.Visible = true
    e.arrow.ImageColor3 = color
end

local function refreshArrowTriangle(e, pos, color)
    if not e.tri then return end

    local _, vis = camera:WorldToViewportPoint(pos)
    if vis then
        e.tri.Visible = false
        return
    end

    local rel = horizontalRelative(pos)
    if rel.Magnitude < 1e-4 then
        e.tri.Visible = false
        return
    end

    local dir = rel.Unit
    local base = dir * Config.TriangleDistFromCenter
    local half = Config.TriangleWidth / 2
    local baseL = base + rotateVect(dir, 90) * half
    local baseR = base + rotateVect(dir, -90) * half
    local tip = dir * (Config.TriangleDistFromCenter + Config.TriangleHeight)

    local center = camera.ViewportSize / 2

    local function snap(v)
        if not Config.TriangleAntiAliasing then return v end
        return Vector2.new(math.round(v.X), math.round(v.Y))
    end

    e.tri.PointA = snap(center - baseL)
    e.tri.PointB = snap(center - baseR)
    e.tri.PointC = snap(center - tip)
    e.tri.Filled = Config.TriangleFilled
    e.tri.Thickness = Config.TriangleThickness
    e.tri.Color = color
    e.tri.Transparency = 1 - Config.TriangleTransparency
    e.tri.Visible = true
end

local function refresh(e)
    local obj = e.obj
    if not obj or not obj:IsDescendantOf(game) then
        leaveElement(e)
        return
    end

    if isTeammate(obj) or not isAlive(obj) or not isVisible(obj) then
        hideElement(e)
        return
    end

    local pos = obj:GetPivot().Position
    local screen, onScreen = camera:WorldToViewportPoint(pos)
    local dist = (camera.CFrame.Position - pos).Magnitude

    if Config.MaxDistance > 0 and dist > Config.MaxDistance then
        onScreen = false
    end

    if not onScreen then
        hideElement(e)
        return
    end

    e.visible = true
    local color = Config.Rainbow and rainbowColor or e.color

    e.hl.Enabled = (Config.ESPStyle == "Highlight")
    if e.hl.Enabled then
        e.hl.FillColor = color
        e.hl.OutlineColor = Config.MatchColors and color or Config.OutlineColor
        if e.active then
            e.hl.FillTransparency = Config.FillTransparency
            e.hl.OutlineTransparency = Config.OutlineTransparency
        end
    end

    refreshBox(e, obj, color)
    refreshHealthBar(e, obj)

    e.labelFrame.Visible = true
    e.labelFrame.Position = UDim2.fromOffset(screen.X, screen.Y)
    e.label.TextColor3 = color
    e.label.TextSize = Config.TextSize
    e.label.Font = Config.Font
    if e.active then
        e.label.TextTransparency = Config.TextTransparency
        e.label.TextStrokeTransparency = Config.TextStrokeTransparency
    end

    local lines = {}
    if Config.ShowName then table.insert(lines, e.text) end
    if Config.ShowHealth then
        local hum = obj:FindFirstChildOfClass("Humanoid")
        if hum then
            lines[#lines + 1] = string.format("%d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth))
        end
    end
    if Config.ShowDistance then
        local s = math.round(Config.TextSize * Config.DistanceSizeRatio)
        lines[#lines + 1] = string.format('<font size="%d">[%d%s]</font>', s, math.floor(dist), Config.DistanceSuffix)
    end
    e.label.Text = table.concat(lines, "\n")

    if Config.Tracers then
        local vp = camera.ViewportSize
        local anchor = Anchors[Config.TracerAnchor] or Anchors.Bottom
        local origin = Vector2.new(vp.X * anchor.X, vp.Y * anchor.Y)
        local dest = Vector2.new(screen.X, screen.Y)
        local mid = (origin + dest) / 2
        local len = (origin - dest).Magnitude
        local ang = math.deg(math.atan2(dest.Y - origin.Y, dest.X - origin.X))

        e.tracer.Position = UDim2.fromOffset(mid.X, mid.Y)
        e.tracer.Size = UDim2.new(0, len, 0, 1)
        e.tracer.Rotation = ang
        e.tracer.BackgroundColor3 = color
        e.tracer.Visible = true
        e.tracerStroke.Color = color
        e.tracerStroke.Thickness = Config.TracerThickness
    else
        e.tracer.Visible = false
    end

    if Config.Arrows then
        if Config.ArrowStyle == "Triangle" and e.tri then
            e.arrow.Visible = false
            refreshArrowTriangle(e, pos, color)
        else
            if e.tri then e.tri.Visible = false end
            refreshArrowImage(e, screen, pos, color)
        end
    else
        e.arrow.Visible = false
        if e.tri then e.tri.Visible = false end
    end
end

local accum = 0
local hbConn = RunService.Heartbeat:Connect(function(dt)
    if unloaded then return end

    accum = accum + dt
    if accum < 1 / Config.RenderRate then return end
    accum = 0

    for _, e in pairs(elements) do
        if e.active then refresh(e) end
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
API.Styles = { "Highlight", "Box" }

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
    if e then leaveElement(e) end
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

    for _, e in pairs(elements) do destroyElement(e) end
    elements = {}

    hbConn:Disconnect()
    rainbowConn:Disconnect()
    camConn:Disconnect()

    Gui.Enabled = false
end

if getgenv then
    getgenv().ESP = API
end

return API
