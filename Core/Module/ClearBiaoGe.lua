if BG.IsBlackListPlayer then return end
local AddonName, ns = ...

local L = ns.L

local SetClassCFF = ns.SetClassCFF
local AddTexture = ns.AddTexture

local Maxb = ns.Maxb
local HopeMaxn = ns.HopeMaxn
local HopeMaxi = ns.HopeMaxi

local realmID = GetRealmID()
local player = BG.playerName
local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded
local GetLootMethod = GetLootMethod or C_PartyInfo.GetLootMethod

-- Keep one check per character and stage for each weekly reset. A character can
-- enter another instance in the same shared table before either raid is locked.
local function GetStageCycleEnd()
    local now = GetServerTime()
    if C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset then
        local seconds = tonumber(C_DateAndTime.GetSecondsUntilWeeklyReset())
        if seconds and seconds > 0 then
            return now + seconds
        end
    end
    if BG.GetNextWeekTime then
        local _, resetAt = BG.GetNextWeekTime()
        if type(resetAt) == "number" and resetAt > now then
            return resetAt
        end
    end
end

local function GetCheckedStageCycleEnd(FB)
    local byRealm = BiaoGe.autoClearStageCycle and BiaoGe.autoClearStageCycle[realmID]
    local byPlayer = byRealm and byRealm[player]
    return byPlayer and byPlayer[FB]
end

local function MarkStageChecked(FB, cycleEnd)
    if not cycleEnd then return end
    BiaoGe.autoClearStageCycle = BiaoGe.autoClearStageCycle or {}
    local byRealm = BiaoGe.autoClearStageCycle
    byRealm[realmID] = byRealm[realmID] or {}
    local byPlayer = byRealm[realmID]
    byPlayer[player] = byPlayer[player] or {}
    byPlayer[player][FB] = cycleEnd
end

local function GetAutoClearDecision(instanceID, savedInstanceCount, getSavedInstanceInfo, hasLedgerItem,
                                    cycleEnd, checkedCycleEnd)
    local FB = BG.FBIDtable[instanceID]
    if not FB then
        return { shouldClear = false, reason = "unknown-instance" }
    end

    local range = BG.bossPositionStartEnd[instanceID]
    if type(range) ~= "table" then
        return { shouldClear = false, FB = FB, reason = "unknown-boss-range" }
    end

    if cycleEnd and type(checkedCycleEnd) == "number" and math.abs(cycleEnd - checkedCycleEnd) <= 120 then
        return { shouldClear = false, FB = FB, reason = "stage-already-checked" }
    end

    savedInstanceCount = savedInstanceCount or GetNumSavedInstances()
    getSavedInstanceInfo = getSavedInstanceInfo or GetSavedInstanceInfo
    for i = 1, savedInstanceCount do
        local _, _, _, _, locked, _, _, _, _, _, _, _, _, savedInstanceID = getSavedInstanceInfo(i)
        if locked and BG.FBIDtable[savedInstanceID] == FB then
            return { shouldClear = false, FB = FB, reason = "stage-locked" }
        end
    end

    hasLedgerItem = hasLedgerItem or BG.BiaoGeHavedItem
    if hasLedgerItem(FB, "onlyboss") then
        return {
            shouldClear = true,
            FB = FB,
            reason = "stage-has-old-data",
            startBoss = 1,
            endBoss = Maxb[FB] - 2,
        }
    end

    return { shouldClear = false, FB = FB, reason = "stage-empty" }
end

local function ClearCurrentStage(decision)
    local FB = decision.FB
    BG.ClickFBbutton(FB)
    local num = BG.ClearBiaoGe("biaoge", FB)
    BG.SendSystemMessage(format(L["已自动清空表格< %s >，分钱人数已改为%s人。"], BG.GetFBinfo(FB, "shortName"), num))
    if decision.reason == "stage-has-old-data" then
        BG.SendSystemMessage(L['自动清空表格的原因：1.当前副本你是新CD；2.%s']:format(
            L['当前副本所在的表格BOSS编号（%s-%s）格子中存在旧记录。']:format(
                decision.startBoss, decision.endBoss)))
    end
    BG.PlaySound("qingkong")
