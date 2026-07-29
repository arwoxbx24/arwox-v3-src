import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import { toast } from "sonner";
import {
  Phone, Mail, MapPin, ArrowRight, Check, Sparkles, Bot, MessageSquare, Mic,
  Calendar, Users, Plug, Send, ShoppingCart, BarChart3, Globe, Database,
  Search, ShieldCheck, GitBranch, GraduationCap, Rocket, PlayCircle,
  Award,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import {
  Accordion, AccordionContent, AccordionItem, AccordionTrigger,
} from "@/components/ui/accordion";
import aiChip from "@/assets/ai-chip.png";
import sanatorium from "@/assets/sanatorium.jpg";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "ARWOX — Внедрение Битрикс24 в Краснодаре" },
      { name: "description", content: "Бизнес-партнёр Битрикс24. Внедрение CRM, интеграция с 1С и телефонией, BitrixGPT, разработка сайтов. Лицензии −30%." },
      { property: "og:title", content: "ARWOX — Внедрение Битрикс24" },
      { property: "og:description", content: "Полный цикл: анализ, настройка CRM, интеграции, обучение. Среднее время запуска — 14 дней." },
    ],
  }),
  component: Landing,
});

/* ---------- Atoms ---------- */
function Pill({ children }: { children: React.ReactNode }) {
  return (
    <div className="inline-flex items-center gap-2 rounded-full border border-border bg-white px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-brand">
      <span className="size-1.5 rounded-full bg-brand" /> {children}
    </div>
  );
}
function Logo({ className = "" }: { className?: string }) {
  return (
    <div className={`flex items-center gap-2 ${className}`}>
      <div className="grid size-9 place-items-center rounded-xl bg-gradient-brand">
        <svg viewBox="0 0 24 24" className="size-5 text-white" fill="none" stroke="currentColor" strokeWidth="2.5">
          <path d="M3 20L12 4l9 16M7 20h10" />
        </svg>
      </div>
      <span className="text-xl font-bold tracking-tight">ARWOX</span>
    </div>
  );
}

/* ---------- Header ---------- */
function Header() {
  return (
    <header className="fixed inset-x-0 top-4 z-50 px-4">
      <div className="mx-auto flex max-w-7xl items-center justify-between rounded-2xl glass px-4 py-3">
        <Logo />
        <nav className="hidden items-center gap-7 text-sm text-muted-foreground lg:flex">
          <a href="#tariffs" className="hover:text-foreground">Тарифы −30%</a>
          <a href="#cases" className="hover:text-foreground">Кейсы</a>
          <a href="#bitrixgpt" className="hover:text-foreground">BitrixGPT</a>
          <a href="#faq" className="hover:text-foreground">Вопросы</a>
          <a href="#websites" className="hover:text-foreground">Разработка сайтов</a>
        </nav>
        <div className="flex items-center gap-3">
          <div className="hidden text-right md:block">
            <a href="tel:+79287051199" className="block text-sm font-semibold">+7 928-705-11-99</a>
            <span className="text-[11px] text-muted-foreground">Бесплатная консультация</span>
          </div>
          <Button asChild className="rounded-xl bg-gradient-brand text-white hover:opacity-90">
            <a href="#contact">Оставить заявку</a>
          </Button>
        </div>
      </div>
    </header>
  );
}

