local cloneref = cloneref or function(o) return o end

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local UserInput = cloneref(game:GetService("UserInputService"))
local Workspace = cloneref(workspace)
local LocalPlayer = Players.LocalPlayer

local DrawingAPI = Drawing

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
    FillTransparency = 0.75,
    OutlineTransparency = 0,
    OutlineColor = Color3.fromRGB(255, 255, 255),
    FadeTime = 0,
    RenderRate = 240,

    Rainbow = false,
    MatchColors = true,

    Tracers = false,
    TracerAnchor = "Bottom",
    TracerThickness = 0.5,

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

    ShowDistance = false,
    DistanceSuffix = " studs",
    DistanceSizeRatio = 1,
    MaxDistance = 1000,
}

local State = {
    Unloaded = false,
    Elements = {},
    Hue = 0,
    RainbowColor = Color3.new(),
    Camera = Workspace.CurrentCamera,
}

local function Tag()
    return string.format("%032x", math.random(0, 2 ^ 31))
end

local function Root()
    if gethui then return gethui() end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function Folder(parent)
    local f = Instance.new("Folder")
    f.Name = Tag()
    f.Parent = parent
    return f
end

local Host = Root()

local Gui = Instance.new("ScreenGui")
Gui.Name = Tag()
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = Host

local HighlightBucket = Folder(Gui)
local LabelBucket = Folder(Gui)

local TracerLayer = Instance.new("Frame")
TracerLayer.Name = Tag()
TracerLayer.Size = UDim2.fromScale(1, 1)
TracerLayer.BackgroundTransparency = 1
TracerLayer.Visible = false
TracerLayer.Parent = Gui

local ArrowLayer = Instance.new("Frame")
ArrowLayer.Name = Tag()
ArrowLayer.Size = UDim2.fromScale(1, 1)
ArrowLayer.BackgroundTransparency = 1
ArrowLayer.Visible = false
ArrowLayer.Parent = Gui

local ArrowProto = Instance.new("ImageLabel")
ArrowProto.Name = Tag()
ArrowProto.Image = "rbxassetid://16368985219"
ArrowProto.Size = UDim2.fromOffset(50, 50)
ArrowProto.AnchorPoint = Vector2.new(0.5, 0.5)
ArrowProto.BackgroundTransparency = 1
ArrowProto.ImageTransparency = 1

local ArrowAspect = Instance.new("UIAspectRatioConstraint")
ArrowAspect.AspectRatio = 1
ArrowAspect.Parent = ArrowProto

local function Fade(inst, props)
    local info = TweenInfo.new(Config.FadeTime, Enum.EasingStyle.Quad)
    local tw = TweenService:Create(inst, info, props)
    tw:Play()
    return tw
end

local function RotateVect(v, a)
    a = math.rad(a)
    local c = math.cos(a)
    local s = math.sin(a)
    return Vector2.new(v.X * c - v.Y * s, v.X * s + v.Y * c)
end

local function HorizontalRelative(pos)
    local camP = State.Camera.CFrame.Position
    local look = State.Camera.CFrame.LookVector
    local flatLook = Vector3.new(look.X, 0, look.Z)
    if flatLook.Magnitude < 1e-4 then
        flatLook = Vector3.new(0, 0, -1)
    end
    local flat = CFrame.new(Vector3.new(0, 0, 0), flatLook)
    local rel = flat:VectorToObjectSpace(pos - camP)
    return Vector2.new(rel.X, rel.Z)
end

local Element = {}
Element.__index = Element

function Element.new(object, text, color)
    local self = setmetatable({}, Element)
    self.Object = object
    self.Text = text
    self.Color = color
    self.Active = true
    self.Visible = false

    self:_BuildHighlight()
    self:_BuildLabel()
    self:_BuildTracer()
    self:_BuildArrow()

    self:Enter()
    return self
end

function Element:_BuildHighlight()
    local hl = Instance.new("Highlight")
    hl.Name = Tag()
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = self.Object
    hl.FillTransparency = 1
    hl.OutlineTransparency = 1
    hl.Parent = HighlightBucket
    self.Highlight = hl
end

function Element:_BuildLabel()
    local frame = Instance.new("Frame")
    frame.Name = Tag()
    frame.Size = UDim2.fromScale(1, 1)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = LabelBucket

    local lbl = Instance.new("TextLabel")
    lbl.Name = Tag()
    lbl.Size = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.Font = Config.Font
    lbl.TextSize = Config.TextSize
    lbl.Text = self.Text
    lbl.TextColor3 = self.Color
    lbl.TextTransparency = 1
    lbl.TextStrokeTransparency = Config.TextStrokeTransparency
    lbl.RichText = true
    lbl.Parent = frame

    self.LabelFrame = frame
    self.Label = lbl