end

local function CheckAutoClearForInstance(instanceID)
    local FB = BG.FBIDtable[instanceID]
    if not FB then return end
    local cycleEnd = GetStageCycleEnd()
    local decision = GetAutoClearDecision(instanceID, nil, nil, nil,
        cycleEnd, GetCheckedStageCycleEnd(FB))
    if decision.shouldClear then
        ClearCurrentStage(decision)
    end
    if decision.reason == "stage-has-old-data" or decision.reason == "stage-empty" then
        MarkStageChecked(FB, cycleEnd)
    end
    return decision
end

local RAID_PLAYER_DEFAULTS = {
    { flag = "IsVanilla", default = 40 },
    { flag = "IsTBC", default = 25 },
    { flag = "IsTitan", default = 25, titan = true },
    { flag = "IsRetail", default = 20 },
}

local DIFFICULTY_RAID_SIZE = {
    [3] = 10, [175] = 10,
    [4] = 25, [176] = 25,
    [5] = 10, [193] = 10,
    [6] = 25, [194] = 25,
}

local CLEAR_UI_TEXT_FIELDS = { "zhuangbei", "maijia", "jine" }
local CLEAR_UI_HIDE_FIELDS = { "qiankuan", "guanzhu" }
local CLEAR_DB_FIELDS = {
    "zhuangbei", "maijia", "jine", "qiankuan", "guanzhu",
    "loot", "itemLevel", "bindOnEquip",
}

local FREE_CLEAR_BUTTON_SPECS = {
    {
        text = L["全选"],
        point = "TOPRIGHT", relPoint = "TOPRIGHT",
        x = -10, y = -30,
        field = "chooseAllButton", choose = true,
    },
    {
        text = L["取消全选"],
        point = "TOP", anchorField = "chooseAllButton", relPoint = "BOTTOM",
        x = 0, y = -5,
        field = "cancelAllButton",
    },
    {
        text = L["确定清空表格"],
        point = "TOP", anchorField = "cancelAllButton", relPoint = "BOTTOM",
        x = 0, y = -40,
        field = "sureButton",
    },
}

local FREE_CLEAR_BACKDROP = {
    bgFile = "Interface/ChatFrame/ChatFrameBackground",
    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
    edgeSize = 1,
}

local function FreeClearOnHide(self)
    self:Hide()
end

local function FreeClearOnMouseUp(self)
    self:StopMovingOrSizing()
end

local function FreeClearOnMouseDown(self)
    self:StartMoving()
end

local function AddGoldDoubleLine(label, value)
    GameTooltip:AddDoubleLine(label, value, 1, .82, 0, 1, .82, 0)
end

local function ResolveRaidPlayerCount(FB)
    local num
    for _, rule in ipairs(RAID_PLAYER_DEFAULTS) do
        if BG[rule.flag] then
            if rule.titan and BiaoGe.options["QingKongPeople"] == 1
                and tonumber(BiaoGe.options["MaxPlayers_Titan"])
                and FB ~= "Worldtitan"
            then
                num = tonumber(BiaoGe.options["MaxPlayers_Titan"])
            else
                num = BG.GetFBinfo(FB, "maxplayers") or rule.default
            end
            break
        end
    end
    if num then
        return num
    end
    local size = DIFFICULTY_RAID_SIZE[GetRaidDifficultyID()]
    if size then
        local optionKey = size == 10 and "10MaxPlayers" or "25MaxPlayers"
        return (BiaoGe.options["QingKongPeople"] == 1 and BiaoGe.options[optionKey]) or size
    end
    return 25
end

