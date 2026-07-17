"use client";

import { PlayCircle, Rocket, BarChart3, Users } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Reveal } from "@/components/landing/atoms";
import { DashboardMock } from "@/components/landing/DashboardMock";
import { goal } from "@/lib/ym";

/* ─── CompetenceRibbon ───────────────────────────────────── */

const COMPETENCE_ASSETS = [
  { icon: "/assets/gen/ic3d-bitrix.png",   eyebrow: "Бизнес-партнёр", title: "Битрикс24" },
  { icon: "/assets/gen/ic3d-platform.png", eyebrow: "Платформа",      title: "Облако + Коробка" },
  { icon: "/assets/gen/ic3d-crm.png",      eyebrow: "CRM",            title: "Внедрение и настройка" },
  { icon: "/assets/gen/ic3d-robot.png",    eyebrow: "Автоматизация",  title: "Роботы и BitrixGPT" },
] as const;

export function CompetenceRibbon() {
  return (
    <Reveal className="mx-auto mt-8 max-w-7xl px-4 sm:px-6 lg:px-8">
      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        {COMPETENCE_ASSETS.map((card) => (
          <article
            key={card.title}
            className="flex items-center gap-3 rounded-2xl border border-[#D9E8FF] bg-white/90 p-4 shadow-[0_18px_55px_rgba(0,75,160,0.08)] backdrop-blur-sm"
          >
            <span className="grid size-14 shrink-0 place-items-center rounded-2xl bg-[#EEF6FF]">
              <img
                src={card.icon}
                alt=""
                aria-hidden="true"
                width={44}
                height={44}
                className="size-11 select-none object-contain"
                loading="lazy"
                decoding="async"
              />
            </span>
            <div className="min-w-0">
              <div className="text-[10px] font-semibold uppercase tracking-[0.16em] text-[#4B638A]">
                {card.eyebrow}
              </div>
              <div className="truncate text-sm font-bold text-[#071A3F]">{card.title}</div>
            </div>
          </article>
        ))}
      </div>
    </Reveal>
  );
}

/* ─── Hero ───────────────────────────────────────────────── */

