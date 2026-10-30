local AddonName, ns = ...


local LibBG = ns.LibBG
local L = ns.L

local Size = ns.Size
local RGB = ns.RGB
local RGB_16 = ns.RGB_16
local GetClassRGB = ns.GetClassRGB
local SetClassCFF = ns.SetClassCFF
local GetText_T = ns.GetText_T
local AddTexture = ns.AddTexture
local SendSystemMessage = BG.SendSystemMessage
local After = C_Timer.After
local K = {
    player = "player",
    N_10000 = 10000,
    raid = "raid",
    S_4 = "\n",
    N_0 = 0,
    N_0_2 = 0.2,
    TXT_TINTERFACE_MONEYFRAME_UI = "|TInterface/MoneyFrame/UI-MoneyIcons:0:0:0:0:100:100:0:25:0:100|t",
    N_50 = 50,
    N_450 = 450,
    N_1_5 = 1.5,
    Button = "Button",
    FriendsFrameTabTemplate = "FriendsFrameTabTemplate",
    LEFT = "LEFT",
    RIGHT = "RIGHT",
    OnClick = "OnClick",
    N_829 = 829,
    OnShow = "OnShow",
    ElvUI = "ElvUI",
    Skins = 'Skins',
    TOPLEFT = 'TOPLEFT',
    TOPRIGHT = 'TOPRIGHT',
    N_19 = 19,
    NDui = "NDui",
    NDui_Plus = "NDui_Plus",
    InboxMailBag = "InboxMailBag",
    N_600 = 600,
    Frame = "Frame",
    BackdropTemplate = "BackdropTemplate",
    N_58 = 58,
    BOTTOMRIGHT = "BOTTOMRIGHT",
    PLAYER_MONEY = "PLAYER_MONEY",
    OnHide = "OnHide",
    OnEvent = "OnEvent",
    N_15 = 15,
    OUTLINE = "OUTLINE",
    CENTER = "CENTER",
    TOP = "TOP",
    N_11 = 11,
    N_55 = 55,
    N_20 = 20,
    BiaoGe_DisableSendMail = "BiaoGe_DisableSendMail",
    TEX_CHATFRAMEBACKGROUND = "Interface/ChatFrame/ChatFrameBackground",
    N_0_1 = 0.1,
    N_10 = 10,
    OnMouseDown = "OnMouseDown",
    N_335 = 335,
    N_4 = 4,
    InsetFrameTemplate = "InsetFrameTemplate",
    BOTTOM = "BOTTOM",
    N_60 = 60,
    N_12 = 12,
    OnEnter = "OnEnter",
    OnLeave = "OnLeave",
    N_75 = 75,
    N_21 = 21,
    BOTTOMLEFT = "BOTTOMLEFT",
    OnMouseUp = "OnMouseUp",
    LeftButton = "LeftButton",
    RightButton = "RightButton",
    S_60 = "   ",
    cursor = "cursor",
    MENU = "MENU",
    BACKGROUND = "BACKGROUND",
    ANCHOR_TOPLEFT = "ANCHOR_TOPLEFT",
    N_0_82 = 0.82,
    N_13 = 13,
    OVERLAY = "OVERLAY",
    TXT_INTERFACE_GROUPFRAME_UI = "interface/groupframe/ui-group-leadericon",
    MAINTANK = "MAINTANK",
    N_132064 = 132064,
    MAINASSIST = "MAINASSIST",
    N_132063 = 132063,
    K_73 = "interface/groupframe/ui-group-assistanticon",
    table = "table",
    N_80 = 80,
    N_120 = 120,
    my1 = "my1",
    my2 = "my2",
    my3 = "my3",
    my4 = "my4",
    my5 = "my5",
    N_100 = 100,
    S_83 = " ",
    EMPTY = "",
    N_0_8 = 0.8,
    N_200 = 200,
    N_0_5 = 0.5,
    N_64 = 64,
    ScrollFrame = "ScrollFrame",
    N_31 = 31,
    N_9 = 9,
    EditBox = "EditBox",
    OnTextChanged = "OnTextChanged",
    OnEscapePressed = "OnEscapePressed",
    OnEditFocusGained = "OnEditFocusGained",
    OnEditFocusLost = "OnEditFocusLost",
    S_97 = ",",
    N_110 = 110,
    CheckButton = "CheckButton",
    UIRadioButtonTemplate = "UIRadioButtonTemplate",
    N_90 = 90,
    N_24 = 24,
    ANCHOR_RIGHT = "ANCHOR_RIGHT",
    S_104 = ". ",
    S_105 = "+",
    TXT_A = "{A}",
    TXT_B = "{B}",
    TXT_C = "{C}",
    TXT_D = "{D}",
    TXT_E = "{E}",
    TXT_Y_M_D_H_M = "%y-%m-%d %H:%M",
    S_112 = "{1}",
    S_113 = "{2}",
    S_114 = "{3}",
    S_115 = "{4}",
    N_65 = 65,
    ANCHOR_BOTTOMRIGHT = "ANCHOR_BOTTOMRIGHT",
    N_210 = 210,
    N_170 = 170,
    OnEnterPressed = "OnEnterPressed",
    OnTabPressed = "OnTabPressed",
    N_45 = 45,
    TEX_UI_TOOLTIP_BORDER = "Interface/Tooltips/UI-Tooltip-Border",
    N_16 = 16,
    N_0_6 = 0.6,
    N_150 = 150,
    N_14 = 14,
    N_230 = 230,
    N_28 = 28,
    N_616343 = 616343,
    N_260 = 260,
    N_265 = 265,
    ANCHOR_TOP = "ANCHOR_TOP",
    success = "success",
    noMoney = "noMoney",
    TXT_INTERFACE_RAIDFRAME_READ = "interface/raidframe/readycheck-notready",
    OnUpdate = "OnUpdate",
    N_30 = 30,
    UI_INFO_MESSAGE = "UI_INFO_MESSAGE",
    K_140 = "interface/raidframe/readycheck-ready",
    TXT_S = "%%s",
    S_142 = "(.+)",
    S_143 = "%[",
    S_144 = "%%[",
    S_145 = "%]",
    S_146 = "%%]",
    CHAT_MSG_SYSTEM = "CHAT_MSG_SYSTEM",
    N_17 = 17,
    N_2_5 = 2.5,
    N_22 = 22,
    AnyUp = "AnyUp",
    S_152 = "808080",
    boss = "boss",
    jine = "jine",
    zhuangbei = "zhuangbei",
}

local player = UnitName(K.player)
local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded

local function ToGold(copper)
    return floor(copper / K.N_10000)
end