local function ClearBiaoGeTable(FB)
    for b = 1, Maxb[FB] + 1 do
        BG.ClearBiaoGeByIndex(FB, b)
    end
    BiaoGe[FB].tradeTbl = {}
    BiaoGe[FB].raidRoster = nil
    BiaoGe[FB].auctionLog = nil
    BiaoGe[FB].leaderInfo = nil
    BG.UpdateAuctionLogFrame()
    BG.auctionLogFrame.changeFrame:Hide()

    local num = ResolveRaidPlayerCount(FB)
    if num then
        local totalBossKey = "boss" .. (Maxb[FB] + 2)
        BG.Frame[FB][totalBossKey]["jine4"]:SetText(num)
        BiaoGe[FB][totalBossKey]["jine4"] = num
    end

    local money = floor(GetMoney() / 1e4)
    BiaoGe.clearBiaoGeMoney = BiaoGe.clearBiaoGeMoney or {}
    BiaoGe.clearBiaoGeMoney[FB] = {
        FB = FB,
        realmID = realmID,
        name = player,
        money = money,
        time = GetServerTime()
    }
    BG.UpdateButtonClearBiaoGeMoney()
    return num
end

local CLEAR_TYPE_HANDLERS = {
    biaoge = ClearBiaoGeTable,
}

local function ClearFreeAuctionLog(FB)
    BiaoGe[FB].auctionLog = nil
    BG.UpdateAuctionLogFrame()
    BG.auctionLogFrame.changeFrame:Hide()
end

local NUMBER_CLEAR_ACTION = function(FB, b)
    BG.ClearBiaoGeByIndex(FB, b)
end

local FREE_CLEAR_ACTIONS = {
    auctionLog = ClearFreeAuctionLog,
}

local function FreeClearCheckOnClick(self)
    self.clearFrame.sureButton:Update()
end

