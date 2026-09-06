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
- The release is complete only when the target GitHub Release is published from `main` with its changelog and generated addon zip attached.
