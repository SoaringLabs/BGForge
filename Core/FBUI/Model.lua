local _, ns = ...

local L = ns.L

local ZERO = 0
local ONE = 1
local C_005 = 0.05
local C_01 = 0.1
local C_03 = 0.3
local C_05 = 0.5
local C_053 = 0.53
local C_06 = 0.6
local C_075 = 0.75
local C_08 = 0.8
local C_045 = 0.45
local C_NEG03 = -0.3
local C_NEG05 = -0.5
local BUTTON_PAIR_COUNT = 2
local ON_CLICK_AXIS = { z = 1, x = 2, y = 3 }



BG.bossModels = {}
local testButtons = {}
local CreateAllTestButton
do
    local function OnClick(self)
        local valueGetter = self.func_get
        local valueSetter = self.func_set
        local deltaValue

        if self._type3 then
            deltaValue = self._type == "+" and C_05 or -C_05

            local z, x, y = valueGetter(self.owner)
            local coords = { z, x, y }
            local slot = ON_CLICK_AXIS[self._type3]
            if slot then
                coords[slot] = coords[slot] + deltaValue
            end
            valueSetter(self.owner, coords[ONE], coords[2], coords[3])
            print(self._type2 .. ": " .. coords[ONE] .. " " .. coords[2] .. " " .. coords[3])
        else
            deltaValue = self._type == "+" and C_005 or -C_005
            local currentValue = valueGetter(self.owner)
            local nextValue = currentValue + deltaValue
            valueSetter(self.owner, nextValue)
            print(self._type2 .. ": " .. nextValue)
        end
    end
    local function OnMouseDown(self)
        local elapsedTotal = ZERO
        local holdTime = C_03
        self:SetScript("OnUpdate", function(self, elapsed)
            elapsedTotal = elapsedTotal + elapsed
            if elapsedTotal >= holdTime then
                elapsedTotal = holdTime - C_01
                OnClick(self)
            end
        end)
    end
    local function OnMouseUp(self)
        self:SetScript("OnUpdate", nil)
    end
    local function OnEnter(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP", ZERO, ZERO)
        GameTooltip:ClearLines()
        GameTooltip:AddLine(self._type2, ONE, ONE, ONE, true)
        GameTooltip:Show()
    end
    local function CreateButton(model, labelText, valueGetter, valueSetter, axisKey)
        local labels = { "+", "-" }
        for i = ONE, BUTTON_PAIR_COUNT do
            local testButton = CreateFrame("Button", nil, BG.MainFrame, "UIPanelButtonTemplate")
            testButton:SetSize(40, 25)
            if not testButtons[ONE] then
                testButton:SetPoint("BOTTOMLEFT", BG.MainFrame, "TOPLEFT", ZERO, 2)
            else
                if i == 2 then
                    testButton:SetPoint("LEFT", testButtons[#testButtons], "RIGHT", ZERO, ZERO)
                else
                    testButton:SetPoint("LEFT", testButtons[#testButtons], "RIGHT", 5, ZERO)
                end
            end
            testButton.owner = model
            testButton._type = labels[i]
            testButton._type2 = labelText
            testButton.func_get = valueGetter
            testButton.func_set = valueSetter
            testButton._type3 = axisKey
            testButton:SetText(labels[i])
            testButton:SetScript("OnClick", OnClick)
            testButton:SetScript("OnEnter", OnEnter)
            testButton:SetScript("OnLeave", GameTooltip_Hide)
            testButton:SetScript("OnMouseDown", OnMouseDown)
            testButton:SetScript("OnMouseUp", OnMouseUp)
            tinsert(testButtons, testButton)
        end
    end
    CreateAllTestButton = function(model)
        local buttonSpecs = {
            { label = L["左右"], getter = model.GetFacing, setter = model.SetFacing },
            { label = L["上下"], getter = model.GetPitch, setter = model.SetPitch },
            { label = L["倾斜"], getter = model.GetRoll, setter = model.SetRoll },
            { label = L["位置z"], getter = model.GetPosition, setter = model.SetPosition, axis = "z" },
            { label = L["位置x"], getter = model.GetPosition, setter = model.SetPosition, axis = "x" },
            { label = L["位置y"], getter = model.GetPosition, setter = model.SetPosition, axis = "y" },
        }
        for _, spec in ipairs(buttonSpecs) do
            CreateButton(model, spec.label, spec.getter, spec.setter, spec.axis)
        end

        model:SetBackdrop({
            edgeFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeSize = 2,
        })
        BG.lastModel = model
    end
end

local function UpdateModel(model, NPCID)
    model:SetScript("OnShow", function(self)
        model:SetCreature(NPCID)
    end)
end

-- BOSS模型
--     model:SetSize(500, 500)
--     model:SetPoint("CENTER", BG.Frame[FB]["boss" .. bossnum].bossName, "CENTER", point_x, point_y)
--     model:SetFrameLevel(101)
--     model:SetAlpha(0.8)
--     model:SetScale(scale or 1)
--         model.actor = model:CreateActor()
--         model.actor:SetModelByCreatureDisplayID(NPCID)
--     end
--     model:SetScript("OnShow", function(self)
--             model.actor:SetModelByCreatureDisplayID(NPCID)
--         else
--             model:SetCreature(NPCID)
--         end
--     end)
-- end
local function CreateBossModel(FB, bossnum, point_x, point_y, NPCID, scale)
    local sceneModel = CreateFrame("PlayerModel", nil, BG["Frame" .. FB], "BackdropTemplate")
    sceneModel:SetSize(500, 500)
    sceneModel:SetPoint("CENTER", BG.Frame[FB]["boss" .. bossnum].bossName, "CENTER", point_x, point_y)
    sceneModel:SetFrameLevel(101)
    sceneModel:SetAlpha(C_08)
    sceneModel:SetScale(scale or ONE)
    sceneModel:SetCreature(NPCID)
    sceneModel:SetScript("OnShow", function(self)
        sceneModel:SetCreature(NPCID)
    end)
    tinsert(BG.bossModels, sceneModel)
    return sceneModel
end
function BG.CreateBossModel()
    if BG.IsVanilla_60 and not BG.IsTBC then
        local model = CreateBossModel("MC", 10, ZERO, 30, 11502, C_08)
        model:SetPosition(-30, ZERO, -7) -- Z,X,Y
        model:SetFacing(C_NEG03)         -- 左右
        model:SetPitch(ZERO)             -- 上下
        model:SetRoll(ZERO)              -- 倾斜
        local model = CreateBossModel("BWL", 8, 50, ZERO, 11583, C_075)
        model:SetPosition(-50, ZERO, 60)
        model:SetFacing(-0.6)
        model:SetPitch(C_08)
        model:SetRoll(C_NEG05)
        local model = CreateBossModel("ZUG", 10, -50, 40, 14834, 1.2)
        model:SetPosition(15, -2.5, -1)
        model:SetFacing(C_NEG05)
        model:SetPitch(C_01)
        model:SetRoll(ZERO)
        local model = CreateBossModel("AQL", 6, 25, 80, 15339, C_08)
        model:SetPosition(-7, ZERO, 5)
        model:SetFacing(C_NEG03)
        model:SetPitch(C_05)
        model:SetRoll(-0.12)
        local model = CreateBossModel("TAQ", 9, 10, ZERO, 15727, C_045) -- 底下
        model:SetPosition(-8, ZERO, -5)
        model:SetFacing(ZERO)
        model:SetPitch(ZERO)
        model:SetRoll(ZERO)
        local model = CreateBossModel("TAQ", 9, ZERO, -10, 15589, C_075) -- 眼睛
        model:SetPosition(-37, ZERO, -3)
        model:SetFacing(ZERO)
        model:SetPitch(ZERO)
        model:SetRoll(ZERO)
        local model = CreateBossModel("NAXX", 15, -15, -130, 15990, 0.9)
        model:SetPosition(-16, ZERO, 9.5)
        model:SetFacing(C_NEG03)
        model:SetPitch(C_03)
        model:SetRoll(-0.1)
        -- CreateAllTestButton(model)
    end
    if BG.IsVanilla_Sod then
        local model = CreateBossModel("BD", 7, 80, -10, 213334, C_05)
        model:SetPosition(ZERO, ZERO, ZERO) -- Z,X,Y
        model:SetFacing(ZERO)         -- 左右
        model:SetPitch(ZERO)          -- 上下
        model:SetRoll(ZERO)           -- 倾斜
        -- CreateAllTestButton(model)
        local model = CreateBossModel("Gno", 6, -20, -30, 7800, C_08)
        model:SetPosition(-4, ZERO, ONE)
        model:SetFacing(-0.4)
        model:SetPitch(0.15)
        model:SetRoll(ZERO)
        -- CreateAllTestButton(model)
        local model = CreateBossModel("Temple", 8, -25, -65, 8443, C_08)
        model:SetPosition(-20, ZERO, 2)
        model:SetFacing(-0.2)
        model:SetPitch(0.15)
        model:SetRoll(ZERO)
        -- CreateAllTestButton(model)
        local model = CreateBossModel("MCsod", 10, ZERO, 30, 11502, C_08)
        model:SetPosition(-30, ZERO, -7) -- Z,X,Y
        model:SetFacing(C_NEG03)         -- 左右
        model:SetPitch(ZERO)             -- 上下
        model:SetRoll(ZERO)              -- 倾斜
        local model = CreateBossModel("ZUGsod", 10, -50, 40, 14834, 1.2)
        model:SetPosition(15, -2.5, -1)
        model:SetFacing(C_NEG05)
        model:SetPitch(C_01)
        model:SetRoll(ZERO)
        local model = CreateBossModel("BWLsod", 7, 50, ZERO, 11583, C_075)
        model:SetPosition(-50, ZERO, 60)
        model:SetFacing(-0.6)
        model:SetPitch(C_08)
        model:SetRoll(C_NEG05)
    end
    if BG.IsTBC then
        local model = CreateBossModel("KZ", 10, ZERO, -10, 15690, C_05)
        model:SetPosition(-0, ZERO, ZERO)
        model:SetFacing(C_NEG03)
        model:SetPitch(ZERO)
        model:SetRoll(ZERO)
        local model = CreateBossModel("GL", 2, -0, 130, 19044, C_045)
        model:SetPosition(-1, ZERO, C_NEG03)
        model:SetFacing(C_NEG03)
        model:SetPitch(ZERO)
        model:SetRoll(ZERO)
        local model = CreateBossModel("GL", 3, -0, 20, 17257, C_06)
        model:SetPosition(-1, ZERO, C_NEG03)
        model:SetFacing(C_NEG03)
        model:SetPitch(ZERO)
        model:SetRoll(ZERO)
        local model = CreateBossModel("SSC", 6, 10, 30, 21212, .9)
        model:SetPosition(-2, ZERO, ONE)
        model:SetFacing(ZERO)
        model:SetPitch(C_053)
        model:SetRoll(ZERO)
        local model = CreateBossModel("SSC", 10, 5, 25, 19622, .9)
        model:SetPosition(-2, ZERO, ONE)
        model:SetFacing(ZERO)
        model:SetPitch(C_053)
        model:SetRoll(ZERO)
        -- CreateAllTestButton(model)
    end
    if BG.IsWLK_80 then
        local model = CreateBossModel("ICC", 12, ZERO, -70, 31301, C_05)
        model:SetPosition(ZERO, ZERO, ZERO) -- Z,X,Y
        model:SetFacing(ZERO)         -- 左右
        model:SetPitch(ZERO)          -- 上下
        model:SetRoll(ZERO)           -- 倾斜
        -- CreateAllTestButton(model)

        local model = CreateBossModel("TOC", 5, 10, -20, 34564, C_06)
        model:SetPosition(-4, ZERO, ZERO)
        model:SetFacing(ZERO)
        model:SetPitch(ZERO)
        model:SetRoll(ZERO)
        -- CreateAllTestButton(model)

        local model = CreateBossModel("ULD", 14, ZERO, ZERO, 32871, C_045)
        model:SetPosition(ZERO, ZERO, ZERO)
        model:SetFacing(ZERO)
        model:SetPitch(ZERO)
        model:SetRoll(ZERO)
        -- CreateAllTestButton(model)

        local model = CreateBossModel("NAXX", 15, ZERO, -170, 15990, 1.7)
        model:SetPosition(-16, ZERO, 9.5)
        model:SetFacing(-0)
        model:SetPitch(C_03)
        model:SetRoll(ZERO)
        -- CreateAllTestButton(model)

        -- TBC
        local model = CreateBossModel("SW", 6, 80, -20, 25315, .75)
        model:SetPosition(ZERO, ZERO, ONE)
        model:SetFacing(-.1)
        model:SetPitch(C_053)
        model:SetRoll(ZERO)
        -- CreateAllTestButton(model)
        local model = CreateBossModel("BT", 9, 50, 60, 22917, .7)
        model:SetPosition(-2, ZERO, ONE)
        model:SetFacing(-.1)
        model:SetPitch(C_053)
        model:SetRoll(ZERO)
        -- CreateAllTestButton(model)
        local model = CreateBossModel("HS", 5, -10, -35, 17968, .9)
        model:SetPosition(-2, ZERO, ONE)
        model:SetFacing(ZERO)
        model:SetPitch(C_053)
        model:SetRoll(ZERO)
        -- CreateAllTestButton(model)
        local model = CreateBossModel("SSC", 6, 10, 30, 21212, .9)
        model:SetPosition(-2, ZERO, ONE)
        model:SetFacing(ZERO)
        model:SetPitch(C_053)
        model:SetRoll(ZERO)
        -- CreateAllTestButton(model)
        local model = CreateBossModel("SSC", 10, 5, 25, 19622, .9)
        model:SetPosition(-2, ZERO, ONE)
        model:SetFacing(ZERO)
        model:SetPitch(C_053)
        model:SetRoll(ZERO)
        -- CreateAllTestButton(model)
        local model = CreateBossModel("BWL", 8, 50, ZERO, 11583, C_075)
        model:SetPosition(-50, ZERO, 60)
        model:SetFacing(-0.6)
        model:SetPitch(C_08)
        model:SetRoll(C_NEG05)
        local model = CreateBossModel("TAQ", 9, 10, ZERO, 15727, C_045) -- 底下
        model:SetPosition(-8, ZERO, -5)
        model:SetFacing(ZERO)
        model:SetPitch(ZERO)
        model:SetRoll(ZERO)
        local model = CreateBossModel("TAQ", 9, ZERO, -10, 15589, C_075) -- 眼睛
        model:SetPosition(-37, ZERO, -3)
        model:SetFacing(ZERO)
        model:SetPitch(ZERO)
        model:SetRoll(ZERO)
    end
    if BG.IsTitan then
        local model = CreateBossModel("MCtitan", 10, 10, 100, 11502, C_08)
        model:SetPosition(-200, ZERO, -195) -- Z,X,Y
        -- model:SetFacing(-0.3)         -- 左右
        model:SetPitch(C_NEG05)             -- 上下
        model:SetRoll(ZERO)                 -- 倾斜
        -- CreateAllTestButton(model)
        local model = CreateBossModel("SSCtitan", 6, 10, 30, 21212, .9)
        model:SetPosition(-2, ZERO, ONE)
        model:SetFacing(ZERO)
        model:SetPitch(C_053)
        model:SetRoll(ZERO)
        local model = CreateBossModel("SSCtitan", 10, 5, 25, 19622, .9)
        model:SetPosition(-2, ZERO, ONE)
        model:SetFacing(ZERO)
        model:SetPitch(C_053)
        model:SetRoll(ZERO)
        local model = CreateBossModel("NAXXtitan", 15, ZERO, -170, 15990, 1.7)
        model:SetPosition(-16, ZERO, 9.5)
        model:SetFacing(-0)
        model:SetPitch(C_03)
        model:SetRoll(ZERO)
        local model = CreateBossModel("TOCtitan", 10, ZERO, 80, 14834, ONE)
        model:SetPosition(13, -2.5, -1)
        model:SetFacing(C_NEG05)
        model:SetPitch(C_01)
        model:SetRoll(ZERO)
        local model = CreateBossModel("TOCtitan", 15, 10, -30, 34564, C_06)
        model:SetPosition(-4, ZERO, ZERO)
        model:SetFacing(ZERO)
        model:SetPitch(ZERO)
        model:SetRoll(ZERO)
        local model = CreateBossModel("SWtitan", 6, -27, -65, 23863, .7)
        model:SetPosition(-1, ZERO, ZERO)
        model:SetFacing(ZERO)
        model:SetPitch(ZERO)
        model:SetRoll(ZERO)
        -- CreateAllTestButton(model)
        local model = CreateBossModel("SWtitan", 13, 50, 10, 25315, .75)
        model:SetPosition(ZERO, ZERO, ONE)
        model:SetFacing(-.1)
        model:SetPitch(C_053)
        model:SetRoll(ZERO)
        local modelFrame = CreateFrame("PlayerModel", nil, model, "BackdropTemplate")
        modelFrame:SetSize(400, 400)
        modelFrame:SetPoint("CENTER", -20, -30)
        modelFrame:SetModel(194045) -- 166112,166149,166303,167000火焰 194045火墙
        modelFrame:SetPosition(-40, -6, ZERO)
        modelFrame:SetFrameLevel(model:GetFrameLevel() + ONE)
        modelFrame:SetKeepModelOnHide(true)
        modelFrame:ClearTransform()
        modelFrame:SetCamDistanceScale(4) -- 镜头远近，数值越大模型越小
        local model = CreateBossModel("ULDtitan", 14, ZERO, ZERO, 32871, C_045)
        model:SetPosition(ZERO, ZERO, ZERO)
        model:SetFacing(ZERO)
        model:SetPitch(ZERO)
        model:SetRoll(ZERO)
    end
    if BG.IsCTM then
        local model = CreateBossModel("BOT", 5, 40, 110, 45213, 0.7)
        model:SetPosition(-2, ZERO, ZERO) -- Z,X,Y
        model:SetFacing(-0.1)       -- 左右
        model:SetPitch(ZERO)           -- 上下
        model:SetRoll(ZERO)            -- 倾斜
        -- -- CreateAllTestButton(model)
        local model = CreateBossModel("BOT", 11, 50, -30, 41376, 0.7)
        model:SetPosition(-8, ZERO, ZERO)    -- Z,X,Y
        model:SetFacing(math.rad(-20)) -- 左右
        model:SetPitch(ZERO)              -- 上下
        model:SetRoll(ZERO)               -- 倾斜
        -- CreateAllTestButton(model)
        local model = CreateBossModel("BOT", 13, ZERO, -20, 46753, C_06)
        model:SetPosition(-20, ZERO, ZERO) -- Z,X,Y
        model:SetFacing(ZERO)           -- 左右
        model:SetPitch(ZERO)            -- 上下
        model:SetRoll(ZERO)             -- 倾斜
        -- -- CreateAllTestButton(model)
        local model = CreateBossModel("FL", 7, 30, 40, 52409, 0.55)
        model:SetPosition(-25, ZERO, 9) -- Z,X,Y
        model:SetFacing(ZERO)           -- 左右
        model:SetPitch(ZERO)            -- 上下
        model:SetRoll(ZERO)             -- 倾斜
        -- CreateAllTestButton(model)
        local model = CreateBossModel("DS", 8, 50, -30, 47103, .9)
        model:SetPosition(-8, ZERO, ZERO)    -- Z,X,Y
        model:SetFacing(math.rad(-20)) -- 左右
        model:SetPitch(ZERO)              -- 上下
        model:SetRoll(ZERO)               -- 倾斜
        -- CreateAllTestButton(model)
    end
    if BG.IsMOP then
        local model = CreateBossModel("MSV", 6, ZERO, ZERO, 60400, .55)
        model:SetPosition(-0, ZERO, ZERO) -- Z,X,Y
        model:SetFacing(ZERO)          -- 左右
        model:SetPitch(ZERO)           -- 上下
        model:SetRoll(ZERO)            -- 倾斜
        -- CreateAllTestButton(model)
        local model = CreateBossModel("MSV", 12, 10, 20, 62837, .75)
        model:SetPosition(-1, ZERO, ZERO)    -- Z,X,Y
        model:SetFacing(math.rad(-10)) -- 左右
        model:SetPitch(ZERO)              -- 上下
        model:SetRoll(ZERO)               -- 倾斜
        -- CreateAllTestButton(model)
        local model = CreateBossModel("MSV", 16, 20, 60, 60999, .7)
        model:SetPosition(-1, ZERO, ZERO)    -- Z,X,Y
        model:SetFacing(math.rad(-10)) -- 左右
        model:SetPitch(ZERO)              -- 上下
        model:SetRoll(ZERO)               -- 倾斜
        -- CreateAllTestButton(model)
        local model = CreateBossModel("TOT", 12, -20, -50, 68397, .55)
        model:SetPosition(-0, ZERO, ZERO) -- Z,X,Y
        model:SetFacing(ZERO)          -- 左右
        model:SetPitch(ZERO)           -- 上下
        model:SetRoll(ZERO)            -- 倾斜
        -- CreateAllTestButton(model)
        local model = CreateBossModel("SOO", 14, 5, -20, 71865, .55)
        model:SetPosition(-0, ZERO, ZERO) -- Z,X,Y
        model:SetFacing(ZERO)          -- 左右
        model:SetPitch(ZERO)           -- 上下
        model:SetRoll(ZERO)            -- 倾斜
        -- CreateAllTestButton(model)
    end
    if BG.IsRetail then
        local model = CreateBossModel("VS", 6, 15, -50, 244761, C_045)
        model:SetPosition(-0, ZERO, ZERO) -- Z,X,Y
        model:SetFacing(ZERO)          -- 左右
        model:SetPitch(ZERO)           -- 上下
        model:SetRoll(ZERO)            -- 倾斜
        -- model:SetPosition(-0, 0, 0)
        -- model:SetFacing(-0.2)
        -- model:SetPitch(0)
        -- model:SetRoll(0)
        local model = CreateBossModel("VS", 9, -5, 20, 214650, C_06)
        model:SetPosition(-0, ZERO, ZERO) -- Z,X,Y
        model:SetFacing(ZERO)          -- 左右
        model:SetPitch(ZERO)           -- 上下
        model:SetRoll(ZERO)            -- 倾斜
        -- model:SetPosition(-3, 0, 1)
        -- -- model:SetFacing(-0.2)
        -- model:SetPitch(0)
        -- model:SetRoll(0)
        -- CreateAllTestButton(model)
        local model = CreateBossModel("VA", 8, ZERO, 30, 268956, 1.1)
        model:SetPosition(-60, ZERO, ZERO) -- Z,X,Y
        model:SetFacing(-.2)          -- 左右
        model:SetPitch(ZERO)           -- 上下
        model:SetRoll(ZERO)            -- 倾斜
    end
end
