import LegalLayout from "@/components/LegalLayout";

const SUPPORT_EMAIL = "support@transfit.app";

export default function Privacy() {
  return (
    <LegalLayout
      title="Privacy Policy"
      updated="19 August 2026"
      intro="TransFit is built for the trans masculine community, and we know privacy is not a formality here — it can be a safety issue. This policy explains exactly what we store, why, and how you can delete it. We do not sell your data, ever, to anyone."
    >
      <h2>The short version</h2>
      <ul>
        <li>We store your account email and the fitness data you choose to enter.</li>
        <li>We never sell or rent your personal data, and we do not run third-party ad tracking.</li>
        <li>We do not require your legal name, gender marker, or any medical documentation.</li>
        <li>Community posts you write are visible to other users — under a display name you choose. Your email is never shown.</li>
        <li>You can delete your account and all associated data from inside the app at any time.</li>
      </ul>

      <h2>Information we collect</h2>

      <h3>Account information</h3>
      <p>
        When you create an account we store your <strong>email address</strong> and a securely hashed
        password. We never store your password in readable form. Your display name is whatever you
        choose to enter — it does not need to match any legal document.
      </p>

      <h3>Fitness and wellbeing information</h3>
      <p>
        TransFit stores the information you enter so it can sync across your devices and show your
        history. This includes:
      </p>
      <ul>
        <li>Training goal, experience level, weekly availability, lifestyle, and equipment access from onboarding</li>
        <li>Optional body stats such as height, weight, and age</li>
        <li>Workout logs — exercises, sets, reps, and weights</li>
        <li>Food logs and nutrition targets</li>
        <li>Weekly check-ins — energy, sleep, stress, hunger ratings, workout adherence, and any notes you write</li>
      </ul>
      <p>
        Some of this may be considered health-related information. We treat it accordingly: it is
        stored on access-controlled servers, is only readable by your own account, and is never used
        for advertising.
      </p>

      <h3>Community content</h3>
      <p>
        If you post in the community feed, we store the display name you typed for that post and the
        post text itself, and both are visible to other signed-in users. Your email address is
        <strong>never</strong> attached to a post. When you report a post, we store the report and
        the reason you selected so a moderator can review it; the person you reported is not told
        who reported them. Deleting your account deletes your posts as well.
      </p>

      <h3>What we do not collect</h3>
      <ul>
        <li>We do not collect your legal name, gender marker, or transition documentation.</li>
        <li>We do not collect your precise location.</li>
        <li>We do not access your device contacts, photos, or health app data unless you explicitly grant it for a specific feature.</li>
        <li>We do not use third-party advertising or cross-app tracking SDKs.</li>
      </ul>

      <h2>How we use your information</h2>
      <ul>
        <li>To provide the core app: saving your logs, check-ins, and programs and syncing them to your devices.</li>
        <li>To generate personalized training and nutrition suggestions on your device.</li>
        <li>To keep the community feed safe: reviewing reported posts and enforcing the community guidelines.</li>
        <li>To respond to you when you contact support.</li>
        <li>To diagnose crashes and fix bugs using aggregated, non-identifying diagnostics.</li>
      </ul>
      <p>
        We do not use your data to train public AI models, and we do not share your check-in notes
        with other users.
      </p>

      <h2>Plan generation happens on your device</h2>
      <p>
        Your training and nutrition plans are built by rules running entirely inside the app — on
        your phone. Nothing about you is sent to an AI provider to build a plan, and the generator
        works offline. If we ever add cloud-based AI features, we will update this policy before
        they launch.
      </p>

      <h2>Service providers</h2>
      <p>We use a small number of vetted providers to run the service:</p>
      <ul>
        <li><strong>Supabase</strong> — database hosting, authentication, and community feed storage.</li>
        <li><strong>Apple</strong> — app distribution and, if you subscribe, payment processing. Apple handles all payment details; we never see your card information.</li>
      </ul>

      <h2>Data retention and deletion</h2>
      <p>
        We keep your data for as long as your account exists. You can delete your account at any time
        from <strong>Profile → Delete account</strong> inside the app. Deleting your account removes
        your profile, logs, check-ins, notes, and community posts from our production database.
        Encrypted backups roll off within 30 days.
      </p>
      <p>
        You may also email <a href={`mailto:${SUPPORT_EMAIL}`}>{SUPPORT_EMAIL}</a> to request access
        to, correction of, or deletion of your data. We respond within 30 days.
      </p>

      <h2>Your rights</h2>
      <p>
        Depending on where you live — including under the UK GDPR, EU GDPR, and CCPA — you may have
        the right to access, correct, export, delete, or restrict processing of your personal data,
        and to object to certain processing. TransFit does not sell personal information as defined
        under the CCPA. To exercise any of these rights, email{" "}
        <a href={`mailto:${SUPPORT_EMAIL}`}>{SUPPORT_EMAIL}</a>.
      </p>

      <h2>Security</h2>
      <p>
        Data is encrypted in transit using TLS and encrypted at rest by our database provider. Access
        rules ensure your rows can only be read by your own authenticated account. No system is
        perfectly secure, but we treat this data as sensitive and design accordingly.
      </p>

      <h2>Children</h2>
      <p>
        TransFit is not directed at children under 13, and we do not knowingly collect data from
        them. If you believe a child has given us personal data, contact us and we will delete it.
      </p>

      <h2>Changes to this policy</h2>
      <p>
        If we make a material change to how we handle your data, we will update this page and notify
        you in the app before the change takes effect.
      </p>

      <h2>Contact</h2>
      <p>
        Questions about privacy? Email <a href={`mailto:${SUPPORT_EMAIL}`}>{SUPPORT_EMAIL}</a>.
      </p>
    </LegalLayout>
  );
}
