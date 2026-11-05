import LegalLayout from "@/components/LegalLayout";

const APP_NAME = "FTM: Fitness & Nutrition";

export default function Privacy() {
  return (
    <LegalLayout
      title="Privacy Policy"
      updated="5 November 2026"
      intro={`${APP_NAME} ("FTM") is built for the trans masculine community, and we know privacy is not a formality here. It can be a safety issue. This policy explains exactly what we store, where it goes, and how you can delete it. We do not sell your data, ever, to anyone.`}
    >
      <h2>The short version</h2>
      <ul>
        <li>We store your account email, your profile, and your weekly check-ins on our servers.</li>
        <li>Your food logs, workout logs, and progress photos stay on your phone.</li>
        <li>If you use AI meal scanning, the meal photo is sent to an AI provider to estimate calories. We don't save it.</li>
        <li>If you build an AI training plan, your plan builder answers are sent to an AI provider to write it. We don't save them on our server.</li>
        <li>We never sell or rent your personal data, and we do not run third-party ad tracking.</li>
        <li>We do not require your legal name, gender marker, or any medical documentation.</li>
        <li>Community posts are visible to other signed-in users under a display name you choose. Your email is never shown.</li>
        <li>You can delete your account and all associated data from inside the app at any time.</li>
      </ul>

      <h2>Information we collect</h2>

      <h3>Account information</h3>
      <p>
        When you create an account we store your <strong>email address</strong> and a securely hashed
        password. We never store your password in readable form. Your display name is whatever you
        choose to enter. It does not need to match any legal document.
      </p>

      <h3>Stored on our servers</h3>
      <ul>
        <li>Your profile: name you entered, training goal, experience level, weekly availability, lifestyle, and equipment access</li>
        <li>Optional body stats such as height, weight, and age, plus your calorie and macro targets</li>
        <li>Weekly check-ins: energy, sleep, stress, and hunger ratings, workout adherence, and any notes you write</li>
        <li>How many AI scans and plan builds you've used (counts only, not photos or answers)</li>
        <li>Messages you send us from Help &amp; feedback, and your email if you ask for a reply</li>
      </ul>
      <p>
        Some of this may be considered health-related information. We treat it accordingly: it is
        stored on access-controlled servers, is only readable by your own account, and is never used
        for advertising.
      </p>

      <h3>Stored only on your phone</h3>
      <p>
        Food logs, workout logs (exercises, sets, reps, and weights), favorite and recent foods, and
        check-in progress photos are saved on your device only. We cannot see them, and they are
        removed if you delete the app or your account. If we add cloud sync for these later, we will
        update this policy first.
      </p>

      <h3>Community content</h3>
      <p>
        If you post in the community feed, we store the display name you typed for that post and the
        post text itself, and both are visible to other signed-in users. Your email address is{" "}
        <strong>never</strong> attached to a post. When you report a post, we store the report and
        the reason you selected so a moderator can review it; the person you reported is not told
        who reported them. If you block someone, that list stays on your phone. Deleting your
        account deletes your posts as well.
      </p>

      <h3>What we do not collect</h3>
      <ul>
        <li>We do not collect your legal name, gender marker, or transition documentation.</li>
        <li>We do not collect your precise location.</li>
        <li>We do not access your contacts or health app data.</li>
        <li>We only access the camera or a photo when you choose to scan a meal, scan a barcode, or add a check-in photo.</li>
        <li>We do not use third-party advertising or cross-app tracking SDKs.</li>
      </ul>

      <h2>AI meal scanning</h2>
      <p>
        Meal scanning is optional, and the app asks for your permission before your first scan. When
        you scan a meal, the photo is sent to our server and then to an AI model from{" "}
        <strong>OpenAI</strong> (through our AI service provider, Rork) to estimate the foods,
        calories, and macros on the plate. The photo is used only to produce that estimate. We do not
        save it or attach it to your account, and our providers do not use it to train AI models.
        OpenAI may keep API requests for a limited time for abuse monitoring under its own policies. Only the photo is sent: no
        name, email, or other profile details go with it. AI estimates can be wrong, so please check
        them before logging.
      </p>

      <h2>AI training plans (Premium)</h2>
      <p>
        Premium members can answer a plan builder questionnaire: goals, schedule, job and work
        hours, sleep, stress, other activities, training experience, equipment, injuries,
        preferences, and optional questions about binding, top surgery, and testosterone (each has
        a "Prefer not to say" option). The app asks for your permission before sending anything.
        When you tap Build my plan, these answers plus your goal, experience level, age, height, and
        weight are sent to our server and to an AI model from <strong>OpenAI</strong> (through
        Rork) to write your program. Your name and email are not sent. We do not save your answers
        on our server; they stay on your phone so you can edit them and rebuild later. Our providers
        do not use them to train AI models.
      </p>
      <p>
        Free plans and nutrition targets are still built by rules running inside the app, without
        any AI provider.
      </p>

      <h2>How we use your information</h2>
      <ul>
        <li>To provide the core app: your profile, targets, check-ins, and programs.</li>
        <li>To estimate the nutrition in meal photos you choose to scan, and to write your AI training plan if you ask for one.</li>
        <li>To manage your subscription and the free and daily AI limits.</li>
        <li>To keep the community feed safe: reviewing reported posts and enforcing the community guidelines.</li>
        <li>To respond to you when you contact support.</li>
      </ul>
      <p>
        We do not use your data to train AI models, and we do not share your check-in notes with
        other users.
      </p>

      <h2>Service providers</h2>
      <p>We use a small number of providers to run the service:</p>
      <ul>
        <li><strong>Supabase</strong>: database hosting, authentication, and community feed storage.</li>
        <li><strong>Rork and OpenAI</strong>: AI meal scan estimates and AI training plans (the photo or your plan answers only, not saved by us).</li>
        <li><strong>RevenueCat</strong>: subscription status. It receives an anonymous account ID and your purchase history from Apple, not your email.</li>
        <li><strong>Apple</strong>: app distribution and payment processing. Apple handles all payment details; we never see your card information.</li>
        <li><strong>Open Food Facts and USDA FoodData Central</strong>: food search and barcode lookups. They receive the search text or barcode, not your identity.</li>
      </ul>

      <h2>Data retention and deletion</h2>
      <p>
        We keep your data for as long as your account exists. You can delete your account at any time
        from <strong>Profile, then Delete account</strong> inside the app. Deleting your account
        removes your profile, check-ins, notes, scan count, and community posts from our production
        database, and clears the data stored on your phone. Encrypted backups roll off within 30 days.
      </p>
      <p>
        You can also ask for a copy, correction, or deletion of your data from <strong>Profile, then Help &amp; feedback</strong> in the app. We
        respond within 30 days.
      </p>

      <h2>Your rights</h2>
      <p>
        Depending on where you live, including under the UK GDPR, EU GDPR, Quebec Law 25, PIPEDA, and
        the CCPA, you may have the right to access, correct, export, delete, or restrict processing
        of your personal data, and to object to certain processing. We do not sell personal
        information as defined under the CCPA. To exercise any of these rights, message us from <strong>Profile, then Help &amp; feedback</strong> in the app.
      </p>

      <h2>Security</h2>
      <p>
        Data is encrypted in transit using TLS and encrypted at rest by our database provider. Access
        rules ensure your rows can only be read by your own authenticated account. No system is
        perfectly secure, but we treat this data as sensitive and design accordingly.
      </p>

      <h2>Children</h2>
      <p>
        {APP_NAME} is not directed at children under 13, and we do not knowingly collect data from
        them. If you believe a child has given us personal data, contact us and we will delete it.
      </p>

      <h2>Changes to this policy</h2>
      <p>
        If we make a material change to how we handle your data, we will update this page and notify
        you in the app before the change takes effect.
      </p>

      <h2>Contact</h2>
      <p>
        Questions about privacy? Message us from <strong>Profile, then Help &amp; feedback</strong> in the app.
      </p>
    </LegalLayout>
  );
}