end

function Element:_BuildTracer()
    local line = Instance.new("Frame")
    line.Name = Tag()
    line.Size = UDim2.fromOffset(0, 0)
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BackgroundTransparency = 1
    line.Parent = TracerLayer

    local stroke = Instance.new("UIStroke")
    stroke.Name = Tag()
    stroke.Thickness = Config.TracerThickness
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Transparency = 1
    stroke.Parent = line

    self.Tracer = line
    self.TracerStroke = stroke
end

function Element:_BuildArrow()
    local img = ArrowProto:Clone()
    img.Name = Tag()
    img.Parent = ArrowLayer
    self.ArrowImage = img

    if DrawingAPI then
        local ok, tri = pcall(function() return DrawingAPI.new("Triangle") end)
        if ok and tri then
            tri.Visible = false
            tri.Filled = Config.TriangleFilled
            tri.Thickness = Config.TriangleThickness
            tri.Color = Config.TriangleColor
            tri.Transparency = 1 - Config.TriangleTransparency
            self.ArrowTriangle = tri
        end
    end
end

function Element:Enter()
    Fade(self.Highlight, { FillTransparency = Config.FillTransparency })
    Fade(self.Highlight, { OutlineTransparency = Config.OutlineTransparency })
    Fade(self.Label, { TextTransparency = Config.TextTransparency })
    Fade(self.Label, { TextStrokeTransparency = Config.TextStrokeTransparency })
    Fade(self.Tracer, { BackgroundTransparency = 0 })
    Fade(self.TracerStroke, { Transparency = 0 })
    Fade(self.ArrowImage, { ImageTransparency = 0 })
end

function Element:Leave()
    if not self.Active then return end
    self.Active = false
    self.Visible = false

    Fade(self.Label, { TextTransparency = 1 })
    Fade(self.Tracer, { BackgroundTransparency = 1 })
    Fade(self.TracerStroke, { Transparency = 1 })
    Fade(self.Highlight, { FillTransparency = 1 })
    Fade(self.Highlight, { OutlineTransparency = 1 })
    Fade(self.ArrowImage, { ImageTransparency = 1 })

    if self.ArrowTriangle then
        self.ArrowTriangle.Visible = false
    end

    task.delay(Config.FadeTime + 0.05, function()
        if not self.Active then
            self:Destroy()
        end
    end)
end

function Element:Destroy()
    if self.Highlight then self.Highlight:Destroy() end
    if self.LabelFrame then self.LabelFrame:Destroy() end
    if self.Tracer then self.Tracer:Destroy() end
    if self.ArrowImage then self.ArrowImage:Destroy() end
    if self.ArrowTriangle then
        pcall(function() self.ArrowTriangle:Remove() end)
        self.ArrowTriangle = nil
    end
    State.Elements[self.Object] = nil
end

local function AnchorFor(anchor, viewport)
    if typeof(anchor) == "Vector2" then
        return Vector2.new(viewport.X * anchor.X, viewport.Y * anchor.Y)
    end
    if anchor == "Mouse" then
        local m = UserInput:GetMouseLocation()
        return Vector2.new(LocalPlayer:GetMouse().X, m.Y)
    end
    local a = Anchors[anchor] or Anchors.Bottom
    return Vector2.new(viewport.X * a.X, viewport.Y * a.Y)
end

local function RefreshArrowImage(el, screen, pos, color)
    local vp = State.Camera.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)

    if screen.Z > 0 then
        el.ArrowImage.Visible = false
        return
    end

    local toObj = (pos - State.Camera.CFrame.Position).Unit
    local dir = Vector2.new(screen.X, screen.Y) - center
    if State.Camera.CFrame.LookVector:Dot(toObj) < 0 then
        dir = -dir
    end

    local ang = math.atan2(dir.Y, dir.X)
    local radius = math.min(vp.X, vp.Y) / 2 - (400 - Config.ArrowRadius)
    local place = center + dir.Unit * radius

    el.ArrowImage.Position = UDim2.fromOffset(place.X, place.Y)
    el.ArrowImage.Rotation = math.deg(ang) - 90
    el.ArrowImage.Visible = true
    el.ArrowImage.ImageColor3 = color
end

