"use client";

import { Container, Reveal } from "@/components/landing/atoms";

/* ─── Data (текст — дословно из designland, блок 10) ─────────── */

interface IntegCard {
  /** Имя SVG-иконки в /assets/icons/ или null для текстового тайла «1С» */
  icon: string | null;
  label: string;
  subtitle: string;
}

const CARDS: IntegCard[] = [
  { icon: null,        label: "1С",              subtitle: "Все данные в CRM" },
  { icon: "/assets/gen/ic3d-phone.png", label: "Телефония",       subtitle: "Звонки и записи" },
  { icon: "/assets/gen/ic3d-email.png",     label: "E-mail",          subtitle: "Письма и рассылки" },
  { icon: "/assets/gen/ic3d-whatsapp.png",  label: "WhatsApp",        subtitle: "Чаты и боты" },
  { icon: "/assets/gen/ic3d-telegram.png",  label: "Telegram",        subtitle: "Уведомления и боты" },
  { icon: "/assets/gen/ic3d-api.png",       label: "API · Webhook",   subtitle: "Гибкая интеграция" },
  { icon: "/assets/gen/ic3d-sites.png",   label: "Сайты и формы",   subtitle: "Лиды и заявки" },
  { icon: "/assets/gen/ic3d-analytics.png",  label: "Аналитика",       subtitle: "Дашборды и отчёты" },
  { icon: "/assets/gen/ic3d-shop.png",    label: "Интернет-магазины", subtitle: "Заказы и клиенты" },
  { icon: "/assets/gen/ic3d-services.png",  label: "Внешние сервисы", subtitle: "По API и вебхукам" },
];

/* ─── Section ───────────────────────────────────────────────── */

export function Integrations() {
  return (
    <section
      id="integrations"
      className="dark-scope relative py-16 md:py-24"
      style={{
        background:
          "linear-gradient(135deg, #061A3D 0%, #082A5A 55%, #0A3470 100%)",
      }}
    >
      {/* ── Network texture overlay ── */}
      <div aria-hidden className="pointer-events-none absolute inset-0 overflow-hidden">
        <img
          src="/assets/gen/integration-net.png"
          alt=""
          className="h-full w-full object-cover opacity-20 mix-blend-luminosity"
          loading="lazy"
          decoding="async"
        />
      </div>

      {/* ── Ambient glows ── */}
      <div aria-hidden className="pointer-events-none absolute inset-0 overflow-hidden">
        <div
          className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 size-[520px] sm:size-[820px] rounded-full blur-[180px]"
          style={{ background: "rgba(0,109,255,0.22)" }}
        />
        <div
          className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 size-[260px] sm:size-[420px] rounded-full blur-[100px]"
          style={{ background: "rgba(0,183,255,0.14)" }}
        />
        <div
          className="absolute right-10 bottom-8 size-[280px] rounded-full blur-[110px]"
          style={{ background: "rgba(139,92,246,0.12)" }}
        />
      </div>

      <Container className="relative z-10">
        {/* ── Header ── */}
        <Reveal>
          <div className="mb-10 flex flex-col items-center text-center md:mb-14">
            <h2 className="text-3xl font-extrabold leading-tight text-white sm:text-4xl md:text-5xl">
              Интеграции с <span className="text-gradient">ключевыми системами</span>
            </h2>
            <p className="mt-4 max-w-xl text-base leading-relaxed text-[color:var(--color-muted-foreground)]">
              Подключаем системы через API, вебхуки и штатные модули.
              Техническую возможность и стоимость определяем на диагностике.
            </p>
          </div>
        </Reveal>

        {/* ── Cards: реальный текст, белые карточки, сетка 5×2 ── */}
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4 lg:grid-cols-5">
          {CARDS.map((card, i) => (
            <Reveal key={card.label} delay={i * 50}>
              <article className="flex h-full items-center gap-3 rounded-[20px] bg-white p-4 shadow-[0_18px_55px_rgba(0,75,160,0.10)]">
                {card.icon === null ? (
                  <span
                    className="grid size-14 shrink-0 place-items-center rounded-2xl text-lg font-extrabold text-white"
                    style={{ background: "linear-gradient(135deg,#006DFF 0%,#00B7FF 55%,#8B5CF6 100%)" }}
                  >
                    1С
                  </span>
                ) : (
                  <span className="grid size-14 shrink-0 place-items-center rounded-2xl bg-[#EEF6FF]">
                    <img src={card.icon} alt="" aria-hidden="true" width={44} height={44} className="size-11 select-none object-contain" loading="lazy" decoding="async" />
                  </span>
                )}
                <div className="min-w-0">
                  <div className="text-sm font-bold leading-tight text-[#071A3F]">{card.label}</div>
                  <div className="mt-0.5 text-xs leading-tight text-[#4B638A]">{card.subtitle}</div>
                </div>
              </article>
            </Reveal>
          ))}
        </div>
      </Container>
    </section>
  );
}
