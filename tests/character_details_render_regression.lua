local frames = {}
local regions = {}
unpack = unpack or table.unpack

local Region = {}
Region.__index = function(_, key)
    if type(key) == "string" and key:match("^_bgforge") then return nil end
    if Region[key] then return Region[key] end
    if key:match("^[A-Z]") then return function() end end
end

local function NewRegion()
    local region = setmetatable({ shown = true }, Region)
    table.insert(regions, region)
    return region
end

function Region:Show() self.shown = true end
function Region:Hide() self.shown = false end
function Region:IsShown() return self.shown end
function Region:SetFont(font, size, flags)
    self.font = font
    self.fontSize = size
    self.fontFlags = flags
end
function Region:SetText(text)
    if rawget(self, "regionType") == "FontString" and not rawget(self, "font") then
        error("FontString:SetText(): Font not set")
    end
    self.text = text
end
function Region:GetText() return self.text end
function Region:GetStringWidth() return #(tostring(self.text or "")) * 7 end
function Region:SetWidth(width) self.width = width end
function Region:SetHeight(height) self.height = height end
function Region:SetSize(width, height) self.width, self.height = width, height end
function Region:SetTexture(texture) self.texture = texture end
function Region:SetColorTexture(...) self.colorTexture = { ... } end
function Region:SetDesaturated(desaturated) self.desaturated = desaturated end
function Region:SetVertexColor(r, g, b, a) self.vertexColor = { r, g, b, a } end
function Region:SetTextColor(r, g, b, a) self.textColor = { r, g, b, a } end
function Region:SetBackdropColor(r, g, b, a) self.backdropColor = { r, g, b, a } end
function Region:SetBackdropBorderColor(r, g, b, a) self.backdropBorderColor = { r, g, b, a } end
function Region:SetAlpha(alpha) self.alpha = alpha end
function Region:SetWordWrap(enabled) self.wordWrap = enabled end
function Region:SetJustifyH(value) self.justifyH = value end
function Region:SetJustifyV(value) self.justifyV = value end
function Region:SetHighlightTexture(texture) self.highlightTexture = texture end
function Region:GetWidth() return rawget(self, "width") or 1275 end
function Region:GetHeight() return rawget(self, "height") or 800 end
function Region:GetFrameLevel() return rawget(self, "frameLevel") or 1 end
function Region:SetFrameLevel(level) self.frameLevel = level end
function Region:SetParent(parent) self.parent = parent end
function Region:GetParent() return rawget(self, "parent") end
function Region:SetShown(shown) self.shown = shown end
function Region:SetEnabled(enabled) self.enabled = enabled end
function Region:EnableMouseWheel(enabled) self.mouseWheelEnabled = enabled end
function Region:ClearAllPoints() self.pointCalls = {} end
function Region:SetPoint(...)
    local points = rawget(self, "pointCalls") or {}
    self.pointCalls = points
    table.insert(points, { ... })
end
function Region:SetScript(script, callback)
    local scripts = rawget(self, "scripts") or {}
    self.scripts = scripts
    scripts[script] = callback
end
function Region:CreateTexture(_, layer)
    local region = NewRegion()
    region.drawLayer = layer
    return region
end
function Region:CreateFontString()
    local region = NewRegion()
    region.regionType = "FontString"
    region.parent = self
    return region
end
function Region:GetVerticalScroll() return rawget(self, "verticalScroll") or 0 end
function Region:SetVerticalScroll(offset) self.verticalScroll = offset end
function Region:SetScrollChild(child) self.scrollChild = child end
function Region:UpdateScrollChildRect() end
function Region:Show()
    self.shown = true
    local scripts = rawget(self, "scripts")
    if scripts and scripts.OnShow then scripts.OnShow(self) end
end

local function NewFrame(parent)
    local frame = NewRegion()
    frame.parent = parent
    frame.ScrollBar = NewRegion()
    table.insert(frames, frame)
    return frame
end

CreateFrame = function(_, _, parent)
    return NewFrame(parent)
end

BIAOGE_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
YES, NO = "Yes", "No"
StaticPopupDialogs = {}

