if BG.IsBlackListPlayer then return end
local AddonName, ns = ...

local LibBG         = ns.LibBG
local L             = ns.L

local C = ns.Protocol
local SendGateway = ns.SendGateway
local Size          = ns.Size
local RGB           = ns.RGB
local GetClassRGB   = ns.GetClassRGB
local SetClassCFF   = ns.SetClassCFF
local AddTexture    = ns.AddTexture
local GetItemID     = ns.GetItemID

local Maxb          = ns.Maxb
local HopeMaxn      = ns.HopeMaxn
local HopeMaxb      = ns.HopeMaxb
local HopeMaxi      = ns.HopeMaxi

local player        = BG.playerName
local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded
local LoadAddOn     = LoadAddOn or C_AddOns.LoadAddOn

BG.Init(function()
    BiaoGe.Auction = BiaoGe.Auction or {}
    if BG.verLess2 then
        BiaoGe.Auction.money = BiaoGe.Auction.money or 1
        BiaoGe.Auction.fastMoney = BiaoGe.Auction.fastMoney or { 100, 300, 500, 1000, 2000 }
    elseif BG.IsTitan then
        BG.Once("fastMoney", 251201, function()
            BiaoGe.Auction.money = nil
            BiaoGe.Auction.fastMoney = nil
        end)
        BiaoGe.Auction.money = BiaoGe.Auction.money or 1000
        BiaoGe.Auction.fastMoney = BiaoGe.Auction.fastMoney or { 300, 500, 1000, 2000, 3000 }
        BG.Once('fastMoney', 250528, function()
            BiaoGe.Auction.fastMoney = { 100, 300, 500, 1000, 2000 }
        end)
    elseif BG.IsWLK then
        BiaoGe.Auction.money = BiaoGe.Auction.money or 1000
        BiaoGe.Auction.fastMoney = BiaoGe.Auction.fastMoney or { 1000, 2000, 3000, 5000, 10000 }
    elseif BG.IsMOP then
        BG.Once("fastMoney", 260110, function()
            BiaoGe.Auction.money = nil
            BiaoGe.Auction.fastMoney = nil
        end)
        BiaoGe.Auction.money = BiaoGe.Auction.money or 10000
        BiaoGe.Auction.fastMoney = BiaoGe.Auction.fastMoney or { 10000, 20000, 30000, 50000, 100000 }
    else
        BiaoGe.Auction.money = BiaoGe.Auction.money or 100000
        BiaoGe.Auction.fastMoney = BiaoGe.Auction.fastMoney or { 10000, 50000, 100000, 200000, 500000 }
    end

    local sending = {}
    local sendDone = {}
    local sendingCount = {}
    local notShowSendingText = {}

    local function UpdateGuildFrame(panel)
        if IsInRaid(1) then
            panel:SetWidth(1)
            panel:Hide()
        elseif IsInGuild() then
            local totalMembers, onlineMembers, onlineMobileMembers = GetNumGuildMembers()
            panel.text:SetFormattedText(panel.title2, (Size(panel.table) .. "/" .. onlineMembers))
            panel:SetWidth(panel.text:GetWidth() + 10)
            panel:Show()
        end
    end

    local function UpdateAddonFrame(panel)
        if IsInRaid(1) then
            local tally = 0
            for memberName in pairs(panel.table) do
                memberName = BG.GSN(memberName)
                if BG.raidRosterName[memberName] then
                    tally = tally + 1
                end
            end
            panel.text:SetFormattedText(panel.title2, (tally .. "/" .. GetNumGroupMembers()))
            panel:SetWidth(panel.text:GetWidth() + 10)
            panel:Show()
        else
            wipe(panel.table)
            panel:Hide()
        end
    end
    local function AddGuildRosterTooltipLine(memberName, versionText, classToken, onlineSlot, rowOffset)
        local red, green, blue = GetClassColor(classToken)
        GameTooltip:AddDoubleLine(BG.GSN(memberName), versionText, red, green, blue, 1, 1, 1)
        if versionText == L["无"] then
            local opacity = 0.3
            local textLeft = _G["GameTooltipTextLeft" .. (onlineSlot + rowOffset)]
            if textLeft then
                textLeft:SetAlpha(opacity)
            end
            local textRight = _G["GameTooltipTextRight" .. (onlineSlot + rowOffset)]
            if textRight then
                textRight:SetAlpha(opacity)
            end
        end
    end

    local function Guild_OnEnter(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
        GameTooltip:ClearLines()
        GameTooltip:AddLine(self.title, 0, 1, 0)
        GameTooltip:AddLine(" ")
        local onlineSlot = 0
        for slot = 1, GetNumGuildMembers() do
            local memberName, rankLabel, rankId, itemLevel, classDisplayLabel, zoneName,
            publicComment, officerComment, onlineNow, stateValue, classToken, achievementScore,
            achievementRankValue, onMobile, canSortRoster, reputationStanding, playerGuid = GetGuildRosterInfo(slot)
            if onlineNow then
                memberName = BG.GSN(memberName)
                if onlineSlot > 40 then
                    GameTooltip:AddLine("......")
                    break
                end
                onlineSlot = onlineSlot + 1
                local rowOffset = 2
                local versionText = self.table[memberName] or L["无"]
                AddGuildRosterTooltipLine(memberName, versionText, classToken, onlineSlot, rowOffset)
            end
        end
        GameTooltip:Show()
    end

    local function ResolveMemberVersionText(self, entry, name)
        local versionText = self.table[name]
        local red, green, blue = 1, 1, 1
        if not versionText then
            if entry.online then
                versionText = L["无"]
            else
                versionText = L["未知(离线)"]
            end
            if self.isAuciton then
                if sendDone[name] then
                    versionText = L["接收完毕，但未导入"]
                elseif sending[name] then
                    versionText = L["正在接收拍卖WA"]
                end
            end
        elseif not self.isAuciton then
            local clientVersion = BG.GetVerNum(BG.ver)
            local memberVersion = BG.GetVerNum(versionText)
            if clientVersion > memberVersion then
                red = .6
                green, blue = red, red
            elseif clientVersion < memberVersion then
                red, green, blue = 0, 1, 0
            end
        end
        return versionText, red, green, blue
    end

    local function BuildRaidRoleText(entry, cursorY)
        local roleText = ""
        if entry.rank == 2 then
            roleText = roleText .. AddTexture("interface/groupframe/ui-group-leadericon", cursorY)
        elseif entry.rank == 1 then
            roleText = roleText .. AddTexture("interface/groupframe/ui-group-assistanticon", cursorY)
        end
        if entry.isML then
            roleText = roleText .. AddTexture("interface/groupframe/ui-group-masterlooter", cursorY)
        end
        return roleText
    end

    local function Addon_OnEnter(self, _, tooltip)
        if not self then return end
        if tooltip then
            self.title = L["BGForge版本"] .. "(" .. RAID .. ")"
            self.table = BG.raidBiaoGeVersion
            tooltip:SetOwner(self, "ANCHOR_NONE", 0, 0)
            tooltip:ClearLines()
            if BG.ButtonIsInTop(self) then
                tooltip:SetPoint('TOP', self, 'BOTTOM', 0, -0)
            else
                tooltip:SetPoint('BOTTOM', self, 'TOP', 0, 0)
            end
        else
            tooltip = GameTooltip
            self.isOnEnter = true
            tooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            tooltip:ClearLines()
        end
        local rowOffset = 2
        tooltip:AddLine(self.title, 0, 1, 0)
        --[[         if self.isAuciton then
            tooltip:AddLine(L["需全团安装%s，没安装的人将会看不到拍卖窗口。"]:format(BG.IsRetail and "BGForge插件" or L["拍卖WA"]), 0.5, 0.5, 0.5, true)
            if not BG.IsRetail then
                local text = ""
                if not WeakAurasOptions then
                    text = BG.STC_r1(L["（WA面板尚未初始化）"])
                elseif BG.ButtonRaidAuction.loadProgressNum and BG.ButtonRaidAuction.total then
                    text = BG.STC_y1(format(L["（WA面板正在初始化：%s/%s）"],
                        BG.ButtonRaidAuction.loadProgressNum, BG.ButtonRaidAuction.total))
                else
                    text = BG.STC_g1(L["（WA面板已初始化，可以发送了）"])
                end
                tooltip:AddLine(L["SHIFT+点击：把WA字符串通过密语发送给没有的团员。"] .. text, 1, 1, 1, true)
                line = line + 2
            else
                line = line + 1
            end
        end ]]
        tooltip:AddLine(" ")
        for slot, entry in ipairs(BG.SortRaidRosterInfo()) do
            local name = entry.name
            local versionText, red, green, blue = ResolveMemberVersionText(self, entry, name)
            local roleText = BuildRaidRoleText(entry, nil)
            local colorR, colorG, colorB = GetClassRGB(name)
            tooltip:AddDoubleLine(name .. roleText, versionText, colorR, colorG, colorB, red, green, blue)
            if versionText == L["无"] or versionText == L["未知(离线)"] then
                local opacity = 0.4
                if _G[tooltip:GetName() .. "TextLeft" .. (slot + rowOffset)] then
                    _G[tooltip:GetName() .. "TextLeft" .. (slot + rowOffset)]:SetAlpha(opacity)
                end
                if _G[tooltip:GetName() .. "TextRight" .. (slot + rowOffset)] then
                    _G[tooltip:GetName() .. "TextRight" .. (slot + rowOffset)]:SetAlpha(opacity)
                end
            end
        end
        tooltip:Show()
    end

    local function UpdateOnEnter(self)
        if self and self.isOnEnter then
            self:GetScript("OnEnter")(self)
        end
    end

    local cd
    local function CanSend()
        if IsAddOnLoaded("WeakAuras") then
            if not IsAddOnLoaded("WeakAurasOptions") then
                if not LoadAddOn("WeakAurasOptions") then
                    BG.SendSystemMessage(L["你没有启用WeakAurasOptions插件。"])
                    return
                end
            end
            return true
        else
            BG.SendSystemMessage(L["你没有安装WeakAuras插件。"])
        end
    end
    local function FindAuctionWAButton()
        for slot = 1, 10 do
            local titleLabel = _G["WeakAurasLoadedHeaderButton" .. slot]
            if titleLabel then
                local titleText = _G[titleLabel:GetName() .. "Text"]:GetText()
                if titleText:match("/") then
                    local tbl = { titleLabel:GetParent():GetChildren() }
                    for slot, buttonRef in ipairs(tbl) do
                        if buttonRef.id and WeakAuras.IsAuraLoaded(buttonRef.id) then
                            local versionText = buttonRef.id:match("<BiaoGe>拍卖%s-v(%d+%.%d+)")
                            if versionText then
                                return buttonRef
                            end
                        end
                    end
                    break
                end
            end
        end
    end

    local function StartSend()
        if cd then return end
        local buttonRef = FindAuctionWAButton()
        if not buttonRef then
            BG.SendSystemMessage(L["在你的WA面板里未找到拍卖WA字符串，你需要先从表格左上角的\"拍卖WA\"按钮导入该字符串。"])
            return
        end
        if not IsShiftKeyDown() then
            BG.SendSystemMessage(L["需要按下SHIFT才能发送WA。"])
            return
        end
        cd = true
        BG.After(2, function() cd = nil end)
        BG.PlaySound(2)
        local editBoxRef = ChatEdit_ChooseBoxForSend()
        editBoxRef:SetText("")
        ChatEdit_ActivateChat(editBoxRef)
        buttonRef:Click()
        BG.ButtonRaidAuction.WACode = editBoxRef:GetText()
        editBoxRef:SetText("")
        editBoxRef:Hide()
        GameTooltip:Hide()
        if BG.ButtonRaidAuction.isOnEnter then
            BG.ButtonRaidAuction:GetScript("OnEnter")(BG.ButtonRaidAuction)
        end
        if BG.ButtonRaidAuction.WACode ~= "" then
            for _, entry in ipairs(BG.raidRosterInfo) do
                if not BG.raidAuctionVersion[entry.name] and entry.online then
                    SendGateway.Chat(BG.ButtonRaidAuction.WACode, "WHISPER", nil, entry.name)
                end
            end
        end
    end
    local function SendWACode()
        if not CanSend() then return end
        if not IsShiftKeyDown() then return end
        if not WeakAurasOptions then
            WeakAuras.OpenOptions()
            WeakAurasOptions:Hide()
            BG.ButtonRaidAuction.total = 0
            for _, _ in pairs(WeakAurasSaved.displays) do
                BG.ButtonRaidAuction.total = BG.ButtonRaidAuction.total + 1
            end
            BG.OnUpdateTime(function(self)
                BG.ButtonRaidAuction.loadProgressNum = WeakAurasOptions.loadProgressNum
                if BG.ButtonRaidAuction.isOnEnter then
                    BG.ButtonRaidAuction:GetScript("OnEnter")(BG.ButtonRaidAuction)
                end
                if not WeakAurasOptions.loadProgress:IsShown() then
                    self:SetScript("OnUpdate", nil)
                    self:Hide()
                    BG.ButtonRaidAuction.total = nil
                    BG.ButtonRaidAuction.loadProgressNum = nil
                    if BG.ButtonRaidAuction.isOnEnter then
                        BG.ButtonRaidAuction:GetScript("OnEnter")(BG.ButtonRaidAuction)
                    end
                    BG.After(0, function()
                        StartSend()
                    end)
                end
            end)
        else
            StartSend()
        end
    end

    -- 团长开始拍卖UI
    do
        BiaoGe.Auction.duration = BiaoGe.Auction.duration or 40
        -- 官方已禁用匿名拍卖，因此不再保留可切换的拍卖模式。
        BiaoGe.Auction.mod = "normal"
        BiaoGe.Auction.aotoSendLate = BiaoGe.Auction.aotoSendLate or 3
        if BiaoGe.Auction.gen ~= 1 and BiaoGe.Auction.gen ~= 2 then
            BiaoGe.Auction.gen = 2
        end
        BiaoGe.Auction.resetThreshold = BiaoGe.Auction.resetThreshold or 20

        local gens = {
            [1] = L["第一代拍卖"],
            [2] = L["第二代拍卖"],
        }
        local mainFrameWidth = 250
        local mainFrameHeight = 173
        local maxCount = 10
        local errorMsg = L['错误：同时拍卖的数量不能超过%s个']:format(maxCount)

        -- 拍卖版本属于整张拍卖表，放在主表顶栏统一切换。入口和切换权限仅限团长。
        do
            local PANEL_WIDTH = 304
            local PANEL_HEIGHT = 366
            local SELECT_WIDTH = 126
            local SELECT_HEIGHT = 20
            local SECTION_TITLE_SIZE = 16
            local COLOR_GOLD = { 0.95, 0.63, 0.16 }
            local COLOR_BORDER = { 0.42, 0.28, 0.10 }
            local COLOR_MUTED = { 0.58, 0.56, 0.51 }
            local COLOR_TEXT = { 0.90, 0.88, 0.80 }

            local function IsAuctionVersionLeader()
                return IsInRaid(1) and UnitIsGroupLeader("player")
            end

            local function CreateText(parent, size, color, text)
                local fontString = parent:CreateFontString(nil, "ARTWORK")
                fontString:SetFont(BIAOGE_TEXT_FONT, size, "OUTLINE")
                fontString:SetTextColor(unpack(color))
                fontString:SetText(text)
                fontString:SetJustifyH("LEFT")
                return fontString
            end

            local function CreateDivider(parent, y)
                local line = parent:CreateTexture(nil, "ARTWORK")
                line:SetPoint("TOPLEFT", 14, y)
                line:SetPoint("TOPRIGHT", -14, y)
                line:SetHeight(1)
                line:SetColorTexture(COLOR_BORDER[1], COLOR_BORDER[2], COLOR_BORDER[3], 0.75)
                return line
            end

            local button = CreateFrame("Button", nil, BG.MainFrame, "BackdropTemplate")
            button:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            button:SetBackdropColor(0.025, 0.075, 0.085, 0.98)
            button:SetBackdropBorderColor(COLOR_BORDER[1], COLOR_BORDER[2], COLOR_BORDER[3], 1)
            button:SetSize(SELECT_WIDTH, SELECT_HEIGHT)

            local function LayoutAuctionVersionButton()
                button:ClearAllPoints()
                button:SetPoint(
                    "RIGHT",
                    BG.ButtonMove or BG.MainFrame.CloseButton,
                    "LEFT",
                    -BG.TopLeftButtonJianGe,
                    0
                )
            end
            BG.LayoutAuctionVersionButton = LayoutAuctionVersionButton
            LayoutAuctionVersionButton()

            local text = button:CreateFontString(nil, "ARTWORK")
            text:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
            text:SetTextColor(unpack(COLOR_GOLD))
            text:SetPoint("LEFT", 10, 0)
            text:SetPoint("RIGHT", -25, 0)
            text:SetJustifyH("LEFT")

            local arrow = button:CreateFontString(nil, "ARTWORK")
            arrow:SetFont(BIAOGE_TEXT_FONT, 10, "OUTLINE")
            arrow:SetTextColor(unpack(COLOR_GOLD))
            arrow:SetPoint("RIGHT", -8, 0)
            arrow:SetText("▼")

            local highlight = button:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetPoint("TOPLEFT", 1, -1)
            highlight:SetPoint("BOTTOMRIGHT", -1, 1)
            highlight:SetColorTexture(1, 0.72, 0.25, 0.12)

            local panel = CreateFrame("Frame", nil, BG.MainFrame, "BackdropTemplate")
            panel:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            panel:SetBackdropColor(0.015, 0.055, 0.065, 0.99)
            panel:SetBackdropBorderColor(COLOR_BORDER[1], COLOR_BORDER[2], COLOR_BORDER[3], 1)
            panel:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
            -- 下拉层的右边框始终和顶部选择框的右边框对齐。
            panel:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", 0, -2)
            panel:SetFrameLevel(button:GetFrameLevel() + 20)
            panel:EnableMouse(true)
            panel:Hide()

            local title = CreateText(panel, SECTION_TITLE_SIZE, COLOR_GOLD, L["拍卖版本"])
            title:SetPoint("TOPLEFT", 14, -12)

            local description = CreateText(panel, 12, COLOR_MUTED,
                L["仅团长可见并切换。需要暂停/恢复拍卖等功能时，请选择第二代拍卖"])
            description:SetPoint("TOPLEFT", 14, -35)
            description:SetSize(PANEL_WIDTH - 28, 40)
            description:SetJustifyV("TOP")
            description:SetWordWrap(true)

            CreateDivider(panel, -80)

            local optionRows = {}
            local HidePanel
            local function CreateOptionRow(gen, y)
                local row = CreateFrame("Button", nil, panel)
                row:SetPoint("TOPLEFT", 8, y)
                row:SetPoint("TOPRIGHT", -8, y)
                row:SetHeight(27)

                local selectedBackground = row:CreateTexture(nil, "BACKGROUND")
                selectedBackground:SetAllPoints()
                selectedBackground:SetColorTexture(0.02, 0.25, 0.29, 0.48)

                local selectedBar = row:CreateTexture(nil, "ARTWORK")
                selectedBar:SetPoint("TOPLEFT", 0, 0)
                selectedBar:SetPoint("BOTTOMLEFT", 0, 0)
                selectedBar:SetWidth(3)
                selectedBar:SetColorTexture(unpack(COLOR_GOLD))

                local rowText = CreateText(row, 13, COLOR_TEXT, gens[gen])
                rowText:SetPoint("LEFT", 14, 0)

                local check = row:CreateTexture(nil, "ARTWORK")
                check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
                check:SetSize(22, 22)
                check:SetPoint("RIGHT", -9, 0)

                local rowHighlight = row:CreateTexture(nil, "HIGHLIGHT")
                rowHighlight:SetAllPoints()
                rowHighlight:SetColorTexture(1, 0.72, 0.25, 0.08)

                row:SetScript("OnClick", function()
                    if BG.SetAuctionGen and BG.SetAuctionGen(gen) then
                        HidePanel()
                        BG.PlaySound(1)
                    end
                end)

                optionRows[gen] = {
                    background = selectedBackground,
                    bar = selectedBar,
                    check = check,
                    text = rowText,
                }
            end
            CreateOptionRow(1, -86)
            CreateOptionRow(2, -114)

            CreateDivider(panel, -146)

            local featureTitle = CreateText(panel, SECTION_TITLE_SIZE, COLOR_GOLD, L["第二代拍卖新增"])
            featureTitle:SetPoint("TOPLEFT", 14, -157)

            local featureDot1 = CreateText(panel, 10, COLOR_GOLD, "●")
            featureDot1:SetPoint("TOPLEFT", 16, -181)
            local feature1 = CreateText(panel, 12, COLOR_TEXT, L["暂停 / 恢复拍卖"])
            feature1:SetPoint("LEFT", featureDot1, "RIGHT", 7, 0)

            local featureDot2 = CreateText(panel, 10, COLOR_GOLD, "●")
            featureDot2:SetPoint("TOPLEFT", 16, -204)
            local feature2 = CreateText(panel, 12, COLOR_TEXT, L["自定义出价后的倒计时重置阈值"])
            feature2:SetPoint("LEFT", featureDot2, "RIGHT", 7, 0)

            local featureDetail = CreateText(panel, 11, COLOR_MUTED,
                L["第一代固定 20 秒 · 第二代最低可设 10 秒"])
            featureDetail:SetPoint("TOPLEFT", 35, -224)

            CreateDivider(panel, -246)

            local compatibilityTitle = CreateText(panel, SECTION_TITLE_SIZE, COLOR_GOLD, L["团队兼容检测"])
            compatibilityTitle:SetPoint("TOPLEFT", 14, -257)

            local compatibilityText = CreateText(panel, 12, COLOR_TEXT, "")
            compatibilityText:SetPoint("TOPLEFT", 14, -280)

            local progressBackground = panel:CreateTexture(nil, "BACKGROUND")
            progressBackground:SetPoint("TOPLEFT", 14, -301)
            progressBackground:SetSize(PANEL_WIDTH - 28, 7)
            progressBackground:SetColorTexture(0.10, 0.12, 0.12, 1)

            local progress = CreateFrame("StatusBar", nil, panel)
            progress:SetPoint("TOPLEFT", progressBackground, "TOPLEFT", 1, -1)
            progress:SetPoint("BOTTOMRIGHT", progressBackground, "BOTTOMRIGHT", -1, 1)
            progress:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
            progress:SetStatusBarColor(COLOR_GOLD[1], COLOR_GOLD[2], COLOR_GOLD[3], 0.9)

            local suggestion = CreateText(panel, 11, COLOR_MUTED, L["当有团员不支持时，建议使用第一代拍卖"])
            suggestion:SetPoint("TOPLEFT", 14, -316)

            CreateDivider(panel, -332)

            local footerIcon = panel:CreateTexture(nil, "ARTWORK")
            footerIcon:SetTexture("Interface\\FriendsFrame\\InformationIcon")
            footerIcon:SetDesaturated(true)
            footerIcon:SetVertexColor(0.72, 0.68, 0.58, 1)
            footerIcon:SetSize(16, 16)
            footerIcon:SetPoint("BOTTOMLEFT", 14, 10)
            local footer = CreateText(panel, 11, COLOR_MUTED, L["需团员使用基于 BGLite 的版本"])
            footer:SetPoint("LEFT", footerIcon, "RIGHT", 6, 0)

            local function UpdateSelection()
                text:SetText(gens[BiaoGe.Auction.gen])
                for gen, row in pairs(optionRows) do
                    local selected = gen == BiaoGe.Auction.gen
                    row.background:SetShown(selected)
                    row.bar:SetShown(selected)
                    row.check:SetShown(selected)
                    if selected then
                        row.text:SetTextColor(1, 1, 1)
                    else
                        row.text:SetTextColor(unpack(COLOR_TEXT))
                    end
                end
            end

            local function UpdateCompatibility()
                local supportedNames = {}
                local supported = 0
                local total = IsInRaid(1) and GetNumGroupMembers() or 0
                if total > 0 then
                    local playerName = BG.GSN(BG.playerName)
                    supportedNames[playerName] = true
                    for name in pairs(BG.raidBiaoGeVersion or {}) do
                        name = BG.GSN(name)
                        if BG.raidRosterName and BG.raidRosterName[name]
                            and BG.raidBiaoGeNewVersion and BG.raidBiaoGeNewVersion[name] then
                            supportedNames[name] = true
                        end
                    end
                    for _ in pairs(supportedNames) do
                        supported = supported + 1
                    end
                end
                progress:SetMinMaxValues(0, max(total, 1))
                progress:SetValue(supported)
                if total > 0 and supported >= total then
                    compatibilityText:SetText(format("|cff33ff40%d / %d|r %s",
                        supported, total, L["名团员支持第二代拍卖"]))
                    progress:SetStatusBarColor(0.20, 0.85, 0.25, 0.9)
                else
                    compatibilityText:SetText(format("|cffff4033%d / %d|r %s",
                        supported, total, L["名团员支持第二代拍卖"]))
                    progress:SetStatusBarColor(0.90, 0.18, 0.12, 0.9)
                end
                compatibilityText:SetTextColor(1, 1, 1)
            end

            local fadeIn = panel:CreateAnimationGroup()
            local fadeInAlpha = fadeIn:CreateAnimation("Alpha")
            fadeInAlpha:SetFromAlpha(0)
            fadeInAlpha:SetToAlpha(1)
            fadeInAlpha:SetDuration(0.14)
            fadeInAlpha:SetSmoothing("OUT")
            fadeIn:SetScript("OnFinished", function()
                panel:SetAlpha(1)
            end)

            local fadeOut = panel:CreateAnimationGroup()
            local fadeOutAlpha = fadeOut:CreateAnimation("Alpha")
            fadeOutAlpha:SetFromAlpha(1)
            fadeOutAlpha:SetToAlpha(0)
            fadeOutAlpha:SetDuration(0.11)
            fadeOutAlpha:SetSmoothing("IN")
            fadeOut:SetScript("OnFinished", function()
                if panel.isClosing then
                    panel.isClosing = nil
                    panel:SetAlpha(1)
                    panel:Hide()
                end
            end)

            local function ShowPanel()
                fadeOut:Stop()
                fadeIn:Stop()
                panel.isClosing = nil
                panel:SetAlpha(0)
                panel:Show()
                fadeIn:Play()
            end

            HidePanel = function(immediate)
                fadeIn:Stop()
                fadeOut:Stop()
                if not panel:IsShown() then
                    panel:SetAlpha(1)
                    return
                end
                if immediate then
                    panel.isClosing = nil
                    panel:SetAlpha(1)
                    panel:Hide()
                else
                    panel.isClosing = true
                    fadeOut:Play()
                end
            end

            local function UpdateVisibility()
                if IsAuctionVersionLeader() then
                    button:Show()
                else
                    HidePanel(true)
                    button:Hide()
                end
            end

            function BG.SetAuctionGen(gen)
                if not IsAuctionVersionLeader() or (gen ~= 1 and gen ~= 2) then
                    return false
                end
                BiaoGe.Auction.gen = gen
                UpdateSelection()
                if BG.StartAucitonFrame and BG.StartAucitonFrame.UpdateFrame then
                    BG.StartAucitonFrame:UpdateFrame()
                end
                if BG.UpdateAuctionOptionsGenState then
                    BG.UpdateAuctionOptionsGenState()
                end
                return true
            end

            button:SetScript("OnClick", function()
                if not IsAuctionVersionLeader() then
                    HidePanel(true)
                    button:Hide()
                    return
                end
                UpdateSelection()
                UpdateCompatibility()
                if panel:IsShown() and not panel.isClosing then
                    HidePanel()
                else
                    ShowPanel()
                end
                BG.PlaySound(1)
            end)
            panel:SetScript("OnShow", function()
                if not IsAuctionVersionLeader() then
                    HidePanel(true)
                    return
                end
                arrow:SetText("▲")
                UpdateSelection()
                UpdateCompatibility()
            end)
            panel:SetScript("OnHide", function()
                arrow:SetText("▼")
            end)

            BG.MainFrame:HookScript("OnShow", UpdateVisibility)
            BG.MainFrame:HookScript("OnMouseDown", function()
                HidePanel()
            end)
            BG.MainFrame:HookScript("OnHide", function()
                HidePanel(true)
            end)
            BG.RegisterEvent({ "GROUP_ROSTER_UPDATE", "PARTY_LEADER_CHANGED", "PLAYER_ENTERING_WORLD" }, function()
                BG.After(0.5, function()
                    UpdateVisibility()
                    if panel:IsShown() then
                        UpdateCompatibility()
                    end
                end)
            end)

            BG.ButtonAuctionVersion = button
            BG.AuctionVersionPanel = panel
            BG.RefreshAuctionVersionCompatibility = UpdateCompatibility
            BG.LayoutMainMenuButtons()
            UpdateSelection()
            UpdateVisibility()
        end

        local function ComposeStartAuctionLabel(secondGen, itemId, price, timeout, mode, link, resetFloor)
            if not secondGen then
                return C.PREFIX_AUCTION, format(C.OP_START_AUCTION .. ",%s,%s,%s,%s,,%s,%s",
                    GetTime(), itemId, price, timeout, mode, link)
            end
            return BGA.aura_env.GetAddonChannelName(), format(
                C.OP_START_AUCTION .. "^%s^%s^%s^%s" .. C.SEP_SECTION .. "%s^%s^%s",
                GetTime(), itemId, price, timeout, mode, link, resetFloor)
        end

        function BG.SendStartAuctionMsg(secondGen, itemId, price, timeout, mode, link, resetFloor)
            local channelName, label = ComposeStartAuctionLabel(
                secondGen, itemId, price, timeout, mode, link, resetFloor)
            SendGateway.Addon(channelName, label, "RAID")
        end

        local function OverAuctionMaxCount(slot)
            local innerSlot = 0
            for _, panel in pairs(BGA.Frames) do
                innerSlot = innerSlot + 1
            end
            if slot + innerSlot > maxCount then
                UIErrorsFrame:AddMessage(errorMsg, 1, 0, 0)
                return true
            end
        end

        local function ClearAllFocus(panel)
            local position = 1
            while panel['Edit' .. position] do
                panel['Edit' .. position]:ClearFocus()
                position = position + 1
            end
            LibBG:CloseDropDownMenus()
        end

        local COUNT_STEP_TEX_COORD = { .13, 1 - .13, .13, 1 - .13 }
        local ITEM_ICON_BACKDROP = {
            edgeFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeSize = 1.5,
        }

        local function BuildAuctionEdit(owner, boxWidth, anchor, editType, editNum, initialText, maxLetters)
            local edit = CreateFrame("EditBox", nil, owner, BG.editTemplate)
            edit:SetSize(boxWidth, 20)
            edit:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 3, 0)
            edit._type = editType
            if editNum then
                edit.num = editNum
            end
            edit:SetText(initialText)
            edit:SetAutoFocus(false)
            edit:SetNumeric(true)
            edit:SetMaxLetters(maxLetters)
            return edit
        end

        local function BuildAuctionDropDown(owner, menuWidthValue, anchor, text)
            local dropDown = LibBG:Create_UIDropDownMenu(nil, owner)
            dropDown:SetScale(0.95)
            dropDown:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -17, 2)
            LibBG:UIDropDownMenu_SetText(dropDown, text)
            dropDown.Text:SetJustifyH("LEFT")
            LibBG:UIDropDownMenu_SetWidth(dropDown, menuWidthValue)
            LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "BOTTOM", dropDown, "TOP")
            return dropDown
        end

        local function NewAuctionLabel(owner, boxWidth, point, anchor, relativePoint, x, y, text)
            local label = owner:CreateFontString()
            label:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            label:SetSize(boxWidth, 20)
            label:SetPoint(point, anchor, relativePoint, x, y)
            label:SetJustifyH("LEFT")
            label:SetWordWrap(false)
            label:SetText(text)
            return label
        end

        local function NewAuctionLabelWide(owner, boxWidth, point, anchor, relativePoint, x, y, text)
            local label = owner:CreateFontString()
            label:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            label:SetSize(boxWidth, 20)
            label:SetJustifyH("LEFT")
            label:SetText(text)
            label:SetPoint(point, anchor, relativePoint, x, y)
            return label
        end

        local function BuildCountStepButton(owner, edit, anchor, relativePoint, width, height,
                                            texNormal, texPushed, texDisabled, step)
            local stepButton = CreateFrame("Button", nil, owner)
            stepButton:SetSize(width, height)
            stepButton:SetPoint("RIGHT", anchor, relativePoint, 0, 0)
            stepButton:SetFrameLevel(edit:GetFrameLevel() + 2)
            stepButton:SetNormalTexture(texNormal)
            stepButton:GetNormalTexture():SetTexCoord(unpack(COUNT_STEP_TEX_COORD))
            stepButton:SetPushedTexture(texPushed)
            stepButton:GetPushedTexture():SetTexCoord(unpack(COUNT_STEP_TEX_COORD))
            stepButton:SetDisabledTexture(texDisabled)
            stepButton:GetDisabledTexture():SetTexCoord(unpack(COUNT_STEP_TEX_COORD))
            stepButton:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight")
            stepButton:SetScript("OnClick", function()
                local storedValue = tonumber(edit:GetText()) or 1
                local nextValue = storedValue + step
                if nextValue >= 1 and nextValue <= 9 then
                    edit:SetText(nextValue)
                end
                BG.PlaySound(1)
            end)
            return stepButton
        end

        local function ScheduleAuctionSend(button, isGen2, money, duration, mod, resetThreshold)
            local delay = 0
            local entries = button.items
            local total = #entries
            if total > 1 then
                for slot = 1, total do
                    local entry = entries[slot]
                    local itemID = entry.id
                    local link = entry.link
                    BG.After(delay, function()
                        BG.SendStartAuctionMsg(isGen2, itemID, money, duration, mod, link, resetThreshold)
                    end)
                    delay = delay + 1
                end
                return
            end
            local tally = tonumber(button:GetParent().Edit4:GetText()) or 1
            for slot = 1, tally do
                local itemID = entries[1].id
                local link = entries[1].link
                BG.After(delay, function()
                    BG.SendStartAuctionMsg(isGen2, itemID, money, duration, mod, link, resetThreshold)
                end)
                delay = delay + 1
            end
        end

        local function item_OnEnter(self)
            if BG.ButtonIsInRight(self) then
                GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0)
            else
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
            end
            GameTooltip:ClearLines()
            GameTooltip:SetHyperlink(self.link)
            self.isOnEnter = true
            if self.isIcon then
                self.owner.lastIcon = self
                if not self.isChooseTex then
                    self.isChooseTex = self:CreateTexture()
                    self.isChooseTex:SetAllPoints()
                    self.isChooseTex:SetColorTexture(1, 1, 1, .2)
                    self.isChooseTex:Hide()
                end
                self.isChooseTex:Show()
            end
        end
        local function item_OnLeave(self)
            GameTooltip_Hide()
            self.isOnEnter = nil
            if self.isIcon then
                self.owner.lastIcon = nil
                self.isChooseTex:Hide()
            end
        end
        local function Start_OnClick(self)
            if not self.noSound then
                BG.PlaySound(1)
            end
            local mod = BiaoGe.Auction.mod
            if mod == "roll" then
                if #self.items > 1 then
                    return
                end
                SendGateway.Chat(format(L["{rt1}Roll点开始{rt1} %s"], self.items[1].link), "RAID_WARNING")
            else
                local money = self.money or tonumber(BiaoGe.Auction.money)
                local _duration = tonumber(BiaoGe.Auction.duration)
                local duration = _duration and _duration > 0 and _duration
                if not (money and duration) then return end
                local isGen2 = BiaoGe.Auction.gen == 2
                local resetThreshold = max(tonumber(BiaoGe.Auction.resetThreshold) or 0, 10)
                ScheduleAuctionSend(self, isGen2, money, duration, mod, resetThreshold)
                if self.callback then
                    self.callback()
                end
            end
            self:GetParent():Hide()
        end
        local function resetThreshold_OnEnter(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", -5, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["重置阈值(秒)"], 1, 1, 1, true)
            GameTooltip:AddLine(L["当剩余时间低于此阈值时有人出价，拍卖时间会自动重置回该阈值。"], 1, 0.82, 0, true)
            GameTooltip:AddLine(L["阈值不能低于10秒。"], 1, 0.82, 0, true)
            if BiaoGe.Auction.gen ~= 2 then
                GameTooltip:AddLine(L["仅第二代拍卖可以修改。"], 1, 0, 0, true)
            end
            GameTooltip:Show()
        end
        local function Start_OnEnter(self)
            if BiaoGe.Auction.mod == "roll" and #self.items > 1 then
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
                GameTooltip:AddLine(L["不能同时发起多件装备Roll点。"], 1, 0, 0, true)
                GameTooltip:Show()
            end
        end
        local function OnTextChanged(self)
            BiaoGe.Auction[self._type] = self:GetText()
        end
        local function OnEnterPressed(self)
            if self.num == 1 then
                self:GetParent().Edit2:SetFocus()
            elseif self.num == 2 then
                Start_OnClick(self:GetParent().bt)
            else
                self:ClearFocus()
            end
        end
        local matchStr = ITEM_CLASSES_ALLOWED:gsub("%%s", "")
        function BG.GetTooltipClassText(itemId)
            BG.Tooltip_SetItemByID(itemId)
            for slot = 1, BiaoGeTooltip:NumLines() do
                local str = _G["BiaoGeTooltipTextLeft" .. slot]:GetText()
                if str then
                    local classString = str:match(matchStr .. "(.+)")
                    if classString then
                        local classColor = ""
                        for _, classLabel in ipairs({ strsplit(",", classString) }) do
                            classLabel = classLabel:gsub("^%s+", "")
                            classColor = classColor .. (BG.classColorNames[classLabel] or classLabel) .. "  "
                        end
                        return classColor
                    end
                end
            end
            return ""
        end

        local function UpdateFrame()
            local mainPanel = BG.StartAucitonFrame
            local secondGen = BiaoGe.Auction.gen == 2
            local shade = secondGen and 1 or 0.5
            mainPanel.Edit3:SetEnabled(secondGen)
            mainPanel.Edit3:SetTextColor(shade, shade, shade)
            if secondGen then
                mainPanel.Text5:SetTextColor(1, .82, 0)
            else
                mainPanel.Edit3:SetText(20)
                mainPanel.Text5:SetTextColor(0.5, 0.5, 0.5)
            end
        end

        local function BuildAuctionItemIcons(itemFrame, mainFrame, items)
            local icons = {}
            for slot, entry in ipairs(items) do
                local itemID = entry.id
                local link = entry.link
                local memberName, link, rarity, itemLevel, _, itemCategory, itemSubcategory, _, equipLocation, Texture,
                _, classId, subclassId, bindingKind = GetItemInfo(link)

                -- 图标
                local red, green, blue = GetItemQualityColor(rarity)
                local flashTexture = CreateFrame("Frame", nil, itemFrame, "BackdropTemplate")
                flashTexture:SetBackdrop(ITEM_ICON_BACKDROP)
                flashTexture:SetBackdropBorderColor(red, green, blue, 1)
                if slot == 1 then
                    flashTexture:SetPoint("TOPLEFT", 0, 0)
                else
                    flashTexture:SetPoint("TOPLEFT", icons[slot - 1], "TOPRIGHT", 3, 0)
                end
                flashTexture:SetSize(itemFrame:GetHeight() - 2, itemFrame:GetHeight() - 2)
                flashTexture.itemID = itemID
                flashTexture.link = link
                tinsert(icons, flashTexture)

                flashTexture.isIcon = true
                flashTexture.owner = mainFrame
                flashTexture:SetScript("OnEnter", item_OnEnter)
                flashTexture:SetScript("OnLeave", item_OnLeave)
                flashTexture:SetScript("OnMouseUp", function(self)
                    mainFrame:GetScript("OnMouseUp")(mainFrame)
                end)
                flashTexture:SetScript("OnMouseDown", function(self)
                    mainFrame:GetScript("OnMouseDown")(mainFrame)
                end)

                flashTexture.tex = flashTexture:CreateTexture(nil, "BACKGROUND")
                flashTexture.tex:SetAllPoints()
                flashTexture.tex:SetTexture(Texture)
                flashTexture.tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
                -- 装备等级
                local store = flashTexture:CreateFontString()
                store:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
                store:SetPoint("BOTTOM", flashTexture, "BOTTOM", 0, 1)
                store:SetText(itemLevel)
                store:SetTextColor(red, green, blue)
                -- 装绑
                if bindingKind == 2 then
                    local store = flashTexture:CreateFontString()
                    store:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
                    store:SetPoint("TOP", flashTexture, 0, -2)
                    store:SetText(L["装绑"])
                    store:SetTextColor(0, 1, 0)
                end
            end
            return icons
        end

        local function BuildSingleAuctionItemName(itemFrame, icons, itemId, itemLink,
                                                  equipLocation, classId, itemSubcategory, itemFrameHeight)
            local nameLabel = itemFrame:CreateFontString()
            nameLabel:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            nameLabel:SetPoint("TOPLEFT", icons[1], "TOPRIGHT", 2, -2)
            nameLabel:SetWidth(itemFrame:GetWidth() - itemFrameHeight - 10)
            nameLabel:SetText(itemLink:gsub("%[", ""):gsub("%]", ""))
            nameLabel:SetJustifyH("LEFT")
            nameLabel:SetWordWrap(false)
            -- 装备类型
            local typeLabel = itemFrame:CreateFontString()
            typeLabel:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
            typeLabel:SetPoint("BOTTOMLEFT", icons[1], "BOTTOMRIGHT", 2, 1)
            typeLabel:SetHeight(12)
            typeLabel:SetWidth(nameLabel:GetWidth())
            local classCaption = BG.GetTooltipClassText(itemId) or ""
            if _G[equipLocation] then
                if classId == 2 then
                    typeLabel:SetText(itemSubcategory .. "  " .. classCaption)
                else
                    typeLabel:SetText(_G[equipLocation] .. " " .. itemSubcategory .. "  " .. classCaption)
                end
            else
                typeLabel:SetText(classCaption)
            end
            typeLabel:SetJustifyH("LEFT")
        end

        local function BuildAuctionFastMoneyBar(mainFrame, startOnClick)
            mainFrame.fastMoneyFrame = CreateFrame("Frame", nil, mainFrame)
            local tex = mainFrame.fastMoneyFrame:CreateTexture()
            tex:SetPoint("TOPLEFT", mainFrame, "BOTTOMLEFT", 2, 18)
            tex:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -2, 2)
            tex:SetColorTexture(0.2, 0.2, 0.2, 1)

            local buttons = {}
            local function CreateButton()
                local money = BiaoGe.Auction.fastMoney[#buttons + 1]
                local bt = CreateFrame("Button", nil, mainFrame.fastMoneyFrame)
                bt:SetSize(50, 18)
                if #buttons == 0 then
                    bt:SetPoint("BOTTOMLEFT", mainFrame, 0, 1)
                else
                    bt:SetPoint("BOTTOMLEFT", buttons[#buttons], "BOTTOMRIGHT", 0, 0)
                end
                if BiaoGe.Auction.fastMoney[#buttons + 1] == "" then
                    bt:Hide()
                end
                bt.money = money
                local t = bt:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 10, "OUTLINE")
                t:SetWidth(bt:GetWidth())
                t:SetPoint("CENTER")
                t:SetText(BG.FormatNumber(money, 2))
                t:SetTextColor(1, 0.82, 0)
                t:SetWordWrap(false)
                bt:SetFontString(t)
                tinsert(buttons, bt)
                bt:SetScript("OnClick", function(self)
                    mainFrame.Edit2:SetText(self.money)
                    BiaoGe.Auction.money = self.money
                    startOnClick(mainFrame.bt)
                end)
                bt:SetScript("OnEnter", function(self)
                    t:SetTextColor(1, 1, 1)
                    if t:GetStringWidth() > bt:GetWidth() then
                        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine(t:GetText(), 1, 0.82, 0, true)
                        GameTooltip:Show()
                    end
                end)
                bt:SetScript("OnLeave", function(self)
                    t:SetTextColor(1, .82, 0)
                    GameTooltip:Hide()
                end)
            end
            for slot = 1, #BiaoGe.Auction.fastMoney do
                CreateButton()
            end
        end

        function BG.StartAuction(link, bt, unsoldPanel, altReleased, rightClick, noSound, callback)
            if BiaoGe.options["autoAuctionStart"] ~= 1 and not altReleased then return end
            if not link then return end
            if not BG.IsML then return end
            local link = BG.Copy(link)
            local items = {}
            if type(link) == "table" then
                items = link
            else
                items[1] = { id = GetItemID(link), link = link }
            end
            if OverAuctionMaxCount(#items) then return end
            if BG.StartAucitonFrame then BG.StartAucitonFrame:Hide() end
            GameTooltip:Hide()
            local memberName, link, rarity, itemLevel, _, itemCategory, itemSubcategory, _, equipLocation, Texture,
            _, classId, subclassId, bindingKind = GetItemInfo(items[1].link)

            local mainFrame
            local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
            do
                f:SetBackdrop({
                    bgFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeSize = 2,
                })
                f:SetBackdropColor(0.3, 0.3, 0.3, 0.8)
                f:SetBackdropBorderColor(0, 0, 0, 1)
                f:SetSize(mainFrameWidth, mainFrameHeight)
                if bt then
                    if unsoldPanel then
                        f:SetPoint("TOP", bt, "BOTTOM", 10, 0)
                    else
                        f:SetPoint("BOTTOM", bt, "TOP", 0, 0)
                    end
                else
                    local cursorX, cursorY = GetCursorPosition()
                    cursorX, cursorY = cursorX / UIParent:GetEffectiveScale(), cursorY / UIParent:GetEffectiveScale()
                    f:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", cursorX + 10, cursorY + 10)
                end
                f:SetFrameStrata("DIALOG")
                f:SetFrameLevel(300)
                f:SetClampedToScreen(true)
                f:SetToplevel(true)
                f:EnableMouse(true)
                f:SetMovable(true)
                f:SetScript("OnMouseUp", function(self)
                    f:StopMovingOrSizing()
                    f:SetScript("OnUpdate", nil)
                end)
                f:SetScript("OnMouseDown", function(self)
                    f:StartMoving()
                    ClearAllFocus(f)

                    f.time = 0
                    f:SetScript("OnUpdate", function(self, time)
                        f.time = f.time + time
                        if f.time >= 0.2 then
                            f.time = 0
                            if f.itemFrame.isOnEnter then
                                GameTooltip:Hide()
                                f.itemFrame:GetScript("OnEnter")(f.itemFrame)
                            elseif f.lastIcon then
                                GameTooltip:Hide()
                                f.lastIcon:GetScript("OnEnter")(f.lastIcon)
                            end
                        end
                    end)
                end)
                mainFrame = f
                BG.StartAucitonFrame = mainFrame
                f.UpdateFrame = UpdateFrame

                BG.CreateCloseButton(f, 0, 0)
                f.CloseButton:SetSize(35, 35)
                f.CloseButton:SetFrameLevel(f.CloseButton:GetParent():GetFrameLevel() + 50)
            end

            -- 装备显示
            do
                local f = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
                f:SetPoint("TOPLEFT", f:GetParent(), "TOPLEFT", 2, -2)
                f:SetPoint("BOTTOMRIGHT", f:GetParent(), "TOPRIGHT", -2, -35)
                f:SetFrameLevel(f:GetParent():GetFrameLevel() + 10)
                f.itemID = items[1].id
                f.link = items[1].link
                f:SetScript("OnMouseUp", function(self)
                    mainFrame:GetScript("OnMouseUp")(mainFrame)
                end)
                f:SetScript("OnMouseDown", function(self)
                    mainFrame:GetScript("OnMouseDown")(mainFrame)
                end)
                mainFrame.itemFrame = f
                -- 黑色背景
                local scratchText = CreateFrame("StatusBar", nil, f)
                scratchText:SetAllPoints()
                scratchText:SetFrameLevel(scratchText:GetParent():GetFrameLevel() - 5)
                scratchText:SetStatusBarTexture("Interface/ChatFrame/ChatFrameBackground")
                scratchText:SetStatusBarColor(0, 0, 0, 0.8)

                local icons = BuildAuctionItemIcons(f, mainFrame, items)
                if #items == 1 then
                    BuildSingleAuctionItemName(f, icons, items[1].id, link, equipLocation, classId, itemSubcategory, f:GetHeight())
                end
            end

            local extent = 90
            local textWidth = extent + 12
            -- 拍卖时长、起拍价
            do
                local store = NewAuctionLabel(mainFrame, textWidth, "TOPLEFT", mainFrame.itemFrame, "BOTTOMLEFT", 10, -2, L["|cffFFD100拍卖时长(秒)"])
                mainFrame.Text3 = store

                local edit = BuildAuctionEdit(mainFrame, textWidth, store, "duration", 1, BiaoGe.Auction.duration, 3)
                edit:SetScript("OnTextChanged", OnTextChanged)
                edit:SetScript("OnEnterPressed", OnEnterPressed)
                mainFrame.Edit1 = edit

                local store = NewAuctionLabel(mainFrame, textWidth, "TOPLEFT", mainFrame.Text3, "BOTTOMLEFT", 0, -20, L["|cffFFD100起拍价|r"])
                mainFrame.Text4 = store

                local edit = BuildAuctionEdit(mainFrame, textWidth, store, "money", 2, BiaoGe.Auction.money, 8)
                edit:SetScript("OnTextChanged", OnTextChanged)
                edit:SetScript("OnEnterPressed", OnEnterPressed)
                mainFrame.Edit2 = edit
            end

            -- 重置阈值、拍卖数量
            do
                local store = NewAuctionLabelWide(mainFrame, textWidth, "LEFT", mainFrame.Text3, "RIGHT", 18, 0, L["重置阈值(秒)"])
                mainFrame.Text5 = store
                local thirdInput = BuildAuctionEdit(mainFrame, textWidth, store, "resetThreshold", nil, BiaoGe.Auction.resetThreshold, 3)
                thirdInput:SetScript("OnTextChanged", OnTextChanged)
                thirdInput:SetScript("OnEnterPressed", OnEnterPressed)
                thirdInput:SetScript("OnEnter", resetThreshold_OnEnter)
                thirdInput:SetScript("OnLeave", GameTooltip_Hide)
                mainFrame.Edit3 = thirdInput

                local store = NewAuctionLabel(mainFrame, textWidth, "TOPLEFT", mainFrame.Text5, "BOTTOMLEFT", 0, -20, L["|cffFFD100拍卖数量|r"])
                mainFrame.Text6 = store
                local edit = BuildAuctionEdit(mainFrame, textWidth, store, "count", 3, 1, 1)
                edit:SetScript("OnEnterPressed", OnEnterPressed)
                edit:SetScript("OnMouseWheel", function(self, delta)
                    local storedValue = tonumber(self:GetText()) or 1
                    storedValue = storedValue + delta
                    if storedValue < 1 then storedValue = 1 end
                    if storedValue > 9 then storedValue = 9 end
                    self:SetText(storedValue)
                end)
                mainFrame.Edit4 = edit
                -- 位于右侧的加减按钮，左右各一个
                local widthValue, heightValue = 18, 18
                local downControl = BuildCountStepButton(mainFrame, edit, edit, "RIGHT",
                    widthValue, heightValue,
                    "Interface/ChatFrame/UI-ChatIcon-ScrollDown-Up",
                    "Interface/ChatFrame/UI-ChatIcon-ScrollDown-Down",
                    "Interface/ChatFrame/UI-ChatIcon-ScrollDown-Disabled", -1)
                local upControl = BuildCountStepButton(mainFrame, edit, downControl, "LEFT",
                    widthValue, heightValue,
                    "Interface/ChatFrame/UI-ChatIcon-ScrollUp-Up",
                    "Interface/ChatFrame/UI-ChatIcon-ScrollUp-Down",
                    "Interface/ChatFrame/UI-ChatIcon-ScrollUp-Disabled", 1)
                if #items > 1 then
                    mainFrame.Edit4:SetEnabled(false)
                    mainFrame.Edit4:SetTextColor(0.5, 0.5, 0.5)
                    mainFrame.Text6:SetTextColor(0.5, 0.5, 0.5)
                    upControl:Hide()
                    downControl:Hide()
                end
            end

            -- 开始拍卖
            do
                local bt = BG.CreateButton(mainFrame)
                bt:SetSize(extent + 19, 25)
                bt:SetPoint("TOPLEFT", mainFrame, "BOTTOMLEFT", 10, BiaoGe.options["fastMoney"] == 1 and 50 or 30)
                bt:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -10, BiaoGe.options["fastMoney"] == 1 and 25 or 5)
                bt:SetText(L["开始拍卖"])
                bt.items = items
                bt.noSound = noSound
                bt.callback = callback
                mainFrame.bt = bt
                bt:SetScript("OnClick", Start_OnClick)
                bt:SetScript("OnEnter", Start_OnEnter)
                bt:SetScript("OnLeave", GameTooltip_Hide)
                -- if BiaoGe.Auction.mod ~= "roll" and isRightButton and ns.isYes and ABCD and ABCD.auction then
                --     local _duration = tonumber(BiaoGe.Auction.duration)
                --     local duration = _duration and _duration > 0 and _duration
                --     if duration then
                --         local tbl = {}
                --         for _, FB in pairs(BG.FBtable) do
                --             if FB == BG.FB1 then
                --                 tinsert(tbl, 1, FB)
                --             else
                --                 tinsert(tbl, FB)
                --             end
                --         end
                --         local itemID = BG.GetLeiTingItem(items[1].id)
                --         for _, FB in ipairs(tbl) do
                --             local money = ABCD.auction[FB].money[itemID]
                --             if money then
                --                 bt.money = money
                --                 Start_OnClick(bt)
                --                 break
                --             end
                --         end
                --     end
                -- end
            end

            -- 底部文字
            if BiaoGe.options["fastMoney"] == 1 then
                BuildAuctionFastMoneyBar(mainFrame, Start_OnClick)
            else
                mainFrame:SetHeight(mainFrameHeight - 20)
            end

            UpdateFrame()
        end

        -- ALT点击背包生效
        local function func(self, clickedButton)
            if not IsAltKeyDown() then return end
            local link = C_Container.GetContainerItemLink(self:GetParent():GetID(), self:GetID())
            BG.StartAuction(link, self, nil, nil, clickedButton == "RightButton")
        end
        if BG.IsRetail then
            hooksecurefunc("ContainerFrameItemButton_OnClick", func)
        else
            hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", func)
        end
    end

    -- 插件版本
    do
        BG.guildBiaoGeVersion = {}
        BG.guildClass = {}
        BG.raidBiaoGeVersion = {}
        BG.raidBiaoGeNewVersion = {}
        BG.raidAuctionVersion = {}

        -- 会员插件
        local guild = CreateFrame("Frame", nil, BG.MainFrame)
        do
            guild:SetSize(1, 20)
            guild:SetPoint("BOTTOMLEFT", 10, 2)
            guild:Hide()
            guild.title = L["BGForge版本"] .. "(" .. GUILD .. ")"
            guild.title2 = GUILD .. L["插件：%s"]
            guild.table = BG.guildBiaoGeVersion
            guild.isGuild = true
            guild:SetScript("OnEnter", Guild_OnEnter)
            guild:SetScript("OnLeave", GameTooltip_Hide)
            guild.text = guild:CreateFontString()
            guild.text:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
            guild.text:SetPoint("LEFT")
            guild.text:SetTextColor(RGB(BG.g1))
            BG.ButtonGuildVer = guild
        end

        -- 团员插件
        local addon = CreateFrame("Frame", nil, BG.MainFrame)
        do
            addon:SetSize(1, 20)
            addon:SetPoint("LEFT", BG.ButtonGuildVer, "RIGHT", 0, 0)
            addon:Hide()
            addon.title = L["BGForge版本"] .. "(" .. RAID .. ")"
            addon.title2 = L["插件：%s"]
            addon.table = BG.raidBiaoGeVersion
            addon.isAddon = true
            addon:SetScript("OnEnter", Addon_OnEnter)
            addon:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
                self.isOnEnter = false
            end)
            addon.text = addon:CreateFontString()
            addon.text:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
            addon.text:SetPoint("LEFT")
            addon.text:SetTextColor(RGB(BG.g1))
            BG.ButtonRaidVer = addon
        end

        -- 拍卖WA
        local auction = CreateFrame("Frame", nil, BG.MainFrame)
        do
            auction:SetSize(1, 20)
            auction:SetPoint("LEFT", addon, "RIGHT", 0, 0)
            auction:Hide()
            auction.title = L["自动拍卖版本"]
            auction.title2 = L["拍卖：%s"]
            auction.table = BG.raidAuctionVersion
            auction.isAuciton = true
            auction:SetScript("OnEnter", Addon_OnEnter)
            auction:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
                self.isOnEnter = false
            end)
            --     auction:SetScript("OnMouseUp", function(self)
            --         SendWACode()
            --     end)
            -- end
            auction.text = auction:CreateFontString()
            auction.text:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
            auction.text:SetPoint("LEFT")
            auction.text:SetTextColor(RGB(BG.g1))
            BG.ButtonRaidAuction = auction
        end

        local lastNum = 0
        function BG.CanSend_BiaoGeVer()
            local groupSize
            local sendAllowed = true
            if IsInRaid(1) then
                groupSize = GetNumGroupMembers(1)
                if lastNum >= groupSize then
                    sendAllowed = false
                end
            else
                sendAllowed = false
                groupSize = 0
            end
            lastNum = groupSize
            return sendAllowed
        end

        BG.RegisterEvent("GROUP_ROSTER_UPDATE", function(self, event, ...)
            local canSend = BG.CanSend_BiaoGeVer()
            BG.After(1, function()
                if IsInRaid(1) then
                    if canSend then
                        SendGateway.Addon(C.PREFIX_MAIN, C.OP_MY_VER .. "-" .. BG.ver, "RAID")
                    end
                else
                    UpdateAddonFrame(addon)
                    UpdateAddonFrame(auction)
                end
                if BG.StartAucitonFrame then
                    BG.StartAucitonFrame:UpdateFrame()
                end
                UpdateGuildFrame(guild)
            end)
        end)
        BG.RegisterEvent("GUILD_ROSTER_UPDATE", function(self, event, ...)
            BG.After(1, function()
                for slot = 1, GetNumGuildMembers() do
                    local memberName, rankLabel, rankId, itemLevel, classDisplayLabel, zoneName,
                    publicComment, officerComment, onlineNow, stateValue, classToken, achievementScore,
                    achievementRankValue, onMobile, canSortRoster, reputationStanding, playerGuid = GetGuildRosterInfo(slot)
                    if memberName then
                        memberName = BG.GSN(memberName)
                        if not onlineNow then
                            BG.guildBiaoGeVersion[memberName] = nil
                            BG.guildClass[memberName] = nil
                        else
                            BG.guildClass[memberName] = classToken
                        end
                    end
                end
                UpdateGuildFrame(guild)
            end)
        end)
        BG.RegisterEvent("CHAT_MSG_SYSTEM", function(self, event, ...) -- 如果团队里有人退出，就删掉
            local messageText = ...
            if BG.IsSecret(messageText) then return end
            local leave = ERR_RAID_MEMBER_REMOVED_S:gsub("%%s", "(.+)")
            local memberName = strmatch(messageText, leave)
            if memberName then
                BG.raidBiaoGeVersion[memberName] = nil
                BG.raidBiaoGeNewVersion[memberName] = nil
                BG.raidAuctionVersion[memberName] = nil
                UpdateAddonFrame(addon)
                UpdateAddonFrame(auction)
                if BG.RefreshAuctionVersionCompatibility then
                    BG.RefreshAuctionVersionCompatibility()
                end
            end
        end)
        BG.RegisterEvent("CHAT_MSG_ADDON", function(self, event, ...)
            local prefixText, messageText, distributionType, senderName = ...
            senderName = BG.GSN(senderName)
            if prefixText == C.PREFIX_MAIN and distributionType == "GUILD" then
                if strfind(messageText, C.OP_MY_VER) then
                    local _, version = strsplit("-", messageText)
                    BG.guildBiaoGeVersion[senderName] = version
                    UpdateGuildFrame(guild)
                end
            elseif prefixText == C.PREFIX_MAIN and distributionType == "RAID" then -- 插件版本
                if messageText == C.OP_VERSION_CHECK then
                    SendGateway.Addon(C.PREFIX_MAIN, C.OP_MY_VER .. "-" .. BG.ver, "RAID")
                elseif strfind(messageText, C.OP_MY_VER) then
                    local _, version = strsplit("-", messageText)
                    BG.raidBiaoGeVersion[senderName] = version
                    BG.raidBiaoGeNewVersion[senderName] = BG.GetVerNum(version) >= 20000 and true or nil
                    UpdateAddonFrame(addon)
                    if BG.RefreshAuctionVersionCompatibility then
                        BG.RefreshAuctionVersionCompatibility()
                    end
                    if BG.StartAucitonFrame then
                        BG.StartAucitonFrame:UpdateFrame()
                    end
                end
            elseif prefixText == C.PREFIX_AUCTION and distributionType == "RAID" then -- 拍卖版本
                local firstArgument, version = strsplit(",", messageText)
                if firstArgument == C.OP_MY_VER then
                    BG.raidAuctionVersion[senderName] = version
                    UpdateAddonFrame(auction)
                    if sendDone[senderName] then
                        sendDone[senderName] = nil
                        if not notShowSendingText[senderName] and sendingCount[senderName] <= 2 then
                            BG.SendSystemMessage(format(BG.STC_g1(L["%s已成功导入拍卖WA。"]), SetClassCFF(senderName)))
                        end
                        UpdateOnEnter(BG.ButtonRaidAuction)
                        UpdateOnEnter(BG.StartAucitonFrame)
                    end
                end
            end
        end)
        BG.Init2(function()
            C_Timer.After(3, function()
                if IsInRaid(1) then
                    SendGateway.Addon(C.PREFIX_MAIN, C.OP_VERSION_CHECK, "RAID")
                    SendGateway.Addon(C.PREFIX_AUCTION, C.OP_VERSION_CHECK, "RAID")
                end
            end)
        end)
    end

    -- 移除屏蔽
    local CheckIgnore
    do
        local link = "|cffFFFF00" .. C.ITEM_PROTOCOL .. "BiaoGeIgnore:" .. "|h[" .. L["禁用此功能"] .. "]|h|r"
        local function Send(excludedName)
            BG.SendSystemMessage((format(L["已把%s从屏蔽名单中移除，防止你看不到对方的拍卖聊天信息。"],
                SetClassCFF(excludedName)) .. link))
        end
        function CheckIgnore()
            if BiaoGe.options.ignore ~= 1 then return end
            for slot = 1, C_FriendList.GetNumIgnores() do
                local excludedName = C_FriendList.GetIgnoreName(slot)
                if UnitInRaid(excludedName) then
                    C_FriendList.DelIgnore(excludedName)
                    Send(excludedName)
                end
            end
        end

        local str = ERR_IGNORE_ADDED_S:gsub("%%s", "(.+)")
        BG.RegisterEvent("CHAT_MSG_SYSTEM", function(self, event, messageText)
            if BiaoGe.options.ignore ~= 1 then return end
            if BG.IsSecret(messageText) then return end
            local ignoreName = messageText:match(str)
            if ignoreName and UnitInRaid(ignoreName) then
                C_FriendList.DelIgnore(ignoreName)
                BG.After(0, function()
                    Send(ignoreName)
                end)
            end
        end)

        hooksecurefunc("SetItemRef", function(link, _, clickedButton)
            local firstArgument, secondArgument, thirdArgument, arg4 = strsplit(":", link)
            if secondArgument == "BiaoGeIgnore" then
                local memberName = "ignore"
                BiaoGe.options[memberName] = 0
                BG.options["button" .. memberName]:SetChecked(false)
                BG.SendSystemMessage(L["已禁用自动移除屏蔽对象功能。"])
            end
        end)
    end

    -- 删除aaa插件
    if IsAddOnLoaded("aaa") then
        BG.After(10, function()
            BG.SendSystemMessage(L["请你删除aaa插件，该插件会破坏系统的通讯功能，导致其他插件功能失效。"])
        end)
    end

    -- 为拍卖WA写入关注列表与心愿单
    local LibCustomGlow = LibStub("LibCustomGlow-1.0")
    local function ShowTooltipGlow(frame)
        local initialColor = nil
        LibCustomGlow.PixelGlow_Start(
            frame,      -- 目标帧（必填）
            initialColor, -- 颜色 {r,g,b,a}，默认 {0.95,0.95,0.32,1}
            10,         -- 线条数量 N，默认 8
            0.2,        -- 旋转频率（负数反转方向），默认 0.25
            nil,        -- 线条长度（默认随帧大小/线条数自适应）
            2,          -- 线条厚度，默认 2
            0,          -- X 轴偏移（相对边框）
            0,          -- Y 轴偏移（相对边框）
            true,      -- 是否显示线条下方的边框，默认 false
            nil         -- 发光标识（同一帧可加多个发光，用 key 区分）
        )
        BG.After(.5, function()
            frame:HookScript("OnEnter", function(self)
                LibCustomGlow.PixelGlow_Stop(frame)
            end)
            frame.autoFrame:HookScript("OnEnter", function(self)
                LibCustomGlow.PixelGlow_Stop(frame)
            end)
        end)
    end
    -- 已移除 SetBestPriceAuto：它读取第三方付费模块 BGV 的「最佳价格」并自动填入出价框、
    -- 自动点击出价按钮。该能力依赖付费模块，本插件不做付费模块挂载点，整函数删除。
    local function FindThunderItemID(itemID)
        for _, raidKey in ipairs(BG.GetAllFB()) do
            if BG.GetLeiTingItem(itemID, raidKey) ~= itemID then
                return BG.GetLeiTingItem(itemID, raidKey)
            end
        end
    end

    local function AppendFocusMark(f, itemID)
        for _, raidKey in ipairs(BG.GetAllFB()) do
            for bossSlot = 1, Maxb[raidKey] do
                for slot = 1, BG.GetMaxi(raidKey, bossSlot) do
                    local equipment = BG.Frame[raidKey]["boss" .. bossSlot]["zhuangbei" .. slot]
                    if equipment and itemID == GetItemID(equipment:GetText()) and BiaoGe[raidKey]["boss" .. bossSlot]["guanzhu" .. slot] then
                        local itemCategory = f.itemFrame.itemTypeText
                        itemCategory:SetText((itemCategory:GetText() or "") .. BG.STC_b1(L["<关注>"]))
                        return true
                    end
                end
            end
        end
        return false
    end

    local function AppendWishMark(f, itemID, focused)
        -- Query the local wishlist model even before its UI has been created.
        local hasHope = BG.IsHope(itemID)
        if hasHope then
            local itemCategory = f.itemFrame.itemTypeText
            itemCategory:SetText((itemCategory:GetText() or "") .. (focused and " " or "") .. BG.STC_g1(L["<心愿>"]))
        end
        return hasHope
    end

    function BG.HookCreateAuction(f)
        local itemID = FindThunderItemID(f.itemID) or f.itemID
        local hasGZ = AppendFocusMark(f, itemID)
        local hasHope = AppendWishMark(f, itemID, hasGZ)
        if hasGZ or hasHope then
            BG.After(0.5, function()
                f.autoFrame:Show()
            end)
            ShowTooltipGlow(f)
        end
        if BG.SpecGearFilter then
            BG.SpecGearFilter.ApplyToAuctionFrame(f, hasGZ or hasHope)
        end
        if not f.isPreview then
            tinsert(BG.auctionLogFrame.auctioning, f.itemID)
            BG.UpdateAuctioning()
            CheckIgnore()
        end
    end

    -- 被顶价语音提醒
    local tipTime = 10
    function BG.PlayTopPriceSound(panel, player)
        if BiaoGe.options.autoAuctionAutoEndTips == 1 and panel.remaining and panel.player then
            if panel.remaining <= tipTime and panel.player == BG.playerName
                and player ~= BG.playerName then
                BG.PlaySound("auctionTopPrice")
            end
        end
    end

    -- 拍卖欢呼语
    do
        if BG.IsVanilla then
            BG.autoAuctionHappySay_minMoney = 20000
        elseif BG.IsTBC then
            BG.autoAuctionHappySay_minMoney = 50000
        elseif BG.IsWLK_80 then
            BG.autoAuctionHappySay_minMoney = 100000
        elseif BG.IsTitan then
            BG.autoAuctionHappySay_minMoney = 20000
        elseif BG.IsMOP then
            BG.autoAuctionHappySay_minMoney = 1000000
        elseif BG.IsRetail then
            BG.autoAuctionHappySay_minMoney = 5000000
        else
            BG.autoAuctionHappySay_minMoney = 100000
        end
        if not BG.IsTitan then
            local tbl = {
                [[<%s>这波操作，直接把竞拍场变成了 "金币战场"，敌方全员溃败！]],
                [[天呐！<%s>的金币像 "冰霜新星"一样冻住了所有竞争者！太强了！]],
                [[<%s>出价如 "炎爆术"般炸裂，直接秒杀全场竞拍者！]],
                [[救命！<%s>的金币大军开着 "奥术飞弹"来了，谁顶得住啊！]],
                [[这波出价，堪比 "星辰坠落"！<%s>这是要把装备砸穿地心啊！]],
                [[<%s>一喊价，就像按下了 "群体驱散"，其他出价瞬间消失！]],
                [[别人竞拍靠 "普通攻击"，<%s>竞拍直接 "开大"！这谁受得了！]],
                [[<%s>的金币如 "复活币"般珍贵，这波操作直接让装备 "起死回生"！]],
                [[哇塞！<%s>这波 "闪现"出价，直接把其他玩家甩到外太空！]],
                [[<%s>的金币像 "治疗链"一样疯狂跳，直接把竞拍值抬到天花板！]],
                [[这出价，是要发动 "末日决战"吗？<%s>太强了！]],
                [[<%s>一出手，就像 "圣骑士开无敌"，其他竞拍者完全无法抵抗！]],
                [[救命！<%s>的金币如 "恶魔之怒"般汹涌，直接把竞拍场炸翻！]],
                [[<%s>这波 "影遁"出价，其他玩家根本找不到机会反击！]],
                [[别人出价是 "普通任务"，<%s>出价是 "史诗级成就"！瑞斯拜！]],
                [[<%s>的金币像 "狂暴战"一样疯狂输出，直接把竞拍值打崩！]],
                [[这波操作，堪比 "法师偷取增益"，<%s>直接把装备buff拉满！]],
                [[<%s>一喊价，就像 "猎人开威慑"，其他出价全成了挠痒痒！]],
                [[<%s>的金币如 "盗贼伏击"般突然，直接把竞拍节奏带飞！]],
                [[哇哦！<%s>这波 "牧师渐隐术"出价，其他玩家完全跟不上节奏！]],
                [[这出价，是要发动 "萨满嗜血"吗？<%s>直接让竞拍速度翻倍！]],
                [[<%s>一出手，就像 "术士召唤末日守卫"，其他竞拍者直接吓退！]],
                [[救命！<%s>的金币如 "猎人瞄准射击"般精准，直接命中装备！]],
                [[<%s>这波 "战士冲锋"出价，直接把其他玩家撞出竞拍圈！]],
                [[别人出价是 "小怪巡逻"，<%s>出价是 "BOSS碾压"！太强了！]],
                [[<%s>的金币像 "德鲁伊变熊"一样坚挺，直接把竞拍价稳住！]],
                [[这波操作，堪比 "潜行者偷袭"，<%s>直接把装备偷走啦！]],
                [[<%s>一喊价，就像 "死亡骑士开大军"，其他出价全成了炮灰！]],
                [[<%s>的金币如 "法师暴风雪"般覆盖全场，其他玩家根本无处可逃！]],
                [[哇塞！<%s>这波 "圣骑士制裁"出价，其他竞拍者直接被沉默！]],
                [[这出价，是要发动 "猎人误导"吗？<%s>直接把装备骗到手！]],
                [[<%s>一出手，就像 "萨满开英勇"，其他玩家只能看着干瞪眼！]],
                [[救命！<%s>的金币如 "术士生命虹吸"般疯狂，直接吸干所有竞争者！]],
                [[<%s>这波 "盗贼消失"出价，其他玩家根本反应不过来！]],
                [[别人出价是 "普通攻击"，<%s>出价是 "暴击秒杀"！太狠了！]],
                [[<%s>的金币像 "牧师治疗祷言"一样慷慨，直接把装备价格抬到天际！]],
                [[这波操作，堪比 "法师奥术飞弹连发"，<%s>直接把竞拍值打穿！]],
                [[<%s>一喊价，就像 "战士破甲"，其他玩家的抵抗瞬间瓦解！]],
                [[<%s>的金币如 "德鲁伊回春术"般持续，直接把竞拍热度拉满！]],
                [[哇哦！<%s>这波 "圣骑士奉献"出价，其他竞拍者全被烧死啦！]],
                [[这出价，是要发动 "猎人假死"吗？<%s>直接让其他玩家放弃抵抗！]],
                [[<%s>一出手，就像 "萨满地震术"，其他玩家的出价全被震碎！]],
                [[救命！<%s>的金币如 "术士恐惧术"般可怕，其他玩家直接吓跑！]],
                [[<%s>这波 "盗贼闷棍"出价，其他玩家根本无法反击！]],
                [[别人出价是 "新手村练习"，<%s>出价是 "团本开荒"！太强了！]],
                [[<%s>的金币像 "法师炎爆术"一样高伤害，直接秒杀所有竞争者！]],
                [[这波操作，堪比 "潜行者毁伤"，<%s>直接把装备拆分成碎片！]],
                [[<%s>一喊价，就像 "死亡骑士冰链术"，其他玩家的出价全被冻结！]],
                [[<%s>的金币如 "猎人爆炸射击"般炸裂，直接把竞拍场炸上天！]],
                [[哇塞！<%s>这波 "圣骑士神恩术"出价，其他玩家只能望尘莫及！]],

                [[救命！<%s>这手速和魄力，是吃了“竞拍开挂套餐”吧！太强了！]],
                [[<%s>出价，寸草不生！这波直接把竞拍门槛抬到外太空！]],
                [[家人们快看！大佬<%s>的金币正在组团冲锋，势不可挡！]],
                [[这出价，是要把装备焊在身上的节奏啊！<%s>太狠了！]],
                [[<%s>这波操作，直接让竞拍变成了个人秀场，瑞斯拜！]],
                [[别人出价靠犹豫，<%s>出价靠霸气！膝盖已献上！]],
                [[哇哦！<%s>这一嗓子，整个服务器都在颤抖！]],
                [[竞拍界的“钞能力”天花板出现了！<%s>yyds！]],
                [[<%s>的金币如瀑布般倾泻，这谁顶得住啊！]],
                [[这波出价，直接给竞拍结果盖棺定论！<%s>太会了！]],
                [[救命！<%s>的金币大军已抵达战场，宣告胜利！]],
                [[<%s>一出手，就知有没有！这格局，爱了爱了！]],
                [[别人出价是试水，<%s>出价是海啸！太强了！]],
                [[<%s>这波操作，直接把竞拍玩成了“金币交响乐”！]],
                [[天呐！<%s>的金币正在疯狂上分，无人能敌！]],
                [[<%s>出价，直接“杀疯了”！这装备妥妥是你的！]],
                [[这出价，是要把其他竞拍者“卷”到地心吗？<%s>牛！]],
                [[别人竞拍靠运气，<%s>竞拍靠实力！瑞斯拜！]],
                [[<%s>的金币正在上演“速度与激情”，太刺激了！]],
                [[哇塞！<%s>这气势，直接把竞拍现场变成了“土豪专属区”！]],
                [[救命！<%s>这波操作，直接让竞拍进入“碾压局”！]],
                [[<%s>一喊价，空气都凝固了！这威慑力绝了！]],
                [[别人出价是小打小闹，<%s>出价是惊天动地！]],
                [[<%s>的金币如火箭般发射，这谁能拦得住！]],
                [[这波出价，直接给装备贴上了“<%s>专属”标签！]],
                [[天呐！<%s>的金币正在疯狂刷屏，太壕了！]],
                [[<%s>出价，直接“封神”！这操作太秀了！]],
                [[别人竞拍是过家家，<%s>竞拍是打BOSS！太强了！]],
                [[<%s>的金币正在谱写“竞拍传奇”，太牛了！]],
                [[哇哦！<%s>这一出手，直接把竞拍变成了“降维打击”！]],
                [[救命！<%s>的金币大军已势不可挡，宣告胜利！]],
                [[<%s>一喊价，全场都沸腾了！这魅力谁能抗拒！]],
                [[别人出价是毛毛雨，<%s>出价是倾盆大雨！]],
                [[<%s>的金币正在上演“王者归来”，太霸气了！]],
                [[这波出价，直接把装备“拿捏”得死死的！<%s>牛！]],
                [[天呐！<%s>的金币正在疯狂输出，太猛了！]],
                [[<%s>出价，直接“炸场”！这操作太顶了！]],
                [[别人竞拍是青铜，<%s>竞拍是王者！瑞斯拜！]],
                [[<%s>的金币正在书写“竞拍神话”，太厉害了！]],
                [[哇塞！<%s>这气势，直接把竞拍现场变成了“个人演唱会”！]],
                [[救命！<%s>这波操作，直接让竞拍进入“无敌模式”！]],
                [[<%s>一喊价，世界都安静了！这实力太震撼了！]],
                [[别人出价是小浪花，<%s>出价是惊涛骇浪！]],
                [[<%s>的金币正在发起“总攻”，胜利在望！]],
                [[这波出价，直接给装备插上了“<%s>的翅膀”！]],
                [[天呐！<%s>的金币正在疯狂收割，太绝了！]],
                [[<%s>出价，直接“起飞”！这操作太帅了！]],
                [[别人竞拍是新手村，<%s>竞拍是终极大本营！太强了！]],
                [[<%s>的金币正在创造“竞拍奇迹”，太牛啦！]],
                [[哇哦！<%s>这一出手，直接把竞拍变成了“老板的Show Time”！]],
            }

            BG.RegisterEvent("CHAT_MSG_ADDON", function(self, event, ...)
                if not (BG.IsLeader and BiaoGe.options.autoAuctionHappySay == 1) then return end
                local prefixText, messageText, distributionType, senderName = ...
                local firstArgument, secondArgument, thirdArgument, arg4, arg5, arg6, arg7, arg8, arg9, arg10
                if prefixText == C.PREFIX_AUCTION then
                    firstArgument, secondArgument, thirdArgument, arg4, arg5, arg6, arg7 = strsplit(",", messageText)
                elseif prefixText:match("BiaoGeAuction(%d+)") then
                    firstArgument, secondArgument, thirdArgument, arg4, arg5, arg6, arg7, arg8, arg9, arg10 = strsplit("^", messageText)
                end
                if not firstArgument then return end
                senderName = BG.GSN(senderName)
                if firstArgument == C.OP_SEND_MY_MONEY and distributionType == "RAID" then
                    local auctionID = tonumber(secondArgument)
                    local price = tonumber(thirdArgument)
                    if price and price >= BG.autoAuctionHappySay_minMoney then
                        for _, panel in pairs(_G.BGA.Frames) do
                            if not panel.IsEnd and not panel.isPaused and panel.auctionID == auctionID then
                                if random(10) > 5 then
                                    local label = tbl[random(#tbl)]
                                    if label and senderName then
                                        SendGateway.Chat(format(label, senderName), "RAID")
                                    end
                                end
                                return
                            end
                        end
                    end
                end
            end)
        end
    end

    -- 询问是否为团长拍下的装备记账
    BG.Init2(function()
        local function HasEmptyGeZi(link, raidKey)
            for bossSlot = 1, BG.Maxb[raidKey] do
                for slot = 1, BG.GetMaxi and BG.GetMaxi(raidKey, bossSlot) or BG.Maxi do
                    local equipment = BG.Frame[raidKey]["boss" .. bossSlot]["zhuangbei" .. slot]
                    local buyer = BG.Frame[raidKey]["boss" .. bossSlot]["maijia" .. slot]
                    local amount = BG.Frame[raidKey]["boss" .. bossSlot]["jine" .. slot]

                    if equipment and GetItemID(equipment:GetText()) == GetItemID(link) and
                        buyer:GetText() == "" and amount:GetText() == "" and
                        not BiaoGe[raidKey]["boss" .. bossSlot]["qiankuan" .. slot] then
                        return bossSlot, slot, equipment, buyer, amount, raidKey
                    end
                end
            end
        end
        local function OnClick(equipment, buyer, amount, saveQianKuan, raidKey)
            local bossSlot, position, _, _maijia, _jine = HasEmptyGeZi(equipment, raidKey)
            if bossSlot then
                _maijia:SetText(buyer or "")
                _maijia:SetTextColor(GetClassRGB(nil, "player"))
                _jine:SetText(amount)
                BiaoGe[raidKey]["boss" .. bossSlot]["maijia" .. position] = buyer
                BiaoGe[raidKey]["boss" .. bossSlot]["jine" .. position] = amount
                for fieldKey, entry in pairs(BG.playerClass) do
                    BiaoGe[raidKey]["boss" .. bossSlot][fieldKey .. position] = select(entry.select, entry.func("player"))
                end
                if saveQianKuan then
                    BiaoGe[raidKey]["boss" .. bossSlot]["qiankuan" .. position] = tonumber(amount)
                    BG.Frame[raidKey]["boss" .. bossSlot]["qiankuan" .. position]:Show()
                end
                BG.SendSystemMessage(equipment .. BG.STC_g1(L["记账成功！"]))
            else
                BG.SendSystemMessage(equipment .. BG.STC_r1(L["记账失败！表格里没有匹配到合适的装备！"]))
            end
        end
        local function MoneyIsError(price)
            return price:match("[!@#$%^&*]")
        end

        local frameName = 'BiaoGe_SaveRaidLeaderBuyItem'
        for i = 1, 4 do
            StaticPopupDialogs[frameName .. i] = {
                text = L["你以|cffffff00%s金|r成功竞拍%s，需要记账进表格吗？"],
                button1 = YES,
                button2 = L["记为欠款"],
                button3 = NO,
                OnButton3 = function()
                    StaticPopup_Hide(frameName .. i)
                end,
                selectCallbackByIndex = true,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
        end

        function BG.SaveRLAuction(zhuangbei, maijia, jine, FB)
            if BG.ImMLorLeader() and zhuangbei and maijia and jine and maijia == player then
                for slot = 1, 4 do
                    local _, dialog = StaticPopup_Visible(frameName .. slot)
                    if not dialog then
                        StaticPopupDialogs[frameName .. slot].OnButton1 = function()
                            OnClick(zhuangbei, maijia, jine, nil, FB)
                        end
                        StaticPopupDialogs[frameName .. slot].OnButton2 = function()
                            OnClick(zhuangbei, maijia, jine, true, FB)
                        end
                        StaticPopup_Show(frameName .. slot, jine, zhuangbei)
                        return
                    end
                end
            end
        end

        -- 已移除对第三方付费模块 BGV 状态字段的清理（该挂载点已整体移除）
    end)

    -- 已移除内嵌的竞拍 WeakAuras 导出字符串（原 22593 字节，单行）及其消费者代码块。
    -- 该字符串是第三方 WeakAuras 作者的导出产物，著作权不属于本插件作者，
    -- 随插件分发缺乏授权依据；且一段不可读的长 blob 出现在公开源码里，观感等同混淆。
    -- 三个消费者（WeakAuras.Import / edit:SetText）原本全部位于长注释块内，
    -- 即「活字面量 + 死消费者」，删除不改变任何运行行为。
end)
