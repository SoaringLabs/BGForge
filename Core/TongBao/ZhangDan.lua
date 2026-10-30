local AddonName, ns = ...

local L = ns.L

local C = ns.Protocol
local SendGateway = ns.SendGateway
local NN = ns.NN
local RN = ns.RN
local RGB_16 = ns.RGB_16

local Maxb = ns.Maxb

BG.tongBaoSendCD = 0.3
BG.TongBaoButtons = {}
local step = 2
local updateFrame = CreateFrame("Frame")
updateFrame.errorCount = 0
updateFrame:SetScript("OnEvent", function(self, event, msg)
    if event == "CHAT_MSG_SYSTEM" and not BG.IsSecret(msg) and msg == ERR_CHAT_THROTTLED then
        self.errorCount = self.errorCount + 1
        if self.errorCount >= 5 then
            self:SetScript("OnUpdate", nil)
            self:UnregisterEvent("CHAT_MSG_SYSTEM")
            BG.SendSystemMessage(L["|cffff0000由于服务器聊天限流，通报已被停止。"])
            if self.callback then
                self.callback()
                self.callback = nil
            end
        end
    end
end)

local function ChunkReportRows(rows)
    local chunks = {}
    for _, row in ipairs(rows) do
        for i = 1, #row, step do
            local chunk = {}
            for groupIdx = i, i + step - 1 do
                if not row[groupIdx] then break end
                tinsert(chunk, row[groupIdx])
            end
            tinsert(chunks, chunk)
        end
    end
    return chunks
end

function BG.SendMsgToRaid(rows, delay, callback)
    if BG.InBoss() then return end
    if updateFrame.callback then
        updateFrame.callback()
        updateFrame.callback = nil
    end
    delay = delay or 0
    local channelName = BiaoGe.NotifyChannel
    local tmpValue = ChunkReportRows(rows)
    BG.After(delay, function()
        local cursor = 1
        updateFrame.t = BG.tongBaoSendCD
        updateFrame.callback = callback
        updateFrame:SetScript("OnUpdate", function(self, t)
            if not tmpValue[cursor] then
                self:SetScript("OnUpdate", nil)
                if self.callback then
                    self.callback()
                    self.callback = nil
                end
                return
            end
            self.t = self.t + t
            if self.t >= BG.tongBaoSendCD then
                self.t = 0
                for _, msg in ipairs(tmpValue[cursor]) do
                    SendGateway.Chat(msg, channelName)
                end
                cursor = cursor + 1
            end
        end)
        updateFrame.errorCount = 0
        updateFrame:RegisterEvent("CHAT_MSG_SYSTEM")
    end)
end

local CHANNEL_RULES = {
    { channel = "RAID", ready = function() return IsInRaid(1) end, message = L["不在团队，无法通报。"] },
    { channel = "GUILD", ready = function() return IsInGuild() end, message = L["没有公会，无法通报。"] },
}

local function ReportChannelError(text)
    BG.SendSystemMessage(text)
    BG.PlaySound(1)
end

function BG.IsErrorSendChannel()
    local channelName = BiaoGe.NotifyChannel
    for _, rule in ipairs(CHANNEL_RULES) do
        if channelName == rule.channel and not rule.ready() then
            ReportChannelError(rule.message)
            return true
        end
    end
    if (channelName == "SAY" or channelName == "YELL") and not IsInInstance() then
        ReportChannelError(L["该频道需在副本内才能通报。"])
        return true
    end
end

local function AddReportLine(flatRows, groupedRows, text)
    table.insert(flatRows, text)
    table.insert(groupedRows, { text })
end

local function CopyTextRows(rows)
    local copy = {}
    for i, entry in ipairs(rows) do
        copy[i] = entry
    end
    return copy
end

local function SectionLine(preview, text, icon, colorPrefix)
    local title = format(text, BG.SetRaidTargetingIcons(preview, icon))
    if preview then
        return title
    end
    return colorPrefix .. title .. RN
end

local function BossHeader(raidKey, bossIdx)
    if bossIdx == Maxb[raidKey] - 1 or bossIdx == Maxb[raidKey] then
        return L["项目："]
    end
    return L["Boss："]
end