export function Hero() {
  return (
    <section
      id="hero"
      className="relative overflow-hidden bg-hero pt-[100px] pb-16"
      aria-label="Главная секция"
    >
      {/* Лёгкие фоновые орбы — не перекрывают светлый фон */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute -top-24 right-0 size-[500px] rounded-full blur-[140px] opacity-40"
        style={{ background: "rgba(0,109,255,0.10)" }}
      />
      <div
        aria-hidden="true"
        className="pointer-events-none absolute -bottom-20 -left-10 size-[350px] rounded-full blur-[120px] opacity-35"
        style={{ background: "rgba(0,183,255,0.12)" }}
      />

      {/* ── Стеклянная 3D-лента через всю секцию (эталон дизайнера) ── */}
      <img
        src="/assets/gen/el-ribbon.png"
        alt=""
        aria-hidden="true"
        className="pointer-events-none absolute -left-[6%] bottom-[130px] hidden w-[62%] select-none opacity-90 lg:block"
        loading="eager"
        decoding="async"
      />

      {/* Стеклянные сферы (CSS) */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute bottom-[190px] left-[2%] hidden size-24 rounded-full lg:block"
        style={{
          background:
            "radial-gradient(circle at 32% 28%, rgba(255,255,255,0.95) 0%, rgba(214,231,255,0.85) 40%, rgba(160,196,255,0.55) 100%)",
          boxShadow: "0 24px 50px rgba(0,75,160,0.18), inset 0 -8px 18px rgba(0,109,255,0.12)",
        }}
      />
      <div
        aria-hidden="true"
        className="pointer-events-none absolute bottom-[320px] left-[9%] hidden size-10 rounded-full lg:block"
        style={{
          background:
            "radial-gradient(circle at 32% 28%, rgba(255,255,255,0.95) 0%, rgba(214,231,255,0.8) 45%, rgba(160,196,255,0.5) 100%)",
          boxShadow: "0 14px 30px rgba(0,75,160,0.15)",
        }}
      />

      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 items-center gap-10 lg:grid-cols-[1fr_1.1fr] lg:gap-12">

          {/* ── Left column ── */}
          <Reveal className="flex flex-col">
            {/* Партнёрский бейдж — стеклянный, с 3D-щитом и градиентной рамкой */}
            <div
              className="inline-flex w-fit items-center gap-3 rounded-2xl p-[1.5px]"
              style={{ background: "linear-gradient(135deg,#00C4FF 0%,#1677FF 55%,#8B5CF6 100%)" }}
            >
              <div className="inline-flex items-center gap-3 rounded-[14.5px] bg-white/85 py-2 pl-2.5 pr-5 shadow-[0_12px_35px_rgba(0,75,160,0.14)] backdrop-blur-md">
                <img
                  src="/assets/gen/badge-shield.png"
                  alt=""
                  aria-hidden="true"
                  width={40}
                  height={40}
                  className="size-10 shrink-0 select-none object-contain drop-shadow-[0_6px_12px_rgba(0,109,255,0.35)]"
                  decoding="async"
                />
                <div className="leading-tight">
                  <div className="text-[10px] font-semibold uppercase tracking-[0.18em] text-[#4B638A]">
                    Официальный статус
                  </div>
                  <div className="text-[15px] font-extrabold text-[#081D3A]">
                    Бизнес-партнёр{" "}
                    <span className="text-gradient">Битрикс24</span>
                  </div>
                </div>
              </div>
            </div>

            {/* H1 — регламент ARWOX */}
            <h1 className="mt-5 text-3xl sm:text-5xl xl:text-6xl font-extrabold leading-[1.07] tracking-tight text-[var(--color-foreground)]">
              Внедрим Битрикс24
              <br />
              <span className="text-gradient">по регламенту ARWOX</span>
              <br />
              <span className="text-[0.82em] font-bold text-[#071A3F]">— понятные этапы и приёмка по ТЗ</span>
            </h1>

            <p className="mt-6 max-w-[520px] text-[15px] leading-[1.65] text-muted-foreground sm:text-[17px]">
              Диагностика → ТЗ → запуск → обучение → акты. Точную стоимость и сроки фиксируем в ТЗ до начала настройки — без сюрпризов в процессе.
            </p>

            {/* CTA buttons */}
            <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:flex-wrap">
              {/* Primary CTA */}
              <Button
                asChild
                size="lg"
                className="h-14 rounded-2xl px-7 text-white shadow-[0_18px_45px_rgba(240,81,42,0.40)] hover:-translate-y-0.5 hover:shadow-[0_22px_55px_rgba(240,81,42,0.52)] transition-transform focus-visible:ring-2 focus-visible:ring-[var(--color-brand)] focus-visible:ring-offset-2"
                style={{ background: 'linear-gradient(135deg,#FF7A29 0%,#F0512A 100%)' }}
              >
                <a href="#contact" onClick={() => goal('cta_click')}>
                  <Rocket className="mr-2 size-5" aria-hidden="true" />
                  Получить разбор за 30 минут
                </a>
              </Button>

              {/* Demo CTA */}
              <Button
                asChild
                size="lg"
                variant="outline"
                className="h-14 rounded-2xl border-[var(--color-brand)] bg-white px-7 text-[var(--color-brand)] hover:bg-[#EEF6FF] focus-visible:ring-2 focus-visible:ring-[var(--color-brand)] focus-visible:ring-offset-2"
              >
                <a href="#demo" onClick={() => goal('demo_view')}>
                  <PlayCircle className="mr-2 size-5" aria-hidden="true" />
                  Смотреть демо Битрикс24
                </a>
              </Button>

              {/* Low-threshold CTA — messenger */}
              <Button
                asChild
                size="lg"
                variant="outline"
                className="h-14 rounded-2xl border-[var(--color-border)] bg-white px-7 text-foreground hover:bg-[var(--color-surface-soft)] focus-visible:ring-2 focus-visible:ring-[var(--color-brand)] focus-visible:ring-offset-2"
              >
                <a
                  href="https://wa.me/79287051199"
                  target="_blank"
                  rel="noopener noreferrer"
                  onClick={() => goal('wa_click')}
                >
                  Я только спросить →
                </a>
              </Button>
            </div>

            {/* Подпись под кнопками (P1-2) */}
            <p className="mt-3 max-w-[520px] text-[12.5px] leading-snug text-[#93A6C4]">
              За 30 минут: разберём ваши процессы, назовём ориентировочную вилку бюджета и покажем план первых шагов. Точную стоимость фиксируем в ТЗ после платной диагностики — до старта настройки.
            </p>

            {/* Contacts */}
            <div className="mt-8 flex flex-wrap gap-5 text-sm text-muted-foreground">
              <a
                href="tel:+79287051199"
                className="inline-flex items-center gap-2 transition-colors hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-brand)] focus-visible:ring-offset-2 rounded-sm"
              >
                <img src="/assets/gen/ic3d-phone.png" alt="" aria-hidden="true" width={32} height={32} className="size-8 select-none object-contain" decoding="async" />
                +7 928-705-11-99
              </a>
              <a
                href="mailto:info@arwox.ru"
                className="inline-flex items-center gap-2 transition-colors hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-brand)] focus-visible:ring-offset-2 rounded-sm"
              >
                <img src="/assets/gen/ic3d-email.png" alt="" aria-hidden="true" width={32} height={32} className="size-8 select-none object-contain" decoding="async" />
                info@arwox.ru
              </a>
            </div>

            {/* Stats strip */}
            <div className="mt-6 grid grid-cols-3 gap-6 sm:flex sm:flex-row sm:gap-6">
              {[
                { value: "с 2021 года", label: "на рынке" },
                { value: "200+",        label: "пользователей на порталах" },
                { value: "10+",         label: "внедрений Битрикс24" },
              ].map((stat) => (
                <div key={stat.label} className="flex flex-col items-center text-center">
                  <span className="text-xl font-extrabold text-[#006DFF]">{stat.value}</span>
                  <span className="text-[11px] text-[#4B638A]">{stat.label}</span>
                </div>
              ))}
            </div>
          </Reveal>

          {/* ── Right column: светлый стеклянный дашборд с 3D-глубиной ── */}
          <Reveal delay={150} className="w-full">
            {/* Scene wrapper */}
            <div className="relative mx-auto max-w-[420px] lg:max-w-none lg:py-6">

              {/* Мягкое свечение позади дашборда */}
              <div
                aria-hidden="true"
                className="pointer-events-none absolute inset-x-8 top-1/4 h-3/4 rounded-full blur-[80px] opacity-25"
                style={{ background: "radial-gradient(ellipse, rgba(0,109,255,0.30) 0%, rgba(0,183,255,0.15) 60%, transparent 100%)" }}
              />

              {/* Стеклянный пьедестал под сценой */}
              <div
                aria-hidden="true"
                className="pointer-events-none absolute -bottom-4 left-1/2 hidden h-16 w-[110%] -translate-x-1/2 rounded-[50%] lg:block"
                style={{
                  background:
                    "linear-gradient(180deg, rgba(214,231,255,0.9) 0%, rgba(235,244,255,0.5) 100%)",
                  boxShadow: "0 30px 60px rgba(0,75,160,0.18), inset 0 2px 6px rgba(255,255,255,0.9)",
                }}
              />

              {/* Dashboard — наклон через perspective реализован внутри DashboardMock */}
              <div className="relative">
                <DashboardMock />
              </div>

              {/* Плавающие стеклянные тайлы приложений — правый край (эталон) */}
              <div
                aria-hidden="true"
                className="pointer-events-none absolute -right-20 top-[16%] z-30 hidden lg:grid size-16 place-items-center rounded-2xl"
                style={{
                  background: "linear-gradient(135deg,#8B5CF6 0%,#6D7CFF 100%)",
                  boxShadow: "0 18px 40px rgba(109,92,246,0.4), inset 0 1px 2px rgba(255,255,255,0.5)",
                }}
              >
                <BarChart3 className="size-8 text-white" />
              </div>
              <div
                aria-hidden="true"
                className="pointer-events-none absolute -right-20 top-[42%] z-30 hidden lg:grid size-16 place-items-center rounded-2xl"
                style={{
                  background: "linear-gradient(135deg,#00B7FF 0%,#006DFF 100%)",
                  boxShadow: "0 18px 40px rgba(0,109,255,0.4), inset 0 1px 2px rgba(255,255,255,0.5)",
                }}
              >
                <Users className="size-8 text-white" />
              </div>
            </div>
          </Reveal>
        </div>
      </div>

      {/* ── Лента компетенций ── */}
      <CompetenceRibbon />
    </section>
  );
}
