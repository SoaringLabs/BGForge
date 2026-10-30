local AddonName, ns = ...

local LibBG = ns.LibBG
local L = ns.L

local Maxb = ns.Maxb
local RGB = ns.RGB

local player = BG.playerName
BG.After = C_Timer.After

------------------四舍五入函数------------------ 入参是数字和保留的小数位数
local function Round(number, decimal_places)
    local mult = 10 ^ (decimal_places or 0)
    return math.floor(number * mult + 0.5) / mult
end
ns.Round = Round

------------------颜色设置函数：把0-1分量拼成16进制色码------------------
local function RGB_16(name, r, g, b)
    if not r then
        r, g, b = name:GetTextColor()
        name = name:GetText()
    end

    local r = string.format("%X", tonumber(r) * 255)
    if r and strlen(r) == 1 then
        r = "0" .. r
    end
    local g = string.format("%X", tonumber(g) * 255)
    if g and strlen(g) == 1 then
        g = "0" .. g
    end
    local b = string.format("%X", tonumber(b) * 255)
    if b and strlen(b) == 1 then
        b = "0" .. b
    end
    local c = r .. g .. b

    if name then
        return "|cff" .. c .. name .. "|r"
    else
        return c
    end
end
ns.RGB_16 = RGB_16

local function SetColorName(name, r, g, b)
    if not (r and g and b) then
        return name
    end
    local r = format("%X", tonumber(r) * 255)
    if r and strlen(r) == 1 then
        r = "0" .. r
    end
    local g = format("%X", tonumber(g) * 255)
    if g and strlen(g) == 1 then
        g = "0" .. g
    end
    local b = format("%X", tonumber(b) * 255)
    if b and strlen(b) == 1 then
        b = "0" .. b
    end
    return "|cff" .. r .. g .. b .. name .. "|r"
end
ns.SetColorName = SetColorName

-- 第几个BOSS
local function BossNum(FB, b, t)
    local tbl = BG.BossNumtbl[FB]
    local bb
    if tbl[t + 1] then
        bb = tbl[t + 1] - tbl[t]
    else
        bb = Maxb[FB] + 2 - tbl[t]
    end
    return b + tbl[t], bb, t, b
end
ns.BossNum = BossNum

function BG.GetBossNumInfo(FB, bossNum)
    local tbl = BG.BossNumtbl[FB]
    for i = 1, #tbl do
        if (not tbl[i + 1]) or (tbl[i] < bossNum and tbl[i + 1] >= bossNum) then
            -- 第几列，第几个
            return i, bossNum - tbl[i]
        end
    end
end

------------------向文本中嵌入材质图标------------------
local TEX_MAP = {
    ["MAINTANK"] = "132064",                                      -- 主坦克
    ["MAINASSIST"] = "132063",                                    -- 主助理
    ["QUEST"] = "Interface\\GossipFrame\\AvailableQuestIcon",     -- 黄色感叹号
    ["BOX"] = format("Interface\\AddOns\\%s\\Media\\icon\\BOX", AddonName),
    ["DD"] = format("Interface\\AddOns\\%s\\Media\\icon\\DD", AddonName),
}
local ICON_MAP = {
    ["TANK"] = "|A:ui-lfg-roleicon-tank:0:0|a",                   -- 坦克职责
    ["HEALER"] = "|A:ui-lfg-roleicon-healer:0:0|a",               -- 治疗职责
    ["DAMAGER"] = "|A:ui-lfg-roleicon-dps:0:0|a",                 -- 输出职责
    ["LEFT"] = "|A:NPE_LeftClick:0:0|a",
    ["RIGHT"] = "|A:NPE_RightClick:0:0|a",
}
local HONOR_TEX = {
    [137000] = true,
    [136998] = true,
}

local function AddTexture(Texture, y, coord, width)
    if not Texture then
        return ""
    end
    local x = 0
    if not y then
        y = "-0"
    end
    local tex = ""
    local coord = coord or ""
    if HONOR_TEX[Texture] then -- 战场荣誉
        coord = ":100:100:10:60:0:55"
        local t = "|T" .. Texture .. ":0:0:0:0" .. coord .. "|t"
        return t
    end
    local icon = ICON_MAP[Texture]
    if icon then
        return icon
    end
    tex = TEX_MAP[Texture] or Texture
    width = width or 0
    return "|T" .. tex .. ":" .. width .. ":" .. width .. ":" .. x .. ":" .. y .. coord .. "|t"
