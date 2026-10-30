if BG.IsBlackListPlayer then return end

local AddonName, ns = ...

local L = ns.L

local RR = ns.RR
local RGB = ns.RGB
local GetClassRGB = ns.GetClassRGB
local SetClassCFF = ns.SetClassCFF
local GetText_T = ns.GetText_T
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID

local Maxb = ns.Maxb

local player = BG.playerName

local K = {
    Frame = "Frame",
    BackdropTemplate = "BackdropTemplate",
    N_395 = 395,
    N_230 = 230,
    TOP = "TOP",
    N_0 = 0,
    N_55 = 55,
    N_1 = 1,
    N_4 = 4,
    N_10 = 10,
    EditBox = "EditBox",
    N_20 = 20,
    N_2 = 2,
    TOPLEFT = "TOPLEFT",
    N_97 = 97,
    N_5 = 5,
    BOTTOMLEFT = "BOTTOMLEFT",
    player = "player",
    HEALER = "HEALER",
    N_3 = 3,
    BOTTOMRIGHT = "BOTTOMRIGHT",
    N_0_2 = 0.2,
    OnMouseDown = "OnMouseDown",
    OnEnter = "OnEnter",
    OnLeave = "OnLeave",
    zhuangbei = "zhuangbei",
    EMPTY = "",
    N_0_3 = 0.3,
    OnUpdate = "OnUpdate",
    COLOR_FFD700 = "|cffFFD700",
    COLOR_END = "|rg",
    COLOR_FF0000 = "|cffFF0000",
    COLOR_PREFIX = "|cff",
    TEX_CHATFRAMEBACKGROUND = "Interface/ChatFrame/ChatFrameBackground",
    TEX_UI_DIALOGBOX_BORDER = "Interface/DialogFrame/UI-DialogBox-Border",
    N_32 = 32,
    N_0_8 = 0.8,
    N_430 = 430,
    N_380 = 380,
    HIGH = "HIGH",
    N_300 = 300,
    OnMouseUp = "OnMouseUp",
    OnHyperlinkEnter = "OnHyperlinkEnter",
    ANCHOR_CURSOR = "ANCHOR_CURSOR",
    OnHyperlinkLeave = "OnHyperlinkLeave",
    OnShow = "OnShow",
    OnHide = "OnHide",
    ARTWORK = "ARTWORK",
    TEX_UI_DIALOGBOX_HEADER = "Interface/DialogFrame/UI-DialogBox-Header",
    N_256 = 256,
    N_64 = 64,
    N_12 = 12,
    N_15 = 15,
    OUTLINE = "OUTLINE",
    N_13 = 13,
    N_35 = 35,
    FFD100 = "FFD100",
    LEFT = 'LEFT',
    N_18 = 18,
    N_120 = 120,
    BOTTOM = "BOTTOM",
    N_60 = 60,
    OnTextChanged = "OnTextChanged",
    OnEnterPressed = "OnEnterPressed",
    OnTabPressed = "OnTabPressed",
    RightButton = "RightButton",
    OnEditFocusGained = "OnEditFocusGained",
    OnEditFocusLost = "OnEditFocusLost",
    RIGHT = "RIGHT",
    N_40 = 40,
    N_70 = 70,
    shortName = "shortName",
    Button = "Button",
    UIPanelButtonTemplate = "UIPanelButtonTemplate",
    N_150 = 150,
    N_25 = 25,
    OnClick = "OnClick",
    N_0_7 = 0.7,
    N_200 = 200,
    N_16 = 16,
    N_8 = 8,
    N_45 = 45,
    S_83 = ":",
    item = "item",
    N_80 = 80,
    N_90 = 90,
    RAID = "RAID",
    N_0_1 = 0.1,
}

