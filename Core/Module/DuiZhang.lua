if BG.IsBlackListPlayer then return end
local _, ns = ...

local LibBG = ns.LibBG
local L = ns.L

local C = ns.Protocol
local RR = ns.RR
local NN = ns.NN
local RN = ns.RN
local Size = ns.Size
local RGB = ns.RGB
local GetClassRGB = ns.GetClassRGB
local SetClassCFF = ns.SetClassCFF
local Maxb = ns.Maxb
local HopeMaxn = ns.HopeMaxn
local HopeMaxb = ns.HopeMaxb
local HopeMaxi = ns.HopeMaxi
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID


local linshi_duizhang
local h_item = "|c.-|Hitem.-|h|r"
local bigfootyes
local bigfoot

local locales = {
    --金团账本
    ["RaidLedger:.... 收入 ...."] = { "RaidLedger:.... 收入 ....", "RaidLedger:.... Credit ...." },
    ["(%d+)金"] = { "(%d+)金", "(%d+)gold" },
    ["平均每人收入:"] = { "平均每人收入:", "Per Member credit:" },
    --金团表格
    ["通报金团账单"] = { "—通报账单—", "—通报金团账单—", "—通報賬單—", "—通報金團帳單—", "—Announce Raid Ledger—", "- Bulletin Bills -" },
    ["感谢使用金团表格"] = { "感谢使用BiaoGe插件", "感谢使用金团表格", "感謝使用BiaoGe插件", "感謝使用金團表格", "-Thanks for using BiaoGe plugin-", "-Thanks for using Gold Raid Ledger-" },
    ["打包交易"] = { "打包交易", "打包交易", "PackingDeal" },
    ["表格：(.+)"] = { "表格：(.+)", "Table: (.+)" },
    --大脚金团助手
    ["事件：.-|c.-|Hitem.-|h|r"] = { "事件：.-|c.-|Hitem.-|h|r", },
    ["^收入为："] = { "^收入为：", "^收入為：", },
    ["^收入为：%d+。"] = { "^收入为：%d+。", "^收入為：%d+。", },
    ["-感谢使用大脚金团辅助工具-"] = { "-感谢使用大脚金团辅助工具-", "-感謝使用大脚金團輔助工具-", },
}
local BOSS_KEY = "boss"

local function Cell(container, raidKey, bossIdx, field, slot)
    return container[raidKey][BOSS_KEY .. bossIdx][field .. slot]
end

local function ForEachSlot(FB, maxBoss, handler)
    for b = 1, maxBoss do
        local limit = BG.GetMaxi(FB, b)
        for i = 1, limit do
            if handler(b, i) then
                return true
            end
        end
    end
end

local function ReadAmount(field)
    local value = tonumber(field:GetText())
    if not value or value == 0 then
        return ""
    end
    return value
end

local function CompareAmountState(mine, theirs)
    local mineValue = tonumber(mine)
    local theirsValue = tonumber(theirs)
    if not (mineValue or theirsValue) then
        return 0
    end
    if mineValue == theirsValue then
        return 1
    end
    return 2
end

local function MemberColor(class)
    if class then
        return select(4, GetClassColor(class))
    end
    return "ffFFFFFF"
end

local function RaidSuffix(raidKey)
    for _, info in ipairs(BG.FBtable2) do
        if raidKey == info.FB then
            return L["，"] .. BG.STC_b1(info.shortName or info.localName)
        end
    end
    return ""
end

local function CopyAmounts(FB, b, i, theirAmount, ourAmount, jine)
    local amountText = theirAmount:GetText()
    ourAmount:SetText(amountText)
    jine:SetText(amountText)
    if amountText == "" then
        BiaoGe[FB][BOSS_KEY .. b]["jine" .. i] = nil
    else
        BiaoGe[FB][BOSS_KEY .. b]["jine" .. i] = amountText
    end
end

local function CopyBuyer(FB, b, i, maijia)
    local billBuyer = Cell(BG.DuiZhangFrame, FB, b, "maijia", i)
    local billColor = Cell(BG.DuiZhangFrame, FB, b, "color", i)
    maijia:SetText(billBuyer or "")
    BiaoGe[FB][BOSS_KEY .. b]["maijia" .. i] = billBuyer
    if billColor then
        maijia:SetTextColor(unpack(billColor))
    else
        maijia:SetTextColor(1, 1, 1)
    end
    for k in pairs(BG.playerClass) do
        BiaoGe[FB][BOSS_KEY .. b][k .. i] = Cell(BG.DuiZhangFrame, FB, b, k, i)
    end
end

local function HasClaimedSlot(claimedSlots, tradeTbl)
    for _, claimed in ipairs(claimedSlots) do
        for _, entry in ipairs(tradeTbl) do
            if claimed.b == entry.b and claimed.i == entry.i then
                return true
            end
        end
    end
    return false
end

local function MergeTradeTbl(FB, tradeTbl, claimedSlots)
    if not tradeTbl or HasClaimedSlot(claimedSlots, tradeTbl) then
        return
    end
    local copy = BG.Copy(tradeTbl)
    for i, entry in ipairs(copy) do
        local equipmentField = Cell(BG.Frame, FB, entry.b, "zhuangbei", entry.i)
        entry.FB = FB
        entry.itemID = GetItemID(equipmentField:GetText())
        entry.link = equipmentField:GetText()
        tinsert(claimedSlots, { b = entry.b, i = entry.i })
    end
    tinsert(BiaoGe[FB].tradeTbl, copy)
