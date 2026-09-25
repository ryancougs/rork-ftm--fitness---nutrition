import LegalLayout from "@/components/LegalLayout";

const SUPPORT_EMAIL = "support@transfit.app";

export default function Terms() {
  return (
    <LegalLayout
      title="Terms of Use"
      updated="19 August 2026"
      intro="These terms cover your use of the TransFit app. The most important part is the health disclaimer — please read that section carefully before following any training or nutrition content in the app."
    >
      <h2>Health disclaimer — please read</h2>
      <p>
        <strong>
          TransFit provides general fitness and nutrition education. It is not medical advice,
          diagnosis, or treatment, and it is not a substitute for care from a qualified healthcare
          professional.
        </strong>
      </p>
      <ul>
        <li>
          Talk to your doctor before starting any new exercise or nutrition program, especially if
          you have an existing health condition, are pregnant, are recovering from surgery, or are
          taking any medication.
        </li>
        <li>
          Content that touches on hormones, gender-affirming surgery recovery, diabetes management,
          or performance-enhancing drugs is <strong>educational and informational only</strong>. Any
          decision in these areas belongs between you and your own medical team.
        </li>
        <li>
          Never delay seeking medical advice, or disregard advice you have been given, because of
          something you read in this app.
        </li>
        <li>Stop exercising and seek medical attention if you feel faint, dizzy, or experience pain.</li>
      </ul>
      <p>
        You use the training and nutrition content in TransFit at your own risk, and you are
        responsible for exercising within your own limits.
      </p>

      <h2>Your account</h2>
      <p>
        You need an account to use TransFit. Keep your login details secure — you are responsible for
        activity under your account. You must be at least 13 years old to create one. Do not share an
        account with someone else.
      </p>

      <h2>Acceptable use</h2>
      <p>You agree not to:</p>
      <ul>
        <li>Harass, threaten, out, or endanger another member of the community.</li>
        <li>Copy, resell, or redistribute paid coaching content without permission.</li>
        <li>Attempt to break, probe, or overload the service.</li>
        <li>Use the app for anything unlawful.</li>
      </ul>
      <p>
        This is a community built on safety. We reserve the right to suspend accounts that put other
        members at risk.
      </p>

      <h2>Free and paid content</h2>
      <p>
        TransFit is free to use at launch. Some coaching content is marked as premium and may require
        a subscription. Where a subscription exists, the price, duration, and renewal terms are shown
        before you buy. Subscriptions purchased through the App Store are billed by Apple and renew
        automatically until cancelled; you can manage or cancel them in your Apple account settings.
        Refund requests for App Store purchases are handled by Apple.
      </p>

      <h2>Your content</h2>
      <p>
        Your logs, notes, and check-ins belong to you. You grant us only the permission needed to
        store and display that content back to you as part of running the service.
      </p>

      <h2>Availability</h2>
      <p>
        We work to keep TransFit running, but we do not guarantee uninterrupted or error-free
        service. Features described as "coming soon" are plans, not promises, and may change.
      </p>

      <h2>Limitation of liability</h2>
      <p>
        To the fullest extent permitted by law, TransFit and its operators are not liable for
        indirect or consequential damages arising from your use of the app, including injury
        resulting from exercise or dietary choices you make. Nothing in these terms limits liability
        that cannot lawfully be limited.
      </p>

      <h2>Changes</h2>
      <p>
        We may update these terms. If a change is material, we will notify you in the app. Continuing
        to use TransFit after a change means you accept the updated terms.
      </p>

      <h2>Contact</h2>
      <p>
        Questions? Email <a href={`mailto:${SUPPORT_EMAIL}`}>{SUPPORT_EMAIL}</a>.
      </p>
    </LegalLayout>
  );
}