floor, ceil, min, max, format, tinsert = math.floor, math.ceil, math.min, math.max, string.format, table.insert
UNKNOWN = "Unknown"
date = os.date
GetServerTime = function() return 1788739200 end
GetClassColor = function() return 1,1,0,"ffffff00" end
GetItemInfoInstant = function() return nil,nil,nil,nil,134400 end
GetItemInfo = function(link) return tostring(link),link,4 end
local inventorySlots = {
    HeadSlot=1, NeckSlot=2, ShoulderSlot=3, ShirtSlot=4, ChestSlot=5,
    WaistSlot=6, LegsSlot=7, FeetSlot=8, WristSlot=9, HandsSlot=10,
    Finger0Slot=11, Finger1Slot=12, Trinket0Slot=13, Trinket1Slot=14,
    BackSlot=15, MainHandSlot=16, SecondaryHandSlot=17, RangedSlot=18,
    TabardSlot=19,
}
GetInventorySlotInfo = function(token)
    return inventorySlots[token], "empty:" .. token
end
GameTooltip = NewRegion()
UISpecialFrames = {}
function Region:GetTexture() return self.texture end
function Region:GetFontString() return rawget(self, "fontString") end
function Region:SetFontString(value) self.fontString=value end
function Region:HookScript(name, fn)
    local old = rawget(self, "scripts") and self.scripts[name]
    self:SetScript(name, function(...) if old then old(...) end; fn(...) end)
end
function Region:SetFormattedText(pattern, ...) self:SetText(string.format(pattern, ...)) end
function Region:SetMinMaxValues(a,b) self.range={a,b} end
function Region:GetMinMaxValues() return unpack(self.range or {0,0}) end
function Region:SetValue(value) self.value=value end
function Region:GetValue() return self.value or 0 end
function Region:SetThumbTexture() self.thumb=NewRegion() end
function Region:GetThumbTexture() return self.thumb end
function Region:Hide() self.shown=false; if rawget(self, "scripts") and self.scripts.OnHide then self.scripts.OnHide(self) end end
local originalCreateFrame=CreateFrame
CreateFrame=function(kind,name,parent,template)
    local f=originalCreateFrame(kind,name,parent)
    if name then _G[name]=f end
    return f
end
local L=setmetatable({}, {__index=function(_,key) return key end})
local character={name="Test",classFile="ROGUE",level=80,itemLevel=239,
    professions={{skillLineID=755},{skillLineID=186}},dailyProfessionSkills={},
    dailyProfessionSkillsUpdatedAt=1788739200,money=181340000,resourcesUpdatedAt=1788739200,
    titanEmbers=152,titanEmbersEarnedThisWeek=20,titanEmbersWeeklyMax=20,
    details={equipment={updatedAt=1788739200, slots={[1]={link="item:1:2:3:0:0:0",itemLevel=238}}},
    backpack={updatedAt=1788739200,usedSlots=98,totalSlots=108,items={
        {link="item:1:0:0:0:0:0",name="Potion",classID=0,count=2},
        {link="item:2:0:0:0:0:0",name="Boots",classID=4,itemLevel=232,count=1}}}}}
local other={name="Empty",classFile="MAGE",level=80}
BG={talentIcon={},GetRaidLockoutStoredCharacters=function() return {character,other} end,
GetRaidLockoutProfessionTracks=function() return {
 {name="Engineering",rank=450,maxRank=450,entries={},hasTrackedCooldowns=false},
 {name="Tailoring",rank=435,maxRank=450,entries={},hasTrackedCooldowns=false},
} end,
GetRaidLockoutProgressModel=function()
 return {updatedAt=1788739200,raids={
 {id="partial",name="Partial",lockouts={{killedCount=2,numEncounters=4,bosses={
  {name="Boss 1",killed=true},{name="Boss 2",killed=false},
  {name="Boss 3",killed=true},{name="Boss 4",killed=false}}}}},
 {id="none",name="None",lockouts={}}},weeklies={{name="Weekly",completed=false}},weeklyCompleted=0,weeklyTotal=1}
end}
assert(loadfile("Core/UI/DesignSystem.lua"))("BGForge",{L=L})
assert(loadfile("Core/Module/CharacterDetails.lua"))("BGForge",{L=L})
local parent=NewFrame()
BG.CharacterDetails.Show(parent,1,"Test")
local f=BGForgeCharacterDetailsFrame
assert(f.todayPanel:IsShown(), "default page must be today")
assert(f.back:GetParent()==f.leftHeader, "back control belongs in the top-left header")
assert(f.leftHeader.height==54, "back header keeps its own compact height")
assert(f.header.height==82, "character identity header keeps its independent height")
assert(f.header.accent and f.header.accent.width==3, "identity header has a three-unit focus divider")
assert(f.left:GetParent()==f, "character list remains inside the details frame")
assert(not f.characterRows[1]._bgforgeStateHooks, "character rows must not inherit bordered button hover states")
assert(f.characterRows[1].scripts.OnEnter and f.characterRows[1].scripts.OnLeave,
    "character rows keep subtle background-only hover feedback")
