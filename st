local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PurchaseSkill =
    ReplicatedStorage
        :WaitForChild("Network")
        :WaitForChild("Skills")
        :WaitForChild("RF:Purchase")

local SkillNodes = {
    [1] = "Enhanced Optics",
    [2] = "Resourcefulness",
    [3] = "Fortify",
    [4] = "Over-Heal",
    [5] = "Fight Dirty",
    [6] = "Extreme Conditioning",
    [7] = "Stonks",
    [8] = "Expanded Barracks",
    [9] = "Improved Gunpowder",
    [10] = "Beefed Up Minions",
    [11] = "Precision",
    [12] = "Scavenger",
    [13] = "Accelerator",
    [14] = "Re-enforcements",
    [15] = "Bigger Budget",
    [16] = "Bandages",
    [17] = "Scholar"
}

local Phases = {
    {
        Name = "Phase 1 - Level 10 Setup",
        Skills = {
            {2, 10},
            {15, 10},
            {7, 10},
            {13, 10},
            {1, 10},
            {8, 10},
            {9, 10},
            {5, 10},
            {3, 10},
            {4, 10},
            {16, 10},
            {6, 10},
            {10, 10}
        }
    },

    {
        Name = "Phase 2 - Priority Max",
        Skills = {
            {15, 25},
            {9, 25},
            {10, 25},
            {7, 20},
            {13, 25},
            {1, 20},
            {8, 20}
        }
    },

    {
        Name = "Phase 3 - Remaining Normal Skills",
        Skills = {
            {2, 25},
            {5, 25},
            {4, 25},
            {16, 25},
            {6, 25},
            {3, 40},
            {11, 15}
        }
    },

    {
        Name = "Phase 4 - Scholar",
        Skills = {
            {17, 20}
        }
    },

    {
        Name = "Phase 5 - Scavenger",
        Skills = {
            {12, 20}
        }
    },

    {
        Name = "Phase 6 - Re-enforcements",
        Skills = {
            {14, 10}
        }
    }
}

local function GetSkillFrame(nodeId)
    local node = workspace:FindFirstChild(tostring(nodeId))

    if not node then
        return nil
    end

    local gui = node:FindFirstChild("TileSurfaceGui")
    local frame = gui and gui:FindFirstChild("Frame")

    return frame
end

local function GetSkillLevel(nodeId)
    local frame = GetSkillFrame(nodeId)

    if not frame then
        return nil, nil
    end

    local levelLabel = frame:FindFirstChild("SkillLevel")

    if not levelLabel then
        return nil, nil
    end

    local current, max =
        tostring(levelLabel.Text):match("(%d+)%s*/%s*(%d+)")

    return tonumber(current), tonumber(max)
end

local function WaitForSkillTree()
    while true do
        local ready = true

        for nodeId = 1, 17 do
            local current, max = GetSkillLevel(nodeId)

            if current == nil or max == nil then
                ready = false
                break
            end
        end

        if ready then
            return
        end

        task.wait(1)
    end
end

local function UpgradeTo(nodeId, targetLevel)
    while true do
        local current, max = GetSkillLevel(nodeId)

        if current == nil or max == nil then
            task.wait(1)
            continue
        end

        local target = math.min(targetLevel, max)

        if current >= target then
            return true
        end

        local before = current

        pcall(function()
            PurchaseSkill:InvokeServer(tostring(nodeId))
        end)

        task.wait(0.2)

        local changed = false
        local timeoutAt = os.clock() + 2

        repeat
            task.wait(0.15)

            local newLevel = GetSkillLevel(nodeId)

            if newLevel and newLevel > before then
                changed = true
                break
            end
        until os.clock() >= timeoutAt

        if not changed then
            task.wait(2)
        end
    end
end

WaitForSkillTree()

for _, phase in ipairs(Phases) do
    for _, entry in ipairs(phase.Skills) do
        local nodeId = entry[1]
        local targetLevel = entry[2]

        UpgradeTo(nodeId, targetLevel)
    end
end
