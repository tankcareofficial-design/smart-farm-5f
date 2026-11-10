# Smartfarm+ Offline UI and Cloud Roadmap — 2026-11-10

Status: DESIGN / CANDIDATE, not deployed. Source baseline: candidate/r8.14-stability-1; current UX on candidate/r8.15-crop-profile-preview-20261110, draft PR #2. No changes to main, ESP32 firmware, NVS, RTC, Wi-Fi credentials, real loads, backend, or deployment authorized by this document.

## Product principle

Smartfarm+ is a general-purpose, local-first IoT device controller. It can drive approved outputs on a connected ESP32 even without Internet access. The optional **ชุดค่าแนะนำการปลูก** (crop recommendations) are editable phone-local guides, *not* actuator commands. User-developed presets never silently overwrite a controller configuration.

### Three distinct states — do not label all of them simply “Offline”

| Condition | UI | Allowed | Blocked |
|---|---|---|---|
| Controller reachable on AP/LAN, Internet not reachable | **เชื่อมต่อกล่องควบคุมแล้ว · ไม่มีอินเทอร์เน็ต** (future explicit Internet detection) | Existing local Manual control, device edits, local crop guides, local timers subject to RTC safety | Cloud login/remote sync |
| Controller unreachable, Internet may be reachable | **กล่องควบคุมออฟไลน์** | View cached data (clearly marked stale), crop guides and phone-local edits | New/edit/delete/controller command writes; no ghost-success feedback |
| Both Controller and Internet reachable | **เชื่อมต่อในพื้นที่ · พร้อมเชื่อมคลาวด์** when cloud feature exists | Local controls and cloud features (once developed and authorized) | Unsafe control paths, unverified crop-to-pump automation |

For R8.15 current UI, only Controller reachability is authoritative: do NOT claim Internet status without testing it. The device Add/Edit entry shows a Thai/English offline warning when the controller is unreachable. The wizard re-checks connectivity before saving, and DeviceStore must still receive a controller acknowledgment before saving locally. Never queue hazardous relay ON commands for automatic replay after reconnection.

## Later Cloud phase: Cloudflare + Supabase (tentative, not yet implemented)

1. **Supabase Auth**: phone registration/login (email and verified identity); user sessions are separate from controller credentials. Design anonymous/local operation policy before enabling login gating, so existing deployments are not locked out. Official documentation: https://supabase.com/docs/guides/auth
2. **Supabase Postgres + RLS**: accounts, farms/sites, controller ownership/claim, device metadata, user roles, app crop guides/customizations, cloud command audit. Enable RLS on every exposed application table, deny by default, and test SELECT/INSERT/UPDATE/DELETE as both member and non-member. Reference: https://supabase.com/docs/guides/database/postgres/row-level-security
3. **Cloudflare Workers**: secure API/gateway for authenticated cloud actions and controlled device command relay; can integrate with Supabase. Reference: https://developers.cloudflare.com/workers/databases/third-party-integrations/supabase/
4. **Secure device connection**: controller-to-cloud outbound authentication and heartbeat; a cloud/edge gateway must not imply direct HTTP exposure of ESP32 AP IP `192.168.4.1`. If using Cloudflare Tunnel, it needs a permanently running gateway host and explicit security design; a standalone ESP32 does not magically run `cloudflared`. Reference: https://developers.cloudflare.com/tunnel/get-started/
5. **Permissions & safety**: role-bound device ownership; nonce/idempotency/expiry, acknowledgments, replay prevention, emergency latch and no automatic relay ON after reconnect. Distinguish requested vs confirmed physical state. Preserve local source of truth for controller scheduling when cloud is unreachable.
6. **Offline synchronization**: distinguish *read/edit saved to phone* from *accepted by controller* and *synced to cloud*; define conflict resolution and audit timestamps. Cloud metadata changes must not silently override local emergency mode.
7. **Implementation phases**: R8.15 offline UX warning & tests -> separately reviewed Auth/UI prototype -> Supabase schema/RLS tests -> Workers API -> mutually authenticated device transport -> remote and offline UAT. No cloud keys, URLs, service-role tokens, or passwords in GitHub source.

## UX copy rules

- “กล่องควบคุมออฟไลน์ — เพิ่มหรือแก้ไขอุปกรณ์ไม่ได้ กรุณาเชื่อมต่อ ESP32 ในหน้าตั้งค่า”
- “ชุดค่าแนะนำการปลูก” and its phone-only edits remain usable without Controller or Internet.
- Never say “no Internet” solely because the ESP32 is unreachable; never say “Controller connected” solely because phone has Wi-Fi or Internet.
- Do not silently lose unsaved manual input when disconnected; show a clear retry notice, and do not claim the action succeeded.
