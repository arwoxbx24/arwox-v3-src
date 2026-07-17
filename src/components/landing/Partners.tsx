import { Container, Reveal } from "@/components/landing/atoms";

/* ─── Data ───────────────────────────────────────────────────── */

interface PartnerCard {
  id: string;
  /** Официальный логотип (SVG с сайта сервиса) */
  logo: string;
  /** alt для доступности */
  name: string;
  /** Короткое описание роли */
  role: string;
  /** Высота лого в карточке, px (wordmark'и разной пропорции) */
  logoHeight: number;
  /** Показывать имя рядом с лого (для знаков-иконок вроде «24») */
  showName?: boolean;
}

const PARTNERS: PartnerCard[] = [
  {
    id: "bitrix24",
    logo: "/assets/partners/bitrix24.svg",
    name: "Битрикс24",
    role: "CRM-платформа — внедряем, настраиваем, сопровождаем",
    logoHeight: 40,
    showName: true,
  },
  {
    id: "beget",
    logo: "/assets/partners/beget.svg",
    name: "Beget",
    role: "Хостинг для сайтов и коробочных установок",
    logoHeight: 32,
  },
  {
    id: "timeweb",
    logo: "/assets/partners/timeweb.svg",
    name: "Timeweb",
    role: "Хостинг и облачные серверы для проектов",
    logoHeight: 26,
  },
  {
    id: "chatapp",
    logo: "/assets/partners/chatapp.svg",
    name: "ChatApp",
    role: "Интеграция WhatsApp и мессенджеров с CRM",
    logoHeight: 32,
  },
  {
    id: "megafon",
    logo: "/assets/partners/megafon.png",
    name: "МегаФон",
    role: "Телефония и связь для отдела продаж",
    logoHeight: 30,
  },
  {
    id: "avecme",
    logo: "/assets/partners/avecme.png",
    name: "AVECME",
    role: "Сервисы для бизнеса и интеграций",
    logoHeight: 28,
  },
];

/* ─── Section ───────────────────────────────────────────────── */

export function Partners() {
  return (
    <section id="partners" className="bg-[#F7FAFF] py-14 md:py-20">
      <Container>
        {/* ── Header ── */}
        <Reveal>
          <div className="mb-10 flex flex-col items-center text-center md:mb-12">
            <h2 className="text-3xl font-extrabold leading-tight text-[#081D3A] sm:text-4xl">
              Работаем с проверенными{" "}
              <span className="text-[#1677FF]">сервисами</span>
            </h2>
            <p className="mt-3 max-w-lg text-base leading-relaxed text-[#4B638A]">
              Инфраструктура и интеграции, которые мы используем в проектах
            </p>
          </div>
        </Reveal>

        {/* ── Cards: официальные логотипы сервисов ── */}
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 sm:gap-5 lg:grid-cols-6">
          {PARTNERS.map((p, i) => (
            <Reveal key={p.id} delay={i * 60}>
              <article className="flex h-full flex-col items-center justify-center gap-3 rounded-[20px] bg-white px-4 py-7 shadow-[0_18px_55px_rgba(0,75,160,0.10)]">
                <div className="grid h-[48px] place-items-center">
                  <span className="inline-flex items-center gap-2">
                    <img
                      src={p.logo}
                      alt={p.name}
                      style={{ height: p.logoHeight }}
                      className="w-auto max-w-[140px] select-none object-contain"
                      loading="lazy"
                      decoding="async"
                    />
                    {p.showName && (
                      <span className="text-lg font-extrabold tracking-tight text-[#081D3A]">
                        Битрикс24
                      </span>
                    )}
                  </span>
                </div>
                <div className="text-center text-xs leading-snug text-[#4B638A]">{p.role}</div>
              </article>
            </Reveal>
          ))}
        </div>
      </Container>
    </section>
  );
}
