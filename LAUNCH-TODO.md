# FTM (TransFit) — Launch To-Do

**Goal: in TestFlight by end of day tomorrow (Oct 24), with a few testers trying it.**
Come back to this list anytime — it lives in the project so it never gets lost.

## 1. RevenueCat paid products (you + me, needs the dashboard)

- [ ] Confirm the two products exist and are attached to App Store Connect subscriptions: `premium_monthly`, `premium_annual`
- [ ] **Change the price**: DECIDED Oct 24. Monthly stays $9.99. Annual goes from $49.99 to **$95.99** (20% off 12 x monthly). Change in App Store Connect > Subscriptions > premium_annual > Subscription Prices
- [ ] **Free trial**: DECIDED Oct 24. **2-week free trial on BOTH plans.** App Store Connect > each subscription > Introductory Offers > Free, 2 weeks, all territories. Paywall copy updates itself.
- [ ] Confirm entitlement `premium` has both products attached
- [ ] Confirm offering `default` has package IDs `premium_monthly` + `premium_annual`
- [ ] Note: prices shown in the app always come from RevenueCat automatically (localized) — no app change needed when prices change, but App Store Connect + RevenueCat must match

## 2. AI functionality — verify all three (me)

- [ ] **Meal scanning** — end-to-end test: real photo → edge function → AI → foods on screen (server verified live; needs one signed-in test through the app)
- [ ] **Workout planning** — verify the personalized program generation on a fresh account
- [ ] **Nutrition targets** — verify calculated goals on a fresh account
- [ ] If you want real AI-generated workout plans (beyond the current rule-based builder), flag it — that's a feature, not a fix, and can ride in v1.1

## 3. Bug hunt (me, with your list)

- [ ] You test on the preview + on TestFlight, send me "screen + what happened" items
- [ ] Already fixed this week: dead buttons, laggy scroll, blank camera in preview — re-check these first

## 4. Aesthetic pass (me)

- [x] Onboarding: added "Your plan is ready" reveal (their calories, macros, split, perks) right before the trial paywall (Oct 24)

- [ ] Sweep for anything looking unfinished (spacing, contrast, leftover default styling)
- [ ] Fresh eyes on Home, Nutrition, Train, Community, Profile — one polish pass, no rebuilds

## 5. TestFlight (me)

- [x] Start the build upload as soon as you say go (needs your Rork plan active) — **Build 7 uploaded Oct 23** ✅
- [ ] You install from TestFlight on your iPhone and run a real user session (invite email arrives once build finishes processing, ~10–30 min)
- [ ] Add your few testers via App Store Connect → TestFlight → internal testers
- [ ] Demo account for Apple's reviewer (email/password they can sign in with)

## 6. App Store submission (after TestFlight looks good)

- [ ] Screenshots (I generate), listing text (I draft, you approve)
- [ ] Privacy policy URL: https://2gxfo9qxolcyjgbzbeaoj-web.rork.live/privacy ✅ already live
- [ ] Submit for review — Apple takes 1–3 days

## Status Oct 24 (end of session)

Done:
- [x] Prices: $9.99/mo, $99.99/yr (Save 17%), 2-week free trial on both (App Store Connect)
- [x] premium_annual created; subscription group named "FTM Premium"
- [x] RevenueCat connected to App Store Connect (API key + In-App Purchase key)
- [x] premium_monthly + premium_annual imported into RevenueCat
- [x] Paywall: "Start free trial" + "Continue with the free version"; FTM Premium name
- [x] Free users can follow ready-made plans; custom plan is Premium
- [x] Check-ins re-upload if a save failed; coach photo placeholder

Left:
- [ ] App Store Connect: fix "Missing Metadata" on Premium Monthly
- [ ] RevenueCat: attach both new products to `premium` entitlement
- [ ] RevenueCat: default offering, swap new products into both packages
- [ ] RevenueCat Test Store: premium_monthly $9.99, premium_annual $99.99 (for preview)
- [ ] Supabase secrets: REVENUECAT_SECRET_KEY + EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY present
- [ ] New TestFlight build, then test: 3 free scans, limit hit, start trial, unlimited scans

## Plan from Oct 28

Phase 1: functionality first (the "Left" list above, step by step).
Phase 2: full redesign. Goal: stop looking like every other AI-generated app. Take inspiration from top fitness apps (bring 3 to 5 screenshots) and redesign screen by screen.

## Oct 28 review: camera fix + full app sweep

