import { Link } from "react-router-dom";
import { ArrowLeft, Leaf } from "lucide-react";
import type { ReactNode } from "react";

interface LegalLayoutProps {
  title: string;
  updated: string;
  intro?: string;
  children: ReactNode;
}

/** Shared shell for the legal / support pages: brand header, readable column, footer. */
export default function LegalLayout({ title, updated, intro, children }: LegalLayoutProps) {
  return (
    <div className="min-h-screen bg-background">
      <header className="border-b border-border/60 bg-card/60 backdrop-blur">
        <div className="mx-auto flex max-w-3xl items-center justify-between px-6 py-4">
          <Link to="/" className="flex items-center gap-2 font-bold tracking-tight text-foreground">
            <span className="grid h-8 w-8 place-items-center rounded-xl bg-primary text-primary-foreground">
              <Leaf className="h-4 w-4" />
            </span>
            TransFit
          </Link>
          <Link
            to="/"
            className="inline-flex items-center gap-1.5 text-sm font-medium text-muted-foreground transition-colors hover:text-primary"
          >
            <ArrowLeft className="h-4 w-4" />
            Home
          </Link>
        </div>
      </header>

      <main className="mx-auto max-w-3xl px-6 py-14">
        <p className="mb-3 text-xs font-semibold uppercase tracking-[0.18em] text-accent-foreground/70">
          TransFit
        </p>
        <h1 className="text-3xl font-bold tracking-tight text-foreground sm:text-4xl">{title}</h1>
        <p className="mt-3 text-sm text-muted-foreground">Last updated: {updated}</p>
        {intro ? (
          <p className="mt-6 rounded-2xl border border-border bg-card p-5 text-[15px] leading-relaxed text-muted-foreground">
            {intro}
          </p>
        ) : null}
        <div className="legal-prose mt-4">{children}</div>
      </main>

      <footer className="border-t border-border/60 py-10">
        <div className="mx-auto flex max-w-3xl flex-col gap-3 px-6 text-sm text-muted-foreground sm:flex-row sm:items-center sm:justify-between">
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
