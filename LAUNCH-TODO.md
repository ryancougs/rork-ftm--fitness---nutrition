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
