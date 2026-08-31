local sourcePath = "Core/Module/HistoryStore.lua"

local function ResetEnvironment(options)
    local now = 2000000000
    BiaoGe = {
        options = options or {},
        History = { RAID = {} },
        HistoryList = { RAID = {} },
    }
    max = math.max
    min = math.min
    format = string.format
    date = os.date
    GetServerTime = function()
        return now
    end
    wipe = function(tbl)
        for key in pairs(tbl) do
            tbl[key] = nil
        end
    end

    BG = {
        IsTitan = true,
        FBtable = { "RAID" },
        GetMaxi = function()
            return 2
        end,
        Init = function(callback)
            callback()
        end,
    }

    assert(loadfile(sourcePath))("BGForge", {
        Maxb = { RAID = 1 },
    })
    return BG.HistoryStore, now
end

local function NewSource()
    return {
        boss1 = {
            zhuangbei1 = "[Test Item]",
            maijia1 = "OtherPlayer-Realm",
            jine1 = "1200",
            qiankuan1 = true,
            color1 = { 2, -1, 0.5 },
            guid1 = "Player-1-SECRET",
            guild1 = "Secret Guild",
            class1 = "WARRIOR",
            zhuangbei2 = true,
            maijia2 = { "Malformed" },
        },
        boss2 = {
            zhuangbei1 = "Expense",
            jine1 = "100",
        },
        boss3 = {
            jine4 = "25",
            jine5 = "44000",
        },
        tradeTbl = { secret = true },
        raidRoster = { "Player-1-SECRET" },
        auctionLog = { secret = true },
        leaderInfo = { guid = "Player-1-SECRET" },
        gameFlavor = "OtherFlavor",
    }
end

local function CountBGForgeRecords()
    local count = 0
    for _, record in pairs(BiaoGe.History.RAID) do
        if type(record) == "table" and type(record._bgforge) == "table" then
            count = count + 1
        end
    end
    return count
end

local function TestSaveUsesWhitelistAndCollisionSafeIDs()
    local Store, now = ResetEnvironment()
    local firstID, firstStatus = Store.Save("RAID", NewSource(), "First", now, { source = "manual" })
    local secondID, secondStatus = Store.Save("RAID", NewSource(), "Second", now, { source = "auto-clear" })
    assert(firstID and firstStatus == "saved")
    assert(secondID and secondStatus == "saved")
    assert(firstID ~= secondID, "two saves in one second reused a history ID")

    local record = BiaoGe.History.RAID[firstID]
    assert(record.boss1.zhuangbei1 == "[Test Item]")
    assert(record.boss1.maijia1 == "OtherPlayer-Realm")
    assert(record.boss1.jine1 == "1200")
    assert(record.boss1.qiankuan1 == true)
    assert(record.boss1.color1[1] == 1 and record.boss1.color1[2] == 0 and record.boss1.color1[3] == 0.5,
        "buyer color was not safely normalized")
    assert(record.boss1.guid1 == nil and record.boss1.guild1 == nil and record.boss1.class1 == nil,
        "identity or class metadata escaped the history whitelist")
    assert(record.boss1.zhuangbei2 == nil and record.boss1.maijia2 == nil,
        "malformed legacy display values escaped validation")
    assert(record.tradeTbl == nil and record.raidRoster == nil and record.auctionLog == nil
        and record.leaderInfo == nil and record.gameFlavor == nil,
        "secondary-use data escaped the history whitelist")
    assert(record._bgforge.source == "manual", "history source metadata was not saved")
    assert(type(record._bgforge.fingerprint) == "string" and record._bgforge.fingerprint ~= "",
        "history content fingerprint was not saved")
    assert(BiaoGe.HistoryList.RAID[1][4] == "auto-clear"
        and BiaoGe.HistoryList.RAID[2][4] == "manual",
        "history list source metadata was not saved")
end

