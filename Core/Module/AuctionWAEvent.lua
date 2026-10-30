if BG.IsBlackListPlayer then return end
local addonName, ns = ...
local LibBG = ns.LibBG
local L = ns.L
local C = ns.Protocol
local SendGateway = ns.SendGateway
local print = print
local After = C_Timer.After
local LibCustomGlow = LibStub("LibCustomGlow-1.0")
local previewAuctionID = -1
BG.Init(function()
 local typeface = BIAOGE_TEXT_FONT or STANDARD_TEXT_FONT
 local wa = BGA.aura_env
 local Wire = wa.Wire
 local auctionIdKey = Wire.auctionIdKey
 local function AcceptsBid(slot, money)
  return slot.start and money >= slot.money or money > slot.money
 end
 local function buildTopButton(ownerFrame, spec)
  local btn = CreateFrame("Button", nil, ownerFrame)
  btn:SetNormalFontObject(BGA.FontGreen15)
  btn:SetHighlightFontObject(BGA.FontWhite15)
  btn:SetDisabledFontObject(BGA.FontDis15)
  if spec.anchor then
   btn:SetPoint(spec.anchor, spec.x, spec.y)
  end
  if spec.text then
   btn:SetText(spec.text)
   btn:SetSize(btn:GetFontString():GetWidth(), 18)
  end
  if spec.levelOffset then
   btn:SetFrameLevel(btn:GetParent():GetFrameLevel() + spec.levelOffset)
  end
  if spec.clickType then
   btn:RegisterForClicks(spec.clickType)
  end
  if spec.offset then
   btn.offset = spec.offset
  end
  btn.owner = ownerFrame
  if spec.onClick then
   btn:SetScript("OnClick", spec.onClick)
  end
  if spec.onEnter then
   btn:SetScript("OnEnter", spec.onEnter)
  end
  if spec.onLeave then
   btn:SetScript("OnLeave", spec.onLeave)
  end
  return btn
 end
 local function createMenuItem(parentFrame, text, onClickFunc)
  local button = CreateFrame("Button", nil, parentFrame)
  button:SetNormalFontObject(BGA.FontWhite15)
  button:SetText(text)
  local label = button:GetFontString()
  local width = label:GetWidth() + 30
  label:SetJustifyH("LEFT")
  button:SetSize(width, 20)
  button:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, -(#parentFrame.buttons * 20 + 10))
  button.owner = parentFrame.owner
  tinsert(parentFrame.buttons, button)
  parentFrame:SetHeight(#parentFrame.buttons * 20 + 20)
  parentFrame:SetWidth(max(width, parentFrame:GetWidth() or 0))
  if onClickFunc then
   label:SetTextColor(1, 1, 1)
   button:SetScript("OnClick", function(self)
    onClickFunc(self)
    parentFrame:Hide()
   end)
   local highlightTex = button:CreateTexture()
   highlightTex:SetAllPoints()
   highlightTex:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
   highlightTex:SetVertexColor(1, .82, 0)
   button:SetHighlightTexture(highlightTex)
  else
   label:SetTextColor(1, .82, 0)
   button:Disable()
  end
  return button
 end
 function wa.ShowMenu(self)
  local slot = self.owner
  if slot.menuFrame and slot.menuFrame:IsVisible() then
   slot.menuFrame:Hide()
   return
  end
  if not slot.menuFrame then
   local menuFrame = CreateFrame("Frame", nil, slot, "BackdropTemplate")
   menuFrame:SetBackdrop({
    bgFile = "Interface/ChatFrame/ChatFrameBackground",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
   })
   menuFrame:SetBackdropColor(0, 0, 0, 1)
   menuFrame:SetBackdropBorderColor(1, 1, 1, 1)
   menuFrame:SetFrameLevel(slot:GetFrameLevel() + 20)
   menuFrame:SetPoint("BOTTOM", self, "TOP", 0, -1)
   menuFrame:EnableMouse(true)
   menuFrame:SetClampedToScreen(true)
   menuFrame.buttons = {}
   menuFrame.owner = slot
   slot.menuFrame = menuFrame
   menuFrame:SetScript("OnUpdate", function()
    if not self:IsMouseOver() and not menuFrame:IsMouseOver() then
     menuFrame:Hide()
    end
   end)
  end
  slot.menuFrame:Show()
  for i = #slot.menuFrame.buttons, 1, -1 do
   local menuItem = slot.menuFrame.buttons[i]
   menuItem:Hide()
   menuItem:SetParent(nil)
   tremove(slot.menuFrame.buttons, i)
  end
  createMenuItem(slot.menuFrame, L["更多操作"])
  createMenuItem(slot.menuFrame, L["取消拍卖"], wa.Cancel_OnClick)
  createMenuItem(slot.menuFrame, slot.isPaused and L["恢复拍卖"] or L["暂停拍卖"], wa.Pause_OnClick)
  for i, menuItem in ipairs(slot.menuFrame.buttons) do
   local width = slot.menuFrame:GetWidth()
   menuItem:SetWidth(width)
   menuItem:GetFontString():SetWidth(width - 30)
  end
 end
 function wa.CreateAuction(auctionKey, itemID, money, duration, player, mod, link, resetThreshold, isGen2, isPreview)
  for minLevel, slot in pairs(BGA.Frames) do
   if slot[auctionIdKey] == auctionKey then
    return
   end
  end
  local itemName, link, rarity, itemLevel, minLevel, itemType, itemSubType, minLevel, equipLoc, icon,
  minLevel, sellPrice, classID, subclassID = GetItemInfo(link or itemID)
  local panel
  mod = isGen2 and mod or "normal"
  do
   local slot = CreateFrame("Frame", nil, BGA.AuctionMainFrame, "BackdropTemplate")
   slot:SetBackdrop({
    bgFile = "Interface/ChatFrame/ChatFrameBackground",
    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
    edgeSize = wa.edgeSize,
   })
   slot:SetBackdropColor(unpack(wa.backdropColor))
   slot:SetBackdropBorderColor(unpack(wa.backdropBorderColor))
   slot:SetSize(wa.WIDTH, wa.HEIGHT)
   if #BGA.Frames == 0 then
    slot:SetPoint("TOP")
    slot.num = 1
   else
    for i = 1, wa.maxNumFrame do
     if not BGA.Frames[i] then
      slot.num = i
      slot:SetPoint("TOP", 0, -wa.GetFrameTotolHeight(slot.num))
      break
     end
    end
   end
   slot:EnableMouse(true)
   slot[auctionIdKey] = auctionKey
   slot.itemID = itemID
   slot.link = link
   slot.mod = mod
   slot.logs = {}
   slot.resetThreshold = resetThreshold
   slot.isGen2 = isGen2
   slot.isPreview = isPreview
   panel = slot
   BGA.Frames[slot.num] = slot
   slot:SetScript("OnMouseUp", function(self)
    local mainFrame = BGA.AuctionMainFrame
    mainFrame:StopMovingOrSizing()
    if BiaoGe and BiaoGe.point then
     BiaoGe.point.Auction = { mainFrame:GetPoint(1) }
    end
    mainFrame:SetScript("OnUpdate", nil)
   end)
   slot:SetScript("OnMouseDown", function(self)
    if wa.lastFocus then
     wa.lastFocus:ClearFocus()
    end
    if BiaoGe and BiaoGe.options and BiaoGe.options.auctionMoveByShift == 1
     and not IsShiftKeyDown() then
     return
    end
    local mainFrame = BGA.AuctionMainFrame
    mainFrame:StartMoving()
    mainFrame.time = 0
    mainFrame:SetScript("OnUpdate", function(self, time)
     mainFrame.time = mainFrame.time + time
     if mainFrame.time >= 0.2 then
      mainFrame.time = 0
      for minLevel, slot in pairs(BGA.Frames) do
       if slot.itemFrame.isOnEnter then
        GameTooltip:Hide()
        slot.itemFrame:GetScript("OnEnter")(slot.itemFrame)
       end
       if slot.autoFrame:IsVisible() then
        slot.autoFrame:GetScript("OnShow")(slot.autoFrame)
       end
      end
     end
    end)
   end)
   slot.cantClickFrame = CreateFrame("Frame", nil, slot, "BackdropTemplate")
   slot.cantClickFrame:SetAllPoints()
   slot.cantClickFrame:SetFrameLevel(200)
   slot.cantClickFrame:EnableMouse(true)
   After(.6, function()
    slot.cantClickFrame:Hide()
   end)
   slot.updateFrame = CreateFrame("Frame", nil, slot, "BackdropTemplate")
   slot.updateFrame:SetBackdrop({
    bgFile = "Interface/ChatFrame/ChatFrameBackground",
   })
   slot.updateFrame:SetBackdropColor(1, 1, 1, .4)
   slot.updateFrame:SetAllPoints()
   slot.updateFrame:SetFrameLevel(150)
   slot.updateFrame.alpha = .5
   slot.updateFrame.totalTime = .4
   slot.updateFrame:Hide()
   slot.updateFrame:SetScript("OnShow", function(self)
    self.time = 0
    self:SetScript("OnUpdate", function(self, time)
     self.time = self.time + time
     local alpha = self.alpha - self.time / self.totalTime * self.alpha
     if alpha < 0 then alpha = 0 end
     self:SetAlpha(alpha)
     slot.autoFrame.updateFrame:SetAlpha(alpha)
     if self:GetAlpha() <= 0 then
      self:SetScript("OnUpdate", nil)
      self:Hide()
      slot.autoFrame.updateFrame:Hide()
     end
    end)
   end)
  end
  do
   local slot = CreateFrame("Frame", nil, panel, "BackdropTemplate")
   do
    slot:SetBackdrop({
     bgFile = "Interface/ChatFrame/ChatFrameBackground",
     edgeFile = "Interface/ChatFrame/ChatFrameBackground",
     edgeSize = wa.edgeSize,
    })
    slot:SetBackdropColor(unpack(wa.backdropColor))
    slot:SetBackdropBorderColor(unpack(wa.backdropBorderColor))
    slot:SetSize(120, 73)
    slot:EnableMouse(true)
    slot:Hide()
    slot.owner = panel
    panel.autoFrame = slot
    slot:SetScript("OnShow", function(self)
     slot:ClearAllPoints()
     if wa.IsRight(self) then
      slot:SetPoint("BOTTOMRIGHT", panel, "BOTTOMLEFT", 2, 0)
     else
      slot:SetPoint("BOTTOMLEFT", panel, "BOTTOMRIGHT", -2, 0)
     end
    end)
    slot:SetScript("OnMouseUp", function(self)
     panel:GetScript("OnMouseUp")(BGA.AuctionMainFrame)
    end)
    slot:SetScript("OnMouseDown", function(self)
     panel:GetScript("OnMouseDown")(BGA.AuctionMainFrame)
    end)
    panel.cantClickFrame.autoFrame = CreateFrame("Frame", nil, panel.cantClickFrame, "BackdropTemplate")
    panel.cantClickFrame.autoFrame:SetPoint("TOPLEFT", slot, 0, 0)
    panel.cantClickFrame.autoFrame:SetPoint("BOTTOMRIGHT", slot, 0, 0)
    panel.cantClickFrame.autoFrame:EnableMouse(true)
    After(.6, function()
     panel.cantClickFrame.autoFrame:Hide()
    end)
    slot.updateFrame = CreateFrame("Frame", nil, slot, "BackdropTemplate")
    slot.updateFrame:SetBackdrop({
     bgFile = "Interface/ChatFrame/ChatFrameBackground",
    })
    slot.updateFrame:SetBackdropColor(1, 1, 1, .3)
    slot.updateFrame:SetAllPoints()
    slot.updateFrame:SetFrameLevel(150)
    slot.updateFrame:Hide()
   end
   local label = slot:CreateFontString()
   do
    label:SetFont(typeface, 15, "OUTLINE")
    label:SetPoint("TOP", 0, -8)
    label:SetTextColor(1, 0.82, 0)
    label:SetText(L["设置心理价格"])
    panel.autoTitleText = label
   end
   local editBox = CreateFrame("EditBox", nil, slot, "InputBoxTemplate")
   do
    wa.SetEditBg(editBox)
    editBox:SetSize(slot:GetWidth() - 30, 20)
    editBox:SetPoint("BOTTOM", 2, 27)
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(true)
    editBox:SetMaxLetters(8)
    editBox.owner = panel
    editBox.alpha = .3
    panel.autoMoney = 0
    panel.autoMoneyEdit = editBox
    editBox:SetScript("OnTextChanged", wa.Auto_OnTextChanged)
    editBox:SetScript("OnEnterPressed", wa.AutoButton_OnClick)
    editBox:SetScript("OnEnter", wa.AutoEdit_OnEnter)
    editBox:SetScript("OnLeave", wa.OnLeave)
    editBox:SetScript("OnEditFocusGained", wa.OnEditFocusGained)
    local slot = CreateFrame("Frame", nil, editBox)
    slot:SetPoint("RIGHT", 12, 2)
    slot:SetSize(25, 25)
    slot:Hide()
    panel.isAutoTex = slot
    local textureObj = slot:CreateTexture()
    textureObj:SetAllPoints()
    textureObj:SetTexture("interface/raidframe/readycheck-ready")
    textureObj:SetAlpha(1)
   end
   local autoButton = CreateFrame("Button", nil, slot, "UIPanelButtonTemplate")
   do
    autoButton:SetPoint("BOTTOM", 0, 5)
    autoButton:SetSize(slot:GetWidth() - 20, 22)
    autoButton:SetText(L["开启自动出价"])
    autoButton:Disable()
    autoButton.owner = panel
    panel.autoButton = autoButton
    autoButton:SetScript("OnClick", wa.AutoButton_OnClick)
    local autoMenuFrame = CreateFrame("Frame", nil, panel.autoButton)
    autoMenuFrame:SetAllPoints()
    autoMenuFrame:Hide()
    autoMenuFrame.dis = true
    autoMenuFrame.owner = panel
    autoMenuFrame:SetScript("OnEnter", wa.AutoButton_OnEnter)
    autoMenuFrame:SetScript("OnLeave", GameTooltip_Hide)
    panel.autoButton.disf = autoMenuFrame
   end
   panel.autoSendDelayFrame = CreateFrame("Frame", nil, panel)
  end
  do
   panel.hide = buildTopButton(panel, {
    anchor = "TOPRIGHT", x = -wa.edgeSize - 1, y = -2,
    text = L["折叠"], levelOffset = 15, clickType = "AnyUp",
    onClick = wa.Hide_OnClick, onEnter = wa.Hide_OnEnter, onLeave = wa.OnLeave,
   })
   panel.logTextButton = buildTopButton(panel, {
    anchor = "TOPLEFT", x = wa.edgeSize + 1, y = -2,
    text = L["记录"], onEnter = wa.LogTextButton_OnEnter, onLeave = wa.OnLeave,
   })
   panel.cancelButton = buildTopButton(panel, { onClick = wa.Cancel_OnClick })
   if panel.isGen2 then
    local autoButton = CreateFrame("Button", nil, panel)
    autoButton:SetNormalFontObject(BGA.FontGreen15)
    autoButton:SetHighlightFontObject(BGA.FontWhite15)
    autoButton:SetDisabledFontObject(BGA.FontDis15)
    autoButton:SetPoint("TOP", panel, "TOPLEFT", wa.WIDTH / 10 * 5, -2)
    autoButton.owner = panel
    panel.puaseButton = autoButton
    autoButton:SetScript("OnClick", wa.Pause_OnClick)
   end
   panel.autoTextButton = buildTopButton(panel, {
    offset = wa.WIDTH / 10 * 6.4, onClick = wa.AutoText_OnClick,
   })
   wa.UpdateButtonState(panel)
  end
  do
   local slot = CreateFrame("Frame", nil, panel, "BackdropTemplate")
   slot:SetPoint("TOPLEFT", slot:GetParent(), "TOPLEFT", wa.edgeSize + 1, -panel.hide:GetHeight() - 3)
   slot:SetPoint("BOTTOMRIGHT", slot:GetParent(), "TOPRIGHT", -wa.edgeSize, -55)
   slot:SetFrameLevel(slot:GetParent():GetFrameLevel() + 10)
   slot.owner = panel
   slot.itemID = itemID
   slot.link = link
   slot:SetScript("OnEnter", wa.itemOnEnter)
   slot:SetScript("OnLeave", wa.itemOnLeave)
   slot:SetScript("OnMouseUp", function(self)
    panel:GetScript("OnMouseUp")(BGA.AuctionMainFrame)
   end)
   slot:SetScript("OnMouseDown", function(self)
    if IsShiftKeyDown() then
     if not GetCurrentKeyBoardFocus() then
      ChatEdit_ActivateChat(ChatEdit_ChooseBoxForSend())
     end
     ChatEdit_InsertLink(link)
    elseif IsControlKeyDown() then
     DressUpItemLink(link)
    else
     panel:GetScript("OnMouseDown")(BGA.AuctionMainFrame)
    end
   end)
   panel.itemFrame = slot
   local itemFrame2 = CreateFrame("Frame", nil, slot)
   panel.itemFrame2 = itemFrame2
   local textureObj = slot:CreateTexture(nil, "BACKGROUND")
   textureObj:SetAllPoints()
   textureObj:SetColorTexture(0, 0, 0, 0.5)
   panel.itemFrame.bg = textureObj
   local qualityR, qualityG, qualityB = GetItemQualityColor(rarity)
   local itemFrame = CreateFrame("Frame", nil, slot, "BackdropTemplate")
   itemFrame:SetBackdrop({
    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
    edgeSize = 2,
   })
   itemFrame:SetBackdropBorderColor(qualityR, qualityG, qualityB, 1)
   itemFrame:SetPoint("TOPLEFT", slot, "TOPLEFT", 0, 0)
   itemFrame:SetPoint("BOTTOMRIGHT", slot, "TOPLEFT", slot:GetHeight(), -slot:GetHeight())
   itemFrame.tex = itemFrame:CreateTexture(nil, "BACKGROUND")
   itemFrame.tex:SetAllPoints()
   itemFrame.tex:SetTexture(icon)
   itemFrame.tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
   itemFrame.color = { qualityR, qualityG, qualityB }
   panel.itemFrame.iconFrame = itemFrame
   local label = itemFrame2:CreateFontString()
   label:SetFont(typeface, 12, "OUTLINE")
   label:SetPoint("BOTTOM", itemFrame, "BOTTOM", 0, 1)
   label:SetText(itemLevel)
   label:SetTextColor(qualityR, qualityG, qualityB)
   panel.itemFrame.levelText = label
   if subclassID == 2 then
    local label = itemFrame2:CreateFontString()
    label:SetFont(typeface, 11, "OUTLINE")
    label:SetPoint("TOP", itemFrame, 0, -2)
    label:SetText(L["装绑"])
    label:SetTextColor(0, 1, 0)
    panel.itemFrame.bindTypeText = label
   end
   local label = slot:CreateFontString()
   label:SetFont(typeface, 15, "OUTLINE")
   label:SetPoint("TOPLEFT", itemFrame, "TOPRIGHT", 2, -2)
   label:SetWidth(slot:GetWidth() - slot:GetHeight() - 50)
   label:SetText(link:gsub("%[", ""):gsub("%]", ""))
   label:SetJustifyH("LEFT")
   label:SetWordWrap(false)
   panel.itemFrame.itemNameText = label
   if BG and BG.GetItemCount and BG.GetItemCount(itemID) ~= 0 or GetItemCount(itemID, true) ~= 0 then
    local textureObj = itemFrame2:CreateTexture(nil, "ARTWORK")
    textureObj:SetSize(15, 15)
    textureObj:SetPoint("LEFT", label, "LEFT", label:GetWrappedWidth(), 0)
    textureObj:SetTexture("interface/raidframe/readycheck-ready")
    local textureObj = itemFrame:CreateTexture(nil, "ARTWORK")
    textureObj:SetAllPoints()
    textureObj:SetTexture("interface/raidframe/readycheck-ready")
    panel.itemFrame.havedTex = textureObj
   end
   local label = itemFrame2:CreateFontString()
   label:SetFont(typeface, 12, "OUTLINE")
   label:SetPoint("BOTTOMLEFT", itemFrame, "BOTTOMRIGHT", 2, 2)
   label:SetHeight(13)
   label:SetWidth(panel.itemFrame.itemNameText:GetWidth())
   local tooltipClassText = BG and BG.GetTooltipClassText and BG.GetTooltipClassText(itemID) or ""
   if _G[equipLoc] then
    if sellPrice == 2 then
     label:SetText(itemSubType .. "  " .. tooltipClassText)
    else
     label:SetText(_G[equipLoc] .. " " .. itemSubType .. "  " .. tooltipClassText)
    end
   else
    label:SetText(tooltipClassText)
   end
   label:SetJustifyH("LEFT")
   panel.itemFrame.itemTypeText = label
   local statusBar = CreateFrame("StatusBar", nil, slot)
   statusBar:SetPoint("TOPLEFT", itemFrame, "TOPRIGHT", 0, 0)
   statusBar:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 0, 0)
   statusBar:SetFrameLevel(statusBar:GetParent():GetFrameLevel())
   statusBar:SetStatusBarTexture("Interface/ChatFrame/ChatFrameBackground")
   statusBar:SetStatusBarColor(1, 1, 0, 0.6)
   statusBar:SetMinMaxValues(0, 1000)
   statusBar.owner = panel
   panel.bar = statusBar
   local fontString2 = itemFrame2:CreateFontString()
   fontString2:SetFont(typeface, 15, "OUTLINE")
   fontString2:SetPoint("RIGHT", slot, "RIGHT", -5, 0)
   fontString2:SetTextColor(1, 1, 1)
   panel.remainingTime = fontString2
  end
  do
   local width = 190
   local offset = 25
   local height = 22
   local slot = CreateFrame("Frame", nil, panel)
   slot:SetSize(width, 20)
   slot:SetPoint("TOPLEFT", panel.itemFrame, "BOTTOMLEFT", 3, -3)
   slot:SetFrameLevel(slot:GetParent():GetFrameLevel() + 11)
   slot:SetScript("OnMouseDown", wa.currentMoney_OnMouseDown)
   slot:SetScript("OnMouseUp", wa.currentMoney_OnMouseUp)
   slot.owner = panel
   local label = slot:CreateFontString()
   label:SetFont(typeface, 14, "OUTLINE")
   label:SetAllPoints()
   label:SetJustifyH("LEFT")
   if player and player ~= "" then
    label:SetText(L["|cffFFD100当前价格：|r"] .. wa.FormatNumber(money))
    panel.start = false
   else
    label:SetText(L["|cffFFD100起拍价：|r"] .. wa.FormatNumber(money))
    panel.start = true
   end
   local prevFrame = slot
   panel.currentMoneyFrame = slot
   panel.currentMoneyText = label
   panel.money = money
   local slot = CreateFrame("Frame", nil, prevFrame)
   slot:SetSize(width, height)
   slot:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", 0, 0)
   local label = slot:CreateFontString()
   label:SetFont(typeface, 14, "OUTLINE")
   label:SetAllPoints()
   label:SetJustifyH("LEFT")
   if player then
    panel.player = player
    panel.colorplayer = wa.SetClassCFF(player)
   end
   if player and player ~= "" then
    if player == wa.GN() then
     label:SetText(L["|cffFFD100出价最高者：|r"] .. "|cff" .. wa.GREEN1 .. L[">> 你 <<"])
     panel:SetBackdropColor(unpack(wa.backdropColor_IsMe))
     panel:SetBackdropBorderColor(unpack(wa.backdropBorderColor_IsMe))
     panel.autoFrame:SetBackdropColor(unpack(wa.backdropColor_IsMe))
     panel.autoFrame:SetBackdropBorderColor(unpack(wa.backdropBorderColor_IsMe))
    else
     label:SetText(L["|cffFFD100出价最高者：|r"] .. panel.colorplayer)
     panel:SetBackdropColor(unpack(wa.backdropColor))
     panel:SetBackdropBorderColor(unpack(wa.backdropBorderColor))
     panel.autoFrame:SetBackdropColor(unpack(wa.backdropColor))
     panel.autoFrame:SetBackdropBorderColor(unpack(wa.backdropBorderColor))
    end
   end
   panel.topMoneyFrame = slot
   panel.topMoneyText = label
   local editBox = CreateFrame("EditBox", nil, prevFrame, "InputBoxTemplate")
   wa.SetEditBg(editBox)
   editBox:SetSize(panel:GetRight() - prevFrame:GetRight() - 3, 20)
   editBox:SetPoint("TOPLEFT", prevFrame, "TOPRIGHT", 0, 0)
   editBox:SetAutoFocus(false)
   editBox:SetNumeric(true)
   editBox:SetText(money)
   editBox:SetMaxLetters(8)
   editBox.owner = panel
   editBox:SetScript("OnTextChanged", wa.myMoney_OnTextChanged)
   editBox:SetScript("OnEnterPressed", wa.SendMyMoney_OnClick)
   editBox:SetScript("OnMouseWheel", wa.myMoney_OnMouseWheel)
   editBox:SetScript("OnEnter", wa.myMoney_OnEnter)
   editBox:SetScript("OnLeave", wa.OnLeave)
   editBox:SetScript("OnEditFocusGained", wa.OnEditFocusGained)
   panel.myMoneyEdit = editBox
   local autoButton = CreateFrame("Button", nil, editBox, "UIPanelButtonTemplate")
   autoButton:SetSize(offset, 22)
   autoButton:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", -5, 0)
   autoButton:SetNormalFontObject(BGA.FontGold18)
   autoButton:SetDisabledFontObject(BGA.FontDis18)
   autoButton.owner = panel
   autoButton.edit = editBox
   autoButton._type = "-"
   autoButton:SetText(autoButton._type)
   autoButton:SetScript("OnMouseDown", wa.JiaJian_OnMouseDown)
   autoButton:SetScript("OnMouseUp", wa.JiaJian_OnMouseUp)
   autoButton:SetScript("OnClick", wa.JiaJian_OnClick)
   autoButton:SetScript("OnEnter", wa.JiaJian_OnEnter)
   autoButton:SetScript("OnLeave", wa.OnLeave)
   panel.ButtonJian = autoButton
   local autoButton = CreateFrame("Button", nil, editBox, "UIPanelButtonTemplate")
   autoButton:SetSize(offset, 22)
   autoButton:SetPoint("LEFT", panel.ButtonJian, "RIGHT", 0, 0)
   autoButton:SetNormalFontObject(BGA.FontGold18)
   autoButton:SetDisabledFontObject(BGA.FontDis18)
   autoButton.owner = panel
   autoButton.edit = editBox
   autoButton._type = "+"
   autoButton:SetText(autoButton._type)
   autoButton:SetScript("OnMouseDown", wa.JiaJian_OnMouseDown)
   autoButton:SetScript("OnMouseUp", wa.JiaJian_OnMouseUp)
   autoButton:SetScript("OnClick", wa.JiaJian_OnClick)
   autoButton:SetScript("OnEnter", wa.JiaJian_OnEnter)
   autoButton:SetScript("OnLeave", wa.OnLeave)
   panel.ButtonJia = autoButton
   local autoButton = CreateFrame("Button", nil, editBox, "UIPanelButtonTemplate")
   autoButton:SetPoint("TOPLEFT", panel.ButtonJia, "TOPRIGHT", 0, 0)
   autoButton:SetPoint("BOTTOMRIGHT", editBox, "BOTTOMRIGHT", 0, -height)
   autoButton:SetText(L["出价"])
   autoButton.owner = panel
   autoButton.edit = editBox
   autoButton.itemID = itemID
   panel.ButtonSendMyMoney = autoButton
   autoButton:SetScript("OnClick", wa.SendMyMoney_OnClick)
   autoButton:SetScript("OnEnter", wa.SendMyMoney_OnEnter)
   autoButton:SetScript("OnLeave", wa.OnLeave)
   local slot = CreateFrame("Frame", nil, autoButton)
   slot:SetAllPoints()
   slot:Hide()
   slot.dis = true
   slot.owner = panel
   slot:SetScript("OnEnter", wa.SendMyMoneyDis_OnEnter)
   slot:SetScript("OnLeave", GameTooltip_Hide)
   panel.disf = slot
   autoButton.disf = slot
   wa.myMoney_OnTextChanged(panel.myMoneyEdit)
  end
  wa.anim(panel)
  if not isPreview then
   wa.Auctioning(panel, duration)
  end
  if BG and BG.HookCreateAuction then
   BG.HookCreateAuction(panel)
  end
  if isPreview then
   panel.remainingTime:SetText(L["预览"])
   panel.remainingTime:SetTextColor(0, 1, 0)
   panel.bar:Show()
   panel.bar:SetValue(700)
   panel.myMoneyEdit:Disable()
   panel.ButtonJian:Disable()
   panel.ButtonJia:Disable()
   panel.ButtonSendMyMoney:Disable()
   panel.autoMoneyEdit:Disable()
   panel.autoButton:Disable()
   panel.cancelButton:Hide()
   if panel.puaseButton then panel.puaseButton:Hide() end
   panel.autoTextButton:Hide()
   panel.logTextButton:Hide()
   panel.hide:Hide()
   panel.cantClickFrame:Hide()
   panel.cantClickFrame.autoFrame:Hide()

   local previewText = panel:CreateFontString()
   previewText:SetFont(typeface, 14, "OUTLINE")
   previewText:SetPoint("TOP", 0, -3)
   previewText:SetText(L["心愿拍卖预览"])
   previewText:SetTextColor(0.2, 1, 0.2)

   local closeButton = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
   closeButton:SetPoint("TOPRIGHT", 4, 4)
   closeButton:SetFrameLevel(panel:GetFrameLevel() + 210)
   local function ClosePreview()
    if panel.previewClosed then return end
    panel.previewClosed = true
    for index, candidate in pairs(BGA.Frames) do
     if candidate == panel then
      BGA.Frames[index] = nil
      break
     end
    end
    panel.autoFrame:Hide()
    LibCustomGlow.PixelGlow_Stop(panel)
    panel:Hide()
    if BG.WishlistAuctionPreviewFrame == panel then
     BG.WishlistAuctionPreviewFrame = nil
    end
    wa.UpdateAllFrames()
   end
   panel.ClosePreview = ClosePreview
   closeButton:SetScript("OnClick", ClosePreview)
   panel.previewCloseButton = closeButton
   BG.WishlistAuctionPreviewFrame = panel
  end
  return panel
 end

 function BG.ShowWishlistAuctionPreview(itemID, link)
  if BG.WishlistAuctionPreviewFrame and BG.WishlistAuctionPreviewFrame.ClosePreview then
   BG.WishlistAuctionPreviewFrame.ClosePreview()
  end
  previewAuctionID = previewAuctionID - 1
  return wa.CreateAuction(previewAuctionID, itemID, 1000, 30, nil, "normal", link, 20, true, true)
 end
 do
  local slot = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  slot:SetSize(wa.WIDTH, wa.HEIGHT)
  if BiaoGe and BiaoGe.options and BiaoGe.options.autoAuctionFrameLevel then
   slot:SetFrameStrata(BiaoGe.options.autoAuctionFrameLevel)
  else
   slot:SetFrameStrata("HIGH")
  end
  slot:SetClampedToScreen(true)
  slot:SetFrameLevel(100)
  slot:SetToplevel(true)
  slot:SetMovable(true)
  slot:SetScale(BiaoGe and BiaoGe.options and BiaoGe.options["autoAuctionScale"] or 0.9)
  BGA.AuctionMainFrame = slot
  if BiaoGe and BiaoGe.point and BiaoGe.point.Auction then
   BiaoGe.point.Auction[2] = nil
   slot:SetPoint(unpack(BiaoGe.point.Auction))
  else
   slot:SetPoint("TOPRIGHT", -100, -200)
  end
 end
 local function getModLabel(link)
  local modLabel = ""
  return modLabel
 end
 local function eventHandler(self, event, ...)
  if event == "CHAT_MSG_ADDON" then
   local channelPrefix, payload, channelScope, vendor, line = ...
   local command, auctionKeyText, itemIdText, moneyText, durationText, playerText, modText, linkText, resetText, trailing
   local isGen2
   if channelPrefix == wa.AddonChannel then
    command, auctionKeyText, itemIdText, moneyText, durationText, playerText, modText, linkText = strsplit(Wire.separatorGen1, payload, Wire.fieldCountGen1)
   elseif channelPrefix:match(wa.AddonChannel2) then
    command, auctionKeyText, itemIdText, moneyText, durationText, playerText, modText, linkText, resetText, trailing = strsplit(Wire.separatorGen2, payload)
    isGen2 = true
   end
   if not command then return end
   if command == C.OP_START_AUCTION and channelScope == "RAID" then
    local auctionKey = tonumber(auctionKeyText)
    local itemID = tonumber(itemIdText)
    local money = tonumber(moneyText)
    local duration = tonumber(durationText)
    local player = playerText
    local mod = modText
    -- 匿名拍卖已移除：匿名 StartAuction 不创建帧，静默忽略。常规拍卖（mod=normal）不受影响。
    if mod == "anonymous" then return end
    local link = linkText ~= "" and linkText or nil
    local resetThreshold = isGen2 and tonumber(resetText) or wa.REPEAT_TIME
    BG.OnItemLoad(link or itemID):ContinueOnItemLoad(function()
     wa.CreateAuction(auctionKey, itemID, money, duration, player, mod, link, resetThreshold, isGen2)
     if wa.IsRaidLeader() then
      local vendor, link = GetItemInfo(link or itemID)
      local payload = format(L["{rt1}拍卖开始{rt1} %s 起拍价：%s"], link, money)
      local modLabel = securecall(getModLabel, link)
      if modLabel then
       if strlen(payload .. modLabel) < 255 then
        payload = payload .. modLabel
       end
      end
      SendGateway.Chat(payload, "RAID_WARNING")
     end
    end)
   elseif command == C.OP_CANCEL_AUCTION and channelScope == "RAID" then
    local auctionKey = tonumber(auctionKeyText)
    for vendor, slot in pairs(BGA.Frames) do
     if slot[auctionIdKey] == auctionKey and not slot.IsEnd then
      wa.SetEndState(slot, L["拍卖取消"], 1, 0, 0)
      if slot.IsSmallWindow then
       slot.currentMoneyText:SetText("|cffFF0000" .. L["拍卖取消"])
      end
      if wa.IsRaidLeader() then
       SendGateway.Chat(format(L["{rt7}拍卖取消{rt7} %s"], slot.link), "RAID")
      end
      if BG and BG.AuctionWAEnd then
       BG.AuctionWAEnd(3, slot.link, slot.player, slot.money)
      end
      After(wa.HIDEFRAME_TIME, function()
       wa.UpdateFrame(slot)
      end)
      return
     end
    end
   elseif command == C.OP_PAUSE_AUCTION and channelScope == "RAID" then
    local itemID = tonumber(auctionKeyText)
    for vendor, slot in pairs(BGA.Frames) do
     if slot.itemID == itemID and slot.isGen2 and not slot.IsEnd then
      wa.PauseAuction(slot)
     end
    end
   elseif command == C.OP_RESUME_AUCTION and channelScope == "RAID" then
    local itemID = tonumber(auctionKeyText)
    for vendor, slot in pairs(BGA.Frames) do
     if slot.itemID == itemID and slot.isGen2 and not slot.IsEnd then
      wa.ResumeAuction(slot)
     end
    end
   elseif command == C.OP_SEND_MY_MONEY and channelScope == "RAID" then
    local auctionKey = tonumber(auctionKeyText)
    local money = tonumber(itemIdText)
    for vendor, slot in pairs(BGA.Frames) do
     if not slot.IsEnd and not slot.isPaused and slot.mod ~= "anonymous" and slot[auctionIdKey] == auctionKey then
      if AcceptsBid(slot, money) then
       wa.SetMoney(slot, money, line)
      end
      return
     end
    end
   elseif command == C.OP_VERSION_CHECK and channelScope == "RAID" then
    SendGateway.Addon(wa.AddonChannel, C.OP_MY_VER .. "," .. wa.ver, "RAID")
   -- 匿名族三消息（AnonymousWhisperMyMoney / AnonymousSendMyMoney / AnonymousWinner）已移除。
   -- 收到外部原版发来的匿名 opcode 自然落入链尾静默丢弃（识别但忽略），不回包、不中继、不落盘。
   end
  elseif event == "GROUP_ROSTER_UPDATE" then
   local canSend = wa.canSend()
   After(0.5, function()
    wa.UpdateRaidRosterInfo(canSend)
   end)
  elseif event == "PLAYER_ENTERING_WORLD" then
   self:UnregisterEvent("PLAYER_ENTERING_WORLD")
   After(2, function()
    wa.UpdateRaidRosterInfo()
   end)
  elseif event == "MODIFIER_STATE_CHANGED" then
   local mod, type = ...
   if (mod == "LCTRL" or mod == "RCTRL") then
    if type == 1 then
     if wa.itemIsOnEnter then
      SetCursor("Interface/Cursor/Inspect")
     end
    else
     SetCursor(nil)
    end
   end
  elseif event == "CHAT_MSG_RAID_LEADER" then
   local payload = ...
   if wa.IsSecret(payload) then return end
   local item, buyer, price
   item, buyer, price = payload:match("{rt6}拍卖成功{rt6} (.-) (.-) (.+)")
   if not (item and buyer and price) then
    item, buyer, price = payload:match("{rt6}拍賣成功{rt6} (.-) (.-) (.+)")
   end
   if not (item and buyer and price) then
    item, buyer, price = payload:match("{rt6}Auction Successful{rt6} (.-) (.-) (.+)")
   end
   if (item and buyer and price) then
    return
   end
   item = payload:match("{rt7}流拍{rt7} (.+)")
   if not item then
    item = payload:match("^{rt7}Auction Failed{rt7} (.+)$")
   end
   if item then
    return
   end
  end
 end
 BGA.Event = CreateFrame("Frame")
 BGA.Event:RegisterEvent("CHAT_MSG_ADDON")
 BGA.Event:RegisterEvent("GROUP_ROSTER_UPDATE")
 BGA.Event:RegisterEvent("PLAYER_ENTERING_WORLD")
 BGA.Event:RegisterEvent("MODIFIER_STATE_CHANGED")
 BGA.Event:RegisterEvent("CHAT_MSG_RAID_LEADER")
 BGA.Event:SetScript("OnEvent", eventHandler)
end)