assert(f.characterRows[1].divider and f.characterRows[2].divider, "continuous rows use one divider each")
assert(f.characterRows[2].pointCalls[1][3] - f.characterRows[1].pointCalls[1][3] == -56,
    "character rows must stack without vertical gaps")
assert(f.updatedAt.pointCalls[1][1]=="TOPLEFT" and f.updatedAt.pointCalls[1][2]==80
    and f.updatedAt.pointCalls[1][3]==-58, "snapshot timestamp belongs to the left-aligned identity stack")
assert(f.todayTab.line:IsShown(), "today tab uses the blue underline active state")
assert(not f.tabs[1].line:IsShown(), "inactive detail tabs must not keep an underline")
assert(#f.tabs==2 and f.tabs[1].label:GetText()=="装备"
    and f.tabs[2].label:GetText()=="背包"
    and not f.professionResourcesPanel and not f.progressPanel,
    "character details exposes only Today, Equipment, and Backpack")
assert(f.todayPanel.actionColumn._bgforgeKind=="surface"
    and f.todayPanel.raidSection._bgforgeKind=="surface"
    and f.todayPanel.operationsColumn._bgforgeKind=="surface",
    "today uses exactly three bordered column surfaces")
assert(f.todayPanel.actionColumn.width==321 and f.todayPanel.raidSection.width==505,
    "today column widths preserve the selected mock ratios")
assert(f.todayPanel.actionColumn.title:GetText()=="今日任务"
    and f.todayPanel.raidSection.title:GetText()=="团队副本"
    and f.todayPanel.operationsColumn.title:GetText()=="资源与快捷入口",
    "today column headings match the selected three-lane hierarchy")
assert(f.todayPanel.operationsColumn.meta:GetText()=="",
    "the mixed resource and shortcut lane does not show an ambiguous timestamp")
assert(f.todayPanel.actionColumn.title:GetParent()==f.todayPanel.actionColumn.header
    and f.todayPanel.raidSection.title:GetParent()==f.todayPanel.raidSection.header
    and f.todayPanel.operationsColumn.title:GetParent()==f.todayPanel.operationsColumn.header
    and f.todayPanel.actionColumn.header.height==38,
    "all lane titles share one fixed-height vertically centered header")
assert(f.todayPanel.actionColumn.title.justifyV=="MIDDLE"
    and f.todayPanel.actionColumn.meta.justifyV=="MIDDLE",
    "lane title and metadata use the same vertical center")
assert(not f.todayPanel.dailySection._bgforgeKind and f.todayPanel.dailySection.divider,
    "today modules share a column surface and use single dividers")
assert(f.todayPanel.dailySection.title:GetText()=="专业日常",
    "the fixed three-row catalog is titled profession dailies")
assert(f.todayPanel.dailyRows[1].height==52 and f.todayPanel.dailyRows[1].iconButton.width==32,
    "daily task rhythm and icon size match the selected mock")
assert(f.todayPanel.dailyRows[1].divider and f.todayPanel.professionRows[1].divider,
    "task and profession rows use one divider instead of individual borders")
assert(f.todayPanel.dailyRows[2].divider:IsShown()
    and not f.todayPanel.dailyRows[3].divider:IsShown(),
    "the final profession-daily row suppresses its redundant divider")
assert(f.todayPanel.todaySummary.count:GetText()=="2"
    and f.todayPanel.todaySummary.label:GetText()=="项待完成"
    and not f.todayPanel.todaySummary.weekly:IsShown(),
    "today summary shows only the combined pending total")
