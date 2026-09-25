if not shared.nkit then
    shared.nkit = { styles = {} }
end

local tween = game:GetService("TweenService")
local players = game:GetService("Players")
local startercore = game:GetService("StarterGui")
local me = players.LocalPlayer

local lib = shared.nkit
local stylemap = lib.styles

local base = {
    sound = {
        main  = "rbxassetid://4590657391",
        soft  = "rbxassetid://8784885431",
        extra = "rbxassetid://10469938989",
    },
    icon = {
        main  = "rbxassetid://6023426923",
        soft  = "rbxassetid://3944668821",
        halo  = "rbxassetid://61997378",
    },
    color = {
        warm = Color3.fromRGB(255, 222, 189),
        pure = Color3.fromRGB(255, 255, 255),
    },
}

local assetSound = {
    link = "https://github.com/Msdoors/Msdoors.gg/raw/refs/heads/main/Scripts/Msdoors/Notification/DOORS-ACHIEVIMENT.mp3",
    save = "nkit/audio_extra.mp3",
}

local cache = {
    sound = {},
    icon  = {},
    ready = false,
}

local function assetloader()
    return getcustomasset or getsynasset
end

local function ensuredirs()
    if cache.ready then return end
    cache.ready = true
    for _, d in ipairs({ "nkit", "nkit/a", "nkit/i" }) do
        if not isfolder(d) then makefolder(d) end
    end
end

local function fingerprint(str)
    local n = 5381
    for i = 1, #str do
        n = (n * 33 + string.byte(str, i)) % 2147483647
    end
    return ("%x"):format(n)
end

local function fetch(url, path)
    ensuredirs()
    local load = assetloader()
    if isfile(path) then
        local ok, v = pcall(load, path)
        return ok and v or nil
    end
    local ok, body = pcall(game.HttpGet, game, url)
    if not ok or not body then return nil end
    if not pcall(writefile, path, body) then return nil end
    local ok2, v = pcall(load, path)
    return ok2 and v or nil
end

local function resound(v, fallback)
    if not v or v == "" then return fallback end
    if cache.sound[v] then return cache.sound[v] end
    local out
    if v:sub(1, 13) == "rbxassetid://" then
        out = v
    elseif v:match("^%d+$") then
        out = "rbxassetid://" .. v
    elseif v:match("^https?://") then
        out = fetch(v, "nkit/a/" .. fingerprint(v) .. ".bin") or fallback
    else
        out = fallback
    end
    cache.sound[v] = out
    return out
end

local function resimage(v)
    if not v or v == "" then return "" end
    if cache.icon[v] then return cache.icon[v] end
    local out = ""
    if v:sub(1, 13) == "rbxassetid://" then
        out = v
    elseif v:match("^%d+$") then
        out = "rbxassetid://" .. v
    elseif v:match("^https?://") then
        out = fetch(v, "nkit/i/" .. fingerprint(v) .. ".bin") or ""
    end
    cache.icon[v] = out
    return out
end

local function playsound(host, id, vol)
    if not id or id == "" then return end
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = vol or 1
    s.Parent = host
    task.delay(0.05, function()
        if s.Parent then s:Play() end
    end)
    s.Ended:Once(function()
        if s.Parent then s:Destroy() end
    end)
end

local function makescreen(name)
    local pg = me:FindFirstChildOfClass("PlayerGui") or me:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild(name)
    if old then old:Destroy() end
    local g = Instance.new("ScreenGui")
    g.Name = name
    g.ResetOnSpawn = false
    g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    g.IgnoreGuiInset = true
    g.Parent = pg
    return g
end

local function round(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r or 8)
    c.Parent = obj
    return c
end

local function border(obj, col, thick, trans)
    local s = Instance.new("UIStroke")
    s.Color = col or base.color.pure
    s.Thickness = thick or 2
    s.Transparency = trans or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

