import { Link } from "react-router-dom";
import { Leaf, ShieldCheck, HeartPulse, NotebookPen, Dumbbell } from "lucide-react";

const FEATURES = [
  {
    icon: Dumbbell,
    title: "Training that fits your frame",
    body: "Programs built around trans masculine goals — X-frame development, strength, and getting comfortable in the gym.",
  },
  {
    icon: HeartPulse,
    title: "Weekly wellbeing check-ins",
    body: "Energy, sleep, stress, and hunger. Because how you feel matters more than a number on a scale.",
  },
  {
    icon: NotebookPen,
    title: "Fueling, not restriction",
    body: "Whole-food nutrition tracking framed around fueling your body well, never around shame.",
  },
  {
    icon: ShieldCheck,
    title: "A coach who lives it",
    body: "Mason is a transgender bodybuilding competitor, BSc, MSc, functional health coach, and Type 1 Diabetic.",
  },
] as const;

export default function Index() {
  return (
    <div className="min-h-screen bg-background">
      <header className="border-b border-border/60">
        <div className="mx-auto flex max-w-5xl items-center justify-between px-6 py-4">
          <span className="flex items-center gap-2 font-bold tracking-tight text-foreground">
            <span className="grid h-8 w-8 place-items-center rounded-xl bg-primary text-primary-foreground">
              <Leaf className="h-4 w-4" />
            </span>
            TransFit
          </span>
          <nav className="flex gap-5 text-sm font-medium text-muted-foreground">
            <Link to="/support" className="transition-colors hover:text-primary">
              Support
            </Link>
            <Link to="/privacy" className="transition-colors hover:text-primary">
              Privacy
            </Link>
          </nav>
        </div>
      </header>

      <main>
        <section className="relative overflow-hidden">
          <div
            aria-hidden
            className="pointer-events-none absolute -top-40 left-1/2 h-[28rem] w-[52rem] -translate-x-1/2 rounded-full bg-accent/25 blur-3xl"
          />
          <div className="relative mx-auto max-w-3xl px-6 py-24 text-center">
            <span className="inline-flex items-center gap-2 rounded-full border border-border bg-card px-4 py-1.5 text-xs font-semibold uppercase tracking-[0.14em] text-primary">
              Free at launch
            </span>
            <h1 className="mt-7 text-4xl font-bold leading-[1.08] tracking-tight text-foreground sm:text-6xl">
              The only FTM fitness
              <br />
              app you&apos;ll need.
            </h1>
            <p className="mx-auto mt-6 max-w-xl text-lg leading-relaxed text-muted-foreground">
              A space where you don&apos;t have to explain yourself before you start training.
              Strength, nutrition, and wellbeing — built for the trans masculine community by a coach
              who lives it.
            </p>
            <p className="mt-8 text-sm font-medium text-muted-foreground">
              Coming soon to the App Store.
            </p>
          </div>
        </section>

        <section className="mx-auto max-w-5xl px-6 pb-24">
          <div className="grid gap-4 sm:grid-cols-2">
            {FEATURES.map((feature) => (
              <article
                key={feature.title}
                className="rounded-2xl border border-border bg-card p-6 transition-shadow hover:shadow-sm"
              >
                <span className="grid h-10 w-10 place-items-center rounded-xl bg-accent/25 text-primary">
                  <feature.icon className="h-5 w-5" />
                </span>
                <h2 className="mt-4 text-base font-bold tracking-tight text-foreground">
                  {feature.title}
                </h2>
                <p className="mt-2 text-sm leading-relaxed text-muted-foreground">{feature.body}</p>
              </article>
            ))}
          </div>

          <p className="mt-10 rounded-2xl border border-border bg-secondary/50 p-6 text-sm leading-relaxed text-muted-foreground">
            <strong className="font-semibold text-foreground">A note on health:</strong> TransFit
            provides general fitness and nutrition education. It is not medical advice. Content
            relating to hormones, surgery recovery, or performance-enhancing drugs is informational
            only — always speak with your own healthcare provider.
          </p>
        </section>
      </main>

      <footer className="border-t border-border/60 py-10">
        <div className="mx-auto flex max-w-5xl flex-col gap-3 px-6 text-sm text-muted-foreground sm:flex-row sm:items-center sm:justify-between">
          <span>© {new Date().getFullYear()} TransFit</span>
          <nav className="flex gap-5">
            <Link to="/privacy" className="transition-colors hover:text-primary">
              Privacy
            </Link>
            <Link to="/terms" className="transition-colors hover:text-primary">
              Terms
            </Link>
            <Link to="/support" className="transition-colors hover:text-primary">
              Support
            </Link>
          </nav>
        </div>
      </footer>
    </div>
  );
}
