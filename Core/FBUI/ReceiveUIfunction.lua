local _, ns = ...

local L = ns.L

local RGB = ns.RGB
local Maxb = ns.Maxb
local BossNum = ns.BossNum
local GetItemID = ns.GetItemID


local p = {}
BG.ReceiveFrame.p = p

local preWidget
local framedown
local frameright
local red, greed, blue = 1, 1, 1
local touming1, touming2 = 0.1, 0.1

------------------标题------------------
function BG.ReceiveTitleUI(FB, t, b, bb, i, ii)
    local headerFontSize = 15
    local headerParent = BG["ReceiveFrame" .. FB]
    local headerCells = {
        { text = L["  项目"], first = true },
        { text = L["装备"], offset = 70, cursorZero = true },
        { text = L["买家"], offset = BG.zhuangbeiWidth + 5 },
        { text = L["金额"], offset = BG.maijiaWidth + 5, last = true },
    }
    for _, spec in ipairs(headerCells) do
        local headerCell = headerParent:CreateFontString()
        if spec.first then
            if t == 1 then
                headerCell:SetPoint("TOPLEFT", BG.ReceiveMainFrame, "TOPLEFT", 13, -60)
            else
                headerCell:SetPoint("TOPLEFT", frameright, "TOPLEFT", 100, 0)
            end
        else
            headerCell:SetPoint("TOPLEFT", preWidget, "TOPLEFT", spec.offset, 0)
        end
        headerCell:SetFont(BIAOGE_TEXT_FONT, headerFontSize, "OUTLINE")
        headerCell:SetTextColor(RGB(BG.y2))
        headerCell:SetText(spec.text)
        preWidget = headerCell
        if spec.cursorZero then
            p.preWidget0 = headerCell
        end
        if spec.last then
            frameright = headerCell
        end
    end
end

------------------装备------------------
function BG.ReceiveZhuangBeiUI(FB, t, b, bb, i, ii, scrollFrame)
    local cellParent = scrollFrame or BG["ReceiveFrame" .. FB]
    local bigRowGap = BG.IsBigFB(FB) and -15 or -20
    local editBox = CreateFrame("EditBox", nil, cellParent, BG.editTemplate);
    if BossNum(FB, b, t) <= Maxb[FB] then
        editBox:SetSize(BG.zhuangbeiWidth, 20)
    else
        editBox:SetSize(BG.zhuangbeiWidth2, 20)
    end
    editBox:SetFrameLevel(110)
    if BG.zaxiang[FB] and BossNum(FB, b, t) == Maxb[FB] - 1 and i == BG.zaxiang[FB].i then
        editBox:SetPoint("TOPLEFT", frameright, "TOPLEFT", 170, -18)
    else
        if scrollFrame and i == 1 then
            editBox:SetPoint("TOPLEFT", scrollFrame, 5, 0)
        elseif b > 1 and i == 1 then
            editBox:SetPoint("TOPLEFT", framedown, "BOTTOMLEFT", 0, bigRowGap)
        else
            if BG.zaxiang[FB] and BossNum(FB, b, t) == Maxb[FB] and i == 1 then
                editBox:SetPoint("TOPLEFT", framedown, "BOTTOMLEFT", 0, bigRowGap)
            else
                editBox:SetPoint("TOPLEFT", p["preWidget" .. i - 1], "BOTTOMLEFT", 0, BG.IsBigFB(FB) and 0 or -3)
            end
        end
    end
    editBox:SetAutoFocus(false)
    editBox:SetEnabled(false)
    BG.SetBorderAlpha(editBox)
    local itemIcon = editBox:CreateTexture(nil, 'ARTWORK')
    itemIcon:SetPoint('LEFT', -22, 0)
    itemIcon:SetSize(16, 16)
    BG.ReceiveFrame[FB]["boss" .. BossNum(FB, b, t)]["zhuangbei" .. i] = editBox
    preWidget = editBox
    p["preWidget" .. i] = editBox
    framedown = p["preWidget" .. ii]
    -- 内容改变时
    editBox:SetScript("OnTextChanged", function(self)
        local cellText = editBox:GetText()
        local itemID = GetItemID(cellText)
        if itemID then
            local item = Item:CreateFromItemID(itemID)
            item:ContinueOnItemLoad(function()
                local name, link, quality, level, _, _, _, _, _, Texture,
                _, typeID, _, bindType = GetItemInfo(cellText)
                itemIcon:SetTexture(Texture)
                BG.BindOnEquip(self, bindType)
                BG.LevelText(self, level, typeID)
                BG.IsHave(self)
            end)
        else
            itemIcon:SetTexture(nil)
            BG.BindOnEquip(self)
            BG.LevelText(self)
            BG.IsHave(self)
        end
    end)
    -- 把装备链接填进聊天输入框
    editBox:SetScript("OnMouseDown", function(self, enter)
        if IsShiftKeyDown() then
            BG.PlaySound(1)
            BG.InsertLink(self:GetText())
        end
    end)
    -- 鼠标悬停在装备时
    editBox:SetScript("OnEnter", function(self)
        BG.ReceiveFrameDs[FB .. 1]["boss" .. BossNum(FB, b, t)]["ds" .. i]:Show()
        if not tonumber(self:GetText()) then
            local link = editBox:GetText()
            local itemID = GetItemID(link)
            if itemID then
                if BG.ButtonIsInRight(self) then
                    GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0)
                else
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
                end
                GameTooltip:ClearLines()
                GameTooltip:SetHyperlink(BG.SetSpecIDToLink(link))
            end
        end
    end)
    editBox:SetScript("OnLeave", function(self)
        BG.ReceiveFrameDs[FB .. 1]["boss" .. BossNum(FB, b, t)]["ds" .. i]:Hide()
        GameTooltip:Hide()
    end)