assert(f.todayPanel.dailySection.meta:GetText()=="0/1"
    and f.todayPanel.weeklySection.meta:GetText()=="0/1"
    and f.todayPanel.dailySection.meta.fontSize==14
    and f.todayPanel.weeklySection.meta.fontSize==14
    and f.todayPanel.dailySection.meta.fontSize==f.todayPanel.dailySection.title.fontSize
    and f.todayPanel.weeklySection.meta.fontSize==f.todayPanel.weeklySection.title.fontSize,
    "section-level counts match their left-hand title size")
assert(f.todayPanel.todaySummary.divider.pointCalls[1][2]==-12
    and f.todayPanel.todaySummary.divider.pointCalls[2][2]==12,
    "the overview/daily-module divider spans the full Today-task lane")
assert(f.todayPanel.dailyRows[1]:IsShown()
    and f.todayPanel.dailyRows[1].name:GetText()=="珠宝日常"
    and f.todayPanel.dailyRows[1].status:GetText()=="未完成"
    and not f.todayPanel.dailyRows[1].action:IsShown()
    and f.todayPanel.dailyRows[1].iconButton.alpha==1
    and not f.todayPanel.dailyRows[1].interactive
    and f.todayPanel.dailyRows[2]:IsShown()
    and f.todayPanel.dailyRows[2].name:GetText()=="烹饪日常"
    and f.todayPanel.dailyRows[2].detail:GetText()=="未学习烹饪"
    and f.todayPanel.dailyRows[2].status:GetText()=="未学习"
    and not f.todayPanel.dailyRows[2].action:IsShown()
    and f.todayPanel.dailyRows[2].iconButton.alpha==0.45
    and f.todayPanel.dailyRows[2].iconButton.icon.desaturated
    and not f.todayPanel.dailyRows[2].interactive
    and f.todayPanel.dailyRows[3]:IsShown()
    and f.todayPanel.dailyRows[3].name:GetText()=="钓鱼日常"
    and f.todayPanel.dailyRows[3].detail:GetText()=="未学习钓鱼"
    and f.todayPanel.dailyRows[3].status:GetText()=="未学习"
    and not f.todayPanel.dailyRows[3].action:IsShown()
    and f.todayPanel.dailyRows[3].iconButton.alpha==0.45
    and f.todayPanel.dailyRows[3].iconButton.icon.desaturated
    and not f.todayPanel.dailyRows[3].interactive,
    "today keeps all three dailies and visually de-emphasizes unlearned skills")
character.dailyProfessionSkills = {
    [185] = { rank = 349, maxRank = 450 },
    [356] = { rank = 1, maxRank = 450 },
}
BG.CharacterDetails.Refresh()
assert(f.todayPanel.todaySummary.count:GetText()=="3"
    and f.todayPanel.dailySection.meta:GetText()=="0/2"
    and f.todayPanel.dailyRows[1].name:GetText()=="珠宝日常"
    and f.todayPanel.dailyRows[2].name:GetText()=="烹饪日常"
    and f.todayPanel.dailyRows[2].detail:GetText()=="技能需达到 350"
    and f.todayPanel.dailyRows[2].status:GetText()=="暂不可做"
    and not f.todayPanel.dailyRows[2].action:IsShown()
    and f.todayPanel.dailyRows[2].iconButton.alpha==0.45
    and f.todayPanel.dailyRows[3].name:GetText()=="钓鱼日常"
    and f.todayPanel.dailyRows[3].status:GetText()=="未完成"
    and not f.todayPanel.dailyRows[3].action:IsShown()
    and f.todayPanel.dailyRows[3].iconButton.alpha==1,
    "fixed daily rows distinguish locked Cooking from eligible Fishing")
assert(not f.todayPanel.dailyNote,
    "Today must express eligibility in its rows instead of appending a footnote")
character.dailyProfessionSkills[185].rank = 350
BG.CharacterDetails.Refresh()
assert(f.todayPanel.todaySummary.count:GetText()=="4"
    and f.todayPanel.dailySection.meta:GetText()=="0/3"
    and f.todayPanel.dailyRows[2].name:GetText()=="烹饪日常"
    and f.todayPanel.dailyRows[2].status:GetText()=="未完成"
    and not f.todayPanel.dailyRows[2].action:IsShown()
    and f.todayPanel.dailyRows[2].iconButton.alpha==1
    and not f.todayPanel.dailyRows[2].iconButton.icon.desaturated
    and f.todayPanel.dailyRows[3].name:GetText()=="钓鱼日常",
    "eligible Cooking and Fishing dailies must return to Today")
