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

    ESPStyle = "Highlight",
    BoxThickness = 1,
    BoxTransparency = 0,
    BoxColor = Color3.fromRGB(255, 255, 255),
    UseElementColorForBox = true,
    CornerLength = 10,
    Box3DThickness = 1,
    Box3DTransparency = 0.5,
    Box3DColor = Color3.fromRGB(255, 255, 255),

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
    ShowName = true,
    ShowHealth = false,
    ShowHealthBar = false,
    HealthBarWidth = 2,
    DynamicHealthColor = true,

    Skeleton = false,
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    SkeletonThickness = 1,
    SkeletonTransparency = 0.2,

    TeamCheck = false,
    VisibleCheck = false,
    AliveCheck = true,
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
local BoxBucket = Folder(Gui)
local Box3DBucket = Folder(Gui)
local LabelBucket = Folder(Gui)
local HealthBarBucket = Folder(Gui)

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

local function HealthColor(humanoid)
    if not humanoid then return Color3.fromRGB(0, 255, 0) end
    local ratio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
    local r = (1 - ratio) * 255
    local g = ratio * 255
    return Color3.fromRGB(math.floor(r), math.floor(g), 0)
end

local function GetCharacterParts(character)
    if not character then return nil end
    return {
        Head = character:FindFirstChild("Head"),
        UpperTorso = character:FindFirstChild("UpperTorso"),
        LowerTorso = character:FindFirstChild("LowerTorso"),
        Torso = character:FindFirstChild("Torso"),
        HumanoidRootPart = character:FindFirstChild("HumanoidRootPart"),
        LeftUpperArm = character:FindFirstChild("LeftUpperArm"),
        LeftLowerArm = character:FindFirstChild("LeftLowerArm"),
        LeftHand = character:FindFirstChild("LeftHand"),
        RightUpperArm = character:FindFirstChild("RightUpperArm"),
        RightLowerArm = character:FindFirstChild("RightLowerArm"),
        RightHand = character:FindFirstChild("RightHand"),
        LeftUpperLeg = character:FindFirstChild("LeftUpperLeg"),
        LeftLowerLeg = character:FindFirstChild("LeftLowerLeg"),
        LeftFoot = character:FindFirstChild("LeftFoot"),
        RightUpperLeg = character:FindFirstChild("RightUpperLeg"),
        RightLowerLeg = character:FindFirstChild("RightLowerLeg"),
        RightFoot = character:FindFirstChild("RightFoot"),
        ["Left Arm"] = character:FindFirstChild("Left Arm"),
        ["Right Arm"] = character:FindFirstChild("Right Arm"),
        ["Left Leg"] = character:FindFirstChild("Left Leg"),
        ["Right Leg"] = character:FindFirstChild("Right Leg"),
    }
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
    self:_BuildBox()
    self:_BuildCorner()
    self:_BuildBox3D()
    self:_BuildLabel()
    self:_BuildHealthBar()
    self:_BuildTracer()
    self:_BuildArrow()
    self:_BuildSkeleton()

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
    hl.Enabled = false
    hl.Parent = HighlightBucket
    self.Highlight = hl
end

function Element:_BuildBox()
    local frame = Instance.new("Frame")
    frame.Name = Tag()
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = BoxBucket

    local function mk()
        local l = Instance.new("Frame")
        l.Name = Tag()
        l.BorderSizePixel = 0
        l.BackgroundTransparency = 1
        l.Parent = frame
        return l
    end

    self.BoxFrame = frame
    self.BoxLines = {
        Top = mk(),
        Bottom = mk(),
        Left = mk(),
        Right = mk(),
    }
end

function Element:_BuildCorner()
    local frame = Instance.new("Frame")
    frame.Name = Tag()
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = BoxBucket

    local function mk()
        local l = Instance.new("Frame")
        l.Name = Tag()
        l.BorderSizePixel = 0
        l.BackgroundTransparency = 1
        l.Parent = frame
        return l
    end

    self.CornerFrame = frame
    self.CornerLines = {
        TL_H = mk(), TL_V = mk(),
        TR_H = mk(), TR_V = mk(),
        BL_H = mk(), BL_V = mk(),
        BR_H = mk(), BR_V = mk(),
    }
end