end

------------------买家------------------
function BG.ReceiveMaiJiaUI(FB, t, b, bb, i, ii)
    local editBox = CreateFrame("EditBox", nil, BG.ReceiveFrame[FB]["boss" .. BossNum(FB, b, t)]["zhuangbei" .. i], BG.editTemplate);
    editBox:SetSize(BG.maijiaWidth, 20)
    editBox:SetPoint("TOPLEFT", preWidget, "TOPRIGHT", 5, 0);
    editBox:SetFrameLevel(110)
    editBox:SetMaxBytes(19) --限制字数
    editBox:SetAutoFocus(false)
    editBox:SetEnabled(false)
    BG.SetBorderAlpha(editBox)
    if BossNum(FB, b, t) <= Maxb[FB] then
        preWidget = editBox
    else
        editBox:Hide()
    end
    BG.ReceiveFrame[FB]["boss" .. BossNum(FB, b, t)]["maijia" .. i] = editBox

    -- 鼠标悬停在装备时
    editBox:SetScript("OnEnter", function(self)
        BG.ReceiveFrameDs[FB .. 1]["boss" .. BossNum(FB, b, t)]["ds" .. i]:Show()
    end)
    editBox:SetScript("OnLeave", function(self)
        BG.ReceiveFrameDs[FB .. 1]["boss" .. BossNum(FB, b, t)]["ds" .. i]:Hide()
        GameTooltip:Hide()
    end)
end

------------------金额------------------
function BG.ReceiveJinEUI(FB, t, b, bb, i, ii)
    local editBox = CreateFrame("EditBox", nil, BG.ReceiveFrame[FB]["boss" .. BossNum(FB, b, t)]["zhuangbei" .. i], BG.editTemplate);
    editBox:SetSize(BG.jineWidth, 20)
    editBox:SetPoint("TOPLEFT", preWidget, "TOPRIGHT", 5, 0);
    editBox:SetFrameLevel(110)
    editBox:SetAutoFocus(false)
    editBox:SetEnabled(false)
    BG.SetBorderAlpha(editBox)
    preWidget = editBox
    BG.ReceiveFrame[FB]["boss" .. BossNum(FB, b, t)]["jine" .. i] = editBox
    BG.ReceiveFrame[FB]["boss" .. BossNum(FB, b, t)]["qiankuan" .. i] =
    BG.CreateQiankuanButton(editBox, "receive")
    -- 鼠标悬停在装备时
    editBox:SetScript("OnEnter", function(self)
        BG.ReceiveFrameDs[FB .. 1]["boss" .. BossNum(FB, b, t)]["ds" .. i]:Show()
    end)
    editBox:SetScript("OnLeave", function(self)
        BG.ReceiveFrameDs[FB .. 1]["boss" .. BossNum(FB, b, t)]["ds" .. i]:Hide()
        GameTooltip:Hide()
    end)
end

------------------底色材质------------------
function BG.ReceiveDiSeUI(FB, t, b, bb, i, ii)
    -- 先绘制第一层底色贴图，用于鼠标悬停效果
    local hoverTexture = BG.ReceiveFrame[FB]["boss" .. BossNum(FB, b, t)]["zhuangbei" .. i]:CreateTexture()
    hoverTexture:SetPoint("TOPLEFT", BG.ReceiveFrame[FB]["boss" .. BossNum(FB, b, t)]["zhuangbei" .. i], "TOPLEFT", -4, -2)
    hoverTexture:SetPoint("BOTTOMRIGHT", BG.ReceiveFrame[FB]["boss" .. BossNum(FB, b, t)]["jine" .. i], "BOTTOMRIGHT", -2, 0)
    -- textrue:SetColorTexture(red, greed, blue, touming1)
    hoverTexture:Hide()
    BG.ReceiveFrameDs[FB .. 1]["boss" .. BossNum(FB, b, t)]["ds" .. i] = hoverTexture
end

------------------支出、总览与工资区域------------------
function BG.ReceiveZhiChuZongLanGongZiUI(FB)
    local expenseBoss = Maxb[FB] + 1
    local summaryBoss = Maxb[FB] + 2
    local colorRounds = {
        { boss = expenseBoss, first = 1, last = BG.GetMaxi(FB, expenseBoss), color = { RGB("00FF00") }, requireCell = true },
        { boss = summaryBoss, first = 1, last = 3, color = { RGB("EE82EE") } },
        { boss = summaryBoss, first = 4, last = 5, color = { RGB("00BFFF") } },
    }
    for _, round in ipairs(colorRounds) do
        for cellIndex = round.first, round.last, 1 do
            local equipmentCell = BG.ReceiveFrame[FB]["boss" .. round.boss]["zhuangbei" .. cellIndex]
            if not round.requireCell or equipmentCell then
                equipmentCell:SetTextColor(unpack(round.color))
                BG.ReceiveFrame[FB]["boss" .. round.boss]["jine" .. cellIndex]:SetTextColor(unpack(round.color))
            end
        end
    end
end