local function BossTitle(preview, raidKey, bossIdx, suffix)
    local header = BossHeader(raidKey, bossIdx)
    local bossLabel = BG.Boss[raidKey]["boss" .. bossIdx].name2
    local bossColor = BG.Boss[raidKey]["boss" .. bossIdx].color
    if preview then
        return header .. bossLabel .. suffix
    end
    return "|cff" .. bossColor .. header .. bossLabel .. suffix .. "|r"
end

local function AppendBossSection(flatRows, groupedRows, title, bossRows)
    table.insert(groupedRows, { title })
    table.insert(groupedRows, CopyTextRows(bossRows))
    table.insert(flatRows, title)
    for _, entry in ipairs(bossRows) do
        table.insert(flatRows, entry)
    end
end

-- 总览和工资
local function ZongLan(preview, flatRows, groupedRows)
    local FB = BG.FB1
    local flatRows = flatRows or {}
    local groupedRows = groupedRows or {}
    AddReportLine(flatRows, groupedRows, SectionLine(preview, L["< 总 %s 览 >"], "ziling", "|cffffffff"))

    local b = Maxb[FB] + 2
    local runningTotal
    for i = 1, 3, 1 do
        local equipment = BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]
        if equipment then
            local itemLink = equipment:GetText()
            local moneyText = BG.Frame[FB]["boss" .. b]["jine" .. i]:GetText()
            local moneyValue = tonumber(moneyText) or 0
            if moneyValue > 0 then
                moneyText = BG.FormatNumber(moneyText, 5)
            end
            local shareText = ""
            if i == 1 then
                runningTotal = moneyValue
            elseif i == 2 and runningTotal and runningTotal ~= 0 then
                shareText = L["（占比%s%%）"]:format(format("%.0f", moneyValue / runningTotal * 100))
            end
            local line
            if preview then
                line = itemLink .. L["："] .. moneyText .. shareText
            else
                line = "|cffEE82EE" .. itemLink .. L["："] .. moneyText .. shareText .. RN
            end
            AddReportLine(flatRows, groupedRows, line)
        end
    end

    AddReportLine(flatRows, groupedRows, SectionLine(preview, L["< 工 %s 资 >"], "fangkuai", "|cffffffff"))

    local countLabel = BG.Frame[FB]["boss" .. b]["zhuangbei4"]:GetText()
    local countText = BG.Frame[FB]["boss" .. b]["jine4"]:GetText()
    local countLine
    if preview then
        countLine = countLabel .. L["："] .. countText .. L["人"]
    else
        countLine = "|cff00BFFF" .. countLabel .. L["："] .. countText .. L["人"] .. RN
    end
    AddReportLine(flatRows, groupedRows, countLine)

    local wageLabel = BG.Frame[FB]["boss" .. b]["zhuangbei5"]:GetText()
    local wage = BG.Frame[FB]["boss" .. b]["jine5"]:GetText()
    local wageLine
    if preview then
        wageLine = wageLabel .. L["："] .. wage
    else
        wageLine = "|cff00BFFF" .. wageLabel .. L["："] .. BG.FormatNumber(wage, 5) .. RN
    end
    AddReportLine(flatRows, groupedRows, wageLine)

    wage = tonumber(wage)
    local teamWage = BG.FormatNumber(wage * 5, 5)
    wage = BG.FormatNumber(wage, 5)
    local teamLabel = L["小队工资"] .. L["："]
    local teamLine
    if preview then
        teamLine = teamLabel .. teamWage
    else
        teamLine = "|cff00BFFF" .. teamLabel .. teamWage .. RN
    end
    AddReportLine(flatRows, groupedRows, teamLine)

    return flatRows, groupedRows
end

local function GetFaKuanSumMoney()
    local runningTotal = 0
    BG.PairFBItem(function(itemLink, tmpValue4, moneyText, b, i)
        runningTotal = runningTotal + (tonumber(moneyText:GetText()) or 0)
    end, Maxb[BG.FB1])
    return runningTotal
end

local function ScanSpecialRows(FB, b, makeLine)
    local rows = {}
    local counter = 1
    local limit = BG.GetMaxi(FB, b)
    for i = 1, limit do
        local equipment = BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]
        local amount = BG.Frame[FB]["boss" .. b]["jine" .. i]
        if equipment then
            local amountText = amount:GetText()
            if tonumber(amountText) and tonumber(amountText) ~= 0 then
                tinsert(rows, makeLine(i, counter, equipment, amountText))
                counter = counter + 1
            end
        end
    end
    return rows
end

