if BG.IsBlackListPlayer then return end
local addonName, ns = ...
local LibBG = ns.LibBG
local L = ns.L
local C = ns.Protocol
local SendGateway = ns.SendGateway
local print = print
local After = C_Timer.After
local Wire = {
 version = "v4.0",
 versionPattern = "v(%d+%.%d+)",
 auctionIdKey = "auctionID",
 separatorGen1 = ",",
 separatorGen2 = "^",
 fieldCountGen1 = 8,
 channelPattern = C.PREFIX_AUCTION .. "(%d+)",
 maxFrames = 20,
}
local auctionKey = Wire.auctionIdKey
local wa = {}
wa.Wire = Wire
wa.ver = Wire.version
function wa.GetVerNum(version)
 return tonumber(string.match(version, Wire.versionPattern)) or 0
end
-- 统一计时入口：优先 GetTimePreciseSec（毫秒精度，用于 1s 出价 CD、0.3s 中继 CD、暂停/恢复计时），
-- 经典服客户端若缺失则兜底 GetTime（毫秒 API 在 Classic 1.15/60 引擎存在性见 docs/09 A3 风险）。
function wa.Now()
 if GetTimePreciseSec then
  return GetTimePreciseSec()
 end
 return GetTime()
end
BGA = BGA or {}
BGA.Frames = {}
BGA.ver = wa.ver
BGA.aura_env = wa
wa.AddonChannel = C.PREFIX_AUCTION
wa.AddonChannel2 = Wire.channelPattern
C_ChatInfo.RegisterAddonMessagePrefix(wa.AddonChannel)
wa.addonChannelCount = C.CHANNEL_COUNT
for i = 1, wa.addonChannelCount do
 local channelName = wa.AddonChannel .. i
 C_ChatInfo.RegisterAddonMessagePrefix(channelName)
end
wa.currentChannelIndex = 0
function wa.GetAddonChannelName()
 wa.currentChannelIndex = wa.currentChannelIndex % wa.addonChannelCount + 1
 return wa.AddonChannel .. wa.currentChannelIndex
