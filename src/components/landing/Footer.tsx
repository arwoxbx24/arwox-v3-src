"use client";

import { MapPin, Phone, Mail } from "lucide-react";
import { Logo, Container } from "@/components/landing/atoms";

/* ─── Data ─────────────────────────────────────────────────── */

const NAV_SERVICES = [
  { label: "Внедрение Битрикс24", href: "#process" },
  { label: "Настройка CRM", href: "#process" },
  { label: "Интеграции", href: "#integrations" },
  { label: "Разработка сайтов", href: "#websites" },
  { label: "Техническая поддержка", href: "#contact" },
  { label: "Обучение и консалтинг", href: "#contact" },
] as const;

const NAV_COMPANY = [
  { label: "О компании", href: "#why-us" },
  { label: "Кейсы", href: "#case" },
  { label: "Тарифы", href: "#tariffs" },
  { label: "Вопросы", href: "#faq" },
  { label: "Контакты", href: "#contact" },
] as const;

/* ─── Social icons ──────────────────────────────────────────── */

function TelegramIcon({ className = "" }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" className={className}>
      <path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z" />
    </svg>
  );
}

function VKIcon({ className = "" }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" className={className}>
      <path d="M12.785 16.241s.288-.032.436-.194c.136-.148.132-.427.132-.427s-.019-1.304.587-1.496c.597-.189 1.364 1.26 2.177 1.817.614.42 1.08.328 1.08.328l2.17-.03s1.135-.07.597-.963c-.044-.073-.312-.659-1.61-1.863-1.359-1.259-1.176-1.056.46-3.237.999-1.33 1.397-2.142 1.272-2.49-.12-.332-.852-.244-.852-.244l-2.442.015s-.181-.025-.315.055c-.132.078-.216.26-.216.26s-.387 1.028-.903 1.903c-1.088 1.85-1.523 1.948-1.7 1.833-.414-.267-.31-1.073-.31-1.646 0-1.79.271-2.535-.528-2.726-.266-.064-.461-.107-1.141-.114-.872-.009-1.608.003-2.025.207-.278.136-.492.44-.362.457.162.022.527.099.722.363.251.341.242 1.107.242 1.107s.144 2.109-.336 2.372c-.329.18-.781-.187-1.751-1.865-.497-.858-.872-1.808-.872-1.808s-.072-.176-.202-.271c-.156-.114-.375-.15-.375-.15l-2.322.015s-.348.01-.476.161c-.114.135-.009.414-.009.414s1.816 4.25 3.872 6.394c1.886 1.966 4.03 1.837 4.03 1.837h.97z" />
    </svg>
  );
}

/* ─── Component ─────────────────────────────────────────────── */

