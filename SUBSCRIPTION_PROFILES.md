# Two subscription profiles

Installed and published follow-up **1.38.4**, 2026-10-30: every existing
Admin → Server → Edit page adds a “نام و دامنه هر لینک اشتراک” block beneath the native
address position, hiding the original address row at the owner's request.
Only two profile groups remain visible, each with its own server name and
hostname, labeled with the subscription titles. Each group maps directly to
that profile, including when both profiles contain
the same server. The block has its own explicit save button. Native server-save
continues to save the shared connection configuration independently. Unconfigured
hostnames start with the existing address. Suggested names append the profile
title so direct/tunnel entries can be distinguished; names remain editable.
All four visible fields are required. The native name is labeled “نام سرور در پنل”.
The hidden original input remains for encoded native-handler compatibility.

Absent/legacy empty overrides use the server's original values. Only the display
name and connection address change in an authenticated profile subscription: UUID/password, SNI, TLS,
transport host/path, port, protocol and node identity stay native. This feature
does not configure DNS or certificates; the supplied hostname must already route
to the intended connection. Selecting a hostname does not add that server to a
profile or expand its access. The original native subscription stays unchanged.

Each server's two overrides are stored together in the existing settings table
as `server_profile_domains_<id>` and `server_profile_names_<id>`. Saves validate
the real server, admin session, CSRF, both hostnames and UTF-8 names before writing
the two settings in one transaction; other servers and the profile definitions
are untouched. No schema migration or node restart is required. The shipped
native Server model adds address and name accessors; verified profile context
supplies overrides, with stored values as fallbacks. A relay uses
the selected entry's hostname and retains its underlying transport settings.

Additional local validation:

```
php tools/server-profile-domains-model-test.php 1
php tools/server-profile-domains-model-test.php 2
php tools/server-profile-domains-model-test.php 1 empty
php tools/server-profile-domains-model-test.php 1 names
php tools/server-profile-domains-model-test.php 2 names
```

The native serializer fixture accepts an extra final `domains` argument:
`php tools/subscription-profiles-native-test.php PANEL_ROOT SOURCE_ROOT 1 config Trojan relay domains`.
It selects the same native server in both profiles with different hostnames,
checks unchanged SNI, credentials, port and stored address, and verifies the
chosen hostname and server name reach the native serializer. Run baseline/profile
1/profile 2 across supported formats before installation. The owner explicitly
authorized transfer, testing and installation on 2026-10-30, and then requested
independent server names. Loopback HTTP tests passed both profiles in all seven
formats, with distinct names/addresses for the same server and no cross-profile
leakage. Disabled, wrong-group and missing-marker requests remain denied.
The native serializer matrix passed 156 cases across four protocols, direct and
relay nodes, baseline and both profiles. Four protocol/relay/format combinations
are absent even in the original baseline; this release does not add those native
serializer capabilities. VMess, Shadowrocket VLESS and SS URIs are decoded at
their additional base64 layer before checking the selected endpoint.

Installed through the native updater from source `aaf73382ec8c8c056549ecab9534c32f75037fa8`.
All 183 installed runtime checksums match its immutable manifest. Authenticated
status confirms installed=latest=1.38.4, server-edit controls render, domain/name
bootstrap works, invalid CSRF and unauthenticated requests are denied, and login
health passes. Customer profile and per-server mappings were not changed. Backup:
`storage/patch/backup-20261030-224735`.

Installed on the existing panel, 2026-10-28: **1.38.0**. The release includes the complete source, manifest and version
for the configured GitHub update repository.

Settings → لینک‌های اتصال defines two independently enabled profiles, each with
a title, multiline plain-text description, selected subscriber groups and exact
server IDs. A subscriber group may belong to either or both profiles; server
selections may overlap. Empty selections never mean everyone/every server.
The subscriber group is `user.server_group`, matched against the panel's `group`
table, consistent with plan/server-group assignment. It is not the employee
permissions table `user_group`.

The dashboard app card renders one copy/import block per authorized profile.
Layout follow-up 1.38.1 places each title and description inside its link card,
with adjacent cards and one shared download/help/how-to section below them.
Admin → Users → Edit shows the same authorized profile URLs and descriptions.
Titles and descriptions are escaped in Smarty. The selected title is also sent
as the client's `profile-title` header. OpenVPN/WireGuard download cards retain
their existing behavior; profiles apply to native `/link/` subscriptions.
Before any configuration has been saved, the original app card/link remains.
Once profiles are saved, groups not selected for either see no subscription
copy/import block in that card. Disabled profiles are hidden and denied.