local function CreateFreeClearCheckButton(frame, id, text)
    local bt = CreateFrame("CheckButton", nil, frame, "ChatConfigCheckButtonTemplate")
    bt:SetSize(30, 30)
    if next(frame.buttons) then
        bt:SetPoint("TOPLEFT", frame.buttons[#frame.buttons], "BOTTOMLEFT", 0, 0)
    else
        bt:SetPoint("TOPLEFT", 10, -30)
    end
    bt.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
    bt.Text:SetText(text)
    bt:SetHitRectInsets(0, -bt.Text:GetWidth(), 0, 0)
    bt.id = id
    bt.clearFrame = frame
    tinsert(frame.buttons, bt)
    bt:HookScript("OnClick", FreeClearCheckOnClick)
end

local function CreateFreeClearActionButton(frame, spec)
    local bt = BG.CreateButton(frame)
    bt:SetSize(110, 25)
    local anchor = spec.anchorField and frame[spec.anchorField] or frame
    bt:SetPoint(spec.point, anchor, spec.relPoint, spec.x, spec.y)
    bt:SetText(spec.text)
    if spec.choose then
        bt.choose = true
    end
    frame[spec.field] = bt
    return bt
end

local function FreeClearToggleAll(self)
    BG.PlaySound(1)
    local frame = self:GetParent()
    for _, bt in ipairs(frame.buttons) do
        bt:SetChecked(self.choose)
    end
    frame.sureButton:Update()
end

local function FreeClearSureOnClick(self)
    local frame = self:GetParent()
    local FB = frame.clearFB
    for _, bt in ipairs(frame.buttons) do
        if bt:GetChecked() then
            local action = type(bt.id) == "number" and NUMBER_CLEAR_ACTION or FREE_CLEAR_ACTIONS[bt.id]
            if action then
                action(FB, bt.id)
            end
        end
    end
    BG.PlaySound(2)
    frame:Hide()
end


local function ApplyMoneyColor(button, r, g, b)
    button.Text:SetTextColor(r, g, b)
    button.title.Text:SetTextColor(r, g, b)
end

function BG.ClearBiaoGeUI()
    function BG.ClearBiaoGeByIndex(FB, b)
        local uiFrame = BG.Frame[FB]
        local dbTable = BiaoGe[FB]
        if b == Maxb[FB] + 1 then
            local maxIndex = math.max(BG.Maxi + 10, BG.GetMaxi(FB, b))
            local rowKey = "boss" .. (Maxb[FB] + 1)
            local uiRow = uiFrame[rowKey]
            local dbRow = dbTable[rowKey]
            for i = 1, maxIndex do -- 清空支出
                if uiRow["zhuangbei" .. i] then
                    if BiaoGe.options["retainExpenses"] ~= 1 then
                        uiRow["zhuangbei" .. i]:SetText("")
                        dbRow["zhuangbei" .. i] = nil
                    end
                    if not (BiaoGe.options["retainExpenses"] == 1 and BiaoGe.options["retainExpensesMoney"] == 1) then
                        uiRow["jine" .. i]:SetText("")
                        dbRow["jine" .. i] = nil
                    end
                    uiRow["maijia" .. i]:SetText("")
                    dbRow["maijia" .. i] = nil
                end
            end
        elseif b <= Maxb[FB] then
            local maxIndex = math.max(BG.Maxi + 10, BG.GetMaxi(FB, b))
            local rowKey = "boss" .. b
            local uiRow = uiFrame[rowKey]
            local dbRow = dbTable[rowKey]
            local dzRow = BG.DuiZhangFrame[FB][rowKey]
            for i = 1, maxIndex do
                -- 表格
                if uiRow["zhuangbei" .. i] then
                    for _, field in ipairs(CLEAR_UI_TEXT_FIELDS) do
                        uiRow[field .. i]:SetText("")
                    end
                    for _, field in ipairs(CLEAR_UI_HIDE_FIELDS) do
                        uiRow[field .. i]:Hide()
                    end
                end
                for _, field in ipairs(CLEAR_DB_FIELDS) do
                    dbRow[field .. i] = nil
                end
                for k in pairs(BG.playerClass) do
                    dbRow[k .. i] = nil
                end
                -- 对账
                if dzRow["zhuangbei" .. i] then
                    dzRow["zhuangbei" .. i]:SetText("")
                    dzRow["myjine" .. i]:SetText("")
                end
            end
        end
    end

    function BG.ClearBiaoGe(_type, FB)
        if not FB then return end
        local handler = CLEAR_TYPE_HANDLERS[_type]
        if handler then
            return handler(FB)
        end
    end

    -- 清空按钮
    do
        local bt = BG.CreateButton(BG.FBMainFrame)
        bt:SetSize(120, 25)
        bt:SetPoint("BOTTOMLEFT", BG.MainFrame, "BOTTOMLEFT", 30, 38)
        bt:SetText(L["清空表格"])
        bt:RegisterForClicks("AnyUp")
        BG.ButtonQingKong = bt
        -- 按钮触发
        bt:SetScript("OnClick", function(self, button)
            BG.PlaySound(1)
            if button == "LeftButton" then
                StaticPopup_Show("QINGKONGBIAOGE")
            elseif button == "RightButton" then
                GameTooltip:Hide()
                BG.CreateFreeClearBiaoGeFrame()
            end
        end)
        bt:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["清空表格"], 1, 1, 1, true)
            GameTooltip:AddLine(L["一键清空全部装备、买家、金额，同时还清空关注和欠款。如果有自动拍卖记录，则也会被清空。"], 1, 0.82, 0, true)
            GameTooltip:AddLine(" ", 1, 0.82, 0, true)
            GameTooltip:AddLine(AddTexture("LEFT") .. L["清空全部"], 1, 0.82, 0, true)
            GameTooltip:AddLine(AddTexture("RIGHT") .. L["清空部分内容（自选）"], 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        BG.GameTooltip_Hide(bt)

        StaticPopupDialogs["QINGKONGBIAOGE"] = {
            text = L["确定清空表格？"],
            button1 = L["是"],
            button2 = L["否"],
            OnAccept = function()
                local num = BG.ClearBiaoGe("biaoge", BG.FB1)
                if num then
                    BG.SendSystemMessage(BG.STC_b1(format(
                        L["已清空表格< %s >，分钱人数已改为%s人。"], BG.GetFBinfo(BG.FB1, "shortName"), num)))
                else
                    BG.SendSystemMessage(BG.STC_b1(format(
                        L["已清空表格< %s >。"], BG.GetFBinfo(BG.FB1, "shortName"))))
                end
                BG.PlaySound(2)
            end,
            OnCancel = function()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            showAlert = true,
        }
    end

    -- 自动清空表格
    do
        local function SendTips(FB)
            if (FB == "ZUG" or FB == "ZUGsod") and BG.IsVanilla and IsInRaid(1) and UnitIsGroupLeader("player") then
                BG.SendSystemMessage(L["提醒团长：如果你没有物品分配权，将会导致交易的相关功能失效。"])
            end
        end

        local needCheck
        local function CheckCD()
            BG.After(3, function()
                local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
                local FB = BG.FBIDtable[instanceID]
                SendTips(FB)
                if BG.IsTBCFB(FB) and not ns.canShowTBC then return end
                if not (FB and IsInInstance()) then return end
                CheckAutoClearForInstance(instanceID)
            end)
        end
        BG.RegisterEvent("RAID_INSTANCE_WELCOME", function(self, event, ...)
            needCheck = true
            RequestRaidInfo()
        end)
        BG.RegisterEvent("UPDATE_INSTANCE_INFO", function()
            if needCheck then
                needCheck = nil
                CheckCD()
            end
        end)
    end

    -- 清空时记录身上金币
    do
        local poit

        local function OnEnter(self)
            local FB = BG.FB1
            local entry = BiaoGe.clearBiaoGeMoney[FB]
            local p = SetClassCFF(entry.name)
            local f = BG.GetFBinfo(entry.FB, "shortName")
            local t = date("%m-%d %H:%M", entry.time)
            local m = GetMoneyString(entry.money .. "0000", true)
            GameTooltip:SetOwner(poit, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["清空表格时携带的金币"], 1, 1, 1, true)
            GameTooltip:AddLine(" ")
            AddGoldDoubleLine(L["角色："], p)
            AddGoldDoubleLine(L["表格："], f)
            AddGoldDoubleLine(L["时间："], t)
            AddGoldDoubleLine(L["金币："], m)
            GameTooltip:Show()
        end

        function BG.UpdateButtonClearBiaoGeMoney()
            local FB = BG.FB1
            local f = BG.ButtonClearBiaoGeMoney
            local entry = BiaoGe.clearBiaoGeMoney and BiaoGe.clearBiaoGeMoney[FB]
            if not entry then
                f:Hide()
            else
                local jine = BG.Frame[FB]["boss" .. Maxb[FB] + 2].jine5
                f:Show()
                f:ClearAllPoints()
                f:SetPoint("TOPRIGHT", jine, "BOTTOMRIGHT", 1, -1)
                f.Text:SetText(entry.money)
                if entry.realmID == realmID and entry.name == player then
                    ApplyMoneyColor(f, 1, .82, 0)
                else
                    ApplyMoneyColor(f, .5, .5, .5)
                end
            end
        end

        local jine = BG.Frame[BG.FB1]["boss" .. Maxb[BG.FB1] + 2].jine5
        local f = CreateFrame("Frame", nil, BG.FBMainFrame, "BackdropTemplate")
        f:SetSize(jine:GetWidth(), 20)
        BG.ButtonClearBiaoGeMoney = f
        local t = f:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
        t:SetAllPoints()
        t:SetJustifyH("LEFT")
        t:SetTextColor(1, .82, 0)
        f.Text = t
        f:SetScript("OnEnter", OnEnter)
        f:SetScript("OnLeave", GameTooltip_Hide)

        local f = CreateFrame("Frame", nil, BG.ButtonClearBiaoGeMoney, "BackdropTemplate")
        f:SetSize(0, 20)
        f:SetPoint("RIGHT", BG.ButtonClearBiaoGeMoney, "LEFT", 0, 0)
        poit = f
        BG.ButtonClearBiaoGeMoney.title = f
        local t = f:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
        t:SetPoint("RIGHT")
        t:SetTextColor(1, .82, 0)
        t:SetJustifyH("RIGHT")
        t:SetText(L["清空表格时的金币："])
        t:SetWordWrap(false)
        f:SetWidth(min(t:GetStringWidth() + 20, 160))
        f.Text = t
        f:SetScript("OnEnter", OnEnter)
        f:SetScript("OnLeave", GameTooltip_Hide)

        BG.UpdateButtonClearBiaoGeMoney()
    end

    -- 自定义清空
    function BG.CreateFreeClearBiaoGeFrame()
        if BG.freeClearBiaoGeFrame and BG.freeClearBiaoGeFrame:IsVisible() then
            BG.freeClearBiaoGeFrame:Hide()
            return
        end
        if BG.exportFrame then
            BG.exportFrame:Hide()
        end
        local FB = BG.FB1
        local parent = BG["Frame" .. FB]
        local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        f:SetBackdrop(FREE_CLEAR_BACKDROP)
        f:SetBackdropColor(0, 0, 0, 0.9)
        f:SetBackdropBorderColor(1, 1, 1, BG.borderAlpha)
        f:SetPoint("BOTTOMLEFT", BG.ButtonQingKong, "TOPLEFT", 0, 5)
        f:SetSize(350, 450)
        f:EnableMouse(true)
        f:SetMovable(true)
        f:SetFrameStrata("HIGH")
        f.buttons = {}
        f.clearFB = FB
        f:SetScript("OnHide", FreeClearOnHide)
        f:SetScript("OnMouseUp", FreeClearOnMouseUp)
        f:SetScript("OnMouseDown", FreeClearOnMouseDown)
        BG.freeClearBiaoGeFrame = f

        BG.CreateCloseButton(f)

        local l = f:CreateLine()
        l:SetColorTexture(1, 1, 1, BG.borderAlpha)
        l:SetStartPoint("TOPLEFT", 1, -21)
        l:SetEndPoint("TOPRIGHT", -1, -21)
        l:SetThickness(1)

        f.titleText = f:CreateFontString()
        f.titleText:SetPoint("CENTER", f, "TOP", 0, -11)
        f.titleText:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        f.titleText:SetFormattedText(L["清空表格（%s）"], BG.GetFBinfo(FB, "shortName"))

        local bossCount = Maxb[FB] + 1
        local bossTable = BG.Boss[FB]
        for b = 1, bossCount do
            local boss = bossTable["boss" .. b]
            CreateFreeClearCheckButton(f, b, "|cff" .. boss.color .. boss.name2)
        end
        CreateFreeClearCheckButton(f, "auctionLog", L["自动拍卖记录"])
        f:SetHeight(#f.buttons * 30 + 40)

        for _, spec in ipairs(FREE_CLEAR_BUTTON_SPECS) do
            local bt = CreateFreeClearActionButton(f, spec)
            if spec.field == "sureButton" then
                bt:SetScript("OnClick", FreeClearSureOnClick)
            else
                bt:SetScript("OnClick", FreeClearToggleAll)
            end
        end
        function f.sureButton:Update()
            self:Disable()
            for _, bt in ipairs(f.buttons) do
                if bt:GetChecked() then
                    self:Enable()
                end
            end
        end

        f.sureButton:Update()
    end

end
