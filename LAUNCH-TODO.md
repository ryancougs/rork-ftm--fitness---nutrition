# FTM (TransFit) — Launch To-Do

**Goal: in TestFlight by end of day tomorrow (Oct 24), with a few testers trying it.**
Come back to this list anytime — it lives in the project so it never gets lost.

## 1. RevenueCat paid products (you + me, needs the dashboard)

- [ ] Confirm the two products exist and are attached to App Store Connect subscriptions: `premium_monthly`, `premium_annual`
- [ ] **Change the price** — DECISION NEEDED FROM YOU: what should the new price(s) be? (Currently $9.99/mo, $49.99/yr)
- [ ] **Dial down the offer** — DECISION NEEDED: shorter/longer free trial? (Currently 7-day trial on annual) — trial is set in App Store Connect, then mirrored in RevenueCat
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

- [ ] Sweep for anything looking unfinished (spacing, contrast, leftover default styling)
- [ ] Fresh eyes on Home, Nutrition, Train, Community, Profile — one polish pass, no rebuilds

## 5. TestFlight (me)

- [ ] Start the build upload as soon as you say go (needs your Rork plan active)
- [ ] You install from TestFlight on your iPhone and run a real user session
- [ ] Add your few testers via App Store Connect → TestFlight → internal testers
- [ ] Demo account for Apple's reviewer (email/password they can sign in with)

## 6. App Store submission (after TestFlight looks good)

- [ ] Screenshots (I generate), listing text (I draft, you approve)
- [ ] Privacy policy URL: https://2gxfo9qxolcyjgbzbeaoj-web.rork.live/privacy ✅ already live
- [ ] Submit for review — Apple takes 1–3 days
