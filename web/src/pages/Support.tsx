import LegalLayout from "@/components/LegalLayout";

const SUPPORT_EMAIL = "support@transfit.app";

export default function Support() {
  return (
    <LegalLayout
      title="Support"
      updated="19 August 2026"
      intro="Something not working, or you want to tell us what TransFit is missing? We read every message. Most replies go out within two working days."
    >
      <h2>Contact us</h2>
      <p>
        Email <a href={`mailto:${SUPPORT_EMAIL}`}>{SUPPORT_EMAIL}</a>. To help us fix things fast,
        include your device model, your iOS version, and what you were doing when the problem
        happened. Screenshots are welcome.
      </p>

      <h2>Common questions</h2>

      <h3>Is TransFit free?</h3>
      <p>
        Yes — TransFit is free at launch. Some of Mason's coaching content is marked premium. If a
        subscription is added later, the price and terms will always be shown before you pay,
        nothing will start charging you silently, and the core tracking features stay free.
      </p>

      <h3>Do I have to disclose anything about being trans?</h3>
      <p>
        No. TransFit never asks for your legal name, gender marker, or any medical documentation.
        Onboarding asks for a display name, your training goal, and your experience level. Body
        stats are optional and you can skip them.
      </p>

      <h3>How do I delete my account and data?</h3>
      <p>
        Open <strong>Profile → Delete account</strong> in the app. This permanently removes your
        profile, workout logs, food logs, and check-ins. You can also email us and we will handle it
        within 30 days.
      </p>

      <h3>Is my check-in data private?</h3>
      <p>
        Yes. Your check-in ratings and notes are visible only to your own account. They are not
        shared with other users and are never used for advertising. See our{" "}
        <a href="/privacy">Privacy Policy</a> for details.
      </p>

      <h3>Can I use TransFit if I'm not on testosterone?</h3>
      <p>
        Absolutely. The training and nutrition principles work regardless of where you are in your
        journey, or whether hormones are part of your journey at all.
      </p>

      <h3>Is the coaching content medical advice?</h3>
      <p>
        No. Everything in TransFit is general fitness and nutrition education. Content touching on
        hormones, surgery recovery, or performance-enhancing drugs is informational only — always
        talk to your own doctor before acting on it. See our <a href="/terms">Terms of Use</a>.
      </p>

      <h3>I found a bug or my data looks wrong</h3>
      <p>
        Email us with a screenshot and roughly when it happened. If data appears missing, do not
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
