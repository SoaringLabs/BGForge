local _, ns = ...
if BG.IsBlackListPlayer then return end

local Maxt = ns.Maxt
local Maxb = ns.Maxb
local BossNum = ns.BossNum


local frameNameByType = {
    ["FB"] = "Frame",
    ["History"] = "HistoryFrame",
    ["Receive"] = "ReceiveFrame",
}

local function GetFrameName(type)
    return frameNameByType[type]
end

-- 滚动框
function BG.CreateFBScrollFrame(frameName, FB, bossNum)
    local _, b = BG.GetBossNumInfo(FB, bossNum)
    local anchorFrame, anchorX, anchorY
    local bigRowGap = BG.IsBigFB(FB) and -15 or -20
    if b == 1 then
        if BG.zaxiang[FB] and bossNum == Maxb[FB] then
            anchorFrame = BG[frameName][FB]["boss" .. bossNum - 1]["zhuangbei" .. BG.GetMaxi(FB, bossNum - 1, true)]
            anchorX, anchorY = -5, bigRowGap
        else
            anchorFrame = BG[frameName].p["preWidget" .. 0]
            anchorX, anchorY = -5, -3
        end
    elseif BG[frameName .. FB]["scrollFrame" .. bossNum - 1] then
        anchorFrame = BG[frameName .. FB]["scrollFrame" .. bossNum - 1].owner
        anchorX, anchorY = 0, BG.IsBigFB(FB) and -13 or -18
    else
        anchorFrame = BG[frameName][FB]["boss" .. bossNum - 1]["zhuangbei" .. BG.GetMaxi(FB, bossNum - 1, true)]
        anchorX, anchorY = -5, bigRowGap
    end

    local scrollParent = BG[frameName .. FB]
    local scrollFrame = CreateFrame("ScrollFrame", nil, scrollParent, "UIPanelScrollFrameTemplate") -- 滚动
    scrollFrame:SetWidth(350)
    scrollFrame:SetHeight(BG.GetMaxi(FB, bossNum, true) * (20 + (BG.IsBigFB(FB) and .1 or 3)))
    scrollFrame:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", anchorX, anchorY)
    BG.CreateSrollBarBackdrop(scrollFrame.ScrollBar)
    BG.HookScrollBarShowOrHide(scrollFrame)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame) -- 子框架
    scrollChild:SetSize(1, 1)
    scrollChild.owner = scrollFrame
    scrollFrame:SetScrollChild(scrollChild)
    BG[frameName .. FB]["scrollFrame" .. bossNum] = scrollChild
    if bossNum == Maxb[FB] + 2 then
        scrollFrame.ScrollBar:Hide()
    end
end

function BG.CreateFBUI(FB, type)
    if BG[FB..type.."IsRoadUI"] then return end
    BG[FB .. type .. "IsRoadUI"]=true

    local frameName = GetFrameName(type)
    if not BG[frameName .. FB] then
        local mainFrames = {
            ["FB"] = BG.FBMainFrame,
            ["History"] = BG.HistoryMainFrame,
            ["Receive"] = BG.ReceiveMainFrame,
        }
        local frameParent = mainFrames[type]
        if not frameParent then
            BG[FB .. type .. "IsRoadUI"] = nil
            return
        end
        BG[frameName .. FB] = CreateFrame("Frame", nil, frameParent)
        BG[frameName .. FB]:Hide()
    end

    local columnKinds = { "ZhuangBeiUI", "MaiJiaUI", "JinEUI", "DiSeUI" }

    -- 正常格子
    for t = 1, Maxt[FB] do
        BG[type .. "TitleUI"](FB, t)
        local _, rowCount = BossNum(FB, 0, t)
        for b = 1, rowCount do
            if BossNum(FB, b, t) > Maxb[FB] - 1 then
                break
            end
            local cellCount = BG.GetMaxi(FB, BossNum(FB, b, t))
            for i = 1, cellCount do
                for _, kind in ipairs(columnKinds) do
                    BG[type .. kind](FB, t, b, rowCount, i, cellCount)
                end
            end
            BG["BossNameUI"](FB, t, b, rowCount, nil, cellCount, GetFrameName(type))
        end
    end

    -- 对账
    if type == "FB" and not BG.DuiZhangProxy then
        local duizhangBuilders = { BG.DuiZhangZhuangBeiUI, BG.DuiZhangMyJinEUI, BG.DuiZhangOtherJinEUI, BG.DuiZhangDiSeUI }
        for t = 1, Maxt[FB] do
            local _, rowCount = BossNum(FB, 0, t)
            for b = 1, rowCount do
                if BossNum(FB, b, t) > Maxb[FB] + 1 then
                    break
                end

                local cellCount = BG.GetMaxi(FB, BossNum(FB, b, t))
                for i = 1, cellCount do
                    BG.DuiZhangBiaoTiUI(FB, t, b, rowCount, i, cellCount)
                    if BossNum(FB, b, t) <= Maxb[FB] then
                        for _, builder in ipairs(duizhangBuilders) do
                            builder(FB, t, b, rowCount, i, cellCount)
                        end
                    end
                end

                if BossNum(FB, b, t) == Maxb[FB] + 1 then
                    local cellCount = 2
                    for i = 1, cellCount do
                        for _, builder in ipairs(duizhangBuilders) do
                            builder(FB, t, b, rowCount, i, cellCount)
                        end
                    end
                end
                BG.BossNameUI(FB, t, b, rowCount, nil, cellCount, "DuiZhangFrame")
            end
        end
    end

    -- 滚动框
    local firstScrollBoss, lastScrollBoss = Maxb[FB], Maxb[FB] + 2
    for bossNum = firstScrollBoss, lastScrollBoss do
        BG.CreateFBScrollFrame(GetFrameName(type), FB, bossNum)
        local t, b = BG.GetBossNumInfo(FB, bossNum)
        local cellCount = BG.GetMaxi(FB, bossNum)
        for i = 1, cellCount do
            BG[type .. "ZhuangBeiUI"](FB, t, b, nil, i, cellCount, BG[GetFrameName(type) .. FB]["scrollFrame" .. bossNum])
            BG[type .. "MaiJiaUI"](FB, t, b, nil, i, cellCount)
            BG[type .. "JinEUI"](FB, t, b, nil, i, cellCount)
            BG[type .. "DiSeUI"](FB, t, b, nil, i, cellCount)
        end
        BG["BossNameUI"](FB, t, b, nil, nil, nil, GetFrameName(type))
    end

    BG[type .. "ZhiChuZongLanGongZiUI"](FB)
end
