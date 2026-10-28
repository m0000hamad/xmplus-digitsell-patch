# Release completion — mandatory

The owner requires deployed panel changes to be published to the configured
update repository. A server-only installation is an incomplete release.

Before reporting a release complete:

1. Run the relevant checks and rebuild `manifest.json` and `VERSION` for the
   actual release. Validate every manifest checksum against the exact file bytes.
2. Commit the complete source, manifest, version and handoff updates. Publish
   the release to the branch the panel updater reads; never force-push.
3. Verify the published branch points to the intended commit and its immutable
   manifest contains the expected version and checksums.
4. Verify the live panel's authenticated patch status reports the same installed
   and latest version, and check health. If it is still a newer-release workflow,
   finish installation before declaring the versions synchronized.

If publication or verification fails, fix it or explicitly report the release as
incomplete. Never lower the installed version to conceal an unpublished release.
Keep customer data, credentials, authentication cookies and deployment scratch
out of this public repository.

Update `HANDOFF.md` after changes, including publication and deployment state.