end
ns.AddTexture = AddTexture

function BG.SetButtonAtlas(bt, atlas)
    local tex = bt:CreateTexture()
    tex:SetAllPoints()
    tex:SetAtlas(atlas)
    local tex2 = bt:CreateTexture()
    tex2:SetAllPoints()
    tex2:SetAtlas(atlas)
    bt:SetNormalTexture(tex)
    bt:SetHighlightTexture(tex2)
end

function BG.CreateRoundTexture(tex, parent, w, h)
    local icon = CreateFrame("Frame", nil, parent or UIParent)
    icon:SetPoint("CENTER")
    icon:SetSize(w or 20, h or 20)

    icon.tex = icon:CreateTexture(nil, "ARTWORK")
    icon.tex:SetAllPoints()
    icon.tex:SetTexture(tex)
    icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    icon.masktex = icon:CreateMaskTexture()
    icon.masktex:SetAllPoints()
    icon.masktex:SetTexture("Interface/CharacterFrame/TempPortraitAlphaMaskSmall")

    icon.tex:AddMaskTexture(icon.masktex)
    return icon
end

------------------取出纯文字内容，并去掉材质标记------------------
local function GetText_T(bt)
    local text
    if type(bt) == "table" then
        text = bt:GetText()
    else
        text = bt
    end
    local t = text:gsub("|T.-|t", ""):gsub("|A.-|a", "")
    return t
end
ns.GetText_T = GetText_T

------------------函数：取得名字所属职业的颜色RGB值------------------
local function GetClassRGB(name, player, Alpha)
    local _, class
    if player then
        _, class = UnitClass(player)
    else
        _, class = UnitClass(BG.GSN(name))
    end
    local c1, c2, c3 = 1, 1, 1
    if class then
        c1, c2, c3 = GetClassColor(class)
    end
    return c1, c2, c3, Alpha
end
ns.GetClassRGB = GetClassRGB

------------------函数：把名字套成职业色CFF片段（形如|cffFFFFFF名字|r）------------------
local function SetClassCFF(name, player, type)
    if type then return name end
    local _, class
    if player then
        _, class = UnitClass(player)
    else
        _, class = UnitClass(BG.GSN(name))
    end
    if class then
        local color = select(4, GetClassColor(class))
        return "|c" .. color .. name .. "|r"
    else
        return name
    end
end
ns.SetClassCFF = SetClassCFF

------------------函数：只截取链接中的文本部分------------------
local function GetItemID(text)
    if not text then return end
    return tonumber(text:match("item:(%d+):"))
end
ns.GetItemID = GetItemID

------------------让输入框失去焦点------------------
function BG.ClearFocus()
    if BG.lastfocus then
        BG.lastfocus:ClearFocus()
    end
end

------------------函数：隐藏窗口------------------   -- 0：隐藏焦点+全部框架，1：隐藏全部框架
function BG.FrameHide(num)
    if num == 0 then
        if BG.lastfocus then
            BG.lastfocus:ClearFocus()
        end
    end
    if BG.FrameZhuangbeiList then
        BG.FrameZhuangbeiList:Hide()
    end
    if BG.FrameMaijiaList then
        BG.FrameMaijiaList:Hide()
    end
    if BG.FrameJineList then
        BG.FrameJineList:Hide()
    end
    if BG.ButtonAucitonWA and BG.ButtonAucitonWA.frame then
        BG.ButtonAucitonWA.frame:Hide()
    end
    if BG.frameExportHope then
        BG.frameExportHope:Hide()
    end
    if BG.frameImportHope then
        BG.frameImportHope:Hide()
    end
    if BG.auctionLogFrame and BG.auctionLogFrame.changeFrame then
        BG.auctionLogFrame.changeFrame:Hide()
    end
end

