"use client";

import { useState } from "react";
import { Menu, X } from "lucide-react";
import { Logo } from "@/components/landing/atoms";
import { goal } from "@/lib/ym";

const NAV_LINKS = [
  { label: "Тарифы", href: "#tariffs" },
  { label: "Внедрение", href: "#process" },
  { label: "Демо", href: "#demo" },
  { label: "Битрикс24", href: "#bitrixgpt" },
  { label: "Интеграции", href: "#integrations" },
  { label: "Кейсы", href: "#case" },
  { label: "FAQ", href: "#faq" },
] as const;

export function Header() {
  const [open, setOpen] = useState(false);

  return (
    <header className="fixed inset-x-0 top-4 z-50 px-4">
      <div className="mx-auto max-w-7xl">
        {/* Main floating bar */}
        <div
          className="flex items-center justify-between rounded-2xl border border-[var(--color-border)] bg-white/80 px-5 py-3 shadow-sm backdrop-blur-md"
        >
          {/* Logo */}
          <Logo />

          {/* Desktop nav — center */}
          <nav
            className="hidden items-center gap-6 text-sm text-muted-foreground lg:flex"
            aria-label="Основная навигация"
          >
            {NAV_LINKS.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className="rounded-sm transition-colors duration-150 hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-brand)] focus-visible:ring-offset-2"
              >
                {link.label}
              </a>
            ))}
          </nav>

          {/* Right: phone + CTA + burger */}
          <div className="flex items-center gap-3">
            {/* Phone block — visible on lg+ */}
            <div className="hidden text-right lg:block">
              <a
                href="tel:+79287051199"
                className="block text-sm font-semibold text-foreground transition-colors hover:text-[var(--color-brand)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-brand)] focus-visible:ring-offset-2 rounded-sm"
              >
                +7 928-705-11-99
              </a>
            </div>

            {/* CTA button — visible on lg+ (desktop only) */}
            <a
              href="#contact"
              onClick={() => goal('header_cta')}
              className="hidden rounded-xl px-4 py-2 text-sm font-semibold text-white transition-opacity hover:opacity-90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-brand)] focus-visible:ring-offset-2 lg:inline-flex lg:items-center"
              style={{ background: "var(--gradient-brand)" }}
            >
              Записаться на разбор
            </a>

            {/* Burger — visible below lg */}
            <button
              type="button"
              className="grid size-9 place-items-center rounded-xl border border-[var(--color-border)] bg-white text-foreground transition-colors hover:bg-[var(--color-surface-soft)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-brand)] focus-visible:ring-offset-2 lg:hidden"
              aria-expanded={open}
              aria-controls="mobile-nav"
              aria-label={open ? "Закрыть меню" : "Открыть меню"}
              data-testid="burger"
              onClick={() => setOpen((prev) => !prev)}
            >
              {open ? <X className="size-5" /> : <Menu className="size-5" />}
            </button>
          </div>
        </div>

        {/* Mobile drawer */}
        {open && (
          <div
            id="mobile-nav"
            className="mt-2 rounded-2xl border border-[var(--color-border)] bg-white px-4 py-5 shadow-md lg:hidden"
            role="navigation"
            aria-label="Мобильное меню"
          >
            <nav className="flex flex-col" aria-label="Мобильная навигация">
              {NAV_LINKS.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  className="rounded-xl px-3 py-2.5 text-sm font-medium text-muted-foreground transition-colors hover:bg-[var(--color-surface-soft)] hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-brand)] focus-visible:ring-offset-2"
                  onClick={() => setOpen(false)}
                >
                  {link.label}
                </a>
              ))}
            </nav>

            <div className="mt-4 flex flex-col gap-3 border-t border-[var(--color-border)] pt-4">
              <a
                href="tel:+79287051199"
                className="text-sm font-semibold text-foreground transition-colors hover:text-[var(--color-brand)]"
              >
                +7 928-705-11-99
              </a>
              <a
                href="#contact"
                onClick={() => { setOpen(false); goal('header_cta'); }}
                className="flex w-full items-center justify-center rounded-xl px-4 py-2.5 text-sm font-semibold text-white transition-opacity hover:opacity-90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-brand)] focus-visible:ring-offset-2"
                style={{ background: "var(--gradient-brand)" }}
              >
                Записаться на разбор
              </a>
            </div>
          </div>
        )}
      </div>
    </header>
  );
}
