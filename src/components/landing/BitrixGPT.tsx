"use client";

import { Container, Pill, Reveal } from "@/components/landing/atoms";
import { Button } from "@/components/ui/button";
import { goal } from "@/lib/ym";
import { ExternalLink } from "lucide-react";

/* ─── Data ─────────────────────────────────────────────────── */

interface GptTariff {
  name: string;
  subtitle: string;
  price: string;
  oldPrice: string;
  popular?: boolean;
}

const GPT_TARIFFS: GptTariff[] = [
  {
    name: "Базовый",
    subtitle: "5 польз. · 24 ГБ",
    price: "500 ₽",
    oldPrice: "1 000 ₽",
  },
  {
    name: "Стандартный",
    subtitle: "50 польз. · 100 ГБ",
    price: "1 500 ₽",
    oldPrice: "3 000 ₽",
    popular: true,
  },
  {
    name: "Профессиональный",
    subtitle: "100 польз. · 1 ТБ",
    price: "3 000 ₽",
    oldPrice: "6 000 ₽",
  },
  {
    name: "Энтерпрайз",
    subtitle: "250+ польз. · 3 ТБ",
    price: "6 800 ₽",
    oldPrice: "13 600 ₽",
  },
];

const CHECKLIST = [
  "Автоматические ответы клиентам",
  "Расшифровка звонков",
  "Follow-up и встречи",
  "Помощь менеджерам",
  "Внешние AI и MCP-интеграции",
  "BitrixGPT в ленте и задачах",
  "Маркетплейс Битрикс24",
];

/* ─── Section ───────────────────────────────────────────────── */

