if BG.IsBlackListPlayer then return end
if not BG.IsTitan then return end
if not BG.HistoryFeatureEnabled then return end
local _, ns = ...

local L = ns.L
local RGB = ns.RGB
local Maxb = ns.Maxb
local AddTexture = ns.AddTexture
local Store = BG.HistoryStore

BG.History = {}

local function GetList(FB)
    return Store.GetList(FB or BG.FB1)
end

local function BuildCurrentSnapshot(FB)
    local snapshot = {}
    local hasLedgerData = false
    for b = 1, Maxb[FB] + 2 do
        local boss = {}
        snapshot["boss" .. b] = boss
        for i = 1, BG.GetMaxi(FB, b) do
            local row = BG.Frame[FB]["boss" .. b]
            local item = row["zhuangbei" .. i]
            local buyer = row["maijia" .. i]
            local money = row["jine" .. i]
            if item then
                local itemText = item:GetText()
                local buyerText = buyer:GetText()
                local moneyText = money:GetText()
                if itemText ~= "" then boss["zhuangbei" .. i] = itemText end
                if buyerText ~= "" then
                    boss["maijia" .. i] = buyerText
                    boss["color" .. i] = { buyer:GetTextColor() }
                end
                if moneyText ~= "" then boss["jine" .. i] = moneyText end
                if BiaoGe[FB]["boss" .. b]["qiankuan" .. i] then
                    boss["qiankuan" .. i] = BiaoGe[FB]["boss" .. b]["qiankuan" .. i]
                end
                if b <= Maxb[FB] and (itemText ~= "" or buyerText ~= "" or moneyText ~= "" or boss["qiankuan" .. i]) then
                    hasLedgerData = true
                elseif b == Maxb[FB] + 1 and (buyerText ~= "" or moneyText ~= "" or boss["qiankuan" .. i]) then
                    hasLedgerData = true
                end
            end
        end
    end
    return snapshot, hasLedgerData
end

