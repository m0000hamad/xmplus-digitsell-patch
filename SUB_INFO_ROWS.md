# Editable information rows per subscription link

Installed and published in panel 1.38.8; authenticated installed/latest agree. Admin → Servers ends with “ردیف‌های اطلاعات داخل
اشتراک”, after the existing VPN cards. Link 1 and link 2 have separate master
switches, row checkboxes and complete editable text templates. One save validates
both cards and writes one complete JSON setting, `sub_info_profile_rows`.
No migration or node-agent change is needed.

Available rows cover wallet/expired-plan states, no-expiry/date/days-left,
remaining/total traffic, exhausted traffic, optional used traffic, wallet balance,
update time and a free-text update hint. Conditional rows retain the existing
account-state rules; selecting an expired-plan message does not display it on
an active plan. The ordinary unconfigured output keeps its prior defaults.

Allowed placeholders are `{expire_date}`, `{days_left}`, `{remaining}`,
`{remaining_short}`, `{total}`, `{used}`, `{balance}`, `{updated_time}`. Values
come from the same authenticated subscription account and use the existing
Persian formatting. Templates are single-line plain text, capped at 800 bytes,
with strict known-placeholder validation. They use string substitution, never
template evaluation. The editor previews with explicitly synthetic values and
uses text/value DOM properties rather than HTML insertion.

Configured profile links use their own saved master/checkbox/text settings,
independent of the legacy global SubInfo switch. Old unprofiled links keep that
legacy switch and behavior. Before the new editor is saved, both profile cards
inherit the legacy switch/default rows; installation does not configure these
choices on the owner's behalf. Subscriber group/server selection, tokens and
the internal profile-signing key are unchanged.

URI-list clients receive only their selected applicable rows. All-off and a
disabled profile master also remove native loopback Total/Used/Expire entries
and Shadowrocket's native STATUS line, so the unchecked English defaults cannot
return. Managed URI-list responses clear the cached native information bar;
Happ announcement text uses the same selected rows. Structured Clash/Meta/
sing-box configurations remain pass-through bodies, with announcement text
controlled separately. This does not inject artificial proxies into those
structured formats. Real connection lines remain byte-identical, including
real endpoints whose names begin with Total/Expire; only loopback metadata
entries are recognized as native information placeholders.

Saving requires the existing admin session, POST and CSRF. Both complete profile
sets are validated before a single setting write; an invalid second profile
cannot partially update the first. Unknown placeholders, malformed row sets,
invalid UTF-8 and control/newline characters are rejected. Users refresh their
subscription to receive text/visibility changes; no credentials rotate.

Validation:

```
php tools/sub-info-rows-test.php
php tools/subscription-profiles-endpoint-test.php
```

Local tests cover independent row text/toggles/masters, old default rendering,
account-state conditions, placeholders, atomic validation and secret/profile
preservation. Headless Edge verifies both cards, independent edits, live preview,
safe plain-text rendering and the complete two-profile save payload. Native
Smarty renders the editor. Loopback-only HTTP/native serializer fixtures verify
selected-only rows and announcements, all-off cleanup, independent master
switches, unchanged real URI lines and structured pass-through. Fixtures use
connection-local temporary user/server/settings tables and disable real wallet
lookups; no production customer row or setting is changed by tests.

Rollback to the preceding panel source leaves this inert configuration setting
in place. Existing profile billing/ports and online-count behavior are unaffected.

Release source: `5cdbf4e0ac5c8694b1469d0550ef650c9a9f0618`. All 188 installed
runtime hashes match the immutable manifest. Native editor/bootstrap/validation,
CSRF and anonymous denial, and login health passed. Backup:
`storage/patch/backup-20261031-103702`. Production row choices were not changed.
