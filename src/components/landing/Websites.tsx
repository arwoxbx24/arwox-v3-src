"use client";

import { Check, Clock, Calendar } from "lucide-react";
import {
  Container,
  SectionTitle,
  Reveal,
} from "@/components/landing/atoms";
import { goal } from "@/lib/ym";

/* ─── Data ─────────────────────────────────────────────────── */

const FORMATS = [
  {
    id: "A" as const,
    badge: "Формат А",
    icon3d: "/assets/gen/ic3d-sites.png",
    title: "Ваш шаблон — наша реализация",
    description:
      "Реализуем ваш дизайн на современных технологиях. Pixel-perfect, точно и с гарантией качества.",
    checks: [
      "Следуем макету без изменений",
      "Программирование, CMS, интеграции под ключ",
      "Подключение к Битрикс24 CRM и сквозная аналитика",
    ],
    timingText: "Срок: рассчитывается на брифе",
    TimingIcon: Calendar,
  },
  {
    id: "B" as const,
    badge: "Формат Б",
    icon3d: "/assets/gen/ic3d-robot.png",
    title: "MVP на базе ИИ — быстрый старт",
    description:
      "Создаём MVP сайта с помощью ИИ. Проверяйте гипотезы и запускайтесь быстрее конкурентов.",
    checks: [
      "2–3 варианта дизайна на выбор",
      "Быстрая разработка и запуск",
      "Готов к масштабированию",
    ],
    timingText: "Срок: от 3 рабочих дней",
    TimingIcon: Clock,
  },
] as const;

const STEPS = [
  {
    num: 1,
    icon3d: "/assets/gen/ic3d-docs.png",
    title: "Бриф и анализ",
    desc: "Погружаемся в ваш бизнес и цели проекта.",
  },
  {
    num: 2,
    icon3d: "/assets/gen/ic3d-analytics.png",
    title: "Проектирование",
    desc: "Структура, прототипы, дизайн и ТЗ.",
  },
  {
    num: 3,
    icon3d: "/assets/gen/ic3d-sites.png",
    title: "Разработка",
    desc: "Вёрстка, программирование, интеграции и тесты.",
  },
  {
    num: 4,
    icon3d: "/assets/gen/ic3d-rocket.png",
    title: "Запуск и поддержка",
    desc: "Публикация, аналитика и развитие проекта.",
  },
] as const;

/* ─── Component ─────────────────────────────────────────────── */

