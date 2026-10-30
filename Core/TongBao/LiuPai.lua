local AddonName, ns = ...

local L = ns.L

local RN = ns.RN
local Maxb = ns.Maxb

local GetItemID = ns.GetItemID


local function AppendReportLine(flatRows, groupedRows, text)
    table.insert(flatRows, text)
    table.insert(groupedRows, { text })
end

local function UnsoldSuffix(preview, itemType, itemLevel)
    if itemType ~= 2 and itemType ~= 4 then
        return ""
    end
    if preview then
        return "(" .. itemLevel .. ")"
    end
    return "|cff9370DB(" .. itemLevel .. ")"
end

local function ReadUnsold(preview, raidKey)
    local groups = {}
    local counter = 0
    local vendorSum = 0
    local bossCount = Maxb[raidKey] - 1
    for bossIdx = 1, bossCount do
        local bossRows = {}
        local slotCount = BG.GetMaxi(raidKey, bossIdx)
        for idx = 1, slotCount do
            local equipmentField = BG.Frame[raidKey]["boss" .. bossIdx]["zhuangbei" .. idx]
            if equipmentField and equipmentField:GetText() ~= "" and GetItemID(equipmentField:GetText())
                and BG.Frame[raidKey]["boss" .. bossIdx]["maijia" .. idx]:GetText() == ""
                and BG.Frame[raidKey]["boss" .. bossIdx]["jine" .. idx]:GetText() == "" then
                local unitName, hyperlink, itemQuality, itemLevel, _, _, _, _, _, _, vendorPrice, itemType = GetItemInfo(equipmentField:GetText())
                local levelSuffix = UnsoldSuffix(preview, itemType, itemLevel)
                tinsert(bossRows, L["流拍："] .. equipmentField:GetText() .. levelSuffix)
                counter = counter + 1
                vendorSum = vendorSum + (vendorPrice or 0)
            end
        end
        if #bossRows ~= 0 then
            tinsert(groups, { bossIdx = bossIdx, rows = bossRows })
        end
    end
    return groups, counter, vendorSum
end

local function BossSectionTitle(preview, raidKey, bossIdx)
    local header
    if bossIdx == Maxb[raidKey] - 1 or bossIdx == Maxb[raidKey] then
        header = L["项目："]
    else
        header = L["Boss："]
    end
    local bossLabel = BG.Boss[raidKey]["boss" .. bossIdx].name2
    local bossColor = BG.Boss[raidKey]["boss" .. bossIdx].color
    if preview then
        return header .. bossLabel
    end
    return "|cff" .. bossColor .. header .. bossLabel .. RN
end

local function AppendBossGroup(flatRows, groupedRows, preview, raidKey, group)
    local title = BossSectionTitle(preview, raidKey, group.bossIdx)
    table.insert(groupedRows, { title })

    local rows = {}
    for idx, entry in ipairs(group.rows) do
        rows[idx] = entry
    end
    table.insert(groupedRows, rows)

    table.insert(flatRows, title)
    for _, entry in ipairs(group.rows) do
        table.insert(flatRows, entry)
    end
end

local function CreateListTable(preview, flatRows)
    local raidKey = BG.FB1
    local flatRows = flatRows or {}
    local groupedRows = {}

    AppendReportLine(flatRows, groupedRows, L["———通报流拍装备———"])
    local groups, counter, vendorSum = ReadUnsold(preview, raidKey)

    if #groups == 0 then
        AppendReportLine(flatRows, groupedRows, L["没有流拍装备"])
        return flatRows, groupedRows, counter
    end

    for _, group in ipairs(groups) do
        AppendBossGroup(flatRows, groupedRows, preview, raidKey, group)
    end

    local summary
    if preview then
        summary = format(L["%s 流拍装备一共%s件 %s"], BG.SetRaidTargetingIcons(preview, "chacha"), counter, BG.SetRaidTargetingIcons(preview, "chacha"))
    else
        summary = "|cffffffff" .. format(L["%s 流拍装备一共%s件 %s"], BG.SetRaidTargetingIcons(preview, "chacha"), counter, BG.SetRaidTargetingIcons(preview, "chacha"))
    end
    table.insert(flatRows, summary)
    table.insert(groupedRows, { summary })

    if not preview then
        local vendorLine = "|cffffffff" .. format(L['流拍装备卖店总价：%s金'], BG.FormatNumber(floor(vendorSum / 10000), 5))
        table.insert(flatRows, vendorLine)
        table.insert(groupedRows, { vendorLine })
    end
    return flatRows, groupedRows, counter
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


function BG.LiuPaiUI(previousButton)
    local tmpValue = BG.CreateButton(BG.ButtonZhangDan)
    tmpValue:SetSize(BG.ButtonZhangDan:GetWidth(), BG.ButtonZhangDan:GetHeight())
    tmpValue:SetPoint("LEFT", previousButton, "RIGHT", BG.ButtonZhangDan.jiange, 0)
    tmpValue:SetText(L["流拍"])
    BG.ButtonLiuPai = tmpValue
    tinsert(BG.TongBaoButtons, tmpValue)

    tmpValue:SetScript("OnEnter", function(self)
        if BG.Backing then return end
        local markTexture = CreateListTable(nil)

        ShowReportTooltip(self, markTexture)
    end)
    tmpValue:SetScript("OnLeave", HideReportTooltip)

    tmpValue:SetScript("OnClick", function(self)
        SendReport(self, CreateListTable)
    end)

    return tmpValue
end