function Element:_BuildBox3D()
    local box = Instance.new("SelectionBox")
    box.Name = Tag()
    box.Adornee = self.Object
    box.LineThickness = Config.Box3DThickness
    box.Transparency = Config.Box3DTransparency
    box.Color3 = Config.Box3DColor
    box.Visible = false
    box.Parent = Box3DBucket
    self.Box3D = box
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

function Element:_BuildHealthBar()
    local bg = Instance.new("Frame")
    bg.Name = Tag()
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.4
    bg.BorderSizePixel = 0
    bg.Visible = false
    bg.Parent = HealthBarBucket

    local fill = Instance.new("Frame")
    fill.Name = Tag()
    fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    fill.BorderSizePixel = 0
    fill.Visible = false
    fill.Parent = bg

    self.HealthBarBg = bg
    self.HealthBarFill = fill
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

function Element:_BuildSkeleton()
    local lines = {}
    local connections = {
        { "Head", "UpperTorso" },
        { "Head", "Torso" },
        { "UpperTorso", "LowerTorso" },
        { "UpperTorso", "LeftUpperArm" },
        { "LeftUpperArm", "LeftLowerArm" },
        { "LeftLowerArm", "LeftHand" },
        { "UpperTorso", "RightUpperArm" },
        { "RightUpperArm", "RightLowerArm" },
        { "RightLowerArm", "RightHand" },
        { "LowerTorso", "LeftUpperLeg" },
        { "LeftUpperLeg", "LeftLowerLeg" },
        { "LeftLowerLeg", "LeftFoot" },
        { "LowerTorso", "RightUpperLeg" },
        { "RightUpperLeg", "RightLowerLeg" },
        { "RightLowerLeg", "RightFoot" },
        { "Torso", "Left Arm" },
        { "Torso", "Right Arm" },
        { "Torso", "Left Leg" },
        { "Torso", "Right Leg" },
    }

    for _, conn in ipairs(connections) do
        local line = Instance.new("Frame")
        line.Name = Tag()
        line.BackgroundTransparency = 1
        line.BorderSizePixel = 0
        line.Visible = false
        line.Parent = BoxBucket

        local stroke = Instance.new("UIStroke")
        stroke.Name = Tag()
        stroke.Thickness = Config.SkeletonThickness
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Transparency = Config.SkeletonTransparency
        stroke.Parent = line

        table.insert(lines, { line, stroke, conn[1], conn[2] })
    end

    self.SkeletonLines = lines
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

    self.BoxFrame.Visible = false
    self.CornerFrame.Visible = false
    self.Box3D.Visible = false
    self.HealthBarBg.Visible = false
    self.HealthBarFill.Visible = false

    for _, data in ipairs(self.SkeletonLines) do
        data[1].Visible = false
    end

    task.delay(Config.FadeTime + 0.05, function()
        if not self.Active then
            self:Destroy()
        end
    end)
end

function Element:Destroy()
    if self.Highlight then self.Highlight:Destroy() end
    if self.BoxFrame then self.BoxFrame:Destroy() end
    if self.CornerFrame then self.CornerFrame:Destroy() end
    if self.Box3D then self.Box3D:Destroy() end
    if self.LabelFrame then self.LabelFrame:Destroy() end
    if self.HealthBarBg then self.HealthBarBg:Destroy() end
    if self.Tracer then self.Tracer:Destroy() end
    if self.ArrowImage then self.ArrowImage:Destroy() end
    if self.ArrowTriangle then
        pcall(function() self.ArrowTriangle:Remove() end)
        self.ArrowTriangle = nil
    end
    if self.SkeletonLines then
        for _, data in ipairs(self.SkeletonLines) do
            data[1]:Destroy()
        end
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

local function ProjectBoundingBox(obj)
    local cf, size
    if obj:IsA("Model") then
        local ok, c, s = pcall(function() return obj:GetBoundingBox() end)
        if not ok then return nil end
        cf, size = c, s
    else
        cf, size = obj.CFrame, obj.Size
    end

    local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
    local pts = {}

    for _, sx in ipairs({ -1, 1 }) do
        for _, sy in ipairs({ -1, 1 }) do
            for _, sz in ipairs({ -1, 1 }) do
                local world = (cf * CFrame.new(hx * sx, hy * sy, hz * sz)).Position
                local sp = State.Camera:WorldToViewportPoint(world)
                if sp.Z <= 0 then return nil end
                table.insert(pts, sp)
            end
        end
    end

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    for _, p in ipairs(pts) do
        if p.X < minX then minX = p.X end
        if p.Y < minY then minY = p.Y end
        if p.X > maxX then maxX = p.X end
        if p.Y > maxY then maxY = p.Y end
    end

    return minX, minY, maxX - minX, maxY - minY