export function BitrixGPT() {
  return (
    <section
      id="bitrixgpt"
      className="dark-scope relative overflow-hidden py-16 md:py-20"
      style={{ backgroundColor: "var(--dark-blue-2)" }}
    >
      {/* ── Glow decorators ── */}
      <div aria-hidden className="pointer-events-none absolute inset-0 overflow-hidden">
        <div className="absolute -top-20 right-10 size-[240px] sm:size-[480px] rounded-full bg-brand/25 blur-[160px]" />
        <div className="absolute bottom-10 -left-20 size-[360px] rounded-full bg-brand-2/15 blur-[120px]" />
      </div>

      <Container className="relative z-10">
        {/* ── Main dark card ── */}
        <div
          className="overflow-hidden rounded-[32px] p-8 md:p-12"
          style={{
            background: "linear-gradient(135deg, #061A3D 0%, #082A5A 55%, #0A3470 100%)",
            border: "1px solid rgba(0, 109, 255, 0.22)",
            boxShadow: "0 28px 80px rgba(0, 92, 180, 0.20)",
          }}
        >
          {/* Two-column layout: left = text, right = checklist + chip */}
          <div className="grid items-center gap-10 lg:grid-cols-[1fr_1fr]">

            {/* Left: pill + heading + description + CTA */}
            <Reveal>
              <div>
                <Pill variant="dark">Подписка Маркетплейс</Pill>
                <h2 className="mt-5 text-3xl font-extrabold leading-tight text-white sm:text-4xl lg:text-5xl">
                  Искусственный интеллект{" "}
                  <span className="text-gradient">BitrixGPT</span>{" "}
                  + Маркетплейс
                </h2>
                <p className="mt-4 max-w-lg text-base leading-relaxed text-white/60">
                  Ускоряйте продажи, экономьте время и повышайте качество
                  работы команды с помощью AI-технологий и готовых решений из
                  маркетплейса Битрикс24.
                </p>
                <div className="mt-6">
                  <Button
                    asChild
                    className="h-12 rounded-full bg-white px-6 text-[#071A3F] font-semibold hover:bg-white/90 focus-visible:ring-2 focus-visible:ring-white focus-visible:ring-offset-2 focus-visible:ring-offset-transparent"
                  >
                    <a
                      href="https://www.bitrix24.ru/apps/"
                      target="_blank"
                      rel="noopener noreferrer"
                      onClick={() => goal('bitrixgpt_click')}
                    >
                      <span>Узнать больше о BitrixGPT</span>
                      <ExternalLink className="ml-2 size-4" />
                    </a>
                  </Button>
                </div>
              </div>
            </Reveal>

            {/* Right: checklist + chip */}
            <Reveal delay={150}>
              <div className="flex flex-col gap-6 lg:flex-row lg:items-center lg:gap-6">
                {/* Checklist */}
                <ul className="flex flex-col gap-3 flex-1">
                  {CHECKLIST.map((item) => (
                    <li key={item} className="flex items-center gap-3">
                      {/* Cyan filled check circle */}
                      <span
                        aria-hidden
                        className="flex size-6 shrink-0 items-center justify-center rounded-full"
                        style={{ background: "linear-gradient(135deg, #006DFF, #00B7FF)" }}
                      >
                        <svg
                          width="11"
                          height="11"
                          viewBox="0 0 12 12"
                          fill="none"
                          xmlns="http://www.w3.org/2000/svg"
                        >
                          <path
                            d="M2 6l3 3 5-5"
                            stroke="white"
                            strokeWidth="2"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                          />
                        </svg>
                      </span>
                      <span className="text-sm font-medium text-white/90">
                        {item}
                      </span>
                    </li>
                  ))}
                </ul>

                {/* AI chip image — visible lg+ next to checklist */}
                <div className="hidden lg:flex items-center justify-center shrink-0 relative">
                  {/* Radial glow behind chip */}
                  <div
                    aria-hidden
                    className="absolute inset-0 rounded-full"
                    style={{
                      background: "radial-gradient(circle, rgba(0,183,255,0.35) 0%, rgba(0,109,255,0.15) 45%, transparent 70%)",
                      width: "280px",
                      height: "280px",
                      filter: "blur(20px)",
                      transform: "translate(-50%, -50%)",
                      top: "50%",
                      left: "50%",
                    }}
                  />
                  <img
                    src="/assets/images/ai-chip.png"
                    alt="AI-чип BitrixGPT"
                    className="w-[200px] xl:w-[240px] max-w-full select-none animate-chip-float relative z-10"
                    style={{
                      filter: "drop-shadow(0 0 32px rgba(0, 183, 255, 0.65)) drop-shadow(0 12px 24px rgba(0,0,0,0.4))",
                    }}
                    loading="lazy"
                    decoding="async"
                    draggable={false}
                  />
                </div>
              </div>

              {/* AI chip image — visible on mobile/tablet, below checklist */}
              <div className="mt-6 flex justify-center lg:hidden relative">
                <div
                  aria-hidden
                  className="absolute rounded-full pointer-events-none"
                  style={{
                    background: "radial-gradient(circle, rgba(0,183,255,0.3) 0%, transparent 70%)",
                    width: "220px",
                    height: "220px",
                    filter: "blur(16px)",
                    top: "50%",
                    left: "50%",
                    transform: "translate(-50%, -50%)",
                  }}
                />
                <img
                  src="/assets/images/ai-chip.png"
                  alt="AI-чип BitrixGPT"
                  className="w-[160px] sm:w-[200px] max-w-full select-none animate-chip-float relative z-10"
                  style={{
                    filter: "drop-shadow(0 0 24px rgba(0, 183, 255, 0.55)) drop-shadow(0 8px 16px rgba(0,0,0,0.35))",
                  }}
                  loading="lazy"
                  decoding="async"
                  draggable={false}
                />
              </div>
            </Reveal>
          </div>
        </div>

        {/* ── GPT Tariff cards ── */}
        <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {GPT_TARIFFS.map((tariff, i) => (
            <Reveal key={tariff.name} delay={i * 80}>
              <article
                className={`relative flex h-full flex-col glass rounded-2xl p-4 transition-all duration-200 hover:-translate-y-1 ${
                  tariff.popular
                    ? "ring-1 ring-brand/60 shadow-[var(--shadow-glow)]"
                    : ""
                }`}
              >
                {tariff.popular && (
                  <div
                    className="absolute -top-3 left-1/2 -translate-x-1/2 rounded-full bg-gradient-brand px-4 py-1 text-[10px] font-semibold text-white whitespace-nowrap"
                    aria-label="Популярный тариф"
                  >
                    Популярный
                  </div>
                )}

                {/* Header */}
                <div className="mb-2">
                  <p className="text-[10px] font-semibold uppercase tracking-[0.15em] text-[color:var(--color-brand-2)]">
                    Для тарифа
                  </p>
                  <h3 className="mt-1 text-sm font-bold leading-snug text-white">
                    {tariff.name}
                  </h3>
                  <p className="mt-0.5 text-xs text-[color:var(--color-muted-foreground)]">
                    {tariff.subtitle}
                  </p>
                </div>

                {/* Price */}
                <div className="mt-auto border-t border-white/10 pt-3">
                  <div className="flex items-baseline gap-2 flex-wrap">
                    <span className="text-2xl font-bold text-white">
                      {tariff.price}
                    </span>
                    <span className="text-sm text-[color:var(--color-muted-foreground)] line-through">
                      {tariff.oldPrice}
                    </span>
                  </div>
                  <p className="mt-0.5 text-xs text-[color:var(--color-muted-foreground)]">
                    в месяц · −50%
                  </p>
                </div>
              </article>
            </Reveal>
          ))}
        </div>

        {/* ── Disclaimer ── */}
        <Reveal delay={200}>
          <p className="mt-4 text-center text-xs text-[color:var(--color-muted-foreground)]">
            * Скидка 50% для тех, кто покупает облачный тариф впервые. Цены без НДС.{" "}
            Цены соответствуют официальному прайс-листу Битрикс24. Актуальную стоимость уточняйте у менеджера.
          </p>
        </Reveal>
      </Container>
    </section>
  );
}
