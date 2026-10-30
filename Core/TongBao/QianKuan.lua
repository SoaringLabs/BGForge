local AddonName, ns = ...

local L = ns.L

local RR = ns.RR
local SetClassCFF = ns.SetClassCFF
local RGB_16 = ns.RGB_16

local Maxb = ns.Maxb


local function AppendReportLine(flatRows, groupedRows, text)
    table.insert(flatRows, text)
    table.insert(groupedRows, { text })
end

local function CollectRosterIndexes(filter)
    local indexes = {}
    local total = GetNumGroupMembers()
    for rosterIndex = 1, total do
        local unitName, _, subgroup = GetRaidRosterInfo(rosterIndex)
        if filter(unitName, subgroup) then
            tinsert(indexes, rosterIndex)
        end
    end
    return indexes
end

------------------用于通报欠款的函数-----------------
local function ReadDebtEntries(raidKey)
    local entries = {}
    local buyerSet = {}
    local bossCount = Maxb[raidKey]
    for bossIdx = 1, bossCount do
        local slotCount = BG.GetMaxi(raidKey, bossIdx)
        for i = 1, slotCount do
            local debtField = BG.Frame[raidKey]["boss" .. bossIdx]["qiankuan" .. i]
            if debtField then
                local storedDebt = BiaoGe[raidKey]["boss" .. bossIdx]["qiankuan" .. i]
                if storedDebt then
                    local buyerField = BG.Frame[raidKey]["boss" .. bossIdx]["maijia" .. i]
                    local buyerName = buyerField:GetText()
                    if buyerName == "" then
                        buyerName = L["没记买家"]
                    end
                    tinsert(entries, {
                        zhuangbei = BG.Frame[raidKey]["boss" .. bossIdx]["zhuangbei" .. i]:GetText(),
                        maijia = buyerName,
                        color = { buyerField:GetTextColor() },
                        qiankuan = tonumber(storedDebt),
                    })
                    buyerSet[buyerName] = true
                end
            end
        end
    end
    return entries, buyerSet
end

local function SumDebt(entries, buyerSet)
    local grandTotal = 0
    for _, entry in ipairs(entries) do
        grandTotal = entry.qiankuan + grandTotal
    end

    local totals = {}
    for buyerName in pairs(buyerSet) do
        local runningTotal = 0
        local color
        for _, entry in ipairs(entries) do
            if buyerName == entry.maijia then
                runningTotal = entry.qiankuan + runningTotal
                color = entry.color
            end
        end
        tinsert(totals, { maijia = buyerName, color = color, qiankuan = runningTotal })
    end
    sort(totals, function(left, right)
        return left.qiankuan > right.qiankuan
    end)
    return totals, grandTotal
end

local function DebtLine(preview, entry)
    if preview then
        return L["欠款："] .. entry.maijia .. " " .. BG.FormatNumber(entry.qiankuan, 5)
    end
    return L["欠款："] .. RGB_16(entry.maijia, unpack(entry.color)) .. " |cffFF0000" .. BG.FormatNumber(entry.qiankuan, 5) .. RR
end

local function TotalDebtLine(preview, grandTotal)
    if preview then
        return L["总欠款："] .. BG.FormatNumber(grandTotal, 5)
    end
    return L["总欠款："] .. " |cffFF0000" .. BG.FormatNumber(grandTotal, 5) .. RR
end

local function CreateListTable(preview, flatRows)
    local entries, buyerSet = ReadDebtEntries(BG.FB1)
    local totals, grandTotal = SumDebt(entries, buyerSet)

    -- 开始
    local flatRows = flatRows or {}
    local groupedRows = {}
    AppendReportLine(flatRows, groupedRows, L["———通报欠款———"])

    if #entries == 0 then
        AppendReportLine(flatRows, groupedRows, L["没有欠款"])
        return flatRows, groupedRows, totals
    end

    for _, entry in ipairs(totals) do
        AppendReportLine(flatRows, groupedRows, DebtLine(preview, entry))
    end
    AppendReportLine(flatRows, groupedRows, TotalDebtLine(preview, grandTotal))
    return flatRows, groupedRows, totals
end

local function ShowReportTooltip(anchor, lines)
    GameTooltip:SetOwner(anchor, "ANCHOR_TOPLEFT", 0, 0);
    GameTooltip:ClearLines()
    for _, entry in ipairs(lines) do
        GameTooltip:AddLine(entry)
    end
    GameTooltip:Show()
    GameTooltip:SetClampedToScreen(false)
end

local function HideReportTooltip()
    GameTooltip:Hide()
    GameTooltip:SetClampedToScreen(true)
end

local function SendReport(button, builder)
    BG.FrameHide(0)
    if BG.IsErrorSendChannel() then return end
    button:SetEnabled(false)
    C_Timer.After(2, function()
        button:SetEnabled(true)
    end)

    local _, rows = builder(true)
    BG.SendMsgToRaid(rows)

    BG.PlaySound(2)
end

local function AddTooltipError(text)
    GameTooltip:AddLine(text, 1, 0, 0, true)
    GameTooltip:Show()
end


function BG.QianKuanUI(previousButton)
    local bt = BG.CreateButton(BG.ButtonZhangDan)
    bt:SetSize(BG.ButtonZhangDan:GetWidth(), BG.ButtonZhangDan:GetHeight())
    bt:SetPoint("LEFT", previousButton, "RIGHT", BG.ButtonZhangDan.jiange, 0)
    bt:SetText(L["欠款"])
    BG.ButtonQianKuan = bt
    tinsert(BG.TongBaoButtons, bt)

    bt:SetScript("OnEnter", function(self)
        if BG.Backing then return end
        local markTexture = CreateListTable(nil)

        ShowReportTooltip(self, markTexture)
    end)
    bt:SetScript("OnLeave", HideReportTooltip)
    -- 单击触发
    bt:SetScript("OnClick", function(self)
        SendReport(self, CreateListTable)
    end)

    return bt