character.questCompletions = { cookingDaily = true }
BG.CharacterDetails.Refresh()
assert(f.todayPanel.todaySummary.count:GetText()=="3"
    and f.todayPanel.dailySection.meta:GetText()=="1/3"
    and f.todayPanel.dailyRows[2].status:GetText()=="已完成"
    and not f.todayPanel.dailyRows[2].action:IsShown()
    and f.todayPanel.dailyRows[2].iconButton.alpha==1,
    "completed learned dailies remain full-strength rows without a dead detail action")
character.questCompletions = nil
character.dailyProfessionSkills = nil
BG.CharacterDetails.Refresh()
assert(f.todayPanel.dailyRows[2].status:GetText()=="未扫描"
    and f.todayPanel.dailyRows[2].detail:GetText()=="资格尚未记录"
    and not f.todayPanel.dailyRows[2].action:IsShown()
    and f.todayPanel.dailyRows[3].status:GetText()=="未扫描",
    "Today preserves fixed rows when a legacy snapshot cannot determine eligibility")
character.dailyProfessionSkills = {}
BG.CharacterDetails.Refresh()
assert(not f.todayPanel.weeklyRows[1].iconButton:IsShown()
    and f.todayPanel.weeklyRows[1].weeklyStatusIcon.width==18
    and f.todayPanel.weeklyRows[1].weeklyStatusIcon.height==18,
    "weekly status remains compact and centered in the existing 32px icon slot")
assert(f.todayPanel.weeklyRows[1].weeklyStatusIcon.pointCalls[1][1]=="CENTER"
    and f.todayPanel.weeklyRows[1].weeklyStatusIcon.pointCalls[1][2]
        ==f.todayPanel.weeklyRows[1].iconButton,
    "weekly status artwork is anchored to the center of the task icon slot")
assert(f.todayPanel.weeklyRows[1].weeklyStatusIcon.texture=="Interface\\RaidFrame\\ReadyCheck-Waiting",
    "incomplete weekly tasks reuse the pending-raid waiting status texture")
assert(not f.todayPanel.weeklyRows[1].action:IsShown()
    and not f.todayPanel.weeklyRows[1].interactive,
    "weekly summaries do not keep a dead link to the removed Progress page")
assert(f.todayPanel.raidSection.meta:GetText()=="副本 1/2",
    "the Today raid heading shows raid progress without repeating weeklies")
assert(f.todayPanel.raidRows[1].name:GetText()=="Partial")
assert(f.todayPanel.raidRows[1].status:GetText()=="已完成", "partial raid uses completed semantics")
assert(not f.todayPanel.raidRows[1].status:IsShown(),
    "raid rows avoid a redundant second status line inside grouped lanes")
assert(f.todayPanel.raidRows[1].kills:GetText()=="2/4", "partial raid keeps exact boss progress")
assert(not f.todayPanel.raidRows[1].action
    and (not f.todayPanel.raidRows[1].scripts
        or (not f.todayPanel.raidRows[1].scripts.OnClick
            and not f.todayPanel.raidRows[1].scripts.OnEnter
            and not f.todayPanel.raidRows[1].scripts.OnLeave)),
    "raid summaries do not advertise interaction after the Progress page is removed")
assert(f.todayPanel.raidRows[1].kills.pointCalls[1][2]==-9
    and f.todayPanel.raidRows[1].progress.pointCalls[1][2]==-67,
    "raid summaries reclaim the removed action column without changing track dimensions")
assert(f.todayPanel.raidRows[1].progress.width==170, "boss segments stay inside a fixed-width track")
assert(f.todayPanel.raidRows[1].segments[4]:IsShown() and not f.todayPanel.raidRows[1].segments[5]:IsShown(),
    "boss count controls the visible segment count")
assert(f.todayPanel.raidRows[1].segments[1].colorTexture[4]==0.95
    and f.todayPanel.raidRows[1].segments[2].colorTexture[4]==0.72
    and f.todayPanel.raidRows[1].segments[3].colorTexture[4]==0.95
    and f.todayPanel.raidRows[1].segments[4].colorTexture[4]==0.72,
    "gapped boss kills must light exactly the bosses reported as killed")