local function SnapV2(v)
    if not Config.TriangleAntiAliasing then return v end
    return Vector2.new(math.round(v.X), math.round(v.Y))
end

local function RefreshArrowTriangle(el, pos, color)
    if not el.ArrowTriangle then return end

    local _, vis = State.Camera:WorldToViewportPoint(pos)
    if vis then
        el.ArrowTriangle.Visible = false
        return
    end

    local rel = HorizontalRelative(pos)
    if rel.Magnitude < 1e-4 then
        el.ArrowTriangle.Visible = false
        return
    end

    local dir = rel.Unit
    local base = dir * Config.TriangleDistFromCenter
    local half = Config.TriangleWidth / 2
    local baseL = base + RotateVect(dir, 90) * half
    local baseR = base + RotateVect(dir, -90) * half
    local tip = dir * (Config.TriangleDistFromCenter + Config.TriangleHeight)

    local vp = State.Camera.ViewportSize
    local center = vp / 2

    el.ArrowTriangle.PointA = SnapV2(center - baseL)
    el.ArrowTriangle.PointB = SnapV2(center - baseR)
    el.ArrowTriangle.PointC = SnapV2(center - tip)
    el.ArrowTriangle.Filled = Config.TriangleFilled
    el.ArrowTriangle.Thickness = Config.TriangleThickness
    el.ArrowTriangle.Color = color
    el.ArrowTriangle.Transparency = 1 - Config.TriangleTransparency
    el.ArrowTriangle.Visible = true
end

local function Refresh(el)
    local obj = el.Object
    if not obj or not obj:IsDescendantOf(game) then
        el:Leave()
        return
    end

    local pos = obj:GetPivot().Position
    local screen, onScreen = State.Camera:WorldToViewportPoint(pos)
    local dist = (State.Camera.CFrame.Position - pos).Magnitude

    if Config.MaxDistance > 0 and dist > Config.MaxDistance then
        onScreen = false
    end

    if not onScreen then
        if el.Highlight then el.Highlight.Enabled = false end
        el.LabelFrame.Visible = false
        el.Tracer.Visible = false
        el.ArrowImage.Visible = false
        if el.ArrowTriangle then el.ArrowTriangle.Visible = false end
        el.Visible = false
        return
    end

    el.Visible = true
    local color = Config.Rainbow and State.RainbowColor or el.Color

    el.Highlight.Enabled = true
    el.Highlight.FillColor = color
    el.Highlight.OutlineColor = Config.MatchColors and color or Config.OutlineColor
    if el.Active then
        el.Highlight.FillTransparency = Config.FillTransparency
        el.Highlight.OutlineTransparency = Config.OutlineTransparency
    end

    el.LabelFrame.Visible = true
    el.LabelFrame.Position = UDim2.fromOffset(screen.X, screen.Y)
    el.Label.TextColor3 = color
    el.Label.TextSize = Config.TextSize
    el.Label.Font = Config.Font
    if el.Active then
        el.Label.TextTransparency = Config.TextTransparency
        el.Label.TextStrokeTransparency = Config.TextStrokeTransparency
    end
    if Config.ShowDistance then
        local s = math.round(Config.TextSize * Config.DistanceSizeRatio)
        el.Label.Text = string.format(
            '%s\n<font size="%d">[%d%s]</font>',
            el.Text, s, math.floor(dist), Config.DistanceSuffix
        )
    else
        el.Label.Text = el.Text
    end

    if Config.Tracers then
        local vp = State.Camera.ViewportSize
        local origin = AnchorFor(Config.TracerAnchor, vp)
        local dest = Vector2.new(screen.X, screen.Y)
        local mid = (origin + dest) / 2
        local len = (origin - dest).Magnitude
        local ang = math.deg(math.atan2(dest.Y - origin.Y, dest.X - origin.X))

        el.Tracer.Position = UDim2.fromOffset(mid.X, mid.Y)
        el.Tracer.Size = UDim2.new(0, len, 0, 1)
        el.Tracer.Rotation = ang
        el.Tracer.BackgroundColor3 = color
        el.Tracer.BorderSizePixel = 0
        el.Tracer.Visible = true
        el.TracerStroke.Color = color
        el.TracerStroke.Thickness = Config.TracerThickness
    else
        el.Tracer.Visible = false
    end

    if Config.Arrows then
        if Config.ArrowStyle == "Triangle" and el.ArrowTriangle then
            el.ArrowImage.Visible = false
            RefreshArrowTriangle(el, pos, color)
        else
            if el.ArrowTriangle then el.ArrowTriangle.Visible = false end
            RefreshArrowImage(el, screen, pos, color)
        end
    else
        el.ArrowImage.Visible = false
        if el.ArrowTriangle then el.ArrowTriangle.Visible = false end
    end