end

-- 欠款者移到78队
BG.Init(function()
    local bt
    local qkPlayers
    local function IsLeader()
        return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
    end
    local function CanMove()
        if IsLeader() and not InCombatLockdown() then
            return true
        else
            bt:SetEnabled(true)
        end
    end
    local function GetSupgroupEmpty()
        local tbl = {}
        for i = 1, 8 do
            tbl[i] = 5
        end
        for rosterIndex = 1, GetNumGroupMembers() do
            local _, _, subgroup = GetRaidRosterInfo(rosterIndex)
            tbl[subgroup] = tbl[subgroup] - 1
        end
        return tbl
    end
    local function FillFreeSlots(indexes, maxGroup)
        if not next(indexes) then return end
        local freeSlots = {}
        local freeCounts = GetSupgroupEmpty()
        for groupNo = 1, maxGroup do
            for _ = 1, freeCounts[groupNo] do
                tinsert(freeSlots, groupNo)
            end
        end
        for i, rosterIndex in ipairs(indexes) do
            if freeSlots[i] then
                SetRaidSubgroup(rosterIndex, freeSlots[i])
            end
        end
        return true
    end
    local function Move(groupNo)
        if not CanMove() then return end
        if groupNo <= 1 then
            BG.SendSystemMessage(L["队伍调整已完成。"])
            bt:SetEnabled(true)
            PlaySoundFile("Interface\\AddOns\\" .. AddonName .. "\\Media\\sound\\other\\done.mp3", "Master")
            return
        end
        local indexes = CollectRosterIndexes(function(unitName, subgroup)
            return subgroup == groupNo and unitName ~= BG.playerName
        end)
        if FillFreeSlots(indexes, groupNo - 1) then
            BG.After(.5, function()
                Move(groupNo - 1)
            end)
        else
            Move(groupNo - 1)
        end
    end
    local function Move78()
        if not CanMove() then return end
        local indexes = CollectRosterIndexes(function(unitName, subgroup)
            return (subgroup == 7 or subgroup == 8) and not BG.ValueInTable(qkPlayers, unitName)
        end)
        return FillFreeSlots(indexes, 6)
    end
    local function Move16()
        if not CanMove() then return end
        local indexes = CollectRosterIndexes(function(unitName)
            return BG.ValueInTable(qkPlayers, unitName)
        end)
        for i, rosterIndex in ipairs(indexes) do
            SetRaidSubgroup(rosterIndex, i <= 5 and 8 or 7) -- 前5个先移到8队，后5个移到7队
        end
        BG.After(.5, function()
            if not BG.ValueInTable(qkPlayers, BG.playerName) then
                for rosterIndex = 1, GetNumGroupMembers() do
                    local unitName, _, subgroup = GetRaidRosterInfo(rosterIndex)
                    if unitName == BG.playerName then
                        SetRaidSubgroup(rosterIndex, 6) -- 把自己调到6队
                        BG.After(.5, function()
                            Move(6)
                        end)
                        return
                    end
                end
            else
                Move(6)
            end
        end)
    end

    -- 先把第7、8队清空，将欠款者放进这两队，再把第6到第1队依次往前挪，填补空位
    function BG.SetRaidSubgroup()
        if not CanMove() then return end
        BG.After((Move78() and .5 or 0), Move16)
    end

    bt = BG.CreateButton(RaidFrame)
    bt:SetSize(90, 25)
    bt:SetPoint("TOPRIGHT", FriendsFrame, "BOTTOMRIGHT", -2, -2)
    bt:SetText(L["移动欠款者"])
    bt:SetShown(IsInRaid(1) and IsLeader())
    bt:SetScript("OnClick", function(self)
        if qkPlayers then
            self:SetEnabled(false)
            BG.SetRaidSubgroup()
            BG.PlaySound(2)
        end
    end)
    bt:SetScript("OnEnter", function(self)
        qkPlayers = nil
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L["把欠款者移到78队"], 1, 1, 1, true)
        if not IsInRaid(1) then
            AddTooltipError(L["不在团队，该功能无法使用。"])
            return
        end
        if not IsLeader() then
            AddTooltipError(L["你不是团长或助理，该功能无法使用。"])
            return
        end
        if InCombatLockdown() then
            AddTooltipError(L["战斗中，该功能无法使用。"])
            return
        end
        if GetNumGroupMembers() > 30 then
            AddTooltipError(L["团队人数超过30人，该功能无法使用。"])
            return
        end
        local _, _, players = CreateListTable(nil)
        if not next(players) then
            AddTooltipError(L["没有欠款。"])
            return
        end
        if #players > 10 then
            AddTooltipError(L["欠款者超过10人，该功能无法使用。"])
            return
        end
        local tbl = {}
        for i, v in ipairs(players) do
            GameTooltip:AddLine(format(L["%s. %s（欠款%s）"], i, SetClassCFF(v.maijia), v.qiankuan), 1, 0.82, 0)
            tinsert(tbl, v.maijia)
        end
        GameTooltip:Show()
        qkPlayers = tbl
    end)
    bt:SetScript("OnLeave", GameTooltip_Hide)

    BG.RegisterEvent("GROUP_ROSTER_UPDATE", function()
        BG.After(0.5, function()
            bt:SetShown(IsInRaid(1) and IsLeader())
        end)
    end)
end)