assert(f.todayPanel.raidRows[2].name:GetText()=="None")
assert(f.todayPanel.raidRows[2].status:GetText()=="未开始")
assert(f.todayPanel.raidCompletedLabel:IsShown() and f.todayPanel.raidPendingLabel:IsShown(),
    "raid progress exposes completed and pending groups")
assert(f.todayPanel.raidRows[1].divider.pointCalls[1][2]==2
    and f.todayPanel.raidRows[1].divider.pointCalls[2][2]==-2,
    "the completed/pending group boundary matches the lane-header divider width")
assert(f.todayPanel.raidRows[2].divider.pointCalls[1][2]==12
    and f.todayPanel.raidRows[2].divider.pointCalls[2][2]==-12,
    "ordinary raid-row dividers retain their original content inset")
assert(f.todayPanel.resourceSection:GetParent()==f.todayPanel.operationsColumn
    and f.todayPanel.professionSection:GetParent()==f.todayPanel.operationsColumn
    and f.todayPanel.quickSection:GetParent()==f.todayPanel.operationsColumn,
    "resources, professions, and shortcuts share the right operations lane")
local emberDetail = f.todayPanel.resourceRows[2].detail
local dangerColor = BG.UI.Token("color", "danger")
assert(emberDetail:GetText()=="（20/20）"
    and emberDetail.fontSize==f.todayPanel.resourceRows[2].value.fontSize
    and emberDetail.fontSize==14,
    "weekly Ember progress matches the resource quantity font size")
assert(emberDetail.pointCalls[1][2]==f.todayPanel.resourceRows[2].value
    and emberDetail.pointCalls[1][3]=="RIGHT"
    and math.abs(emberDetail.pointCalls[1][4]
        + f.todayPanel.resourceRows[2].value:GetStringWidth())==4,
    "weekly Ember progress sits one xs token before the visible quantity")
assert(emberDetail.textColor[1]==dangerColor[1]
    and emberDetail.textColor[2]==dangerColor[2]
    and emberDetail.textColor[3]==dangerColor[3],
    "weekly Ember progress uses danger red at the cap")
character.titanEmbersEarnedThisWeek = 19
BG.CharacterDetails.Refresh()
local successColor = BG.UI.Token("color", "success")
assert(emberDetail:GetText()=="（19/20）"
    and emberDetail.textColor[1]==successColor[1]
    and emberDetail.textColor[2]==successColor[2]
    and emberDetail.textColor[3]==successColor[3],
    "weekly Ember progress uses success green below the cap")
character.titanEmbersEarnedThisWeek = 20
BG.CharacterDetails.Refresh()
assert(f.todayPanel.professionRows[1].name.justifyH=="LEFT"
    and f.todayPanel.professionRows[1].detail.justifyH=="LEFT"
    and not f.todayPanel.professionRows[1].action:IsShown()
    and not f.todayPanel.professionRows[1].interactive,
    "profession summaries stay aligned and do not link to the removed detail page")
assert(f.todayPanel.professionRows[1].divider:IsShown()
    and not f.todayPanel.professionRows[2].divider:IsShown(),
    "only the final visible profession suppresses its redundant row divider")
assert(f.todayPanel.equipmentPreview.height==64 and f.todayPanel.equipmentPreview.items[1].width==32,
    "quick previews preserve the selected mock's deliberate icon scale")
assert(f.todayPanel.equipmentPreview._bgforgeKind=="surface"
    and f.todayPanel.backpackPreview._bgforgeKind=="surface"
    and f.todayPanel.equipmentPreview.backdropBorderColor[4]==0,
    "equipment and backpack are separate filled click surfaces without added borders")
assert(f.todayPanel.equipmentPreview.scripts.OnEnter and f.todayPanel.equipmentPreview.scripts.OnLeave
    and f.todayPanel.equipmentPreview.items[1].scripts.OnEnter
    and not f.todayPanel.equipmentPreview.hoverAccent:IsShown(),
    "each quick-preview surface has a whole-block hover treatment")
f.todayPanel.equipmentPreview.scripts.OnEnter(f.todayPanel.equipmentPreview)
assert(f.todayPanel.equipmentPreview.hoverAccent:IsShown(),
    "hover reveals the quick-preview focus accent")
