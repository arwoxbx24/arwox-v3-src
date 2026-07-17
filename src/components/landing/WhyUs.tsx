/**
 * WhyUs — Секция «Почему ARWOX»
 * bg-surface (белый), 5 компактных карточек, 3D-иконки из /assets/gen/.
 * Без pill-бэджика и подзаголовка — по эталону дизайнера.
 */

import type { ReactNode } from 'react';

import { Container, Reveal } from '@/components/landing/atoms';

/* ── 3D-иконка в тайле ── */
interface Icon3DProps {
  src: string;
}

function Icon3D({ src }: Icon3DProps) {
  return (
    <span className="grid size-14 shrink-0 place-items-center rounded-2xl bg-[#EEF6FF]">
      <img
        src={src}
        alt=""
        aria-hidden="true"
        width={44}
        height={44}
        className="size-11 select-none object-contain"
        loading="lazy"
        decoding="async"
      />
    </span>
  );
}

interface WhyCard {
  icon: ReactNode;
  title: string;
  description: string;
}

const CARDS: WhyCard[] = [
  {
    icon: <Icon3D src="/assets/gen/ic3d-analytics.png" />,
    title: 'Глубокий предпроектный анализ',
    description:
      'Изучаем воронку продаж, процессы команды и узкие места до начала настройки. Решаем конкретную задачу.',
  },
  {
    icon: <Icon3D src="/assets/gen/ic3d-platform.png" />,
    title: 'Комплексный аудит перед стартом',
    description:
      'Оцениваем текущие инструменты, интеграции и данные. Выявляем риски до того, как они станут проблемой.',
  },
  {
    icon: <Icon3D src="/assets/gen/ic3d-crm.png" />,
    title: 'Настройка под вашу воронку',
    description:
      'Не даём «типовую» конфигурацию — разрабатываем структуру CRM, роботов и БП под реальную модель продаж.',
  },
  {
    icon: <Icon3D src="/assets/gen/ic3d-docs.png" />,
    title: 'Обучение команды и поддержка',
    description:
      'Обучение для менеджеров и руководителей. После запуска сопровождаем, отвечаем на вопросы, дорабатываем.',
  },
  {
    icon: <Icon3D src="/assets/gen/ic3d-check-green.png" />,
    title: 'Фиксация договорённостей',
    description:
      'Объём работ, сроки и бюджет фиксируем в ТЗ и договоре до старта. Сопровождаем проект до приёмки по ТЗ, а не «до сдачи настройки».',
  },
];

export function WhyUs() {
  return (
    <section className="bg-[var(--color-surface)] py-16 md:py-20" id="why-us">
      <Container>
        {/* Заголовок — без pill-бэджика и подзаголовка */}
        <Reveal>
          <h2 className="mb-3 text-center text-[2rem] font-semibold leading-tight text-[var(--color-foreground)]">
            Почему{' '}
            <span style={{ color: '#006DFF' }}>ARWOX</span>
          </h2>
          {/* УТП-крюк: обосновывает карточки ниже */}
          <p className="mx-auto mb-10 max-w-xl text-center text-[15px] leading-relaxed text-[#4B638A]">
            Большинство неудачных внедрений Битрикс24 проваливаются из-за
            отсутствия предпроектного анализа. Мы начинаем именно с него.
          </p>
        </Reveal>

        {/* 5 карточек в ряд */}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
          {CARDS.map((card, i) => (
            <Reveal key={card.title} delay={i * 80}>
              <WhyCardItem card={card} />
            </Reveal>
          ))}
        </div>
      </Container>
    </section>
  );
}

/* ── Individual card ── */
function WhyCardItem({ card }: { card: WhyCard }) {
  return (
    <article className="card-soft rounded-2xl p-5 transition-shadow duration-200 hover:shadow-[0_18px_55px_rgba(0,75,160,0.10)]">
      {/* 3D-иконка в тайле */}
      <div className="mb-4">{card.icon}</div>

      {/* Text */}
      <h3 className="text-sm font-semibold leading-snug text-[var(--color-foreground)]">
        {card.title}
      </h3>
      <p className="mt-2 text-sm leading-relaxed text-[var(--color-muted-foreground)]">
        {card.description}
      </p>
    </article>
  );
}
