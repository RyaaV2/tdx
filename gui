local Globals = getgenv()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local platform = UserInputService:GetPlatform()
local IsMobile = platform == Enum.Platform.IOS or platform == Enum.Platform.Android

local CONFIG_FILE = "AutoProgress_" .. tostring(LocalPlayer.Name) .. ".json"
local LOBBY_PLACE_ID = 3260590327
local AUTO_FARM_URL = "https://api.jnkie.com/api/v1/luascripts/public/b6f94e11cee9f4f5d02f2d41490f2370afdbed8b345834b3b383decb2c386acc/download"

local STATS_URL = "https://raw.githubusercontent.com/Ceepizz/rya/refs/heads/main/AutoProgressStats.lua"
local WEBHOOK_URL = "https://raw.githubusercontent.com/Ceepizz/WEBHOOKSOURCE/refs/heads/main/doakes"

local function LoadRemoteModule(url)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)

    if ok then
        return result
    end

    warn("[Auto Progress] Failed to load module:", result)
    return nil
end

local Stats = shared.AutoProgressStats or LoadRemoteModule(STATS_URL)
local ProgressWebhook

local function LoadProgressWebhook()
    if type(ProgressWebhook) == "table" then
        return ProgressWebhook
    end

    if type(shared.ProgressWebhook) == "table" then
        ProgressWebhook = shared.ProgressWebhook
        return ProgressWebhook
    end

    ProgressWebhook = LoadRemoteModule(WEBHOOK_URL)
    if type(ProgressWebhook) ~= "table" then
        ProgressWebhook = shared.ProgressWebhook
    end

    return type(ProgressWebhook) == "table" and ProgressWebhook or nil
end

if Stats and Stats.SetRewardTimeout then
    pcall(function()
        Stats.SetRewardTimeout(3)
    end)
end

local Defaults = {
    AutoPickups = false,
    PickupMethod = "Pathfinding",
    ClaimRewards = false,
    AutoFarmGatlingStrategy = "Win",
    AutoProgressEnabled = false,
    Webhook = "",
    PrivateCode = ""
}

local function SaveSettings()
    if not writefile then
        return
    end

    local data = {}

    if isfile and readfile and isfile(CONFIG_FILE) then
        pcall(function()
            local existing = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if type(existing) == "table" then
                data = existing
            end
        end)
    end

    for key, defaultValue in pairs(Defaults) do
        local value = Globals[key]
        if value == nil then
            value = defaultValue
        end
        data[key] = value
    end

    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end)
end