local function TestAutomaticSaveDeduplicatesOnlyIdenticalLatestSnapshot()
    local Store, now = ResetEnvironment()
    local firstID, firstStatus = Store.Save("RAID", NewSource(), "Manual", now, { source = "manual" })
    assert(firstID and firstStatus == "saved")

    local duplicateID, duplicateStatus = Store.Save("RAID", NewSource(), "Automatic", now + 1, {
        source = "auto-clear",
        dedupe = true,
    })
    assert(duplicateID == firstID and duplicateStatus == "duplicate",
        "identical automatic save was not matched to the latest history record")
    assert(#BiaoGe.HistoryList.RAID == 1 and CountBGForgeRecords() == 1,
        "identical automatic save created a duplicate history record")

    local changed = NewSource()
    changed.boss1.jine1 = "1300"
    local changedID, changedStatus = Store.Save("RAID", changed, "Changed", now + 2, {
        source = "auto-clear",
        dedupe = true,
    })
    assert(changedID and changedID ~= firstID and changedStatus == "saved",
        "changed ledger content was incorrectly treated as a duplicate")
    assert(#BiaoGe.HistoryList.RAID == 2 and BiaoGe.HistoryList.RAID[1][4] == "auto-clear")
    assert(BiaoGe.History.RAID[changedID]._bgforge.fingerprint
        ~= BiaoGe.History.RAID[firstID]._bgforge.fingerprint,
        "different ledger content produced the same stored fingerprint")
end

local function TestLegacyReadIsSanitizedWithoutMutatingLegacyRecord()
    local Store = ResetEnvironment()
    local id = 12345
    local legacy = NewSource()
    BiaoGe.History.RAID[id] = legacy
    BiaoGe.HistoryList.RAID[1] = { id, "Legacy", 100 }

    local snapshot = assert(Store.LoadByIndex("RAID", 1))
    assert(snapshot.boss1.zhuangbei1 == "[Test Item]")
    assert(snapshot.boss1.guid1 == nil and snapshot.tradeTbl == nil and snapshot.raidRoster == nil,
        "legacy history was not reduced to the display whitelist")
    assert(legacy.boss1.guid1 == "Player-1-SECRET" and legacy.tradeTbl.secret,
        "reading a legacy record unexpectedly rewrote its saved data")
end

local function TestPruneOnlyTouchesBGForgeRecords()
    local Store, now = ResetEnvironment({ historyRetentionDays = 90, historyMaxRecords = 2 })
    local legacyID = 777
    BiaoGe.History.RAID[legacyID] = NewSource()
    BiaoGe.HistoryList.RAID[1] = { legacyID, "Legacy", 1 }

    assert(Store.Save("RAID", NewSource(), "One", now))
    assert(Store.Save("RAID", NewSource(), "Two", now + 1))
    assert(Store.Save("RAID", NewSource(), "Three", now + 2))
    assert(CountBGForgeRecords() == 2, "max-record retention did not remove the oldest BGForge record")
    assert(BiaoGe.History.RAID[legacyID] ~= nil, "retention deleted a legacy BiaoGe record")

    Store.Prune("RAID", now + 91 * 86400)
    assert(CountBGForgeRecords() == 0, "age retention did not remove expired BGForge records")
    assert(BiaoGe.History.RAID[legacyID] ~= nil, "age retention deleted a legacy BiaoGe record")
end

local function TestPermanentRetentionAndTitanScope()
    local Store, now = ResetEnvironment({ historyRetentionDays = 0, historyMaxRecords = 1 })
    assert(Store.Save("RAID", NewSource(), "One", now))
    assert(Store.Save("RAID", NewSource(), "Two", now + 1))
    Store.Prune("RAID", now + 1000 * 86400)
    assert(CountBGForgeRecords() == 2, "permanent retention still pruned BGForge records")

    BG.IsTitan = false
    local id, reason = Store.Save("RAID", NewSource(), "Unsupported", now + 2)
    assert(id == nil and reason == "unsupported", "history storage escaped the Titan-only scope")
end

local function TestInvalidRetentionSettingsFallBackSafely()
    ResetEnvironment({ historyRetentionDays = { "bad" }, historyMaxRecords = -1 })
    assert(BiaoGe.options.historyRetentionDays == 90, "invalid retention duration was not reset")
    assert(BiaoGe.options.historyMaxRecords == 50, "invalid record limit was not reset")
end

TestSaveUsesWhitelistAndCollisionSafeIDs()
TestAutomaticSaveDeduplicatesOnlyIdenticalLatestSnapshot()
TestLegacyReadIsSanitizedWithoutMutatingLegacyRecord()
TestPruneOnlyTouchesBGForgeRecords()
TestPermanentRetentionAndTitanScope()
TestInvalidRetentionSettingsFallBackSafely()

print("History store regression tests passed")
