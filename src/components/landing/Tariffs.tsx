/**
 * Секция 10 — Tariffs (Тарифы и лицензии Битрикс24)
 * Ownership: Tariffs.tsx
 */

import { Users, HardDrive } from "lucide-react";
import { Button } from "@/components/ui/button";
import { goal } from "@/lib/ym";
import {
  Container,
  SectionTitle,
  Reveal,
} from "@/components/landing/atoms";

/* ─── данные тарифов ──────────────────────────────────────────*/
interface TariffFeature {
  icon: "users" | "storage";
  text: string;
}

interface TariffPlan {
  name: string;
  desc: string;
  priceCurrent: string;
  priceOld: string;
  features: TariffFeature[];
  popular?: boolean;
}

const PLANS: TariffPlan[] = [
  {
    name: "Базовый",
    desc: "Для небольших команд и старта в CRM",
    priceCurrent: "1 220 ₽",
    priceOld: "1 743 ₽",
    features: [
      { icon: "users", text: "5 пользователей" },
      { icon: "storage", text: "24 ГБ места" },
    ],
  },
  {
    name: "Стандартный",
    desc: "Для растущего бизнеса и управления продажами",
    priceCurrent: "3 425 ₽",
    priceOld: "4 893 ₽",
    features: [
      { icon: "users", text: "50 пользователей" },
      { icon: "storage", text: "100 ГБ места" },
    ],
    popular: true,
  },
  {
    name: "Профессиональный",
    desc: "Для автоматизации бизнес-процессов",
    priceCurrent: "6 855 ₽",
    priceOld: "9 793 ₽",
    features: [
      { icon: "users", text: "100 пользователей" },
      { icon: "storage", text: "1 024 ГБ места" },
    ],
  },
  {
    name: "Энтерпрайз",
    desc: "Для крупных компаний и корпораций",
    priceCurrent: "16 655 ₽",
    priceOld: "23 793 ₽",
    features: [
      { icon: "users", text: "от 250 пользователей" },
      { icon: "storage", text: "от 3 ТБ места" },
    ],
  },
];

/* ─── компонент карточки тарифа ───────────────────────────────*/
function TariffCard({ plan, delay }: { plan: TariffPlan; delay: number }) {
  return (
    <Reveal delay={delay}>
      <article
        className={[
          "relative flex flex-col rounded-[20px] bg-white p-6",
          "hover:-translate-y-1 transition-all duration-200",
          "shadow-[0_18px_55px_rgba(0,75,160,0.10)]",
          "hover:shadow-[0_24px_65px_rgba(0,75,160,0.16)]",
          plan.popular ? "ring-2 ring-[#006DFF]/30" : "",
        ]
          .filter(Boolean)
          .join(" ")}
      >
        {/* Название + inline-бейдж «Популярный» */}
        <div className="flex items-center gap-2 flex-wrap">
          <span className="text-lg font-semibold leading-snug text-[#071A3F]">
            {plan.name}
          </span>
          {plan.popular && (
            <span
              aria-label="Популярный тариф"
              className="inline-flex items-center rounded-full px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wider text-white"
              style={{ background: "linear-gradient(90deg,#006DFF,#00B7FF)" }}
            >
              Популярный
            </span>
          )}
        </div>

        {/* Описание */}
        <div className="mt-1 text-xs text-[#4B638A]">{plan.desc}</div>

        {/* Иконочные строки характеристик */}
        <ul className="mt-4 flex flex-col gap-2">
          {plan.features.map((f) => (
            <li key={f.text} className="flex items-center gap-2 text-sm text-[#071A3F]">
              {f.icon === "users" ? (
                <Users className="size-4 shrink-0 text-[#006DFF]" />
              ) : (
                <HardDrive className="size-4 shrink-0 text-[#006DFF]" />
              )}
              {f.text}
            </li>
          ))}
        </ul>

        {/* Цена — крупно */}
        <div className="mt-4">
          <div className="flex items-baseline gap-1.5">
            <span className="text-[32px] font-extrabold leading-none text-[#071A3F]">
              {plan.priceCurrent}
            </span>
            <span className="text-sm text-[#4B638A]">/мес</span>
          </div>
          {/* Старая цена мелко снизу */}
          <div className="mt-0.5 text-xs text-[#4B638A] line-through">
            {plan.priceOld}
          </div>
        </div>

        {/* CTA внутри карточки */}
        <div className="mt-auto pt-5">
          <Button
            asChild
            size="sm"
            className={
              plan.popular
                ? "w-full rounded-xl bg-gradient-brand text-white hover:opacity-90 focus-visible:ring-2 focus-visible:ring-[#006DFF]"
                : "w-full rounded-xl border border-[#D9E8FF] bg-white text-[#071A3F] hover:bg-[#EEF6FF] focus-visible:ring-2 focus-visible:ring-[#006DFF]"
            }
            variant={plan.popular ? "default" : "outline"}
          >
            <a href="#contact" onClick={() => goal('tariff_click')}>Выбрать тариф</a>
          </Button>
        </div>
      </article>
    </Reveal>
  );
}

/* ─── главный экспорт ─────────────────────────────────────────*/
export function Tariffs() {
  return (
    <section id="tariffs" className="bg-white py-16 md:py-20">
      <Container>
        <SectionTitle
          eyebrow="Выгодные условия"
          title="Тарифы и лицензии Битрикс24"
          titleGradient="Битрикс24"
          subtitle="Официальные тарифы облачной версии Битрикс24. Скидка 50% при первой покупке."
        />

        {/* Сетка карточек */}
        <div className="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {PLANS.map((plan, i) => (
            <TariffCard key={plan.name} plan={plan} delay={i * 80} />
          ))}
        </div>

        {/* Дисклеймер */}
        <Reveal delay={200}>
          <p className="mt-4 text-center text-xs text-[#4B638A]">
            * Скидка 50% для тех, кто покупает облачный тариф впервые. Цены без НДС. Цены соответствуют{" "}
            <a
              href="https://www.bitrix24.ru/prices/"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#006DFF] underline underline-offset-2 hover:text-[#0057CC]"
            >
              официальному прайс-листу Битрикс24
            </a>
            . Актуальную стоимость уточняйте у менеджера.
          </p>
        </Reveal>
      </Container>
    </section>
  );
}
