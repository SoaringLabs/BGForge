# Small Interface Design QA

- Source visual truth: `/Users/liushuxiang/.codex/generated_images/01a03ce4-dac0-7fd2-ae9c-00aca6858856/exec-eff1fb4c-8ac1-47d0-95dd-1b2dea875912.png`
- Resource-label references: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-c4406a1a-eb3e-4913-bead-dac0952bb410.png` and `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-02c91abf-a04e-4e26-a977-a69e6e3578f3.png`
- Implementation: `Core/Module/RaidLockoutOverview.lua`, `CreateHoverFrame`
- Latest implementation screenshot: `/var/folders/8r/xdsf4nhn2cj4yb9030z85w900000gn/T/codex-clipboard-71740154-63d5-4247-ba28-a28be95989b2.png` (after the border correction, before the compact-status and resource-icon adjustments in this iteration).
- Intended UI scale: native WoW UI coordinates at the player's configured UI scale.
- State: minimap/main-frame star hover, ten locally recorded characters, all configured raid columns visible.
- Source dimensions: 1488 × 1056 pixels.
- Implementation dimensions: dynamic; approximately 726 × 626 UI units with ten characters and all eleven raids visible.
- Density normalization: unavailable until an in-game screenshot is captured at UI scale 1.

**Full-view comparison evidence**

The latest in-game screenshot confirms the overall hierarchy, compact rows, single outer frame, and shared one-pixel table separators render correctly. It also shows that fractional raid progress is too detailed for the compact panel, completed cells need slightly stronger contrast, and resource icons repeat too often when attached to every character value.

**Focused region comparison evidence**

Focused inspection of the raid cells and resource columns shows three objective issues: partial lockouts use `x/x` instead of the requested binary state, the green completed-state fill is faint against the navy rows, and icons in every resource row increase noise without adding meaning.

**Findings**

- [P2] Revised compact-state and resource-icon rendering remains unverified.
  Location: small hover interface.
  Evidence: the supplied game screenshot shows the corrected frame/grid but predates this iteration. Compact raid cells now render a check whenever at least one boss has been defeated; ordinary resource rows now contain numbers only, while resource headers and totals retain their icons. Current-character and completed-cell fills were strengthened without changing the overall dark palette.
  Impact: the requested behavior is implemented, but final color and icon alignment still require a new game-client capture.
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

**Follow-up polish**

- Tune border tint and edge size after seeing the actual client texture.
- Adjust icon texcoords if the refresh or settings art has excess transparent padding in Titan.
- Check whether the game UI scale requires a one-pixel increase in the compact number font.

final result: blocked