end

local function FillBillRow(FB, billRow)
    local item = billRow.zhuangbei
    local matched
    ForEachSlot(FB, Maxb[FB] - 1, function(b, i)
        local zhuangbei = Cell(BG.DuiZhangFrame, FB, b, "zhuangbei", i)
        local theirAmount = Cell(BG.DuiZhangFrame, FB, b, "otherjine", i)
        if zhuangbei and GetItemID(zhuangbei:GetText()) == GetItemID(item) and theirAmount:GetText() == "" then
            theirAmount:SetText(billRow.jine)
            BG.DuiZhangFrame[FB][BOSS_KEY .. b]["maijia" .. i] = billRow.maijia
            for k in pairs(BG.playerClass) do
                BG.DuiZhangFrame[FB][BOSS_KEY .. b][k .. i] = billRow[k]
            end
            matched = true
            return true
        end
    end)
    if matched then
        return
    end
    local b = Maxb[FB]
    for i = 1, BG.GetMaxi(FB, b) do
        local zhuangbei = Cell(BG.DuiZhangFrame, FB, b, "zhuangbei", i)
        if zhuangbei and not GetItemID(zhuangbei:GetText()) then
            zhuangbei:SetText(item)
            Cell(BG.DuiZhangFrame, FB, b, "otherjine", i):SetText(billRow.jine)
            return
        end
    end
end

local function FindTradeSlot(FB, tradeEntry)
    for b = 1, Maxb[FB] do
        for i = 1, BG.GetMaxi(FB, b) do
            local theirAmount = Cell(BG.DuiZhangFrame, FB, b, "otherjine", i)
            if theirAmount and not (theirAmount.hasTradeTbl or theirAmount.tradeTbl) then
                local maijia = Cell(BG.DuiZhangFrame, FB, b, "maijia", i)
                local itemID = GetItemID(Cell(BG.DuiZhangFrame, FB, b, "zhuangbei", i):GetText())
                local jine = theirAmount:GetText()
                if jine == L["打包交易"] then
                    jine = "t"
                end
                if maijia == tradeEntry.maijia and itemID == tradeEntry.itemID and jine == tradeEntry.jine then
                    theirAmount.hasTradeTbl = true
                    return b, i
                end
            end
        end
    end
end

local function MarkTradeGroups(FB, num)
    local tradeGroups = BiaoGe.duizhang[num].tradeTbl
    if not tradeGroups then return end
    for groupIdx in ipairs(tradeGroups) do
        local rows = {}
        for _, tradeEntry in ipairs(tradeGroups[groupIdx]) do
            local b, i = FindTradeSlot(FB, tradeEntry)
            if b then
                tinsert(rows, { b = b, i = i })
            end
        end
        for _, slot in ipairs(rows) do
            local amount = Cell(BG.DuiZhangFrame, FB, slot.b, "otherjine", slot.i)
            amount.hasTradeTbl = nil
            amount.tradeTbl = rows
        end
    end
end

local function UpdateMarks(FB)
    local mismatchRows = {}
    for b = 1, Maxb[FB] + 1 do
        for i = 1, BG.GetMaxi(FB, b) do
            local zhuangbei = Cell(BG.DuiZhangFrame, FB, b, "zhuangbei", i)
            local ourAmount = Cell(BG.DuiZhangFrame, FB, b, "myjine", i)
            local theirAmount = Cell(BG.DuiZhangFrame, FB, b, "otherjine", i)
            local markTexture = Cell(BG.DuiZhangFrame, FB, b, "yes", i)
            if zhuangbei and zhuangbei ~= BG.DuiZhangFrame[FB][BOSS_KEY .. Maxb[FB] + 1]["zhuangbei2"] then
                local diffBackdrop = Cell(BG.DuiZhangFrameDs, FB .. 3, b, "ds", i)
                local mine = ReadAmount(ourAmount)
                local theirs = ReadAmount(theirAmount)
                local state = CompareAmountState(mine, theirs)
                if state == 1 then
                    markTexture:SetTexture("interface/raidframe/readycheck-ready")
                    diffBackdrop:Hide()
                elseif state == 2 then
                    markTexture:SetTexture("interface/raidframe/readycheck-notready")
                    diffBackdrop:Show()
                    if b <= Maxb[FB] - 1 then
                        local itemID = GetItemID(zhuangbei:GetText())
                        if itemID then
                            tinsert(mismatchRows, {
                                itemID = itemID,
                                b = b,
                                i = i,
                                my = tonumber(mine) or 0,
                                other = tonumber(theirs) or 0,
                            })
                        end
                    end
                else
                    markTexture:SetTexture(nil)
                    diffBackdrop:Hide()
                end
            end
        end
    end
    if next(mismatchRows) then
        local sameItem = {}
        for _, row in ipairs(mismatchRows) do
            local bucket = sameItem[row.itemID]
            if not bucket then
                bucket = { gz = {}, my = 0, other = 0, }
                sameItem[row.itemID] = bucket
            end
            tinsert(bucket.gz, { b = row.b, i = row.i })
            bucket.my = bucket.my + row.my
            bucket.other = bucket.other + row.other
        end
        for _, bucket in pairs(sameItem) do
            if bucket.my == bucket.other then
                for _, slot in ipairs(bucket.gz) do
                    local b = slot.b
                    local i = slot.i
                    Cell(BG.DuiZhangFrame, FB, b, "yes", i):SetTexture("interface/raidframe/readycheck-ready")
                    Cell(BG.DuiZhangFrameDs, FB .. 3, b, "ds", i):Hide()
                    Cell(BG.DuiZhangFrame, FB, b, "zhuangbei", i).sameItem = bucket.gz
                    Cell(BG.DuiZhangFrame, FB, b, "myjine", i).sameItem = bucket.gz
                    Cell(BG.DuiZhangFrame, FB, b, "otherjine", i).sameItem = bucket.gz
                end
            end
        end
    end
