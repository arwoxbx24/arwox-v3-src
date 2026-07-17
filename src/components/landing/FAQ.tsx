/**
 * Секция 11 — FAQ (Часто задаваемые вопросы)
 * Ownership: FAQ.tsx
 *
 * Структура:
 *   1. Заголовок по центру
 *   2. Простой аккордеон max-w ~860px по центру:
 *      белые скруглённые строки, вопрос жирным слева, +/− справа,
 *      раскрытый ответ серым
 *   3. Строка "Остались вопросы? Напишите нам" внизу
 */

"use client";

import { useState, useRef, useEffect, type ReactNode } from "react";
import { Container, SectionTitle, Reveal } from "@/components/landing/atoms";
import { goal } from "@/lib/ym";

/* ─── Данные аккордеона ───────────────────────────────────────*/
interface QA {
  q: string;
  a: ReactNode;
}

const QUESTIONS: QA[] = [
  {
    q: "Чем Битрикс24 отличается от AmoCRM, Salesforce и других?",
    a: "Битрикс24 — это не только CRM. В одной подписке: мессенджер, задачи, видеозвонки, HR, конструктор сайтов, интернет-магазин и документооборот. Конкуренты закрывают 1–2 задачи — Битрикс24 закрывает весь рабочий контур компании.",
  },
  {
    q: "Что входит в бесплатный тариф?",
    a: (
      <>
        Бесплатный тариф — навсегда, без ограничений по числу пользователей.
        Включает CRM, задачи, чаты, диск 5 ГБ, конструктор сайтов, контакт-центр
        и базовый доступ к BitrixGPT. Автоматизация процессов и расширенная
        аналитика доступны на платных тарифах.{" "}
        <a
          href="https://www.bitrix24.ru/prices/"
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-1 text-[#1677FF] hover:underline"
        >
          <svg width="12" height="12" viewBox="0 0 12 12" fill="none" aria-hidden="true">
            <path d="M2.5 9.5L9.5 2.5M9.5 2.5H4.5M9.5 2.5V7.5" stroke="#1677FF" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          bitrix24.ru/prices
        </a>
      </>
    ),
  },
  {
    q: "Сколько времени занимает внедрение?",
    a: "Базовое внедрение (воронка + роботы + обучение) — 10–14 рабочих дней. Сложные проекты с интеграцией 1С, телефонии и нестандартными процессами — от 3 до 6 недель.",
  },
  {
    q: "Облако или коробка — что выбрать?",
    a: (
      <>
        Облако — быстрый старт, обновления автоматически, оплата по подписке.
        Коробка — если данные обязаны храниться на вашем сервере: подходит для
        финансовых и государственных структур. Для большинства бизнесов
        рекомендуем облако.{" "}
        <a
          href="https://www.bitrix24.ru/box/"
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-1 text-[#1677FF] hover:underline"
        >
          <svg width="12" height="12" viewBox="0 0 12 12" fill="none" aria-hidden="true">
            <path d="M2.5 9.5L9.5 2.5M9.5 2.5H4.5M9.5 2.5V7.5" stroke="#1677FF" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          Коробочная версия
        </a>
      </>
    ),
  },
  {
    q: "Можно ли интегрировать с 1С?",
    a: "Да. Официальная интеграция Битрикс24 + 1С синхронизирует товары, счета, оплаты и контрагентов. ARWOX настраивал эту интеграцию более чем в 50 проектах.",
  },
  {
    q: "Что такое маркетплейс Битрикс24?",
    a: (
      <>
        Маркетплейс — магазин готовых интеграций и расширений. Коннекторы с
        WhatsApp, Telegram, Ozon, Wildberries, Яндекс.Доставкой, платёжными
        системами и сотнями других сервисов. Большинство популярных интеграций
        доступны бесплатно или по минимальной цене.{" "}
        <a
          href="https://www.bitrix24.ru/apps/"
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-1 text-[#1677FF] hover:underline"
        >
          <svg width="12" height="12" viewBox="0 0 12 12" fill="none" aria-hidden="true">
            <path d="M2.5 9.5L9.5 2.5M9.5 2.5H4.5M9.5 2.5V7.5" stroke="#1677FF" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          Маркетплейс приложений
        </a>
      </>
    ),
  },
  {
    q: "Работаете с юридическими лицами? Какие документы предоставляете?",
    a: "Да. Работаем с ИП и юрлицами. После оплаты выставляем договор, счёт и закрывающие документы (акт). НДС и УСН — оба варианта.",
  },
  {
    q: "Сколько стоит внедрение?",
    a: (
      <>
        Стоимость зависит от объёма и сложности проекта. Ориентировочные пакеты:{" "}
        <strong>«Старт»</strong> — базовая настройка CRM-воронки, права доступа, роботы, обучение для команд до 5 человек;{" "}
        <strong>«Бизнес»</strong> — воронки под ваш цикл, подключение каналов (телефония, WhatsApp, Telegram, почта), шаблоны документов, обучение отдела, до 50 человек;{" "}
        <strong>«Проект»</strong> — интеграция с 1С, нетиповые процессы, разработка. Цена определяется по итогам платного предпроектного обследования — его результат (ТЗ и смета) остаётся у вас. Точные цифры называем на разборе после погружения в ваши процессы.
      </>
    ),
  },
  {
    q: "Что будет на 30-минутном разборе?",
    a: "Разберём ваши текущие процессы по чек-листу, назовём вилку бюджета под вашу задачу и набросаем план первых шагов. Никаких обязательств — просто честный разговор о том, что и как можно улучшить.",
  },
  {
    q: "Вы показываете систему до покупки?",
    a: "Да. Проводим 20-минутное демо на настроенном портале Битрикс24 под вашу отрасль: живая воронка, интеграции, документы по шаблону. После демо включаем пробный период полного тарифа. Перед демо — короткий созвон на 15–20 минут, чтобы уточнить вашу отрасль и показать именно нужные сценарии.",
  },
];

/* ─── AccordionItem ───────────────────────────────────────────*/
interface AccordionItemProps {
  item: QA;
  isOpen: boolean;
  onToggle: () => void;
}

function AccordionItem({ item, isOpen, onToggle }: AccordionItemProps) {
  const contentRef = useRef<HTMLDivElement>(null);
  const [height, setHeight] = useState<number>(0);

  useEffect(() => {
    if (contentRef.current) {
      setHeight(isOpen ? contentRef.current.scrollHeight : 0);
    }
  }, [isOpen]);

  return (
    <div className="overflow-hidden rounded-xl border border-[var(--color-border)] bg-white">
      <button
        type="button"
        onClick={onToggle}
        className="flex w-full items-center justify-between gap-4 px-5 py-5 text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-brand)] focus-visible:ring-offset-2"
        aria-expanded={isOpen}
      >
        <span className="text-base font-bold leading-snug text-[var(--color-foreground)]">
          {item.q}
        </span>
        <span
          className="flex h-8 w-8 shrink-0 items-center justify-center text-2xl font-light leading-none text-[var(--color-brand)]"
          aria-hidden="true"
        >
          {isOpen ? "−" : "+"}
        </span>
      </button>

      {/* Animated content */}
      <div
        style={{
          height: `${height}px`,
          overflow: "hidden",
          transition: "height 300ms cubic-bezier(0.16, 1, 0.3, 1)",
        }}
      >
        <div ref={contentRef} className="px-5 pb-5">
          <p className="text-sm leading-relaxed text-[var(--color-muted-foreground)]">
            {item.a}
          </p>
        </div>
      </div>
    </div>
  );
}

/* ─── Главный экспорт ─────────────────────────────────────────*/
export function FAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  const handleToggle = (i: number) => {
    setOpenIndex((prev) => (prev === i ? null : i));
  };

  return (
    <section id="faq" className="bg-white py-16 md:py-24">
      <Container className="max-w-5xl">
        <SectionTitle
          eyebrow="FAQ"
          title="Часто задаваемые вопросы"
          subtitle="Ответы на частые вопросы о Битрикс24 и наших услугах."
        />

        {/* Аккордеон */}
        <div className="mx-auto mt-4 flex max-w-[860px] flex-col gap-2">
          {QUESTIONS.map((item, i) => (
            <Reveal key={i} delay={i * 60}>
              <AccordionItem
                item={item}
                isOpen={openIndex === i}
                onToggle={() => handleToggle(i)}
              />
            </Reveal>
          ))}
        </div>

        {/* Финальный призыв */}
        <Reveal delay={200}>
          <p className="mt-10 text-center text-sm text-[var(--color-muted-foreground)]">
            Остались вопросы?{" "}
            <a
              href="#contact"
              onClick={() => goal('faq_contact')}
              className="font-semibold text-[var(--color-brand)] hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-brand)] focus-visible:ring-offset-2 rounded"
            >
              Напишите нам
            </a>{" "}
            — ответим в течение 15 минут.
          </p>
        </Reveal>
      </Container>
    </section>
  );
}