export function Websites() {
  return (
    <section
      id="websites"
      className="relative overflow-hidden bg-[var(--color-background)] py-16 md:py-20"
    >
      {/* Decorative glow */}
      <div
        aria-hidden
        className="pointer-events-none absolute right-0 top-0 size-[250px] sm:size-[500px] rounded-full opacity-[0.06] blur-[140px]"
        style={{ background: "var(--gradient-brand)" }}
      />

      <Container>
        <Reveal>
          <SectionTitle
            eyebrow="разработка сайтов"
            title="Разработка сайтов под ваш проект"
            titleGradient="под ваш проект"
            subtitle="Два формата на выбор — никакого навязывания."
          />
        </Reveal>

        {/* ── 2 Format Cards ───────────────────────────────────── */}
        <div className="mt-12 grid gap-6 lg:grid-cols-2">
          {FORMATS.map((fmt, i) => (
            <Reveal key={fmt.id} delay={i * 120}>
              <div className="card-soft relative flex flex-col overflow-hidden rounded-[28px] p-8 transition-all duration-200 hover:-translate-y-1 hover:shadow-[0_18px_55px_rgba(0,75,160,0.14)]">
                {/* Format badge */}
                <span className="inline-flex w-fit items-center rounded-full bg-[var(--color-brand)]/10 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.16em] text-[var(--color-brand)]">
                  {fmt.badge}
                </span>

                {/* Icon + heading */}
                <div className="mt-4 flex items-start gap-4">
                  {/* 3D icon tile */}
                  <span className="grid size-16 shrink-0 place-items-center rounded-2xl bg-[#EEF6FF]">
                    <img
                      src={fmt.icon3d}
                      alt=""
                      aria-hidden="true"
                      width={52}
                      height={52}
                      className="size-[52px] select-none object-contain"
                      loading="lazy"
                      decoding="async"
                    />
                  </span>
                  <div className="min-w-0">
                    <h3 className="text-xl font-bold leading-snug">
                      {fmt.title}
                    </h3>
                    <p className="mt-1.5 text-sm text-[var(--color-muted-foreground)]">
                      {fmt.description}
                    </p>
                  </div>
                </div>

                {/* Checklist */}
                <ul className="mt-5 space-y-2.5">
                  {fmt.checks.map((item) => (
                    <li key={item} className="flex items-start gap-2.5">
                      <span className="mt-0.5 flex size-5 shrink-0 items-center justify-center rounded-full bg-[var(--color-brand)]/10">
                        <Check
                          className="size-3 text-[var(--color-brand)]"
                          strokeWidth={2.5}
                        />
                      </span>
                      <span className="text-sm text-[var(--color-foreground)]">
                        {item}
                      </span>
                    </li>
                  ))}
                </ul>

                {/* Timing */}
                <div className="mt-5 flex items-center gap-2 text-sm text-[var(--color-muted-foreground)]">
                  <fmt.TimingIcon
                    className="size-5 shrink-0 text-[var(--color-muted-foreground)]"
                    strokeWidth={1.5}
                  />
                  <span>
                    <strong className="text-[var(--color-foreground)]">
                      {fmt.timingText}
                    </strong>
                  </span>
                </div>
              </div>
            </Reveal>
          ))}
        </div>

        {/* ── 4 Development Steps ─────────────────────────────── */}
        <Reveal delay={100}>
          <p className="mt-14 text-center text-sm font-semibold uppercase tracking-[0.16em] text-[var(--color-muted-foreground)]">
            Как проходит разработка
          </p>
        </Reveal>

        {/* Steps — contrasting surface-soft background */}
        <Reveal delay={140}>
          <div
            className="mt-5 rounded-[28px] px-6 py-8 sm:px-8"
            style={{ background: "#EEF6FF" }}
          >
            <div className="grid gap-4 sm:grid-cols-2 md:grid-cols-4">
              {STEPS.map((step, i) => (
                <div key={step.num} className="relative flex items-stretch">
                  {/* Step card */}
                  <div className="flex-1 rounded-2xl bg-white p-5 shadow-[0_4px_18px_rgba(0,75,160,0.07)]">
                    {/* Large step number */}
                    <span
                      className="block text-[28px] font-black leading-none tabular-nums"
                      style={{ color: "#006DFF" }}
                    >
                      {String(step.num).padStart(2, "0")}
                    </span>

                    {/* 3D step icon */}
                    <span className="mt-3 grid size-14 shrink-0 place-items-center rounded-2xl bg-[#EEF6FF]">
                      <img
                        src={step.icon3d}
                        alt=""
                        aria-hidden="true"
                        width={44}
                        height={44}
                        className="size-11 select-none object-contain"
                        loading="lazy"
                        decoding="async"
                      />
                    </span>

                    <h4 className="mt-2 text-sm font-semibold text-[#071A3F]">
                      {step.title}
                    </h4>
                    <p className="mt-1 text-xs leading-relaxed text-[#4B638A]">
                      {step.desc}
                    </p>
                  </div>

                  {/* Connector arrow — desktop only */}
                  {i < STEPS.length - 1 && (
                    <div
                      aria-hidden
                      className="absolute right-0 top-1/2 z-10 hidden -translate-y-1/2 translate-x-full items-center gap-0 md:flex"
                      style={{ width: "1rem" }}
                    >
                      <div className="h-[2px] w-2.5 bg-[#006DFF]/40" />
                      <div
                        className="size-0 border-y-[4px] border-l-[5px] border-y-transparent"
                        style={{ borderLeftColor: "#006DFF" }}
                      />
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </Reveal>

        {/* CTA */}
        <Reveal delay={180}>
          <div className="mt-10 flex justify-center">
            <a
              href="#contact"
              onClick={() => goal('websites_cta')}
              className="inline-flex items-center gap-2 rounded-full px-8 py-4 text-sm font-semibold text-white transition-all duration-200 hover:opacity-90 hover:-translate-y-0.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#006DFF] focus-visible:ring-offset-2"
              style={{ background: 'linear-gradient(135deg,#006DFF 0%,#1677FF 52%,#8B5CF6 100%)' }}
            >
              Обсудить проект сайта
            </a>
          </div>
        </Reveal>
      </Container>
    </section>
  );
}