BG.Init(function()
    -- 创建买家
    local function CreateMaijiaFrame(parent)
        local f = CreateFrame(K.Frame, nil, parent, K.BackdropTemplate)
        f:SetWidth(K.N_395)
        f:SetHeight(K.N_230)
        f:SetPoint(K.TOP, parent, K.TOP, K.N_0, -K.N_55)
        f:EnableMouse(true)
        parent.maijiaFrame = f
        parent.buttons = {}
        local framedown
        local frameright = f
        local raid = BG.SortRaidRosterInfo()
        for t = K.N_1, K.N_4 do
            for i = K.N_1, K.N_10 do
                local bt = CreateFrame(K.EditBox, nil, f, BG.editTemplate)
                bt:SetSize(BG.maijiaWidth, K.N_20)
                bt:SetAutoFocus(false)
                bt:SetEnabled(false)
                if t >= K.N_2 and i == K.N_1 then
                    bt:SetPoint(K.TOPLEFT, frameright, K.TOPLEFT, K.N_97, K.N_0)
                    frameright = bt
                end
                if t == K.N_1 and i == K.N_1 then
                    bt:SetPoint(K.TOPLEFT, frameright, K.TOPLEFT, K.N_10, -K.N_5)
                    frameright = bt
                end
                if i > K.N_1 then
                    bt:SetPoint(K.TOPLEFT, framedown, K.BOTTOMLEFT, K.N_0, -K.N_2)
                end
                if not IsInRaid(K.N_1) and t == K.N_1 and i == K.N_1 then -- 单人时
                    bt:SetText(BG.playerName)
                    bt:SetCursorPosition(K.N_0)
                    bt:SetTextColor(GetClassRGB(BG.playerName))
                    bt.hasName = true
                    for k, v in pairs(BG.playerClass) do
                        bt[k] = select(v.select, v.func(K.player))
                    end
                end
                local num = (t - K.N_1) * K.N_10 + i
                if raid[num] and raid[num].name then
                    if raid[num].role then
                        bt:SetText(AddTexture(raid[num].role) .. raid[num].name)
                    elseif raid[num].combatRole == K.HEALER then
                        bt:SetText(AddTexture(raid[num].combatRole) .. raid[num].name)
                    else
                        bt:SetText(raid[num].name)
                    end
                    bt:SetCursorPosition(K.N_0)
                    bt:SetTextColor(GetClassRGB(GetText_T(raid[num].name)))
                    bt.hasName = true
                else
                    bt:EnableMouse(false)
                end
                framedown = bt

                if bt.hasName then
                    tinsert(parent.buttons, bt)

                    bt.ds = bt:CreateTexture()
                    bt.ds:SetPoint(K.TOPLEFT, -K.N_3, -K.N_2)
                    bt.ds:SetPoint(K.BOTTOMRIGHT, -K.N_1, K.N_2)
                    bt.ds:SetColorTexture(K.N_1, K.N_1, K.N_1, BG.onEnterAlpha)
                    bt.ds:Hide()

                    bt.choose = bt:CreateTexture()
                    bt.choose:SetPoint(K.TOPLEFT, -K.N_3, -K.N_2)
                    bt.choose:SetPoint(K.BOTTOMRIGHT, -K.N_1, K.N_2)
                    bt.choose:SetColorTexture(K.N_0, K.N_1, K.N_0, K.N_0_2)
                    bt.choose:Hide()

                    bt:SetScript(K.OnMouseDown, function(self, enter)
                        for i, _bt in ipairs(parent.buttons) do
                            _bt.Left:SetVertexColor(K.N_1, K.N_1, K.N_1)
                            _bt.Right:SetVertexColor(K.N_1, K.N_1, K.N_1)
                            _bt.Middle:SetVertexColor(K.N_1, K.N_1, K.N_1)
                            _bt.choose:Hide()
                        end
                        if parent.maijia == GetText_T(self) then
                            parent.maijia = nil
                            for k, v in pairs(BG.playerClass) do
                                parent[k] = nil
                            end
                        else
                            parent.maijia = GetText_T(self)
                            if raid[num] or self.class then
                                for k, v in pairs(BG.playerClass) do
                                    parent[k] = raid[num] and raid[num][k] or self[k]
                                end
                            end
                            self.Left:SetVertexColor(K.N_0, K.N_1, K.N_0)
                            self.Right:SetVertexColor(K.N_0, K.N_1, K.N_0)
                            self.Middle:SetVertexColor(K.N_0, K.N_1, K.N_0)
                            self.choose:Show()
                        end
                        BG.ChatAccountingFrame:SureButtonUpdate()
                        BG.PlaySound(K.N_1)
                    end)
                    bt:SetScript(K.OnEnter, function(self)
                        self.ds:Show()
                    end)
                    bt:SetScript(K.OnLeave, function(self)
                        GameTooltip:Hide()
                        self.ds:Hide()
                    end)
                end
            end
        end
    end
    -- 找到合适的格子
    local function HasEmptyGeZi(link)
        local FB = BG.FB1
        for b = K.N_1, Maxb[FB] do
            for i = K.N_1, BG.GetMaxi(FB, b) do
                local zhuangbei = BG.Frame[FB]["boss" .. b][K.zhuangbei .. i]
                local maijia = BG.Frame[FB]["boss" .. b]["maijia" .. i]
                local jine = BG.Frame[FB]["boss" .. b]["jine" .. i]

                if zhuangbei and GetItemID(zhuangbei:GetText()) == GetItemID(link) and
                    maijia:GetText() == K.EMPTY and jine:GetText() == K.EMPTY and
                    not BiaoGe[FB]["boss" .. b]["qiankuan" .. i] then
                    return b, i, zhuangbei, maijia, jine, FB
                end
            end
        end
    end
    -- 记账失败
    local frames = {}
    local updateFrame = CreateFrame(K.Frame)
    updateFrame.time = K.N_0
    local function JiZhangError(link)
        BG.FrameLootMsg:AddMessage(L["表格里没找到此次交易的装备，或者该装备已记过账"], RED_FONT_COLOR:GetRGB())
        if BG.ChatAccountingFrame:IsVisible() then
            BG.ChatAccountingFrame:Hide()
        end

        for i, textrue in ipairs(frames) do
            textrue:Hide()
        end
        wipe(frames)

        updateFrame.time = K.N_0
        local FB = BG.FB1
        for b = K.N_1, Maxb[FB] do
            for i = K.N_1, BG.GetMaxi(FB, b) do
                local zhuangbei = BG.Frame[FB]["boss" .. b][K.zhuangbei .. i]
                local maijia = BG.Frame[FB]["boss" .. b]["maijia" .. i]
                local jine = BG.Frame[FB]["boss" .. b]["jine" .. i]

                if zhuangbei and GetItemID(zhuangbei:GetText()) == GetItemID(link) then
                    if not zhuangbei.JiZhangErrorTextrue then
                        local textrue = zhuangbei:CreateTexture()
                        textrue:SetPoint(K.TOPLEFT, zhuangbei, K.TOPLEFT, -K.N_4, -K.N_2)
                        textrue:SetPoint(K.BOTTOMRIGHT, jine, K.BOTTOMRIGHT, -K.N_2, K.N_0)
                        textrue:SetColorTexture(K.N_1, K.N_0, K.N_0, K.N_0_3)
                        zhuangbei.JiZhangErrorTextrue = textrue
                    end
                    zhuangbei.JiZhangErrorTextrue:Show()
                    zhuangbei.JiZhangErrorTextrue:SetAlpha(K.N_1)
                    tinsert(frames, zhuangbei.JiZhangErrorTextrue)
                end
            end
        end
        if #frames ~= K.N_0 then
            updateFrame:SetScript(K.OnUpdate, function(self, elapsed)
                updateFrame.time = updateFrame.time + elapsed
                if updateFrame.time >= K.N_3 and updateFrame.time < K.N_5 then
                    for i, textrue in ipairs(frames) do
                        textrue:SetAlpha((K.N_5 - updateFrame.time) / K.N_2)
                    end
                elseif updateFrame.time >= K.N_5 then
                    for i, textrue in ipairs(frames) do
                        textrue:Hide()
                    end
                    updateFrame.time = K.N_0
                    updateFrame:SetScript(K.OnUpdate, nil)
                end
            end)
        end
    end
    -- 记账效果预览
    local function UpdateSeeText()
        if not BG.ChatAccountingFrame.itemLink then return end
        if BG.ChatAccountingFrame.maijia or BG.ChatAccountingFrame.jine ~= K.EMPTY then
            local b, i, zhuangbei, maijia, jine, FB = HasEmptyGeZi(BG.ChatAccountingFrame.itemLink)
            local Texture = select(K.N_10, GetItemInfo(BG.ChatAccountingFrame.itemLink))
            local maijiaText = SetClassCFF(BG.ChatAccountingFrame.maijia or K.EMPTY)
            if maijiaText == K.EMPTY then
                maijiaText = BG.STC_y2(L["无"])
            end
            local jineText = K.COLOR_FFD700 .. K.N_0 .. K.COLOR_END
            if BG.ChatAccountingFrame.jine ~= K.EMPTY then
                jineText = K.COLOR_FFD700 .. BG.ChatAccountingFrame.jine .. K.COLOR_END
            end
            local qiankuantext = K.EMPTY
            if BG.ChatAccountingFrame.qiankuan ~= K.EMPTY then
                qiankuantext = format(K.COLOR_FF0000 .. L["（欠款%d）"] .. RR, BG.ChatAccountingFrame.qiankuan)
            end

            local text = format(L["|cff00BFFF< 快速记账成功 >|r\n|cffFFFFFF装备：%s\n买家：%s\n金额：%s%s\nBoss：%s"],
                (AddTexture(Texture) .. BG.ChatAccountingFrame.itemLink),
                maijiaText,
                jineText,
                qiankuantext,
                K.COLOR_PREFIX .. BG.Boss[FB]["boss" .. b]["color"] .. BG.Boss[FB]["boss" .. b]["name2"] .. RR)
            BG.ChatAccountingFrame.seeText:SetText(text)
        else
            BG.ChatAccountingFrame.seeText:SetText(K.EMPTY)
        end
    end

    -- 主UI
    local f = CreateFrame(K.Frame, "BG.ChatAccountingFrame", UIParent, K.BackdropTemplate)
    do
        f:SetBackdrop({
            bgFile = K.TEX_CHATFRAMEBACKGROUND,
            edgeFile = K.TEX_UI_DIALOGBOX_BORDER,
            edgeSize = K.N_32,
            insets = { left = K.N_3, right = K.N_3, top = K.N_3, bottom = K.N_3 }
        })
        f:SetBackdropColor(K.N_0, K.N_0, K.N_0, K.N_0_8)
        f:SetSize(K.N_430, K.N_380)
        f:SetFrameStrata(K.HIGH)
        f:SetClampedToScreen(true)
        f:SetFrameLevel(K.N_300)
        f:EnableMouse(true)
        f:SetMovable(true)
        f:SetHyperlinksEnabled(true)
        f:SetScript(K.OnMouseUp, function(self)
            self:StopMovingOrSizing()
        end)
        f:SetScript(K.OnMouseDown, function(self)
            self:StartMoving()
        end)
        f:SetScript(K.OnHyperlinkEnter, function(self, link, text, button)
            GameTooltip:SetOwner(self, K.ANCHOR_CURSOR, K.N_0, K.N_0)
            GameTooltip:ClearLines()
            local itemID = GetItemInfoInstant(link)
            if itemID then
                GameTooltip:SetHyperlink(BG.SetSpecIDToLink(link))
            end
        end)
        f:SetScript(K.OnHyperlinkLeave, GameTooltip_Hide)
        f:SetScript(K.OnShow, function(self)
            if BG.ChatAccountingFrame.maijiaFrame then
                BG.ChatAccountingFrame.maijiaFrame:Hide()
            end
            CreateMaijiaFrame(BG.ChatAccountingFrame)
            local link = K.EMPTY
            local Texture
            if BG.ChatAccountingFrame.itemLink then
                Texture = select(K.N_10, GetItemInfo(BG.ChatAccountingFrame.itemLink))
                link = BG.ChatAccountingFrame.itemLink
            end

            local x, y = GetCursorPosition()
            x, y = x / UIParent:GetEffectiveScale(), y / UIParent:GetEffectiveScale()
            BG.ChatAccountingFrame:ClearAllPoints()
            BG.ChatAccountingFrame:SetPoint(K.BOTTOMLEFT, UIParent, K.BOTTOMLEFT, x + K.N_10, y + K.N_10)
            BG.ChatAccountingFrame.item:SetText(link)
            BG.ChatAccountingFrame.icon:SetTexture(Texture)
            BG.ChatAccountingFrame.maijia = nil
            BG.ChatAccountingFrame.jine = K.EMPTY
            BG.ChatAccountingFrame.qiankuan = K.EMPTY
            BG.ChatAccountingFrame.jineFrame:SetText(K.EMPTY)
            BG.ChatAccountingFrame.jineFrame:SetFocus()
            BG.ChatAccountingFrame.qiankuanFrame:SetText(K.EMPTY)
            for k, v in pairs(BG.playerClass) do
                BG.ChatAccountingFrame[k] = nil
            end
            if BiaoGe.options.fastCountPreview == K.N_1 then
                BG.ChatAccountingFrame.seeFrame:Show()
            else
                BG.ChatAccountingFrame.seeFrame:Hide()
            end
            BG.ChatAccountingFrame:SureButtonUpdate()
        end)
        f:SetScript(K.OnHide, function(self)
            if BG.ChatAccountingFrame.BlinkHilight then
                BG.ChatAccountingFrame.BlinkHilight:Hide()
            end
        end)
        BG.ChatAccountingFrame = f
    end
    tinsert(UISpecialFrames, "BG.ChatAccountingFrame")

    -- 顶部标题
    do
        local t = f:CreateTexture(nil, K.ARTWORK)
        t:SetTexture(K.TEX_UI_DIALOGBOX_HEADER)
        t:SetWidth(K.N_256)
        t:SetHeight(K.N_64)
        t:SetPoint(K.TOP, f, K.N_0, K.N_12)
        f.texture = t
        local t = f:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
        t:SetText(L["< 快速记账 >"])
        t:SetPoint(K.TOP, f.texture, K.N_0, -K.N_13)
        t:SetTextColor(RGB(BG.b1))
    end

    -- 装备
    do
        BG.ChatAccountingFrame.item = BG.ChatAccountingFrame:CreateFontString()
        BG.ChatAccountingFrame.item:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
        BG.ChatAccountingFrame.item:SetPoint(K.TOP, BG.ChatAccountingFrame, K.TOP, K.N_0, -K.N_35)
        BG.ChatAccountingFrame.item:SetTextColor(RGB(K.FFD100))

        BG.ChatAccountingFrame.icon = BG.ChatAccountingFrame:CreateTexture(nil, K.ARTWORK)
        BG.ChatAccountingFrame.icon:SetPoint(K.LEFT, BG.ChatAccountingFrame.item, K.LEFT, -K.N_20, K.N_0)
        BG.ChatAccountingFrame.icon:SetSize(K.N_18, K.N_18)
    end

    -- 金额
    do
        local edit = CreateFrame(K.EditBox, nil, BG.ChatAccountingFrame, BG.editTemplate)
        edit:SetSize(K.N_120, K.N_20)
        edit:SetPoint(K.BOTTOMRIGHT, BG.ChatAccountingFrame, K.BOTTOM, -K.N_10, K.N_60)
        edit:SetAutoFocus(false)
        BG.SetEditStickyFocus(edit)
        BG.ChatAccountingFrame.jineFrame = edit
        edit:SetScript(K.OnTextChanged, function(self)
            BG.UpdateTwo0(self)
            BG.ChatAccountingFrame.jine = self:GetText()
            BG.ChatAccountingFrame:SureButtonUpdate()
        end)
        edit:SetScript(K.OnEnterPressed, function()
            BG.ChatAccountingFrame:SureOnClick()
        end)
        edit:SetScript(K.OnTabPressed, function()
            BG.ChatAccountingFrame.qiankuanFrame:SetFocus()
        end)
        edit:SetScript(K.OnMouseDown, function(self, button)
            if button == K.RightButton then
                self:SetEnabled(false)
                self:SetText(K.EMPTY)
                if self:HasFocus() then
                    self:ClearFocus()
                end
            end
        end)
        edit:SetScript(K.OnMouseUp, function(self, button)
            self:SetEnabled(true)
        end)
        edit:SetScript(K.OnEditFocusGained, function(self)
            local f = BG.CreateNumFrame(BG.ChatAccountingFrame)
            if f then
                f:ClearAllPoints()
                f:SetPoint(K.BOTTOMRIGHT, BG.ChatAccountingFrame, K.BOTTOMLEFT, K.N_2, K.N_0)
            end
        end)
        edit:SetScript(K.OnEditFocusLost, function(self, button)
            edit:ClearHighlightText()
            BG.After(K.N_0, function()
                if BG.ChatAccountingFrame.clickChat then
                    edit:SetFocus()
                    edit:ClearHighlightText()
                end
            end)
            if BG.FrameNumFrame then
                BG.FrameNumFrame:Hide()
            end
        end)

        local t = BG.ChatAccountingFrame.jineFrame:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
        t:SetPoint(K.RIGHT, BG.ChatAccountingFrame.jineFrame, K.LEFT, -K.N_10, K.N_0)
        t:SetTextColor(RGB(K.FFD100))
        t:SetText(L["金额："])
    end

    -- 欠款
    do
        local edit = CreateFrame(K.EditBox, nil, BG.ChatAccountingFrame, BG.editTemplate)
        edit:SetSize(K.N_120, K.N_20)
        edit:SetPoint(K.BOTTOMRIGHT, BG.ChatAccountingFrame, K.BOTTOMRIGHT, -K.N_40, K.N_60)
        edit:SetAutoFocus(false)
        edit:SetNumeric(true)
        edit:SetTextColor(K.N_1, K.N_0, K.N_0)
        BG.SetEditStickyFocus(edit)
        BG.ChatAccountingFrame.qiankuanFrame = edit
        edit:SetScript(K.OnTextChanged, function(self)
            BG.UpdateTwo0(self)
            BG.ChatAccountingFrame.qiankuan = self:GetText()
            BG.ChatAccountingFrame:SureButtonUpdate()
        end)
        edit:SetScript(K.OnEnterPressed, function()
            BG.ChatAccountingFrame:SureOnClick()
        end)
        edit:SetScript(K.OnTabPressed, function()
            BG.ChatAccountingFrame.jineFrame:SetFocus()
        end)
        edit:SetScript(K.OnMouseDown, function(self, button)
            if button == K.RightButton then
                self:SetEnabled(false)
                self:SetText(K.EMPTY)
                if self:HasFocus() then
                    self:ClearFocus()
                end
            end
        end)
        edit:SetScript(K.OnMouseUp, function(self, button)
            self:SetEnabled(true)
        end)
        edit:SetScript(K.OnEditFocusGained, function(self)
            local f = BG.CreateNumFrame(BG.ChatAccountingFrame)
            if f then
                f:ClearAllPoints()
                f:SetPoint(K.BOTTOMRIGHT, BG.ChatAccountingFrame, K.BOTTOMLEFT, K.N_2, K.N_0)
            end
        end)
        edit:SetScript(K.OnEditFocusLost, function(self, button)
            edit:ClearHighlightText()
            BG.After(K.N_0, function()
                if BG.ChatAccountingFrame.clickChat then
                    edit:SetFocus()
                    edit:ClearHighlightText()
                end
            end)
            if BG.FrameNumFrame then
                BG.FrameNumFrame:Hide()
            end
        end)

        local t = BG.ChatAccountingFrame.qiankuanFrame:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
        t:SetPoint(K.RIGHT, BG.ChatAccountingFrame.qiankuanFrame, K.LEFT, -K.N_10, K.N_0)
        t:SetTextColor(RGB(K.FFD100))
        t:SetText(L["欠款："])
        t:SetJustifyH(K.RIGHT)
        t:SetWidth(K.N_70)
    end

    -- 确定/取消
    do
        local function GetJinE(jine)
            if jine and jine ~= K.EMPTY then
                return jine
            end
            return K.N_0
        end
        function BG.ChatAccountingFrame:SureOnClick()
            if not self.sureButton:IsEnabled() then return end
            local b, i, zhuangbei, maijia, jine, FB = HasEmptyGeZi(self.itemLink)
            if b then
                maijia:SetText(self.maijia or K.EMPTY)
                maijia:SetTextColor(unpack(self.color or { K.N_1, K.N_1, K.N_1 }))
                jine:SetText(GetJinE(self.jine))
                BiaoGe[FB]["boss" .. b]["maijia" .. i] = self.maijia
                BiaoGe[FB]["boss" .. b]["jine" .. i] = GetJinE(self.jine)
                for k, v in pairs(BG.playerClass) do
                    BiaoGe[FB]["boss" .. b][k .. i] = self[k]
                end

                local Texture = select(K.N_10, GetItemInfo(self.itemLink))

                local maijiaText = SetClassCFF(self.maijia or K.EMPTY)
                if maijiaText == K.EMPTY then
                    maijiaText = BG.STC_y2(L["无"])
                end

                local jineText = K.COLOR_FFD700 .. K.N_0 .. K.COLOR_END
                if self.jine ~= K.EMPTY then
                    jineText = K.COLOR_FFD700 .. self.jine .. K.COLOR_END
                end

                local qiankuantext = K.EMPTY
                if self.qiankuan ~= K.EMPTY then
                    BiaoGe[FB]["boss" .. b]["qiankuan" .. i] = self.qiankuan
                    BG.Frame[FB]["boss" .. b]["qiankuan" .. i]:Show()
                    qiankuantext = format(K.COLOR_FF0000 .. L["（欠款%d）"] .. RR, self.qiankuan)
                end
                self:Hide()

                if BiaoGe.options["fastCountMsg"] == K.N_1 then
                    local text = format(L["|cff00BFFF< 快速记账成功 >|r\n|cffFFFFFF装备：%s\n买家：%s\n金额：%s%s\n表格：%s\nBoss：%s"],
                        (AddTexture(Texture) .. self.itemLink),
                        maijiaText,
                        jineText,
                        qiankuantext,
                        BG.GetFBinfo(FB, K.shortName),
                        K.COLOR_PREFIX .. BG.Boss[FB]["boss" .. b]["color"] .. BG.Boss[FB]["boss" .. b]["name2"] .. RR)
                    BG.FrameTradeMsg:AddMessage(text)
                end
                return
            end
            JiZhangError(self.itemLink)
        end

        function BG.ChatAccountingFrame:SureButtonUpdate()
            if self.maijia or self.jine ~= K.EMPTY then
                self.sureButton:Enable()
            else
                self.sureButton:Disable()
            end
            UpdateSeeText()
        end

        local bt = CreateFrame(K.Button, nil, BG.ChatAccountingFrame, K.UIPanelButtonTemplate)
        bt:SetSize(K.N_150, K.N_25)
        bt:SetPoint(K.BOTTOMRIGHT, BG.ChatAccountingFrame, K.BOTTOM, -K.N_10, K.N_20)
        bt:SetText(L["确定"])
        BG.ChatAccountingFrame.sureButton = bt
        bt:SetScript(K.OnClick, function(self)
            BG.ChatAccountingFrame:SureOnClick()
            BG.PlaySound(K.N_1)
        end)
        local bt = CreateFrame(K.Button, nil, BG.ChatAccountingFrame, K.UIPanelButtonTemplate)
        bt:SetSize(K.N_150, K.N_25)
        bt:SetPoint(K.BOTTOMRIGHT, BG.ChatAccountingFrame, K.BOTTOMRIGHT, -K.N_40, K.N_20)
        bt:SetText(L["取消"])
        bt:SetScript(K.OnClick, function(self)
            BG.ChatAccountingFrame:Hide()
            BG.PlaySound(K.N_1)
        end)
    end

    -- 预览框
    do
        local f = CreateFrame(K.Frame, nil, BG.ChatAccountingFrame, K.BackdropTemplate)
        f:SetBackdrop({
            bgFile = K.TEX_CHATFRAMEBACKGROUND,
            edgeFile = K.TEX_CHATFRAMEBACKGROUND,
            edgeSize = K.N_1,
        })
        f:SetBackdropColor(K.N_0, K.N_0, K.N_0, K.N_0_7)
        f:SetBackdropBorderColor(K.N_0, K.N_0, K.N_0, K.N_1)
        f:SetSize(K.N_200, K.N_200)
        f:SetPoint(K.BOTTOMLEFT, BG.ChatAccountingFrame, K.BOTTOMRIGHT, -K.N_2, K.N_5)
        f:EnableMouse(true)
        BG.ChatAccountingFrame.seeFrame = f

        local text = f:CreateFontString()
        text:SetPoint(K.TOP, f, K.TOP, K.N_0, -K.N_10)
        text:SetFont(BIAOGE_TEXT_FONT, K.N_16, K.OUTLINE)
        text:SetText(L["记账效果预览"])

        local text = f:CreateFontString()
        text:SetPoint(K.TOPLEFT, f, K.TOPLEFT, K.N_8, -K.N_45)
        text:SetWidth(f:GetWidth() - K.N_10)
        text:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
        text:SetJustifyH(K.LEFT) -- 对齐格式
        BG.ChatAccountingFrame.seeText = text
    end

    hooksecurefunc("SetItemRef", function(link, text, button)
        if BG.IsML then return end -- 如果是团长或物品分配者则退出
        if BiaoGe.options["fastCount"] ~= K.N_1 then return end
        local _type, name, line, chattype = strsplit(K.S_83, link)
        if _type == K.item then
            if button == K.RightButton then
                local item, link, quality, level, _, _, _, _, _, Texture, _, typeID = GetItemInfo(link)
                if not link then return end
                if ItemRefTooltip:IsVisible() then
                    ItemRefTooltip:Hide()
                end
                local b, i, zhuangbei, maijia, jine, FB = HasEmptyGeZi(link)
                if b then
                    BG.ChatAccountingFrame.itemLink = link
                    BG.ChatAccountingFrame:Hide()
                    BG.ChatAccountingFrame:Show()
                    GameTooltip:Hide()

                    local f = BG.Create_BlinkHilight(zhuangbei)
                    f:SetPoint(K.TOPLEFT, zhuangbei, K.TOPLEFT, -K.N_80, K.N_5)
                    f:SetPoint(K.BOTTOMRIGHT, jine, K.BOTTOMRIGHT, K.N_90, -K.N_5)
                    BG.ChatAccountingFrame.BlinkHilight = f
                    return
                end
                JiZhangError(link)
            end
        elseif _type == K.player and chattype == K.RAID and BG.ChatAccountingFrame:IsVisible() then
            BG.ChatAccountingFrame.clickChat = true
            BG.After(K.N_0_1, function()
                BG.ChatAccountingFrame.clickChat = false
            end)
            ChatFrame1EditBox:Hide()
            ChatFrame1EditBox:SetText(K.EMPTY)

            local num
            local raid = BG.raidRosterInfo
            for i, v in ipairs(raid) do
                if v.name == name then
                    num = i
                    break
                end
            end
            if num then
                for i, _bt in ipairs(BG.ChatAccountingFrame.buttons) do
                    _bt.Left:SetVertexColor(K.N_1, K.N_1, K.N_1)
                    _bt.Right:SetVertexColor(K.N_1, K.N_1, K.N_1)
                    _bt.Middle:SetVertexColor(K.N_1, K.N_1, K.N_1)
                    _bt.choose:Hide()
                end
                if BG.ChatAccountingFrame.maijia == name then
                    BG.ChatAccountingFrame.maijia = nil
                    for k, v in pairs(BG.playerClass) do
                        BG.ChatAccountingFrame[k] = nil
                    end
                else
                    BG.ChatAccountingFrame.maijia = name
                    for k, v in pairs(BG.playerClass) do
                        BG.ChatAccountingFrame[k] = raid[num][k]
                    end
                    for i, _bt in ipairs(BG.ChatAccountingFrame.buttons) do
                        if GetText_T(_bt) == name then
                            _bt.Left:SetVertexColor(K.N_0, K.N_1, K.N_0)
                            _bt.Right:SetVertexColor(K.N_0, K.N_1, K.N_0)
                            _bt.Middle:SetVertexColor(K.N_0, K.N_1, K.N_0)
                            _bt.choose:Show()
                        end
                    end
                end
                BG.ChatAccountingFrame:SureButtonUpdate()
                BG.PlaySound(K.N_1)
            end
        end
    end)
end)
