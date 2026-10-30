local AddonName, ns = ...

local L = ns.L

local RGB_16 = ns.RGB_16

local Maxb = ns.Maxb


------------------用于通报消费排名的函数-----------------
local function AppendReportLine(flatRows, groupedRows, text)
    table.insert(flatRows, text)
    table.insert(groupedRows, { text })
end

local function ReadSpending(raidKey)
    local entries = {}
    local bossCount = Maxb[raidKey]
    for bossIdx = 1, bossCount do
        local slotCount = BG.GetMaxi(raidKey, bossIdx)
        for idx = 1, slotCount do
            local buyerField = BG.Frame[raidKey]["boss" .. bossIdx]["maijia" .. idx]
            if buyerField then
                local buyerName = buyerField:GetText()
                local amount = tonumber(BG.Frame[raidKey]["boss" .. bossIdx]["jine" .. idx]:GetText())
                if buyerName ~= "" and amount and amount ~= 0 then
                    local entry = entries[buyerName]
                    if entry then
                        entry.jine = entry.jine + amount
                    else
                        entries[buyerName] = {
                            maijia = buyerName,
                            color = { buyerField:GetTextColor() },
                            jine = amount,
                        }
                    end
                end
            end
        end
    end
    return entries
end

local function RankSpending(entries)
    local ranking = {}
    for _, entry in pairs(entries) do
        tinsert(ranking, entry)
    end
    sort(ranking, function(left, right)
        return left.jine > right.jine
    end)
    return ranking
end

local function SpendingLine(preview, position, entry)
    if preview then
        return position .. ". " .. entry.maijia .. " " .. BG.FormatNumber(entry.jine, 5)
    end
    return position .. ". " .. RGB_16(entry.maijia, unpack(entry.color)) .. " " .. BG.FormatNumber(entry.jine, 5)
end

local function CreateListTable(preview, flatRows)
    local ranking = RankSpending(ReadSpending(BG.FB1))

    -- 开始
    local flatRows = flatRows or {}
    local groupedRows = {}
    AppendReportLine(flatRows, groupedRows, L["———通报消费排名———"])

    if #ranking == 0 then
        AppendReportLine(flatRows, groupedRows, L["没有消费记录"])
        return flatRows, groupedRows
    end
    for idx, entry in ipairs(ranking) do
        AppendReportLine(flatRows, groupedRows, SpendingLine(preview, idx, entry))
    end
    return flatRows, groupedRows
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


function BG.XiaoFeiUI(previousButton)
    local tmpValue = BG.CreateButton(BG.ButtonZhangDan)
    tmpValue:SetSize(BG.ButtonZhangDan:GetWidth(), BG.ButtonZhangDan:GetHeight())
    tmpValue:SetPoint("LEFT", previousButton, "RIGHT", BG.ButtonZhangDan.jiange, 0)
    tmpValue:SetText(L["消费"])
    BG.ButtonXiaoFei = tmpValue
    tinsert(BG.TongBaoButtons, tmpValue)
    -- 鼠标悬停提示
    tmpValue:SetScript("OnEnter", function(self)
        if BG.Backing then return end
        local markTexture = CreateListTable(nil)
        ShowReportTooltip(self, markTexture)
    end)
    tmpValue:SetScript("OnLeave", HideReportTooltip)
    -- 点击通报消费排名
    tmpValue:SetScript("OnClick", function(self)
        SendReport(self, CreateListTable)
    end)

    return tmpValue
end
