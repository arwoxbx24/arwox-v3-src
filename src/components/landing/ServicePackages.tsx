/**
 * Секция — ServicePackages (Пакеты внедрения ARWOX)
 * Ownership: ServicePackages.tsx
 */

import { Check, Clock } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Container,
  SectionTitle,
  Reveal,
} from "@/components/landing/atoms";
import { goal } from "@/lib/ym";

/* ─── данные пакетов ──────────────────────────────────────────*/
interface ServicePackage {
  name: string;
  price: string;
  description: string;
  features: string[];
  timeline: string;
  popular?: boolean;
}

const PACKAGES: ServicePackage[] = [
  {
    name: "Старт",
    price: "от 30 000 ₽",
    description: "Базовая настройка CRM и воронки продаж",
    features: [
      "Настройка CRM-воронки",
      "Подключение телефонии",
      "Импорт базы клиентов",
      "Обучение команды (2 ч)",
      "Поддержка 14 дней",
    ],
    timeline: "от 2 недель",
  },
  {
    name: "Бизнес",
    price: "от 80 000 ₽",
    description: "Комплексное внедрение для растущего бизнеса",
    features: [
      "Всё из «Старт»",
      "Автоматизация бизнес-процессов",
      "Интеграции (1С, сайт, мессенджеры)",
      "Настройка аналитики и отчётов",
      "Обучение команды (8 ч)",
      "Поддержка 30 дней",
    ],
    timeline: "от 4 недель",
    popular: true,
  },
  {
    name: "Проект",
    price: "по запросу",
    description: "Индивидуальный проект под сложные задачи",
    features: [
      "Всё из «Бизнес»",
      "Проектирование бизнес-процессов",
      "Кастомная разработка",
      "Миграция с других CRM",
      "Обучение + регламенты",
      "Поддержка 60 дней",
    ],
    timeline: "индивидуально",
  },
];

/* ─── компонент карточки пакета ───────────────────────────────*/
function PackageCard({ pkg, delay }: { pkg: ServicePackage; delay: number }) {
  return (
    <Reveal delay={delay}>
      <article
        className={[
          "relative flex flex-col rounded-[20px] bg-white p-6",
          "hover:-translate-y-1 transition-all duration-200",
          "shadow-[0_18px_55px_rgba(0,75,160,0.10)]",
          "hover:shadow-[0_24px_65px_rgba(0,75,160,0.16)]",
          pkg.popular ? "ring-2 ring-[#006DFF]/30" : "",
        ]
          .filter(Boolean)
          .join(" ")}
      >
        {/* Название + бейдж «Популярный» */}
        <div className="flex items-center gap-2 flex-wrap">
          <span className="text-lg font-semibold leading-snug text-[#071A3F]">
            {pkg.name}
          </span>
          {pkg.popular && (
            <span
              aria-label="Популярный пакет"
              className="inline-flex items-center rounded-full px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wider text-white"
              style={{ background: "linear-gradient(90deg,#006DFF,#00B7FF)" }}
            >
              Популярный
            </span>
          )}
        </div>

        {/* Описание */}
        <div className="mt-1 text-xs text-[#4B638A]">{pkg.description}</div>

        {/* Цена */}
        <div className="mt-4">
          <span className="text-[32px] font-extrabold leading-none text-[#071A3F]">
            {pkg.price}
          </span>
        </div>

        {/* Список фич */}
        <ul className="mt-5 flex flex-col gap-2.5 flex-1">
          {pkg.features.map((feature) => (
            <li key={feature} className="flex items-start gap-2 text-sm text-[#071A3F]">
              <Check className="size-4 shrink-0 text-[#006DFF] mt-0.5" />
              {feature}
            </li>
          ))}
        </ul>

        {/* Сроки */}
        <div className="mt-4 flex items-center gap-1.5 text-xs text-[#4B638A]">
          <Clock className="size-3.5 shrink-0 text-[#006DFF]" />
          <span>{pkg.timeline}</span>
        </div>

        {/* CTA */}
        <div className="mt-5">
          <Button
            asChild
            size="sm"
            className={
              pkg.popular
                ? "w-full rounded-xl bg-gradient-brand text-white hover:opacity-90 focus-visible:ring-2 focus-visible:ring-[#006DFF]"
                : "w-full rounded-xl border border-[#D9E8FF] bg-white text-[#071A3F] hover:bg-[#EEF6FF] focus-visible:ring-2 focus-visible:ring-[#006DFF]"
            }
            variant={pkg.popular ? "default" : "outline"}
          >
            <a href="#contact" onClick={() => goal('package_click')}>Обсудить</a>
          </Button>
        </div>
      </article>
    </Reveal>
  );
}

/* ─── главный экспорт ─────────────────────────────────────────*/
export function ServicePackages() {
  return (
    <section id="packages" className="bg-white py-16 md:py-20">
      <Container>
        <SectionTitle
          eyebrow="Пакеты внедрения"
          title="Выберите формат работы"
          titleGradient="формат работы"
          subtitle="Фиксированный объём работ, понятные сроки и результат. Детали обсуждаем на консультации."
        />

        {/* Сетка карточек */}
        <div className="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {PACKAGES.map((pkg, i) => (
            <PackageCard key={pkg.name} pkg={pkg} delay={i * 80} />
          ))}
        </div>
      </Container>
    </section>
  );
}
