/**
 * ARWOX Landing V3 — Demo Section
 * «Не рассказываем — показываем» (P1-3)
 * Вставляется после блока Results.
 */

import { Container, SectionTitle, Reveal, GradientIconBox } from '@/components/landing/atoms';
import { MonitorPlay, Building2, Clock } from 'lucide-react';
import { goal } from "@/lib/ym";

/* ── Пункты секции ── */
const DEMO_POINTS = [
  {
    icon: <MonitorPlay className="size-5" />,
    text: 'Портал уже настроен — вы смотрите работающую систему, а не слайды',
  },
  {
    icon: <Building2 className="size-5" />,
    text: 'Показываем сценарии именно вашей отрасли',
  },
  {
    icon: <Clock className="size-5" />,
    text: 'После демо поможем активировать 15-дневный демо-режим Битрикс24',
  },
];

/* ── Main export ── */
export function Demo() {
  return (
    <section
      id="demo"
      className="py-16 md:py-24"
      style={{ background: 'linear-gradient(160deg, #EEF6FF 0%, #F6FAFF 60%, #EEF6FF 100%)' }}
    >
      <Container>
        <div className="mx-auto max-w-4xl">
          <Reveal>
            <SectionTitle
              eyebrow="Демо"
              title="Не рассказываем — показываем"
              subtitle="За 20 минут проведём вас по настроенному порталу Битрикс24 под вашу отрасль: живая воронка, автоматическое заполнение оплат из 1С, все мессенджеры в одном окне, документы по шаблону за минуту."
            />
          </Reveal>

          {/* Три пункта */}
          <Reveal delay={80}>
            <ul className="mt-10 flex flex-col gap-4 sm:flex-row sm:gap-6">
              {DEMO_POINTS.map((point, i) => (
                <li
                  key={i}
                  className="flex flex-1 items-start gap-4 rounded-[20px] bg-white p-5"
                  style={{ boxShadow: '0 10px 40px rgba(0,75,160,.09)' }}
                >
                  <GradientIconBox size="sm" gradient="brand" className="mt-0.5 shrink-0">
                    {point.icon}
                  </GradientIconBox>
                  <p className="text-sm leading-relaxed text-[#071A3F]">{point.text}</p>
                </li>
              ))}
            </ul>
          </Reveal>

          {/* CTA */}
          <Reveal delay={160}>
            <div className="mt-10 flex flex-col items-center gap-3">
              <a
                href="#contact"
                onClick={() => goal('demo_cta')}
                className="inline-flex h-14 items-center justify-center rounded-full px-8 text-sm font-semibold text-white transition-opacity hover:opacity-90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#006DFF] focus-visible:ring-offset-2"
                style={{
                  background: 'linear-gradient(135deg, #006DFF 0%, #1677FF 55%, #8B5CF6 100%)',
                  boxShadow: '0 8px 32px rgba(0,109,255,0.35)',
                }}
              >
                Записаться на демо
              </a>
              <p className="max-w-md text-center text-xs leading-relaxed text-[#4B638A]">
                Перед демо — короткий созвон на 15–20 минут: уточним вашу отрасль и процессы,
                чтобы показать сценарии, которые касаются именно вас.
              </p>
            </div>
          </Reveal>
        </div>
      </Container>
    </section>
  );
}