local function FaKuan(preview, flatRows, groupedRows)
    local FB = BG.FB1
    local flatRows = flatRows or {}
    local groupedRows = groupedRows or {}
    local b = Maxb[FB]
    local bossRows = ScanSpecialRows(FB, b, function(i, counter, equipment, amountText)
        local fineName = equipment:GetText()
        if fineName == "" then
            fineName = L["罚款"]
        end
        local buyerField = BG.Frame[FB]["boss" .. b]["maijia" .. i]
        if preview then
            return fineName .. " " .. buyerField:GetText() .. " " ..
                amountText
        end
        return counter .. ". " .. fineName .. " " ..
            RGB_16(buyerField:GetText(), unpack({ buyerField:GetTextColor() })) .. " " ..
            amountText
    end)
    if #bossRows ~= 0 then
        table.insert(groupedRows, CopyTextRows(bossRows))
        for _, entry in ipairs(bossRows) do
            table.insert(flatRows, entry)
        end
        local totalText = format(L["罚款合计：%s"], GetFaKuanSumMoney())
        AddReportLine(flatRows, groupedRows, totalText)
    end
    if #bossRows == 0 then
        AddReportLine(flatRows, groupedRows, L["没有罚款"])
    end
    return flatRows, groupedRows
end

local function ZhiChu(preview, flatRows, groupedRows)
    local FB = BG.FB1
    local flatRows = flatRows or {}
    local groupedRows = groupedRows or {}
    local b = Maxb[FB] + 1
    local bossRows = ScanSpecialRows(FB, b, function(_, counter, equipment, amountText)
        if preview then
            return equipment:GetText() .. " " .. amountText
        end
        return counter .. ". " .. "|cff00FF00" .. equipment:GetText() .. " " .. amountText .. "|r"
    end)
    if #bossRows ~= 0 then
        table.insert(groupedRows, CopyTextRows(bossRows))
        for _, entry in ipairs(bossRows) do
            table.insert(flatRows, entry)
        end
    else
        AddReportLine(flatRows, groupedRows, L["没有支出"])
    end
    return flatRows, groupedRows
end

local function HasQianKuan()
    local FB = BG.FB1
    for b = 1, Maxb[FB] do
        for i = 1, BG.GetMaxi(FB, b) do
            if BG.Frame[FB]["boss" .. b]["qiankuan" .. i] and BiaoGe[FB]["boss" .. b]["qiankuan" .. i] then
                return true
            end
        end
    end
end

local function CollectIncomeRows(preview, FB, b)
    local rows = {}
    local limit = BG.GetMaxi(FB, b)
    for i = 1, limit do
        local equipment = BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]
        local buyerField = BG.Frame[FB]["boss" .. b]["maijia" .. i]
        local amount = BG.Frame[FB]["boss" .. b]["jine" .. i]
        if equipment then
            local amountText = amount:GetText()
            local buyerName = buyerField:GetText()
            if (tonumber(amountText) and tonumber(amountText) ~= 0)
                or (equipment:GetText() ~= "" and (buyerName ~= "" or amountText ~= "")) then
                if amountText:gsub(" ", "") == "" then
                    amountText = 0
                end
                local red, green, blue = buyerField:GetTextColor()
                if buyerName:gsub(" ", "") == "" or tonumber(buyerName) then
                    buyerName = L["未知买家"]
                    red, green, blue = .5, .5, .5
                end
                local equipmentName = equipment:GetText()
                if equipmentName:gsub(" ", "") == "" then
                    if b == Maxb[FB] then
                        equipmentName = L["罚款"]
                    else
                        equipmentName = L["未知装备"]
                    end
                end
                if preview then
                    tinsert(rows, equipmentName .. " " .. buyerName .. " " .. amountText)
                else
                    tinsert(rows, equipmentName .. " " .. RGB_16(buyerName, red, green, blue) .. " " .. amountText)
                end
            end
        end
    end
    return rows
end

local function BuildIncomeSection(preview, FB, flatRows, groupedRows)
    AddReportLine(flatRows, groupedRows, SectionLine(preview, L["< 收 %s 入 >"], "xingxing", "|cffffffff"))
    local found
    for b = 1, Maxb[FB] do
        local bossRows = CollectIncomeRows(preview, FB, b)
        if #bossRows ~= 0 then
            found = true
            local fineTotalText = ""
            if b == Maxb[FB] then
                fineTotalText = format(L["（合计%s）"], GetFaKuanSumMoney())
            end
            AppendBossSection(flatRows, groupedRows, BossTitle(preview, FB, b, fineTotalText), bossRows)
        end
    end
    if not found then
        AddReportLine(flatRows, groupedRows, L["没有收入"] .. NN)
    end