export function Footer() {
  return (
    <footer className="dark-scope border-t border-white/5 pb-8 pt-12" style={{ backgroundColor: '#111f3a' }}>
      <Container>
        {/* ── Main grid ────────────────────────────────────────── */}
        <div className="grid gap-10 md:grid-cols-2 lg:grid-cols-4">

          {/* Col 1: Brand */}
          <div className="flex flex-col gap-5">
            <Logo variant="dark" />

            <p className="max-w-[260px] text-sm leading-relaxed text-white/60">
              Внедряем Битрикс24, настраиваем CRM, интеграции и разрабатываем
              сайты, которые помогают бизнесу расти и зарабатывать больше.
            </p>

            {/* Битрикс24 Официальный бизнес-партнёр badge */}
            <div
              className="inline-flex w-fit items-center gap-3 rounded-2xl px-4 py-3"
              style={{
                background: "linear-gradient(135deg, rgba(8,29,58,0.95) 0%, rgba(16,40,80,0.90) 100%)",
                border: "1px solid transparent",
                backgroundClip: "padding-box",
                boxShadow: "0 0 0 1px rgba(126,211,33,0.25), inset 0 1px 0 rgba(255,255,255,0.06), 0 8px 24px rgba(0,0,0,0.35)",
                backdropFilter: "blur(12px)",
              }}
            >
              <img
                src="/assets/gen/ic3d-check-green.png"
                alt=""
                aria-hidden="true"
                width={38}
                height={38}
                className="shrink-0 select-none object-contain"
                loading="lazy"
                decoding="async"
              />
              <div className="flex flex-col leading-tight">
                <span className="text-sm font-bold tracking-wide text-white">Битрикс24</span>
                <span className="text-[11px] text-white/60">
                  Официальный{" "}
                  <span style={{ color: "#7ED321" }} className="font-semibold">
                    бизнес-партнёр
                  </span>
                </span>
              </div>
            </div>
          </div>

          {/* Col 2: Services */}
          <nav aria-label="Услуги">
            <h4 className="mb-4 text-sm font-semibold text-white">Услуги</h4>
            <ul className="space-y-2">
              {NAV_SERVICES.map((item) => (
                <li key={item.label}>
                  <a
                    href={item.href}
                    className="text-sm text-white/55 transition-colors duration-150 hover:text-white focus-visible:outline-none focus-visible:underline"
                  >
                    {item.label}
                  </a>
                </li>
              ))}
            </ul>
          </nav>

          {/* Col 3: Company */}
          <nav aria-label="Компания">
            <h4 className="mb-4 text-sm font-semibold text-white">Компания</h4>
            <ul className="space-y-2">
              {NAV_COMPANY.map((item) => (
                <li key={item.label}>
                  <a
                    href={item.href}
                    className="text-sm text-white/60 transition-colors duration-150 hover:text-white focus-visible:outline-none focus-visible:underline"
                  >
                    {item.label}
                  </a>
                </li>
              ))}
            </ul>
          </nav>

          {/* Col 4: Contacts */}
          <div>
            <h4 className="mb-4 text-sm font-semibold text-white">Контакты</h4>
            <ul className="space-y-3">
              <li>
                <a
                  href="tel:+79287051199"
                  className="flex items-center gap-2.5 text-sm text-white/60 transition-colors duration-150 hover:text-white focus-visible:outline-none focus-visible:underline"
                >
                  <Phone className="size-5 shrink-0" aria-hidden />
                  +7 928-705-11-99
                </a>
              </li>
              <li>
                <a
                  href="mailto:info@arwox.ru"
                  className="flex items-center gap-2.5 text-sm text-white/60 transition-colors duration-150 hover:text-white focus-visible:outline-none focus-visible:underline"
                >
                  <Mail className="size-5 shrink-0" aria-hidden />
                  info@arwox.ru
                </a>
              </li>
              <li className="flex items-start gap-2.5 text-sm text-white/60">
                <MapPin className="mt-0.5 size-5 shrink-0" aria-hidden />
                г.&nbsp;Краснодар, ул.&nbsp;Рашпилевская,&nbsp;180
              </li>
            </ul>

            {/* Social icons */}
            <div className="mt-5 flex items-center gap-2">
              {[
                { href: "https://t.me/arwox", label: "Telegram", SocIcon: TelegramIcon },
                { href: "https://vk.com/arwox", label: "ВКонтакте", SocIcon: VKIcon },
              ].map(({ href, label, SocIcon }) => (
                <a
                  key={label}
                  href={href}
                  target="_blank"
                  rel="noopener noreferrer"
                  aria-label={label}
                  className="grid size-8 place-items-center rounded-full bg-white/[0.08] text-white/60 transition-colors duration-200 hover:bg-white/[0.16] hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/40"
                >
                  <SocIcon className="size-5" />
                </a>
              ))}
            </div>
          </div>
        </div>

        {/* ── Bottom bar ───────────────────────────────────────── */}
        <div className="mt-10 border-t border-white/[0.07] pt-6">
          <div className="flex flex-col gap-3 text-xs text-white/40 sm:flex-row sm:items-center sm:justify-between">
            <span>© 2021–2026 ARWOX. Все права защищены.</span>
            <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:gap-4">
<a
                href="/privacy.html"
                target="_blank"
                rel="noopener noreferrer"
                className="transition-colors duration-150 hover:text-white/70 focus-visible:outline-none focus-visible:underline"
              >
                Политика обработки персональных данных
              </a>
            </div>
            <span className="flex items-center gap-1 sm:justify-end">
              Сделано с{" "}
              <span className="text-rose-400" aria-label="любовью">♥</span>
              {" "}в ARWOX
            </span>
          </div>
        </div>
      </Container>
    </footer>
  );
}