------------------表格中已经存在内容的情形------------------
local END_OFFSET = {
    ["onlyboss"] = -2,
}
local RANGE_TYPE = {
    ["autoQingKong"] = true,
}
local FRAME_FIELDS = { "maijia", "jine" }
local BOOK_FIELDS = { "guanzhu", "qiankuan" }

function BG.BiaoGeHavedItem(FB, _type, instanceID)
    local startB = 1
    local endB = Maxb[FB] + 1
    local endOffset = END_OFFSET[_type]
    if endOffset then
        endB = Maxb[FB] + endOffset
    elseif RANGE_TYPE[_type] then
        local range = BG.bossPositionStartEnd[instanceID]
        startB = range[1]
        endB = range[2]
    end
    for b = startB, endB do
        for i = 1, BG.GetMaxi(FB, b) do
            local frameRow = BG.Frame[FB]["boss" .. b]
            if frameRow["zhuangbei" .. i] then
                if b ~= Maxb[FB] + 1 and frameRow["zhuangbei" .. i]:GetText() ~= "" then
                    return true
                end
                for _, field in ipairs(FRAME_FIELDS) do
                    if frameRow[field .. i]:GetText() ~= "" then
                        return true
                    end
                end
                for _, field in ipairs(BOOK_FIELDS) do
                    if BiaoGe[FB]["boss" .. b][field .. i] then
                        return true
                    end
                end
            end
        end
    end
    return false
end

------------------关闭提示框------------------
local function GameTooltip_Hide()
    GameTooltip:Hide()
end
function BG.GameTooltip_Hide(frame)
    frame:SetScript("OnLeave", GameTooltip_Hide)
end

------------------在table中查找或匹配子串------------------
do
    function BG.FindTableString(text, table)
        local num
        for key, value in pairs(table) do
            num = strfind(text, value)
            if num then
                return num
            end
        end
    end

    function BG.MatchTableString(text, table)
        local str
        for key, value in pairs(table) do
            str = strmatch(text, value)
            if str then
                return str
            end
        end
    end
end
------------------给出字符串里每个字符所在的索引------------------
function BG.getCharacterPositions(str)
    local positions = {}
    local position = 1

    while position <= #str do
        local byte = string.byte(str, position)

        if byte >= 0xC0 and byte <= 0xDF then
            -- 针对两字节的UTF-8字符处理
            positions[string.sub(str, position, position + 1)] = position
            position = position + 2
        elseif byte >= 0xE0 and byte <= 0xEF then
            -- 针对三字节的UTF-8字符处理
            positions[string.sub(str, position, position + 2)] = position
            position = position + 3
        elseif byte >= 0xF0 and byte <= 0xF7 then
            -- 针对四字节的UTF-8字符处理
            positions[string.sub(str, position, position + 3)] = position
            position = position + 4
        else
            -- 针对单字节字符以及非法字节处理
            positions[string.sub(str, position, position)] = position
            position = position + 1
        end
    end

    return positions
end

------------------把所有Tab按钮隐藏起来------------------
function BG.HideTab(Buttons, Show)
    for i, v in ipairs(Buttons) do
        v:Hide()
        v:GetParent():SetEnabled(true)
    end
    Show:Show()
    Show:GetParent():SetEnabled(false)
end

------------------计时器------------------
function BG.OnUpdateTime(func)
    local updateFrame = CreateFrame("Frame")
    updateFrame.timeElapsed = 0
    updateFrame:SetScript("OnUpdate", func)
    return updateFrame
end

--[[
BG.OnUpdateTime(function(self,elapsed)
    self.timeElapsed=self.timeElapsed+elapsed
    if self.timeElapsed then
        self:SetScript("OnUpdate",nil)
        self:Hide()
    end
end)
 ]]

------------------设定按钮文字占用的宽度------------------
function BG.SetButtonStringWidth(bt)
    local t = bt:GetFontString()
    t:SetWidth(bt:GetWidth())
    t:SetWordWrap(false)
end

------------------让按钮宽度贴合文字长度------------------
function BG.SetButtonWidthForString(bt)
    local t = bt:GetFontString()
    bt:SetWidth(t:GetWidth())
end