Fixed Oct 28 (needs a new TestFlight build to test):
- [x] Meal scanner + barcode scanner camera was black (preview never connected), picked front camera, crashed on retake
- [x] Notification prompt froze the launch splash; now asked once inside the app
- [x] Barcode scanner had no Cancel button; double barcode reads
- [x] Empty system tab bar under the custom one
- [x] Camera permission text said barcodes only (App Review flag)
- [x] Scans-left count from the server was always 3 (redeploy scan-meal function)
- [x] Delete never showed on your own Community posts

Must fix before App Store:
- [x] Logged sets vanish after closing the app (exercise IDs regenerate each launch / on plan rebuild)
- [x] "Full history" upgrade card shows to everyone, feature doesn't exist (rejection risk); "Programs are Premium" copy contradicts free plans
- [x] Community: add Block user (Apple requirement)
- [x] Profile: hide Developer "Reset onboarding" in release; Restore purchases for free users; Done button on Profile tab does nothing
- [x] Check-in notification says "Mason reads every one" (not true today)
- [x] One app name everywhere (FTM: Fitness & Nutrition vs FTMFitnessNutrition vs FTM Team vs TransFit); drop "Free at launch"
- [ ] Confirm support@transfit.app actually receives mail (you)

Notes on the Oct 28 fixes:
- Full history is now real: Premium gets 7/30/90 day calorie bars with average kcal, protein and days logged
- Developer "Reset onboarding" only shows in debug builds, so not on TestFlight
- Training days: pick exact weekdays in Profile > Edit profile (2 to 6); onboarding now offers 2 days
- Check-in photos stay on the phone only (copy says so); no coach dashboard yet
- Still your call: Community header "This is where we shine, boys"

Improvements:
- [x] Home: remove duplicate Log food tile and profile icon; show "over by X" kcal
- [x] Train: lbs/kg setting; show last session's weight x reps; rest timer; pick training weekdays incl. 2 days/week; "Train anyway" on rest days
- [x] Nutrition: day switcher (log yesterday); meal "+" preselects that meal; tap to edit a logged item; undo delete; "Scan a meal" on the main screen; over-target state
- [x] Community: Mason posts get real dates (guidelines were already collapsed)
- [x] Profile: units + notifications toggle; confirm before "Rebuild my training plan"
- [x] Check-in: front photo optional; say photos stay on this phone

## Oct 30 fixes (needs a new TestFlight build to test)