local function BuildDefaultTitle(FB, serverTime)
    return format(L["%s%s %s人 工资:%s"],
        date(L["%m月%d日%H:%M:%S\n"], serverTime),
        BG.GetFBinfo(FB, "shortName"),
        BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine" .. 4]:GetText(),
        BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine" .. 5]:GetText())
end

local function ClearHistoryView(FB)
    if not (BG.HistoryFrame and BG.HistoryFrame[FB]) then return end
    for b = 1, Maxb[FB] + 2 do
        local boss = BG.HistoryFrame[FB]["boss" .. b]
        for i = 1, BG.GetMaxi(FB, b) do
            if boss and boss["zhuangbei" .. i] then
                boss["zhuangbei" .. i]:SetText("")
                boss["maijia" .. i]:SetText("")
                boss["maijia" .. i]:SetTextColor(1, 1, 1)
                boss["jine" .. i]:SetText("")
                boss["guanzhu" .. i]:Hide()
                boss["qiankuan" .. i].qiankuan = nil
                boss["qiankuan" .. i]:Hide()
            end
        end
    end
end

local function ShowSnapshot(FB, snapshot)
    ClearHistoryView(FB)
    if not snapshot then return end
    for b = 1, Maxb[FB] + 2 do
        local source = snapshot["boss" .. b] or {}
        local boss = BG.HistoryFrame[FB]["boss" .. b]
        for i = 1, BG.GetMaxi(FB, b) do
            if boss and boss["zhuangbei" .. i] then
                boss["zhuangbei" .. i]:SetText(source["zhuangbei" .. i] or "")
                boss["zhuangbei" .. i]:SetCursorPosition(0)
                boss["maijia" .. i]:SetText(source["maijia" .. i] or "")
                boss["maijia" .. i]:SetCursorPosition(0)
                boss["maijia" .. i]:SetTextColor(unpack(source["color" .. i] or { 1, 1, 1 }))
                boss["jine" .. i]:SetText(source["jine" .. i] or "")
                if source["qiankuan" .. i] then
                    boss["qiankuan" .. i].qiankuan = source["qiankuan" .. i]
                    boss["qiankuan" .. i]:Show()
                else
                    boss["qiankuan" .. i].qiankuan = nil
                    boss["qiankuan" .. i]:Hide()
                end
            end
        end
    end
end

local function ApplySnapshot(FB, snapshot)
    if not snapshot then return false end
    for b = 1, Maxb[FB] + 2 do
        local source = snapshot["boss" .. b] or {}
        local dbBoss = BiaoGe[FB]["boss" .. b]
        local frameBoss = BG.Frame[FB]["boss" .. b]
        for i = 1, BG.GetMaxi(FB, b) do
            local item = source["zhuangbei" .. i]
            local buyer = source["maijia" .. i]
            local money = source["jine" .. i]
            local debt = source["qiankuan" .. i]
            local color = source["color" .. i]

            dbBoss["zhuangbei" .. i] = item
            dbBoss["maijia" .. i] = buyer
            dbBoss["jine" .. i] = money
            dbBoss["qiankuan" .. i] = debt
            dbBoss["guanzhu" .. i] = nil
            dbBoss["loot" .. i] = nil
            dbBoss["itemLevel" .. i] = nil
            dbBoss["bindOnEquip" .. i] = nil
            for field in pairs(BG.playerClass) do
                dbBoss[field .. i] = nil
            end
            for _, field in ipairs(BG.removedIdentityFields or {}) do
                dbBoss[field .. i] = nil
            end
            if color then
                dbBoss["color" .. i] = BG.Copy(color)
            end

            if frameBoss["zhuangbei" .. i] then
                frameBoss["zhuangbei" .. i]:SetText(item or "")
                frameBoss["maijia" .. i]:SetText(buyer or "")
                frameBoss["maijia" .. i]:SetCursorPosition(0)
                frameBoss["maijia" .. i]:SetTextColor(unpack(color or { 1, 1, 1 }))
                frameBoss["jine" .. i]:SetText(money or "")
                frameBoss["guanzhu" .. i]:Hide()
                if debt then
                    frameBoss["qiankuan" .. i].qiankuan = debt
                    frameBoss["qiankuan" .. i]:Show()
                else
                    frameBoss["qiankuan" .. i].qiankuan = nil
                    frameBoss["qiankuan" .. i]:Hide()
                end
            end
        end
    end

    -- Applying a local history snapshot must not resurrect secondary-use data.
    BiaoGe[FB].tradeTbl = {}
    BiaoGe[FB].raidRoster = nil
    BiaoGe[FB].auctionLog = nil
    BiaoGe[FB].leaderInfo = nil
    BG.UpdateAuctionLogFrame()
    return true
end

local function HasCurrentReplacementData(FB)
    local current = type(BiaoGe[FB]) == "table" and BiaoGe[FB] or {}
    return BG.BiaoGeHavedItem(FB)
        or (type(current.auctionLog) == "table" and next(current.auctionLog) ~= nil)
        or (type(current.tradeTbl) == "table" and next(current.tradeTbl) ~= nil)
        or (type(current.raidRoster) == "table" and next(current.raidRoster) ~= nil)
        or (type(current.leaderInfo) == "table" and next(current.leaderInfo) ~= nil)
end

function BG.UpdateHistoryButton()
    if not BG.History.HistoryButton then return end
    local bt = BG.History.HistoryButton
    bt:SetFormattedText(L["历史表格（%d个）"], #GetList(BG.FB1))
    bt:SetSize(bt:GetFontString():GetWidth(), 20)
end

function BG.SaveBiaoGe(FB, options)
    FB = FB or BG.FB1
    options = type(options) == "table" and options or {}
    local serverTime = GetServerTime()
    local snapshot, hasLedgerData = BuildCurrentSnapshot(FB)
    if not hasLedgerData then
        if not options.silent then
            BG.SendSystemMessage(BG.STC_r1(L["当前表格为空，未保存历史记录。"]))
        end
        return false, "empty"
    end
    local id, reason = Store.Save(FB, snapshot, BuildDefaultTitle(FB, serverTime), serverTime, {
        source = options.source or "manual",
        dedupe = options.dedupe,
    })
    if not id then
        if not options.silent then
            if reason == "empty" then
                BG.SendSystemMessage(BG.STC_r1(L["当前表格为空，未保存历史记录。"]))
            else
                BG.SendSystemMessage(BG.STC_r1(L["历史表格保存失败。"]))
            end
        end
        return false, reason
    end
    BG.UpdateHistoryButton()
    BG.CreatHistoryListButton(FB)
    if not options.silent then
        if reason == "duplicate" then
            BG.SendSystemMessage(BG.STC_g1(L["当前表格与最近一条历史记录相同，未重复保存。"]))
        else
            BG.SendSystemMessage(BG.STC_g1(L["已保存至历史表格，当前表格不会被清空。"]))
        end
    end
    return true, reason, id
end

function BG.SetBiaoGeFormHistory(FB, num)
    FB = FB or BG.FB1
    num = num or BG.History.chooseNum
    local snapshot = num and Store.LoadByIndex(FB, num)
    if not snapshot then return false end
    ApplySnapshot(FB, snapshot)
    BG.EscHistoryFrame()
    return true
end

function BG.DeleteHistory(FB, num)
    FB = FB or BG.FB1
    if not Store.Delete(FB, num) then return false end
    BG.History.chooseNum = nil
    BG.UpdateHistoryButton()
    BG.CreatHistoryListButton(FB)
    ClearHistoryView(FB)
    return true
end

function BG.EscHistoryFrame()
    BG.HistoryMainFrame:Hide()
    BG.FBMainFrame:Show()
    BG.History.List:Hide()
    BG.UpdateAuctionLogFrame()
    BG.PlaySound(1)
end

function BG.HistoryUI()
    local parent = BG.FBMainFrame
    local gap = -7

    local listFrame = CreateFrame("Frame", nil, BG.MainFrame, "BackdropTemplate")
    listFrame:SetBackdrop({
        bgFile = "Interface/ChatFrame/ChatFrameBackground",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    listFrame:SetBackdropColor(0, 0, 0, 0.9)
    listFrame:SetSize(270, 380)
    listFrame:SetPoint("TOPRIGHT", BG.MainFrame, "TOPRIGHT", 0, -20)
    listFrame:SetFrameLevel(130)
    listFrame:EnableMouse(true)
    listFrame:Hide()
    BG.History.List = listFrame

    local scroll = CreateFrame("ScrollFrame", nil, listFrame, BG.scrollTemplate)
    scroll:SetWidth(listFrame:GetWidth() - 27)
    scroll:SetHeight(listFrame:GetHeight() - 9)
    scroll:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 0, -5)
    scroll.ScrollBar.scrollStep = BG.scrollStep
    BG.CreateSrollBarBackdrop(scroll.ScrollBar)
    BG.HookScrollBarShowOrHide(scroll)
    BG.History.scroll = scroll

    local child = CreateFrame("Frame", nil, listFrame)
    child:SetWidth(scroll:GetWidth())
    child:SetHeight(scroll:GetHeight())
    scroll:SetScrollChild(child)
    BG.History.child = child

    local title = BG["HistoryFrame" .. BG.FB1]:CreateFontString()
    title:SetPoint("TOP", BG.MainFrame, "TOP", 0, -4)
    title:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
    title:SetTextColor(RGB("00FF00"))
    title:SetText(L["<历史表格>"])
    BG.History.Title = title

    local hint = listFrame:CreateFontString()
    hint:SetPoint("TOP", listFrame, "BOTTOM", 0, 0)
    hint:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
    hint:SetText(BG.STC_w1(format(L["（ALT+%s改名，ALT+%s删除表格）"], AddTexture("LEFT"), AddTexture("RIGHT"))))

    local clearButton = BG.CreateButton(listFrame)
    clearButton:SetSize(110, 25)
    clearButton:SetPoint("TOP", listFrame, "BOTTOM", 0, -20)
    clearButton:SetText(L["清空历史表格"])
    clearButton:SetScript("OnClick", function()
        StaticPopup_Show("BiaoGe_ClearAllHistory", BG.GetFBinfo(BG.FB1, "shortName"))
    end)

    StaticPopupDialogs["BiaoGe_ClearAllHistory"] = {
        text = L["确定清空<%s>的所有历史表格？"],
        button1 = L["是"],
        button2 = L["否"],
        OnAccept = function()
            local FB = BG.FB1
            Store.Clear(FB)
            BG.History.chooseNum = nil
            BG.UpdateHistoryButton()
            BG.CreatHistoryListButton(FB)
            ClearHistoryView(FB)
            BG.EscHistoryFrame()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        showAlert = true,
    }

    local historyButton = CreateFrame("Button", nil, parent)
    historyButton:SetPoint("TOPRIGHT", BG.MainFrame, "TOPRIGHT", -30, -1)
    historyButton:SetNormalFontObject(BG.FontGreen15)
    historyButton:SetDisabledFontObject(BG.FontDis15)
    historyButton:SetHighlightFontObject(BG.FontWhite15)
    BG.SetTextHighlightTexture(historyButton)
    BG.History.HistoryButton = historyButton
    BG.UpdateHistoryButton()
    historyButton:SetScript("OnClick", function()
        BG.CreatHistoryListButton(BG.FB1)
        listFrame:SetShown(not listFrame:IsShown())
        BG.PlaySound(1)
    end)

    local saveButton = CreateFrame("Button", nil, parent)
    saveButton:SetPoint("TOPRIGHT", historyButton, "TOPLEFT", gap, 0)
    saveButton:SetNormalFontObject(BG.FontGreen15)
    saveButton:SetDisabledFontObject(BG.FontDis15)
    saveButton:SetHighlightFontObject(BG.FontWhite15)
    saveButton:SetText(L["保存"])
    saveButton:SetSize(saveButton:GetFontString():GetWidth(), 20)
    BG.SetTextHighlightTexture(saveButton)
    BG.History.SaveButton = saveButton
    saveButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L["保存表格"], 1, 1, 1, true)
        GameTooltip:AddLine(L["保存当前表格的本地副本，不会清空当前表格，也不会分享给其他玩家。"], 1, 0.82, 0, true)
        GameTooltip:Show()
    end)
    saveButton:SetScript("OnLeave", GameTooltip_Hide)
    saveButton:SetScript("OnClick", function(self)
        self:Disable()
        C_Timer.After(0.5, function() self:Enable() end)
        if BG.SaveBiaoGe() then BG.PlaySound(2) end
    end)

    local applyButton = CreateFrame("Button", nil, BG.HistoryMainFrame)
    applyButton:SetPoint("TOPRIGHT", BG.MainFrame, "TOPRIGHT", -30, -1)
    applyButton:SetNormalFontObject(BG.FontGreen15)
    applyButton:SetDisabledFontObject(BG.FontDis15)
    applyButton:SetHighlightFontObject(BG.FontWhite15)
    applyButton:SetText(L["应用"])
    applyButton:SetSize(applyButton:GetFontString():GetWidth(), 20)
    BG.SetTextHighlightTexture(applyButton)
    BG.History.YongButton = applyButton
    applyButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L["应用表格"], 1, 1, 1, true)
        GameTooltip:AddLine(L["把该历史表格复制粘贴到当前表格，这样你可以编辑内容。"], 1, 0.82, 0, true)
        GameTooltip:Show()
    end)
    applyButton:SetScript("OnLeave", GameTooltip_Hide)
    applyButton:SetScript("OnClick", function()
        if not BG.History.chooseNum then return end
        if HasCurrentReplacementData(BG.FB1) then
            StaticPopup_Show("YINGYONGBIAOGE")
        else
            BG.SetBiaoGeFormHistory()
            BG.PlaySound(2)
        end
    end)

    StaticPopupDialogs["YINGYONGBIAOGE"] = {
        text = L["确定应用历史表格？\n当前表格及相关拍卖、交易和团队快照数据将被替换或清空。"],
        button1 = L["是"],
        button2 = L["否"],
        OnAccept = function()
            if BG.SetBiaoGeFormHistory() then BG.PlaySound(2) end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        showAlert = true,
    }

    local backButton = CreateFrame("Button", nil, BG.HistoryMainFrame)
    backButton:SetPoint("TOPRIGHT", applyButton, "TOPLEFT", gap, 0)
    backButton:SetNormalFontObject(BG.FontFen15)
    backButton:SetDisabledFontObject(BG.FontDis15)
    backButton:SetHighlightFontObject(BG.FontWhite15)
    backButton:SetText(L["返回"])
    backButton:SetSize(backButton:GetFontString():GetWidth(), 20)
    BG.SetTextHighlightTexture(backButton)
    BG.History.EscButton = backButton
    backButton:SetScript("OnClick", BG.EscHistoryFrame)

    local renameFrame = CreateFrame("Frame", nil, listFrame, "BackdropTemplate")
    renameFrame:SetBackdrop({
        bgFile = "Interface/ChatFrame/ChatFrameBackground",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    renameFrame:SetBackdropColor(0, 0, 0, 0.9)
    renameFrame:SetSize(250, 150)
    renameFrame:SetPoint("TOPRIGHT", listFrame, "TOPLEFT", -2, 0)
    renameFrame:SetFrameLevel(130)
    renameFrame:Hide()
    BG.History.GaiMingFrame = renameFrame
    listFrame:SetScript("OnHide", function() renameFrame:Hide() end)

    local renameTitle = renameFrame:CreateFontString()
    renameTitle:SetPoint("TOP", renameFrame, "TOP", 0, -20)
    renameTitle:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
    renameTitle:SetTextColor(RGB("00BFFF"))
    BG.History.GaiMingBiaoTi = renameTitle

    local editBackground = CreateFrame("Frame", nil, renameFrame, "BackdropTemplate")
    editBackground:SetBackdrop({
        bgFile = "Interface/ChatFrame/ChatFrameBackground",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    editBackground:SetBackdropColor(0, 0, 0, 0.2)
    editBackground:SetSize(230, 60)
    editBackground:SetPoint("TOPRIGHT", renameFrame, "TOPRIGHT", -10, -45)

    local renameEdit = CreateFrame("EditBox", nil, editBackground)
    renameEdit:SetSize(editBackground:GetWidth() - 10, editBackground:GetHeight())
    renameEdit:SetPoint("TOPLEFT", 5, -5)
    renameEdit:SetAutoFocus(false)
    renameEdit:EnableMouse(true)
    renameEdit:SetMultiLine(true)
    renameEdit:SetMaxBytes(120)
    renameEdit:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
    renameEdit:SetScript("OnEscapePressed", function() renameFrame:Hide() end)
    BG.History.GaiMingEdit1 = renameEdit

    local confirmRename = BG.CreateButton(renameFrame)
    confirmRename:SetSize(110, 25)
    confirmRename:SetPoint("BOTTOMLEFT", renameFrame, "BOTTOMLEFT", 10, 15)
    confirmRename:SetText(L["确定"])
    confirmRename:SetScript("OnClick", function()
        local FB = BG.FB1
        local text = renameEdit:GetText()
        for i, entry in ipairs(GetList(FB)) do
            if i ~= BG.History.GaiMingNum and entry[2] == text then
                BG.SendSystemMessage(BG.STC_r1(L["不能使用该名字，因为跟其他历史表格重名！"]))
                return
            end
        end
        if Store.Rename(FB, BG.History.GaiMingNum, text) then
            renameFrame:Hide()
            BG.CreatHistoryListButton(FB)
            BG.PlaySound(1)
        end
    end)

    local cancelRename = BG.CreateButton(renameFrame)
    cancelRename:SetSize(110, 25)
    cancelRename:SetPoint("BOTTOMRIGHT", renameFrame, "BOTTOMRIGHT", -10, 15)
    cancelRename:SetText(L["取消"])
    cancelRename:SetScript("OnClick", function()
        renameFrame:Hide()
        BG.PlaySound(1)
    end)
end

function BG.CreatHistoryListButton(FB)
    FB = FB or BG.FB1
    if not BG.History.child then return end
    local index = 1
    while BG.History["ListButton" .. index] do
        BG.History["ListButton" .. index]:Hide()
        BG.History["ListButton" .. index] = nil
        index = index + 1
    end

    local list = GetList(FB)
    BG.History.child:SetHeight(max(BG.History.scroll:GetHeight(), #list * 45 + 20))
    for i, entry in ipairs(list) do
        local bt = CreateFrame("Button", nil, BG.History.child, "BackdropTemplate")
        bt:SetBackdrop({ bgFile = "Interface/ChatFrame/ChatFrameBackground" })
        bt:SetBackdropColor(1, 1, 1, 0.1)
        if i == 1 then
            bt:SetPoint("TOPLEFT", BG.History.child, "TOPLEFT", 10, -10)
        else
            bt:SetPoint("TOPLEFT", BG.History["ListButton" .. i - 1], "BOTTOMLEFT", 0, -5)
        end
        bt:SetSize(230, 40)
        bt:SetNormalFontObject(BG.FontBlue13)
        bt:SetDisabledFontObject(BG.FontWhite13)
        bt:SetHighlightFontObject(BG.FontWhite13)
        local sourceText = ""
        if entry[4] == "manual" then
            sourceText = L["[手动]"] .. " "
        elseif entry[4] == "auto-clear" then
            sourceText = L["[自动]"] .. " "
        end
        bt:SetText(i .. ". " .. sourceText .. tostring(entry[2] or ""))
        bt:GetFontString():SetWidth(bt:GetWidth() - 10)
        bt:GetFontString():SetPoint("LEFT", 3, 0)
        bt:GetFontString():SetJustifyH("LEFT")
        BG.History["ListButton" .. i] = bt

        local selected = bt:CreateTexture(nil, "ARTWORK")
        selected:SetAllPoints()
        selected:SetColorTexture(RGB(BG.b1))
        bt:SetDisabledTexture(selected)
        bt:HookScript("OnEnter", function(self) self:SetBackdropColor(RGB(BG.b1, 0.6)) end)
        bt:HookScript("OnLeave", function(self) self:SetBackdropColor(1, 1, 1, 0.1) end)

        bt:SetScript("OnMouseUp", function(self, button)
            if IsAltKeyDown() then
                if button == "RightButton" then
                    BG.DeleteHistory(FB, i)
                    BG.History.GaiMingFrame:Hide()
                else
                    BG.History.GaiMingNum = i
                    BG.History.GaiMingFrame:Show()
                    BG.History.GaiMingBiaoTi:SetText(format(L["你正在改名第 %s 个表格"], i))
                    BG.History.GaiMingEdit1:SetText(tostring(entry[2] or ""))
                    BG.History.GaiMingEdit1:SetFocus()
                    BG.History.GaiMingEdit1:HighlightText()
                end
                BG.PlaySound(1)
                return
            end

            BG.CreateFBUI(FB, "History")
            local snapshot = Store.LoadByIndex(FB, i)
            if not snapshot then return end
            for n = 1, #list do
                if BG.History["ListButton" .. n] then BG.History["ListButton" .. n]:Enable() end
            end
            self:Disable()
            BG.History.chooseNum = i
            ShowSnapshot(FB, snapshot)
            BG.HistoryMainFrame:Show()
            BG.History.Title:SetParent(BG["HistoryFrame" .. FB])
            BG.History.Title:SetText(L["<历史表格>"] .. " " .. i)
            BG.History.List:Hide()
            BG.PlaySound(1)
        end)
    end
end