------------------菜单：点击文字同样可以展开菜单------------------
function BG.dropDownToggle(dropDown)
    dropDown:SetScript("OnMouseDown", function(self)
        if dropDown.isDisabled then return end
        LibBG:ToggleDropDownMenu(nil, nil, self)
        BG.PlaySound(1)
    end)
    BG.SkinDropDown(dropDown)
end

------------------判断当前是否国服或亚服------------------
function BG.IsCN()
    if GetCurrentRegionName() == "CN" or GetCurrentRegionName() == "TW" or GetCurrentRegionName() == "KR" then
        return true
    end
end

------------------按键声音------------------
function BG.PlaySound(id)
    if BiaoGe.options['buttonSound'] == 1 and type(id) == "number" then
        if BG["sound" .. id] then
            if id == 2 then
                PlaySoundFile(BG["sound" .. id])
            else
                PlaySound(BG["sound" .. id])
            end
        end
    elseif BiaoGe.options['tipsSound'] == 1 and type(id) == "string" then
        if BG["sound_" .. id .. BiaoGe.options.Sound] then
            if not PlaySoundFile(BG["sound_" .. id .. BiaoGe.options.Sound] .. ".mp3", "Master") then
                if not PlaySoundFile(BG["sound_" .. id .. BiaoGe.options.Sound] .. ".ogg", "Master") then
                    if BG["sound_" .. id .. "AI"] then
                        PlaySoundFile(BG["sound_" .. id .. "AI"] .. ".mp3", "Master")
                        PlaySoundFile(BG["sound_" .. id .. "AI"] .. ".ogg", "Master")
                    end
                end
            end
        end
    end
end

------------------对按钮文字做截断处理------------------
function BG.ButtonTextSetWordWrap(bt)
    local t = bt:GetFontString()
    t:SetWidth(bt:GetWidth())
    t:SetWordWrap(false)
end

------------------设定按钮文字的颜色------------------
function BG.ButtonTextColor(bt, color)
    local t = bt:GetFontString()
    t:SetTextColor(RGB(color))
end

------------------团队标记所用的贴图------------------
local tex = [[Interface\TargetingFrame\UI-RaidTargetingIcons]]
local y = -3
local RaidTargetingIcons = {
    ["xingxing"] = { num = 1, tex = "|T" .. tex .. ":0:0:0:" .. y .. ":100:100:0:25:0:25" .. "|t" },
    ["dabing"] = { num = 2, tex = "|T" .. tex .. ":0:0:0:" .. y .. ":100:100:25:50:0:25" .. "|t" },
    ["ziling"] = { num = 3, tex = "|T" .. tex .. ":0:0:2:" .. y .. ":100:100:55:75:0:25" .. "|t" },
    ["sanjiao"] = { num = 4, tex = "|T" .. tex .. ":0:0:0:" .. y .. ":100:100:75:100:0:25" .. "|t" },
    ["yueliang"] = { num = 5, tex = "|T" .. tex .. ":0:0:0:" .. y .. ":100:100:0:25:25:50" .. "|t" },
    ["fangkuai"] = { num = 6, tex = "|T" .. tex .. ":0:0:0:" .. y .. ":100:100:25:50:25:50" .. "|t" },
    ["chacha"] = { num = 7, tex = "|T" .. tex .. ":0:0:0:" .. y .. ":100:100:50:75:25:50" .. "|t" },
    ["kulou"] = { num = 8, tex = "|T" .. tex .. ":0:0:0:" .. y .. ":100:100:75:100:25:50" .. "|t" },
}
function BG.SetRaidTargetingIcons(type, name)
    if type then
        return "{rt" .. RaidTargetingIcons[name].num .. "}"
    else
        return RaidTargetingIcons[name].tex
    end
end

function BG.GsubRaidTargetingIcons(text)
    for k, v in pairs(RaidTargetingIcons) do
        text = text:gsub("{rt" .. v.num .. "}", v.tex)
    end
    return text
end

----------滚动到最末----------
function BG.SetScrollBottom(scroll, child)
    local offset = child:GetHeight() - scroll:GetHeight()
    if offset > 0 then
        scroll:SetVerticalScroll(offset)
    end
end