local function RoadSendMail()
    BiaoGe.sendMail = BiaoGe.sendMail or {}
    BiaoGe.sendMail.title = BiaoGe.sendMail.title or L["工资{A}金"]
    BiaoGe.sendMail.body = BiaoGe.sendMail.body or
        L["{C}，这是你的工资，请查收。\n感谢你参与本次金团活动！^_^\n\n邮件发送时间：{E}"]
    BiaoGe.sendMail.member = BiaoGe.sendMail.member or K.raid
    BiaoGe.sendMail.split = BiaoGe.sendMail.split or K.S_4

    BiaoGe.options.enableSendMail = BiaoGe.options.enableSendMail or 1
    if BiaoGe.options.enableSendMail == K.N_0 then return end

    local choose = {}
    local chooseBackdropColor = { K.N_0, 1, K.N_0, .2 }
    local chooseBorderColor = { K.N_0, 1, K.N_0, .8 }
    local notChooseBackdropColor = { K.N_0, K.N_0, K.N_0, K.N_0_2 }
    local notChooseBorderColor = { 1, 1, 1, .3 }
    local CreateRaidButton, DefaultRaidFrame, UpdateRaidFrame, UpdateMailFrame, InsetFrameSkin, IsRaidMember
    local goldTex = K.TXT_TINTERFACE_MONEYFRAME_UI
    local mainFrame
    local MAXLETTER1 = K.N_50
    local MAXLETTER2 = K.N_450
    local sendStartTime = BG.IsTitan and K.N_1_5 or .5
    local sendCD = sendStartTime + .5
    local sendTimeOutCD = sendCD + 1

    -- TAB按钮
    do
        local num = MailFrame.numTabs + 1
        local bt = CreateFrame(K.Button, "MailFrameTab" .. num, MailFrame, K.FriendsFrameTabTemplate)
        bt:SetID(num)
        bt:SetPoint(K.LEFT, _G["MailFrameTab" .. (num - 1)], K.RIGHT, -8, K.N_0)
        bt:SetText(L["批量"])
        BG.SendMailButton = bt
        PanelTemplates_SetNumTabs(MailFrame, num)
        bt:SetScript(K.OnClick, nil)

        local function HookMailFrameTabs()
            for i = 1, MailFrame.numTabs or K.N_0 do
                local tab = _G["MailFrameTab" .. i]
                if tab and not tab.BiaoGeSendMailHooked then
                    tab.BiaoGeSendMailHooked = true
                    if tab == bt then
                        tab:HookScript(K.OnClick, function(self)
                            PanelTemplates_SetTab(MailFrame, self:GetID())
                            PanelTemplates_SelectTab(self)
                            ButtonFrameTemplate_HideButtonBar(MailFrame)
                            MailFrameInset:Hide()
                            InboxFrame:Hide()
                            SendMailFrame:Hide()
                            SetSendMailShowing(false)
                            if InboxMailbagFrame then
                                InboxMailbagFrame:Hide()
                            end
                            mainFrame:Show()
                            PlaySound(K.N_829)
                        end)
                    else
                        tab:HookScript(K.OnClick, function(self)
                            mainFrame:Hide()
                            MailFrameInset:Show()
                        end)
                    end
                end
            end
        end
        HookMailFrameTabs()

        MailFrame:HookScript(K.OnShow, function()
            After(K.N_0, HookMailFrameTabs)
        end)
        hooksecurefunc("PanelTemplates_SetNumTabs", function(frame)
            if frame == MailFrame then
                After(K.N_0, HookMailFrameTabs)
            end
        end)

        -- 适配美化
        if IsAddOnLoaded(K.ElvUI) then
            local E = unpack(ElvUI)
            local S = E:GetModule(K.Skins)
            local tab = BG.SendMailButton
            tab:StripTextures()
            tab:ClearAllPoints()
            S:HandleTab(tab)
            tab:Point(K.TOPLEFT, _G["MailFrameTab" .. (num - 1)], K.TOPRIGHT, -K.N_19, K.N_0)
        elseif IsAddOnLoaded(K.NDui) and not (IsAddOnLoaded(K.NDui_Plus) and IsAddOnLoaded(K.InboxMailBag)) then
            local B = unpack(NDui)
            B.ReskinTab(BG.SendMailButton)
        end
    end

    -- 主界面
    do
        local width = K.N_600
        local w, h = MailFrame:GetSize()
        mainFrame = CreateFrame(K.Frame, nil, MailFrame, K.BackdropTemplate)
        mainFrame:SetPoint(K.TOPLEFT, K.N_0, -K.N_58)
        mainFrame:SetPoint(K.BOTTOMRIGHT, K.N_0, K.N_0)
        mainFrame:Hide()
        BG.SendMailMainFrame = mainFrame
        BG.SendMailButton.frame = mainFrame
        mainFrame:SetScript(K.OnShow, function(self)
            MailFrame:SetSize(width, h)
            self:RegisterEvent(K.PLAYER_MONEY)
            mainFrame:UpdateGZFrame()
        end)
        mainFrame:SetScript(K.OnHide, function(self)
            MailFrame:SetSize(w, h)
            StaticPopup_Hide("BiaoGe_SendMail")
            self:UnregisterEvent(K.PLAYER_MONEY)
        end)
        mainFrame:SetScript(K.OnEvent, function(self, event)
            if event == K.PLAYER_MONEY then
                UpdateMailFrame()
            end
        end)

        local t = mainFrame:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
        t:SetPoint(K.CENTER, MailFrame, K.TOP, K.N_0, -K.N_11)
        t:SetText(L["批量邮寄工资"])

        -- 禁用此功能
        do
            local bt = CreateFrame(K.Button, nil, mainFrame)
            bt:SetPoint(K.TOPRIGHT, MailFrame, K.TOPRIGHT, -K.N_55, -2)
            bt:SetNormalFontObject(BG.FontGreen15)
            bt:SetDisabledFontObject(BG.FontDis15)
            bt:SetHighlightFontObject(BG.FontWhite15)
            bt:SetText(L["禁用此功能"])
            bt:SetSize(bt:GetFontString():GetWidth(), K.N_20)
            BG.SetTextHighlightTexture(bt)
            bt:SetScript(K.OnClick, function()
                local name = K.BiaoGe_DisableSendMail
                if not StaticPopupDialogs[name] then
                    StaticPopupDialogs[name] = {
                        text = L["确定禁用批量邮寄功能？\n需要重载游戏才能生效。"],
                        button1 = OKAY,
                        button2 = CANCEL,
                        OnAccept = function()
                            BiaoGe.options.enableSendMail = K.N_0
                        end,
                        timeout = K.N_0,
                        whileDead = true,
                        hideOnEscape = true,
                        showAlert = true,
                    }
                end
                StaticPopup_Show(name)
            end)
        end

        local f = CreateFrame(K.Frame, nil, mainFrame, K.BackdropTemplate)
        f:SetBackdrop({
            bgFile = K.TEX_CHATFRAMEBACKGROUND,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        f:SetBackdropColor(.5, .5, .5, K.N_0_1)
        f:SetPoint(K.TOPLEFT, MailFrame, 1, -K.N_20)
        f:SetPoint(K.BOTTOMRIGHT, MailFrame, -2, 2)
        f:SetFrameLevel(f:GetParent():GetFrameLevel() + K.N_10)
        f:EnableMouse(true)
        f:Hide()
        mainFrame.disFrame = f

        MailFrame:HookScript(K.OnMouseDown, function(self)
            if mainFrame.lastFocus then
                mainFrame.lastFocus:ClearFocus()
            end
        end)
        MailFrame:HookScript(K.OnHide, function(self)
            mainFrame:Hide()
            MailFrameInset:Show()
        end)

        function InsetFrameSkin(f)
            if IsAddOnLoaded(K.NDui) or IsAddOnLoaded(K.ElvUI) then
                if f.NineSlice then
                    f.NineSlice:Hide()
                else
                    f.InsetBorderBottom:Hide()
                    f.InsetBorderBottomLeft:Hide()
                    f.InsetBorderBottomRight:Hide()
                    f.InsetBorderTop:Hide()
                    f.InsetBorderTopLeft:Hide()
                    f.InsetBorderTopRight:Hide()
                    f.InsetBorderLeft:Hide()
                    f.InsetBorderRight:Hide()
                end
                f.Bg:Hide()
            end
        end
    end

    -- 团队框架
    do
        local f = CreateFrame(K.Frame, nil, mainFrame, K.BackdropTemplate)
        f:SetPoint(K.TOPLEFT, mainFrame, K.TOPRIGHT, -K.N_335, K.N_0)
        f:SetPoint(K.BOTTOMRIGHT, mainFrame, K.BOTTOMRIGHT, -K.N_4, K.N_4)
        BG.SendMailMemberFrame = f
        BG.SendMailMemberFrame.buttons = {}
        f:SetScript(K.OnShow, function(self)
            if not f.init then
                f.init = true
                for i = 1, 40 do
                    CreateRaidButton(i)
                end
                InsetFrameSkin(mainFrame.bg1)
                InsetFrameSkin(mainFrame.bg2)
                InsetFrameSkin(mainFrame.bg3)
            end
            UpdateRaidFrame()
        end)
        local f = CreateFrame(K.Frame, nil, BG.SendMailMemberFrame, K.InsetFrameTemplate)
        f:SetAllPoints()
        f:SetFrameLevel(BG.SendMailMemberFrame:GetFrameLevel())
        mainFrame.bg1 = f

        local function SetChoose(bt, _choose)
            if _choose == 1 then
                bt.ischoose = true
                bt:SetBackdropColor(unpack(chooseBackdropColor))
                bt:SetBackdropBorderColor(unpack(chooseBorderColor))
                choose[bt.name] = {
                    name = bt.name,
                    colorName = bt.nameText:GetText(),
                    guid = bt.guid,
                    num = bt.num,
                }
            else
                bt.ischoose = false
                bt:SetBackdropColor(unpack(notChooseBackdropColor))
                bt:SetBackdropBorderColor(unpack(notChooseBorderColor))
                choose[bt.name] = nil
            end
        end

        local function CreateTeamNum(parent, id)
            local f = CreateFrame(K.Frame, nil, parent)
            f:SetPoint(K.BOTTOM, parent, K.TOP, K.N_0, K.N_0)
            f:SetSize(K.N_60, K.N_15)
            f.id = id
            local t = f:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, K.N_12, K.OUTLINE)
            t:SetPoint(K.CENTER)
            t:SetText(id)
            t:SetTextColor(.5, .5, .5)
            f:SetScript(K.OnMouseDown, function(self)
                local hasName = K.N_0
                local ischoose = K.N_0
                local startID = (self.id - 1) * 5 + 1
                for i = startID, startID + K.N_4 do
                    local bt = BG.SendMailMemberFrame.buttons[i]
                    if bt.name then
                        if not (bt.name == player) then
                            hasName = hasName + 1
                        end
                    end
                    if bt.ischoose then
                        ischoose = ischoose + 1
                    end
                end
                if hasName == K.N_0 then return end
                if hasName == ischoose then
                    for i = startID, startID + K.N_4 do
                        local bt = BG.SendMailMemberFrame.buttons[i]
                        if bt.name then
                            SetChoose(bt, K.N_0)
                        end
                    end
                else
                    for i = startID, startID + K.N_4 do
                        local bt = BG.SendMailMemberFrame.buttons[i]
                        if bt.name then
                            if not (bt.name == player) then
                                SetChoose(bt, 1)
                            end
                        end
                    end
                end
                UpdateMailFrame()
                BG.PlaySound(1)
            end)
            f:SetScript(K.OnEnter, function(self)
                local startID = (self.id - 1) * 5 + 1
                for i = startID, startID + K.N_4 do
                    local bt = BG.SendMailMemberFrame.buttons[i]
                    if bt.name then
                        if not (bt.name == player) then
                            t:SetTextColor(1, 1, 1)
                            return
                        end
                    end
                end
            end)
            f:SetScript(K.OnLeave, function(self)
                t:SetTextColor(.5, .5, .5)
            end)
        end

        function CreateRaidButton(i)
            local bt = CreateFrame(K.Frame, nil, nil, K.BackdropTemplate)
            bt:SetBackdrop({
                bgFile = K.TEX_CHATFRAMEBACKGROUND,
                edgeFile = K.TEX_CHATFRAMEBACKGROUND,
                edgeSize = 1,
            })
            bt:SetBackdropColor(unpack(notChooseBackdropColor))
            bt:SetBackdropBorderColor(unpack(notChooseBorderColor))
            bt:SetSize(K.N_75, 25)
            bt.num = i
            do
                if i == 1 then
                    bt:SetPoint(K.TOPLEFT, BG.SendMailMemberFrame, K.TOPLEFT, K.N_10, -K.N_20)
                    bt:SetParent(BG.SendMailMemberFrame)
                    CreateTeamNum(bt, 1)
                elseif i == K.N_21 then
                    bt:SetPoint(K.TOPLEFT, BG.SendMailMemberFrame.buttons[5], K.BOTTOMLEFT, K.N_0, -25)
                    bt:SetParent(BG.SendMailMemberFrame)
                    CreateTeamNum(bt, (i - 1) / 5 + 1)
                elseif (i - 1) % 5 == K.N_0 then
                    bt:SetPoint(K.TOPLEFT, BG.SendMailMemberFrame.buttons[i - 5], K.TOPRIGHT, 5, K.N_0)
                    bt:SetParent(BG.SendMailMemberFrame)
                    CreateTeamNum(bt, (i - 1) / 5 + 1)
                else
                    bt:SetPoint(K.TOPLEFT, BG.SendMailMemberFrame.buttons[i - 1], K.BOTTOMLEFT, K.N_0, -1)
                    local num = floor((i - 1) / 5) * 5 + 1
                    bt:SetParent(BG.SendMailMemberFrame.buttons[num])
                end
            end
            tinsert(BG.SendMailMemberFrame.buttons, bt)
            bt:SetScript(K.OnMouseUp, function(self, button)
                if not self.name then return end
                if button == K.LeftButton then
                    if self.name == player then return end
                    if self.ischoose then
                        SetChoose(self, K.N_0)
                    else
                        SetChoose(self, 1)
                    end
                    UpdateMailFrame()
                    BG.PlaySound(1)
                elseif button == K.RightButton and not IsRaidMember() then
                    local menu = {
                        {
                            text = self.name,
                            isTitle = true,
                            notCheckable = true,
                        },
                        {
                            text = K.S_60,
                            isTitle = true,
                            notCheckable = true,
                        },
                        {
                            text = L["删除该玩家"],
                            notCheckable = true,
                            func = function()
                                local key = BiaoGe.sendMail.member
                                tremove(BiaoGe.sendMail[key], i)
                                UpdateRaidFrame()
                            end
                        },
                        {
                            text = CANCEL,
                            notCheckable = true,
                            func = LibBG.CloseDropDownMenus,
                        }
                    }
                    LibBG:EasyMenu(menu, BG.dropDown, K.cursor, K.N_0, K.N_0, K.MENU, 2)
                    BG.PlaySound(1)
                end
            end)
            bt:SetScript(K.OnEnter, function(self)
                if not self.name then return end
                if not self.ds then
                    self.ds = self:CreateTexture(nil, K.BACKGROUND)
                    self.ds:SetAllPoints()
                    self.ds:SetColorTexture(.5, .5, .5, .3)
                end
                self.ds:Show()
                if self.name == player then
                    GameTooltip:SetOwner(self, K.ANCHOR_TOPLEFT, K.N_0, K.N_0)
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(L["提示："], 1, 1, 1, true)
                    GameTooltip:AddLine(L["不能给自己邮寄！"], 1, K.N_0_82, K.N_0, true)
                    GameTooltip:Show()
                    return
                end
                if self.nameText:IsTruncated() then
                    GameTooltip:SetOwner(self, K.ANCHOR_TOPLEFT, K.N_0, K.N_0)
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(self.nameText:GetText(), 1, 1, 1, true)
                    GameTooltip:Show()
                end
            end)
            bt:SetScript(K.OnLeave, function(self)
                GameTooltip:Hide()
                if self.ds then
                    self.ds:Hide()
                end
            end)

            local t = bt:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, K.N_13, K.OUTLINE)
            t:SetPoint(K.TOPLEFT, 2, -2)
            t:SetWidth(bt:GetWidth() - K.N_4)
            t:SetJustifyH(K.LEFT)
            t:SetWordWrap(false)
            bt.nameText = t

            local t = bt:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, K.N_10, K.OUTLINE)
            t:SetPoint(K.BOTTOMLEFT, 2, 1)
            t:SetWidth(bt:GetWidth() - K.N_4)
            t:SetJustifyH(K.LEFT)
            t:SetWordWrap(false)
            bt.otherText = t

            local tex = bt:CreateTexture(nil, K.OVERLAY)
            tex:SetPoint(K.CENTER, bt, K.TOPLEFT, K.N_0, -2)
            tex:SetSize(K.N_10, K.N_10)
            bt.icon = tex

            local tex = bt:CreateTexture(nil, K.OVERLAY)
            tex:SetPoint(K.RIGHT, K.N_0, K.N_0)
            tex:SetSize(25, 25)
            bt.tex = tex
        end

        function DefaultRaidFrame()
            wipe(choose)
            for i, bt in ipairs(BG.SendMailMemberFrame.buttons) do
                bt:SetBackdropColor(unpack(notChooseBackdropColor))
                bt:SetBackdropBorderColor(unpack(notChooseBorderColor))
                bt.nameText:Hide()
                bt.otherText:Hide()
                bt.name = nil
                bt.guid = nil
                bt.ischoose = nil
                bt.icon:SetTexture(nil)
                bt.tex:SetTexture(nil)
            end
        end

        function UpdateRaidFrame()
            local function UpdateNameSize(fontString)
                fontString:SetFont(BIAOGE_TEXT_FONT, K.N_13, K.OUTLINE)
                if fontString:IsTruncated() then
                    fontString:SetFont(BIAOGE_TEXT_FONT, K.N_12, K.OUTLINE)
                end
                if fontString:IsTruncated() then
                    fontString:SetFont(BIAOGE_TEXT_FONT, K.N_11, K.OUTLINE)
                end
            end
            DefaultRaidFrame()
            if IsRaidMember() then
                BG.SendMailMemberFrame.refreshButton:Show()
                BG.SendMailMemberFrame.importButton:Hide()
                if mainFrame.importFrame then
                    mainFrame.importFrame:Hide()
                end
                if IsInRaid(1) then
                    for _, v in ipairs(BG.raidRosterInfo) do
                        for i = (v.subgroup - 1) * 5 + 1, v.subgroup * 5 do
                            local bt = BG.SendMailMemberFrame.buttons[i]
                            if not bt.name then
                                bt.name = v.name
                                bt.guid = v.guid
                                bt.nameText:SetText(SetClassCFF(v.name))
                                bt.nameText:Show()
                                UpdateNameSize(bt.nameText)
                                if v.rank == 2 then
                                    bt.icon:SetTexture(K.TXT_INTERFACE_GROUPFRAME_UI)
                                elseif v.role == K.MAINTANK then
                                    bt.icon:SetTexture(K.N_132064)
                                elseif v.role == K.MAINASSIST then
                                    bt.icon:SetTexture(K.N_132063)
                                elseif v.rank == 1 then
                                    bt.icon:SetTexture(K.K_73)
                                end
                                if not BG.raidRosterIsOnline[v.name] then
                                    bt.otherText:SetText(L["离线"])
                                    bt.otherText:SetTextColor(.5, .5, .5)
                                    bt.otherText:Show()
                                end
                                break
                            end
                        end
                    end
                end
            else
                BG.SendMailMemberFrame.refreshButton:Hide()
                BG.SendMailMemberFrame.importButton:Show()
                local key = BiaoGe.sendMail.member
                if type(BiaoGe.sendMail[key]) == K.table then
                    for i, name in ipairs(BiaoGe.sendMail[key]) do
                        if i > 40 then break end
                        local bt = BG.SendMailMemberFrame.buttons[i]
                        bt.name = name
                        bt.nameText:SetText(name)
                        bt.nameText:Show()
                        UpdateNameSize(bt.nameText)
                    end
                end
            end
            UpdateMailFrame(true)
        end

        function IsRaidMember()
            return BiaoGe.sendMail.member == K.raid
        end

        -- 全选
        do
            local bt = BG.CreateButton(BG.SendMailMemberFrame)
            bt:SetSize(K.N_80, 25)
            bt:SetPoint(K.BOTTOMLEFT, K.N_10, K.N_20)
            bt:SetText(L["全选"])
            BG.SendMailMemberFrame.allChooseButton = bt
            bt:SetScript(K.OnClick, function(self)
                BG.PlaySound(1)
                wipe(choose)
                for i, bt in ipairs(BG.SendMailMemberFrame.buttons) do
                    if bt.name then
                        if not (bt.name == player) then
                            SetChoose(bt, 1)
                        end
                    end
                end
                UpdateMailFrame()
            end)
        end
        -- 取消全选
        do
            local bt = BG.CreateButton(BG.SendMailMemberFrame)
            bt:SetSize(K.N_80, 25)
            bt:SetPoint(K.LEFT, BG.SendMailMemberFrame.allChooseButton, K.RIGHT, 5, K.N_0)
            bt:SetText(L["取消全选"])
            BG.SendMailMemberFrame.cancelChooseButton = bt
            bt:SetScript(K.OnClick, function(self)
                BG.PlaySound(1)
                bt.Click()
            end)
            function bt.Click()
                wipe(choose)
                for _, bt in ipairs(BG.SendMailMemberFrame.buttons) do
                    if bt.name then
                        bt.ischoose = false
                        bt:SetBackdropColor(unpack(notChooseBackdropColor))
                        bt:SetBackdropBorderColor(unpack(notChooseBorderColor))
                    end
                end
                UpdateMailFrame()
            end
        end
        -- 刷新团队框架
        do
            local bt = BG.CreateButton(BG.SendMailMemberFrame)
            bt:SetSize(K.N_120, 25)
            bt:SetPoint(K.BOTTOMRIGHT, -K.N_10, K.N_20)
            bt:SetText(L["刷新团队框架"])
            BG.SendMailMemberFrame.refreshButton = bt
            bt:SetScript(K.OnClick, function(self)
                BG.PlaySound(1)
                UpdateRaidFrame()
            end)
        end
    end

    -- 名单下拉菜单
    do
        local tbl = {
            { key = K.raid, name = L["团队成员"] },
            { key = K.my1, name = L["自定义名单1"] },
            { key = K.my2, name = L["自定义名单2"] },
            { key = K.my3, name = L["自定义名单3"] },
            { key = K.my4, name = L["自定义名单4"] },
            { key = K.my5, name = L["自定义名单5"] },
        }
        local function Set(key)
            for i, v in ipairs(tbl) do
                if v.key == key then
                    return v.name
                end
            end
        end

        local dropDown = LibBG:Create_UIDropDownMenu(nil, mainFrame)
        dropDown:SetPoint(K.BOTTOMRIGHT, mainFrame, K.TOPRIGHT, 8, -3)
        LibBG:UIDropDownMenu_SetWidth(dropDown, K.N_120)
        LibBG:UIDropDownMenu_SetAnchor(dropDown, -K.N_15, K.N_0, K.TOPRIGHT, dropDown, K.BOTTOMRIGHT)
        BG.dropDownToggle(dropDown)
        mainFrame.dropDown = dropDown
        local text = dropDown:CreateFontString()
        text:SetPoint(K.RIGHT, dropDown, K.LEFT, K.N_15, 2)
        text:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
        text:SetTextColor(RGB(BG.y2))
        text:SetText(L["名单："])
        LibBG:UIDropDownMenu_SetText(dropDown, Set(BiaoGe.sendMail.member))
        LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level)
            for _, v in ipairs(tbl) do
                local info = LibBG:UIDropDownMenu_CreateInfo()
                info.text = v.name
                if v.key == BiaoGe.sendMail.member then
                    info.checked = true
                end
                info.func = function()
                    BiaoGe.sendMail.member = v.key
                    LibBG:UIDropDownMenu_SetText(dropDown, Set(BiaoGe.sendMail.member))
                    UpdateRaidFrame()
                end
                LibBG:UIDropDownMenu_AddButton(info)
            end
        end)
    end

    -- 导入名单
    do
        local CreateUI
        local bt = BG.CreateButton(BG.SendMailMemberFrame)
        bt:SetSize(K.N_100, 25)
        bt:SetPoint(K.BOTTOMRIGHT, -K.N_10, K.N_20)
        bt:SetText(L["导入名单"])
        BG.SendMailMemberFrame.importButton = bt
        bt:SetScript(K.OnClick, function(self)
            BG.PlaySound(1)
            if not mainFrame.importFrame then
                CreateUI()
                return
            end
            mainFrame.importFrame:SetShown(not mainFrame.importFrame:IsVisible())
        end)

        local function GetNameTbl()
            local parent = mainFrame.importFrame
            local split = BiaoGe.sendMail.split
            local tbl = { strsplit(split, parent.edit:GetText()) }
            for i = #tbl, 1, -1 do
                local name = tbl[i]
                if name:gsub(K.S_83, K.EMPTY) == K.EMPTY or string.utf8len(name) > MAXLETTER1 then
                    tremove(tbl, i)
                end
            end
            -- 去重
            local seen = {}
            local result = {}
            for _, value in ipairs(tbl) do
                if not seen[value] then
                    tinsert(result, value)
                    seen[value] = true
                end
            end
            return result
        end

        local function StartImport()
            local parent = mainFrame.importFrame
            local key = BiaoGe.sendMail.member
            BiaoGe.sendMail[key] = {}
            local tbl = GetNameTbl()
            for i, name in ipairs(tbl) do
                if i > 40 then break end
                tinsert(BiaoGe.sendMail[key], name)
            end
            UpdateRaidFrame()
            parent:Hide()
        end

        function CreateUI()
            local parent

            local function SetEditText()
                local edit = parent.edit
                local text = K.EMPTY
                local key = BiaoGe.sendMail.member
                local split = BiaoGe.sendMail.split
                if type(BiaoGe.sendMail[key]) == K.table then
                    for i, name in ipairs(BiaoGe.sendMail[key]) do
                        if i == #BiaoGe.sendMail[key] then
                            text = text .. name
                        else
                            text = text .. name .. split
                        end
                    end
                end
                edit:SetText(text)
                edit:SetFocus()
                edit:HighlightText()
                After(K.N_0, function()
                    local max = select(2, parent.scroll.ScrollBar:GetMinMaxValues())
                    parent.scroll.ScrollBar:SetValue(max)
                end)
            end
            -- 背景
            do
                local f = CreateFrame(K.Frame, nil, BG.SendMailMemberFrame.importButton, K.BackdropTemplate)
                f:SetBackdrop({
                    bgFile = K.TEX_CHATFRAMEBACKGROUND,
                    edgeFile = K.TEX_CHATFRAMEBACKGROUND,
                    edgeSize = 1,
                })
                f:SetBackdropColor(K.N_0, K.N_0, K.N_0, K.N_0_8)
                f:SetBackdropBorderColor(K.N_0, K.N_0, K.N_0, 1)
                f:SetPoint(K.TOPLEFT, mainFrame.gzFrame, K.TOPRIGHT, 1, K.N_0)
                f:SetPoint(K.BOTTOMRIGHT, mainFrame.gzFrame, K.BOTTOMRIGHT, K.N_200, K.N_0)
                f:EnableMouse(true)
                mainFrame.importFrame = f
                parent = f

                local t = parent:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
                t:SetPoint(K.TOP, K.N_0, -5)
                t:SetText(L["导入名单"])
            end
            -- 滚动框
            do
                local frame = CreateFrame(K.Frame, nil, parent, K.BackdropTemplate)
                frame:SetBackdrop({
                    bgFile = K.TEX_CHATFRAMEBACKGROUND,
                    edgeFile = K.TEX_CHATFRAMEBACKGROUND,
                    edgeSize = 1,
                })
                frame:SetBackdropColor(K.N_0, K.N_0, K.N_0, K.N_0_5)
                frame:SetBackdropBorderColor(.5, .5, .5, 1)
                frame:SetPoint(K.TOPLEFT, 5, -K.N_50)
                frame:SetPoint(K.BOTTOMRIGHT, -5, K.N_64)
                frame:EnableMouse(true)
                parent.frame = frame
                local scroll = CreateFrame(K.ScrollFrame, nil, frame, BG.scrollTemplate)
                scroll:SetWidth(frame:GetWidth() - K.N_31)
                scroll:SetHeight(frame:GetHeight() - K.N_9)
                scroll:SetPoint(K.TOPLEFT, frame, K.TOPLEFT, 5, -5)
                parent.scroll = scroll
                local edit = CreateFrame(K.EditBox, nil, frame)
                edit:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
                edit:SetWidth(scroll:GetWidth())
                edit:SetHeight(scroll:GetHeight())
                edit:SetAutoFocus(false)
                edit:SetMultiLine(true)
                parent.edit = edit
                scroll:SetScrollChild(edit)
                SetEditText()
                edit:SetScript(K.OnShow, function(self)
                    SetEditText()
                end)
                edit:SetScript(K.OnTextChanged, function(self)
                    local bt = parent.SureButton
                    if bt.isOnEnter then
                        bt:GetScript(K.OnEnter)(bt)
                    end
                end)
                edit:SetScript(K.OnEscapePressed, function(self)
                    self:ClearFocus()
                end)
                edit:SetScript(K.OnMouseDown, function(self, enter)
                    if enter == K.RightButton then
                        edit:SetEnabled(false)
                        edit:SetText(K.EMPTY)
                    else
                        edit:SetFocus()
                    end
                end)
                edit:SetScript(K.OnMouseUp, function(self, enter)
                    if enter == K.RightButton then
                        edit:SetEnabled(true)
                    end
                end)
                edit:SetScript(K.OnEditFocusGained, function(self)
                    mainFrame.lastFocus = self
                end)
                edit:SetScript(K.OnEditFocusLost, function(self)
                    self:ClearHighlightText()
                end)
                frame:SetScript(K.OnMouseDown, edit:GetScript(K.OnMouseDown))
                frame:SetScript(K.OnMouseUp, edit:GetScript(K.OnMouseUp))
            end
            -- 分隔符
            do
                local buttons = {}
                local numOptions = {
                    { key = K.S_4, name = L["回车"], point = { x = K.N_0, y = K.N_0 } },
                    { key = K.S_83, name = L["空格"], point = { x = K.N_55, y = K.N_0 } },
                    { key = K.S_97, name = L["英文逗号"], point = { x = K.N_110, y = K.N_0 } },
                }
                local buttonGroup = CreateFrame(K.Frame, nil, parent)
                buttonGroup:SetPoint(K.BOTTOMLEFT, parent.frame, K.TOPLEFT, K.N_0, 5)
                buttonGroup:SetSize(1, 1)
                for i = 1, #numOptions do
                    local v = numOptions[i]
                    local bt = CreateFrame(K.CheckButton, nil, buttonGroup, K.UIRadioButtonTemplate)
                    bt:SetPoint(K.BOTTOMLEFT, v.point.x, v.point.y)
                    bt:SetSize(K.N_15, K.N_15)
                    tinsert(buttons, bt)
                    bt.Text = bt:CreateFontString()
                    bt.Text:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
                    bt.Text:SetPoint(K.LEFT, bt, K.RIGHT, K.N_0, K.N_0)
                    bt.Text:SetText(v.name)
                    bt.Text:SetTextColor(1, .82, K.N_0)
                    bt:SetHitRectInsets(K.N_0, -bt.Text:GetWidth(), -5, -5)
                    if v.key == BiaoGe.sendMail.split then
                        bt:SetChecked(true)
                        bt.Text:SetTextColor(K.N_0, 1, K.N_0)
                    end
                    bt:SetScript(K.OnClick, function(self)
                        BG.PlaySound(1)
                        for _, radioButton in ipairs(buttons) do
                            if radioButton ~= self then
                                radioButton:SetChecked(false)
                                radioButton.Text:SetTextColor(1, .82, K.N_0)
                            end
                        end
                        self:SetChecked(true)
                        self.Text:SetTextColor(K.N_0, 1, K.N_0)
                        BiaoGe.sendMail.split = v.key
                    end)
                    bt:SetScript(K.OnEnter, function(self)
                        GameTooltip:SetOwner(self, K.ANCHOR_TOPLEFT, K.N_0, K.N_0)
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine(format(L["使用|cffffffff%s|r作为多个名字的分隔符。"], v.name), 1, K.N_0_82, K.N_0, true)
                        GameTooltip:Show()
                    end)
                    bt:SetScript(K.OnLeave, GameTooltip_Hide)
                end
            end
            -- 确认按钮
            do
                local bt = BG.CreateButton(parent)
                bt:SetSize(K.N_90, 25)
                bt:SetPoint(K.BOTTOMLEFT, 5, K.N_24)
                bt:SetText(L["确认"])
                parent.SureButton = bt
                bt:SetScript(K.OnClick, function(self)
                    BG.PlaySound(1)
                    StartImport()
                end)
                bt:SetScript(K.OnEnter, function(self)
                    self.isOnEnter = true
                    local tbl = GetNameTbl()
                    local allCount = #tbl

                    GameTooltip:SetOwner(self, K.ANCHOR_RIGHT, K.N_0, K.N_0)
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(format(L["名字一共|cff00ff00%s|r个"], allCount), 1, 1, 1, true)
                    for i, name in ipairs(tbl) do
                        GameTooltip:AddLine(i .. K.S_104 .. name, 1, .82, K.N_0)
                    end
                    if #tbl > 40 then
                        GameTooltip:AddLine(L["（只会导入前40个名字）"], .5, .5, .5, true)
                    end
                    GameTooltip:Show()
                end)
                bt:SetScript(K.OnLeave, function(self)
                    self.isOnEnter = nil
                    GameTooltip:Hide()
                end)

                local bt = BG.CreateButton(parent)
                bt:SetSize(K.N_90, 25)
                bt:SetPoint(K.BOTTOMRIGHT, -5, K.N_24)
                bt:SetText(L["关闭"])
                bt:SetScript(K.OnClick, function(self)
                    BG.PlaySound(1)
                    parent:Hide()
                end)
            end
            -- 复制团队成员
            do
                local bt = BG.CreateButton(parent)
                bt:SetSize(K.N_20, K.N_20)
                bt:SetPoint(K.TOPRIGHT, -2, -2)
                bt:SetText(K.S_105)
                bt:SetScript(K.OnEnter, function(self)
                    GameTooltip:SetOwner(self, K.ANCHOR_TOPLEFT, K.N_0, K.N_0)
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(L["导入当前团队成员名单"], 1, 1, 1, true)
                    if not IsInRaid(1) then
                        GameTooltip:AddLine(L["你当前没有团队。"], 1, K.N_0, K.N_0, true)
                    end
                    GameTooltip:Show()
                end)
                bt:SetScript(K.OnLeave, GameTooltip_Hide)
                bt:SetScript(K.OnClick, function(self)
                    if IsInRaid(1) then
                        BG.PlaySound(1)
                        local edit = parent.edit
                        local split = BiaoGe.sendMail.split
                        edit:SetText(K.EMPTY)
                        for i, v in ipairs(BG.raidRosterInfo) do
                            if i == #BG.raidRosterInfo then
                                edit:Insert(v.name)
                            else
                                edit:Insert(v.name .. split)
                            end
                        end
                        edit:SetFocus()
                        After(K.N_0, function()
                            local max = select(2, parent.scroll.ScrollBar:GetMinMaxValues())
                            parent.scroll.ScrollBar:SetValue(max)
                        end)
                    end
                end)
            end
        end
    end

    -- 邮寄
    do
        local var, SwitchVar, lastName, oldVarToNewVar
        -- 变量
        do
            var = {
                {
                    key = K.TXT_A,
                    text = L["邮寄金额"],
                    func = function()
                        return tonumber(mainFrame.moneyEdit:GetText()) or K.N_0
                    end,
                    func_color = function()
                        return BG.STC_g1(tonumber(mainFrame.moneyEdit:GetText()) or K.N_0)
                    end,
                },
                {
                    key = K.TXT_B,
                    text = L["邮寄人数"],
                    func = function()
                        return Size(choose)
                    end,
                    func_color = function()
                        return BG.STC_g1(Size(choose))
                    end,
                },
                {
                    key = K.TXT_C,
                    text = L["收件人名字"],
                    func = function()
                        return lastName or L["(收件人名字)"]
                    end,
                    func_color = function()
                        return BG.STC_g1(lastName or L["(收件人名字)"])
                    end,
                },
                {
                    key = K.TXT_D,
                    text = L["发件人名字"],
                    func = function()
                        return player
                    end,
                    func_color = function()
                        return BG.STC_g1(player)
                    end,
                },
                {
                    key = K.TXT_E,
                    text = L["日期和时间"],
                    func = function()
                        return date(K.TXT_Y_M_D_H_M)
                    end,
                    func_color = function()
                        return BG.STC_g1(date(K.TXT_Y_M_D_H_M))
                    end,
                },
            }
            function SwitchVar(text, color)
                local has
                for _, v in ipairs(var) do
                    local yes
                    if color then
                        text, yes = text:gsub(v.key, v.func_color)
                    else
                        text, yes = text:gsub(v.key, v.func)
                    end
                    if yes ~= K.N_0 then
                        has = true
                    end
                end
                return text, has
            end

            function oldVarToNewVar(text)
                return text:gsub(K.S_112, K.TXT_A):gsub(K.S_113, K.TXT_B):gsub(K.S_114, K.TXT_C):gsub(K.S_115, K.TXT_D)
            end

            local bt = CreateFrame(K.Button, nil, mainFrame)
            bt:SetPoint(K.TOPLEFT, MailFrame, K.TOPLEFT, K.N_65, -1)
            bt:SetNormalFontObject(BG.FontGreen15)
            bt:SetDisabledFontObject(BG.FontDis15)
            bt:SetHighlightFontObject(BG.FontWhite15)
            bt:SetText(L["变量"])
            bt:SetSize(bt:GetFontString():GetWidth(), K.N_20)
            mainFrame.varButton = bt
            bt:SetScript(K.OnEnter, function(self)
                GameTooltip:SetOwner(self, K.ANCHOR_BOTTOMRIGHT, K.N_0, K.N_0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
                GameTooltip:AddLine(L["你可以在主题和内容里使用变量，系统会把特定字符自动变为对应的数字或文本。"], 1, K.N_0_82, K.N_0, true)
                GameTooltip:AddLine(L[ [[比如：在主题里输入"工资{A}金"，在邮寄金额里输入"2000"，那么实际发送的主题是"工资2000金"。]] ], 1, K.N_0_82, K.N_0, true)
                GameTooltip:AddLine(K.S_83, 1, 1, 1, true)
                GameTooltip:AddDoubleLine(L["特定字符:"], L["实际效果:"])
                for _, v in ipairs(var) do
                    GameTooltip:AddDoubleLine(v.key, v.text, 1, 1, 1, 1, 1, 1)
                end

                GameTooltip:Show()
            end)
            bt:SetScript(K.OnLeave, GameTooltip_Hide)
        end

        -- 邮寄记录
        do
            local bt = CreateFrame(K.Button, nil, mainFrame)
            bt:SetPoint(K.LEFT, mainFrame.varButton, K.RIGHT, K.N_15, K.N_0)
            bt:SetNormalFontObject(BG.FontGreen15)
            bt:SetDisabledFontObject(BG.FontDis15)
            bt:SetHighlightFontObject(BG.FontWhite15)
            bt:SetText(L["邮寄记录"])
            bt:SetSize(bt:GetFontString():GetWidth(), K.N_20)
            BG.SetTextHighlightTexture(bt)
            bt:SetScript(K.OnClick, function(self)
                BG.PlaySound(1)
                BG.MainFrame:Show()
                BG.ClickTabButton(BG.MailHistoryMainFrameTabNum)
                CloseAllBags()
            end)
        end

        -- 背景
        do
            local f = CreateFrame(K.Frame, nil, mainFrame, K.InsetFrameTemplate)
            f:SetPoint(K.TOPLEFT, mainFrame, K.TOPLEFT, K.N_0, K.N_0)
            f:SetPoint(K.BOTTOMRIGHT, BG.SendMailMemberFrame, K.TOPLEFT, K.N_0, -K.N_210)
            f:SetFrameLevel(mainFrame:GetFrameLevel())
            mainFrame.bg2 = f
            local f = CreateFrame(K.Frame, nil, mainFrame, K.InsetFrameTemplate)
            f:SetPoint(K.TOPLEFT, mainFrame.bg2, K.BOTTOMLEFT, K.N_0, K.N_0)
            f:SetPoint(K.BOTTOMRIGHT, BG.SendMailMemberFrame, K.BOTTOMLEFT, -K.N_0, K.N_0)
            f:SetFrameLevel(mainFrame:GetFrameLevel())
            mainFrame.bg3 = f
        end

        -- 主题
        do
            local t = mainFrame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            t:SetPoint(K.TOPRIGHT, mainFrame, K.TOPLEFT, K.N_60, -K.N_15)
            t:SetTextColor(1, K.N_0_82, K.N_0)
            t:SetText(MAIL_SUBJECT_LABEL)
            t:SetJustifyH(K.RIGHT)
            local text1 = t
            local edit = CreateFrame(K.EditBox, nil, mainFrame,  BG.editTemplate)
            edit:SetSize(K.N_170, K.N_20)
            edit:SetPoint(K.LEFT, text1, K.RIGHT, K.N_10, K.N_0)
            edit:SetAutoFocus(false)
            edit:SetMaxLetters(MAXLETTER1)
            edit:SetText(oldVarToNewVar(BiaoGe.sendMail.title))
            mainFrame.Edit1 = edit
            edit:SetScript(K.OnEditFocusGained, function(self)
                mainFrame.lastFocus = self
            end)
            edit:SetScript(K.OnTextChanged, function(self)
                BiaoGe.sendMail.title = self:GetText()
                UpdateMailFrame()
                if self.isOnEnter then
                    self:GetScript(K.OnEnter)(self)
                end
            end)
            edit:SetScript(K.OnEnterPressed, function(self)
                self:ClearFocus()
            end)
            edit:SetScript(K.OnTabPressed, function(self)
                mainFrame.Edit2:SetFocus()
            end)
            edit:SetScript(K.OnMouseDown, function(self, enter)
                if enter == K.RightButton then
                    edit:SetEnabled(false)
                    edit:SetText(K.EMPTY)
                else
                    edit:SetFocus()
                end
            end)
            edit:SetScript(K.OnMouseUp, function(self, enter)
                if enter == K.RightButton then
                    edit:SetEnabled(true)
                end
            end)
            edit:SetScript(K.OnEnter, function(self)
                self.isOnEnter = true
                local has
                local text = self:GetText()
                text, has = SwitchVar(text, true)
                if has then
                    GameTooltip:SetOwner(self, K.ANCHOR_TOPLEFT, -5, K.N_0)
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(L["实际发送效果："], 1, .82, K.N_0, true)
                    GameTooltip:AddLine(text, 1, 1, 1, true)
                    GameTooltip:Show()
                else
                    GameTooltip:Hide()
                end
            end)
            edit:SetScript(K.OnLeave, function(self)
                self.isOnEnter = nil
                GameTooltip:Hide()
            end)
        end

        -- 邮件内容
        do
            local t = mainFrame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            t:SetPoint(K.TOPRIGHT, mainFrame, K.TOPLEFT, K.N_60, -K.N_45)
            t:SetTextColor(1, K.N_0_82, K.N_0)
            t:SetText(L["内容："])
            t:SetJustifyH(K.RIGHT)
            local text2 = t
            local frame = CreateFrame(K.Frame, nil, mainFrame, K.BackdropTemplate)
            frame:SetBackdrop({
                bgFile = K.TEX_CHATFRAMEBACKGROUND,
                edgeFile = K.TEX_UI_TOOLTIP_BORDER,
                edgeSize = K.N_16,
                insets = { left = 3, right = 3, top = 3, bottom = 3 }
            })
            frame:SetBackdropColor(K.N_0, K.N_0, K.N_0, K.N_0_5)
            frame:SetBackdropBorderColor(1, 1, 1, K.N_0_6)
            frame:SetSize(mainFrame.Edit1:GetWidth() + 8, K.N_150)
            frame:SetPoint(K.TOPLEFT, text2, K.TOPRIGHT, K.N_4, 2)
            local edit = CreateFrame(K.EditBox, nil, frame)
            edit:SetWidth(frame:GetWidth())
            edit:SetAutoFocus(false)
            edit:SetMaxLetters(MAXLETTER2)
            edit:EnableMouse(true)
            edit:SetTextInsets(K.N_0, K.N_10, K.N_0, K.N_0)
            edit:SetMultiLine(true)
            edit:SetFont(BIAOGE_TEXT_FONT, K.N_14, K.OUTLINE)
            edit:SetText(oldVarToNewVar(BiaoGe.sendMail.body))
            mainFrame.Edit2 = edit
            mainFrame.Edit2.frame = frame
            local scroll = CreateFrame(K.ScrollFrame, nil, frame, BG.scrollTemplate)
            scroll:SetWidth(frame:GetWidth() - K.N_10)
            scroll:SetHeight(frame:GetHeight() - K.N_10)
            scroll:SetPoint(K.CENTER)
            BG.CreateSrollBarBackdrop(scroll.ScrollBar)
            BG.HookScrollBarShowOrHide(scroll, true)
            scroll:SetScrollChild(edit)

            edit:SetScript(K.OnEditFocusGained, function(self)
                mainFrame.lastFocus = self
            end)
            edit:SetScript(K.OnEditFocusLost, function(self)
                self:ClearHighlightText()
            end)
            edit:SetScript(K.OnTextChanged, function(self)
                BiaoGe.sendMail.body = self:GetText()
                if self.isOnEnter then
                    self:GetScript(K.OnEnter)(self)
                end
            end)
            edit:SetScript(K.OnEscapePressed, function(self)
                self:ClearFocus()
            end)
            edit:SetScript(K.OnTabPressed, function(self)
                mainFrame.moneyEdit:SetFocus()
            end)
            edit:SetScript(K.OnMouseDown, function(self, enter)
                if enter == K.RightButton then
                    edit:SetEnabled(false)
                    edit:SetText(K.EMPTY)
                else
                    edit:SetFocus()
                end
            end)
            edit:SetScript(K.OnMouseUp, function(self, enter)
                if enter == K.RightButton then
                    edit:SetEnabled(true)
                end
            end)
            edit:SetScript(K.OnEnter, function()
                local self = edit
                self.isOnEnter = true
                local has
                local text = self:GetText()
                text, has = SwitchVar(text, true)
                if has then
                    GameTooltip:SetOwner(self, K.ANCHOR_TOPLEFT, -5, K.N_0)
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(L["实际发送效果："], 1, .82, K.N_0, true)
                    GameTooltip:AddLine(text, 1, 1, 1, true)
                    GameTooltip:Show()
                else
                    GameTooltip:Hide()
                end
            end)
            edit:SetScript(K.OnLeave, function()
                local self = edit
                self.isOnEnter = nil
                GameTooltip:Hide()
            end)
            frame:SetScript(K.OnMouseDown, edit:GetScript(K.OnMouseDown))
            frame:SetScript(K.OnMouseUp, edit:GetScript(K.OnMouseUp))
            frame:SetScript(K.OnEnter, edit:GetScript(K.OnEnter))
            frame:SetScript(K.OnLeave, edit:GetScript(K.OnLeave))
        end

        -- 邮寄人数
        do
            local t = mainFrame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            t:SetPoint(K.TOPRIGHT, mainFrame, K.TOPLEFT, K.N_100, -K.N_230)
            t:SetTextColor(1, K.N_0_82, K.N_0)
            t:SetText(L["邮寄人数："])
            t:SetJustifyH(K.RIGHT)
            local text = t
            local t = mainFrame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            t:SetPoint(K.TOPLEFT, text, K.TOPRIGHT, 5, K.N_0)
            t:SetTextColor(1, K.N_0_82, K.N_0)
            t:SetJustifyH(K.LEFT)
            mainFrame.countText = t
            -- 提示
            local bt = CreateFrame(K.Button, nil, mainFrame)
            bt:SetSize(K.N_28, K.N_28)
            bt:SetPoint(K.LEFT, mainFrame.countText, K.RIGHT, K.N_0, K.N_0)
            bt:Hide()
            mainFrame.tipsButton = bt
            local tex = bt:CreateTexture()
            tex:SetAllPoints()
            tex:SetTexture(K.N_616343)
            bt:SetHighlightTexture(K.N_616343)
            bt:SetScript(K.OnEnter, function(self)
                GameTooltip:SetOwner(self, K.ANCHOR_TOPLEFT, K.N_0, K.N_0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(L["提示："], 1, 1, 1, true)
                GameTooltip:AddLine(L["服务器限制短时间内最多只能给20名不同玩家发送邮件。你当前选择的人数已经超过20人，可能会导致部分玩家邮寄失败。"], 1, K.N_0_82, K.N_0, true)
                GameTooltip:Show()
            end)
            bt:SetScript(K.OnLeave, GameTooltip_Hide)
        end

        -- 邮寄金额
        do
            local t = mainFrame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            t:SetPoint(K.TOPRIGHT, mainFrame, K.TOPLEFT, K.N_100, -K.N_260)
            t:SetTextColor(1, K.N_0_82, K.N_0)
            t:SetText(L["邮寄金额："])
            t:SetJustifyH(K.RIGHT)
            local text = t
            local edit = CreateFrame(K.EditBox, nil, mainFrame,  BG.editTemplate)
            edit:SetSize(K.N_100, K.N_20)
            edit:SetPoint(K.LEFT, text, K.RIGHT, K.N_10, K.N_0)
            edit:SetAutoFocus(false)
            edit:SetNumeric(true)
            mainFrame.moneyEdit = edit
            edit:SetScript(K.OnEditFocusGained, function(self)
                self:HighlightText()
                mainFrame.lastFocus = self
            end)
            edit:SetScript(K.OnTextChanged, function()
                UpdateMailFrame()
                local bt = mainFrame.startButton
                if bt.isOnEnter then
                    bt:GetScript(K.OnEnter)(bt)
                end
                local bt = mainFrame.startButton.disFrame
                if bt.isOnEnter then
                    bt:GetScript(K.OnEnter)(bt)
                end
                local bt = mainFrame.Edit1
                if bt.isOnEnter then
                    bt:GetScript(K.OnEnter)(bt)
                end
                local bt = mainFrame.Edit2
                if bt.isOnEnter then
                    bt:GetScript(K.OnEnter)(bt)
                end
            end)
            BG.SetEditBaseClass(edit)
            local tex = edit:CreateTexture()
            tex:SetPoint(K.LEFT, edit, K.RIGHT, K.N_0, K.N_0)
            tex:SetSize(K.N_16, K.N_16)
            tex:SetTexture([[Interface\MoneyFrame\UI-MoneyIcons]])
            tex:SetTexCoord(K.N_0, .25, K.N_0, 1)
        end

        -- 顶部进度条
        do
            local t = mainFrame:CreateFontString()
            t:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            t:SetPoint(K.LEFT, mainFrame, K.TOPLEFT, K.N_65, K.N_15)
            t:SetTextColor(1, 1, 1)
            t:SetJustifyH(K.LEFT)
            mainFrame.topText = t
        end

        -- 开始批量邮寄
        do
            local updateFrame = CreateFrame(K.Frame)
            local lastSend = {}
            local success = K.N_0
            local addFriend = {}
            local SendTbl = {}

            local bt = BG.CreateButton(mainFrame)
            bt:SetSize(K.N_150, 25)
            bt:SetPoint(K.BOTTOM, mainFrame, K.BOTTOMLEFT, K.N_265 / 2, K.N_24)
            bt.text1 = L["开始批量邮寄"]
            bt.text0 = L["停止"]
            bt:SetText(bt.text1)
            bt:SetFrameLevel(bt:GetParent():GetFrameLevel() + K.N_20)
            mainFrame.startButton = bt
            bt:SetScript(K.OnClick, function(self)
                if self:GetText() == self.text1 then
                    if mainFrame.lastFocus then
                        mainFrame.lastFocus:ClearFocus()
                    end
                    StaticPopup_Show("BiaoGe_SendMail")
                else
                    mainFrame.EndSend()
                    BG.PlaySound(1)
                end
            end)
            bt:SetScript(K.OnEnter, function(self)
                self.isOnEnter = true
                local count = Size(choose)
                local money = (tonumber(mainFrame.moneyEdit:GetText()) or K.N_0) * K.N_10000
                GameTooltip:SetOwner(self, K.ANCHOR_TOP, K.N_0, K.N_0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
                GameTooltip:AddLine(format(L["邮寄人数：%s人"], count), 1, .82, K.N_0)
                GameTooltip:AddLine(format(L["邮寄金额：%s %s"], ToGold(money), goldTex), 1, .82, K.N_0)
                GameTooltip:AddLine(format(L["合计金额：%s %s"], count * ToGold(money), goldTex), 1, .82, K.N_0)
                GameTooltip:Show()
            end)
            bt:SetScript(K.OnLeave, function(self)
                self.isOnEnter = nil
                GameTooltip:Hide()
            end)

            local f = CreateFrame(K.Frame, nil, bt)
            f:SetAllPoints()
            f:Hide()
            f.tooltip = {}
            mainFrame.startButton.disFrame = f
            f:SetScript(K.OnEnter, function(self)
                self.isOnEnter = true
                GameTooltip:SetOwner(self, K.ANCHOR_TOP, K.N_0, K.N_0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(L["错误："], 1, 1, 1, true)
                for i, text in ipairs(self.tooltip) do
                    GameTooltip:AddLine(text, 1, .82, K.N_0, true)
                end
                GameTooltip:Show()
            end)
            f:SetScript(K.OnLeave, function(self)
                self.isOnEnter = nil
                GameTooltip:Hide()
            end)

            function mainFrame.EndSend(type)
                local maxPlayer = mainFrame.topText.count
                After(1, function()
                    if lastSend.fullName and addFriend[lastSend.fullName] then
                        C_FriendList.RemoveFriend(lastSend.name)
                    end
                    wipe(addFriend)
                    wipe(lastSend)
                    mainFrame.isSending = nil
                    mainFrame.disFrame:Hide()
                    mainFrame.startButton:SetText(mainFrame.startButton.text1)
                    local msg
                    if type == K.success then
                        msg = format(L["批量邮寄已完成。\n邮寄人数：%s，成功：%s，失败：%s。"],
                            maxPlayer, success, maxPlayer - success)
                        SendSystemMessage(msg:gsub(K.S_4, K.EMPTY))
                    elseif type == K.noMoney then
                        msg = format(L["|cffff0000身上金币不够，批量邮寄已停止。|r\n邮寄人数：%s，已邮寄：%s，未邮寄：%s。"],
                            maxPlayer, success, maxPlayer - success)
                        SendSystemMessage(msg:gsub(K.S_4, K.EMPTY))
                    else
                        msg = format(L["|cffff0000批量邮寄被终止。|r\n邮寄人数：%s，已邮寄：%s，未邮寄：%s。"],
                            maxPlayer, success, maxPlayer - success)
                        SendSystemMessage(msg:gsub(K.S_4, K.EMPTY))
                    end
                    mainFrame.topText:SetText(msg)
                    for _, bt in ipairs(BG.SendMailMemberFrame.buttons) do
                        if bt.ischoose and bt.name and not bt.tex:GetTexture() then
                            bt.tex:SetTexture(K.TXT_INTERFACE_RAIDFRAME_READ)
                        end
                    end
                    BG.SendMailMemberFrame.cancelChooseButton.Click()
                end)
                updateFrame:SetScript(K.OnUpdate, nil)
            end

            function mainFrame.Send(fullName, name, colorName, money)
                lastSend = { fullName = fullName, name = name, colorName = colorName }
                ClearSendMail()
                SetSendMailMoney(money)
                lastName = BG.GSN(fullName)
                SendMail(lastName, SwitchVar(mainFrame.Edit1:GetText()), SwitchVar(mainFrame.Edit2:GetText()))
                lastName = nil
                if addFriend[fullName] then
                    C_FriendList.RemoveFriend(name)
                end
                updateFrame.elapsed = K.N_0
            end

            StaticPopupDialogs["BiaoGe_SendMail"] = {
                text = L["确定开始批量邮寄？"],
                button1 = L["是"],
                button2 = L["否"],
                OnAccept = function()
                    LibBG.CloseDropDownMenus()
                    if mainFrame.lastFocus then
                        mainFrame.lastFocus:ClearFocus()
                    end
                    if mainFrame.importFrame then
                        mainFrame.importFrame:Hide()
                    end
                    local money = (tonumber(mainFrame.moneyEdit:GetText()) or K.N_0) * K.N_10000
                    wipe(SendTbl)
                    for _, v in pairs(choose) do
                        tinsert(SendTbl, {
                            fullName = v.name,
                            name = v.name,
                            colorName = v.colorName,
                            guid = v.guid,
                            num = v.num,
                        })
                    end
                    sort(SendTbl, function(a, b)
                        return a.num < b.num
                    end)
                    local maxPlayer = #SendTbl
                    mainFrame.topText.count = maxPlayer
                    local topText = mainFrame.topText
                    topText.send = K.N_0
                    wipe(addFriend)
                    wipe(lastSend)
                    success = K.N_0
                    mainFrame.isSending = true
                    mainFrame.disFrame:Show()
                    mainFrame.startButton:SetText(mainFrame.startButton.text0)
                    for i, bt in ipairs(BG.SendMailMemberFrame.buttons) do
                        bt.tex:SetTexture(nil)
                    end

                    local i = 1
                    updateFrame.elapsed = sendStartTime
                    updateFrame:SetScript(K.OnUpdate, function(_, elapsed)
                        if not mainFrame:IsVisible() then
                            mainFrame.EndSend()
                            return
                        end
                        local nowMoney = GetMoney()
                        if i <= maxPlayer then
                            if money + K.N_30 > nowMoney then -- 钱不够了
                                mainFrame.EndSend(K.noMoney)
                                return
                            end
                            updateFrame.elapsed = updateFrame.elapsed + elapsed
                            if updateFrame.elapsed >= sendCD then -- 每x秒邮寄一次
                                local fullName = SendTbl[i].fullName
                                local name = SendTbl[i].name
                                local colorName = SendTbl[i].colorName
                                local isFriend = C_FriendList.GetFriendInfo(name)
                                if isFriend then -- 如果是好友，直接邮寄
                                    mainFrame.Send(fullName, name, colorName, money)
                                    topText.send = topText.send + 1
                                    topText:SetText(format(L["正在批量邮寄：%s/%s"], topText.send, topText.count))
                                    i = i + 1
                                elseif not addFriend[fullName] then -- 不是朋友，先加好友
                                    addFriend[fullName] = true
                                    C_FriendList.AddFriend(fullName)
                                    After(K.N_0, function()
                                        C_FriendList.ShowFriends()
                                    end)
                                elseif updateFrame.elapsed >= sendTimeOutCD then -- 如果超过x秒还没添加为好友，则邮寄下一个玩家
                                    updateFrame.elapsed = sendStartTime
                                    topText.send = topText.send + 1
                                    topText:SetText(format(L["正在批量邮寄：%s/%s"], topText.send, topText.count))
                                    i = i + 1
                                end
                            end
                        else
                            mainFrame.EndSend(K.success)
                            return
                        end
                    end)
                end,
                OnCancel = function()
                end,
                timeout = K.N_0,
                whileDead = true,
                hideOnEscape = true,
            }

            -- 邮寄成功/失败事件
            local f = CreateFrame(K.Frame)
            f:RegisterEvent(K.UI_INFO_MESSAGE)
            f:SetScript(K.OnEvent, function(self, event, _, message)
                if not (mainFrame.isSending and lastSend.colorName) then return end
                local money = (tonumber(mainFrame.moneyEdit:GetText()) or K.N_0) * K.N_10000
                if message == ERR_MAIL_SENT then
                    success = success + 1
                    SendSystemMessage(format(L["已邮寄%s%s金。"], lastSend.colorName, ToGold(money)))
                    for _, bt in ipairs(BG.SendMailMemberFrame.buttons) do
                        if bt.name then
                            if lastSend.fullName == bt.name then
                                bt.tex:SetTexture(K.K_140)
                                break
                            end
                        end
                    end
                end
            end)

            -- 过滤掉「XX已添加为好友」这类系统提示
            local function Filter(self, event, msg, player, l, cs, t, flag, channelId, ...)
                local fullName = msg:match(ERR_FRIEND_ADDED_S:gsub(K.TXT_S, K.S_142)) or
                    msg:match(ERR_FRIEND_ALREADY_S:gsub(K.TXT_S, K.S_142)) or
                    msg:match(ERR_FRIEND_ONLINE_SS:gsub(K.TXT_S, K.S_142):gsub(K.S_143, K.S_144):gsub(K.S_145, K.S_146))
                if fullName then
                    if addFriend[fullName] then
                        return true
                    end
                end
            end
            ChatFrame_AddMessageEventFilter(K.CHAT_MSG_SYSTEM, Filter)
        end

        -- 刷新框架
        function UpdateMailFrame(clearTopText)
            if clearTopText then
                mainFrame.topText:SetText(K.EMPTY)
            end
            if IsRaidMember() and not IsInRaid(1) then
                mainFrame.topText:SetText(BG.STC_r1(L["你当前没有团队。"]))
            end

            if not mainFrame.isSending then
                local count = Size(choose)
                mainFrame.countText:SetText(count .. L["人"])
                if count == K.N_0 or count > K.N_20 then
                    mainFrame.countText:SetTextColor(1, K.N_0, K.N_0)
                else
                    mainFrame.countText:SetTextColor(1, .82, K.N_0)
                end
                mainFrame.tipsButton:SetShown(count > K.N_20)
                local money = (tonumber(mainFrame.moneyEdit:GetText()) or K.N_0) * K.N_10000
                local totalMoney = count * (money + K.N_30)
                local nowMoney = GetMoney()
                if count == K.N_0 or count > K.N_20 or money == K.N_0 or BiaoGe.sendMail.title == K.EMPTY or totalMoney > nowMoney then
                    mainFrame.startButton:Disable()
                    mainFrame.startButton.disFrame:Show()
                    local tbl = mainFrame.startButton.disFrame.tooltip
                    wipe(tbl)
                    if count == K.N_0 then
                        tinsert(tbl, L["请在右边团队框架选择你要邮寄的对象。"])
                    end
                    if count > K.N_20 then
                        tinsert(tbl, L["服务器限制同一账号1小时内最多只能邮寄20人。你可以用当前账号邮寄20人，双开用另一个账号邮寄剩下的人。"])
                    end
                    if money == K.N_0 then
                        tinsert(tbl, L["邮寄金额不能为0。"])
                    elseif totalMoney > nowMoney then
                        tinsert(tbl, format(L["合计邮寄金额%s %s，你的钱不够。"], ToGold(totalMoney), goldTex))
                    end
                    if BiaoGe.sendMail.title == K.EMPTY then
                        tinsert(tbl, L["主题不能为空。"])
                    end
                else
                    mainFrame.startButton:Enable()
                    mainFrame.startButton.disFrame:Hide()
                end
            end
        end
    end

    -- 补贴与工资
    do
        local frame, child, width
        local buttons = {}

        local function CreateUI()
            if mainFrame.gzFrame then return end
            local f = CreateFrame(K.Frame, nil, mainFrame, K.BackdropTemplate)
            f:SetBackdrop({
                bgFile = K.TEX_CHATFRAMEBACKGROUND,
                edgeFile = K.TEX_CHATFRAMEBACKGROUND,
                edgeSize = 1,
            })
            f:SetBackdropColor(K.N_0, K.N_0, K.N_0, K.N_0_8)
            f:SetBackdropBorderColor(K.N_0, K.N_0, K.N_0, 1)
            f:SetPoint(K.TOPLEFT, mainFrame, K.TOPRIGHT, K.N_0, K.N_0)
            f:SetPoint(K.BOTTOMRIGHT, mainFrame, K.BOTTOMRIGHT, K.N_200, K.N_0)
            f:EnableMouse(true)
            f.events = {}
            mainFrame.gzFrame = f

            local text = f:CreateFontString()
            text:SetPoint(K.TOP, K.N_0, -5)
            text:SetFont(BIAOGE_TEXT_FONT, K.N_15, K.OUTLINE)
            text:SetText(L["工资与补贴"])

            local bt = BG.CreateButton(f)
            bt:SetSize(K.N_50, K.N_17)
            bt:SetPoint(K.TOPLEFT, 2, -3)
            bt:SetText(L["刷新"])
            bt:SetScript(K.OnClick, function(self)
                BG.PlaySound(1)
                mainFrame:UpdateGZFrame()
            end)

            frame = CreateFrame(K.Frame, nil, f, K.BackdropTemplate)
            frame:SetPoint(K.TOPLEFT, K.N_2_5, -K.N_22)
            frame:SetPoint(K.BOTTOMRIGHT, -K.N_2_5, K.N_2_5)
            frame:SetBackdrop({
                edgeFile = K.TEX_CHATFRAMEBACKGROUND,
                edgeSize = 1,
            })
            frame:SetBackdropBorderColor(.5, .5, .5, .5)
            frame.scroll = CreateFrame(K.ScrollFrame, nil, frame, BG.scrollTemplate)
            frame.scroll:SetPoint(K.TOPLEFT, 5, -2)
            frame.scroll:SetPoint(K.BOTTOMRIGHT, -5, 5)
            frame.scroll.ScrollBar.scrollStep = nil
            BG.HookScrollBarShowOrHide(frame.scroll, true)
            width = frame.scroll:GetWidth()
            child = CreateFrame(K.Frame, nil, frame.scroll)
            child:SetPoint(K.TOPLEFT)
            child:SetWidth(frame.scroll:GetWidth())
            child:SetHeight(frame.scroll:GetHeight())
            frame.scroll:SetScrollChild(child)
        end

        local function CreateButton(name, money, hasMan)
            local ds
            local f = CreateFrame(K.Frame, nil, child)
            do
                f:SetSize(width, K.N_20)
                if next(buttons) then
                    f:SetPoint(K.TOPLEFT, buttons[#buttons], K.BOTTOMLEFT, K.N_0, -2)
                else
                    f:SetPoint(K.TOPLEFT, K.N_0, K.N_0)
                end
                tinsert(buttons, f)
                f.ds = f:CreateTexture()
                f.ds:SetAllPoints()
                f.ds:SetColorTexture(.5, .5, .5, .3)
                f.ds:Hide()
                ds = f.ds
                f:SetScript(K.OnEnter, function(self)
                    ds:Show()
                end)
                f:SetScript(K.OnLeave, function(self)
                    ds:Hide()
                end)
            end

            local nameFrame = CreateFrame(K.Frame, nil, f)
            do
                nameFrame:SetSize(width * .40, f:GetHeight())
                nameFrame:SetPoint(K.LEFT, K.N_0, K.N_0)
                local t = nameFrame:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, K.N_14, K.OUTLINE)
                t:SetAllPoints()
                t:SetText(name)
                t:SetJustifyH(K.LEFT)
                t:SetWordWrap(false)
                nameFrame:SetScript(K.OnEnter, function(self)
                    if t:IsTruncated() then
                        GameTooltip:SetOwner(self, K.ANCHOR_TOPLEFT, K.N_0, K.N_0)
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine(name, 1, .82, K.N_0, true)
                        GameTooltip:Show()
                    end
                    ds:Show()
                end)
                nameFrame:SetScript(K.OnLeave, function(self)
                    GameTooltip:Hide()
                    ds:Hide()
                end)
            end

            local moneyFrame = CreateFrame(K.Frame, nil, f)
            do
                moneyFrame:SetSize(width * .35, nameFrame:GetHeight())
                moneyFrame:SetPoint(K.LEFT, nameFrame, K.RIGHT, 2, K.N_0)
                local t = moneyFrame:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, K.N_14, K.OUTLINE)
                t:SetAllPoints()
                t:SetText(money)
                t:SetJustifyH(K.LEFT)
                t:SetWordWrap(false)
                moneyFrame:SetScript(K.OnEnter, function(self)
                    if t:IsTruncated() then
                        GameTooltip:SetOwner(self, K.ANCHOR_TOPLEFT, K.N_0, K.N_0)
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine(name, 1, .82, K.N_0, true)
                        GameTooltip:Show()
                    end
                    ds:Show()
                end)
                moneyFrame:SetScript(K.OnLeave, function(self)
                    GameTooltip:Hide()
                    ds:Hide()
                end)
            end

            local bt = BG.CreateButton(f)
            do
                bt:SetSize(width * .25 - 5, nameFrame:GetHeight() - 2)
                bt:SetPoint(K.LEFT, moneyFrame, K.RIGHT, 2, K.N_0)
                bt:SetText(L["应用"])
                bt:RegisterForClicks(K.AnyUp)
                bt:SetScript(K.OnClick, function(self, button)
                    BG.PlaySound(1)
                    local money = money
                    if button == K.RightButton and hasMan then
                        money = hasMan.avg
                    end
                    if money < K.N_0 then
                        UIErrorsFrame:AddMessage(L["金额不能为负数！"], 1, K.N_0, K.N_0)
                    else
                        for _, f in pairs(buttons) do
                            f.ds:Hide()
                        end
                        ds:Show()
                        mainFrame.moneyEdit:SetText(money)
                    end
                end)
                bt:SetScript(K.OnEnter, function(self)
                    ds:Show()
                    if hasMan then
                        GameTooltip:SetOwner(self, K.ANCHOR_RIGHT, K.N_0, K.N_0)
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
                        GameTooltip:AddLine(AddTexture(K.LEFT) .. self:GetText() .. money, 1, .82, K.N_0, true)
                        GameTooltip:AddLine(AddTexture(K.RIGHT) .. self:GetText() .. hasMan.avg, 1, .82, K.N_0, true)
                        GameTooltip:Show()
                    end
                end)
                bt:SetScript(K.OnLeave, function(self)
                    GameTooltip:Hide()
                    ds:Hide()
                end)
            end

            local l = nameFrame:CreateLine()
            l:SetColorTexture(RGB(K.S_152, 1))
            l:SetStartPoint(K.BOTTOMLEFT, K.N_0, K.N_0)
            l:SetEndPoint(K.BOTTOMLEFT, width, K.N_0)
            l:SetThickness(1)
        end

        function mainFrame:UpdateGZFrame()
            CreateUI()
            for _, bt in pairs(buttons) do
                bt:Hide()
            end
            wipe(buttons)
            local FB = BG.FB1
            local Maxb = BG.Maxb
            local money = tonumber(BG.Frame[FB][K.boss .. Maxb[FB] + 2][K.jine .. 5]:GetText()) or K.N_0
            CreateButton(L["单人工资"], money)
            local i = 1
            while BG.Frame[FB][K.boss .. Maxb[FB] + 1][K.zhuangbei .. i] do
                local item = BG.Frame[FB][K.boss .. Maxb[FB] + 1][K.zhuangbei .. i]:GetText()
                local hasMan = BG.Frame[FB][K.boss .. Maxb[FB] + 1][K.zhuangbei .. i].hasMan
                local money = tonumber(BG.Frame[FB][K.boss .. Maxb[FB] + 1][K.jine .. i]:GetText())
                if item ~= K.EMPTY and money and money ~= K.N_0 then
                    CreateButton(item, money, hasMan)
                end
                i = i + 1
            end
        end
    end
end

BG.Init2(RoadSendMail)