local function LoadSettings()
    local saved = {}

    if isfile and readfile and isfile(CONFIG_FILE) then
        pcall(function()
            saved = HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
    end

    for key, defaultValue in pairs(Defaults) do
        if Globals[key] == nil then
            if type(saved) == "table" and saved[key] ~= nil then
                Globals[key] = saved[key]
            else
                Globals[key] = defaultValue
            end
        end
    end
end

local function SetSetting(name, value)
    if Defaults[name] == nil then
        return
    end

    Globals[name] = value
    SaveSettings()
end

LoadSettings()
shared.AutoProgressStrategy = Globals.AutoFarmGatlingStrategy == "Lose" and "Lose" or "Win"

local function IsLobby()
    return PlayerGui:FindFirstChild("ReactLobbyHud") ~= nil
end

local function IsVoidCharm(obj)
    return math.abs(obj.Position.Y) > 999999
end

local function GetRoot()
    local character = LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local AutoPickupsRunning = false
local AutoClaimRewards = false

local function StartAutoPickups()
    if AutoPickupsRunning or not Globals.AutoPickups then
        return
    end

    AutoPickupsRunning = true

    task.spawn(function()
        while Globals.AutoPickups do
            local folder = workspace:FindFirstChild("Pickups")
            local hrp = GetRoot()

            if folder and hrp then
                local character = hrp.Parent
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")

                local function MoveToPos(targetPos)
                    if not humanoid then
                        return false
                    end

                    local function MoveDirect(pos)
                        humanoid:MoveTo(pos)
                        local startedAt = os.clock()

                        while os.clock() - startedAt < 2 do
                            if not Globals.AutoPickups then
                                return false
                            end

                            if (hrp.Position - pos).Magnitude < 4 then
                                return true
                            end

                            task.wait(0.1)
                        end

                        return (hrp.Position - pos).Magnitude < 4
                    end

                    local path = PathfindingService:CreatePath({
                        AgentRadius = 2,
                        AgentHeight = 6,
                        AgentCanJump = true,
                        AgentJumpHeight = 7,
                        AgentMaxSlope = 45
                    })

                    local ok = pcall(function()
                        path:ComputeAsync(hrp.Position, targetPos)
                    end)

                    if ok and path.Status == Enum.PathStatus.Success then
                        local blockedConnection

                        blockedConnection = path.Blocked:Connect(function()
                            if blockedConnection then
                                blockedConnection:Disconnect()
                            end

                            if Globals.AutoPickups then
                                task.spawn(function()
                                    MoveToPos(targetPos)
                                end)
                            end
                        end)

                        for _, waypoint in ipairs(path:GetWaypoints()) do
                            if not Globals.AutoPickups then
                                if blockedConnection then
                                    blockedConnection:Disconnect()
                                end
                                return false
                            end

                            if waypoint.Action == Enum.PathWaypointAction.Jump then
                                humanoid.Jump = true
                            end

                            if not MoveDirect(waypoint.Position) then
                                if blockedConnection then
                                    blockedConnection:Disconnect()
                                end
                                return false
                            end
                        end

                        if blockedConnection then
                            blockedConnection:Disconnect()
                        end

                        return true
                    end

                    return MoveDirect(targetPos)
                end

                for _, item in ipairs(folder:GetChildren()) do
                    if not Globals.AutoPickups then
                        break
                    end

                    if item:IsA("MeshPart")
                        and (item.Name == "Bunz" or item.Name == "Lorebook" or item.Name == "SnowCharm")
                        and not IsVoidCharm(item) then

                        if Globals.PickupMethod == "Instant" then
                            hrp.CFrame = item.CFrame * CFrame.new(0, 3, 0)
                            task.wait(0.5)
                        else
                            MoveToPos(item.Position + Vector3.new(0, 3, 0))
                            task.wait(0.5)
                        end
                    end
                end
            end

            task.wait(1)
        end

        AutoPickupsRunning = false
    end)
end

local function StartClaimRewards()
    if AutoClaimRewards or not Globals.ClaimRewards or not IsLobby() then
        return
    end

    AutoClaimRewards = true

    task.spawn(function()
        pcall(function()
            local network = ReplicatedStorage:WaitForChild("Network")
            local spinTickets = LocalPlayer:WaitForChild("SpinTickets", 15)

            if spinTickets and spinTickets.Value > 0 then
                local dailySpin = network:WaitForChild("DailySpin", 5)
                local redeemSpin = dailySpin and dailySpin:WaitForChild("RF:RedeemSpin", 5)

                if redeemSpin then
                    local ticketCount = spinTickets.Value
                    for _ = 1, ticketCount do
                        if not Globals.ClaimRewards then
                            break
                        end
                        redeemSpin:InvokeServer()
                        task.wait(0.5)
                    end
                end
            end

            if Globals.ClaimRewards then
                local playtimeRewards = network:WaitForChild("PlaytimeRewards")
                local claimReward = playtimeRewards:WaitForChild("RF:ClaimReward")

                for i = 1, 6 do
                    if not Globals.ClaimRewards then
                        break
                    end
                    claimReward:InvokeServer(i)
                    task.wait(0.5)
                end
            end

            if Globals.ClaimRewards then
                local dailySpin = network:FindFirstChild("DailySpin")
                local redeemReward = dailySpin and dailySpin:FindFirstChild("RF:RedeemReward")
                if redeemReward then
                    redeemReward:InvokeServer()
                end
            end
        end)

        AutoClaimRewards = false
    end)
end

local AutoProgressFarm

local function LoadAutoProgressFarm()
    if type(AutoProgressFarm) == "table" then
        return AutoProgressFarm
    end

    if type(shared.AutoProgress) == "table" then
        AutoProgressFarm = shared.AutoProgress
        return AutoProgressFarm
    end

    local success, result = pcall(function()
        return loadstring(game:HttpGet(AUTO_FARM_URL))()
    end)

    if success and type(result) == "table" then
        AutoProgressFarm = result
    elseif type(shared.AutoProgress) == "table" then
        AutoProgressFarm = shared.AutoProgress
    else
        warn("[AUTO PROGRESS] Failed to load farm source:", result)
    end

    return AutoProgressFarm
end

local StartTaskRunning = false

local function StartAutoProgress()
    if StartTaskRunning then
        return
    end

    if Globals.AutoProgressEnabled ~= true then
        return
    end

    StartTaskRunning = true

    task.spawn(function()
        local farm = LoadAutoProgressFarm()

        if not farm
            or not farm.Start then

            StartTaskRunning = false
            return
        end

        shared.AutoProgressStrategy = Globals.AutoFarmGatlingStrategy == "Lose" and "Lose" or "Win"

        if farm.SetStrategy then
            pcall(function()
                farm.SetStrategy(shared.AutoProgressStrategy)
            end)
        end

        local alreadyRunning = false

        if shared.AutoProgress
            and shared.AutoProgress.GetStatus then

            local ok, state =
                pcall(
                    shared.AutoProgress.GetStatus
                )

            if ok and state then
                local stateText =
                    tostring(state)

                alreadyRunning =
                    stateText ~= ""
                    and stateText ~= "Disabled"
                    and stateText ~= "Status: Disabled"
            end
        end

        if not alreadyRunning
            and Globals.AutoProgressEnabled == true then

            farm.Start()
        end

        StartTaskRunning = false
    end)
end

local function StopAutoProgress()
    StartTaskRunning = false

    local farm = AutoProgressFarm or shared.AutoProgress

    if farm and farm.Stop then
        pcall(function()
            farm.Stop()
        end)
    elseif farm and farm.SetEnabled then
        pcall(function()
            farm.SetEnabled(false)
        end)
    end
end

local function TeleportToLobby()
    if game.PlaceId == LOBBY_PLACE_ID then
        return false
    end

    pcall(function()
        if not IsMobile
            and Globals.PrivateCode
            and Globals.PrivateCode ~= "" then

            game:GetService("ExperienceService"):LaunchExperience({
                placeId = LOBBY_PLACE_ID,
                linkCode = Globals.PrivateCode
            })
        else
            TeleportService:Teleport(
                LOBBY_PLACE_ID,
                LocalPlayer
            )
        end
    end)

    return true
end


local DisconnectCheckRunning = false

local function DisconnectToLobby()
    if DisconnectCheckRunning then
        return
    end

    local initialCode = GuiService:GetErrorCode()

    if not initialCode
        or initialCode == Enum.ConnectionError.OK
        or game.PlaceId == LOBBY_PLACE_ID then

        return
    end

    DisconnectCheckRunning = true

    task.spawn(function()
        task.wait(5)

        local currentCode = GuiService:GetErrorCode()

        if currentCode == initialCode
            and currentCode ~= Enum.ConnectionError.OK
            and game.PlaceId ~= LOBBY_PLACE_ID then

            TeleportToLobby()
        end

        DisconnectCheckRunning = false
    end)
end

task.spawn(DisconnectToLobby)
GuiService.ErrorMessageChanged:Connect(DisconnectToLobby)

local GameReady = false

local function WaitForLoadingScreen()
    local loadingScreen =
        PlayerGui:FindFirstChild(
            "LoadingScreen"
        )

    local content =
        loadingScreen
        and loadingScreen:FindFirstChild(
            "content"
        )

    if content then
        while content.Visible do
            content
                :GetPropertyChangedSignal(
                    "Visible"
                )
                :Wait()
        end
    end
end

local function IsLoading()
    local attrLoading =
        LocalPlayer:GetAttribute(
            "Loading"
        ) == true

    local attrTeleporting =
        LocalPlayer:GetAttribute(
            "Teleporting"
        ) == true

    local pg =
        LocalPlayer:FindFirstChild(
            "PlayerGui"
        )

    local loadingScreen =
        pg
        and pg:FindFirstChild(
            "LoadingScreen"
        )

    local content =
        loadingScreen
        and loadingScreen:FindFirstChild(
            "content"
        )

    local contentVisible =
        content
        and content.Visible == true

    return
        attrLoading
        or attrTeleporting
        or contentVisible
end

local function WaitUntilLoaded()
    print(
        "[AUTO PROGRESS GUI] Waiting for loading screen..."
    )

    while IsLoading() do
        task.wait(1)
    end

    print(
        "[AUTO PROGRESS GUI] Loaded!"
    )
end

local function WaitForGame()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    LocalPlayer:WaitForChild("PlayerGui")

    local startedAt = os.clock()

    print(
        "[AUTO PROGRESS GUI] Waiting for loading screen..."
    )

    while IsLoading() do
        if os.clock() - startedAt >= 60 then
            warn(
                "[AUTO PROGRESS GUI] Loading stuck for 60 seconds. Teleporting to lobby..."
            )

            TeleportToLobby()

            return false
        end

        task.wait(1)
    end

    print(
        "[AUTO PROGRESS GUI] Loaded!"
    )

    GameReady = true
    return true
end


-- Match the original working Auto Progress startup order:
-- do not create the UI until TDS is no longer loading.
WaitForGame()

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/DuxiiT/auto-strat/refs/heads/main/Sources/UI.lua"
))()