end

local accumulator = 0
local RenderConnection
RenderConnection = RunService.Heartbeat:Connect(function(dt)
    if State.Unloaded then return end

    accumulator = accumulator + dt
    if accumulator < 1 / Config.RenderRate then return end
    accumulator = 0

    for _, el in pairs(State.Elements) do
        if el.Active then
            Refresh(el)
        end
    end
end)

local hueAccum = 0
local RainbowConnection = RunService.RenderStepped:Connect(function(dt)
    hueAccum = hueAccum + dt
    if hueAccum < 1 / 60 then return end
    hueAccum = 0
    State.Hue = (State.Hue + 1 / 400) % 1
    State.RainbowColor = Color3.fromHSV(State.Hue, 0.8, 1)
end)

local CameraConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    State.Camera = Workspace.CurrentCamera
end)

local API = {}
API.Config = Config
API.Anchors = Anchors

function API:Add(object, text, color)
    if State.Unloaded then return end
    if not object then return end
    if not (object:IsA("BasePart") or object:IsA("Model")) then return end
    if State.Elements[object] then return State.Elements[object] end

    local el = Element.new(
        object,
        text or object.Name,
        color or Color3.fromRGB(255, 255, 255)
    )
    State.Elements[object] = el
    return el
end

function API:Remove(object)
    local el = State.Elements[object]
    if not el then return end
    el:Leave()
end

function API:Update(object, text, color)
    local el = State.Elements[object]
    if not el then return end
    if text ~= nil then el.Text = text end
    if color ~= nil then el.Color = color end
end

function API:SetTextSize(n) Config.TextSize = n end
function API:SetFont(f) Config.Font = f end
function API:SetTextTransparency(n) Config.TextTransparency = n end
function API:SetTextStrokeTransparency(n) Config.TextStrokeTransparency = n end
function API:SetFillTransparency(n) Config.FillTransparency = n end
function API:SetOutlineTransparency(n) Config.OutlineTransparency = n end
function API:SetOutlineColor(c) Config.OutlineColor = c end
function API:SetMatchColors(v) Config.MatchColors = v end
function API:SetRainbow(v) Config.Rainbow = v end

function API:SetTracers(v)
    Config.Tracers = v
    TracerLayer.Visible = v
end

function API:SetTracerAnchor(a) Config.TracerAnchor = a end
function API:SetTracerThickness(n) Config.TracerThickness = n end

function API:SetArrows(v)
    Config.Arrows = v
    ArrowLayer.Visible = v
end

function API:SetArrowStyle(s)
    Config.ArrowStyle = s
    if s == "Triangle" then
        ArrowLayer.Visible = false
    elseif Config.Arrows then
        ArrowLayer.Visible = true
    end
end

function API:SetArrowRadius(n) Config.ArrowRadius = n end

function API:SetTriangleDistFromCenter(n) Config.TriangleDistFromCenter = n end
function API:SetTriangleHeight(n) Config.TriangleHeight = n end
function API:SetTriangleWidth(n) Config.TriangleWidth = n end
function API:SetTriangleFilled(v) Config.TriangleFilled = v end
function API:SetTriangleTransparency(n) Config.TriangleTransparency = n end
function API:SetTriangleThickness(n) Config.TriangleThickness = n end
function API:SetTriangleColor(c) Config.TriangleColor = c end
function API:SetTriangleAntiAliasing(v) Config.TriangleAntiAliasing = v end

function API:SetShowDistance(v) Config.ShowDistance = v end
function API:SetDistanceSuffix(s) Config.DistanceSuffix = s end
function API:SetDistanceSizeRatio(n) Config.DistanceSizeRatio = n end
function API:SetMaxDistance(n) Config.MaxDistance = n end
function API:SetFadeTime(n) Config.FadeTime = n end
function API:SetRenderRate(n) Config.RenderRate = n end

function API:Unload()
    if State.Unloaded then return end
    State.Unloaded = true

    for _, el in pairs(State.Elements) do
        el:Destroy()
    end
    State.Elements = {}

    RenderConnection:Disconnect()
    RainbowConnection:Disconnect()
    CameraConnection:Disconnect()

    Gui.Enabled = false
end

if getgenv then
    getgenv().ESP = API
end

return API