end

local function ResolveBoxColor(elementColor)
    if Config.UseElementColorForBox then
        return elementColor
    end
    return Config.BoxColor
end

local function RefreshBox(el, obj, color)
    local style = Config.ESPStyle
    if style ~= "Box" and style ~= "Corner" and style ~= "Box3D" then
        el.BoxFrame.Visible = false
        el.CornerFrame.Visible = false
        el.Box3D.Visible = false
        return
    end

    if style == "Box3D" then
        el.BoxFrame.Visible = false
        el.CornerFrame.Visible = false
        el.Box3D.Visible = true
        el.Box3D.Color3 = ResolveBoxColor(color)
        el.Box3D.LineThickness = Config.Box3DThickness
        el.Box3D.Transparency = Config.Box3DTransparency
        return
    end

    el.Box3D.Visible = false

    local x, y, w, h = ProjectBoundingBox(obj)
    if not x then
        el.BoxFrame.Visible = false
        el.CornerFrame.Visible = false
        return
    end

    local t = Config.BoxThickness
    local tr = Config.BoxTransparency
    local c = ResolveBoxColor(color)

    if style == "Box" then
        el.CornerFrame.Visible = false
        el.BoxFrame.Visible = true
        el.BoxFrame.Position = UDim2.fromOffset(x, y)
        el.BoxFrame.Size = UDim2.fromOffset(w, h)

        local B = el.BoxLines

        B.Top.Position = UDim2.fromOffset(0, 0)
        B.Top.Size = UDim2.new(1, 0, 0, t)

        B.Bottom.Position = UDim2.new(0, 0, 1, -t)
        B.Bottom.Size = UDim2.new(1, 0, 0, t)

        B.Left.Position = UDim2.fromOffset(0, 0)
        B.Left.Size = UDim2.new(0, t, 1, 0)

        B.Right.Position = UDim2.new(1, -t, 0, 0)
        B.Right.Size = UDim2.new(0, t, 1, 0)

        for _, line in pairs(B) do
            line.BackgroundColor3 = c
            line.BackgroundTransparency = tr
        end
    else
        el.BoxFrame.Visible = false
        el.CornerFrame.Visible = true
        el.CornerFrame.Position = UDim2.fromOffset(x, y)
        el.CornerFrame.Size = UDim2.fromOffset(w, h)

        local cl = math.min(Config.CornerLength, w / 2, h / 2)
        local C = el.CornerLines

        local function setLine(line, pos, sz)
            line.Position = pos
            line.Size = sz
            line.BackgroundColor3 = c
            line.BackgroundTransparency = tr
        end

        setLine(C.TL_H, UDim2.fromOffset(0, 0), UDim2.fromOffset(cl, t))
        setLine(C.TL_V, UDim2.fromOffset(0, 0), UDim2.fromOffset(t, cl))

        setLine(C.TR_H, UDim2.new(1, -cl, 0, 0), UDim2.fromOffset(cl, t))
        setLine(C.TR_V, UDim2.new(1, -t, 0, 0), UDim2.fromOffset(t, cl))

        setLine(C.BL_H, UDim2.new(0, 0, 1, -t), UDim2.fromOffset(cl, t))
        setLine(C.BL_V, UDim2.new(0, 0, 1, -cl), UDim2.fromOffset(t, cl))

        setLine(C.BR_H, UDim2.new(1, -cl, 1, -t), UDim2.fromOffset(cl, t))
        setLine(C.BR_V, UDim2.new(1, -t, 1, -cl), UDim2.fromOffset(t, cl))
    end
end