local Window = Library:Window({
    Title = "Auto Progress",
    Desc = "Progression Hub",
    Theme = "Default",
    Icon = 99432006374500,
    Config = {
        Keybind = Enum.KeyCode.LeftControl,
        Size = UDim2.new(0, 500, 0, 400)
    }
})

local LevelLabel
local CoinsLabel
local GatlingLabel

local Automation = Window:Tab({Title = "Automation", Icon = "bot"}) do
    Automation:Section({Title = "Auto Farm Until Gatling"})

    LevelLabel = Automation:Label({
        Title = "Level: Loading...",
        Desc = ""
    })

    CoinsLabel = Automation:Label({
        Title = "Coins: Loading...",
        Desc = ""
    })

    GatlingLabel = Automation:Label({
        Title = "Gatling Gun: Checking...",
        Desc = ""
    })

    local AutoProgressStatus = Automation:Label({
        Title = "Status: Ready",
        Desc = ""
    })

    local function SetAutoProgressStatus(text)
        text = tostring(text or "Ready")
        local title = text:match("^Status:") and text or ("Status: " .. text)

        local updated = false

        pcall(function()
            if AutoProgressStatus.SetTitle then
                AutoProgressStatus:SetTitle(title)
                updated = true
            end
        end)

        if not updated then
            pcall(function()
                if AutoProgressStatus.Set then
                    AutoProgressStatus:Set({
                        Title = title,
                        Desc = ""
                    })
                end
            end)
        end
    end

    local function GetStrategyDescription(strategy)
        if strategy == "Lose" then
           return "Lose Strategy", "Recommended for speed. Faster progression and usually reaches Gatling in about 2–3 days."
        end

        return "Win Strategy", "Slower but safer. Has a 100% win ratio and usually reaches Gatling in about 5–7 days."
     end

    local initialStrategy = Globals.AutoFarmGatlingStrategy == "Lose" and "Lose" or "Win"
    local initialTitle, initialDesc = GetStrategyDescription(initialStrategy)

    local StrategyDescription = Automation:Label({
        Title = initialTitle,
        Desc = initialDesc
    })

    local function UpdateStrategyDescription(strategy)
        local title, desc = GetStrategyDescription(strategy)

        local updated = false

        pcall(function()
            if StrategyDescription.SetTitle then
                StrategyDescription:SetTitle(title)
                updated = true
            end
        end)

        pcall(function()
            if StrategyDescription.SetDesc then
                StrategyDescription:SetDesc(desc)
                updated = true
            end
        end)

        if not updated then
            pcall(function()
                if StrategyDescription.Set then
                    StrategyDescription:Set({
                        Title = title,
                        Desc = desc
                    })
                end
            end)
        end
    end

    Automation:Dropdown({
        Title = "Strategy",
        Desc = "Choose how Auto Farm Until Gatling should run",
        List = {"Win", "Lose"},
        Value = initialStrategy,
        Callback = function(choice)
            local selected = type(choice) == "table" and choice[1] or choice

            if selected ~= "Lose" then
                selected = "Win"
            end

            local oldStrategy = Globals.AutoFarmGatlingStrategy or "Win"

            SetSetting("AutoFarmGatlingStrategy", selected)
            shared.AutoProgressStrategy = selected
            UpdateStrategyDescription(selected)

            local farm = AutoProgressFarm or shared.AutoProgress
            if farm and farm.SetStrategy then
                pcall(function()
                    farm.SetStrategy(selected)
                end)
            end

            if selected ~= oldStrategy then
                StopAutoProgress()

                if game.PlaceId == LOBBY_PLACE_ID then
                    if Globals.AutoProgressEnabled == true then
                        SetAutoProgressStatus("Strat changed to " .. selected .. " - Restarting Auto Progress...")

                        task.delay(0.5, function()
                            if Globals.AutoProgressEnabled == true
                                and Globals.AutoFarmGatlingStrategy == selected then

                                StartAutoProgress()
                                SetAutoProgressStatus("Auto Progress Running - " .. selected)
                            end
                        end)
                    else
                        SetAutoProgressStatus("Strat changed to " .. selected)
                    end
                else
                    SetAutoProgressStatus("Strat changed to " .. selected .. " - Teleporting to Lobby...")

                    task.delay(2, function()
                        if Globals.AutoProgressEnabled == true
                            and Globals.AutoFarmGatlingStrategy == selected then

                            TeleportToLobby()
                        end
                    end)
                end
            end
        end
    })

    Automation:Toggle({
        Title = "Start Auto Progress",
        Desc = "Starts or stops Auto Farm Until Gatling",
        Value = Globals.AutoProgressEnabled or false,
        Callback = function(value)
            SetSetting("AutoProgressEnabled", value)

            if value then
                SetAutoProgressStatus("Auto Progress Turned On - Starting...")

                local webhook = LoadProgressWebhook()

                if webhook then
                    local url = Globals.Webhook or ""

                    if url ~= "" and webhook.SetWebhook then
                        pcall(function()
                            webhook.SetWebhook(url)
                        end)
                    end

                    if webhook.Start then
                        pcall(function()
                            webhook.Start()
                        end)
                    end
                end

                StartAutoProgress()
                SetAutoProgressStatus("Auto Progress Running - " .. (Globals.AutoFarmGatlingStrategy or "Win"))
            else
                StopAutoProgress()

                if game.PlaceId == LOBBY_PLACE_ID then
                    SetAutoProgressStatus("Auto Progress Turned Off")
                else
                    SetAutoProgressStatus("Auto Progress Turned Off - Teleporting to Lobby...")
                end

                local webhook = ProgressWebhook or shared.ProgressWebhook
                if webhook and webhook.Stop then
                    pcall(function()
                        webhook.Stop()
                    end)
                end

                task.delay(2, function()
                    if Globals.AutoProgressEnabled ~= true then
                        TeleportToLobby()
                    end
                end)
            end
        end
    })

    Automation:Textbox({
        Title = "Progress Webhook",
        Desc = "Discord webhook used for Auto Progress updates",
        Placeholder = "Paste Discord webhook...",
        Value = Globals.Webhook or "",
        ClearTextOnFocus = false,
        Callback = function(text)
            text = tostring(text or "")
            SetSetting("Webhook", text)

            local webhook = LoadProgressWebhook()
            if webhook and webhook.SetWebhook then
                pcall(function()
                    webhook.SetWebhook(text)
                end)
            end
        end
    })

    Automation:Button({
        Title = "Send Webhook",
        Desc = "Sends a test/current Auto Progress webhook",
        Callback = function()
            local webhook = LoadProgressWebhook()
            if not webhook then
                return
            end

            local url = Globals.Webhook or ""

            if url ~= "" and webhook.SetWebhook then
                pcall(function()
                    webhook.SetWebhook(url)
                end)
            end

            if webhook.Send then
                pcall(function()
                    webhook.Send(true)
                end)
            end
        end
    })

    Automation:Section({Title = "Utilities"})

    Automation:Toggle({
        Title = "Auto Collect Pickups",
        Desc = "Collects Logbooks + Event currency",
        Value = Globals.AutoPickups,
        Callback = function(value)
            SetSetting("AutoPickups", value)
            if value then
                StartAutoPickups()
            end
        end
    })

    Automation:Dropdown({
        Title = "Pickup Method",
        Desc = "",
        List = {"Pathfinding", "Instant"},
        Value = Globals.PickupMethod or "Pathfinding",
        Callback = function(choice)
            local selected = type(choice) == "table" and choice[1] or choice
            if selected ~= "Instant" then
                selected = "Pathfinding"
            end
            SetSetting("PickupMethod", selected)
        end
    })

    Automation:Toggle({
        Title = "Claim Rewards",
        Desc = "Claims playtime rewards and uses spin tickets in Lobby",
        Value = Globals.ClaimRewards,
        Callback = function(value)
            SetSetting("ClaimRewards", value)
            if value then
                StartClaimRewards()
            end
        end
    })