end

local function CreateSlotLabel(button, value)
    local text = button:CreateFontString()
    text:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
    text:SetPoint("BOTTOM", button, "TOP", 0, 2)
    text:SetText(value)
    text:SetTextColor(.5, .5, .5)
    return text
end

local function PlaceRaidButton(button, i, parent)
    if i == 1 then
        button:SetPoint("TOPLEFT", 15, -25)
        CreateSlotLabel(button, 1)
    elseif i == 21 then
        button:SetPoint("TOPLEFT", parent.buttons[5], "BOTTOMLEFT", 0, -30)
        CreateSlotLabel(button, (i - 1) / 5 + 1)
    elseif (i - 1) % 5 == 0 then
        button:SetPoint("TOPLEFT", parent.buttons[i - 5], "TOPRIGHT", 5, 0)
        CreateSlotLabel(button, (i - 1) / 5 + 1)
    else
        button:SetPoint("TOPLEFT", parent.buttons[i - 1], "BOTTOMLEFT", 0, -1)
    end
end

local function BuildRaidMemberButton(i, mainFrame)
    local button = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    button:SetBackdrop({
        bgFile = "Interface/ChatFrame/ChatFrameBackground",
        edgeFile = "Interface/ChatFrame/ChatFrameBackground",
        edgeSize = 1,
    })
    button:SetBackdropColor(0, 0, 0, .2)
    button:SetBackdropBorderColor(1, 1, 1, .2)
    button:SetSize(90, 20)
    PlaceRaidButton(button, i, mainFrame)
    tinsert(mainFrame.buttons, button)

    local nameText = button:CreateFontString()
    nameText:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
    nameText:SetPoint("LEFT", 2, 0)
    nameText:SetWidth(button:GetWidth() - 5)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    button.nameText = nameText

    local iconTexture = button:CreateTexture(nil, "OVERLAY")
    iconTexture:SetPoint("CENTER", button, "TOPLEFT", 2, -2)
    iconTexture:SetSize(10, 10)
    button.icon = iconTexture

    local masterTexture = button:CreateTexture(nil, "OVERLAY")
    masterTexture:SetSize(10, 10)
    button.master = masterTexture
end

local function MemberRankIcon(v)
    if v.rank == 2 then
        return "interface/groupframe/ui-group-leadericon"
    elseif v.role == "MAINTANK" then
        return 132064
    elseif v.role == "MAINASSIST" then
        return 132063
    elseif v.rank == 1 then
        return "interface/groupframe/ui-group-assistanticon"
    end
end

local function Default(player, time)
    BG.IsSavingLedger = true
    return {
        player = player,
        class = select(2, UnitClass(player)),
        FB = nil,
        zhangdan = {},
        msgTbl = {},
        yes = nil,
        sumjine = 0,
        time = date("%m-%d %H:%M:%S", GetServerTime()),
        t = time,
    }
end

local function CheckTimeOut(time)
    BG.After(50, function()
        if linshi_duizhang and linshi_duizhang.t then
            if time == linshi_duizhang.t then
                BG.IsSavingLedger = nil
                linshi_duizhang = nil
                BG.SendSystemMessage(L["账单识别错误或超时！"])
            end
        end
    end)
end

local function Send(num, sumMoney, FB)
    local raidSuffix = ""
    local raidShortName = BG.GetFBinfo(FB, "shortName")
    if raidShortName then
        raidSuffix = L["，"] .. BG.STC_b1(raidShortName)
    end
    local link = format(L["|Hgarrmission:BiaoGeDuiZhang:%s|h[点击：对账]（|cff00ff00装备总收入%s|r%s）"],
        num, BG.FormatNumber(sumMoney, 5), raidSuffix)
    SendSystemMessage(link)
    BG.After(0.1, function()
        local link = format(L["|Hgarrmission:BiaoGeDuiZhangCopy:%s:%s|h[ALT+点击：复制账单]（|cff00ff00仅对装备收入有效|r）"],
            num, FB)
        SendSystemMessage(link)
    end)
end

local function SaveRaidMember()
    local rows = {}
    local point = BG.GetRaidPoint()
    for _, v in ipairs(BG.raidRosterInfo) do
        local name = v.name
        rows[name] = BG.Copy(v)
        rows[name].point = point[name]
    end
    if next(rows) then
        return rows
    end
end

-- 已移除 SaveLeaderInfo：它从第三方付费模块 BiaoGeAI / BGAI 读取团长的
-- 装等（GetPlayerItemsLevel）、天赋（talentInfo）与全套装备（itemInfo）。
-- 该函数唯一的调用点原本就是注释掉的，属死代码；同时它也是本插件里
-- 采集他人信息最重的一处，随付费模块挂载点一并移除。