local function RefreshHealthBar(el, obj)
    if not Config.ShowHealthBar then
        el.HealthBarBg.Visible = false
        el.HealthBarFill.Visible = false
        return
    end

    local humanoid = obj:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        el.HealthBarBg.Visible = false
        el.HealthBarFill.Visible = false
        return
    end

    local x, y, w, h = ProjectBoundingBox(obj)
    if not x then
        el.HealthBarBg.Visible = false
        el.HealthBarFill.Visible = false
        return
    end

    local barW = Config.HealthBarWidth
    local barH = h
    local barX = x - barW - 4
    local barY = y

    el.HealthBarBg.Visible = true
    el.HealthBarBg.Position = UDim2.fromOffset(barX, barY)
    el.HealthBarBg.Size = UDim2.fromOffset(barW, barH)

    local ratio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
    local fillH = barH * ratio

    el.HealthBarFill.Visible = true
    el.HealthBarFill.Position = UDim2.fromOffset(0, barH - fillH)
    el.HealthBarFill.Size = UDim2.fromOffset(barW, fillH)
    el.HealthBarFill.BackgroundColor3 = Config.DynamicHealthColor
        and HealthColor(humanoid)
        or Color3.fromRGB(0, 255, 0)
end

local function RefreshSkeleton(el, obj)
    if not Config.Skeleton then
        for _, data in ipairs(el.SkeletonLines) do
            data[1].Visible = false
        end
        return
    end

    local character = obj:IsA("Model") and obj or obj.Parent
    if not character or not character:IsA("Model") then
        for _, data in ipairs(el.SkeletonLines) do
            data[1].Visible = false
        end
        return
    end

    local parts = GetCharacterParts(character)
    if not parts then
        for _, data in ipairs(el.SkeletonLines) do
            data[1].Visible = false
        end
        return
    end

    local color = Config.SkeletonColor

    for _, data in ipairs(el.SkeletonLines) do
        local line, stroke, boneA, boneB = data[1], data[2], data[3], data[4]
        local partA = parts[boneA]
        local partB = parts[boneB]

        if partA and partB then
            local posA = partA.Position
            local posB = partB.Position
            local spA, onA = State.Camera:WorldToViewportPoint(posA)
            local spB, onB = State.Camera:WorldToViewportPoint(posB)

            if onA and onB and spA.Z > 0 and spB.Z > 0 then
                local screenA = Vector2.new(spA.X, spA.Y)
                local screenB = Vector2.new(spB.X, spB.Y)
                local mid = (screenA + screenB) / 2
                local len = (screenA - screenB).Magnitude
                local ang = math.deg(math.atan2(screenB.Y - screenA.Y, screenB.X - screenA.X))

                line.Position = UDim2.fromOffset(mid.X, mid.Y)
                line.Size = UDim2.new(0, len, 0, 1)
                line.Rotation = ang
                line.BackgroundColor3 = color
                line.Visible = true
                stroke.Color = color
                stroke.Thickness = Config.SkeletonThickness
                stroke.Transparency = Config.SkeletonTransparency
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
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

local function IsTeammate(obj)
    if not Config.TeamCheck then return false end
    if not obj then return false end
    local player
    if obj:IsA("Model") then
        player = Players:GetPlayerFromCharacter(obj)
    else
        player = Players:GetPlayerFromCharacter(obj.Parent)
    end
    if not player or player == LocalPlayer then return false end
    if not player.Team or not LocalPlayer.Team then return false end
    return player.Team == LocalPlayer.Team
end

local function IsVisible(obj)
    if not Config.VisibleCheck then return true end
    local character = obj:IsA("Model") and obj or obj.Parent
    if not character or not character:IsA("Model") then return true end

    local head = character:FindFirstChild("Head")
    local target = head or character.PrimaryPart
    if not target then return true end

    local origin = State.Camera.CFrame.Position
    local direction = target.Position - origin

    local filter = {}
    if LocalPlayer.Character then
        table.insert(filter, LocalPlayer.Character)
    end
    table.insert(filter, character)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = filter
    params.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction, params)
    return result == nil
end

local function IsAlive(obj)
    if not Config.AliveCheck then return true end
    local character = obj:IsA("Model") and obj or obj.Parent
    if not character or not character:IsA("Model") then return true end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return true end
    return humanoid.Health > 0
end

local function HideAll(el)
    el.Highlight.Enabled = false
    el.LabelFrame.Visible = false
    el.Tracer.Visible = false
    el.ArrowImage.Visible = false
    if el.ArrowTriangle then el.ArrowTriangle.Visible = false end
    el.BoxFrame.Visible = false
    el.CornerFrame.Visible = false
    el.Box3D.Visible = false
    el.HealthBarBg.Visible = false
    el.HealthBarFill.Visible = false
    for _, data in ipairs(el.SkeletonLines) do
        data[1].Visible = false
    end
    el.Visible = false