/* ---------- Hero ---------- */
function Hero() {
  return (
    <section className="relative overflow-hidden bg-hero pt-36 pb-24">
      <div className="relative mx-auto grid max-w-7xl items-center gap-12 px-4 lg:grid-cols-2">
        <div>
          <div className="inline-flex items-center gap-2 rounded-full border border-border bg-white px-4 py-2 text-xs text-muted-foreground shadow-sm">
            <span className="size-2 rounded-full bg-brand" />
            Бизнес-партнёр Битрикс24 · г. Краснодар
          </div>
          <h1 className="mt-6 text-5xl font-bold leading-[1.05] sm:text-6xl lg:text-7xl">
            Внедрим <span className="text-gradient">Битрикс24</span>
            <br />от анализа до результата
          </h1>
          <p className="mt-6 max-w-xl text-base text-muted-foreground sm:text-lg">
            Проводим полный цикл: анализ бизнес-процессов, настройка CRM под вашу
            воронку, интеграция с 1С и телефонией, обучение команды.
            Среднее время запуска — <span className="font-semibold text-foreground">14 дней</span>.
          </p>
          <div className="mt-8 flex flex-wrap gap-3">
            <Button asChild size="lg" className="h-14 rounded-2xl bg-gradient-brand px-6 text-white hover:opacity-90">
              <a href="#contact"><Rocket className="mr-2 size-5" /> Получить консультацию</a>
            </Button>
            <Button asChild size="lg" variant="outline" className="h-14 rounded-2xl border-border bg-white px-6 text-foreground hover:bg-surface-soft">
              <a href="#cases"><PlayCircle className="mr-2 size-5" /> Смотреть кейсы</a>
            </Button>
          </div>
          <div className="mt-8 flex flex-wrap gap-6 text-sm text-muted-foreground">
            <a href="tel:+79287051199" className="inline-flex items-center gap-2 hover:text-foreground"><Phone className="size-4" /> +7 928-705-11-99</a>
            <a href="mailto:hello@arwox.ru" className="inline-flex items-center gap-2 hover:text-foreground"><Mail className="size-4" /> hello@arwox.ru</a>
          </div>
        </div>

        <div className="relative">
          <DashboardMock />
        </div>
      </div>

      {/* competence ribbon */}
      <div className="relative mx-auto mt-16 max-w-7xl px-4">
        <div className="grid grid-cols-2 gap-3 rounded-2xl glass p-3 md:grid-cols-4">
          {[
            { i: <Award className="size-5" />, t: "БИЗНЕС-ПАРТНЁР", s: "Битрикс24" },
            { i: <Database className="size-5" />, t: "ПЛАТФОРМА", s: "Облако + Коробка" },
            { i: <BarChart3 className="size-5" />, t: "CRM", s: "Внедрение и настройка" },
            { i: <Bot className="size-5" />, t: "АВТОМАТИЗАЦИЯ", s: "Роботы и BitrixGPT" },
          ].map((c) => (
            <div key={c.t} className="flex items-center gap-3 rounded-xl bg-surface-soft px-4 py-3">
              <div className="grid size-10 place-items-center rounded-lg bg-gradient-brand text-white">{c.i}</div>
              <div>
                <div className="text-[10px] font-semibold tracking-[0.18em] text-muted-foreground">{c.t}</div>
                <div className="text-sm font-semibold">{c.s}</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function DashboardMock() {
  return (
    <div className="dark-scope relative rounded-[28px] p-4 shadow-glow" style={{ background: "linear-gradient(180deg, #082A5A, #061A3D)" }}>
      <div className="rounded-2xl bg-dark-blue p-5">
        <div className="mb-4 flex items-center justify-between">
          <div className="flex items-center gap-1.5">
            <span className="size-3 rounded-full bg-[#ff5f57]" />
            <span className="size-3 rounded-full bg-[#febc2e]" />
            <span className="size-3 rounded-full bg-[#28c840]" />
          </div>
          <div className="text-xs text-muted-foreground">Битрикс24 · CRM Dashboard</div>
          <div className="inline-flex items-center gap-1.5 rounded-full bg-emerald-500/15 px-2 py-1 text-[10px] font-semibold text-emerald-300">
            <span className="size-1.5 rounded-full bg-emerald-400 animate-pulse" /> Live
          </div>
        </div>

        <div className="grid grid-cols-2 gap-2 md:grid-cols-4">
          {[
            { v: "124", l: "Лидов", d: "↑ 18%" },
            { v: "38", l: "Сделок", d: "↑ 12%" },
            { v: "31%", l: "Конверсия", d: "↑ с 14%" },
            { v: "₽3.2М", l: "Выручка", d: "↑ 8%" },
          ].map((k) => (
            <div key={k.l} className="rounded-xl bg-white/[0.05] p-3">
              <div className="text-2xl font-bold">{k.v}</div>
              <div className="text-[11px] text-muted-foreground">{k.l}</div>
              <div className="text-[11px] text-emerald-300">{k.d}</div>
            </div>
          ))}
        </div>

        <div className="mt-4 rounded-xl bg-white/[0.05] p-4">
          <div className="mb-2 flex justify-between text-xs text-muted-foreground">
            <span>ВОРОНКА ПРОДАЖ</span><span className="text-brand-2">124 → 38 сделок</span>
          </div>
          <div className="space-y-2">
            {[
              { l: "Новые", v: 124, w: "100%" },
              { l: "Переговоры", v: 52, w: "70%" },
              { l: "Счёт", v: 44, w: "55%" },
              { l: "Закрыты", v: 38, w: "40%" },
            ].map((s) => (
              <div key={s.l} className="flex items-center gap-2 text-xs">
                <div className="w-20 text-muted-foreground">{s.l} ({s.v})</div>
                <div className="h-2 flex-1 overflow-hidden rounded-full bg-white/10">
                  <div className="h-full bg-gradient-brand" style={{ width: s.w }} />
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="mt-4 grid grid-cols-1 gap-3 md:grid-cols-2">
          <div className="rounded-xl bg-white/[0.05] p-4">
            <div className="mb-2 flex justify-between text-xs text-muted-foreground">
              <span>КОНВЕРСИЯ ПО МЕСЯЦАМ</span><span className="text-brand-2">+122% за год</span>
            </div>
            <div className="flex h-28 items-end gap-1.5">
              {[18, 22, 25, 30, 34, 40, 52, 70].map((h, i) => (
                <div key={i} className="flex-1 rounded-t bg-gradient-brand" style={{ height: `${h}%` }} />
              ))}
            </div>
            <div className="mt-1 flex justify-between text-[10px] text-muted-foreground"><span>Ноя</span><span>Май</span></div>
          </div>
          <div className="rounded-xl bg-white/[0.05] p-4">
            <div className="mb-2 text-xs text-muted-foreground">ЗАДАЧИ КОМАНДЫ</div>
            <div className="flex items-center gap-4">
              <div className="relative grid size-24 place-items-center rounded-full"
                style={{ background: "conic-gradient(#006DFF 72%, rgba(255,255,255,0.08) 0)" }}>
                <div className="grid size-16 place-items-center rounded-full bg-dark-blue">
                  <span className="text-base font-bold">72%</span>
                </div>
              </div>
              <div className="space-y-1 text-xs">
                <div className="flex items-center gap-2"><span className="size-2 rounded-full bg-brand"/>Выполнено 72%</div>
                <div className="flex items-center gap-2"><span className="size-2 rounded-full bg-brand-2"/>В работе 18%</div>
                <div className="flex items-center gap-2"><span className="size-2 rounded-full bg-rose-400"/>Просрочено 10%</div>
              </div>
            </div>
          </div>
        </div>

        <div className="mt-4 rounded-xl bg-white/[0.05] p-4">
          <div className="mb-3 text-xs text-muted-foreground">АКТИВНОСТЬ СЕГОДНЯ</div>
          <div className="space-y-2">
            {[
              { n: "Позвонить Иванову А.В.", c: "Сделка: Внедрение CRM", t: "14:00", b: "Скоро", bc: "bg-amber-500/20 text-amber-300" },
              { n: "Отправить КП Петрову", c: "Сделка: Интеграция 1С", t: "11:30", b: "Готово", bc: "bg-emerald-500/20 text-emerald-300" },
            ].map((a) => (
              <div key={a.n} className="flex items-center justify-between rounded-lg bg-white/[0.04] p-2 text-xs">
                <div className="flex items-center gap-2">
                  <div className="grid size-7 place-items-center rounded-full bg-gradient-brand text-[10px] text-white">●</div>
                  <div>
                    <div className="font-medium">{a.n}</div>
                    <div className="text-[10px] text-muted-foreground">{a.c}</div>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-muted-foreground">Сегодня {a.t}</span>
                  <span className={`rounded-full px-2 py-0.5 text-[10px] ${a.bc}`}>{a.b}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

/* ---------- Results / scenarios ---------- */
function Results() {
  const cases = [
    {
      tag: "Сценарий 1",
      problem: "Лиды теряются на трёх этапах воронки",
      story: "Клиент приходит с жалобой: конверсия 14%, заявки ведут в Excel, ответственные не назначены, повторных звонков нет. Руководитель не видит, на каком этапе обрываются продажи.",
      base: { v: "14%", l: "конверсия лид → сделка" },
      did: [
        "Настроили воронку под реальный цикл продаж — от первой заявки до закрытия",
        "Роботы ставят задачи, напоминают о звонках, автоматически создают счета",
        "Руководитель видит каждый лид и его статус в реальном времени",
      ],
      didTitle: "CRM-воронка с автоматическими задачами на каждом шаге",
      result: { title: "Конверсия выросла в 2,2 раза", days: "90 дней",
        metrics: [{ v: "31%", l: "конверсия", was: "было 14%" }, { v: "16 дн", l: "закрытие", was: "было 28 дней" }] },
    },
    {
      tag: "Сценарий 2",
      problem: "Заявки из WhatsApp, сайта и Авито теряются",
      story: "Обращения поступают в разные места — телефон, почта, мессенджеры. Часть теряется, часть обрабатывается спустя часы. Клиент успевает уйти к конкуренту.",
      base: { v: "3–4 ч", l: "среднее время первого ответа" },
      did: [
        "Подключили WhatsApp, Telegram, форму сайта и Авито через Open Channels Битрикс24",
        "Каждое обращение автоматически создаёт лид и назначает ответственного",
        "Бот мгновенно отвечает клиенту и ставит задачу менеджеру с дедлайном",
      ],
      didTitle: "Все каналы — в единую воронку через Open Channels",
      result: { title: "Скорость ответа выросла в 13 раз", days: "60 дней",
        metrics: [{ v: "18 мин", l: "первый ответ", was: "было 3–4 ч" }, { v: "+23%", l: "конв. первого контакта", was: "к базовому периоду" }] },
    },
    {
      tag: "Сценарий 3",
      problem: "Нет контроля: сотрудники работают хаотично",
      story: "Регламенты не соблюдаются, документы не прикладываются. Руководитель не понимает, где сотрудник «застрял» и как объективно оценить эффективность команды.",
      base: { v: "0", l: "видимость работы команды" },
      did: [
        "Внедрили регламенты и шаблоны бизнес-процессов в Битрикс24",
        "Подключили контроль задач, дедлайнов и автоматические напоминания",
        "Настроили дашборды эффективности: руководитель видит загрузку каждого",
      ],
      didTitle: "Прозрачные процессы и единые регламенты для команды",
      result: { title: "Команда работает в едином ритме", days: "75 дней",
        metrics: [{ v: "+35%", l: "продуктивность", was: "" }, { v: "−50%", l: "время на поиск инфо", was: "" }] },
    },
  ];

  return (
    <section id="results" className="relative bg-surface-soft">
      <div className="mx-auto max-w-7xl px-4 py-24">
        <div className="text-center">
          <Pill>Результат</Pill>
          <h2 className="mt-4 text-4xl font-bold sm:text-5xl">
            Что меняется после <br /> внедрения <span className="text-gradient">Битрикс24</span>
          </h2>
          <p className="mx-auto mt-4 max-w-2xl text-muted-foreground">
            Три сценария из практики. Сначала замеряем базовые показатели — потом внедряем и
            отслеживаем динамику. Цифры появляются после, не до.
          </p>
        </div>

        <div className="mt-12 grid gap-6 lg:grid-cols-3">
          {cases.map((c) => (
            <article key={c.tag} className="flex flex-col rounded-2xl card-soft p-6">
              <div className="mb-4 flex items-center justify-between">
                <div className="grid size-11 place-items-center rounded-xl bg-gradient-brand text-white">
                  <BarChart3 className="size-5" />
                </div>
                <span className="rounded-full bg-brand/10 px-3 py-1 text-[11px] font-medium text-brand">{c.tag}</span>
              </div>
              <h3 className="text-sm font-semibold text-rose-600">Проблема</h3>
              <div className="mt-1 text-base font-semibold">{c.problem}</div>
              <p className="mt-2 text-sm text-muted-foreground">{c.story}</p>

              <div className="mt-4 rounded-xl bg-surface-soft p-3">
                <div className="text-[11px] uppercase tracking-wider text-muted-foreground">Базовый замер — до</div>
                <div className="mt-1 text-2xl font-bold">{c.base.v}</div>
                <div className="text-xs text-muted-foreground">{c.base.l}</div>
              </div>

              <div className="mt-5">
                <div className="text-sm font-semibold text-brand">Что сделали</div>
                <div className="mt-1 text-sm font-medium">{c.didTitle}</div>
                <ol className="mt-3 space-y-2">
                  {c.did.map((d, i) => (
                    <li key={i} className="flex gap-3 text-sm">
                      <span className="grid size-6 shrink-0 place-items-center rounded-full bg-gradient-brand text-[11px] font-bold text-white">{i + 1}</span>
                      <span className="text-foreground/80">{d}</span>
                    </li>
                  ))}
                </ol>
              </div>

              <div className="mt-5 rounded-xl border border-brand/20 bg-gradient-to-br from-brand/[0.06] to-brand-2/[0.06] p-4">
                <div className="text-[11px] uppercase tracking-wider text-brand">Итог — через {c.result.days}</div>
                <div className="mt-1 font-semibold">{c.result.title}</div>
                <div className="mt-3 grid grid-cols-2 gap-3">
                  {c.result.metrics.map((m) => (
                    <div key={m.l}>
                      <div className="text-2xl font-bold text-gradient">{m.v}</div>
                      <div className="text-[11px] text-muted-foreground">{m.l}</div>
                      {m.was && <div className="text-[10px] text-muted-foreground/80">{m.was}</div>}
                    </div>
                  ))}
                </div>
              </div>
              <p className="mt-3 text-[10px] text-muted-foreground">* Замер выполняется после внедрения. Результат зависит от специфики бизнеса.</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ---------- Sanatorium case ---------- */
function SanatoriumCase() {
  return (
    <section id="cases" className="bg-background py-24">
      <div className="mx-auto max-w-7xl px-4">
        <div className="overflow-hidden rounded-3xl card-soft">
          <div className="p-8 md:p-10">
            <div className="flex flex-wrap items-center justify-between gap-4">
              <Pill>Кейс клиента</Pill>
              <div className="flex items-center gap-2 text-sm font-semibold text-muted-foreground">
                <Sparkles className="size-4 text-brand" /> Санаторно-курортный комплекс
              </div>
            </div>
            <h3 className="mt-4 text-3xl font-bold md:text-4xl">Заявки терялись, менеджеры работали в нескольких окнах</h3>
            <p className="mt-2 text-sm text-muted-foreground">Отрасль: санаторно-курортный комплекс · Bitrix24 Коробка · 50 пользователей</p>
          </div>

          <div className="grid gap-6 px-8 pb-8 md:grid-cols-[1.1fr_1.4fr] md:px-10 md:pb-10">
            <div className="relative overflow-hidden rounded-2xl">
              <img src={sanatorium} alt="Санаторно-курортный комплекс" width={1280} height={800} className="h-full w-full object-cover" />
              <div className="absolute inset-x-0 bottom-0 flex gap-3 bg-gradient-to-t from-black/70 to-transparent p-4">
                <div className="rounded-xl bg-white/15 px-3 py-2 backdrop-blur text-white">
                  <div className="text-[10px] uppercase tracking-wider text-white/80">Срок внедрения</div>
                  <div className="text-lg font-bold">30 дней</div>
                </div>
                <div className="rounded-xl bg-white/15 px-3 py-2 backdrop-blur text-white">
                  <div className="text-[10px] uppercase tracking-wider text-white/80">Команда клиента</div>
                  <div className="text-lg font-bold">50 человек</div>
                </div>
              </div>
            </div>

            <div className="grid gap-6 md:grid-cols-3">
              <div>
                <div className="grid size-10 place-items-center rounded-lg bg-gradient-brand text-white"><ShieldCheck className="size-5" /></div>
                <div className="mt-3 font-semibold">Задача</div>
                <p className="mt-2 text-sm text-muted-foreground">
                  Заявки приходили в личные телефоны и почту, терялись. Менеджеры держали по 4 окна одновременно. Руководитель не видел картину звонков и обращений.
                </p>
              </div>
              <div>
                <div className="grid size-10 place-items-center rounded-lg bg-gradient-brand text-white"><GitBranch className="size-5" /></div>
                <div className="mt-3 font-semibold">Решение</div>
                <ul className="mt-2 space-y-2 text-sm text-muted-foreground">
                  <li className="flex gap-2"><Check className="mt-0.5 size-4 shrink-0 text-brand" /> Bitrix24 Коробка на 50 пользователей</li>
                  <li className="flex gap-2"><Check className="mt-0.5 size-4 shrink-0 text-brand" /> CRM + телефония: IP-шлюз и маршрутизация звонков</li>
                  <li className="flex gap-2"><Check className="mt-0.5 size-4 shrink-0 text-brand" /> Интеграция Marquiz для опросов + КИНТ</li>
                  <li className="flex gap-2"><Check className="mt-0.5 size-4 shrink-0 text-brand" /> Аналитика звонков в реальном времени</li>
                </ul>
              </div>
              <div>
                <div className="grid size-10 place-items-center rounded-lg bg-gradient-brand text-white"><Award className="size-5" /></div>
                <div className="mt-3 font-semibold">Результаты</div>
                <ul className="mt-2 space-y-3 text-sm">
                  <li>
                    <div className="text-2xl font-bold text-gradient">1 окно</div>
                    <div className="text-muted-foreground">Все заявки в единой CRM</div>
                  </li>
                  <li>
                    <div className="text-2xl font-bold text-gradient">real-time</div>
                    <div className="text-muted-foreground">Аналитика звонков для руководителя</div>
                  </li>
                  <li>
                    <div className="text-2xl font-bold text-gradient">×0</div>
                    <div className="text-muted-foreground">Потерянных обращений</div>
                  </li>
                </ul>
              </div>
            </div>
          </div>

          <div className="border-t border-border bg-surface-soft px-8 py-5 md:px-10">
            <div className="flex items-center gap-3 text-sm">
              <div className="grid size-9 place-items-center rounded-full bg-gradient-brand text-xs font-bold text-white">АК</div>
              <div>
                <div className="font-semibold">Андрей К.</div>
                <div className="text-muted-foreground">«Перестали терять обращения. Команда наконец-то работает в одном окне, а я вижу картину звонков в реальном времени.»</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ---------- Why ARWOX ---------- */
function WhyUs() {
  const items = [
    { i: <Search className="size-5" />, t: "Глубокий предпроектный анализ", d: "Изучаем воронку продаж, процессы команды и узкие места до начала настройки. Решаем конкретную задачу." },
    { i: <ShieldCheck className="size-5" />, t: "Комплексный аудит перед стартом", d: "Оцениваем текущие инструменты, интеграции и данные. Выявляем риски до того, как они станут проблемой." },
    { i: <GitBranch className="size-5" />, t: "Настройка под вашу воронку", d: "Не даём «типовую» конфигурацию — разрабатываем структуру CRM, роботов и БП под реальную модель продаж." },
    { i: <GraduationCap className="size-5" />, t: "Обучение команды и поддержка", d: "Обучение для менеджеров и руководителей. После запуска сопровождаем, отвечаем на вопросы, дорабатываем." },
  ];
  return (
    <section className="bg-surface-soft py-24">
      <div className="mx-auto max-w-7xl px-4">
        <div className="text-center">
          <Pill>Наши преимущества</Pill>
          <h2 className="mt-4 text-4xl font-bold sm:text-5xl">Почему <span className="text-gradient">ARWOX</span></h2>
        </div>
        <div className="mt-12 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {items.map((x) => (
            <div key={x.t} className="rounded-2xl card-soft p-6">
              <div className="grid size-12 place-items-center rounded-xl bg-gradient-brand text-white">{x.i}</div>
              <h3 className="mt-4 text-lg font-semibold">{x.t}</h3>
              <p className="mt-2 text-sm text-muted-foreground">{x.d}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ---------- Integrations (dark) ---------- */
function Integrations() {
  const top = [
    { i: "1С", l: "1С" },
    { i: <Phone className="size-5" />, l: "Телефония" },
    { i: <Mail className="size-5" />, l: "E-mail" },
    { i: <MessageSquare className="size-5" />, l: "WhatsApp" },
    { i: <Send className="size-5" />, l: "Telegram" },
    { i: "API", l: "API · Webhook" },
  ];
  const bottom = [
    { i: <Globe className="size-5" />, l: "Сайты и формы" },
    { i: <BarChart3 className="size-5" />, l: "Аналитика" },
    { i: <ShoppingCart className="size-5" />, l: "Интернет-магазины" },
    { i: <Database className="size-5" />, l: "Внешние сервисы" },
  ];
  return (
    <section className="dark-scope relative py-24">
      <div className="mx-auto max-w-7xl px-4">
        <div className="grid gap-10 lg:grid-cols-[1fr_1.6fr] lg:items-center">
          <div>
            <div className="inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/[0.06] px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-brand-2">
              <span className="size-1.5 rounded-full bg-brand-2"/> интеграции
            </div>
            <h2 className="mt-4 text-4xl font-bold sm:text-5xl">Интеграции <br /><span className="text-gradient">без границ</span></h2>
            <p className="mt-4 text-muted-foreground">Подключаем всё, что важно для вашего бизнеса. Единая экосистема — единый результат.</p>
            <ul className="mt-6 space-y-2 rounded-2xl glass p-5 text-sm">
              <li className="flex gap-2"><Check className="mt-0.5 size-4 text-brand-2"/> Готовые коннекторы и гибкие API</li>
              <li className="flex gap-2"><Check className="mt-0.5 size-4 text-brand-2"/> Webhook, скрипты и кастомные решения</li>
              <li className="flex gap-2"><Check className="mt-0.5 size-4 text-brand-2"/> Быстрая синхронизация и надёжность</li>
            </ul>
          </div>

          <div className="space-y-8">
            <IntegrationRow items={top} />
            <IntegrationRow items={bottom} />
          </div>
        </div>
      </div>
    </section>
  );
}
function IntegrationRow({ items }: { items: { i: React.ReactNode; l: string }[] }) {
  return (
    <div className="relative">
      <div className="absolute inset-x-8 top-7 h-px bg-gradient-to-r from-transparent via-brand-2/40 to-transparent" />
      <div className="relative grid gap-3" style={{ gridTemplateColumns: `repeat(${items.length}, minmax(0,1fr))` }}>
        {items.map((it) => (
          <div key={it.l} className="flex flex-col items-center gap-2">
            <div className="grid size-14 place-items-center rounded-2xl bg-white/[0.05] border border-white/10 text-foreground shadow-glow">
              {typeof it.i === "string" ? <span className="text-sm font-bold">{it.i}</span> : it.i}
            </div>
            <span className="text-[11px] text-muted-foreground text-center">{it.l}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

/* ---------- BitrixGPT (dark) ---------- */
function BitrixGPT() {
  const features = [
    { i: <MessageSquare className="size-5" />, t: "Автоматические ответы клиентам", d: "ИИ отвечает в чатах и мессенджерах, экономя время команды." },
    { i: <Mic className="size-5" />, t: "Расшифровка звонков", d: "Транскрипция и анализ звонков, ключевые тезисы и задачи." },
    { i: <Calendar className="size-5" />, t: "Follow-up и встречи", d: "ИИ ставит задачи, напоминает о встречах и контролирует дедлайны." },
    { i: <Users className="size-5" />, t: "Помощь менеджерам", d: "Рекомендации, подсказки и шаблоны прямо в сделке или лиде." },
    { i: <Plug className="size-5" />, t: "Внешние AI и MCP-интеграции", d: "Подключаем ChatGPT, Claude, Mistral и любые MCP-сервисы." },
    { i: <Bot className="size-5" />, t: "BitrixGPT в ленте и задачах", d: "Формулирует тексты, комментарии и предлагает улучшения." },
  ];
  return (
    <section id="bitrixgpt" className="dark-scope relative overflow-hidden py-24" style={{ background: "var(--dark-blue-2)" }}>
      <div aria-hidden className="pointer-events-none absolute inset-0">
        <div className="absolute top-10 right-10 size-[480px] rounded-full bg-brand/25 blur-[160px]" />
      </div>
      <div className="relative mx-auto max-w-7xl px-4">
        <div className="overflow-hidden rounded-3xl glass p-8 md:p-12">
          <div className="grid items-center gap-10 lg:grid-cols-[1.2fr_1fr]">
            <div>
              <div className="inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/[0.06] px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-brand-2">
                <span className="size-1.5 rounded-full bg-brand-2"/> ИИ и автоматизация
              </div>
              <h2 className="mt-4 text-4xl font-bold sm:text-5xl leading-tight">
                Искусственный интеллект<br />
                <span className="text-gradient">BitrixGPT + Маркетплейс</span>
              </h2>
              <p className="mt-4 max-w-xl text-muted-foreground">
                Подписка объединяет 5000+ приложений Маркетплейса и возможности ИИ.
                AI работает 24/7 — вы растёте быстрее.
              </p>
            </div>
            <div className="relative grid place-items-center">
              <div className="absolute inset-0 m-auto size-72 rounded-full bg-brand/30 blur-3xl" />
              <img src={aiChip} alt="AI чип" width={1024} height={1024} loading="lazy" className="relative w-72" />
            </div>
          </div>

          <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {features.map((f) => (
              <div key={f.t} className="rounded-2xl bg-white/[0.05] border border-white/10 p-5">
                <div className="grid size-11 place-items-center rounded-xl bg-gradient-brand text-white">{f.i}</div>
                <h3 className="mt-4 font-semibold">{f.t}</h3>
                <p className="mt-1 text-sm text-muted-foreground">{f.d}</p>
              </div>
            ))}
          </div>

          <div className="mt-8 flex flex-wrap items-center justify-between gap-4 rounded-2xl bg-white/[0.05] border border-white/10 p-5">
            <div className="flex items-center gap-3">
              <div className="grid size-11 place-items-center rounded-xl bg-gradient-brand text-white"><Sparkles className="size-5"/></div>
              <div>
                <div className="font-semibold">Маркетплейс Битрикс24</div>
                <div className="text-sm text-muted-foreground">5000+ готовых приложений и решений для любых задач бизнеса.</div>
              </div>
            </div>
            <Button asChild className="rounded-xl bg-gradient-brand text-white hover:opacity-90">
              <a href="#contact">Открыть маркетплейс <ArrowRight className="ml-2 size-4"/></a>
            </Button>
          </div>
        </div>

        {/* GPT tariffs */}
        <div className="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {[
            { n: "Базовый", u: "5 польз. · 24 ГБ", was: "1 000 ₽", now: "500 ₽" },
            { n: "Стандартный", u: "50 польз. · 100 ГБ", was: "3 000 ₽", now: "1 500 ₽", pop: true },
            { n: "Профессиональный", u: "100 польз. · 1 ТБ", was: "6 000 ₽", now: "3 000 ₽" },
            { n: "Энтерпрайз", u: "250+ польз. · 3 ТБ", was: "13 600 ₽", now: "6 800 ₽" },
          ].map((p) => (
            <div key={p.n} className={`relative rounded-2xl glass p-6 ${p.pop ? "ring-1 ring-brand/60 shadow-glow" : ""}`}>
              {p.pop && <div className="absolute -top-3 left-1/2 -translate-x-1/2 rounded-full bg-gradient-brand px-3 py-1 text-[10px] font-semibold uppercase tracking-wider text-white">Популярный</div>}
              <div className="text-xs text-muted-foreground">Для тарифа</div>
              <div className="mt-1 text-lg font-semibold">{p.n}</div>
              <div className="text-xs text-muted-foreground">{p.u}</div>
              <div className="mt-4 flex items-end gap-2">
                <span className="text-3xl font-bold">{p.now}</span>
                <span className="mb-1 text-sm text-muted-foreground line-through">{p.was}</span>
              </div>
              <div className="text-xs text-muted-foreground">в месяц · −50%</div>
            </div>
          ))}
        </div>
        <p className="mt-3 text-center text-xs text-muted-foreground">Скидка 50% для тех, кто покупает облачный тариф впервые. Цены без НДС.</p>
      </div>
    </section>
  );
}

/* ---------- Tariffs ---------- */
function Tariffs() {
  return (
    <section id="tariffs" className="bg-background py-24">
      <div className="mx-auto max-w-7xl px-4">
        <div className="text-center">
          <Pill>Выгодные условия</Pill>
          <h2 className="mt-4 text-4xl font-bold sm:text-5xl">Тарифы и лицензии <span className="text-gradient">Битрикс24</span></h2>
          <p className="mt-3 text-muted-foreground">Скидка <span className="font-bold text-brand">30%</span> на облачные тарифы через официального партнёра ARWOX</p>
        </div>

        <div className="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {[
            { n: "Базовый", d: "Для небольших команд и старта в CRM", was: "1 700 ₽", now: "1 190 ₽", u: ["12 ГБ места", "5 пользователей"] },
            { n: "Расширенный", d: "Для растущего бизнеса и управления продажами", was: "3 990 ₽", now: "2 790 ₽", u: ["24 ГБ места", "50 пользователей"] },
            { n: "Профессиональный", d: "Для автоматизации бизнес-процессов", was: "7 990 ₽", now: "5 590 ₽", u: ["100 ГБ места", "неогр. пользователей"], pop: true },
            { n: "Энтерпрайз", d: "Для крупных компаний и корпораций", was: "16 990 ₽", now: "11 890 ₽", u: ["1 024 ГБ места", "неогр. пользователей"] },
          ].map((p) => (
            <div key={p.n} className={`relative rounded-2xl card-soft p-6 ${p.pop ? "ring-1 ring-brand/30" : ""}`}>
              {p.pop && <div className="absolute -top-3 left-1/2 -translate-x-1/2 rounded-full bg-gradient-brand px-3 py-1 text-[10px] font-semibold uppercase tracking-wider text-white">Популярный</div>}
              <div className="text-lg font-semibold">{p.n}</div>
              <div className="text-xs text-muted-foreground">{p.d}</div>
              <div className="mt-5 flex items-end gap-2">
                <span className="text-3xl font-bold">{p.now}</span>
                <span className="mb-1 text-sm text-muted-foreground line-through">{p.was}</span>
              </div>
              <div className="text-xs text-muted-foreground">/мес</div>
              <ul className="mt-4 space-y-1 text-sm">
                {p.u.map((x) => <li key={x} className="flex gap-2"><Check className="mt-0.5 size-4 text-brand"/> {x}</li>)}
              </ul>
            </div>
          ))}
        </div>

        <div className="mt-8 rounded-2xl border border-dashed border-border bg-surface-soft p-6 text-center">
          <div className="inline-flex items-center gap-2 text-sm font-semibold">
            <Users className="size-4" /> Официальный виджет тарифов Битрикс24
          </div>
          <p className="mt-2 text-sm text-muted-foreground">
            Здесь будет установлен официальный виджет тарифов — выберите тариф и получите скидку 30% через ARWOX.
          </p>
          <div className="mt-4 flex flex-wrap justify-center gap-3">
            <Button asChild className="rounded-xl bg-gradient-brand text-white hover:opacity-90"><a href="#contact">Получить скидку 30%</a></Button>
            <Button asChild variant="outline" className="rounded-xl"><a href="#contact">Попробовать бесплатно</a></Button>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ---------- FAQ ---------- */
function FAQ() {
  const qa = [
    { q: "Чем Битрикс24 отличается от AmoCRM, Salesforce и других?", a: "Битрикс24 — это не только CRM. В одной подписке: мессенджер, задачи, видеозвонки, HR, конструктор сайтов, интернет-магазин и документооборот. Конкуренты закрывают 1–2 задачи — Битрикс24 закрывает весь рабочий контур компании." },
    { q: "Что входит в бесплатный тариф?", a: "Бесплатный тариф — навсегда, без ограничения по числу пользователей. Включает CRM, задачи, чаты, диск 5 ГБ. Ограничения: нет автоматизации, 1 воронка продаж, базовая телефония." },
    { q: "Сколько времени занимает внедрение?", a: "Базовое внедрение (воронка + роботы + обучение) — 10–14 рабочих дней. Сложные проекты с интеграцией 1С, телефонии и нестандартными процессами — от 3 до 6 недель." },
    { q: "Облако или коробка — что выбрать?", a: "Облако — быстрый старт, обновления автоматически, оплата по подписке. Коробка — если данные обязаны храниться на вашем сервере. Для большинства бизнесов рекомендуем облако." },
    { q: "Можно ли интегрировать с 1С?", a: "Да. Официальная интеграция Битрикс24 + 1С синхронизирует товары, счета, оплаты и контрагентов. ARWOX настраивал эту интеграцию более чем в 50 проектах." },
    { q: "Что такое маркетплейс Битрикс24 и 5000+ приложений?", a: "Маркетплейс — магазин готовых интеграций и расширений. Коннекторы с WhatsApp, Telegram, Ozon, Wildberries, Яндекс.Доставкой, платёжными системами. Подписка BitrixGPT + Маркетплейс даёт доступ ко всем 5000+ приложениям и AI-инструментам." },
  ];
  return (
    <section id="faq" className="bg-surface-soft py-24">
      <div className="mx-auto max-w-5xl px-4">
        <div className="text-center">
          <Pill>вопросы и ответы</Pill>
          <h2 className="mt-4 text-4xl font-bold sm:text-5xl">Часто задаваемые вопросы</h2>
        </div>
        <Accordion type="single" collapsible className="mt-10 w-full space-y-3">
          {qa.map((x, i) => (
            <AccordionItem key={i} value={`i${i}`} className="rounded-2xl card-soft px-5">
              <AccordionTrigger className="text-left text-base font-medium hover:no-underline">{x.q}</AccordionTrigger>
              <AccordionContent className="text-sm text-muted-foreground">{x.a}</AccordionContent>
            </AccordionItem>
          ))}
        </Accordion>
        <p className="mt-6 text-center text-sm text-muted-foreground">
          Остались вопросы? <a href="#contact" className="font-semibold text-brand">Напишите нам</a> — ответим в течение 15 минут.
        </p>
      </div>
    </section>
  );
}

/* ---------- Websites ---------- */
function Websites() {
  return (
    <section id="websites" className="relative overflow-hidden bg-background py-24">
      <div className="mx-auto max-w-7xl px-4">
        <div className="text-center">
          <Pill>разработка сайтов</Pill>
          <h2 className="mt-4 text-4xl font-bold sm:text-5xl">Разработка сайтов <br /><span className="text-gradient">под ваш проект</span></h2>
          <p className="mx-auto mt-4 max-w-2xl text-muted-foreground">Два формата на выбор — никакого навязывания.</p>
        </div>

        <div className="mt-12 grid gap-6 lg:grid-cols-2">
          <div className="rounded-3xl card-soft p-8">
            <div className="flex items-center gap-3">
              <div className="grid size-12 place-items-center rounded-xl bg-gradient-brand text-white"><Globe className="size-5"/></div>
              <span className="rounded-full bg-brand/10 px-3 py-1 text-xs font-semibold text-brand">Формат А</span>
            </div>
            <h3 className="mt-4 text-2xl font-semibold">Ваш шаблон — наша реализация</h3>
            <p className="mt-2 text-muted-foreground">Реализуем ваш дизайн на современных технологиях. Pixel-perfect, точно и с гарантией качества.</p>
            <ul className="mt-5 space-y-2 text-sm">
              <li className="flex gap-2"><Check className="mt-0.5 size-4 text-brand"/> Следуем макету без изменений</li>
              <li className="flex gap-2"><Check className="mt-0.5 size-4 text-brand"/> Программирование, CMS, интеграции под ключ</li>
              <li className="flex gap-2"><Check className="mt-0.5 size-4 text-brand"/> Подключение к Битрикс24 CRM и сквозная аналитика</li>
            </ul>
          </div>
          <div className="rounded-3xl card-soft p-8">
            <div className="flex items-center gap-3">
              <div className="grid size-12 place-items-center rounded-xl bg-gradient-brand text-white"><Sparkles className="size-5"/></div>
              <span className="rounded-full bg-brand/10 px-3 py-1 text-xs font-semibold text-brand">Формат Б</span>
            </div>
            <h3 className="mt-4 text-2xl font-semibold">MVP на базе ИИ — быстрый старт</h3>
            <p className="mt-2 text-muted-foreground">Создаём MVP сайта за дни с помощью ИИ. Проверяйте гипотезы и запускайтесь быстрее.</p>
            <ul className="mt-5 space-y-2 text-sm">
              <li className="flex gap-2"><Check className="mt-0.5 size-4 text-brand"/> 2–3 варианта дизайна на выбор</li>
              <li className="flex gap-2"><Check className="mt-0.5 size-4 text-brand"/> Быстрая разработка и запуск</li>
              <li className="flex gap-2"><Check className="mt-0.5 size-4 text-brand"/> Готов к масштабированию</li>
            </ul>
          </div>
        </div>

        <div className="mt-10 grid gap-4 md:grid-cols-4">
          {[
            { n: "1", t: "Бриф и анализ", d: "Погружаемся в ваш бизнес и цели проекта." },
            { n: "2", t: "Проектирование", d: "Структура, прототипы, дизайн и ТЗ." },
            { n: "3", t: "Разработка", d: "Вёрстка, программирование, интеграции и тесты." },
            { n: "4", t: "Запуск и поддержка", d: "Публикация, аналитика и развитие проекта." },
          ].map((s) => (
            <div key={s.n} className="rounded-2xl card-soft p-5">
              <div className="grid size-9 place-items-center rounded-full bg-gradient-brand text-sm font-bold text-white">{s.n}</div>
              <div className="mt-3 font-semibold">{s.t}</div>
              <div className="mt-1 text-sm text-muted-foreground">{s.d}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ---------- Contact ---------- */
function Contact() {
  const [submitting, setSubmitting] = useState(false);
  const onSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setTimeout(() => {
      setSubmitting(false);
      (e.target as HTMLFormElement).reset();
      toast.success("Заявка отправлена! Перезвоним в течение 15 минут.");
    }, 700);
  };
  return (
    <section id="contact" className="relative overflow-hidden bg-surface-soft py-24">
      <div aria-hidden className="pointer-events-none absolute inset-0">
        <div className="absolute -top-20 left-10 size-[400px] rounded-full bg-brand/15 blur-[160px]"/>
        <div className="absolute bottom-0 right-10 size-[400px] rounded-full bg-brand-2/15 blur-[160px]"/>
      </div>
      <div className="relative mx-auto max-w-7xl px-4">
        <div className="overflow-hidden rounded-3xl card-soft p-8 md:p-12">
          <div className="grid gap-10 lg:grid-cols-2">
            <div>
              <Pill>свяжитесь с нами</Pill>
              <h2 className="mt-4 text-4xl font-bold sm:text-5xl">Обсудим ваш <span className="text-gradient">проект</span></h2>
              <p className="mt-4 text-muted-foreground">Оставьте заявку — подготовим решение и расчёт под ваши задачи. Перезвоним в течение 15 минут.</p>

              <div className="mt-8 space-y-4">
                {[
                  { i: <Phone className="size-5"/>, t: "Телефон", v: "+7 928-705-11-99" },
                  { i: <Mail className="size-5"/>, t: "Email", v: "hello@arwox.ru" },
                  { i: <MapPin className="size-5"/>, t: "Адрес", v: "Краснодар, Рашпилевская 180" },
                ].map((c) => (
                  <div key={c.t} className="flex items-center gap-3">
                    <div className="grid size-11 place-items-center rounded-xl bg-gradient-brand text-white">{c.i}</div>
                    <div>
                      <div className="text-xs text-muted-foreground">{c.t}</div>
                      <div className="font-semibold">{c.v}</div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <form onSubmit={onSubmit} className="space-y-3 rounded-2xl bg-surface-soft border border-border p-6">
              <div className="grid gap-3 sm:grid-cols-2">
                <Input required name="name" placeholder="Ваше имя" className="h-12 rounded-xl" />
                <Input required name="phone" type="tel" placeholder="Телефон" className="h-12 rounded-xl" />
              </div>
              <Input name="email" type="email" placeholder="E-mail" className="h-12 rounded-xl" />
              <Textarea name="message" placeholder="Опишите задачу или цели проекта" rows={4} className="rounded-xl" />
              <Button type="submit" disabled={submitting} className="h-12 w-full rounded-xl bg-gradient-brand text-white hover:opacity-90">
                {submitting ? "Отправляем..." : <>Получить консультацию <Send className="ml-2 size-4"/></>}
              </Button>
              <p className="text-center text-[11px] text-muted-foreground">
                Нажимая кнопку, вы соглашаетесь с политикой обработки данных
              </p>
            </form>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ---------- Footer ---------- */
function Footer() {
  return (
    <footer className="dark-scope border-t border-white/5 py-12">
      <div className="mx-auto max-w-7xl px-4">
        <div className="grid gap-10 md:grid-cols-2 lg:grid-cols-4">
          <div>
            <Logo />
            <p className="mt-4 text-sm text-muted-foreground">Внедряем Битрикс24, автоматизируем бизнес и разрабатываем сайты. Краснодар, работаем по всей России.</p>
          </div>
          <FooterCol title="Услуги" items={["Внедрение Bitrix24", "Тарифы −30%", "BitrixGPT", "Разработка сайтов"]} />
          <FooterCol title="Помощь" items={["FAQ", "Соглашение", "Политика данных"]} />
          <div>
            <div className="mb-3 text-sm font-semibold">Контакты</div>
            <div className="space-y-2 text-sm text-muted-foreground">
              <div className="flex items-center gap-2"><Phone className="size-4"/> +7 928-705-11-99</div>
              <div className="flex items-center gap-2"><Mail className="size-4"/> hello@arwox.ru</div>
              <div className="flex items-center gap-2"><MapPin className="size-4"/> Краснодар, Рашпилевская 180</div>
            </div>
          </div>
        </div>
        <div className="mt-10 flex flex-col items-center justify-between gap-3 border-t border-white/10 pt-6 text-xs text-muted-foreground md:flex-row">
          <span>© 2025 ARWOX. Официальный партнёр Битрикс24.</span>
          <span>Made with <span className="text-brand-2">♥</span> for your growth</span>
        </div>
      </div>
    </footer>
  );
}
function FooterCol({ title, items }: { title: string; items: string[] }) {
  return (
    <div>
      <div className="mb-3 text-sm font-semibold">{title}</div>
      <ul className="space-y-2 text-sm text-muted-foreground">
        {items.map((i) => <li key={i}><a href="#" className="hover:text-foreground">{i}</a></li>)}
      </ul>
    </div>
  );
}

/* ---------- Landing ---------- */
function Landing() {
  return (
    <main className="bg-background text-foreground">
      <Header />
      <Hero />
      <Results />
      <SanatoriumCase />
      <WhyUs />
      <Integrations />
      <BitrixGPT />
      <Tariffs />
      <FAQ />
      <Websites />
      <Contact />
      <Footer />
    </main>
  );
}