f.todayPanel.equipmentPreview.scripts.OnLeave(f.todayPanel.equipmentPreview)
assert(not f.todayPanel.equipmentPreview.hoverAccent:IsShown(),
    "leaving the quick preview restores its resting treatment")
f.tabs[1].scripts.OnClick(f.tabs[1])
assert(f.paperDoll:IsShown() and not f.tablePanel and not f.equipmentInspector,
    "equipment remains one continuous surface instead of restoring the legacy card pair")
assert(f.paperDoll.backdropColor[1]==f.todayPanel.actionColumn.backdropColor[1]
    and f.paperDoll.backdropColor[2]==f.todayPanel.actionColumn.backdropColor[2]
    and f.paperDoll.backdropColor[3]==f.todayPanel.actionColumn.backdropColor[3]
    and f.paperDoll.backdropColor[4]==f.todayPanel.actionColumn.backdropColor[4]
    and f.paperDoll.backdropBorderColor[1]
        ==f.todayPanel.actionColumn.backdropBorderColor[1],
    "equipment inherits the same dark panel and border color roles as Today")
assert(f.paperDoll.pointCalls[1][1]=="TOPLEFT"
    and f.paperDoll.pointCalls[1][2]==8 and f.paperDoll.pointCalls[1][3]==-50
    and f.paperDoll.pointCalls[2][1]=="BOTTOMRIGHT"
    and f.paperDoll.pointCalls[2][2]==-8 and f.paperDoll.pointCalls[2][3]==8,
    "paper doll keeps the fixed eight-unit content inset")
assert(f.equipmentDetail.width==520 and f.equipmentDetailDivider.width==1
    and f.paperDollStage.pointCalls[3][2]==f.equipmentDetail,
    "the equipment surface splits into a fixed detail rail and a fluid paper-doll stage")
assert(f.paperDollSlotGroups[1].width==48 and f.paperDollSlotGroups[1].height==48
    and f.paperDollSlotGroups[1].itemButton.width==44,
    "paper-doll icons use the compact size while their slot geometry remains fixed")
assert(f.paperDollSlotGroups[1].pointCalls[1][1]=="TOPLEFT"
    and f.paperDollSlotGroups[1].pointCalls[1][2]==0
    and f.paperDollSlotGroups[10].pointCalls[1][1]=="TOPRIGHT"
    and f.paperDollSlotGroups[10].pointCalls[1][2]==0,
    "left and right equipment rails hug opposite panel edges symmetrically")
assert(not f.paperDollSlotGroups[1].slotLabel:IsShown()
    and not f.paperDollSlotGroups[1].itemName:IsShown()
    and not f.paperDollSlotGroups[1].itemLevel:IsShown(),
    "names and levels are not duplicated beside the paper-doll icons")
assert(f.paperDollSlotGroups[16].width==104 and f.paperDollSlotGroups[16].height==72
    and f.paperDollSlotGroups[16].pointCalls[1][1]=="BOTTOM",
    "the three weapon slots use the dedicated bottom rail geometry")
assert(f.paperDollWatermark.alpha==0.055 and f.paperDollWatermark.width==240,
    "the class artwork stays a low-contrast central watermark")
assert(f.inspectorIcon.width==64 and f.inspectorName:GetText()=="item:1:2:3:0:0:0"
    and f.inspectorMeta:GetText()=="头部  ·  物品等级 238",
    "the selected item detail sits directly in the paper-doll center")
assert(f.inspectorEnhancements[1]:IsShown() and f.inspectorEnhancements[2]:IsShown()
    and not f.inspectorEnhancements[3]:IsShown(),
    "central detail renders only the recorded enchantment and gem icons")
assert(f.equipmentDetailTitle:GetText()=="装备明细"
    and f.equipmentDetailSummary:GetText()=="装等 239"
    and #f.equipmentDetailRows==17
    and f.equipmentDetailRows[1].definition.id==1
    and f.equipmentDetailRows[6].definition.id==9,
    "right detail rail lists seventeen functional equipment positions and omits cosmetics")
assert(f.equipmentDetailRows[1].itemName:GetText()=="item:1:2:3:0:0:0"
    and f.equipmentDetailRows[1].itemLevel:GetText()==238
    and f.equipmentDetailRows[1].enhancements[1]:IsShown()
    and f.equipmentDetailRows[1].enhancements[2]:IsShown()
    and not f.equipmentDetailRows[1].enhancements[3]:IsShown(),
    "each detail row exposes the item name, level, enchantment, and gems")