end


local Settings = Window:Tab({Title = "Settings", Icon = "settings"}) do
    Settings:Section({Title = "Private Server"})

    Settings:Label({
        Title = "Private Server Code",
        Desc = "PC only. Paste your private server code below to return to your private server instead of a public lobby."
    })

    if not IsMobile then
        Settings:Textbox({
            Title = "Private Server Code",
            Desc = "PC only",
            Placeholder = "Example: 16055572089259659857100802598629",
            Value = Globals.PrivateCode or "",
            ClearTextOnFocus = false,
            Callback = function(text)
                text = tostring(text or "")

                local validated = text

                if text ~= ""
                    and not text:match("^%d+$") then

                    validated = ""
                end

                SetSetting("PrivateCode", validated)
            end
        })
    end
end


local function FormatNumber(value)
    local n = math.floor(tonumber(value) or 0)
    local formatted = tostring(n)

    while true do
        local updated, count = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        formatted = updated
        if count == 0 then
            break
        end
    end

    return formatted
end

local function RefreshUserStats(snapshot)
    snapshot = snapshot or {}

    local level = tonumber(snapshot.Level) or 0
    local coins = tonumber(snapshot.Coins) or 0
    local gatlingOwned = snapshot.GatlingOwned == true

    if LevelLabel and LevelLabel.SetTitle then
        LevelLabel:SetTitle("Level: " .. FormatNumber(level))
    end

    if CoinsLabel and CoinsLabel.SetTitle then
        if gatlingOwned then
            CoinsLabel:SetTitle("Coins: " .. FormatNumber(coins))
        else
            CoinsLabel:SetTitle("Coins: " .. FormatNumber(coins) .. " / 35,000")
        end
    end

    if GatlingLabel and GatlingLabel.SetTitle then
        GatlingLabel:SetTitle("Gatling Gun: " .. (gatlingOwned and "Owned" or "Not Owned"))
    end