----------判断右键菜单是展开还是收起----------
function BG.DropDownListIsVisible(self)
    local _, parent = _G.L_DropDownList1:GetPoint()
    if parent == self and _G.L_DropDownList1:IsVisible() then
        return true
    end
end

----------高亮按钮----------
function BG.SetTextHighlightTexture(bt)
    local tex = bt:CreateTexture()
    tex:SetPoint("TOPLEFT", bt, "TOPLEFT", -8, 0)
    tex:SetPoint("BOTTOMRIGHT", bt, "BOTTOMRIGHT", 8, 0)
    tex:SetTexture("Interface/PaperDollInfoFrame/UI-Character-Tab-Highlight")
    bt:SetHighlightTexture(tex)
end

----------判断光标或按钮是否处于右侧----------
do
    function BG.CursorIsInRight()
        local uiScale = UIParent:GetEffectiveScale()
        if GetCursorPosition() / uiScale > UIParent:GetWidth() * 0.5 then
            return true
        end
    end

    function BG.ButtonIsInRight(self)
        if self:GetCenter() > UIParent:GetWidth() * 0.5 then
            return true
        end
    end

    function BG.ButtonIsInTop(self)
        if self:GetTop() > UIParent:GetHeight() * 0.5 then
            return true
        end
    end
end

----------将秒数换算成小时或分钟----------
function BG.SecondsToTime(second, short)
    local h = floor(second / 3600)
    if h >= 1 then
        return h .. (short and "h" or L["小时"])
    end

    local m = floor(second / 60)
    if m >= 1 then
        return m .. (short and 'm' or L["分钟"])
    end

    local s = floor(second)
    if s then
        return s .. (short and 's' or L["秒"])
    end
end

----------检查某件物品是否早已拥有----------
function BG.GetItemCount(itemIDorLink)
    local itemID = itemIDorLink
    if not tonumber(itemIDorLink) then
        itemID = tonumber(itemIDorLink:match("item:(%d+)"))
    end
    for _, FB in pairs(BG.FBtable) do
        for itemID2 in pairs(BG.Loot[FB].ExchangeItems) do
            if itemID == itemID2 then
                for _, itemID3 in pairs(BG.Loot[FB].ExchangeItems[itemID2]) do
                    local count = GetItemCount(itemID3, true)
                    if count ~= 0 then
                        return count
                    end
                end
            end
        end
    end
    return GetItemCount(itemID, true)
end

function BG.SendSystemMessage(msg)
    SendSystemMessage(BG.STC_b1("<BGForge>") .. " " .. msg)
end

function BG.SetBorderAlpha(self)
    self.Left:SetAlpha(BG.otherEditAlpha)
    self.Right:SetAlpha(BG.otherEditAlpha)
    self.Middle:SetAlpha(BG.otherEditAlpha)
end

local SCALES_EN = {
    [1] = {
        { 1000000, "%.1fm", 1000000 },
        { 1000, "%.1fk", 1000 },
    },
    [3] = {
        { 1000000, "%.1fm", 1000000 },
        { 10000, "%dk", 1000 },
        { 1000, "%.1fk", 1000 },
    },
}
local SCALES_CN = {
    [1] = {
        { 10000, L["%.1f万"], 10000 },
    },
    [3] = {
        { 10000, L["%.1f万"], 10000 },
        { 1000, L["%.1fk"], 1000 },
    },
}

function BG.FormatNumber(num, type)
    if not tonumber(num) or num % 1 ~= 0 then return num end
    num = tonumber(num)
    type = type or 1
    if type == 0 or type == 5 then -- 添加分隔符
        local formatted = tostring(num)
        formatted = formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
        return formatted
    end
    local scales
    if ns.enUS then
        if type == 2 then -- 添加分隔符
            local formatted = tostring(num)
            formatted = formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
            return formatted
        end
        scales = SCALES_EN[type]
    else
        if type == 2 then -- 输出所有小数点
            if num >= 10000 then
                local wanNum = num / 10000
                if num % 10000 == 0 then
                    return format("%d" .. L["万"], wanNum)
                elseif num % 1000 == 0 then
                    return format("%.1f" .. L["万"], wanNum)
                elseif num % 100 == 0 then
                    return format("%.2f" .. L["万"], wanNum)
                elseif num % 10 == 0 then
                    return format("%.3f" .. L["万"], wanNum)
                else
                    return format("%.4f" .. L["万"], wanNum)
                end
            else
                return num
            end
        end
        scales = SCALES_CN[type]
    end
    if scales then
        for _, row in ipairs(scales) do
            local threshold, fmt, divisor = unpack(row)
            if num >= threshold then
                return format(fmt, floor(num / divisor * 10) / 10)
            end
        end
    end
    return num