local function glide(obj, props, dur, style, dir)
    tween:Create(
        obj,
        TweenInfo.new(dur or 0.35, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local panel = {
    root = nil,
    entries = {},
    w = 340,
    h = 78,
    gap = 10,
    cap = 6,
    pad = 16,
}

local function panelroot()
    if panel.root and panel.root.Parent then return panel.root end
    local g = makescreen("NkitPanel")
    local r = Instance.new("Frame")
    r.Name = "Root"
    r.AnchorPoint = Vector2.new(1, 0)
    r.Position = UDim2.new(1, -panel.pad, 0, panel.pad)
    r.Size = UDim2.new(0, panel.w, 1, -panel.pad * 2)
    r.BackgroundTransparency = 1
    r.Parent = g
    panel.root = r
    return r
end

local function panelsort()
    for i, it in ipairs(panel.entries) do
        local y = (i - 1) * (panel.h + panel.gap)
        it.y = y
        glide(it.frame, { Position = UDim2.new(0, 0, 0, y) }, i == 1 and 0.5 or 0.35, Enum.EasingStyle.Quart)
    end
end

local function paneldrop(it)
    for i, v in ipairs(panel.entries) do
        if v == it then
            table.remove(panel.entries, i)
            break
        end
    end
    local ti = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    tween:Create(it.frame, ti, {
        Position = UDim2.new(0, panel.w + 50, 0, it.y or 0),
        BackgroundTransparency = 1,
    }):Play()
    for _, o in ipairs(it.frame:GetDescendants()) do
        if o:IsA("TextLabel") then
            tween:Create(o, ti, { TextTransparency = 1 }):Play()
        elseif o:IsA("ImageLabel") then
            tween:Create(o, ti, { ImageTransparency = 1 }):Play()
        elseif o:IsA("Frame") and o.Name ~= "Bar" then
            tween:Create(o, ti, { BackgroundTransparency = 1 }):Play()
        end
    end
    task.delay(0.4, function()
        if it.frame and it.frame.Parent then it.frame:Destroy() end
    end)
    panelsort()
end

local function panelpush(o)
    local host = panelroot()
    local accent = o.Color or base.color.pure
    local surface = o.BackgroundColor or Color3.fromRGB(20, 20, 26)
    local ink = o.FontColor or Color3.fromRGB(245, 245, 245)
    local subink = o.DescriptionColor or Color3.fromRGB(170, 170, 180)
    local alive = o.Time or 5

    while #panel.entries >= panel.cap do
        paneldrop(panel.entries[#panel.entries])
    end

    local it = { y = 0 }

    local card = Instance.new("Frame")
    it.frame = card
    card.Name = "Panel"
    card.Size = UDim2.new(0, panel.w, 0, panel.h)
    card.Position = UDim2.new(0, panel.w + 50, 0, 0)
    card.BackgroundColor3 = surface
    card.BackgroundTransparency = 0.08
    card.BorderSizePixel = 0
    card.Parent = host
    round(card, 12)
    border(card, accent, 1, 0.6)

    local rail = Instance.new("Frame")
    rail.Name = "Edge"
    rail.Size = UDim2.new(0, 4, 1, -20)
    rail.Position = UDim2.new(0, 0, 0, 10)
    rail.BackgroundColor3 = accent
    rail.BorderSizePixel = 0
    rail.Parent = card
    round(rail, UDim.new(1, 0))

    local badge = Instance.new("ImageLabel")
    badge.Name = "Badge"
    badge.Size = UDim2.new(0, 44, 0, 44)
    badge.Position = UDim2.new(0, 16, 0.5, -22)
    badge.BackgroundTransparency = 1
    local im = resimage(o.Image or "")
    badge.Image = im ~= "" and im or base.icon.main
    badge.ImageColor3 = o.IconColor or Color3.fromRGB(255, 255, 255)
    badge.ScaleType = Enum.ScaleType.Fit
    badge.Parent = card

    local head = Instance.new("TextLabel")
    head.Name = "Head"
    head.BackgroundTransparency = 1
    head.Position = UDim2.new(0, 72, 0, 12)
    head.Size = UDim2.new(1, -86, 0, 20)
    head.Font = Enum.Font.GothamBold
    head.TextSize = 15
    head.TextColor3 = ink
    head.TextXAlignment = Enum.TextXAlignment.Left
    head.Text = o.Title or "Notification"
    head.TextTruncate = Enum.TextTruncate.AtEnd
    head.Parent = card

    local note = Instance.new("TextLabel")
    note.Name = "Note"
    note.BackgroundTransparency = 1
    note.Position = UDim2.new(0, 72, 0, 34)
    note.Size = UDim2.new(1, -86, 0, 30)
    note.Font = Enum.Font.Gotham
    note.TextSize = 13
    note.TextColor3 = subink
    note.TextXAlignment = Enum.TextXAlignment.Left
    note.TextYAlignment = Enum.TextYAlignment.Top
    note.TextWrapped = true
    note.Text = o.Description or o.Reason or ""
    note.Parent = card

    local track = Instance.new("Frame")
    track.Name = "Bar"
    track.Size = UDim2.new(1, -16, 0, 3)
    track.Position = UDim2.new(0, 8, 1, -6)
    track.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
    track.BackgroundTransparency = 0.5
    track.BorderSizePixel = 0
    track.Parent = card
    round(track, UDim.new(1, 0))

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    round(fill, UDim.new(1, 0))

    playsound(card, resound(o.Sound, base.sound.main), o.Volume or 0.5)

    table.insert(panel.entries, 1, it)
    panelsort()

    glide(fill, { Size = UDim2.new(0, 0, 1, 0) }, alive, Enum.EasingStyle.Linear)

    task.delay(alive, function()
        if it.frame and it.frame.Parent then
            paneldrop(it)
        end
    end)
end

local wave = { root = nil, step = 60 }

local function waveroot()
    if wave.root and wave.root.Parent then return wave.root end
    local g = makescreen("NkitWave")
    local r = Instance.new("Frame")
    r.Name = "Root"
    r.Size = UDim2.new(1, 0, 1, 0)
    r.BackgroundTransparency = 1
    r.Parent = g
    wave.root = r
    return r
end

local function wavepush(o)
    task.spawn(function()
        local host = waveroot()
        local accent = o.Color or base.color.pure
        local surface = o.BackgroundColor or Color3.fromRGB(30, 30, 35)
        local ink = o.FontColor or Color3.fromRGB(240, 240, 240)
        local alive = o.Time or 5

        for _, c in ipairs(host:GetChildren()) do
            if c.Name == "Slot" then
                local ly = (c:GetAttribute("ly") or 60) + wave.step
                c:SetAttribute("ly", ly)
                glide(c, { Position = UDim2.new(1, -370, 0, ly) }, 0.4, Enum.EasingStyle.Exponential)
            end
        end

        local card = Instance.new("Frame")
        card.Name = "Slot"
        card.BackgroundColor3 = surface
        card.BackgroundTransparency = 0.4
        card.BorderSizePixel = 0
        card.Position = UDim2.new(1, 5, 0, 60)
        card.Size = UDim2.new(0, 420, 0, 50)
        card:SetAttribute("ly", 60)
        card.Parent = host
        round(card, 4)

        local rule = Instance.new("Frame")
        rule.Name = "Rule"
        rule.BackgroundColor3 = accent
        rule.BorderSizePixel = 0
        rule.Position = UDim2.new(0, 0, 1, -3)
        rule.Size = UDim2.new(0, 0, 0, 3)
        rule.Parent = card

        local sigil = Instance.new("ImageLabel")
        sigil.Name = "Sigil"
        sigil.BackgroundTransparency = 1
        sigil.Position = UDim2.new(0, 10, 0, 5)
        sigil.Size = UDim2.new(0, 40, 0, 40)
        local im = resimage(o.Image or "")
        sigil.Image = im ~= "" and im or base.icon.soft
        sigil.ImageColor3 = accent
        sigil.ScaleType = Enum.ScaleType.Fit
        sigil.Parent = card
        round(sigil, UDim.new(1, 0))

        local head = Instance.new("TextLabel")
        head.Name = "Head"
        head.BackgroundTransparency = 1
        head.Position = UDim2.new(0, 60, 0.155, 0)
        head.Size = UDim2.new(0, 205, 0, 15)
        head.Text = o.Title or "..."
        head.TextColor3 = ink
        head.TextSize = 10
        head.TextStrokeTransparency = 0.75
        head.TextXAlignment = Enum.TextXAlignment.Left
        head.Parent = card

        local note = Instance.new("TextLabel")
        note.Name = "Note"
        note.BackgroundTransparency = 1
        note.Position = UDim2.new(0, 60, 0.483, 0)
        note.Size = UDim2.new(0, 205, 0, 18)
        note.Text = o.Description or o.Reason or "..."
        note.TextColor3 = ink
        note.TextTransparency = 0.1
        note.TextSize = 10
        note.TextStrokeTransparency = 0.75
        note.TextXAlignment = Enum.TextXAlignment.Left
        note.Parent = card

        playsound(host, resound(o.Sound, base.sound.soft), 3)

        glide(card, { Position = UDim2.new(1, -370, 0, 60) }, 1, Enum.EasingStyle.Exponential)

        task.wait(0.25)
        glide(rule, { Size = UDim2.new(0, 400, 0, 3) }, math.max(alive - 0.25, 0.1), Enum.EasingStyle.Linear)
        task.wait(math.max(alive - 0.25, 0.1))

        local my = card:GetAttribute("ly") or 60
        glide(card, { Position = UDim2.new(1, 5, 0, my) }, 0.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)

        task.wait(0.75)
        if card.Parent then card:Destroy() end

        for _, c in ipairs(host:GetChildren()) do
            if c.Name == "Slot" then
                local ly = c:GetAttribute("ly") or 60
                if ly > my then
                    local ny = ly - wave.step
                    c:SetAttribute("ly", ny)
                    glide(c, { Position = UDim2.new(1, -370, 0, ny) }, 0.4, Enum.EasingStyle.Exponential)
                end
            end
        end
    end)
end

local trophy = {
    root = nil,
    queue = {},
    busy = false,
    soundCache = nil,
}

local function trophysound()
    if trophy.soundCache then return trophy.soundCache end
    trophy.soundCache = fetch(assetSound.link, assetSound.save) or base.sound.extra
    return trophy.soundCache
end

local function trophyroot()
    if trophy.root and trophy.root.Parent then return trophy.root end
    local g = makescreen("NkitTrophy")
    local holder = Instance.new("Frame")
    holder.Name = "Holder"
    holder.Size = UDim2.new(1, 0, 1, 0)
    holder.BackgroundTransparency = 1
    holder.Parent = g

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 25)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.HorizontalAlignment = Enum.HorizontalAlignment.Right
    list.VerticalAlignment = Enum.VerticalAlignment.Top
    list.Parent = holder

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 15)
    pad.PaddingRight = UDim.new(0, 15)
    pad.Parent = holder

    trophy.root = holder
    return holder
end

local function trophycard()
    local wrap = Instance.new("Frame")
    wrap.Name = "Wrap"
    wrap.Size = UDim2.new(0.28, 0, 0.11, 0)
    wrap.Position = UDim2.new(1.2, 0, 0, 0)
    wrap.AnchorPoint = Vector2.new(1, 0)
    wrap.BackgroundTransparency = 1
    wrap.ZIndex = 2000

    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Size = UDim2.new(1, 0, 1, 0)
    body.Position = UDim2.new(1.1, 0, 0, 0)
    body.BackgroundColor3 = Color3.fromRGB(38, 25, 25)
    body.BackgroundTransparency = 0.25
    body.BorderSizePixel = 0
    body.ZIndex = 2000
    body.Parent = wrap
    round(body, 10)
    border(body, base.color.warm, 3)

    local halo = Instance.new("ImageLabel")
    halo.Name = "Halo"
    halo.Size = UDim2.new(2, 0, 4, 0)
    halo.Position = UDim2.new(-0.5, 0, 0.5, 0)
    halo.AnchorPoint = Vector2.new(0, 0.5)
    halo.Image = base.icon.halo
    halo.ImageColor3 = base.color.warm
    halo.BackgroundTransparency = 1
    halo.ZIndex = 1999
    halo.Parent = wrap

    local top = Instance.new("TextLabel")
    top.Name = "Top"
    top.Size = UDim2.new(1, -10, 0.22, 0)
    top.Position = UDim2.new(0, 5, -0.35, 0)
    top.BackgroundTransparency = 1
    top.Text = "UNLOCKED"
    top.TextColor3 = base.color.warm
    top.TextScaled = true
    top.Font = Enum.Font.FredokaOne
    top.ZIndex = 2001
    top.TextTruncate = Enum.TextTruncate.AtEnd
    top.Parent = body

    local badge = Instance.new("ImageLabel")
    badge.Name = "Badge"
    badge.Size = UDim2.new(0.2, 0, 0.85, 0)
    badge.Position = UDim2.new(0.03, 0, 0.075, 0)
    badge.BackgroundTransparency = 1
    badge.ScaleType = Enum.ScaleType.Fit
    badge.ZIndex = 2001
    badge.Parent = body

    local info = Instance.new("Frame")
    info.Name = "Info"
    info.Size = UDim2.new(0.73, 0, 0.95, 0)
    info.Position = UDim2.new(0.25, 0, 0.025, 0)
    info.BackgroundTransparency = 1
    info.ZIndex = 2001
    info.Parent = body

    local stack = Instance.new("UIListLayout")
    stack.Padding = UDim.new(0, 2)
    stack.SortOrder = Enum.SortOrder.LayoutOrder
    stack.Parent = info

    local fields = {
        { "Head",   0.38, Color3.fromRGB(255, 222, 189), Enum.Font.GothamBlack,  20, 1 },
        { "Note",   0.28, Color3.fromRGB(221, 180, 151), Enum.Font.GothamMedium, 14, 2 },
        { "Reason", 0.28, Color3.fromRGB(200, 165, 140), Enum.Font.Gotham,       13, 3 },
    }
    for _, f in ipairs(fields) do
        local l = Instance.new("TextLabel")
        l.Name = f[1]
        l.Size = UDim2.new(1, 0, f[2], 0)
        l.BackgroundTransparency = 1
        l.TextColor3 = f[3]
        l.TextWrapped = true
        l.Font = f[4]
        l.TextSize = f[5]
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextYAlignment = Enum.TextYAlignment.Top
        l.ZIndex = 2001
        l.LayoutOrder = f[6]
        l.TextTruncate = Enum.TextTruncate.AtEnd
        l.Parent = info
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 5)
        if f[6] == 1 then pad.PaddingTop = UDim.new(0, 3) end
        pad.Parent = l
    end

    return wrap
end

local function trophypush(o)
    local host = trophyroot()
    local card = trophycard()
    card.Parent = host
    card.LayoutOrder = tick()

    card.Body.Top.Text = o.Style or "UNLOCKED"
    card.Body.Info.Head.Text = o.Title or "Achievement"
    card.Body.Info.Note.Text = o.Description or ""
    card.Body.Info.Reason.Text = o.Reason or ""
    local im = resimage(o.Image or "")
    card.Body.Badge.Image = im ~= "" and im or base.icon.main

    local col = o.Color or base.color.warm
    card.Body.Top.TextColor3 = col
    card.Body.UIStroke.Color = col
    card.Halo.ImageColor3 = col

    playsound(card, resound(o.Sound, trophysound()), 0.575)

    card.Body:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Sine", 0.8, true)
    glide(card.Halo, { ImageTransparency = 1 }, 2, Enum.EasingStyle.Sine)

    task.spawn(function()
        task.wait(o.Time or 5)
        card.Body:TweenPosition(UDim2.new(1.1, 0, 0, 0), "In", "Sine", 0.6, true)
        task.wait(0.6)
        if card.Parent then card:Destroy() end
    end)
end

local function trophytick()
    if trophy.busy then return end
    trophy.busy = true
    while #trophy.queue > 0 do
        trophypush(table.remove(trophy.queue, 1))
        task.wait(0.35)
    end
    trophy.busy = false
end

local function trophypush_async(o)
    trophyroot()
    table.insert(trophy.queue, o)
    trophytick()
end

local native = {
    root   = nil,
    width  = 460,
    height = 110,
    gap    = 12,
    pad    = 20,
}

local function nativeroot()
    if native.root and native.root.Parent then return native.root end
    local g = makescreen("NkitNative")

    local holder = Instance.new("Frame")
    holder.Name = "Holder"
    holder.BackgroundTransparency = 1
    holder.AnchorPoint = Vector2.new(1, 0)
    holder.Position = UDim2.new(1, -native.pad, 0, native.pad)
    holder.Size = UDim2.new(0, native.width, 1, -native.pad * 2)
    holder.Parent = g

    local cam = workspace.CurrentCamera
    local scale = Instance.new("UIScale")
    scale.Scale = math.clamp(cam.ViewportSize.X / 1280, 0.65, 1)
    scale.Parent = holder

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, native.gap)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.HorizontalAlignment = Enum.HorizontalAlignment.Right
    list.VerticalAlignment = Enum.VerticalAlignment.Top
    list.Parent = holder

    native.root = holder
    return holder
