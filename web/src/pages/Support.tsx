import LegalLayout from "@/components/LegalLayout";

export default function Support() {
  return (
    <LegalLayout
      title="Support"
      updated="5 November 2026"
      intro="Something not working, or you want to tell us what FTM is missing? We read every message. Most replies go out within two working days."
    >
      <h2>Contact us</h2>
      <p>
        Send us a message from <strong>Profile, then Help &amp; feedback</strong> in the app. A real person reads every message, and you can choose
        to get a reply by email. To help us fix things fast, say which screen you were on, what you
        tapped, and any error code you saw (like S503).
      </p>

      <h2>Common questions</h2>

      <h3>Is FTM free?</h3>
      <p>
        Yes, the core tracking features are free, including ready-made training plans and 3 AI meal
        scans a week. FTM Premium adds an AI-built training plan, unlimited scans (a fair-use daily cap applies),
        the barcode scanner, custom goals and 30 and 90 day trends, with a free trial for new members. The price is always
        shown before you pay, and you can cancel any time in your Apple account settings.
      </p>

      <h3>Do I have to disclose anything about being trans?</h3>
      <p>
        No. FTM never asks for your legal name, gender marker, or any medical documentation.
        Onboarding asks for a display name, your training goal, and your experience level. Body
        stats are optional and you can skip them.
      </p>

      <h3>How do I delete my account and data?</h3>
      <p>
        Open <strong>Profile → Delete account</strong> in the app. This permanently removes your
        profile, workout logs, food logs, and check-ins. You can also ask us in Profile, then Help &amp; feedback, and we will handle it
        within 30 days.
      </p>

      <h3>Is my check-in data private?</h3>
      <p>
        Yes. Your check-in ratings and notes are visible only to your own account. They are not
        shared with other users and are never used for advertising. See our{" "}
        <a href="/privacy">Privacy Policy</a> for details.
      </p>

      <h3>Can I use FTM if I'm not on testosterone?</h3>
      <p>
        Absolutely. The training and nutrition principles work regardless of where you are in your
        journey, or whether hormones are part of your journey at all.
      </p>

      <h3>Is the coaching content medical advice?</h3>
      <p>
        No. Everything in FTM is general fitness and nutrition education. Content touching on
        hormones, surgery recovery, or performance-enhancing drugs is informational only — always
        talk to your own doctor before acting on it. See our <a href="/terms">Terms of Use</a>.
      </p>

      <h3>I found a bug or my data looks wrong</h3>
      <p>
        Tell us in Profile, then Help &amp; feedback, and include roughly when it happened. If data appears missing, do not
        delete and reinstall the app before contacting us — that can make it harder to recover.
      </p>

      <h2>Feature requests</h2>
      <p>
        Group chat, gym buddies, a cookbook, pre- and post-surgery guides, and contests are all on
        the roadmap. If you want something else, tell us — this app is being built with the
        community, not just for it.
      </p>
    </LegalLayout>
  );
}