end

if Globals.AutoProgressEnabled then
    task.spawn(function()
        task.wait(1)

        local webhook = LoadProgressWebhook()
        if webhook then
            local url = Globals.Webhook or ""

            if url ~= "" and webhook.SetWebhook then
                pcall(function()
                    webhook.SetWebhook(url)
                end)
            end

            if webhook.Start then
                pcall(function()
                    webhook.Start()
                end)
            end
        end

        StartAutoProgress()
    end)
end

if Stats then
    pcall(function()
        RefreshUserStats(Stats.GetSnapshot and Stats.GetSnapshot() or nil)
    end)

    if Stats.Start then
        pcall(function()
            Stats.Start(function(snapshot)
                RefreshUserStats(snapshot)
            end)
        end)
    end
else
    if LevelLabel and LevelLabel.SetTitle then
        LevelLabel:SetTitle("Level: Unavailable")
    end
    if CoinsLabel and CoinsLabel.SetTitle then
        CoinsLabel:SetTitle("Coins: Unavailable")
    end
    if GatlingLabel and GatlingLabel.SetTitle then
        GatlingLabel:SetTitle("Gatling Gun: Unavailable")
    end
end

task.spawn(function()
    while task.wait(1) do
        if Globals.AutoPickups and not AutoPickupsRunning then
            StartAutoPickups()
        end

        if Globals.ClaimRewards and not AutoClaimRewards and IsLobby() then
            StartClaimRewards()
        end
    end
end)

local GuiBase = {
    Window = Window,
    Library = Library,
    LevelLabel = LevelLabel,
    CoinsLabel = CoinsLabel,
    GatlingLabel = GatlingLabel,
    Stats = Stats,
    LoadProgressWebhook = LoadProgressWebhook,
    LoadAutoProgressFarm = LoadAutoProgressFarm,
    StartAutoProgress = StartAutoProgress,
    StopAutoProgress = StopAutoProgress,
    TeleportToLobby = TeleportToLobby,
    WaitForGame = WaitForGame,
    RefreshUserStats = RefreshUserStats,
    StartAutoPickups = StartAutoPickups,
    StartClaimRewards = StartClaimRewards,
    SetSetting = SetSetting,
    GetSetting = function(name)
        return Globals[name]
    end
}

shared.AutoProgressGuiBase = GuiBase
return GuiBase