end

local function nativecard(o)
    local col     = o.Color or base.color.pure
    local surface = o.BackgroundColor or Color3.fromRGB(22, 22, 28)
    local ink     = o.FontColor or Color3.fromRGB(245, 245, 245)
    local subink  = o.DescriptionColor or Color3.fromRGB(170, 170, 180)

    local card = Instance.new("Frame")
    card.Name = "Native"
    card.BackgroundTransparency = 1
    card.Size = UDim2.new(1, 0, 0, 0)
    card.ClipsDescendants = true
    card.LayoutOrder = math.floor(tick() * 1000) % 100000
    card.Parent = nativeroot()

    local body = Instance.new("Frame")
    body.Name = "Frame"
    body.Size = UDim2.new(1, 0, 0, native.height)
    body.Position = UDim2.new(1.1, 0, 0, 0)
    body.BackgroundColor3 = surface
    body.BackgroundTransparency = 0.12
    body.BorderSizePixel = 0
    body.Parent = card
    round(body, 10)
    border(body, col, 2, 0.35)

    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.BackgroundTransparency = 1
    glow.Image = base.icon.halo
    glow.ImageColor3 = col
    glow.ImageTransparency = 0.35
    glow.Size = UDim2.new(1.4, 0, 3, 0)
    glow.Position = UDim2.new(-0.2, 0, 0.5, 0)
    glow.AnchorPoint = Vector2.new(0, 0.5)
    glow.ZIndex = 0
    glow.Parent = body

    local icon = Instance.new("ImageLabel")
    icon.Name = "ImageLabel"
    icon.BackgroundTransparency = 1
    icon.Position = UDim2.new(0, 16, 0.5, -32)
    icon.Size = UDim2.new(0, 64, 0, 64)
    icon.ScaleType = Enum.ScaleType.Fit
    local im = resimage(o.Image or "")
    icon.Image = im ~= "" and im or base.icon.main
    icon.ImageColor3 = o.IconColor or Color3.new(1, 1, 1)
    icon.Parent = body

    local tag = Instance.new("TextLabel")
    tag.Name = "TextLabel"
    tag.BackgroundTransparency = 1
    tag.Position = UDim2.new(0, 96, 0, 12)
    tag.Size = UDim2.new(1, -112, 0, 14)
    tag.Font = Enum.Font.GothamBold
    tag.TextSize = 12
    tag.TextColor3 = col
    tag.TextXAlignment = Enum.TextXAlignment.Left
    tag.Text = o.Style or "NOTIFICATION"
    tag.TextTruncate = Enum.TextTruncate.AtEnd
    tag.Parent = body

    local details = Instance.new("Frame")
    details.Name = "Details"
    details.BackgroundTransparency = 1
    details.Position = UDim2.new(0, 96, 0, 30)
    details.Size = UDim2.new(1, -112, 0, 70)
    details.Parent = body

    local function field(name, y, h, size, color, font)
        local l = Instance.new("TextLabel")
        l.Name = name
        l.BackgroundTransparency = 1
        l.Position = UDim2.new(0, 0, 0, y)
        l.Size = UDim2.new(1, 0, 0, h)
        l.Font = font
        l.TextSize = size
        l.TextColor3 = color
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextYAlignment = Enum.TextYAlignment.Top
        l.TextWrapped = true
        l.TextTruncate = Enum.TextTruncate.AtEnd
        l.Parent = details
        return l
    end

    field("Title",  0,  24, 18, ink,    Enum.Font.GothamBold).Text   = o.Title or "Achievement"
    field("Desc",  26,  20, 14, subink, Enum.Font.GothamMedium).Text = o.Description or ""
    field("Reason",46,  20, 12, subink, Enum.Font.Gotham).Text       = o.Reason or ""

    return card, body, glow