end

function BG.Copy(table)
    if type(table) == "table" then
        local t = {}
        for k, v in pairs(table) do
            if type(v) == "table" then
                t[k] = BG.Copy(v) -- 递归拷贝子表
            else
                t[k] = v
            end
        end
        return t
    else
        return table
    end
end

local info = {
    "Hope",
    "MeetingHorn",
    "MeetingHornWhisper",
    "FBCD",
    "RaidCD",
    "QuestCD",
    "Money",
    "MONEY",
    "tradeSkillCooldown",
    "PlayerItemsLevel",
    "playerInfo",
    "equip",
    "bag",
    "worldBossCD",
    "roleOverviewNote",
    "buffCD",
    "legendaryCloak",
    "RoleOverviewSort",
    -- "",
}
function BG.DeletePlayerData(realmID, player)
    for _, key in pairs(info) do
        if BiaoGe[key] and BiaoGe[key][realmID] then
            BiaoGe[key][realmID][player] = nil
        end
    end
    -- if ABCD and ABCD.RoleOverviewSort and ABCD.RoleOverviewSort[realmID] then
    --     for i, v in ipairs(ABCD.RoleOverviewSort[realmID]) do
    --         if v.player == player then
    --             tremove(ABCD.RoleOverviewSort[realmID], i)
    --             break
    --         end
    --     end
    -- end
end

--读取副本表中某个字段的值
function BG.GetFBinfo(FB, info)
    for i, v in ipairs(BG.FBtable2) do
        if FB == v.FB then
            if v[info] then
                return v[info]
            elseif info == "shortName" then
                return v.localName
            end
        end
    end
end

function BG.GetSpecID()
    return GetSpecializationInfo(GetSpecialization())
end

