local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local API_URL = "local API_URL = "https://robloxchat.vercel.app/chat"
local TOKEN = "d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d5"

local sessionId = game.JobId ~= "" and game.JobId or "STUDIO_" .. player.UserId

-- Переменные анти-спама
local cooldownTime = 5
local lastSendTick = 0

-- UI
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.ResetOnSpawn = false
screenGui.Name = "XenoChatUI"

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 300, 0, 350)
frame.Position = UDim2.new(0, 20, 0.5, -175)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

-- Заголовок
local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
titleBar.BackgroundTransparency = 0.2
titleBar.BorderSizePixel = 0

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "GLOBAL CHAT"
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16

local toggleBtn = Instance.new("TextButton", titleBar)
toggleBtn.Size = UDim2.new(0, 25, 0, 25)
toggleBtn.Position = UDim2.new(1, -30, 0, 2)
toggleBtn.Text = "−"
toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 18

local contentFrame = Instance.new("Frame", frame)
contentFrame.Size = UDim2.new(1, 0, 1, -30)
contentFrame.Position = UDim2.new(0, 0, 0, 30)
contentFrame.BackgroundTransparency = 1

local scroll = Instance.new("ScrollingFrame", contentFrame)
scroll.Size = UDim2.new(1, -10, 1, -75)
scroll.Position = UDim2.new(0, 5, 0, 5)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 4
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0

local layout = Instance.new("UIListLayout", scroll)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 4)

-- Таймер
local timerLabel = Instance.new("TextLabel", contentFrame)
timerLabel.Size = UDim2.new(0, 60, 0, 20)
timerLabel.Position = UDim2.new(1, -65, 1, -55)
timerLabel.Text = "" 
timerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
timerLabel.BackgroundTransparency = 1
timerLabel.Font = Enum.Font.SourceSansBold
timerLabel.TextSize = 14

-- Исправленное поле ввода
local input = Instance.new("TextBox", contentFrame)
input.Size = UDim2.new(1, -75, 0, 30)
input.Position = UDim2.new(0, 5, 1, -35)
input.PlaceholderText = "Enter a message..."
input.Text = "" -- ЯВНО обнуляем текст, чтобы не было надписи "TextBox"
input.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
input.TextColor3 = Color3.new(1, 1, 1)
input.TextSize = 16
input.ClearTextOnFocus = true

local btn = Instance.new("TextButton", contentFrame)
btn.Size = UDim2.new(0, 60, 0, 30)
btn.Position = UDim2.new(1, -65, 1, -35)
btn.Text = "SEND"
btn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.SourceSansBold

-- Кулдаун логика
local function startCooldown()
    lastSendTick = tick()
    btn.Active = false
    btn.AutoButtonColor = false
    btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    
    task.spawn(function()
        for i = cooldownTime, 1, -1 do
            timerLabel.Text = i .. "s"
            task.wait(1)
        end
        timerLabel.Text = ""
        btn.Active = true
        btn.AutoButtonColor = true
        btn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    end)
end

-- Сворачивание
local isMinimized = false
toggleBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        contentFrame.Visible = false
        frame.Size = UDim2.new(0, 300, 0, 30)
        toggleBtn.Text = "+"
    else
        contentFrame.Visible = true
        frame.Size = UDim2.new(0, 300, 0, 350)
        toggleBtn.Text = "−"
    end
end)

local function addMessage(txt)
    local lbl = Instance.new("TextLabel", scroll)
    lbl.Size = UDim2.new(1, -10, 0, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.Text = " " .. txt
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.TextSize = 18
    lbl.Font = Enum.Font.SourceSans
    
    task.wait(0.1)
    scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
end

local function apiCall(msg)
    local httpRequest = (syn and syn.request) or (http and http.request) or request
    if not httpRequest then return end
    local isPolling = (msg == "")
    
    task.defer(function()
        local payload = {
            userid = player.UserId,
            username = tostring(player.Name),
            sessionid = tostring(sessionId),
            Question = isPolling and "POLLING" or tostring(msg),
            Recipient = "GlobalChat"
        }
        local success, response = pcall(function()
            return httpRequest({
                Url = API_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Authorization"] = "Bearer "..TOKEN
                },
                Body = HttpService:JSONEncode(payload)
            })
        end)
        if success and response and response.StatusCode == 200 then
            local res = HttpService:JSONDecode(response.Body)
            if res.status == "success" and res.data then
                for _, text in ipairs(res.data) do
                    addMessage(text)
                end
            end
        end
    end)
end

btn.MouseButton1Click:Connect(function()
    if tick() - lastSendTick < cooldownTime then return end
    
    local text = input.Text
    if text ~= "" and text ~= "TextBox" then -- Доп. проверка
        addMessage(player.Name .. ": " .. text)
        apiCall(text)
        input.Text = ""
        startCooldown()
    end
end)

task.spawn(function()
    warn("[Xeno] Chat Started Successfully")
    while true do
        apiCall("") 
        task.wait(3)
    end
end)