Links retain the user's existing token, with `do=sub&t=...&profile=1` or `2`.
The endpoint resolves that token directly and checks group membership before
fetching anything. The internal request carries a short-lived HMAC over the
profile number, expiry and token. ConfigProvider verifies it and installs an
Eloquent Server scope selecting the configured IDs. Native serializers therefore
retain their formats and protocol handling. A marker from that scope must be
present in the internal response; otherwise the external request is denied.
A selected relay may resolve its underlying transport by an exact primary-key
lookup; that dependency is never added to the subscription listing. Native
managed-config refresh URLs in bodies/headers are rewritten to the profile URL.
Scoped links never redirect to the unrestricted native subscription on error.
No token, account, plan, server or node entitlement is modified by these settings.

This is an intersection with existing native access. Selecting a server does
not grant node access to accounts whose native group cannot use it. The original
native link and individual configs are not revoked by this presentation feature.

Settings are stored atomically in `sub_profiles`; `sub_profiles_secret` is
generated server-side and is never included in the settings API response.
Admin saves use the existing session authorization and CSRF mechanism and
validate both profiles before writing either. No schema migration is needed.

Local validation:

```
php tools/subscription-profiles-test.php
php tools/subscription-profiles-endpoint-test.php
```

The endpoint suite uses an in-memory SQLite fixture and shared-auth substitutes;
it tests settings validation, persistence, CSRF handling and secret stability,
not the real panel login. The scope suite uses a recording model substitute;
it does not prove the encoded controller's query path.

Native validation on the installed panel used synthetic users, nodes and
connection-local temporary MySQL tables, including temporary subscribe_log.
No customer table was modified by those fixtures. Minimal YAML/JSON template
arrays were explicitly supplied to the CLI fixture, rather than relying on the
normal web entry point's environment initialization. The native baseline and
both profile selections passed URI, Shadowrocket, Surfboard, Stash, Clash,
Clash Meta and sing-box serialization, including relay transport lookup.

```
php tools/subscription-profiles-native-test.php PANEL_ROOT SOURCE_ROOT 1 config Trojan relay
php tools/subscription-profiles-template-test.php PANEL_ROOT SOURCE_ROOT
```

For these commands, SOURCE_ROOT contains app/ and view/ from patch/, or is the
installed panel root. The template test expects application.tpl,
subprofiles.tpl and admin-edit.tpl in its test view directory; the private test
staging tree has those aliases. The native fixture tool takes profile 0 for the
unfiltered baseline, 1/2 for profile selection, and a native format selector.

A pair of loopback-only PHP servers exercised actual SubInfo HTTP fetching and
signature acknowledgement across all seven formats, checked selected titles,
excluded unrelated servers, retained scoped refresh URLs, and denied disabled,
wrong-group and missing-marker requests without redirects. Native Smarty
rendering tested shared/distinct/unauthorized groups, disabled profiles,
legacy behavior, escaped titles/descriptions and correct per-app copy/import
URLs, including QuantumultX's selector without a leading question mark.
Settings and administrator user-edit templates compiled successfully.

Live FPM checks passed: unauthenticated settings denied, native administrator
session accepted, invalid CSRF rejected, invalid group/server selections rejected,
settings page contains the profile editor, and invalid profile token denied.
The short-lived health session was removed afterward. The production
sub_profiles/sub_profiles_secret rows remained unchanged; no real group/server
membership or customer config was selected on the owner's behalf.

The owner explicitly authorized transfer, testing and installation after the
initial automatic approval rejection. Only the ten changed runtime files were
installed, after verifying all original hashes against the repository baseline
and checking PHP 7.4 syntax. Replacements were atomic; new files belong to the
panel worker. Runtime hashes were checked against the prepared manifest.

Backup: storage/patch/backup-20261028-193347-subprofiles. The updater's rollback
pointer and version metadata were updated. Rollback restores replaced files;
new inert helpers may remain. Private deployment metadata and test scripts are
under /tmp/digitsell-subprofiles-check on the server. The publication follow-up includes this release in the update
repository. AGENTS.md makes publication and live installed/latest version
agreement mandatory before declaring future releases complete.
