# Small Interface Design QA

- Source visual truth: `/Users/liushuxiang/.codex/generated_images/01a03ce4-dac0-7fd2-ae9c-00aca6858856/exec-eff1fb4c-8ac1-47d0-95dd-1b2dea875912.png`
- Resource-label references: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-c4406a1a-eb3e-4913-bead-dac0952bb410.png` and `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-02c91abf-a04e-4e26-a977-a69e6e3578f3.png`
- Implementation: `Core/Module/RaidLockoutOverview.lua`, `CreateHoverFrame`
- Latest full implementation screenshot: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-825eb53b-2b7f-40a7-a6ab-de979d085a9f.png` (after row-hover highlighting and tooltip removal, before the grouped profession/equipment/resource expansion).
- Profession-cell reference: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-fdfbf308-9337-43ec-a951-15f0a887504a.png`.
- Intended UI scale: native WoW UI coordinates at the player's configured UI scale.
- State: minimap/main-frame star hover, ten locally recorded characters, all configured raid columns visible.
- Source dimensions: 1488 × 1056 pixels.
- Implementation dimensions: dynamic; approximately 726 × 626 UI units with ten characters and all eleven raids visible.
- Density normalization: unavailable until an in-game screenshot is captured at UI scale 1.

**Full-view comparison evidence**

The latest screenshot confirms the compact raid matrix, row-hover interaction, and three-column common-resource group render coherently. It predates the newly requested profession and equipment groups, so their final density and icon alignment are not yet visually verified.

**Focused region comparison evidence**

The profession reference establishes the intended compact pattern: numeric value followed by the corresponding icon, with up to two values on one line. The implementation applies the same pattern to legendary item levels, upgrade-item counts, and equipped trinket item levels.

**Findings**

- [P2] Grouped resource expansion remains unverified.
  Location: small hover interface.
  Evidence: the supplied game screenshot predates this iteration. The resource table now contains embedded `专业`, `装备` (`橙装` / `升级物品` / `饰品`), and `通用资源` groups. Values use compact `number + native icon` strips; general-resource totals retain their icons.
  Impact: the data and layout are implemented, but the widest real character rows may require column-width tuning after a client capture.
  Fix: reload the addon in Titan Reforged Classic and capture the revised star-hover panel.

**Implementation checks completed**

- Lua parsed successfully with `luaparse`.
- `git diff --check` passed.
- The complete `CreateOverviewFrame` block for `/bgr` is byte-for-byte unchanged.
- New localization keys are present in zhCN, zhTW, and enUS.
- Gold and Titan Ember snapshots are current-character/account-local only and are not transmitted.
- Gold, Titan Ember, and Titan Shard headers and totals append native client texture tags; ordinary character rows remain numeric. The two Titan currency icons come from `CurrencyInfo.iconFileID`.
- Border iteration: removed the outer `UI-Tooltip-Border`; retained one inset panel frame; replaced per-cell four-edge backdrops with shared one-pixel grid separators.
- Compact-state iteration: removed fractional progress from the small panel; any positive boss-kill count renders as completed, while untouched raids remain blank. Detailed progress remains available in the existing tooltip.
- Character-column iteration: reduced the shared name column by 24 UI units, changed the embedded titles to identify their suffix metric, persisted current-character level, and separated raid-eligible rows from the unfiltered resource list.
- Row-hover iteration: added contiguous row mouse targets and low-alpha gold overlays with eased 0.1-second transitions; removed small-interface raid/resource cell tooltips.
- Resource-group iteration: records two primary professions, finished legendary equipment from equipped/bag/recent-bank scope with actual item level, catalogued Titan legendary-upgrade items including bank counts, and the two currently equipped trinkets. Only local logged-in character snapshots are persisted.

**Follow-up polish**

- Tune border tint and edge size after seeing the actual client texture.
- Adjust icon texcoords if the refresh or settings art has excess transparent padding in Titan.
- Tune the profession/equipment column widths after checking characters with two professions, several legendaries, and both equipped trinkets.

final result: blocked