function BG.SetSpecIDToLink(link)
    if BG.IsRetail then
        local k = link:match("item:%d+:[%d-:]+")
        local _, s = k:find("item:%d+:%d-:%d-:%d-:%d-:%d-:%d-:%d-:")
        local _, e = k:find("item:%d+:%d-:%d-:%d-:%d-:%d-:%d-:%d-:%d-:%d-:")
        k = k:sub(1, s) .. "80:" .. BG.GetSpecID() .. k:sub(e, #k)
        return link:gsub("item:%d+:[%d-:]+", k)
    else
        return link
    end
end

-- end

local function Get(link)
    local tbl = { strsplit(":", link) }
    tremove(tbl, 1)
    local itemID = tbl[1]
    local bonus = {}
    for i = 13, #tbl do
        tinsert(bonus, tbl[i])
    end
    return itemID, bonus
end
function BG.IsSameItem(link1, link2)
    if BG.IsRetail then
        local itemID1, bonus1 = Get(link1)
        local itemID2, bonus2 = Get(link2)
        if not (itemID1 == itemID2 and #bonus1 == #bonus2) then
            return
        end
        for i = 1, #bonus1 do
            if bonus1[i] ~= bonus2[i] then
                return
            end
        end
        return true
    else
        return GetItemID(link1) == GetItemID(link2)
    end
end

local function GetID(link)
    if type(link) == "number" or tonumber(link) then
        return link
    elseif type(link) == "string" then
        return GetItemID(link)
    elseif type(link) == "table" then
        return GetID(link:GetText())
    end
end
function BG.IsSame(link1, link2)
    return GetID(link1) == GetID(link2)
end

function BG.OnItemLoad(item)
    if type(item) == "number" then
        return Item:CreateFromItemID(item)
    elseif type(item) == "string" then
        return Item:CreateFromItemLink(item)
    end
end

function BG.ClearColorCode(text)
    return text:gsub("|c........", ""):gsub("|r", "")
end

function BG.ClearCode(text)
    return text:gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|cff......", ""):gsub("|r", "")
end

function BG.ValueInTable(tbl, value)
    for k, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
end

function BG.GetNpcID(guid)
    if guid then
        local npcType, _, _, _, _, npcID = strsplit("-", guid)
        return tonumber(npcID) or 0, npcType
    else
        return "", ""
    end
end

function BG.OnEnterDelay(self, func, delay, isHook)
    delay = delay or .4
    local script = isHook and self.HookScript or self.SetScript
    script(self, "OnEnter", function(self)
        self.isOnEnter = true
        if func then
            self.t = 0
            self:SetScript("OnUpdate", function(self, t)
                self.t = self.t + t
                if self.t >= delay then
                    self:SetScript("OnUpdate", nil)
                    func(self)
                end
            end)
        end
    end)
end

function BG.OnLeaveDelay(self, func)
    self:SetScript("OnLeave", function(self)
        self.isOnEnter = false
        self:SetScript("OnUpdate", nil)
        GameTooltip:Hide()
        if func then
            func(self)
        end
    end)
end

function BG.IsMe(realmID, player)
    return realmID == BG.realmID and player == BG.playerName
end

function BG.SetCD(self, time)
    if self.cd then return true end
    self.cd = true
    BG.After(time, function()
        self.cd = nil
    end)
end

function BG.GetNextWeekTime() -- 距离下周四还有多少秒
    local resetDay = 2
    if BG.IsCN() then
        resetDay = 4
    end

    local currentTimestamp = GetServerTime()
    local currentWeekday = date("%w", currentTimestamp)
    local daysToThursday = resetDay - currentWeekday
    local nextThursdayTimestamp

    local today = date("*t", currentTimestamp)
    if daysToThursday == 0 and today.hour < 7 then
        -- 当时间还没到当天早上7点时
        today.hour = 7
        today.min = 0
        today.sec = 0
        nextThursdayTimestamp = time(today)
    else
        -- 若当前已经是周四，就把日期往后加7天
        if daysToThursday <= 0 then
            daysToThursday = daysToThursday + 7
        end
        nextThursdayTimestamp = currentTimestamp + daysToThursday * 86400

        local nextThursdayDateTable = date("*t", nextThursdayTimestamp)
        nextThursdayDateTable.hour = 7
        nextThursdayDateTable.min = 0
        nextThursdayDateTable.sec = 0
        nextThursdayTimestamp = time(nextThursdayDateTable)
    end
    return nextThursdayTimestamp - currentTimestamp, nextThursdayTimestamp
end

function BG.GetNextDayTime() -- 距离明天7点还有多少秒
    local currentTimestamp = GetServerTime()
    local tomorrow7amTimestamp
    local today = date("*t", currentTimestamp)
    -- 当时间还没到当天早上7点时
    if today.hour < 7 then
        today.hour = 7
        today.min = 0
        today.sec = 0
        tomorrow7amTimestamp = time(today)
    else
        -- 算出明天早上7点对应的时间戳
        local tomorrow = date("*t", currentTimestamp + 86400) -- 加上一天的秒数
        tomorrow.hour = 7
        tomorrow.min = 0
        tomorrow.sec = 0
        tomorrow7amTimestamp = time(tomorrow)
    end
    return tomorrow7amTimestamp - currentTimestamp, tomorrow7amTimestamp
end

function BG.Split(delimiter, str)
    local result = {}
    local delimiterLen = string.len(delimiter)
    local startPos = 1                                              -- 每次切割的起始位置
    while true do
        local findPos = string.find(str, delimiter, startPos, true) -- true表示纯文本匹配（不转义）
        if not findPos then
            local part = string.sub(str, startPos)
            table.insert(result, part)
            break
        end
        local part = string.sub(str, startPos, findPos - 1)
        table.insert(result, part)
        startPos = findPos + delimiterLen
    end
    return unpack(result)
end

function BG.SetMixin(f, mixin)
    if type(f) == "table" then
        for k, v in pairs(mixin) do
            if f.HasScript and f:HasScript(k) then
                f:SetScript(k, v)
            else
                f[k] = v
            end
        end
    end
end

function BG.CreateCloseButton(f, x, y, point)
    f.CloseButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.CloseButton:SetPoint(point or "TOPRIGHT", x or BG.IsRetail and 0 or 5, y or BG.IsRetail and 0 or 5)
    f.CloseButton:SetScript("OnClick", function(self)
        f:Hide()
    end)
end

function BG.GetDiffShortName(diff)
    if diff == 14 then
        return "|cff00BFFFN|r"
    elseif diff == 15 then
        return "|cffFF0000H|r"
    elseif diff == 16 then
        return "|cffa335eeM|r"
    end
end

function BG.ShowNotLootTips(bossID)
    local text = BG.notLootBossIDs[bossID]
    local loot = C_PartyInfo.GetLootMethod()
    if text and (loot == "master" or loot == 2) and not IsMasterLooter() then
        BG.FrameLootMsg:AddMessage(BG.STC_y1(text))
    end
end

function BG.IsSecret(value)
    return issecretvalue and value and issecretvalue(value)
end

function BG.InBoss()
    return issecretvalue and BG.IsRetail and C_InstanceEncounter and C_InstanceEncounter.IsEncounterInProgress()
end

-- 在右下角生成可拖动、用于缩放界面的按钮
do
    local btMixin = {}
    local ag = 0.002 -- 灵敏度可调整
    local function SetValue(optionName, newScale)
        BiaoGe.options[optionName] = newScale
        BG.options["button" .. optionName]:SetValue(newScale)
        BG.options["button" .. optionName].edit:SetText(newScale)
    end
    function btMixin:OnMouseDown(btn)
        if btn == "LeftButton" then
            self.isDragging = true
            self.startX = GetCursorPosition()
            self.startScale = self:GetParent():GetScale()
        elseif btn == "RightButton" then
            local newScale = BG.options[self.optionName .. "reset"]
            self:GetParent():SetScale(newScale)
            SetValue(self.optionName, newScale)
        end
    end

    function btMixin:OnMouseUp()
        self.isDragging = false
    end

    function btMixin:OnUpdate()
        if not self.isDragging then return end
        local uiScale = UIParent:GetScale()
        local curX = GetCursorPosition()
        local deltaX = (curX - self.startX) / uiScale
        local newScale = self.startScale + deltaX * ag
        newScale = format("%.3f", math.max(self.minValue, math.min(newScale, self.maxValue)))
        self:GetParent():SetScale(newScale)
        SetValue(self.optionName, newScale)
    end

    function BG.CreateFrameResizeHandle(parent, optionName, minValue, maxValue, size, x, y)
        size = size or 20
        x = x or 0
        y = y or 0
        local bt = CreateFrame("Button", nil, parent)
        bt:SetSize(size, size)
        bt:SetPoint("BOTTOMRIGHT", x, y)
        bt:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        bt:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        bt:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        bt.optionName = optionName
        bt.minValue = minValue
        bt.maxValue = maxValue
        BG.SetMixin(bt, btMixin)
        return bt
    end
end

function BG.IsHideTooltipKeyDown()
    return IsShiftKeyDown() and IsControlKeyDown()
end

-- 「最佳价格」由第三方付费模块 BGV 提供，本插件不做付费模块挂载点，故恒返回 false。
-- 保留空实现是为了让各调用点（表格/背包/拍卖记录的点击分支）无需逐处改写即可短路。
function BG.IsSetBestPriceKeyDown()
    return false
end

function BG.GetAddonChannelName(channel, i)
    return channel .. ((i - 1) % BG.addonChannelCount + 1)
end

function BG.GetTargetBiaoGeVerIsOver(target, ver)
    local targetVer = BG.raidBiaoGeVersion[target]
    if targetVer and BG.GetVerNum(targetVer) >= ver then
        return true
    end
    return false
end

-- 输入框边框着色原由第三方付费模块 BGV 提供，已移除该挂载点，此处不做任何处理。
function BG.UpdateEditBorderColor(edit)
end

function BG.TargetVerOver(name,verNum)
   local ver= BG.raidBiaoGeVersion[name]
    return ver and BG.GetVerNum(ver) >= verNum
end