end

local function Refresh(el)
    local obj = el.Object
    if not obj or not obj:IsDescendantOf(game) then
        el:Leave()
        return
    end

    if IsTeammate(obj) or not IsAlive(obj) or not IsVisible(obj) then
        HideAll(el)
        return
    end

    local pos = obj:GetPivot().Position
    local screen, onScreen = State.Camera:WorldToViewportPoint(pos)
    local dist = (State.Camera.CFrame.Position - pos).Magnitude

    if Config.MaxDistance > 0 and dist > Config.MaxDistance then
        onScreen = false
    end

    if not onScreen then
        HideAll(el)
        return
    end

    el.Visible = true
    local color = Config.Rainbow and State.RainbowColor or el.Color
    local style = Config.ESPStyle

    el.Highlight.Enabled = (style == "Highlight")
    if style == "Highlight" then
        el.Highlight.FillColor = color
        el.Highlight.OutlineColor = Config.MatchColors and color or Config.OutlineColor
        if el.Active then
            el.Highlight.FillTransparency = Config.FillTransparency
            el.Highlight.OutlineTransparency = Config.OutlineTransparency
        end
    end

    RefreshBox(el, obj, color)
    RefreshHealthBar(el, obj)
    RefreshSkeleton(el, obj)

    el.LabelFrame.Visible = true
    el.LabelFrame.Position = UDim2.fromOffset(screen.X, screen.Y)
    el.Label.TextColor3 = color
    el.Label.TextSize = Config.TextSize
    el.Label.Font = Config.Font
    if el.Active then
        el.Label.TextTransparency = Config.TextTransparency
        el.Label.TextStrokeTransparency = Config.TextStrokeTransparency
    end

    local lines = {}
    if Config.ShowName then
        table.insert(lines, el.Text)
    end
    if Config.ShowHealth then
        local humanoid = obj:FindFirstChildOfClass("Humanoid")
        if humanoid then
            table.insert(lines, string.format("%d/%d", math.floor(humanoid.Health), math.floor(humanoid.MaxHealth)))
        end
    end
    if Config.ShowDistance then
        local s = math.round(Config.TextSize * Config.DistanceSizeRatio)
        table.insert(lines, string.format('<font size="%d">[%d%s]</font>', s, math.floor(dist), Config.DistanceSuffix))
    end
    el.Label.Text = table.concat(lines, "\n")

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
API.Styles = { "Highlight", "Box", "Corner", "Box3D" }

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

function API:SetESPStyle(style)
    if style ~= "Highlight" and style ~= "Box" and style ~= "Corner" and style ~= "Box3D" then return end
    Config.ESPStyle = style
end

function API:SetBoxThickness(n) Config.BoxThickness = n end
function API:SetBoxTransparency(n) Config.BoxTransparency = n end
function API:SetBoxColor(c) Config.BoxColor = c end
function API:SetUseElementColorForBox(v) Config.UseElementColorForBox = v end
function API:SetCornerLength(n) Config.CornerLength = n end
function API:SetBox3DThickness(n) Config.Box3DThickness = n end
function API:SetBox3DTransparency(n) Config.Box3DTransparency = n end
function API:SetBox3DColor(c) Config.Box3DColor = c end

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
function API:SetShowName(v) Config.ShowName = v end
function API:SetShowHealth(v) Config.ShowHealth = v end
function API:SetShowHealthBar(v) Config.ShowHealthBar = v end
function API:SetHealthBarWidth(n) Config.HealthBarWidth = n end
function API:SetDynamicHealthColor(v) Config.DynamicHealthColor = v end

function API:SetSkeleton(v) Config.Skeleton = v end
function API:SetSkeletonColor(c) Config.SkeletonColor = c end
function API:SetSkeletonThickness(n) Config.SkeletonThickness = n end
function API:SetSkeletonTransparency(n) Config.SkeletonTransparency = n end

function API:SetTeamCheck(v) Config.TeamCheck = v end
function API:SetVisibleCheck(v) Config.VisibleCheck = v end
function API:SetAliveCheck(v) Config.AliveCheck = v end

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