end

local function BuildExpenseSection(preview, FB, flatRows, groupedRows)
    AddReportLine(flatRows, groupedRows, SectionLine(preview, L["< 支 %s 出 >"], "sanjiao", "|cffffffff"))
    local b = Maxb[FB] + 1
    local bossRows = {}
    for i = 1, BG.GetMaxi(FB, b), 1 do
        local equipment = BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]
        local amount = BG.Frame[FB]["boss" .. b]["jine" .. i]
        if equipment then
            local amountText = amount:GetText()
            if tonumber(amountText) and tonumber(amountText) ~= 0 then
                local equipmentName = equipment:GetText()
                if equipmentName:gsub(" ", "") == "" then
                    equipmentName = L["支出"]
                end
                local line
                if preview then
                    line = equipmentName .. " " .. amountText
                else
                    line = BG.STC_g1(equipmentName) .. " " .. BG.STC_g1(amountText)
                end
                tinsert(bossRows, line)
            end
        end
    end
    if #bossRows ~= 0 then
        table.insert(groupedRows, CopyTextRows(bossRows))
        for _, entry in ipairs(bossRows) do
            table.insert(flatRows, entry)
        end
    else
        AddReportLine(flatRows, groupedRows, L["没有支出"] .. NN)
    end
end

local function CreateListTable(preview, flatRows)
    local FB = BG.FB1
    local flatRows = flatRows or {}
    local groupedRows = {}
    -- 收入
    BuildIncomeSection(preview, FB, flatRows, groupedRows)
    -- 支出
    BuildExpenseSection(preview, FB, flatRows, groupedRows)
    -- 总览和工资
    flatRows, groupedRows = ZongLan(preview, flatRows, groupedRows)
    return flatRows, groupedRows
end

local MODIFIER_REPORTS = {
    { isDown = IsAltKeyDown, title = L["———通报总览———"], build = ZongLan },
    { isDown = IsShiftKeyDown, title = L["———通报罚款———"], build = FaKuan },
    { isDown = IsControlKeyDown, title = L["———通报支出———"], build = ZhiChu },
}

local function OnEnter(self)
    self.OnEnter = true
    if BG.Backing then return end
    local flatRows = {}

    local matched
    for _, rule in ipairs(MODIFIER_REPORTS) do
        if rule.isDown() then
            table.insert(flatRows, rule.title)
            flatRows = rule.build(nil, flatRows)
            matched = true
            break
        end
    end
    if not matched then
        table.insert(flatRows, L["———通报账单———"])
        table.insert(flatRows, format(BG.STC_b1(L["表格：%s"]), BG.FB1))
        flatRows = CreateListTable(nil, flatRows)
    end

    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0);
    GameTooltip:ClearLines()
    for i, entry in ipairs(flatRows) do
        GameTooltip:AddLine(entry)
    end
    GameTooltip:Show()
    GameTooltip:SetClampedToScreen(false)

    BiaoGeTooltip2:SetOwner(GameTooltip, "ANCHOR_NONE", 0, 0);
    BiaoGeTooltip2:SetPoint("BOTTOMLEFT", GameTooltip, "BOTTOMRIGHT", 0, 0)
    BiaoGeTooltip2:ClearLines()
    BiaoGeTooltip2:AddLine(L["其他选项"])
    BiaoGeTooltip2:AddLine(L["长按SHITF：仅通报罚款"], 0.5, 0.5, 0.5)
    BiaoGeTooltip2:AddLine(L["长按CTRL：仅通报支出"], 0.5, 0.5, 0.5)
    BiaoGeTooltip2:AddLine(L["长按ALT：仅通报总览"], 0.5, 0.5, 0.5)
    BiaoGeTooltip2:Show()
end