- [x] Bottom of every tab was hidden behind the tab bar; content now stops at the top of the bar
- [x] Meal scan: photo was sent at 3x size (could hit the server size limit); now 1024 px
- [x] Meal scan: opens straight from Nutrition instead of stacking on Add Food (sometimes didn't open)
- [x] Meal scan: free users with 0 scans left see the upgrade card before taking a photo
- [x] Meal scan errors now end with a code (S400, S422, S503...) so you can tell me which one you hit
- [x] Barcode / packaged foods with a serving size logged the wrong calories (a 40 g bar logged at 40%)
- [x] Editing a weighed food now updates its label ("300 g") to match the new amount
- [x] Paywall: a failed purchase now shows the reason instead of doing nothing; "Try again" when plans don't load
- [x] Profile: "Copy account ID" (for support and for granting testers Premium in RevenueCat)
- [x] Profile: "Reset to recommended" no longer saves until you tap Save
- [x] Body stats accept a decimal comma (72,5)
- [x] Community: report/delete failures now show a message; display names get the same language filter

Testing Premium without paying:
- Fastest: RevenueCat > Customers > search your account ID (Profile > Copy account ID) > Grant promotional entitlement > premium. Works for scans too.
- Or start the free trial in TestFlight. TestFlight purchases are sandbox and never charged, but only work once both products are attached to the `premium` entitlement and the default offering in RevenueCat.

## Nov 5 security + App Review audit (needs the migration applied + a new TestFlight build)

Fixed:
- [x] CRITICAL: free scan limit could be bypassed. Any signed-in user could call refund_ai_scan_for on themselves for unlimited free AI scans (real cost), or burn other users' scans. The Oct 1 revoke missed the default PUBLIC grant. New migration `20261105_security_hardening.sql` locks both functions to the edge function only
- [x] RLS reset to a known owner-only set on every table (profiles, check_ins, food_logs, workout_logs, community_posts, community_reports, ai_scan_usage). The originals were never in the repo, so they couldn't be checked
- [x] Community: server rejects posts over 500 chars, names over 40 chars, and names that impersonate the coach or team (Mason, Coach, Admin, Support, FTM Team...). App shows a friendly message for the same rule
- [x] Delete account could fail for anyone whose post was ever reported (report foreign key had no cascade)
- [x] AI consent screen before the first meal scan (Apple guideline 5.1.2(i): third-party AI disclosure, a common rejection since Nov 2025)
- [x] RevenueCat: logging out then quickly into another account could carry the first account's Premium over
- [x] Switching accounts on one phone now also clears the previous person's program pick, training weekdays and block list
- [x] Privacy policy rewritten to match reality: meal photos go to OpenAI via Rork; food/workout logs and photos stay on the phone; adds RevenueCat, Open Food Facts, USDA, Quebec Law 25 / PIPEDA
- [x] Terms + Support no longer say "free at launch"; describe Premium, free trial and cancellation
- [x] Website renamed from TransFit to FTM (support email unchanged)

Still open (you):
- [ ] Apply the migration in Supabase (Rork: "run backend/migrations/20261105_security_hardening.sql") and confirm it ran without errors
- [x] Support email removed everywhere (Nov 5). Replaced by Profile > Help & feedback (messages land in Supabase table support_messages)
- [ ] App Store Connect > App Privacy: declare Health & Fitness, Email, User ID, Photos (meal scans, not linked to you), Purchases
- [x] Premium scans capped at 25/day server-side (Nov 5)

## Nov 5 (afternoon): AI training plans + limits

Built:
- [x] Premium AI plan builder: 8-step questionnaire (goals + focus areas, exact weekdays + session length + work schedule, job/sports/sleep/stress, experience + exact equipment, injuries + binding/top surgery/testosterone with "Prefer not to say", style/cardio/gym comfort/likes/dislikes), AI consent, then a plan with coach notes
- [x] New edge function `generate-plan`: verifies Premium with RevenueCat, 5 builds/day, gpt-4.1 with gpt-4o-mini fallback, validates every field, refunds failed builds
- [x] Safety rules in the prompt: no upper body while recovering from top surgery, never train in a binder, no hormone/medical advice, work around injuries, respect equipment and session length
- [x] Editing goal/level/days/equipment after an AI plan shows "Rebuild" instead of silently swapping in a template
- [x] New Premium members are invited into the builder once, right after subscribing
- [x] Premium meal scans: 25/day cap with a clear message
- [x] Help & feedback form replaces the support email
- [x] Privacy policy covers AI plans and feedback messages

To test on the next TestFlight build:
- [ ] Premium account: Train > Start the plan builder > answer everything > Build. Check the days match the weekdays you picked
- [ ] Try "Recovering (under 3 months)" for top surgery: plan should have no pressing/rows/pull-ups
- [ ] Profile > Help & feedback: send one, confirm it shows in Supabase > support_messages

Security follow-up:
- [ ] The Rork toolkit key was added to the iOS build config as EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY, which puts it inside the app binary. Edge functions now read RORK_TOOLKIT_SECRET_KEY first. Ask Rork to keep the key out of the iOS app, and rotate the key once a build without it ships

## Nov 11: backend caught up + support email

Found: live Supabase was behind the code. generate-plan was never deployed, scan-meal was a month old, and the Nov 5 + Nov 6 migrations had never run (no support_messages table). Premium plans and Help & feedback would have failed on TestFlight.

Done (directly in the Supabase dashboard):
- [x] Ran 20261105_security_hardening.sql (success)
- [x] Ran 20261106_ai_daily_limits_and_feedback.sql (success)
- [x] Deployed scan-meal (25/day Premium cap, clamped numbers, grace period)
- [x] Created + deployed generate-plan. Both functions answer
- [x] Support email: ryan.coughlin@hotmail.com on the Support page (for people locked out)

App Store Connect, Nov 11:
- [x] RevenueCat already correct: premium_monthly + premium_annual on `ftm_pro` and the default offering ($rc_monthly / $rc_annual). App and server both read ftm_pro as Premium
- [x] Premium Monthly "Missing Metadata" was availability: now all 175 regions (matches Annual)
- [x] Privacy Policy URL set
- [x] App Privacy answers filled: Name, Email, Health, Fitness, Other User Content, User ID, Purchase History (linked, app functionality); Photos (not linked). No tracking. **Not published yet**
- [ ] Ryan: accept the updated Apple Developer Program License Agreement (developer.apple.com/account)
- [ ] Ryan: EU trader status (or remove EU from availability)
- [ ] Each subscription needs a review screenshot of the paywall (from the new TestFlight build)
- [ ] 1.0 listing: screenshots, description, keywords, Support URL (/support), copyright, build, reviewer sign-in

Password reset, decided Nov 11:
- Supabase free plan without custom SMTP can't edit email templates and only delivers to the project team, so the reset code flow can't work yet
- For now "Forgot password" says email us; reset by hand in Supabase > Authentication > Users > the user > Send password recovery or set a temporary password
- [ ] At launch: buy a domain, set up custom SMTP (e.g. Resend), paste the code template below, then set `AppInfo.selfServePasswordReset = true`
- [ ] At launch: upgrade Supabase to Pro (Ryan's call)

## Nov 10: launch-blocker sweep (needs a new TestFlight build + two backend steps)

Read every Swift file, both AI functions and all four migrations. Fixed:

Accounts and sign-in
- [x] Forgot password never worked: the email link needs a web page to finish, and there isn't one. Reset now happens in the app: email, then the code from the email plus a new password. **Needs the email template change below**
- [x] A new account created on a phone someone else had used inherited that person's food log, workouts and check-ins, and the check-ins were later uploaded to the new account
- [x] Closing the app during onboarding and reopening skipped onboarding and the trial offer
- [x] Delete account left the dead login saved; next launch dropped the person into onboarding for a deleted account
- [x] Delete account now warns Premium members that it doesn't cancel the subscription (Apple asks for this)
- [x] Onboarding finished with no signal: the profile is now sent on the next launch instead of never
- [x] Sign-up shows "By creating an account you agree to Terms and Privacy" (expected for apps with a community)

Paywall
- [x] Annual plan line read `That's Optional("$8.33")/month`
- [x] "Start free trial" showed even to someone who already used their trial (they'd be charged right away). The app now asks the App Store first
- [x] Restore said "Restore complete" even when the App Store couldn't be reached

Nutrition
- [x] App left open overnight: Nutrition stayed on yesterday, so breakfast went into the wrong day. Home and Train also showed yesterday until something else refreshed them
- [x] Amount 0 logged an empty item; the total shown and the amount logged could differ
- [x] After subscribing from the "free scans used" card, the card stayed up instead of opening the camera
- [x] Food search fired on every keystroke. Open Food Facts allows about 10 searches a minute and blocks apps that go over; search now waits for a pause

Train
- [x] Bodyweight exercises couldn't be logged without typing a weight. Leave weight empty and it logs "Bodyweight x reps"

Profile
- [x] Changing weight, height, age or training days never updated the calorie targets, despite the screen saying they would. They update now unless the targets were set by hand
- [x] Custom calorie target can't be saved below 1,200

Check-in
- [x] Progress photos were saved at 2700 px instead of 900 px (same 3x bug the meal scanner had)
- [x] Photos lived inside the main save file, which is rewritten on every set and food logged. After a few months that's many MB per tap. Photos are now separate files; existing ones move over on first launch

Community
- [x] Blocking someone now also sends a report to moderation (Apple's rule: a block must reach the developer)
- [x] "1 days ago" on posts
- [x] Mason's supplements post was Premium-locked but only said the details were "inside the Prep Team". Reworded and unlocked. **Have Mason check the new wording**

AI functions (redeploy needed)
- [x] Top surgery recovery: the plan builder now strips any upper-body exercise from the plan itself and always adds the surgeon-clearance note, instead of trusting the AI to follow the rule
- [x] Billing grace period (failed renewal) no longer drops a paying member to free on the server
- [x] Scan results: negative or absurd numbers from the AI are clamped

App Store
- [x] iPhone was allowed to rotate to landscape, where the tab bar and camera break. Portrait only now
- [x] App is now iPhone-only. It was set to iPhone + iPad, which means iPad screenshots, an iPad layout Apple reviews, and no way to drop iPad after the first release. iPad users can still install it. Say the word if you want iPad back
- [x] Website: removed "Free at launch", "email us", and "premium coaching content"

Your steps:
- [ ] Supabase > Authentication > Emails > Reset Password: put the code in the email. Body:
      `<h2>Reset your FTM password</h2><p>Enter this code in the app:</p><p style="font-size:24px"><strong>{{ .Token }}</strong></p><p>It expires in 1 hour. If you didn't ask for this, ignore this email.</p>`
- [ ] Redeploy `generate-plan` and `scan-meal` (Rork: "deploy the backend functions")
- [ ] New TestFlight build, then test: forgot password, sign up a second account on the same phone, log a bodyweight set, change your weight in Profile and watch the targets move
- [ ] Decide on a support email. Apple requires a Support URL where people can reach you, and the page currently only points to the in-app form, which someone locked out of their account can't open

Still open from before:
- [ ] RevenueCat: both products attached to `premium` entitlement and the default offering
- [ ] The AI key still ships inside the app (EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY in the iOS build config). Ask Rork to remove it from the iOS app, then rotate it
- [ ] App Store Connect > App Privacy answers
