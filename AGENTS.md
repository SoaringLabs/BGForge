<claude-mem-context>
# Memory Context

# [BGForge] recent context, 2026-09-04 10:27pm GMT+8

No previous sessions found.
</claude-mem-context>

## Releases

- Use this workflow for every GitHub release:
  1. Obtain the target version in `vX.Y.Z` form before changing release metadata; ask the user when it is missing.
  2. Compare the previous published GitHub release with the target release commit. Summarize every user-visible change in `CHANGELOG.md`, update `BGForge.toc` to `X.Y.Z`, and add any release screenshots supplied in the conversation to the repository and the matching changelog entry.
  3. Verify the release changes, then commit and push them. When the release commit is not on `main`, open a pull request to `main` and merge it after required checks pass.
  4. Confirm the merged release commit is on `main`, then create the `vX.Y.Z` tag from that commit.
  5. Run `scripts/build-release.sh vX.Y.Z`, then publish the GitHub Release using the matching changelog entry as its notes and upload only the generated `dist/BGForge-vX.Y.Z.zip`. For any release-asset rebuild, use the same script and asset. GitHub source archives and direct `git archive` output are not addon release packages.
  6. After confirming that the GitHub Release is published and `dist/BGForge-vX.Y.Z.zip` is attached successfully, delete that matching local zip. Keep it when publishing or uploading fails so the release can be retried.
- The release is complete only when the target GitHub Release is published from `main` with its changelog and generated addon zip attached, and the matching local zip has been deleted.

## Changelog format

- Apply this format to new `CHANGELOG.md` entries and GitHub Release notes. Keep the version/date heading in `CHANGELOG.md`; use only its entry body for Release notes.
- Write consecutive lines starting at `1`, in the exact form `1.【修复】描述`: no space between the number, period, category, or description. Use `【新增】`, `【修复】`, or `【优化】` on each line instead of category subheadings or bullet lists. Separate entries with a blank line for Markdown rendering.
- Use concise Chinese describing player-visible behavior. Cover every user-visible change since the previous release; omit commit hashes, source paths, test details, and internal implementation/version details. Keep older changelog entries as-is unless requested.
- Before publishing or editing a Release, check consecutive numbering, exact prefixes, and that its notes match the corresponding changelog body.

Example:

```text
1.【修复】升级新版 RurutiaSuite 后，点击“金”字无法打开 BGForge 的问题
2.【优化】保留 RurutiaSuite 3.7.2 及以上旧版兼容，左右键均可开关 BGForge 界面
```

For documentation-only corrections to an existing Release, commit and push the documentation, update that Release's notes, and verify they match `CHANGELOG.md`. Preserve its tag and existing addon ZIP, and confirm the uploaded asset is unchanged.