-- 自动记录别人账单
BG.RegisterEvent({ "CHAT_MSG_RAID_WARNING", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID" }, function(self, event, msg, sender, ...)
    if BG.IsSecret(msg) then return end
    local IsRaidLedger = BG.FindTableString(msg, locales["RaidLedger:.... 收入 ...."])
    local IsBiaoGe = BG.FindTableString(msg, locales["通报金团账单"])
    local IsBigFoot = BG.FindTableString(msg, locales["事件：.-|c.-|Hitem.-|h|r"])
    local _time = GetServerTime()
    sender = BG.GSN(sender)
    -- 判断是否一个账单
    if IsRaidLedger then -- 金团账本
        linshi_duizhang = Default(sender, _time)
        linshi_duizhang.yes = 1
        linshi_duizhang.addons = "raidledger"
        tinsert(linshi_duizhang.msgTbl, msg)
        CheckTimeOut(_time)
        return
    elseif IsBiaoGe then -- 金团表格
        linshi_duizhang = Default(sender, _time)
        linshi_duizhang.yes = 2
        linshi_duizhang.addons = "biaoge"
        tinsert(linshi_duizhang.msgTbl, msg)
        CheckTimeOut(_time)
        return
    elseif not bigfootyes and IsBigFoot then -- 大脚
        linshi_duizhang = Default(sender, _time)
        linshi_duizhang.addons = "bigfoot"
        bigfoot = {}
        bigfootyes = true
        tinsert(bigfoot, msg)
        tinsert(linshi_duizhang.msgTbl, msg)
        CheckTimeOut(_time)
        return
    end

    if not linshi_duizhang then return end

    -- 保存聊天记录
    if (linshi_duizhang.yes or bigfootyes) and sender == linshi_duizhang.player then
        tinsert(linshi_duizhang.msgTbl, msg)
    end

    -- 识别表格
    local FB = BG.MatchTableString(msg, locales["表格：(.+)"])
    if linshi_duizhang.yes and sender == linshi_duizhang.player and FB then
        linshi_duizhang.FB = FB
    end

    -- 一旦进入账单阶段，就逐件保存装备价格
    if linshi_duizhang.yes and sender == linshi_duizhang.player and strfind(msg, h_item) then
        local item = strmatch(msg, h_item)
        local jine

        if linshi_duizhang.yes == 1 then -- 金团账本
            jine = BG.MatchTableString(msg, locales["(%d+)金"])
            if jine and tonumber(jine) ~= 0 then
                local aaa = {
                    zhuangbei = item,
                    jine = jine,
                }
                tinsert(linshi_duizhang.zhangdan, aaa)
            end
        elseif linshi_duizhang.yes == 2 then -- 金团表格
            local playerClass = {}
            local maijia = strmatch(msg, " (%S-) %S+$")
            if maijia == "" then
                maijia = nil
            end
            if maijia then
                for k, v in pairs(BG.playerClass) do
                    local value = select(v.select, v.func(maijia))
                    if value == 0 then value = nil end
                    playerClass[k] = value
                end
                if not playerClass.guild then
                    playerClass.realm = nil
                end
            end
            jine = strmatch(msg, " (%d+)$") or strmatch(msg, "：(%d+)$")
            local j
            if jine and tonumber(jine) then
                j = jine
            elseif BG.FindTableString(msg, locales["打包交易"]) then
                j = L["打包交易"]
            else
                j = 0
            end
            local a = {
                zhuangbei = item,
                maijia = maijia,
                jine = j,
            }
            for k, v in pairs(playerClass) do
                a[k] = v
            end
            tinsert(linshi_duizhang.zhangdan, a)
        end
        return
    elseif bigfootyes and sender == linshi_duizhang.player and (BG.FindTableString(msg, locales["事件：.-|c.-|Hitem.-|h|r"]) or BG.FindTableString(msg, locales["^收入为："])) then -- 大脚
        tinsert(bigfoot, msg)
        return
    end

    -- 把整份账单写入存档
    local yes
    if linshi_duizhang.yes and sender == linshi_duizhang.player and (BG.FindTableString(msg, locales["平均每人收入:"]) or BG.FindTableString(msg, locales["感谢使用金团表格"])) then
        yes = true
    elseif bigfootyes and sender == linshi_duizhang.player and BG.FindTableString(msg, locales["-感谢使用大脚金团辅助工具-"]) then -- 大脚
        for i, value in ipairs(bigfoot) do
            if strfind(bigfoot[i], h_item) then
                if bigfoot[i + 1] and BG.FindTableString(bigfoot[i + 1], locales["^收入为：%d+。"]) then
                    local item = strmatch(bigfoot[i], h_item)
                    local jine = tonumber(strmatch(bigfoot[i + 1], "%d+"))

                    if jine ~= "" and tonumber(jine) ~= 0 then
                        local aaa = {
                            zhuangbei = item,
                            jine = jine,
                        }
                        tinsert(linshi_duizhang.zhangdan, aaa)
                    end
                end
            end
        end
        yes = true
        bigfootyes = nil
        bigfoot = nil
    end
    if yes then
        linshi_duizhang.yes = nil
        local sumMoney = 0
        for _, v in pairs(linshi_duizhang.zhangdan) do
            local jine = tonumber(v.jine) or 0
            sumMoney = sumMoney + jine
        end
        linshi_duizhang.sumjine = sumMoney
        linshi_duizhang.member = SaveRaidMember()
        local FB = linshi_duizhang.FB
        tinsert(BiaoGe.duizhang, linshi_duizhang)
        linshi_duizhang = nil
        BG.IsSavingLedger = nil
        BG.DuiZhangList()
        if FB then
            BG.After(0.1, function()
                Send(#BiaoGe.duizhang, sumMoney, FB)
            end)
            if BG.ShowYYPJ then
                BG.ShowYYPJ(sender)
            end
        end
        return
    end
end)

BG.RegisterEvent("CHAT_MSG_ADDON", function(self, event, ...)
    local prefix, msg, distType = ...
    if not linshi_duizhang then return end
    if prefix == C.PREFIX_MAIN and distType == "RAID" and msg:match("^DuiZhang-") then
        linshi_duizhang.tradeTbl = linshi_duizhang.tradeTbl or {}
        local a = {}
        local _, maijia, text = strsplit("-", msg)
        -- 24478 10000, 27854 t, 27503 t,
        for _, t in ipairs({ strsplit(",", text) }) do
            -- 24478 10000
            local itemID, jine = strsplit(" ", t)
            if itemID and tonumber(itemID) then
                tinsert(a, {
                    maijia = maijia,
                    jine = jine,
                    itemID = tonumber(itemID),
                })
            end
        end
        tinsert(linshi_duizhang.tradeTbl, a)
    end
end)

------------------创建UI------------------
function BG.DuiZhangUI()
    BG.DuiZhangDropDown = {}
    local menu = LibBG:Create_UIDropDownMenu(nil, BG.DuiZhangMainFrame)
    menu:SetPoint("BOTTOM", BG.MainFrame, "BOTTOM", -40, 30)
    LibBG:UIDropDownMenu_SetWidth(menu, 450)
    LibBG:UIDropDownMenu_SetText(menu, L["无"])
    LibBG:UIDropDownMenu_SetAnchor(menu, 0, 0, "BOTTOM", menu, "TOP")
    BG.dropDownToggle(menu)
    BG.DuiZhangDropDown.DropDown = menu
    local text = menu:CreateFontString()
    text:SetPoint("RIGHT", menu, "LEFT", 10, 3)
    text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
    text:SetTextColor(1, 1, 0)
    text:SetText(BG.STC_g1(L["对比的账单："]))
    BG.DuiZhangDropDown.BiaoTi = text

    -- 删除账单
    hooksecurefunc(LibBG, "ToggleDropDownMenu", function(_, _, _, menu)
        if menu == BG.DuiZhangDropDown.DropDown then
            for i = 1, _G['L_DropDownList1'].numButtons do
                local mouseButton = _G["L_DropDownList1Button" .. i]
                if not mouseButton.deleteZhangDan then
                    local tmpValue = CreateFrame("Button", nil, mouseButton)
                    tmpValue:SetSize(20, 20)
                    tmpValue:SetPoint("RIGHT", -2, 0)
                    tmpValue:SetNormalTexture("interface/raidframe/readycheck-notready")
                    tmpValue:SetHighlightTexture("interface/raidframe/readycheck-notready")
                    tmpValue:RegisterForClicks("AnyUp")
                    tmpValue.num = i
                    tmpValue:Hide()
                    mouseButton.deleteZhangDan = tmpValue
                    tmpValue:SetScript("OnClick", function(self)
                        BG.PlaySound(1)
                        tremove(BiaoGe.duizhang, self.num)
                        BG.lastduizhangNum = nil
                        BG.DuiZhang0()
                        LibBG:UIDropDownMenu_SetText(BG.DuiZhangDropDown.DropDown, L["无"])
                        BG.DuiZhangMainFrame.ButtonCopy:Disable()
                        LibBG:CloseDropDownMenus()
                        LibBG:ToggleDropDownMenu(nil, nil, BG.DuiZhangDropDown.DropDown)
                    end)
                    tmpValue:SetScript("OnEnter", function(self)
                        LibBG:UIDropDownMenu_StopCounting(self:GetParent():GetParent())
                        mouseButton.Highlight:Show()
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine(L["删除该账单"], 1, 1, 1, true)
                        GameTooltip:Show()
                    end)
                    tmpValue:SetScript("OnLeave", function(self)
                        LibBG:UIDropDownMenu_StartCounting(self:GetParent():GetParent())
                        mouseButton.Highlight:Hide()
                        GameTooltip:Hide()
                    end)
                end
                mouseButton.deleteZhangDan.num = i
                mouseButton.deleteZhangDan:SetShown(not (i == _G['L_DropDownList1'].numButtons))
            end
        else
            for i = 1, L_UIDROPDOWNMENU_MAXBUTTONS do
                local mouseButton = _G["L_DropDownList1Button" .. i]
                if mouseButton.deleteZhangDan then
                    mouseButton.deleteZhangDan:Hide()
                end
            end
        end
    end)

    -- 超过一天后自动清除对应的账单
    local name = "duiZhangTime"
    BG.options[name .. "reset"] = 24 -- 对账单保存24小时
    if not BiaoGe.options[name] then
        BiaoGe.options[name] = BG.options[name .. "reset"]
    end
    local currentTime = GetServerTime()
    for i = #BiaoGe.duizhang, 1, -1 do
        if type(BiaoGe.duizhang[i]) == "table" and BiaoGe.duizhang[i].t then
            local billTime = BiaoGe.duizhang[i].t
            if tonumber(currentTime) - tonumber(billTime) >= (BiaoGe.options[name] * 60 * 60) then
                tremove(BiaoGe.duizhang, i)
            end
        end
    end

    -- 复制对方金额
    do
        local tmpValue = BG.CreateButton(BG.DuiZhangMainFrame)
        tmpValue:SetSize(100, 25)
        tmpValue:SetPoint("LEFT", menu, "RIGHT", 0, 3)
        tmpValue:SetText(L["复制对方账单"])
        tmpValue:Disable()
        BG.DuiZhangMainFrame.ButtonCopy = tmpValue
        tmpValue:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["复制对方账单"], 1, 1, 1, true)
            GameTooltip:AddLine(L["把对方账单的金额覆盖我当前表格的金额。如果对方是BGForge插件的账单，则也会复制其买家。"], 1, 0.82, 0, true)
            GameTooltip:AddLine(" ", 1, 0.82, 0, true)
            GameTooltip:AddLine(L["不会对漏记的装备和金额生效。"], 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        tmpValue:SetScript("OnLeave", GameTooltip_Hide)
        tmpValue:SetScript("OnClick", function(self)
            tmpValue:Copy()
            BG.PlaySound(2)
        end)
        function tmpValue:Copy()
            local addons = BiaoGe.duizhang[BG.lastduizhangNum].addons
            local FB = BG.FB1
            local claimedSlots = {}
            BiaoGe[FB].tradeTbl = {}
            ForEachSlot(FB, Maxb[FB] - 1, function(b, i)
                local theirAmount = Cell(BG.DuiZhangFrame, FB, b, "otherjine", i)
                local zhuangbei = Cell(BG.Frame, FB, b, "zhuangbei", i)
                if zhuangbei then
                    local ourAmount = Cell(BG.DuiZhangFrame, FB, b, "myjine", i)
                    local jine = Cell(BG.Frame, FB, b, "jine", i)
                    CopyAmounts(FB, b, i, theirAmount, ourAmount, jine)
                    if addons == "biaoge" then
                        local maijia = Cell(BG.Frame, FB, b, "maijia", i)
                        CopyBuyer(FB, b, i, maijia)
                        MergeTradeTbl(FB, theirAmount.tradeTbl, claimedSlots)
                    end
                end
            end)
            BG.DuiZhangSet(BG.lastduizhangNum)
        end
    end

    -- 成员名单
    do
        local tmpValue = BG.CreateButton(BG.DuiZhangMainFrame)
        tmpValue:SetSize(80, 25)
        tmpValue:SetPoint("LEFT", BG.DuiZhangMainFrame.ButtonCopy, "RIGHT", 10, 0)
        tmpValue:SetText(L["团员名单"])
        tmpValue:Disable()
        BG.DuiZhangMainFrame.ButtonRaidMember = tmpValue
        tmpValue:SetScript("OnEnter", function(self)
            self:ShowRaidMember()
        end)
        tmpValue:SetScript("OnLeave", function(self)
            BG.DuiZhangMainFrame.raidMemberFrame:Hide()
            GameTooltip:Hide()
        end)
        tmpValue:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            local text = ""
            local num = BG.lastduizhangNum
            if not (BiaoGe.duizhang[num] and BiaoGe.duizhang[num].member) then return end
            for name, v in pairs(BiaoGe.duizhang[num].member) do
                text = text .. "|c" .. MemberColor(v.class) .. name .. "|r\n"
            end
            BG.CreateExportFrame(L["导出名单"], text)
        end)
        function tmpValue:ShowRaidMember()
            if not BG.DuiZhangMainFrame.raidMemberFrame then
                local mainFrame = CreateFrame("Frame", nil, BG.DuiZhangMainFrame, "BackdropTemplate")
                mainFrame:SetBackdrop({
                    bgFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeSize = 1,
                })
                mainFrame:SetBackdropColor(0, 0, 0, .9)
                mainFrame:SetBackdropBorderColor(1, 1, 1, .5)
                mainFrame:SetSize(405, 290)
                mainFrame:SetPoint("BOTTOM", self, "TOP", 0, 5)
                mainFrame:SetFrameLevel(200)
                mainFrame:Hide()
                mainFrame.buttons = {}
                BG.DuiZhangMainFrame.raidMemberFrame = mainFrame

                local t = mainFrame:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                t:SetPoint("BOTTOMLEFT", 15, 5)
                t:SetTextColor(1, 0.82, 0)
                t:SetText(AddTexture("LEFT") .. L["导出名单"])

                for i = 1, 40 do
                    BuildRaidMemberButton(i, mainFrame)
                end
            end
            local mainFrame = BG.DuiZhangMainFrame.raidMemberFrame
            mainFrame:Show()
            for i = 1, 40 do
                local tmpValue = mainFrame.buttons[i]
                tmpValue.nameText:SetText("")
                tmpValue.icon:SetTexture(nil)
                tmpValue.master:SetTexture(nil)
            end
            local num = BG.lastduizhangNum
            if not (BiaoGe.duizhang[num] and BiaoGe.duizhang[num].member) then return end
            for name, v in pairs(BiaoGe.duizhang[num].member) do
                local groupNo, slotIndex = strsplit("-", v.point)
                groupNo = tonumber(groupNo)
                slotIndex = tonumber(slotIndex)
                local rosterIndex = (groupNo - 1) * 5 + slotIndex
                local button = mainFrame.buttons[rosterIndex]
                button.nameText:SetText("|c" .. MemberColor(v.class) .. name)
                local icon = MemberRankIcon(v)
                if icon then
                    button.icon:SetTexture(icon)
                end
                if v.isML then
                    button.master:SetTexture("Interface/GroupFrame/UI-Group-MasterLooter")
                    button.master:ClearAllPoints()
                    if button.icon:GetTexture() then
                        button.master:SetPoint("LEFT", button.icon, "RIGHT", 0, 0)
                    else
                        button.master:SetPoint("CENTER", button, "TOPLEFT", 2, -2)
                    end
                end
            end
        end
    end

    -- 聊天记录
    do
        local frame = CreateFrame("Frame", nil, BG.DuiZhangMainFrame, "BackdropTemplate")
        frame:SetBackdrop({
            bgFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        frame:SetBackdropColor(0, 0, 0, 0.6)
        frame:SetSize(335, 190)
        frame:EnableMouse(true)
        frame.offSetY1 = 90
        frame.offSetY2 = 65
        BG.DuiZhangMainFrame.msgBg = frame

        local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate") -- 滚动
        scroll:SetWidth(frame:GetWidth() - 31)
        scroll:SetHeight(frame:GetHeight() - 9)
        scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5)
        scroll.ScrollBar.scrollStep = BG.scrollStep
        BG.CreateSrollBarBackdrop(scroll.ScrollBar)
        BG.HookScrollBarShowOrHide(scroll)

        local chatEdit = CreateFrame("EditBox", nil, frame) -- 子框架
        chatEdit:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
        chatEdit:SetWidth(scroll:GetWidth())
        chatEdit:SetAutoFocus(false)
        chatEdit:EnableMouse(false)
        chatEdit:SetTextInsets(3, 3, 3, 3)
        chatEdit:SetMultiLine(true)
        chatEdit:SetHyperlinksEnabled(true)
        chatEdit:SetTextColor(RGB("FF7F50"))
        chatEdit.scroll = scroll
        scroll:SetScrollChild(chatEdit)
        BG.DuiZhangMainFrame.msgFrame = chatEdit

        chatEdit:SetScript("OnHyperlinkEnter", function(self, link, text, mouseButton)
            GameTooltip:SetOwner(frame, "ANCHOR_TOPRIGHT", 0, 0)
            GameTooltip:ClearLines()
            local itemID = GetItemInfoInstant(link)
            if itemID then
                GameTooltip:SetHyperlink(BG.SetSpecIDToLink(link))
                BG.Show_AllHighlight(link)
            end
        end)
        chatEdit:SetScript("OnHyperlinkLeave", function(self, link, text, mouseButton)
            GameTooltip:Hide()
            BG.Hide_AllHighlight()
        end)
        chatEdit:SetScript("OnHyperlinkClick", function(self, link, text, mouseButton)
            if (strsub(link, 1, 6) == "player") then
                local _, name, linkLine, linkChat = strsplit(":", link)
                if mouseButton == "LeftButton" then
                    ChatFrame_SendTell(name, ChatFrame1)
                elseif mouseButton == "RightButton" then
                    FriendsFrame_ShowDropdown(name, 1, nil, "RAID", nil)
                end
            elseif (strsub(link, 1, 4) == "item") then
                local name, link, itemQuality, itemLevel, _, _, _, _, _, itemTexture, _, itemType = GetItemInfo(link)
                if IsShiftKeyDown() then
                    BG.InsertLink(text)
                elseif IsAltKeyDown() then
                    if BG.IsML then -- 开始拍卖
                        BG.StartAuction(link, nil, nil, nil, mouseButton == "RightButton")
                    else
                        if mouseButton ~= "RightButton" then
                            BG.AddGuanZhu(link)
                        end
                    end
                else
                    ShowUIPanel(ItemRefTooltip)
                    if (not ItemRefTooltip:IsShown()) then
                        ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
                    end
                    ItemRefTooltip:SetHyperlink(link)
                end
            end
        end)

        local t = frame:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        t:SetPoint("BOTTOM", frame, "TOP", 0, 0)
        t:SetText(L["账单聊天记录"])

        function BG.DuiZhangMainFrame.msgBg:UpdatePoint(FB)
            FB = FB or BG.FB1
            self:ClearAllPoints()
            self:SetPoint("BOTTOMRIGHT", BG.MainFrame, -40, FB == 'TOCtitan' and self.offSetY2 or self.offSetY1)
        end
    end
end

------------------构建下拉菜单中的账单候选项------------------
local function CreateZhangDanTitle(num)
    local zhangdan = BiaoGe.duizhang[num]
    local raidSuffix = RaidSuffix(zhangdan.FB)
    local classColor = MemberColor(zhangdan.class)
    local label = zhangdan.time .. L["，"] .. "|c" .. classColor .. zhangdan.player .. RR
        .. L["，"] .. L["装备总收入"] .. BG.STC_g1(BG.FormatNumber(zhangdan.sumjine, 5)) .. raidSuffix
    return label
end

local function CreateZhangDanMsg(num)
    BG.DuiZhangMainFrame.msgFrame.scroll.ScrollBar:Hide()
    local zhangdan = BiaoGe.duizhang[num]
    if zhangdan.msgTbl then
        local classColor = MemberColor(zhangdan.class)
        local playerLink = "|Hplayer:" .. zhangdan.player .. "|h[" .. "|c" .. classColor .. zhangdan.player .. RR .. "]|h"
        BG.DuiZhangMainFrame.msgFrame:SetText("")
        for _, msg in ipairs(zhangdan.msgTbl) do
            msg = BG.GsubRaidTargetingIcons(msg)
            local text = playerLink .. L["："] .. msg .. NN
            BG.DuiZhangMainFrame.msgFrame:Insert(text)
        end
    end
end

local function AddBillMenuItem(index)
    local label = CreateZhangDanTitle(index)
    local menuItem = LibBG:UIDropDownMenu_CreateInfo()
    menuItem.text = label
    menuItem.func = function()
        BG.FrameHide(0)
        BG.lastduizhangNum = index
        BG.DuiZhangSet(index)
        LibBG:UIDropDownMenu_SetText(BG.DuiZhangDropDown.DropDown, label)
    end
    if BG.lastduizhangNum == index then
        menuItem.checked = true
    end
    LibBG:UIDropDownMenu_AddButton(menuItem)
end

function BG.DuiZhangList()
    for _, v in ipairs(BiaoGe.duizhang) do
        v.sumjine = v.sunjine or v.sumjine or 0
        v.sunjine = nil
    end

    LibBG:UIDropDownMenu_Initialize(BG.DuiZhangDropDown.DropDown, function(self, itemLevel)
        BG.FrameHide(0)
        for i in ipairs(BiaoGe.duizhang) do
            AddBillMenuItem(i)
        end
        local menuItem = LibBG:UIDropDownMenu_CreateInfo()
        menuItem.text = L["无"]
        menuItem.func = function()
            BG.FrameHide(0)
            BG.lastduizhangNum = nil
            BG.DuiZhang0()
            LibBG:UIDropDownMenu_SetText(BG.DuiZhangDropDown.DropDown, L["无"])
            BG.DuiZhangMainFrame.ButtonCopy:Disable()
            BG.DuiZhangMainFrame.ButtonRaidMember:Disable()
        end
        if not BG.lastduizhangNum then
            menuItem.checked = true
        end
        LibBG:UIDropDownMenu_AddButton(menuItem)
    end)
end

------------------负责生成账单的函数------------------
function BG.DuiZhangSet(num)
    local billRows = BiaoGe.duizhang[num].zhangdan
    local FB = BG.FB1
    BG.lastduizhangNum = num
    BG.DuiZhangMainFrame.ButtonCopy:Enable()
    if BiaoGe.duizhang[num].member then
        BG.DuiZhangMainFrame.ButtonRaidMember:Enable()
    else
        BG.DuiZhangMainFrame.ButtonRaidMember:Disable()
    end

    BG.DuiZhang0()
    CreateZhangDanMsg(num)

    for _, billRow in ipairs(billRows) do
        if billRow.zhuangbei then
            FillBillRow(FB, billRow)
        end
    end

    MarkTradeGroups(FB, num)

    -- 设置打钩/叉叉材质
    BG.After(0, function()
        UpdateMarks(FB)
    end)
end

------------------清空对账界面里的格子------------------
function BG.DuiZhang0()
    local FB = BG.FB1
    ForEachSlot(FB, Maxb[FB] + 1, function(b, i)
        local zhuangbei = Cell(BG.DuiZhangFrame, FB, b, "zhuangbei", i)
        if zhuangbei then
            local theirAmount = Cell(BG.DuiZhangFrame, FB, b, "otherjine", i)
            local ourAmount = Cell(BG.DuiZhangFrame, FB, b, "myjine", i)
            theirAmount:SetText("")
            theirAmount.tradeTbl = nil
            zhuangbei.sameItem = nil
            ourAmount.sameItem = nil
            theirAmount.sameItem = nil
            BG.DuiZhangFrame[FB][BOSS_KEY .. b]["maijia" .. i] = nil
            for k in pairs(BG.playerClass) do
                BG.DuiZhangFrame[FB][BOSS_KEY .. b][k .. i] = nil
            end
            Cell(BG.DuiZhangFrame, FB, b, "yes", i):SetTexture(nil)
            Cell(BG.DuiZhangFrameDs, FB .. 3, b, "ds", i):Hide()
        end
    end)

    -- 漏记装备
    local b = Maxb[FB]
    for i = 1, BG.GetMaxi(FB, b) do
        local zhuangbei = Cell(BG.DuiZhangFrame, FB, b, "zhuangbei", i)
        if zhuangbei then
            zhuangbei:SetText("")
            Cell(BG.DuiZhangFrame, FB, b, "myjine", i):SetText("")
        end
    end
    BG.DuiZhangMainFrame.msgFrame:SetText("")
end

local function CopyBill(num, FB)
    FB = FB or BG.FB1
    if FB ~= BG.FB1 then
        BG.ClickFBbutton(FB)
    end
    BG.MainFrame:Show()
    BG.ClickTabButton(BG.DuiZhangMainFrameTabNum)
    BG.DuiZhangSet(num)
    LibBG:UIDropDownMenu_SetText(BG.DuiZhangDropDown.DropDown, CreateZhangDanTitle(num))
    BG.DuiZhangMainFrame.ButtonCopy:Copy()
    BG.ClickTabButton(BG.FBMainFrameTabNum)
end

hooksecurefunc("SetItemRef", function(link)
    local _, BiaoGeDuiZhang, num, FB = strsplit(":", link)
    if BiaoGeDuiZhang == "BiaoGeDuiZhang" and num then
        num = tonumber(num)
        BG.MainFrame:Show()
        BG.ClickTabButton(BG.DuiZhangMainFrameTabNum)
        BG.DuiZhangSet(num)
        LibBG:UIDropDownMenu_SetText(BG.DuiZhangDropDown.DropDown, CreateZhangDanTitle(num))
        BG.PlaySound(1)
    elseif BiaoGeDuiZhang == "BiaoGeDuiZhangCopy" and num and IsAltKeyDown() then
        num = tonumber(num)
        CopyBill(num, FB)
        BG.PlaySound(2)
    end
end)