end
BG.Init(function()
 local typeface = BIAOGE_TEXT_FONT or STANDARD_TEXT_FONT
 local realmName = GetRealmName():gsub(" ", ""):gsub("%-", "")
 do
  function wa.GN(unit)
   unit = unit or "player"
   if unit == "t" then
    unit = "target"
   end
   return GetUnitName(unit, true)
  end
  function wa.IsMe(entryFrame)
   return entryFrame.player and entryFrame.player == wa.GN() or false
  end
  function wa.GFN(name)
   if not name then return end
   local name, realm = strsplit("-", name)
   realm = realm or realmName
   return name .. "-" .. realm
  end
  function wa.GSN(name)
   if not name then return end
   local name, realm = strsplit("-", name)
   if not realm or realm == "" or realm == realmName then
    return name
   else
    return name .. "-" .. realm
   end
  end
  function wa.SPN(name)
   if not name then return end
   return strsplit("-", name)
  end
  function wa.RGB(hex, alpha)
   local r = string.sub(hex, 1, 2)
   local g = string.sub(hex, 3, 4)
   local b = string.sub(hex, 5, 6)
   r = tonumber(r, 16) / 255
   g = tonumber(g, 16) / 255
   b = tonumber(b, 16) / 255
   if alpha then
    return r, g, b, alpha
   else
    return r, g, b
   end
  end
 end
 do
  wa.sound1 = SOUNDKIT.GS_TITLE_OPTION_OK
  wa.sound2 = 569593
  wa.GREEN1 = "00FF00"
  wa.RED1 = "FF0000"
  wa.maxNumFrame = Wire.maxFrames
  wa.WIDTH = 310
  wa.HEIGHT = 105
  wa.SMALL_HEIGHT = 23
  wa.REPEAT_TIME = 20
  wa.HIDEFRAME_TIME = 1
  wa.edgeSize = 2.5
  wa.backdropColor = { 0, 0, 0, .6 }
  wa.backdropBorderColor = { 1, 1, 0, 1 }
  wa.backdropColor_IsMe = { 0, .6, 0, .6 }
  wa.backdropBorderColor_IsMe = { 0, 1, 0, 1 }
  wa.raidRosterInfo = {}
  wa.endMsg = {}
  wa.tooLateTime = 3
  wa.MiniMoneyTbl = {
   { 50, 1, 1 },
   { 100, 10, 1 },
   { 2000, 100, 100 },
   { 5000, 200, 100 },
   { 1 * 10000, 500, 100 },
   { 2 * 10000, 1000, 500 },
   { 5 * 10000, 2000, 500 },
   { 10 * 10000, 5000, 500 },
   { 20 * 10000, 10000, 1000 },
   { 50 * 10000, 20000, 1000 },
   { 100 * 10000, 50000, 1000 },
   { nil, 100000, 5000 },
  }
 end
 do
  local function buildFont(label, r, g, b, size)
   local obj = CreateFont("BGA.Font" .. label)
   obj:SetTextColor(r, g, b)
   obj:SetFont(typeface, size, "OUTLINE")
   return obj
  end
  BGA.FontGold18 = buildFont("Gold18", 1, 0.82, 0, 18)
  BGA.FontDis18 = buildFont("Dis18", .5, .5, .5, 18)
  BGA.FontDis15 = buildFont("Dis15", .5, .5, .5, 15)
  BGA.FontGreen15 = buildFont("Green15", 0, 1, 0, 15)
  BGA.FontWhite15 = buildFont("white15", 1, 1, 1, 15)
 end
 do
  function wa.SetClassCFF(name, player, type)
   if type then return name end
   local k, classFile
   if player then
    k, classFile = UnitClass(player)
   else
    k, classFile = UnitClass(wa.GSN(name))
   end
   local coloredName = ""
   if classFile then
    local colorHex = select(4, GetClassColor(classFile))
    coloredName = "|c" .. colorHex .. name .. "|r"
    return coloredName, colorHex
   else
    return name, ""
   end
  end
  function wa.SetEditBg(edit)
   edit:SetFont(typeface, 14, "OUTLINE")
  end
  function wa.FormatNumber(amount)
   if not tonumber(amount) then return amount end
   if Locale == "enUS" then
    local s = tostring(amount)
    s = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return s
   else
    amount = tostring(amount)
    local len = strlen(amount)
    if len < 5 then return amount end
    local last4 = amount:sub(-4, -1)
    local head = amount:sub(1, -5)
    if tonumber(last4) == 0 then
     return head .. L["万"]
    else
     for i = 1, 4 do
      local len = strlen(last4)
      local last = last4:sub(len, len)
      if last == "0" then
       last4 = last4:sub(1, len - 1)
      else
       break
      end
     end
     return head .. "." .. last4 .. L["万"]
    end
   end
  end
  function wa.IsRight(self)
   if self.owner:GetCenter() > UIParent:GetCenter() then
    return true
   end
  end
  function wa.OnLeave(self)
   GameTooltip_Hide()
   self.isOnEnter = false
  end
  function wa.OnEditFocusGained(self)
   wa.lastFocus = self
   self:HighlightText()
  end
  function wa.IsRaidLeader()
   return IsInRaid(1) and UnitIsGroupLeader("player")
  end
  function wa.IsML(player)
   if not player then
    player = wa.GN()
   end
   if (player == wa.raidLeader) or (player == wa.masterLooter) then
    return true
   end
  end
  function wa.UpdateRaidRosterInfo(sendVer)
   wipe(wa.raidRosterInfo)
   wa.raidLeader = nil
   wa.masterLooter = nil
   wa.onlineCount = 0
   if IsInRaid(1) then
    for i = 1, GetNumGroupMembers() do
     local name, rank, subgroup, level, class2, class, zone, online,
     isDead, role, isML, combatRole = GetRaidRosterInfo(i)
     if name then
      local member = {
       name = name,
       rank = rank,
       subgroup = subgroup,
       level = level,
       class2 = class2,
       class = class,
       zone = zone,
       online = online,
       isDead = isDead,
       role = role,
       isML = isML,
       combatRole = combatRole
      }
      tinsert(wa.raidRosterInfo, member)
      if rank == 2 then
       wa.raidLeader = name
      end
      if isML then
       wa.masterLooter = name
      end
     end
    end
    if sendVer then
     SendGateway.Addon(wa.AddonChannel, C.OP_MY_VER .. "," .. wa.ver, "RAID")
    end
   end
   for k, entryFrame in pairs(BGA.Frames) do
    wa.UpdateButtonState(entryFrame)
   end
  end
  function wa.IsSecret(value)
   return issecretvalue and issecretvalue(value)
  end
  function wa.InBoss()
   return issecretvalue and C_InstanceEncounter.IsEncounterInProgress()
  end
  local receivedCount = 0
  function wa.canSend()
   local memberCount
   local canSend = true
   if IsInRaid(1) then
    memberCount = GetNumGroupMembers(1)
    if receivedCount >= memberCount then
     canSend = false
    end
   else
    canSend = false
    memberCount = 0
   end
   receivedCount = memberCount
   return canSend
  end
  function wa.GetAuctioningFromRaid()
   if not IsInRaid(1) then return end
   wa.canGetAuctioning = true
   SendGateway.Addon(wa.AddonChannel, C.OP_GET_AUCTIONING, "RAID")
   After(1, function()
    wa.canGetAuctioning = false
   end)
  end
  function wa.SetFrameColor(entryFrame, colorIndex)
   local backdropColor, borderColor, typeface
   if colorIndex == 1 then
    backdropColor = wa.backdropColor_IsMe
    borderColor = wa.backdropBorderColor_IsMe
    typeface = BGA.FontGreen15
   else
    backdropColor = wa.backdropColor
    borderColor = wa.backdropBorderColor
    typeface = BGA.FontGreen15
   end
   for k, frame in ipairs({ entryFrame, entryFrame.autoFrame }) do
    frame:SetBackdropColor(unpack(backdropColor))
    frame:SetBackdropBorderColor(unpack(borderColor))
   end
   for k, name in ipairs({ "hide", "cancelButton", "puaseButton", "autoTextButton", "logTextButton", }) do
    if entryFrame[name] then
     entryFrame[name]:SetNormalFontObject(typeface)
    end
   end
  end
 end
 do
  local function expandFrame(entryFrame)
   if not entryFrame.hide:IsEnabled() then return end
   entryFrame.IsSmallWindow = false
   entryFrame.hide:SetText(L["折叠"])
   wa.UpdateButtonState(entryFrame)
   entryFrame.topMoneyFrame:Show()
   if not entryFrame.IsEnd and not entryFrame.isPaused then
    entryFrame.myMoneyEdit:Show()
   end
   entryFrame.itemFrame2:Show()
   entryFrame:SetSize(wa.WIDTH, wa.HEIGHT)
   entryFrame.itemFrame:ClearAllPoints()
   entryFrame.itemFrame:SetPoint("TOPLEFT", entryFrame, "TOPLEFT", wa.edgeSize + 1, -entryFrame.hide:GetHeight() - 3)
   entryFrame.itemFrame:SetPoint("BOTTOMRIGHT", entryFrame, "TOPRIGHT", -wa.edgeSize, -55)
   entryFrame.itemFrame.iconFrame:ClearAllPoints()
   entryFrame.itemFrame.iconFrame:SetPoint("TOPLEFT", entryFrame.itemFrame, "TOPLEFT", 0, 0)
   entryFrame.itemFrame.iconFrame:SetPoint("BOTTOMRIGHT", entryFrame.itemFrame, "TOPLEFT", entryFrame.itemFrame:GetHeight(), -entryFrame.itemFrame:GetHeight())
   entryFrame.itemFrame.iconFrame:SetBackdropBorderColor(unpack(entryFrame.itemFrame.iconFrame.color))
   entryFrame.itemFrame.itemNameText:ClearAllPoints()
   entryFrame.itemFrame.itemNameText:SetPoint("TOPLEFT", entryFrame.itemFrame.iconFrame, "TOPRIGHT", 2, -2)
   entryFrame.itemFrame.bg:ClearAllPoints()
   entryFrame.itemFrame.bg:SetAllPoints()
   entryFrame.bar:ClearAllPoints()
   entryFrame.bar:SetPoint("TOPLEFT", entryFrame.itemFrame.iconFrame, "TOPRIGHT", 0, 0)
   entryFrame.bar:SetPoint("BOTTOMRIGHT", entryFrame.itemFrame, "BOTTOMRIGHT", 0, 0)
   entryFrame.currentMoneyFrame:ClearAllPoints()
   entryFrame.currentMoneyFrame:SetPoint("TOPLEFT", entryFrame.itemFrame, "BOTTOMLEFT", 3, -3)
   if entryFrame.start then
    entryFrame.currentMoneyText:SetText(L["|cffFFD100起拍价：|r"] .. wa.FormatNumber(entryFrame.money))
   else
    entryFrame.currentMoneyText:SetText(L["|cffFFD100当前价格：|r"] .. wa.FormatNumber(entryFrame.money))
   end
   entryFrame.currentMoneyText:SetJustifyH("LEFT")
  end
  local function collapseFrame(entryFrame)
   if not entryFrame.hide:IsEnabled() then return end
   entryFrame.IsSmallWindow = true
   entryFrame.hide:SetText(L["展开"])
   wa.UpdateButtonState(entryFrame)
   entryFrame.autoFrame:Hide()
   entryFrame.topMoneyFrame:Hide()
   entryFrame.myMoneyEdit:Hide()
   entryFrame.itemFrame2:Hide()
   entryFrame:SetSize(wa.WIDTH, wa.SMALL_HEIGHT)
   entryFrame.itemFrame:ClearAllPoints()
   entryFrame.itemFrame:SetAllPoints()
   entryFrame.itemFrame.iconFrame:ClearAllPoints()
   entryFrame.itemFrame.iconFrame:SetPoint("TOPLEFT", wa.edgeSize, -wa.edgeSize)
   entryFrame.itemFrame.iconFrame:SetPoint("BOTTOMRIGHT", entryFrame.itemFrame, "TOPLEFT", entryFrame.itemFrame:GetHeight() - wa.edgeSize, -entryFrame.itemFrame:GetHeight() + wa.edgeSize)
   entryFrame.itemFrame.iconFrame:SetBackdropBorderColor(1, 1, 1, 0)
   entryFrame.itemFrame.itemNameText:ClearAllPoints()
   entryFrame.itemFrame.itemNameText:SetPoint("LEFT", entryFrame.itemFrame.iconFrame, "RIGHT", 2, 0)
   entryFrame.itemFrame.bg:ClearAllPoints()
   entryFrame.itemFrame.bg:SetPoint("TOPLEFT", wa.edgeSize, -wa.edgeSize)
   entryFrame.itemFrame.bg:SetPoint("BOTTOMRIGHT", -wa.edgeSize, wa.edgeSize)
   entryFrame.bar:ClearAllPoints()
   entryFrame.bar:SetPoint("TOPLEFT", entryFrame.itemFrame.iconFrame, "TOPRIGHT", 0, 0)
   entryFrame.bar:SetPoint("BOTTOMRIGHT", entryFrame.itemFrame, "BOTTOMRIGHT", -wa.edgeSize, wa.edgeSize)
   entryFrame.currentMoneyFrame:ClearAllPoints()
   entryFrame.currentMoneyFrame:SetPoint("RIGHT", entryFrame.hide, "LEFT", -5, -0)
   if entryFrame.start then
    entryFrame.currentMoneyText:SetText("")
   else
    entryFrame.currentMoneyText:SetText(wa.FormatNumber(entryFrame.money))
   end
   entryFrame.currentMoneyText:SetJustifyH("RIGHT")
  end
  function wa.Hide_OnClick(self, button)
   local entryFrame = self.owner
   local layoutFunc = entryFrame.IsSmallWindow and expandFrame or collapseFrame
   if (IsAltKeyDown() or button == "RightButton") and not entryFrame.notClick then
    for k, entryFrame in pairs(BGA.Frames) do
     layoutFunc(entryFrame)
    end
   else
    layoutFunc(entryFrame)
   end
   if not entryFrame.notClick then
    wa.UpdateAllOnEnters()
    wa.UpdateAllFrames()
    PlaySound(wa.sound1)
   end
  end
  function wa.Hide_OnEnter(self)
   local entryFrame = self.owner
   if wa.IsRight(self) then
    GameTooltip:SetOwner(entryFrame, "ANCHOR_LEFT", 0, 0)
   else
    GameTooltip:SetOwner(entryFrame, "ANCHOR_RIGHT", 0, 0)
   end
   GameTooltip:ClearLines()
   if entryFrame.IsSmallWindow then
    GameTooltip:AddLine(L["展开"], 1, 1, 1, true)
    GameTooltip:AddLine(L["左键：单个展开"], 1, 0.82, 0, true)
    GameTooltip:AddLine(L["右键：全部展开"], 1, 0.82, 0, true)
   else
    GameTooltip:AddLine(L["折叠"], 1, 1, 1, true)
    GameTooltip:AddLine(L["左键：单个折叠"], 1, 0.82, 0, true)
    GameTooltip:AddLine(L["右键：全部折叠"], 1, 0.82, 0, true)
   end
   GameTooltip:Show()
   self.isOnEnter = true
  end
 end
 function wa.SendAddonMessage(entryFrame, ...)
  local separator = entryFrame.isGen2 and Wire.separatorGen2 or Wire.separatorGen1
  local buffer = ""
  for i, part in ipairs({ ... }) do
   buffer = buffer .. (i == 1 and "" or separator) .. part
  end
  SendGateway.Addon(entryFrame.isGen2 and wa.GetAddonChannelName() or wa.AddonChannel, buffer, "RAID")
 end
 do
  function wa.Cancel_OnClick(self)
   local entryFrame = self.owner
   wa.SendAddonMessage(entryFrame, C.OP_CANCEL_AUCTION, entryFrame[auctionKey])
   PlaySound(wa.sound1)
  end
  function wa.Cancel_OnEnter(self)
   local entryFrame = self.owner
   if wa.IsRight(self) then
    GameTooltip:SetOwner(entryFrame, "ANCHOR_LEFT", 0, 0)
   else
    GameTooltip:SetOwner(entryFrame, "ANCHOR_RIGHT", 0, 0)
   end
   GameTooltip:ClearLines()
   GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
   GameTooltip:AddLine(L["Alt+点击才能生效"], 1, 0.82, 0, true)
   GameTooltip:AddLine(L["只有团长或物品分配者有权限取消拍卖"], 0.5, 0.5, 0.5, true)
   GameTooltip:Show()
  end
 end
 do
  function wa.Pause_OnClick(self)
   local entryFrame = self.owner
   wa.SendAddonMessage(entryFrame, entryFrame.isPaused and C.OP_RESUME_AUCTION or C.OP_PAUSE_AUCTION, entryFrame.itemID)
   PlaySound(wa.sound1)
  end
  function wa.PauseAuction(entryFrame)
   if entryFrame.IsEnd or entryFrame.isPaused then return end
   entryFrame.isPaused = true
   entryFrame.pausedRemaining = entryFrame.endTime - wa.Now()
   entryFrame.myMoneyEdit:Hide()
   entryFrame.ButtonJian:Hide()
   entryFrame.ButtonJia:Hide()
   entryFrame.ButtonSendMyMoney:Hide()
   entryFrame.remainingTime:SetText(L["已暂停"])
   entryFrame.remainingTime:SetTextColor(1, 1, 0)
   wa.UpdateButtonState(entryFrame)
  end
  function wa.ResumeAuction(entryFrame)
   if entryFrame.IsEnd or not entryFrame.isPaused then return end
   entryFrame.isPaused = false
   entryFrame.endTime = wa.Now() + entryFrame.pausedRemaining
   entryFrame.pausedRemaining = nil
   entryFrame.myMoneyEdit:Show()
   entryFrame.ButtonJian:Show()
   entryFrame.ButtonJia:Show()
   entryFrame.ButtonSendMyMoney:Show()
   wa.RefreshTimer(entryFrame)
   wa.AutoSendMyMoney(entryFrame)
   wa.UpdateButtonState(entryFrame)
  end
 end
 do
  local function buildLogTooltip(entryFrame, i)
   local timeText = entryFrame.logs[i].time and L["剩余%s秒时出价"]:format(entryFrame.logs[i].time) or ""
   GameTooltip:AddLine(format(L["%s、%s（%s）|cffff0000%s"], i, entryFrame.logs[i].money, entryFrame.logs[i].player, timeText), 1, .82, 0, true)
  end
  function wa.LogTextButton_OnEnter(self)
   self.isOnEnter = true
   local entryFrame = self.owner
   if wa.IsRight(self) then
    GameTooltip:SetOwner(entryFrame, "ANCHOR_LEFT", 0, 0)
   else
    GameTooltip:SetOwner(entryFrame, "ANCHOR_RIGHT", 0, 0)
   end
   GameTooltip:ClearLines()
   GameTooltip:AddLine(L["出价记录"], 1, 1, 1, true)
   if #entryFrame.logs == 0 then
    GameTooltip:AddLine(L["没有人出价"], .5, .5, .5, true)
   elseif #entryFrame.logs > 15 then
    GameTooltip:AddLine("......", .5, .5, .5, true)
    for i = #entryFrame.logs - 14, #entryFrame.logs do
     buildLogTooltip(entryFrame, i)
    end
   else
    for i = 1, #entryFrame.logs do
     buildLogTooltip(entryFrame, i)
    end
   end
   GameTooltip:Show()
  end
 end
 do
  function wa.itemOnEnter(self)
   local entryFrame = self.owner
   if entryFrame.IsSmallWindow then return end
   local anchor
   if wa.IsRight(self) then
    GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0)
    anchor = "LEFT"
   else
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
    anchor = "RIGHT"
   end
   GameTooltip:ClearLines()
   GameTooltip:SetHyperlink(self.link)
   if BG and BG.SetZUGSetTooltip then
    BG.SetZUGSetTooltip(self.itemID, anchor)
   end
   if IsControlKeyDown() then
    SetCursor("Interface/Cursor/Inspect")
   end
   self.isOnEnter = true
   wa.itemIsOnEnter = true
   if BG then
    if BG.Show_AllHighlight then
     BG.Show_AllHighlight(self.link)
    end
   end
  end
  function wa.itemOnLeave(self)
   GameTooltip:Hide()
   self.isOnEnter = false
   wa.itemIsOnEnter = false
   SetCursor(nil)
   if BG then
    if BG.Hide_AllHighlight then
     BG.Hide_AllHighlight()
    end
   end
  end
 end
 do
  function wa.JiaJian(money, step, direction)
   if direction == "+" then
    return money + step
   elseif direction == "-" then
    if money - step > 0 then
     return money - step
    elseif (money == step) and money ~= 1 then
     return money - 10
    else
     return 0
    end
   end
  end
  function wa.Addmoney(money, direction)
   local money = tonumber(money) or 0
   local step
   for i, tier in ipairs(wa.MiniMoneyTbl) do
    if not tier[1] or money < tier[1] then
     step = tier[2]
     break
    end
   end
   return wa.JiaJian(money, step, direction), step
  end
  function wa.TooSmallMoney(amount, threshold)
   local money = amount - threshold
   for i, tier in ipairs(wa.MiniMoneyTbl) do
    if not tier[1] or threshold < tier[1] then
     if money < tier[3] then
      return tier[3]
     else
      return false
     end
    end
   end
  end
  function wa.TooSmall(self)
   local amount = tonumber(self:GetText()) or 0
   local threshold = self.owner.money
   return wa.TooSmallMoney(amount, threshold)
  end
  function wa.currentMoney_OnMouseDown(self)
   self.owner:GetScript("OnMouseDown")(BGA.AuctionMainFrame)
  end
  function wa.currentMoney_OnMouseUp(self)
   local entryFrame = self.owner
   entryFrame:GetScript("OnMouseUp")(BGA.AuctionMainFrame)
  end
  function wa.myMoney_OnTextChanged(self)
   local entryFrame = self.owner
   local money = tonumber(self:GetText()) or 0
   if entryFrame.start then
    if money < entryFrame.money then
     self:SetTextColor(1, 0, 0)
     entryFrame.ButtonSendMyMoney:Disable()
     if not wa.IsMe(entryFrame) then
      entryFrame.ButtonSendMyMoney.disf:Show()
      entryFrame.ButtonSendMyMoney.disf.text = L["需高于或等于起拍价"]
     end
    else
     self:SetTextColor(1, 1, 1)
     entryFrame.ButtonSendMyMoney:Enable()
     entryFrame.ButtonSendMyMoney.disf:Hide()
    end
   elseif money <= entryFrame.money then
    entryFrame.ButtonSendMyMoney:Disable()
    if wa.IsMe(entryFrame) then
     self:SetTextColor(1, 1, 1)
    else
     self:SetTextColor(1, 0, 0)
     entryFrame.ButtonSendMyMoney.disf:Show()
     entryFrame.ButtonSendMyMoney.disf.text = L["需高于当前价格"]
    end
   elseif wa.TooSmall(self) then
    self:SetTextColor(1, 0, 0)
    entryFrame.ButtonSendMyMoney:Disable()
    entryFrame.ButtonSendMyMoney.disf:Show()
    entryFrame.ButtonSendMyMoney.disf.text = format(L["最小加价幅度为%s"], wa.TooSmall(self))
   else
    self:SetTextColor(1, 1, 1)
    entryFrame.ButtonSendMyMoney:Enable()
    entryFrame.ButtonSendMyMoney.disf:Hide()
   end
   if money <= entryFrame.money then
    entryFrame.ButtonJian:Disable()
   else
    entryFrame.ButtonJian:Enable()
   end
   wa.UpdateAllOnEnters()
  end
  function wa.myMoney_OnMouseWheel(self, step)
   local direction = "-"
   if step == 1 then
    direction = "+"
   end
   if direction == "-" then
    local entryFrame = self.owner
    local price = tonumber(self:GetText())
    if price and price <= entryFrame.money then
     return
    end
   end
   self:SetText(wa.Addmoney(self:GetText(), direction))
  end
  function wa.myMoney_OnEnter(self)
   GameTooltip:SetOwner(self.owner, "ANCHOR_BOTTOM", 0, 0)
   GameTooltip:ClearLines()
   GameTooltip:AddLine(wa.FormatNumber(self:GetText()), 1, 1, 1)
   GameTooltip:AddLine(L["滚轮：快速调整价格"], 1, 0.82, 0, true)
   GameTooltip:Show()
   self.isOnEnter = true
  end
  function wa.JiaJian_OnEnter(self)
   local entryFrame = self.owner
   local price = tonumber(self.edit:GetText()) or 0
   local k, step = wa.Addmoney(price, self._type)
   GameTooltip:SetOwner(entryFrame, "ANCHOR_BOTTOM", 0, 0)
   GameTooltip:ClearLines()
   if not entryFrame.start and not entryFrame.IsEnd and not wa.IsMe(entryFrame) and self._type == "+" and price <= entryFrame.money then
    GameTooltip:AddLine(L["出价设为："] .. "|cffffffff" .. wa.FormatNumber(wa.Addmoney(entryFrame.money, "+")), 1, 0.82, 0, true)
   else
    local r, g, b = 1, 0, 0
    if self._type == "+" then
     r, g, b = 0, 1, 0
    end
    GameTooltip:AddLine(self._type .. " " .. wa.FormatNumber(step), r, g, b, true)
    GameTooltip:AddLine(L["根据你的出价动态改变增减幅度"], 1, 0.82, 0, true)
    GameTooltip:AddLine(L["长按：快速调整价格"], 1, 0.82, 0, true)
   end
   GameTooltip:Show()
   self.isOnEnter = true
  end
  function wa.JiaJian_OnClick(self)
   local entryFrame = self.owner
   local price = tonumber(self.edit:GetText()) or 0
   if not entryFrame.start and not entryFrame.IsEnd and not wa.IsMe(entryFrame) and self._type == "+" and price <= entryFrame.money then
    self.edit:SetText(wa.Addmoney(entryFrame.money, "+"))
   else
    self.edit:SetText(wa.Addmoney(price, self._type))
   end
   wa.UpdateAllOnEnters()
   PlaySound(wa.sound1)
  end
  function wa.JiaJian_OnMouseDown(self)
   local holdTime = 0
   local longPressTime = 0.5
   self:SetScript("OnUpdate", function(self, elapsed)
    holdTime = holdTime + elapsed
    if not self:IsEnabled() then
     self:SetScript("OnUpdate", nil)
     return
    end
    if holdTime >= longPressTime then
     holdTime = longPressTime - 0.1
     self.edit:SetText(wa.Addmoney(self.edit:GetText(), self._type))
     wa.JiaJian_OnEnter(self)
    end
   end)
  end
  function wa.JiaJian_OnMouseUp(self)
   self:SetScript("OnUpdate", nil)
  end
 end
 do
  local function sendMoney(entryFrame)
   if entryFrame.ButtonSendMyMoney:IsEnabled() then
    local money = tonumber(entryFrame.myMoneyEdit:GetText()) or 0
    wa.SendMyMoneyMsg(entryFrame, money)
    entryFrame.myMoneyEdit:ClearFocus()
    PlaySound(wa.sound1)
   end
  end
  -- 统一出价发送：按模式选择匿名/普通通道。IsEnabled 门保留在各调用点（SendMyMoney_OnClick），
  -- 不得收进本函数——否则自动出价路径在按钮禁用态会被意外加门而静默失效。
  function wa.SendMyMoneyMsg(entryFrame, money)
   wa.SendAddonMessage(entryFrame, C.OP_SEND_MY_MONEY, entryFrame[auctionKey], money)
  end
  function wa.SendMyMoney_OnClick(self)
   local entryFrame = self.owner
   if entryFrame.ButtonSendMyMoney:IsEnabled() then
    self.cd = self.cd or 0
    if wa.Now() - self.cd < 1 then return end
    self.cd = wa.Now()
    if wa.IsMe(entryFrame) then
     if not StaticPopupDialogs["BiaoGeAuction_RepeatSend"] then
      StaticPopupDialogs["BiaoGeAuction_RepeatSend"] = {
       text = L["你已是%s的出价最高者，|cffff0000没必要自己顶自己|r。真的要继续出价到 %s ？"],
       button1 = YES,
       button2 = NO,
       OnCancel = function()
       end,
       timeout = 0,
       whileDead = true,
       hideOnEscape = true,
       showAlert = true,
      }
     end
     StaticPopupDialogs["BiaoGeAuction_RepeatSend"].OnAccept = function()
      sendMoney(entryFrame)
     end
     StaticPopup_Show("BiaoGeAuction_RepeatSend", entryFrame.link, tonumber(entryFrame.myMoneyEdit:GetText()) or 0)
    else
     sendMoney(entryFrame)
    end
   end
  end
  function wa.SetMoney(entryFrame, money, player)
   if not entryFrame.IsSmallWindow then
    entryFrame.updateFrame:Show()
    entryFrame.autoFrame.updateFrame:Show()
   end
   if not entryFrame.isAuto and BG and BG.PlayTopPriceSound then
    BG.PlayTopPriceSound(entryFrame, player)
   end
   entryFrame.money = money
   if entryFrame.IsSmallWindow then
    entryFrame.currentMoneyText:SetText(wa.FormatNumber(money))
   else
    entryFrame.currentMoneyText:SetText(L["|cffFFD100当前价格：|r"] .. wa.FormatNumber(money))
    entryFrame.myMoneyEdit:Show()
   end
   entryFrame.player = player
   entryFrame.colorplayer = wa.SetClassCFF(player)
   entryFrame.start = false
   local lateTag = ((entryFrame.remaining or 10) <= wa.tooLateTime) and format("%.1f", entryFrame.remaining) or nil
   if player == wa.GN() then
    entryFrame.topMoneyText:SetText(L["|cffFFD100出价最高者：|r"] .. "|cff" .. wa.GREEN1 .. L[">> 你 <<"])
    wa.SetFrameColor(entryFrame, 1)
    tinsert(entryFrame.logs, { money = money, player = "|cff" .. wa.GREEN1 .. L["你"] .. "|r", time = lateTag })
    if lateTag then
     SendGateway.Chat(format(L["%s的剩余时间不到%s秒时我出价%s。卡秒出价可能导致拍卖出错！"], entryFrame.link, lateTag, entryFrame.money), "RAID")
     if BG and BG.PlaySound then
      BG.PlaySound("tooLate")
     end
    end
   else
    entryFrame.topMoneyText:SetText(L["|cffFFD100出价最高者：|r"] .. entryFrame.colorplayer)
    tinsert(entryFrame.logs, { money = money, player = entryFrame.colorplayer, time = lateTag })
    wa.SetFrameColor(entryFrame, 0)
    if entryFrame.isAuto then
     entryFrame.autoSendDelayFrame.t = 0
     entryFrame.autoSendDelayFrame.delay = wa.AutoSendLate()
     entryFrame.autoSendDelayFrame:SetScript("OnUpdate", function(self, elapsed)
      self.t = self.t + elapsed
      if self.t >= self.delay then
       wa.AutoSendMyMoney(entryFrame)
       self:SetScript("OnUpdate", nil)
      end
     end)
    end
   end
   wa.myMoney_OnTextChanged(entryFrame.myMoneyEdit)
   if entryFrame.isAuto and (entryFrame.money >= entryFrame.autoMoney or wa.TooSmallMoney(entryFrame.autoMoney, entryFrame.money)) then
    entryFrame.autoTitleText:SetText(L["设置心理价格"])
    entryFrame.autoTitleText:SetTextColor(1, .82, 0)
    entryFrame.isAutoTex:Hide()
    entryFrame.autoButton:SetText(L["开启自动出价"])
    entryFrame.autoButton:Enable()
    entryFrame.autoMoneyEdit.Left:SetAlpha(1)
    entryFrame.autoMoneyEdit.Right:SetAlpha(1)
    entryFrame.autoMoneyEdit.Middle:SetAlpha(1)
    entryFrame.isAuto = false
    entryFrame.autoSendDelayFrame:SetScript("OnUpdate", nil)
    entryFrame.autoTextButton:SetText(L["自动出价"])
    entryFrame.autoTextButton:SetWidth(entryFrame.autoTextButton:GetFontString():GetWidth())
    entryFrame.autoMoneyEdit:SetTextColor(1, 1, 1)
    entryFrame.autoMoneyEdit:SetEnabled(true)
    entryFrame.autoMoneyEdit.isLocked = false
    entryFrame.hide:Enable()
    wa.AutoSendEndPlaySound()
   end
   wa.Auto_OnTextChanged(entryFrame.autoMoneyEdit)
   wa.RefreshTimer(entryFrame)
   if entryFrame.isGen2 then
    for k, otherFrame in pairs(BGA.Frames) do
     if otherFrame ~= entryFrame and otherFrame.itemID == entryFrame.itemID then
      wa.RefreshTimer(otherFrame)
     end
    end
   end
   -- 新高价到达即取消自动出价 ticker（v2.3.5 三处取消点之①）：避免旧 ticker 在延迟出价后重复顶价，
   -- 重投时机交给上方的 autoSendDelayFrame。
   if entryFrame.autoTimer then
    entryFrame.autoTimer:Cancel()
   end
  end
  function wa.SendMyMoney_OnEnter(self)
   self.isOnEnter = true
  end
  function wa.SendMyMoneyDis_OnEnter(self)
   local entryFrame = self.owner
   GameTooltip:SetOwner(self.owner, "ANCHOR_BOTTOM", 0, 0)
   GameTooltip:ClearLines()
   GameTooltip:AddLine(self.text, 1, 0, 0, true)
   GameTooltip:Show()
  end
 end
 do
  function wa.UpdateAllOnEnters()
   for k, entryFrame in pairs(BGA.Frames) do
    if entryFrame.myMoneyEdit.isOnEnter then
     wa.myMoney_OnEnter(entryFrame.myMoneyEdit)
    end
    if entryFrame.ButtonJian.isOnEnter then
     wa.JiaJian_OnEnter(entryFrame.ButtonJian)
    end
    if entryFrame.ButtonJia.isOnEnter then
     wa.JiaJian_OnEnter(entryFrame.ButtonJia)
    end
    if entryFrame.ButtonSendMyMoney.isOnEnter then
     wa.SendMyMoney_OnEnter(entryFrame.ButtonSendMyMoney)
    end
    if entryFrame.logTextButton.isOnEnter then
     entryFrame.logTextButton:GetScript("OnEnter")(entryFrame.logTextButton)
    end
    if entryFrame.autoMoneyEdit.isOnEnter then
     wa.AutoEdit_OnEnter(entryFrame.autoMoneyEdit)
    end
    if entryFrame.hide.isOnEnter then
     wa.Hide_OnEnter(entryFrame.hide)
    end
   end
  end
  function wa.GetFrameTotolHeight(count)
   local height = 0
   for i = 1, count - 1 do
    local entryFrame = BGA.Frames[i]
    if entryFrame then
     if entryFrame.IsSmallWindow then
      height = height + wa.SMALL_HEIGHT + 5
     else
      height = height + wa.HEIGHT + 5
     end
    end
   end
   return height
  end
  local function arrangeFrames()
   local idx = 0
   local frames = {}
   for i = 1, wa.maxNumFrame do
    local entryFrame = BGA.Frames[i]
    if entryFrame then
     idx = idx + 1
     entryFrame.num = idx
     frames[idx] = entryFrame
    end
   end
   BGA.Frames = frames
  end
  function wa.UpdateAllFrames()
   arrangeFrames()
   for k, entryFrame in pairs(BGA.Frames) do
    if entryFrame.showCantClickFrame and not entryFrame.IsSmallWindow then
     entryFrame.cantClickFrame:Show()
     entryFrame.cantClickFrame.t = 0
     entryFrame.cantClickFrame:SetScript("OnUpdate", function(self, elapsed)
      self.t = self.t + elapsed
      if self.t >= .8 then
       self:SetScript("OnUpdate", nil)
       self:Hide()
      end
     end)
    end
    entryFrame:ClearAllPoints()
    entryFrame:SetPoint("TOP", 0, -wa.GetFrameTotolHeight(entryFrame.num))
   end
  end
  function wa.UpdateFrame(entryFrame)
   local alpha = 1
   entryFrame:SetScript("OnUpdate", function(self, elapsed)
    alpha = alpha - elapsed
    if alpha >= 0 then
     entryFrame:SetAlpha(alpha)
    else
     entryFrame:SetScript("OnUpdate", nil)
     BGA.Frames[entryFrame.num] = nil
     entryFrame:Hide()
     BGA.AuctionMainFrame:StopMovingOrSizing()
     if BG and BG.options and BiaoGe.options.autoAuctionUp == 1 then
      for k, otherFrame in pairs(BGA.Frames) do
       if otherFrame.num < entryFrame.num then
        otherFrame.showCantClickFrame = false
       else
        otherFrame.showCantClickFrame = true
       end
      end
      wa.UpdateAllFrames()
     end
    end
   end)
  end
  function wa.UpdateButtonState(entryFrame)
   local btn = entryFrame.cancelButton
   btn:ClearAllPoints()
   if entryFrame.isGen2 then
    btn:SetText(CANCEL)
    btn:SetPoint("TOP", entryFrame, "TOPLEFT", wa.WIDTH / 10 * 3, -2)
   else
    btn:SetText(L["取消拍卖"])
    btn:SetPoint("TOP", entryFrame, "TOPLEFT", wa.WIDTH / 10 * 3.3, -2)
   end
   btn:SetSize(btn:GetFontString():GetWidth() + 10, 18)
   btn:SetShown(wa.IsML() and not entryFrame.IsEnd and not entryFrame.IsSmallWindow)
   local btn = entryFrame.puaseButton
   if btn then
    btn:SetText(entryFrame.isPaused and L["恢复"] or L["暂停"])
    btn:SetSize(btn:GetFontString():GetWidth() + 10, 18)
    btn:SetShown(wa.IsML() and not entryFrame.IsEnd and not entryFrame.IsSmallWindow)
   end
   local btn = entryFrame.autoTextButton
   btn:ClearAllPoints()
   if wa.IsML() then
    if entryFrame.isGen2 then
     btn:SetPoint("TOP", entryFrame, "TOPLEFT", wa.WIDTH / 10 * 7, -2)
     btn:SetText(L["自动"])
    else
     btn:SetPoint("TOP", entryFrame, "TOPLEFT", btn.offset, -2)
     btn:SetText(L["自动出价"])
    end
   else
    btn:SetPoint("TOP", 0, -2)
    btn:SetText(L["自动出价"])
   end
   btn:SetSize(btn:GetFontString():GetWidth() + 10, 18)
   btn:SetShown(not entryFrame.IsSmallWindow)
   local btn = entryFrame.logTextButton
   btn:SetShown(not entryFrame.IsSmallWindow)
   if entryFrame.isPreview then
    entryFrame.cancelButton:Hide()
    if entryFrame.puaseButton then entryFrame.puaseButton:Hide() end
    entryFrame.autoTextButton:Hide()
    entryFrame.logTextButton:Hide()
    entryFrame.hide:Hide()
   end
  end
 end
 do
  local function checkOverlap()
   for j = 1, wa.maxNumFrame do
    local entryFrame = BGA.Frames[j]
    if entryFrame and not entryFrame.animing then
     local top = entryFrame:GetTop()
     local bottom = entryFrame:GetBottom()
     for i = 1, wa.maxNumFrame do
      local otherFrame = BGA.Frames[i]
      if otherFrame and not otherFrame.animing and entryFrame.num ~= otherFrame.num then
       local otherTop = otherFrame:GetTop()
       local otherBottom = otherFrame:GetBottom()
       if (top <= otherTop and top >= otherBottom) or (bottom <= otherTop and bottom >= otherBottom) then
        wa.UpdateAllFrames()
        return
       end
      end
     end
    end
   end
  end
  function wa.anim(parent)
   parent.alltime = 0.5
   parent.t = 0.5
   parent.animing = true
   parent:SetScript("OnUpdate", function(self, step)
    self.t = self.t - step
    if self.t <= 0 then self.t = 0 end
    self:SetAlpha(max(1 - self.t / self.alltime, 0.01))
    self.myMoneyEdit:SetCursorPosition(0)
    if self.t <= 0 then
     self.animing = nil
     self:SetScript("OnUpdate", nil)
     After(0, function()
      checkOverlap()
     end)
    end
   end)
  end
 end
 do
  function wa.AutoText_OnClick(self)
   self.owner.autoFrame:SetShown(not self.owner.autoFrame:IsVisible())
   self.owner.autoFrame.isClicked = true
   PlaySound(wa.sound1)
  end
  function wa.Auto_OnTextChanged(self)
   local entryFrame = self.owner
   local money = tonumber(self:GetText()) or 0
   entryFrame.autoMoney = money
   entryFrame.autoButton:Enable()
   entryFrame.autoButton.disf:Hide()
   if not entryFrame.isAuto then
    local isMe = wa.IsMe(entryFrame)
    local isZero = money == 0
    local shouldTip = isZero and (entryFrame.start or not isMe)
    local tipMsg
    if not isZero then
     if entryFrame.start and money < entryFrame.money then
      isZero = true
      shouldTip = true
      if not isMe then
       tipMsg = L["心理价格需高于或等于起拍价"]
      end
     elseif not entryFrame.start and money <= entryFrame.money then
      isZero = true
      shouldTip = not isMe
      if not isMe then
       tipMsg = L["心理价格需高于当前价格"]
      end
     elseif not entryFrame.start then
      local minInc = wa.TooSmallMoney(money, entryFrame.money)
      if minInc then
       isZero = true
       shouldTip = true
       tipMsg = format(L["最小加价幅度为%s"], minInc)
      end
     end
    end
    if isZero then
     entryFrame.autoButton:Disable()
     if tipMsg then
      entryFrame.autoButton.onEnterText = tipMsg
      entryFrame.autoButton.disf:Show()
     end
    end
    if shouldTip then
     self:SetTextColor(1, 0, 0)
    else
     self:SetTextColor(1, 1, 1)
    end
   end
   wa.UpdateAllOnEnters()
  end
  function wa.AutoEdit_OnEnter(self)
   local entryFrame = self.owner
   GameTooltip:SetOwner(entryFrame.autoFrame, "ANCHOR_BOTTOM", 0, 0)
   GameTooltip:ClearLines()
   if self.isLocked then
    local money = self:GetText()
    if tonumber(money) then
     GameTooltip:AddLine(L["心理价格锁定中"] .. format(L["（%s）"], wa.FormatNumber(money)), 1, 0, 0, true)
    else
     GameTooltip:AddLine(L["心理价格锁定中"], 1, 0, 0, true)
    end
    GameTooltip:AddLine(L["取消自动出价后才能修改。"], 1, 0.82, 0, true)
   else
    local money = self:GetText()
    if tonumber(money) then
     GameTooltip:AddLine(L["自动出价"], 1, 1, 1, true)
     GameTooltip:AddLine(L["心理价格："] .. wa.FormatNumber(money), 1, 1, 1, true)
    else
     GameTooltip:AddLine(L["自动出价"], 1, 1, 1, true)
    end
    GameTooltip:AddLine(L["如果别人出价比你高时，自动帮你出价，每次加价为最低幅度，出价不会高于你设定的心理价格。"], 1, 0.82, 0, true)
   end
   GameTooltip:Show()
   self.isOnEnter = true
  end
  function wa.AutoButton_OnClick(self)
   local entryFrame = self.owner
   if not entryFrame.autoButton:IsEnabled() then return end
   if entryFrame.isAuto then
    entryFrame.isAuto = false
    entryFrame.autoSendDelayFrame:SetScript("OnUpdate", nil)
    entryFrame.autoTitleText:SetText(L["设置心理价格"])
    entryFrame.autoTitleText:SetTextColor(1, .82, 0)
    entryFrame.isAutoTex:Hide()
    entryFrame.autoButton:SetText(L["开启自动出价"])
    entryFrame.autoMoneyEdit.Left:SetAlpha(1)
    entryFrame.autoMoneyEdit.Right:SetAlpha(1)
    entryFrame.autoMoneyEdit.Middle:SetAlpha(1)
    entryFrame.autoTextButton:SetWidth(entryFrame.autoTextButton:GetFontString():GetWidth())
    entryFrame.autoMoneyEdit:SetTextColor(1, 1, 1)
    entryFrame.autoMoneyEdit:SetEnabled(true)
    entryFrame.autoMoneyEdit.isLocked = false
    entryFrame.hide:Enable()
   else
    entryFrame.isAuto = true
    entryFrame.autoTitleText:SetText(L["心理价格"])
    entryFrame.autoTitleText:SetTextColor(0, 1, 0)
    entryFrame.isAutoTex:Show()
    entryFrame.autoButton:SetText(L["取消自动出价"])
    entryFrame.autoMoneyEdit:ClearFocus()
    entryFrame.autoMoneyEdit.Left:SetAlpha(entryFrame.autoMoneyEdit.alpha)
    entryFrame.autoMoneyEdit.Right:SetAlpha(entryFrame.autoMoneyEdit.alpha)
    entryFrame.autoMoneyEdit.Middle:SetAlpha(entryFrame.autoMoneyEdit.alpha)
    entryFrame.autoTextButton:SetWidth(entryFrame.autoTextButton:GetFontString():GetWidth())
    entryFrame.autoMoneyEdit:SetTextColor(0, 1, 0)
    entryFrame.autoMoneyEdit:SetEnabled(false)
    entryFrame.autoMoneyEdit.isLocked = true
    wa.AutoSendMyMoney(entryFrame)
    entryFrame.hide:Disable()
   end
   wa.UpdateAllOnEnters()
   PlaySound(wa.sound1)
  end
  function wa.AutoButton_OnEnter(self)
   local entryFrame = self.owner
   GameTooltip:SetOwner(entryFrame.autoFrame, "ANCHOR_BOTTOM", 0, 0)
   GameTooltip:ClearLines()
   GameTooltip:AddLine(entryFrame.autoButton.onEnterText, 1, 0, 0, true)
   GameTooltip:Show()
  end
 local function NextAutoBid(entryFrame, priceCap)
   if entryFrame.start then
    return entryFrame.money
   end
   local candidate = wa.Addmoney(entryFrame.money, "+")
   if candidate > priceCap and entryFrame.money < priceCap then
    if wa.TooSmallMoney(priceCap, entryFrame.money) then
     return nil
    end
    candidate = priceCap
   end
   return candidate
  end
  function wa.AutoSendMyMoney(entryFrame)
   if entryFrame.IsEnd or not entryFrame.isAuto or entryFrame.isPaused then return end
   if wa.IsMe(entryFrame) then return end
   local nextAmount = NextAutoBid(entryFrame, entryFrame.autoMoney)
   if nextAmount and nextAmount <= entryFrame.autoMoney then
    wa.SendMyMoneyMsg(entryFrame, nextAmount)
    -- 重建 ticker 前先取消旧 ticker，防堆叠
    if entryFrame.autoTimer then
     entryFrame.autoTimer:Cancel()
    end
    entryFrame.autoTimer = C_Timer.NewTicker(3, function()
     -- 回调开头自检，任一条件变化即取消并退出
     if entryFrame.IsEnd or not entryFrame.isAuto or entryFrame.isPaused or wa.IsMe(entryFrame) then
      if entryFrame.autoTimer then
       entryFrame.autoTimer:Cancel()
      end
      return
     end
     wa.AutoSendMyMoney(entryFrame)
    end)
   end
  end
  function wa.AutoSendEndPlaySound()
   if BiaoGe and BiaoGe.options and BiaoGe.options.autoAuctionAutoEndTips == 1 then
    BG.PlaySound("autoAuctionAutoEndTips")
   end
  end
  function wa.AutoSendLate()
   if BiaoGe and BiaoGe.options and BiaoGe.options.aotoSendLate == 1 then
    local delay = tonumber(BiaoGe.Auction.aotoSendLate)
    if delay then
     delay = min(max(delay, 1), 5)
     delay = random(1 * 10, delay * 10) / 10
     return delay
    end
   end
   if BG and BG.IsTitan then
    return 1.5 + random(-5, 5) / 100
   end
   return 0.5 + random(-5, 5) / 100
  end
 end
 function wa.SetEndState(entryFrame, text, r, g, b, barNotHide)
  if not entryFrame.endText then
   entryFrame.endText = entryFrame.itemFrame2:CreateFontString()
   entryFrame.endText:SetFont(typeface, 30, "OUTLINE")
   entryFrame.endText:SetPoint("TOPRIGHT", entryFrame.itemFrame, "BOTTOMRIGHT", -10, -5)
  end
  entryFrame.endText:SetText(text)
  entryFrame.endText:SetTextColor(r, g, b)
  entryFrame.remainingTime:Hide()
  if not barNotHide then
   entryFrame.bar:Hide()
  end
  entryFrame.IsEnd = true
  entryFrame.autoSendDelayFrame:SetScript("OnUpdate", nil)
  entryFrame.myMoneyEdit:Hide()
  entryFrame.cancelButton:Hide()
  entryFrame.hide:Disable()
  wa.UpdateButtonState(entryFrame)
  return entryFrame.endText
 end
 local function hasWinner(entryFrame)
  return entryFrame.player and entryFrame.player ~= ""
 end
 local function updateEndState(entryFrame)
  if hasWinner(entryFrame) then
   wa.SetEndState(entryFrame, L["拍卖成功"], 0, 1, 0)
   if entryFrame.IsSmallWindow then
    entryFrame.currentMoneyText:SetText("|cff00FF00" .. wa.FormatNumber(entryFrame.money))
   else
    entryFrame.currentMoneyText:SetText(L["|cff00FF00成交价：|r"] .. wa.FormatNumber(entryFrame.money))
   end
   if entryFrame.player == wa.GN() then
    entryFrame.topMoneyText:SetText(L["|cff00FF00买家：|r"] .. "|cff" .. wa.GREEN1 .. L[">> 你 <<"])
   else
    entryFrame.topMoneyText:SetText(L["|cff00FF00买家：|r"] .. entryFrame.colorplayer)
   end
   if wa.IsRaidLeader() then
    After(.2, function()
     if not wa.InBoss() then
      SendGateway.Chat(format(L["{rt6}拍卖成功{rt6} %s %s %s"], entryFrame.link, entryFrame.player, entryFrame.money), "RAID")
     end
    end)
   end
   if BG and BG.AuctionWAEnd then
    BG.AuctionWAEnd(1, entryFrame.link, entryFrame.player, entryFrame.money, entryFrame.logs)
   end
  else
   wa.SetEndState(entryFrame, L["流拍"], 1, 0, 0)
   if entryFrame.IsSmallWindow then
    entryFrame.currentMoneyText:SetText(L["|cffFF0000流拍"])
   else
    entryFrame.currentMoneyText:SetText(L["|cffFF0000流拍：|r"] .. wa.FormatNumber(entryFrame.money))
   end
   entryFrame.topMoneyText:SetText("")
   if wa.IsRaidLeader() then
    if not wa.InBoss() then
     SendGateway.Chat(format(L["{rt7}流拍{rt7} %s"], entryFrame.link), "RAID")
    end
   end
   if BG and BG.AuctionWAEnd then
    BG.AuctionWAEnd(2, entryFrame.link, entryFrame.player, entryFrame.money)
   end
  end
  After(wa.HIDEFRAME_TIME, function()
   wa.UpdateFrame(entryFrame)
  end)
 end
 local function secondsLeft(entryFrame)
  return tonumber(format("%.3f", entryFrame.endTime - wa.Now()))
 end
 function wa.Auctioning(entryFrame, duration)
  entryFrame.bar:Show()
  entryFrame.endTime = wa.Now() + duration
  entryFrame.bar:SetScript("OnUpdate", function(self, elapsed)
   local remaining = secondsLeft(entryFrame)
   if entryFrame.isPaused then
    return
   end
   local ratio = remaining / duration
   local sender, max = entryFrame.bar:GetMinMaxValues()
   local entry = ratio * max
   entryFrame.bar:SetValue(entry)
   if remaining <= 10 then
    entryFrame.bar:SetStatusBarColor(1, 0, 0, 0.6)
    entryFrame.remainingTime:SetTextColor(1, 0, 0)
    entryFrame.remainingTime:SetFont(typeface, 20, "OUTLINE")
   else
    entryFrame.bar:SetStatusBarColor(1, 1, 0, 0.6)
    entryFrame.remainingTime:SetTextColor(1, 1, 1)
    entryFrame.remainingTime:SetFont(typeface, 15, "OUTLINE")
   end
   entryFrame.remainingTime:SetText((remaining <= 0 and 0 or (format("%d", remaining) + 1)) .. "s")
   entryFrame.remaining = remaining
   if remaining <= 1 then
    entryFrame.myMoneyEdit:Hide()
   end
   if remaining <= -0.5 then
    updateEndState(entryFrame)
   end
  end)
 end
 function wa.RefreshTimer(entryFrame)
  if entryFrame.IsEnd or entryFrame.isPaused then return end
  if entryFrame.remaining and entryFrame.remaining <= entryFrame.resetThreshold then
   wa.Auctioning(entryFrame, entryFrame.resetThreshold)
  end
 end
end)