local function OnClick(self)
    local FB = BG.FB1
    BG.FrameHide(0)
    if BG.IsErrorSendChannel() then return end
    self:SetEnabled(false)
    C_Timer.After(3, function()
        self:SetEnabled(true)
    end)

    local matched
    for _, rule in ipairs(MODIFIER_REPORTS) do
        if rule.isDown() then
            local _, rows = rule.build(true)
            tinsert(rows, 1, { rule.title })
            BG.SendMsgToRaid(rows)
            matched = true
            break
        end
    end
    if not matched then
        if HasQianKuan() then
            BG.PlaySound("qiankuan")
        end
        local channelName = BiaoGe.NotifyChannel
        if channelName == "RAID" then
            BG.After(2, function()
                for groupIdx in ipairs(BiaoGe[FB].tradeTbl) do
                    local line = "DuiZhang-"
                    local found = true
                    for i, entry in ipairs(BiaoGe[FB].tradeTbl[groupIdx]) do
                        if i == 1 then
                            if BiaoGe[entry.FB]["boss" .. entry.b]["maijia" .. entry.i] then
                                -- DuiZhang-苍牧-
                                line = line .. BiaoGe[entry.FB]["boss" .. entry.b]["maijia" .. entry.i] .. "-"
                            else
                                found = nil
                                break
                            end
                        end
                        local amount = BiaoGe[entry.FB]["boss" .. entry.b]["jine" .. entry.i]
                        if not amount then
                            found = nil
                            break
                        end
                        if amount == L["打包交易"] then
                            amount = "t"
                        end
                        -- DuiZhang-苍牧-24478 10000,27854 t,27503 t,
                        line = line .. entry.itemID .. " " .. amount .. ","
                    end
                    if found then
                        SendGateway.Addon(C.PREFIX_MAIN, line, "RAID")
                    end
                end
            end)
        end
        local _, rows = CreateListTable(true)
        tinsert(rows, 1, { format(L["表格：%s"], BG.FB1) })
        tinsert(rows, 1, { L["———通报账单———"] })
        tinsert(rows, { L["—感谢使用金团表格—"] })
        BG.After(.2, function()
            BG.SendMsgToRaid(rows)
        end)
    end
    BG.PlaySound(2)
end

local MODIFIER_KEYS = { "LALT", "RALT", "LSHIFT", "RSHIFT", "LCTRL", "RCTRL" }

local function IsWindowModifier(key)
    for _, name in ipairs(MODIFIER_KEYS) do
        if key == name then
            return true
        end
    end
    return false
end

local function OnLeave(self)
    self.OnEnter = false
    GameTooltip:Hide()
    GameTooltip:SetClampedToScreen(true)
    BiaoGeTooltip2:Hide()
end

function BG.ZhangDanUI(previousButton)
    local tmpValue5 = BG.CreateButton(BG.FBMainFrame)
    tmpValue5:SetSize(60, 25)
    tmpValue5.jiange = 5
    if previousButton then
        tmpValue5:SetPoint("LEFT", previousButton, "RIGHT", tmpValue5.jiange, 0)
    else
        local offsetX = -290
        if BG.hasWCL then
            offsetX = offsetX - 60
        end
        tmpValue5:SetPoint("BOTTOMRIGHT", BG.MainFrame, "BOTTOMRIGHT", offsetX, 38)
    end
    tmpValue5:SetText(L["账单"])
    BG.ButtonZhangDan = tmpValue5
    tinsert(BG.TongBaoButtons, tmpValue5)

    -- 鼠标悬停提示账单
    tmpValue5:SetScript("OnEnter", OnEnter)
    tmpValue5:SetScript("OnLeave", OnLeave)
    -- 点击通报账单
    tmpValue5:SetScript("OnClick", OnClick)

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("MODIFIER_STATE_CHANGED")
    frame:SetScript("OnEvent", function(self, event, key)
        if IsWindowModifier(key) and tmpValue5.OnEnter then
            OnEnter(tmpValue5)
        end
    end)

    local t = tmpValue5:CreateFontString()
    t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
    t:SetPoint("RIGHT", tmpValue5, "LEFT", -5, 0)
    t:SetTextColor(1, 0.82, 0)
    t:SetText(L["通报："])

    return tmpValue5
end

local function FormatExpenses(self, event, msg, ...)
    local line, moneyText = msg:match("^(" .. L["人均工资"] .. L["："] .. ")(%d+)$")
    if moneyText then
        moneyText = BG.FormatNumber(moneyText, 5)
        local replacedMessage = line .. moneyText
        return false, replacedMessage, ...
    end
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", FormatExpenses)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", FormatExpenses)