assert(f.equipmentDetailRows[1].selectedBackground:IsShown()
    and f.equipmentDetailRows[1].selectedAccent:IsShown(),
    "the detail rail identifies the slot currently shown in the center")
assert(not f.paperDollSlotGroups[1].hoverBackground:IsShown())
f.paperDollSlotGroups[1].scripts.OnEnter(f.paperDollSlotGroups[1])
assert(f.paperDollSlotGroups[1].hoverBackground:IsShown(),
    "equipment groups use a fill-only hover without another border")
f.paperDollSlotGroups[1].scripts.OnLeave(f.paperDollSlotGroups[1])
assert(not f.paperDollSlotGroups[1].hoverBackground:IsShown())
assert(f.paperDollSlotGroups[17].itemButton.icon.texture=="empty:SecondaryHandSlot"
    and f.paperDollSlotGroups[17].itemButton.icon.desaturated
    and f.paperDollSlotGroups[17].itemButton.icon.alpha==0.38,
    "empty equipment slots retain their native slot silhouette and subdued treatment")
f.equipmentDetailRows[2].scripts.OnEnter(f.equipmentDetailRows[2])
assert(f.equipmentDetailRows[2].hoverBackground:IsShown(),
    "detail rows use a borderless fill hover")
f.equipmentDetailRows[2].scripts.OnLeave(f.equipmentDetailRows[2])
f.equipmentDetailRows[2].scripts.OnClick(f.equipmentDetailRows[2])
assert(f.inspectorName:GetText()=="尚未记录"
    and f.equipmentDetailRows[2].selectedBackground:IsShown()
    and not f.equipmentDetailRows[1].selectedBackground:IsShown(),
    "clicking the detail rail updates the central selection and selected row")
f.tabs[2].scripts.OnClick(f.tabs[2])
assert(f.backpackPanel.backdropColor[1]==f.todayPanel.actionColumn.backdropColor[1]
    and f.backpackPanel.backdropColor[2]==f.todayPanel.actionColumn.backdropColor[2]
    and f.backpackPanel.backdropColor[3]==f.todayPanel.actionColumn.backdropColor[3]
    and f.backpackPanel.backdropColor[4]==f.todayPanel.actionColumn.backdropColor[4]
    and f.backpackPanel.backdropBorderColor[1]
        ==f.todayPanel.actionColumn.backdropBorderColor[1],
    "backpack inherits the same dark panel and border roles as Today")
assert(not f.backpackHeader._bgforgeKind and f.backpackHeader.height==42
    and f.backpackHeader.divider,
    "backpack header keeps its geometry but uses one divider instead of a boxed surface")
assert(not f.backpackFilters.all._bgforgeKind
    and f.backpackFilters.all.width==78 and f.backpackFilters.all.height==28
    and f.backpackFilters.all.line:IsShown()
    and not f.backpackFilters.consumable.line:IsShown(),
    "backpack filters preserve their size and use the lightweight detail-tab treatment")
assert(f.backpackInfoDivider.width==1,
    "backpack summary is separated from the item grid by one subtle divider")
assert(not f.backpackGroupHeaders[1]._bgforgeKind
    and f.backpackGroupHeaders[1].height==26
    and f.backpackGroupHeaders[1].divider,
    "backpack group headings use a single divider instead of bordered header bars")
assert(f.backpackItemButtons[1].width==35,
    "backpack item geometry remains unchanged during visual-system alignment")
f.backpackSearch:SetText("Potion")
f.backpackSearch.scripts.OnTextChanged(f.backpackSearch)
assert(f.backpackItemButtons[1].link=="item:1:0:0:0:0:0")
assert(not f.backpackItemButtons[2]:IsShown(), "search must hide nonmatches")
f.characterRows[2].scripts.OnClick(f.characterRows[2])
assert(f.backpackEmpty:IsShown())
for i=1,2 do f.tabs[i].scripts.OnClick(f.tabs[i]) end
f.todayTab.scripts.OnClick(f.todayTab)
assert(f.todayPanel.resourceRows[1].value:GetText()=="—", "unknown currency remains unknown")
BG.CharacterDetails.Hide(true)
print("Character details runtime navigation, search, selection, empty snapshots and partial raid tests passed")
