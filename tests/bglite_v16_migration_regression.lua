-- Exercise real migrated modules with deterministic WoW API doubles.
format, tinsert, tremove, floor, ceil, max, min = string.format, table.insert, table.remove, math.floor, math.ceil, math.max, math.min
strlen, strmatch, strfind = string.len, string.match, string.find
strsplit = function(sep, value, limit)
    local out, offset = {}, 1
    while not limit or #out < limit - 1 do
        local i, j = value:find(sep, offset, true)
        if not i then break end
        out[#out + 1] = value:sub(offset, i - 1)
        offset = j + 1
    end
    out[#out + 1] = value:sub(offset)
    return unpack(out)
end
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
local function Equal(a, b, label) assert(a == b, (label or 'value') .. ': expected ' .. tostring(b) .. ', got ' .. tostring(a)) end
local frames, sent, registrations, initCallbacks, events = {}, {}, {}, {}, {}
local Node = {}
local function Frame(parent, name)
    local o = setmetatable({ parent = parent, name = name, scripts = {}, shown = true, enabled = true, text = '', width = 300, height = 100 }, { __index = Node })
    frames[#frames + 1] = o
    if name then _G[name] = o end
    return o
end
function Node:SetScript(name, fn) self.scripts[name] = fn end
function Node:GetScript(name) return self.scripts[name] end
function Node:HookScript(name, fn) local old=self.scripts[name]; self.scripts[name]=function(...) if old then old(...) end fn(...) end end
function Node:RegisterEvent(e) self.events = self.events or {}; self.events[e] = true end
function Node:UnregisterEvent(e) self.events[e] = nil end
function Node:GetParent() return self.parent end
function Node:GetName() return self.name end
function Node:CreateTexture() return Frame(self) end
function Node:CreateFontString() return Frame(self) end
function Node:CreateLine() return Frame(self) end
function Node:CreateAnimationGroup() return Frame(self) end
function Node:CreateAnimation() return Frame(self) end
function Node:GetNormalTexture() self.normalTexture = self.normalTexture or Frame(self); return self.normalTexture end
function Node:GetPushedTexture() return self:GetNormalTexture() end
function Node:GetHighlightTexture() return self:GetNormalTexture() end
function Node:GetDisabledTexture() return self:GetNormalTexture() end
function Node:GetFontString() return self end
function Node:SetText(v) self.text=tostring(v or '') end
function Node:SetFormattedText(f, ...) self.text=format(f, ...) end
function Node:GetText() return self.text end
function Node:GetWidth() return self.width end
function Node:GetHeight() return self.height end
function Node:GetStringWidth() return #self.text * 6 end
Node.GetWrappedWidth = Node.GetStringWidth
function Node:SetWidth(v) assert(type(v)=='number'); self.width=v end
function Node:SetHeight(v) assert(type(v)=='number'); self.height=v end
function Node:SetSize(w,h) self:SetWidth(w); self:SetHeight(h) end
function Node:SetPoint(...) self.point={...} end
function Node:SetFont(font, size) assert(type(font)=='string', 'missing font after migration'); self.font, self.fontSize=font,size end
function Node:GetRight() return 500 end
function Node:GetLeft() return 100 end
function Node:GetTop() return 500 end
function Node:GetBottom() return 100 end
function Node:GetFont() return self.font or 'Fonts/Test.ttf',self.fontSize or 15,'OUTLINE' end
function Node:GetFrameLevel() return 10 end
function Node:SetTextColor(...) self.textColor={...} end
function Node:SetStatusBarColor(...) self.barColor={...} end
function Node:SetValue(v) self.value=v end
function Node:GetValue() return self.value or 0 end
function Node:IsShown() return self.shown end
Node.IsVisible = Node.IsShown
function Node:Show() self.shown=true end
function Node:Hide() self.shown=false end
function Node:SetShown(v) self.shown=not not v end
function Node:Enable() self.enabled=true end
function Node:Disable() self.enabled=false end
function Node:SetEnabled(v) self.enabled=v end
function Node:NumLines() return 0 end
function Node:GetChecked() return self.checked end
function Node:SetChecked(v) self.checked=v end
function Node:Click() if self.scripts.OnClick then self.scripts.OnClick(self) end end
for _, method in ipairs({ 'SetDesaturated','SetColorTexture','SetBackdrop','SetBackdropColor','SetBackdropBorderColor','SetClampedToScreen','SetMovable','SetToplevel','EnableMouse','RegisterForClicks','SetNormalFontObject','SetHighlightFontObject','SetDisabledFontObject','SetFrameLevel','SetFrameStrata','SetNormalTexture','SetPushedTexture','SetHighlightTexture','SetDisabledTexture','SetTexCoord','SetTexture','SetAtlas','SetAllPoints','SetJustifyH','SetWordWrap','SetAutoFocus','SetMaxLetters','SetNumeric','SetCursorPosition','ClearFocus','ClearAllPoints','SetScale','SetAlpha','SetBlendMode','SetReverse','SetStatusBarTexture','SetMinMaxValues','SetShadowOffset','SetShadowColor','SetVertexColor','SetStartDelay','SetEndDelay','SetDuration','SetOrder','SetLooping','SetOffset','SetSmoothing','SetFromAlpha','SetToAlpha','Play','SetHitRectInsets','SetHyperlinksEnabled','SetJustifyV' }) do
    Node[method] = Node[method] or function() end
end
CreateFrame = function(kind, name, parent) local f=Frame(parent,name); f.Text=Frame(f); if kind=='ScrollFrame' then f.ScrollBar=Frame(f) end; return f end
CreateFont = function(name) return Frame(nil,name) end
UIParent, GameTooltip, BiaoGeTooltip2 = Frame(), Frame(), Frame()
BIAOGE_TEXT_FONT, STANDARD_TEXT_FONT = 'Fonts/Test.ttf', 'Fonts/Test.ttf'
SOUNDKIT = { GS_TITLE_OPTION_OK = 1 }
StaticPopupDialogs, UISpecialFrames = {}, {}
ITEM_CLASSES_ALLOWED='Classes: %s'
ERR_IGNORE_ADDED_S='Ignoring %s'
ERR_FRIEND_REMOVED_S='Removed %s'
ERR_RAID_MEMBER_REMOVED_S='%s left raid'
YES, NO, GUILD, RAID, NONE, CURRENTLY_EQUIPPED = 'Yes','No','Guild','Raid','None','Equipped'
L_DropDownList1 = Frame()
L_DropDownList1.dropdown = nil
GetBuildInfo=function() return nil,nil,nil,38002 end
GetCurrentRegion=function() return 5 end
GetUnitName=function() return 'Tester-Realm' end
GetRealmName=function() return 'Realm' end
GetRealmID=function() return 1 end
UnitFactionGroup=function() return 'Alliance','Alliance' end
UnitClass=function() return 'Mage','MAGE' end
GetItemQualityColor=function() return 0.6,0.2,0.9 end
GetClassColor=function() return 1,1,1,'ffffffff' end
GetClassInfo=function() return 'Mage','MAGE',8 end
GetTime=function() return 100 end
GetTimePreciseSec=function() return 100 end
GetServerTime=function() return 1000 end
GetLocale=function() return 'zhCN' end
IsAddOnLoaded=function() return false end
LoadAddOn=function() end
IsInRaid=function() return true end
IsInGroup=function() return true end
IsInGuild=function() return false end
UnitIsGroupLeader=function() return true end
GetNumGroupMembers=function() return 2 end
GetItemInfo=function(v) return 'Test item', '|Hitem:45087|h[Test item]|h',4,245,80,'Armor','Cloth',1,'INVTYPE_CHEST',134400,0,4,1,1 end
GetItemCount=function() return 0 end
GetItemInfoInstant=function() return 45087,nil,nil,'INVTYPE_CHEST',134400,4,1 end
GetMouseButtonClicked=function() return 'LeftButton' end
IsModifierKeyDown=function() return false end
IsShiftKeyDown=function() return false end
IsAltKeyDown=function() return false end
hooksecurefunc=function() end
securecall=function(f, ...) return f(...) end
C_Timer={ After=function() end, NewTicker=function(_, f) return { Cancel=function(self) self.cancelled=true end } end }
C_AddOns={ IsAddOnLoaded=IsAddOnLoaded, LoadAddOn=LoadAddOn }
local function Record(...)
    sent[#sent+1]={n=select('#',...),...}
    return 'sent'
end
C_ChatInfo={ SendAddonMessage=Record, RegisterAddonMessagePrefix=function(p) registrations[p]=true end }
SendChatMessage=Record
ChatThrottleLib={ SendAddonMessage=Record }
local L=setmetatable({}, {__index=function(_,k) return k end})
local lib={}
function lib:Create_UIDropDownMenu(_, parent) local f=Frame(parent);f.Text=Frame(f);return f end
for _,k in ipairs({'UIDropDownMenu_SetText','UIDropDownMenu_SetWidth','UIDropDownMenu_SetAnchor','UIDropDownMenu_Initialize','CloseDropDownMenus','UIDropDownMenu_AddButton'}) do lib[k]=function() end end
function lib:UIDropDownMenu_CreateInfo() return {} end
local glow={ PixelGlow_Start=function() end,PixelGlow_Stop=function() end }
LibStub=setmetatable({GetLibrary=function() return lib end},{__call=function() return glow end})
local ns={ L=L, LibBG=lib, RGB=function() return 1,1,1 end, Size=function(t) local n=0;for _ in pairs(t) do n=n+1 end return n end, GetClassRGB=GetClassColor, SetClassCFF=function(v) return v end, AddTexture=function() return '' end, GetItemID=function(v) return tonumber(tostring(v):match('item:(%d+)')) or tonumber(v) end, Maxb={TEST=2}, HopeMaxn={}, HopeMaxb={}, HopeMaxi=0 }
assert(loadfile('Core/Protocol/Constants.lua'))('BGForge',ns)
assert(loadfile('Core/Protocol/SendGateway.lua'))('BGForge',ns)
local C,G=ns.Protocol,ns.SendGateway
Equal(G.Addon('BiaoGe','payload','RAID'),'sent')
Equal(sent[#sent].n,3,'no phantom target')
G.WhisperAddon('BiaoGeReceive','payload','Other-Realm'); Equal(sent[#sent][3],'WHISPER'); Equal(sent[#sent][4],'Other-Realm')
G.Chat('message','RAID'); Equal(sent[#sent].n,2)
G.Chat('message','WHISPER',nil,'Other-Realm'); Equal(sent[#sent].n,4)
G.Throttled('BiaoGeReceive1','payload','WHISPER','Other-Realm'); Equal(sent[#sent][2],'NORMAL')
-- The gateway must propagate failures to its caller.
local oldSend=C_ChatInfo.SendAddonMessage
C_ChatInfo.SendAddonMessage=function() error('transport failed') end
assert(not pcall(G.Addon,'BiaoGe','payload','RAID'))
C_ChatInfo.SendAddonMessage=oldSend

-- Load the real lifecycle dispatcher. Another addon must not initialize BGForge.
assert(loadfile('Core/DB/Init.lua'))('BGForge',ns)
assert(BG.IsTitan and BG.onlyOneHard)
local initCount=0
BG.Init(function() initCount=initCount+1 end)
local lifecycle
for _,f in ipairs(frames) do if f.events and f.events.ADDON_LOADED then lifecycle=f end end
lifecycle.scripts.OnEvent(lifecycle,'ADDON_LOADED','BGLite'); Equal(initCount,0)
lifecycle.scripts.OnEvent(lifecycle,'ADDON_LOADED','bgforge'); Equal(initCount,1)
assert(not lifecycle.events.ADDON_LOADED)
-- Use an explicit initializer queue for the rest of the module tests.
BG.Init=function(f) initCallbacks[#initCallbacks+1]=f end
BG.Init2=function() end
BG.Init3=function() end
BG.RegisterEvent=function(e,f) events[e]=f end
BG.g1,BG.g2,BG.b1,BG.y2,BG.w1,BG.r1='00ff00','00cc00','00bfff','ffff00','ffffff','ff0000'
BG.MainFrame=Frame(); BG.MainFrame.CloseButton=Frame(); BG.ButtonMove=Frame()
BG.MainNavigationHeight, BG.TopLeftButtonJianGe=30,4
BG.FB1, BG.FBtable, BG.Frame, BG.Maxb='TEST',{'TEST'},{TEST={boss1={}}},ns.Maxb
BG.GetAllFB=function() return {'TEST'} end
BG.GetMaxi=function() return 1 end
BG.GetLeiTingItem=function(id) return id end
BG.LayoutMainMenuButtons=function() end
BG.After=function(_,f) end
BG.Once=function() end
BG.IsSecret=function() return false end
BG.dropDownToggle=function() end
BG.IsHope=function(id) return id==45087 end
BG.STC_g1=function(s) return s end
BG.STC_b1=BG.STC_g1
BG.STC_dis=BG.STC_g1
BG.GetItemType=function() return '' end
BG.GetVerNum=function() return 24400 end
BG.GetFBinfo=function() return 'Test' end
BG.UpdateAuctioning=function() end
BG.auctionLogFrame={auctioning={}}
BG.OnItemLoad=function() return {ContinueOnItemLoad=function(_,f) f() end} end
BG.GetTooltipClassText=function() return '' end
BG.CreateButton=function(parent) return Frame(parent) end
BG.SetButtonAtlas=function() end
BG.FrameHide=function() end
BG.Addon_OnEnter=function() end
BG.GlowInterface='Test'
BiaoGe={options={fastMoney=0},point={},Auction={gen=2,mod='normal',money=1000,fastMoney={100}}}
assert(loadfile('Core/Module/AuctionWA.lua'))('BGForge',ns)
local wa=BGA.aura_env
Equal(wa.ver,'v4.0')
for i=1,11 do Equal(wa.GetAddonChannelName(),'BiaoGeAuction'..((i-1)%10+1),'rotating channel') end
initCallbacks[1]()
assert(loadfile('Core/Module/AuctionWAEvent.lua'))('BGForge',ns)
initCallbacks[2]()
assert(loadfile('Core/Module/Auction.lua'))('BGForge',ns)
initCallbacks[3]()

-- Golden messages are the actual published v1.5/v1.6 wire shape, not generated from the constants under test.
local link='|Hitem:45087|h[Test item]|h'
BG.SendStartAuctionMsg(false,45087,1000,30,'normal',link,20)
Equal(sent[#sent][1],'BiaoGeAuction')
Equal(sent[#sent][2],'StartAuction,100,45087,1000,30,,normal,'..link)
BG.SendStartAuctionMsg(true,45087,1000,30,'normal',link,20)
Equal(sent[#sent][1],'BiaoGeAuction2')
Equal(sent[#sent][2],'StartAuction^100^45087^1000^30^^normal^'..link..'^20')
Equal(sent[#sent][3],'RAID')
print('BGLite v1.6 protocol, lifecycle and auction migration behavior passed')

-- Creating previews must retain the local wishlist and filter hooks without starting an auction.
BG.Frame.TEST.boss2={}
BG.Tooltip_SetItemByID=function() end
BiaoGeTooltip=Frame()
local keepExpanded
BG.SpecGearFilter={ApplyToAuctionFrame=function(_,keep) keepExpanded=keep end}
local hook=BG.HookCreateAuction
BG.HookCreateAuction=function(f) hook(f) end
local before=#sent
local preview=BG.ShowWishlistAuctionPreview(45087,link)
assert(preview.isPreview and preview.remainingTime.text=='预览')
assert(keepExpanded, 'wishlist item must stay expanded under gear filtering')
assert(not preview.ButtonSendMyMoney.enabled and not preview.autoButton.enabled)
assert(not preview.cancelButton.shown and not preview.hide.shown)
Equal(#sent,before,'preview must not send messages')
Equal(#BG.auctionLogFrame.auctioning,0,'preview must not enter live auction tracking')
wa.IsML=function() return true end
wa.UpdateButtonState(preview)
assert(not preview.cancelButton.shown and not preview.hide.shown)
preview.ClosePreview()
assert(not BG.WishlistAuctionPreviewFrame)
assert(not next(BGA.Frames))

-- Real incoming packet handler, both generations and control messages.
local created,cancelled,paused,resumed,bids={},{},{},{},{}
wa.CreateAuction=function(...) created[#created+1]={...} end
wa.SetEndState=function(...) cancelled[#cancelled+1]={...} end
wa.PauseAuction=function(f) paused[#paused+1]=f end
wa.ResumeAuction=function(f) resumed[#resumed+1]=f end
wa.SetMoney=function(...) bids[#bids+1]={...} end
wa.IsRaidLeader=function() return false end
local handler=BGA.Event:GetScript('OnEvent')
local function Inbound(prefix,msg,scope)
    handler(BGA.Event,'CHAT_MSG_ADDON',prefix,msg,scope or 'RAID','Other-Realm',77)
end
Inbound('BiaoGeAuction','StartAuction,101,45087,1000,30,,normal,'..link)
Inbound('BiaoGeAuction3','StartAuction^102^45087^1000^30^^normal^'..link..'^20')
Equal(#created,2);Equal(created[1][1],101);assert(not created[1][9]);assert(created[2][9]);Equal(created[2][8],20)
Inbound('BiaoGeAuction3','StartAuction^103^45087^1000^30^^anonymous^'..link..'^20')
Equal(#created,2,'anonymous auctions remain disabled')
local live={auctionID=102,itemID=45087,isGen2=true,mod='normal',money=1000,start=true}
BGA.Frames[1]=live
Inbound('BiaoGeAuction3','SendMyMoney^102^1000');Equal(#bids,1)
live.start=false
Inbound('BiaoGeAuction3','SendMyMoney^102^1000');Equal(#bids,1,'equal later bid rejected')
Inbound('BiaoGeAuction3','SendMyMoney^102^1100');Equal(#bids,2)
Inbound('BiaoGeAuction3','PauseAuction^45087');Equal(paused[1],live)
Inbound('BiaoGeAuction3','ResumeAuction^45087');Equal(resumed[1],live)
live.currentMoneyText=Frame()
Inbound('BiaoGeAuction3','CancelAuction^102');Equal(cancelled[1][1],live)
Inbound('BiaoGeAuction','VersionCheck');Equal(sent[#sent][2],'MyVer,v4.0')
print('BGLite v1.6 preview, filtering, incoming auction and control packets passed')

-- The real countdown callbacks retain their fonts in both timer states.
function Node:GetMinMaxValues() return 0,1000 end
local timer={bar=Frame(),remainingTime=Frame(),myMoneyEdit=Frame()}
wa.Now=function() return 100 end
wa.Auctioning(timer,30)
timer.bar.scripts.OnUpdate(timer.bar,0.1)
Equal(timer.remainingTime.fontSize,15)
wa.Now=function() return 125 end
timer.bar.scripts.OnUpdate(timer.bar,0.1)
Equal(timer.remainingTime.fontSize,20)

-- Receive the legacy packet envelope and decoded field layout through the real handler.
function Node:GetBackdrop() return {} end
function Node:GetBackdropColor() return 0,0,0,1 end
function Node:SetScrollChild(child) self.scrollChild=child end
function Node:SetStartPoint() end
function Node:SetEndPoint() end
function Node:SetThickness() end
function Node:SetOwner() end
function Node:ClearLines() end
BG.addonChannelCount=10
BG.FBWidth={TEST=1275}; BG.FBHeight={TEST=870}
BG.iconTexCoord={0.07,0.93,0.07,0.93}
BG.STC_r1=function(v) return v end
BG.FormatNumber=function(v) return tostring(v) end
BG.CreateCloseButton=function(f) f.CloseButton=Frame(f) end
BG.CreateSrollBarBackdrop=function() end
BG.HookScrollBarShowOrHide=function() end
BG.SendSystemMessage=function() end
BG.ReceiveFrame={TEST={}}
for b=1,4 do BG.ReceiveFrame.TEST['boss'..b]={zhuangbei1=Frame(),maijia1=Frame(),jine1=Frame(),qiankuan1=Frame()} end
BG.CreateFBUI=function(FB,kind) Equal(FB,'TEST');Equal(kind,'Receive') end
BG.Split=strsplit
ns.IsBase64=function() return true end
ns.Decode=function(v) return v end
ns.RGB_16=function() return '334d66' end
C_EncodingUtil={DecompressString=function(v) return v end}
ChatFrame_AddMessageEventFilter=function() end
assert(loadfile('Core/Module/Receive.lua'))('BGForge',ns)
-- The XML-created scrollbar is supplied by WoW, not by addon code.
local createFrameBeforeReceive=CreateFrame
CreateFrame=function(kind,name,parent,template)
    local f=createFrameBeforeReceive(kind,name,parent,template)
    if kind=='ScrollFrame' then f.ScrollBar=Frame(f) end
    return f
end
BG.ReceiveUI()
BG.ResetReceiveBiaoGe('TEST')
local function Upvalue(f,key)
    for i=1,100 do local n,v=debug.getupvalue(f,i);if not n then break end;if n==key then return v end end
    error('missing captured state: '..key)
end
local draft=Upvalue(BG.ResetReceiveBiaoGe,'draft')
local row='1¦1¦'..link..'¦Buyer¦1200¦¦0.20¦0.30¦0.40&&'
local log='1¦'..link..'¦245¦4¦1¦Buyer¦1200¦¦¦&&'
local packet='!BIAOGE!TEST&&1000&&Golden^^'..row..'^^'..log..'^^!END!'
local receive=events.CHAT_MSG_ADDON
receive(nil,'CHAT_MSG_ADDON','BiaoGeReceive1',packet:sub(1,50),'WHISPER','Other-Realm')
assert(not draft.FB,'partial packet must not apply')
receive(nil,'CHAT_MSG_ADDON','BiaoGeReceive2',packet:sub(51),'WHISPER','Other-Realm')
Equal(draft.FB,'TEST');Equal(draft.title,'Golden')
Equal(draft.boss1.zhuangbei1,link);Equal(draft.boss1.maijia1,'Buyer');Equal(draft.boss1.jine1,'1200')
assert(not draft.boss1.qiankuan1)
Equal(draft.boss1.color1[1],0.2);Equal(draft.boss1.color1[3],0.4)
Equal(#draft.auctionLog,1);Equal(draft.auctionLog[1].jine,'1200')
Equal(draft.auctionLog[1].color[1],1,'missing log colors default to white')
BG.ResetReceiveBiaoGe('TEST')
receive(nil,'CHAT_MSG_ADDON','BiaoGeReceive',packet,'RAID','Other-Realm')
assert(not draft.FB,'table data only accepted over whisper')
receive(nil,'CHAT_MSG_ADDON','BiaoGeReceive',packet,'WHISPER','Other-Realm')
Equal(draft.FB,'TEST','legacy single-channel reception')
CreateFrame=createFrameBeforeReceive
print('BGLite v1.6 table framing, chunk assembly and decoded fields passed')

-- Load the refactored database and execute its actual startup callbacks.
GetAddOnMetadata=function(_,key) return key=='X-Upstream-Version' and '2.4.4' or '1.5.1' end
GetRealZoneText=function(id) return tostring(id) end
UnitRace=function() return 'Human','Human',1 end
UnitLevel=function() return 80 end
GetAverageItemLevel=function() return 245,245 end
GetRaidDifficultyID=function() return 4 end
GetSpellInfo=function(id) return tostring(id) end
GetNumClasses=function() return 9 end
GetInventorySlotInfo=function() return 1 end
GetNumSavedInstances=function() return 0 end
GetServerTime=function() return 1000 end
QUESTS_LABEL='Quests'
initCallbacks={}
assert(loadfile('Core/DB/Init.lua'))('BGForge',ns)
BG.Init=function(f) initCallbacks[#initCallbacks+1]=f end
BG.Init2=function() end
BG.Init3=function() end
BG.RegisterEvent=function() end
BG.STC_y1=function(v) return v end
BG.STC_dis=BG.STC_y1
BG.Once=function() end
BG.Tooltip_SetItemByID=function() end
BG.GetMaxi=function(FB,b) return ns.Maxi[FB][b] end
assert(loadfile('Core/DB/DB.lua'))('BGForge',ns)
Equal(BG.FBWidth.ULDtitan,1685,'Ulduar four-column layout')
Equal(ns.Maxi.ULDtitan[15],52,'expanded misc rows')
Equal(BG.FBIDtable[603],'ULDtitan')
Equal(BG.HistoryFeatureEnabled,false)
local historic={keep=true}
BiaoGe={Alpha=0.65,History=historic,options={autoQingKong=0},ULDtitan={boss15={zhuangbei52=link}}}
for _,f in ipairs(initCallbacks) do f() end
Equal(BiaoGe.options.alpha,0.65,'legacy alpha retained')
Equal(BiaoGe.options.autoQingKong,1)
Equal(BiaoGe.History,historic,'legacy history retained')
Equal(BiaoGe.ULDtitan.boss15.zhuangbei52,link,'ledger retained during startup')
assert(not BiaoGe.filterClassNum,'removed talent-filter storage must not return')
BiaoGe={}
for _,f in ipairs(initCallbacks) do f() end
Equal(BiaoGe.options.alpha,0.8,'fresh alpha initialized')
print('BGLite v1.6 countdown and fresh/legacy database initialization passed')

-- Execute the real loot UI initializer and world-boss save path once per target.
local lootInitializer
BG.CreateSrollBarBackdrop=function() end
BG.HookScrollBarShowOrHide=function() end
BG.Init2=function(f) lootInitializer=f end
for _,key in ipairs({'LOOT_ITEM_SELF_MULTIPLE','LOOT_ITEM_PUSHED_SELF_MULTIPLE','LOOT_ITEM_MULTIPLE','LOOT_ITEM_PUSHED_MULTIPLE','LOOT_ITEM_SELF','LOOT_ITEM_PUSHED_SELF','LOOT_ITEM','LOOT_ITEM_PUSHED','LOOT_ITEM_BONUS_ROLL_SELF','LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE'}) do _G[key]='Loot %s x%d' end
LootFrame=Frame()
BG.CreateButton=function(parent) return Frame(parent) end
BG.GameTooltip_Hide=function() end
BG.SetTextHighlightTexture=function() end
BG.SetButtonAtlas=function() end
BG.PlaySound=function() end
BG.IsHope=function() return true end
BG.GetLeiTingItem=function(id) return id end
BG.ClickTabButton=function() end
BG.ClickFBbutton=function() end
local saves,wishNotices=0,0
BG.AddLootItem=function() saves=saves+1 end
BG.Wishlist={NotifyDrop=function() wishNotices=wishNotices+1 end}
BG.ClearBiaoGeByIndex=function() end
BG.OnItemLoad=function() return {ContinueOnItemLoad=function(_,f) f() end} end
GetNumLootItems=function() return 1 end
LootSlotHasItem=function() return true end
GetLootSlotInfo=function() return nil,nil,1 end
GetLootSlotLink=function() return link end
UnitGUID=function() return 'Creature-world-boss-test' end
assert(loadfile('Core/Module/Loot.lua'))('BGForge',ns)
lootInitializer()
BG.saveWorldBossLoot.bossIndex=1
BG.saveWorldBossLoot:AutoSave()
Equal(saves,1,'one world-boss drop must produce one ledger entry')
Equal(wishNotices,1,'one world-boss drop must produce one wish notice')
BG.saveWorldBossLoot:AutoSave()
Equal(saves,1,'repeat display of the same target must not duplicate ledger entries')
print('BGLite v1.6 world-boss save and wishlist regression passed')
