--[[
    Core/Protocol/Constants.lua — 协议字面量单一来源

    本文件是 addon 通信协议字面量的唯一权威定义。其余代码只能通过
    C.xxx 引用，禁止再写字面量。这些标识符属于与第三方插件互操作的
    公开协议面，必须保持原样，改名或改值会导致对端无法解析。
--]]
local AddonName, ns = ...

local C = {}
ns.Protocol = C

-- 前缀（注册与发送共用）
C.PREFIX_MAIN = "BiaoGe"
C.PREFIX_AUX = "BiaoGe2"
C.PREFIX_WORLD_BOSS = "BiaoGeWorldBoss"
C.PREFIX_RECEIVE = "BiaoGeReceive"
C.PREFIX_AUCTION = "BiaoGeAuction"
C.CHANNEL_COUNT = 10

-- opcode
C.OP_MY_VER = "MyVer"
C.OP_VERSION_CHECK = "VersionCheck"
C.OP_START_AUCTION = "StartAuction"
C.OP_CANCEL_AUCTION = "CancelAuction"
C.OP_PAUSE_AUCTION = "PauseAuction"
C.OP_RESUME_AUCTION = "ResumeAuction"
C.OP_SEND_MY_MONEY = "SendMyMoney"
C.OP_GET_AUCTIONING = "GetAuctioning"
C.OP_RE_AUCTION = "ReAuction"
C.OP_REMIND_AUCTION = "RemindAuction"
C.OP_REFUND_TO_FAILED = "RefundAuctionToFailed"

-- 表格分片分隔符（1/2/3 级）
C.SEP_SECTION = "^^"
C.SEP_ROW = "&&"
C.SEP_FIELD = "¦"

-- 表格帧标记
C.FRAME_BEGIN = "!BIAOGE!"
C.FRAME_END = "!END!"

-- 物品链接标签
C.TAG_BIAOGE = "!BiaoGe"
C.ITEM_PROTOCOL = "|Hgarrmission:"