end

local function dispatch_native(o)
    local card, body, glow = nativecard(o)

    playsound(card, resound(o.Sound, base.sound.extra), 1)

    glide(card, { Size = UDim2.new(1, 0, 0, native.height) }, 0.8,
        Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    glide(body, { Position = UDim2.new(0, 0, 0, 0) }, 0.5,
        Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    glide(glow, { ImageTransparency = 1 }, 1.2,
        Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    task.delay(o.Time or 5, function()
        glide(body, { Position = UDim2.new(1.1, 0, 0, 0) }, 0.5,
            Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.wait(0.5)
        glide(card, { Size = UDim2.new(1, 0, 0, 0) }, 0.5,
            Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        task.wait(0.55)
        if card.Parent then card:Destroy() end
    end)
end

local function dispatch_console(o)
    if not (Library and Library.Notify) then
        warn("[nkit] Library is not initialized")
        return
    end
    playsound(game.Workspace, resound(o.Sound, base.sound.main), 1)
    Library:Notify({
        Title = o.Title or "No Title",
        Description = o.Description or "No Description",
        Time = o.Time or 5,
    })
end

local function dispatch_system(o)
    playsound(game.Workspace, resound(o.Sound, base.sound.main), 1)
    startercore:SetCore("SendNotification", {
        Title = o.Title or "Notification",
        Text = o.Description or o.Reason or "",
        Icon = o.Image or "",
        Duration = o.Time or 5,
        Callback = o.Callback or nil,
        Button1 = o.Button1 or nil,
        Button2 = o.Button2 or nil,
    })
end

stylemap.Panel   = panelpush
stylemap.Toast   = panelpush
stylemap.Alert   = wavepush
stylemap.Trophy  = trophypush_async
stylemap.Native  = dispatch_native
stylemap.Console = dispatch_console
stylemap.System  = dispatch_system

local function tidy(o)
    o = o or {}
    if not o.Time then o.Time = o.Duration end
    if not o.Reason then o.Reason = o.Action end
    if not o.Sound then o.Sound = o.SoundId or o.soundpar end
    return o
end

local function dispatch(style, o)
    o = tidy(o)
    local fn = stylemap[style]
    if fn then
        fn(o)
    else
        warn("[nkit] Unknown style: " .. tostring(style))
    end
end

local function notify(style, o)
    if type(style) == "table" and o == nil then
        dispatch(style.NotifyStyle or "Panel", style)
    else
        dispatch(style, o or {})
    end
end

shared.nkit.Notify = notify
shared.nkit.Styles = stylemap

if getgenv then
    getgenv().nkit = notify
end

return notify
