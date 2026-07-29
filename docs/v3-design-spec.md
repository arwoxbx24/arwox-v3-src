# ARWOX Landing V3 — Design Specification

> Версия: 3.0 | Дата: 2026-07-02
> Автор: Design Architect (Claude Sonnet)
> Статус: КАНОНИЧЕСКИЙ документ для всех билдеров

---

## Общие принципы

- **Фон по умолчанию**: `bg-background` (#F6FAFF) — ни в коем случае не чёрный
- **Тёмные секции**: только `dark-scope` (тёмно-синий #061A3D/#082A5A) — Integrations, BitrixGPT, Footer
- **Адрес**: строго в Contact + Footer, нигде больше
- **Один главный CTA**: первый экран → «Получить консультацию» (якорь #contact)
- **Адаптив**: 360 / 768 / 1024 / 1368 / 1440+
- **Анимации**: scroll-reveal через `<Reveal>` атом (IntersectionObserver, нет внешних deps)
- **Hover у карточек**: translateY(-4px) + усиление тени (transition 200ms ease)
- **Focus**: outline 2px brand, offset 2px — у всех интерактивных элементов
- **Иконки**: только SVG из `/assets/icons/*.svg` через атом `<Icon name="..." />`
- **Изображения**: `/assets/images/*.png` через `<img>` с alt-атрибутами
- **Текст**: 1:1 из `landing_text_content.md`

---

## Порядок секций

```
01  Header          — fixed, glass, light
02  Hero            — bg-hero, CRM Dashboard справа
03  CompetenceRibbon — ниже Hero, glass-панель 4 бейджа
04  Results         — bg-surface-soft, 3 сценария + 3 краткие карточки результата
05  CaseStudy       — bg-background, sanatorium кейс
06  WhyUs           — bg-surface-soft, 4 карточки причин
07  Process         — bg-background, 6 шагов с timeline-линией
08  Integrations    — dark-scope, орбитальная сетка иконок
09  BitrixGPT       — dark-scope (dark-blue-2), AI фичи + 4 GPT-тарифа
10  Tariffs         — bg-background, 4 карточки + виджет-блок
11  FAQ             — bg-surface-soft, 6 аккордеон-вопросов
12  Websites        — bg-background, 2 формата + 4 шага
13  Contact         — bg-surface-soft, контакты + форма
14  Footer          — dark-scope
```

---

## Секция 01 — Header

**Файл**: `src/components/landing/Header.tsx`

### Layout
- `position: fixed; inset-x: 0; top: 1rem; z-index: 50`
- Внутри: `mx-auto max-w-7xl px-4`
- Контейнер: `glass rounded-[28px] px-5 py-3` (backdrop-blur-12, border 1px border/20)

### Состав (flex row, space-between)
- **Слева**: `<Logo />` (атом)
- **Центр** (hidden на < 1024px): nav links с `gap-7 text-sm`
  - Тарифы −30% → `#tariffs`
  - Внедрение → `#results`
  - BitrixGPT → `#bitrixgpt`
  - Вопросы → `#faq`
  - Разработка сайтов → `#websites`
- **Справа**: телефон (скрыт на < 768px) + Button CTA «Оставить заявку» → `#contact`

### Мобильный (< 1024px)
- Гамбургер-кнопка (lucide `Menu`) → drawer или dropdown меню
- Телефон показывается в drawer

### Hover/Focus
- Nav ссылки: `hover:text-foreground transition-colors`
- CTA кнопка: `hover:opacity-90 focus-visible:ring-2 focus-visible:ring-brand`

---

## Секция 02 — Hero

**Файл**: `src/components/landing/Hero.tsx`

### Background
```css
background: var(--gradient-hero);
/* = radial(85% 45%, brand/18) + radial(15% 35%, cyan/16) + linear(F8FBFF→EEF7FF→E7F4FF) */
```
Дополнительные декоративные пятна (aria-hidden):
- `absolute top-[-120px] right-[-80px] size-[600px] rounded-full bg-brand/8 blur-[160px]`
- `absolute bottom-[-80px] left-[-60px] size-[400px] rounded-full bg-brand-2/10 blur-[140px]`

### Layout
- `pt-[140px] pb-20` (компенсация fixed header ~80px + 60px пространство)
- `max-w-7xl mx-auto px-4`
- Grid: `grid-cols-1 gap-12 lg:grid-cols-[1fr_1.1fr] items-center`

### Левая колонка
1. **Бейдж**: `<Pill>Бизнес-партнёр Битрикс24 · г. Краснодар</Pill>` (light variant)
2. **H1** (Space Grotesk, 800):
   - 360px: `text-[40px] leading-[1.08]`
   - 768px: `text-[52px]`
   - 1024px: `text-[64px]`
   - 1440px: `text-[76px] leading-[1.04]`
   - «Внедрим» — обычный текст, «Битрикс24» — `<span class="text-gradient">`, «от анализа до результата» — обычный
3. **Paragraph** (Inter 400): `mt-6 max-w-[520px] text-[15px] sm:text-[17px] text-muted-foreground leading-[1.6]`
   - «14 дней» выделить `font-semibold text-foreground`
4. **CTA блок** `mt-8 flex flex-wrap gap-3`:
   - Primary: `<Button size="lg">` с `bg-gradient-brand rounded-2xl h-14 px-7 text-white` + иконка `<Icon name="rocket" className="mr-2 size-5" />`
     → текст «Получить консультацию»
   - Secondary: outline `rounded-2xl h-14 border-border bg-white text-foreground hover:bg-surface-soft`
     → иконка lucide `PlayCircle` + «Смотреть кейсы»
5. **Контакты** `mt-8 flex flex-wrap gap-6 text-sm text-muted-foreground`:
   - `<Icon name="telephony" />` + +7 928-705-11-99 (tel: link)
   - `<Icon name="email" />` + hello@arwox.ru (mailto: link)

### Правая колонка — CRM Dashboard

**Компонент**: `DashboardMock` (внутри Hero.tsx или отдельный файл)

**Оболочка** `rounded-[32px] shadow-[0_28px_80px_rgba(0,92,180,0.22)]`:
```css
background: linear-gradient(180deg, #082A5A 0%, #061A3D 100%);
padding: 12px;
```

**Внутри** `dark-scope rounded-2xl p-5`:

1. **Title bar**: три кружка macOS (red/yellow/green) + «Битрикс24 · CRM Dashboard» + Live badge (emerald пульс)

2. **KPI row** — 4 карточки `grid-cols-2 md:grid-cols-4 gap-2`:
   - Лидов 124 ↑18% | Сделок 38 ↑12% | Конверсия 31% ↑с14% | Выручка ₽3.2М ↑8%
   - **Animated counters**: при `Reveal` → `useEffect` запускает инкремент числа от 0 до целевого значения за 1200ms (easeOut)
   - Карточки: `bg-white/[0.05] rounded-xl p-3`
   - Значение: `text-2xl font-bold`; дельта: `text-[11px] text-emerald-300`

3. **Воронка продаж** `mt-4 rounded-xl bg-white/[0.05] p-4`:
   - Header: «ВОРОНКА ПРОДАЖ» + «124 → 38 сделок» (brand-2)
   - 4 бара: Новые(124)→100%, Переговоры(52)→42%, Счёт(44)→35%, Закрыты(38)→31%
   - Каждый бар: `h-2 flex-1 overflow-hidden rounded-full bg-white/10` + fill `bg-gradient-brand`
   - Анимация: при enter viewport ширина заполняется с 0 до целевой за 800ms (CSS transition, delay cascading)

4. **Нижние 2 панели** `grid-cols-1 md:grid-cols-2 gap-3 mt-4`:
   - **Конверсия по месяцам**: бар-чарт 8 столбцов, +122% за год
     - Столбцы `flex-1 rounded-t bg-gradient-brand` с высотой от 18% до 100%
     - Анимация роста при enter viewport
   - **Задачи команды**: donut chart через CSS `conic-gradient` + легенда
     - Выполнено 72% (brand), В работе 18% (brand-2), Просрочено 10% (rose)

5. **Активность сегодня** `mt-4 rounded-xl bg-white/[0.05] p-4`:
   - 2 строки с аватаром-градиент + текст + время + статус-бейдж

### 360px адаптив
- Правая колонка (Dashboard) спускается ПОД левую
- Dashboard: `max-w-[360px] mx-auto` на мобильном, overflow-x: auto если нужно

---

## Секция 03 — CompetenceRibbon

**Файл**: `src/components/landing/CompetenceRibbon.tsx`

### Layout
Сразу под Hero, внутри той же секции Hero или отдельным блоком `mt-16`:
- `<Reveal>` обёртка
- `max-w-7xl mx-auto px-4`
- Контейнер: `glass rounded-[24px] p-3`
- `grid grid-cols-2 md:grid-cols-4 gap-2`

### 4 карточки
```
icon           label-small              title
bitrix_cloud   БИЗНЕС-ПАРТНЁР           Битрикс24
crm_users      CRM                      Внедрение и настройка
telephony      ТЕЛЕФОНИЯ                Коммуникации
robot          АВТОМАТИЗАЦИЯ            Роботы и BitrixGPT
```

**Карточка структура**:
- `flex items-center gap-3 rounded-xl bg-surface-soft px-4 py-3`
- `hover:bg-white transition-colors duration-200`
- Иконка: `<div class="grid size-10 place-items-center rounded-lg" style="background: linear-gradient(135deg, #00B7FF 0%, #006DFF 55%, #8B5CF6 100%)">`
  → `<Icon name="..." className="size-5 invert brightness-0 saturate-0" />`
  (SVG белым цветом через CSS filter)
- Label small: `text-[10px] font-semibold tracking-[0.18em] uppercase text-muted-foreground`
- Title: `text-sm font-semibold text-foreground`

---

## Секция 04 — Results (Что меняется после внедрения Битрикс24)

**Файл**: `src/components/landing/Results.tsx`

### Layout
- `bg-surface-soft py-24`
- Центрированный заголовок: `<SectionTitle eyebrow="Результат" title="Что меняется после\nвнедрения Битрикс24" titleGradient="Битрикс24" />`
- Подзаголовок: «Три сценария из практики...»

### 3 кратких карточки результата (ROW-FIRST)
Перед сценариями — `grid grid-cols-1 sm:grid-cols-3 gap-4 mt-10`:
```
card_result_growth.png  → +47% рост продаж (из mockup)   — Icon: chart_up
card_result_time.png    → −32% время обработки             — Icon: clock
card_result_data.png    → +28% данные в CRM               — Icon: pie
```
Карточка: `card-soft rounded-2xl p-5 flex items-center gap-4 hover:-translate-y-1 transition-transform duration-200`
- Иконка `size-12` с `bg-gradient-brand rounded-xl`
- Значение `text-3xl font-bold text-gradient`
- Описание `text-sm text-muted-foreground`

> Используем `<img src="/assets/images/card_result_*.png">` как декоративный акцент ИЛИ
> делаем pure-text карточку с icon — без изображений (text beats image rule). Текст приоритет.

### 3 детальных сценария
`mt-12 grid gap-6 lg:grid-cols-3`
Каждый сценарий — `<Reveal delay={index * 100}>`:

**Сценарий-карточка** `card-soft rounded-2xl p-6 flex flex-col`:
1. Header: icon (`funnel`/`channels`/`document`) + тег «Сценарий N»
2. Проблема (красный заголовок `text-rose-600 font-semibold text-sm`) + title + story
3. Замер ДО: `bg-surface-soft rounded-xl p-3` — big value + label
4. Что сделали: numbered list 1-3 с gradient-circles
5. Итог: `border border-brand/20 bg-gradient-to-br from-brand/[0.06] to-brand-2/[0.06] rounded-xl p-4`
   - Метрики: `text-gradient text-2xl font-bold`
6. Дисклеймер `text-[10px] text-muted-foreground`

**Иконки по сценариям**:
- С1 (воронка): `funnel.svg`
- С2 (каналы): `channels.svg`
- С3 (контроль): `document.svg`

---

## Секция 05 — CaseStudy (Санаторно-курортный комплекс)

**Файл**: `src/components/landing/CaseStudy.tsx`

### Layout
- `bg-background py-24`
- `<Reveal>` на всю секцию

**Карточка** `overflow-hidden rounded-[32px] card-soft`:

1. **Header** `p-8 md:p-10`:
   - `<Pill>Кейс клиента</Pill>` + «Санаторно-курортный комплекс» справа (иконка `shield.svg`)
   - H3 `text-3xl md:text-4xl font-bold`: «Заявки терялись, менеджеры работали в нескольких окнах»
   - Meta: «Отрасль: санаторно-курортный комплекс · Bitrix24 Коробка · 50 пользователей»

2. **Body** `grid md:grid-cols-[1.1fr_1.4fr] gap-6 px-8 pb-8 md:px-10 md:pb-10`:

   **Левая**: Изображение `/assets/images/sanatorium.jpg`
   - `relative overflow-hidden rounded-2xl`
   - Оверлей снизу `bg-gradient-to-t from-black/70 to-transparent p-4`:
     - 2 бейджа: «30 дней» срок, «50 человек» команда
     - `bg-white/15 backdrop-blur rounded-xl px-3 py-2 text-white`

   **Правая** `grid md:grid-cols-3 gap-6`:
   - Задача (иконка `shield.svg`) | Решение (иконка `document.svg`) | Результаты (иконка `chart_up.svg`)
   - Результаты: `text-gradient text-2xl font-bold` для «1 окно», «real-time», «×0»

3. **Цитата** `border-t border-border bg-surface-soft px-8 py-5 md:px-10`:
   - Аватар АК (`bg-gradient-brand size-9 rounded-full text-white text-xs font-bold`)
   - Андрей К. + цитата

### Улучшение V3
- Добавить `card_client_case_full.png` как фоновый декоративный акцент (opacity 0.03) в карточке
- Или использовать как отдельный превью-образ справа от цитаты

---

## Секция 06 — WhyUs (Почему ARWOX)

**Файл**: `src/components/landing/WhyUs.tsx`

### Layout
- `bg-surface-soft py-24`
- Заголовок: `<SectionTitle eyebrow="Наши преимущества" title="Почему ARWOX" titleGradient="ARWOX" />`
- `grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5 mt-12`

### 4 карточки с `<Reveal delay={i*80}>`
```
icon       title                          description
funnel     Глубокий предпроектный анализ  Изучаем воронку продаж...
shield     Комплексный аудит перед стартом Оцениваем текущие инструменты...
crm_users  Настройка под вашу воронку     Не даём «типовую» конфигурацию...
rocket     Обучение команды и поддержка   Обучение для менеджеров...
```

**Карточка** `card-soft rounded-2xl p-6 hover:-translate-y-1 transition-all duration-200 hover:shadow-[0_18px_55px_rgba(0,75,160,0.14)]`:
- Icon container: `size-12 rounded-xl` с gradient competence (00B7FF → 006DFF → 8B5CF6)
- Использовать `<img src="/assets/images/card_why_N.png">` как фоновую текстуру 5% opacity ИЛИ pure-text

### Улучшение V3
- В правом нижнем углу карточки: декоративная линия-акцент `absolute bottom-4 right-4 size-16 opacity-5 rounded-full bg-gradient-brand`

---

## Секция 07 — Process (Как мы внедряем Bitrix24)

**Файл**: `src/components/landing/Process.tsx`

### Layout
- `bg-background py-24`
- `<SectionTitle eyebrow="этапы работы" title="Как мы внедряем Bitrix24" />`
- Subtext: «Гибкий подход с экспертизой — от первого разбора задачи до подписания актов.»

### Timeline (КЛЮЧЕВОЕ УЛУЧШЕНИЕ V3)

**Desktop (≥ 1024px)**: Горизонтальный timeline в 2 ряда по 3 шага:
```
[01] ——— [02] ——— [03]
         |
[06] ——— [05] ——— [04]
```
Реализация:
- `grid grid-cols-3 gap-0 relative` для каждого ряда
- Соединительная линия: `absolute top-[28px] left-[calc(50%+28px)] right-0 h-[2px] bg-gradient-to-r from-brand/60 to-brand-2/40`
- Между рядами: вертикальная линия в правой колонке
- Линии — CSS pseudo-elements или абсолютные div-ы с `z-0`

**Tablet (768-1023px)**: 2 колонки × 3 строки, горизонтальная линия в каждой строке

**Mobile (< 768px)**: 1 колонка, вертикальный timeline (линия слева)

### Карточка шага `<Reveal delay={i*100}>`
- `relative z-10 flex flex-col items-center text-center p-4` (desktop)
- Кружок с номером: `size-14 rounded-full bg-gradient-brand text-white text-lg font-bold grid place-items-center shadow-[0_8px_24px_rgba(0,109,255,0.25)]`
- Иконка шага под кружком (PNG из `/assets/images/process_step_N.png` как декор 60% opacity height-20 object-contain)
- Title `font-semibold mt-3`
- Description `text-sm text-muted-foreground mt-1 max-w-[180px]`

### 6 шагов
```
01 Диагностика           Icon: funnel
02 Разработка ТЗ         Icon: document
03 Запуск и демонстрация Icon: rocket
04 Сдача проекта         Icon: shield
05 Обучение              Icon: crm_users
06 Подписание актов      Icon: lock
```

---

## Секция 08 — Integrations (dark)

**Файл**: `src/components/landing/Integrations.tsx`

### Layout
- `dark-scope relative py-24 overflow-hidden`
- Background: `linear-gradient(135deg, #061A3D 0%, #082A5A 55%, #0A3470 100%)` + radial glows
- Декор: орбитальные кольца (aria-hidden)

### Орбитальный декор (КЛЮЧЕВОЕ УЛУЧШЕНИЕ V3)
```html
<div aria-hidden class="absolute right-0 top-1/2 -translate-y-1/2 w-[500px] h-[500px] opacity-20">
  <!-- SVG орбиты — концентрические круги с точками -->
  <svg viewBox="0 0 500 500" fill="none">
    <circle cx="250" cy="250" r="120" stroke="#00B7FF" stroke-width="1" stroke-dasharray="4 8"/>
    <circle cx="250" cy="250" r="190" stroke="#006DFF" stroke-width="1" stroke-dasharray="4 12"/>
    <circle cx="250" cy="250" r="240" stroke="#8B5CF6" stroke-width="1" stroke-dasharray="2 16"/>
  </svg>
</div>
```

### Двухколоночный layout
`grid gap-10 lg:grid-cols-[1fr_1.6fr] items-center`

**Левая**: текст
- `<Pill variant="dark">интеграции</Pill>`
- H2: «Интеграции» + `<span class="text-gradient">без границ</span>`
- Paragraph
- Список из 3 пунктов в `glass rounded-2xl p-5`
  - `<Icon name="api" />` Готовые коннекторы и гибкие API
  - ✓ Webhook, скрипты и кастомные решения
  - ✓ Быстрая синхронизация и надёжность

**Правая**: сетка иконок интеграций

**Ряд 1** (6 иконок с горизонтальной connector-линией):
```
1С | telephony | email | whatsapp | telegram | api
```
**Ряд 2** (5 иконок):
```
website | chart_up | funnel | crm_users | robot
```

**Иконка-ячейка** `flex flex-col items-center gap-2`:
- `size-14 rounded-2xl glass border border-white/10 grid place-items-center hover:border-brand-2/40 hover:scale-105 transition-all duration-200`
- `<Icon name="..." className="size-6 opacity-80" />`
- Label `text-[11px] text-muted-foreground text-center`

**Connector line** между рядами: `absolute inset-x-8 top-7 h-px bg-gradient-to-r from-transparent via-brand-2/40 to-transparent`

### Иконки → integration labels
```
telephony  → Телефония
email      → E-mail
whatsapp   → WhatsApp
telegram   → Telegram
api        → API · Webhook
website    → Сайты и формы
chart_up   → Аналитика
funnel     → CRM-воронки
crm_users  → Пользователи
robot      → ИИ-боты
```
(1С рендерится как текстовая надпись `text-sm font-bold text-white`)

---

## Секция 09 — BitrixGPT (dark)

**Файл**: `src/components/landing/BitrixGPT.tsx`

### Layout
- `dark-scope relative overflow-hidden py-24`
- Background: `var(--dark-blue-2)` = #082A5A
- Glow: `absolute top-10 right-10 size-[480px] rounded-full bg-brand/25 blur-[160px] pointer-events-none`

### Главная карточка `overflow-hidden rounded-[32px] glass p-8 md:p-12`

**Top row** `grid items-center gap-10 lg:grid-cols-[1.2fr_1fr]`:
- Левая: `<Pill variant="dark">ИИ и автоматизация</Pill>` + H2 + paragraph + Button «Открыть маркетплейс»
- Правая: AI chip image `/assets/images/ai-chip.png` с glow background
  `relative grid place-items-center`
  - `absolute inset-0 m-auto size-72 rounded-full bg-brand/30 blur-3xl`
  - `<img src="/assets/images/ai-chip.png" class="relative w-72 drop-shadow-2xl" />`

**6 feature cards** `mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3`:
Каждая: `rounded-2xl bg-white/[0.05] border border-white/10 p-5 hover:bg-white/[0.08] hover:border-brand-2/30 transition-all duration-200`
```
Icon (lucide)     Title                          Description
MessageSquare     Автоматические ответы          ИИ отвечает в чатах...
Mic               Расшифровка звонков            Транскрипция и анализ...
Calendar          Follow-up и встречи            ИИ ставит задачи...
Users             Помощь менеджерам              Рекомендации, подсказки...
Plug              Внешние AI и MCP-интеграции    ChatGPT, Claude, Mistral...
Bot               BitrixGPT в ленте и задачах    Формулирует тексты...
```
Icon container: `size-11 rounded-xl bg-gradient-brand text-white grid place-items-center`

**Marketplace strip** `mt-8 flex items-center justify-between gap-4 rounded-2xl bg-white/[0.05] border border-white/10 p-5`:
- `<Icon name="ai_spark" />` + «Маркетплейс Битрикс24» + «5000+ готовых приложений»
- Button «Открыть маркетплейс →»

### 4 GPT-тарифа `mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-4`
```
Базовый       5 польз. · 24 ГБ    500 ₽   (было 1 000 ₽) −50%
Стандартный   50 польз. · 100 ГБ  1 500 ₽ (было 3 000 ₽) −50% [POPULAR]
Профессиональный 100 польз. · 1 ТБ 3 000 ₽ (было 6 000 ₽) −50%
Энтерпрайз    250+ польз. · 3 ТБ  6 800 ₽ (было 13 600 ₽) −50%
```
Карточка: `relative glass rounded-2xl p-6`
- Popular badge: `absolute -top-3 left-1/2 -translate-x-1/2 rounded-full bg-gradient-brand px-3 py-1 text-[10px] text-white`
- Popular ring: `ring-1 ring-brand/60 shadow-glow`
- Цена: `text-3xl font-bold` + старая цена `line-through text-sm text-muted-foreground`

Дисклеймер: `mt-3 text-center text-xs text-muted-foreground`

---

## Секция 10 — Tariffs (Тарифы Битрикс24)

**Файл**: `src/components/landing/Tariffs.tsx`

### Layout
- `bg-background py-24`
- `<SectionTitle eyebrow="Выгодные условия" title="Тарифы и лицензии Битрикс24" titleGradient="Битрикс24" />`
- Sub: «Скидка **30%** на облачные тарифы через официального партнёра ARWOX»

### 4 карточки `mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-4`
```
Базовый        Для небольших команд и старта в CRM       1 190 ₽ (1 700)  12 ГБ, 5 польз
Расширенный    Для растущего бизнеса                     2 790 ₽ (3 990)  24 ГБ, 50 польз
Профессиональный Для автоматизации бизнес-процессов      5 590 ₽ (7 990)  100 ГБ, неогр [POP]
Энтерпрайз     Для крупных компаний и корпораций         11 890 ₽ (16 990) 1024 ГБ, неогр
```

**Карточка** `relative card-soft rounded-2xl p-6 hover:-translate-y-1 transition-all duration-200`:
- Popular: `ring-1 ring-brand/30`
- Название `text-lg font-semibold`
- Описание `text-xs text-muted-foreground`
- Цена: `text-3xl font-bold mt-5` + `line-through`
- `/мес` `text-xs text-muted-foreground`
- Фичи: `<Check>` + текст

### Виджет-блок `mt-8 rounded-2xl border border-dashed border-border bg-surface-soft p-6 text-center`
- Заголовок «Официальный виджет тарифов Битрикс24»
- Описание
- 2 кнопки: «Получить скидку 30%» (primary) + «Попробовать бесплатно» (outline)

---

## Секция 11 — FAQ

**Файл**: `src/components/landing/FAQ.tsx`

### Layout
- `bg-surface-soft py-24`
- `max-w-5xl mx-auto px-4`
- `<SectionTitle eyebrow="вопросы и ответы" title="Часто задаваемые вопросы" />`

### Accordion `mt-10 space-y-3`
6 вопросов из текста — `shadcn/ui Accordion`:
- Item: `card-soft rounded-2xl px-5`
- Trigger: `text-left text-base font-medium hover:no-underline`
- Content: `text-sm text-muted-foreground pb-4`

Вопросы:
1. Чем Битрикс24 отличается от AmoCRM, Salesforce и других?
2. Что входит в бесплатный тариф?
3. Сколько времени занимает внедрение?
4. Облако или коробка — что выбрать?
5. Можно ли интегрировать с 1С?
6. Что такое маркетплейс Битрикс24 и 5000+ приложений?

Footer FAQ: «Остались вопросы? [Напишите нам](#contact) — ответим в течение 15 минут.»

---

## Секция 12 — Websites (Разработка сайтов)

**Файл**: `src/components/landing/Websites.tsx`

### Layout
- `bg-background py-24 relative overflow-hidden`
- `<SectionTitle eyebrow="разработка сайтов" title="Разработка сайтов" titleGradient="под ваш проект" />`
- Sub: «Два формата на выбор — никакого навязывания.»

### 2 формата `mt-12 grid gap-6 lg:grid-cols-2`

**Формат А — Классический сайт** `rounded-[28px] card-soft p-8`:
- Иконка: `<Icon name="website" size-12 gradient-brand-icon>`
- Бейдж «Формат А» (brand/10 bg)
- H3: «Ваш шаблон — наша реализация»
- Description
- 3 пункта с Check + текст
- Декоративный акцент: `/assets/images/card_site_classic.png` как фоновое изображение `absolute bottom-0 right-0 w-48 opacity-[0.07] object-contain`
- Срок «от 20 дней» — `text-sm text-muted-foreground mt-5 flex items-center gap-2` + `<Icon name="clock" size-4>`

**Формат Б — MVP на базе ИИ** `rounded-[28px] card-soft p-8`:
- Иконка: `<Icon name="ai_spark" size-12 gradient-brand-icon>`
- Бейдж «Формат Б»
- H3: «MVP на базе ИИ — быстрый старт»
- Декоративный акцент: `/assets/images/card_site_mvp_ai.png`
- Срок «от 7 дней»

### 4 шага разработки `mt-10 grid gap-4 md:grid-cols-4`
```
1 Бриф и анализ      Icon: document   Погружаемся в ваш бизнес...
2 Проектирование      Icon: funnel     Структура, прототипы, дизайн...
3 Разработка          Icon: robot      Вёрстка, программирование...
4 Запуск и поддержка  Icon: rocket     Публикация, аналитика...
```
Шаг: `card-soft rounded-2xl p-5 hover:-translate-y-1 transition-transform duration-200`
- Кружок `size-9 bg-gradient-brand rounded-full text-white text-sm font-bold grid place-items-center`
- Горизонтальный коннектор между шагами (desktop): CSS стрелка-линия

---

## Секция 13 — Contact

**Файл**: `src/components/landing/Contact.tsx`

### Layout
- `bg-surface-soft py-24 relative overflow-hidden`
- Glow decorators: brand/15 и brand-2/15 blurs

**Карточка** `overflow-hidden rounded-[32px] card-soft p-8 md:p-12 max-w-7xl mx-auto`:
`grid gap-10 lg:grid-cols-2`

**Левая**:
- `<Pill>свяжитесь с нами</Pill>`
- H2: «Обсудим ваш» + `<span class="text-gradient">проект</span>`
- Paragraph
- Контакты-иконки × 3:
  - `<Icon name="telephony">` +7 928-705-11-99
  - `<Icon name="email">` hello@arwox.ru
  - `<Icon name="lock">` Краснодар, Рашпилевская 180 (иконка lock не идеальна, но используем что есть — или lucide MapPin)

**Правая — форма** `space-y-3 rounded-2xl bg-surface-soft border border-border p-6`:
- `grid grid-cols-2 gap-3`: Имя | Телефон
- Email (full width)
- Textarea «Опишите задачу»
- Button primary «Получить консультацию» full width
- Дисклеймер `text-[11px] text-center text-muted-foreground`

**UX**: onSubmit → state loading → toast success (без внешней отправки, заглушка)

---

## Секция 14 — Footer (dark)

**Файл**: `src/components/landing/Footer.tsx`

### Layout
- `dark-scope border-t border-white/5 py-12`

**Grid** `grid gap-10 md:grid-cols-2 lg:grid-cols-4`:
1. **Бренд**: `<Logo variant="dark" />` + description + social icons (telegram icon из /assets/icons/)
2. **Услуги**: Внедрение Bitrix24 / Тарифы −30% / BitrixGPT / Разработка сайтов
3. **Помощь**: FAQ / Соглашение / Политика данных
4. **Контакты**: телефон + email + адрес

**Bottom bar** `border-t border-white/10 pt-6 mt-10 flex justify-between text-xs text-muted-foreground`:
- «© 2025 ARWOX. Официальный партнёр Битрикс24.»
- «Made with ♥ for your growth»

---

## Анимации и UX

### Scroll-Reveal
Все секции/карточки оборачиваются `<Reveal>`:
```tsx
<Reveal delay={0}>   // секция в целом
<Reveal delay={100}> // карточки с каскадом
```
CSS класс `.reveal-hidden` → `.reveal-visible` через IntersectionObserver.
Transition: `opacity 0 → 1, translateY(24px → 0)` за 500ms cubic-bezier(0.16, 1, 0.3, 1)

### Hover-подъёмы карточек
Все `card-soft` карточки: `hover:-translate-y-1 transition-all duration-200`
Добавить усиленную тень: `hover:shadow-[0_18px_55px_rgba(0,75,160,0.14)]`

### Animated Counters (CRM Dashboard)
- При первом появлении в viewport запускается JS-счётчик 0 → target за 1200ms easeOutQuart
- Только для числовых KPI в Dashboard
- Реализация в `DashboardMock` через `useState` + `useEffect` + `requestAnimationFrame`

### Bar/Funnel анимации (CRM Dashboard)
- При enter viewport: CSS width от 0 до target с `transition-[width] duration-800ms ease-out`
- `delay-100, delay-200, delay-300` на каждый бар воронки

---

## Брейкпоинты — сводная таблица

| Секция        | 360px              | 768px            | 1024px           | 1440px+          |
|---------------|--------------------|------------------|------------------|------------------|
| Hero          | stack, text-[40px] | text-[52px]      | 2-col, text-[64px] | text-[76px]    |
| Dashboard     | max-w-[340px]      | full, 2-col kpi  | full             | full             |
| Competence    | 2×2 grid           | 4-col            | 4-col            | 4-col            |
| Results       | 1-col              | 1-col            | 3-col            | 3-col            |
| CaseStudy     | stack              | 2-col            | 2-col            | 2-col            |
| WhyUs         | 1-col              | 2×2              | 4-col            | 4-col            |
| Process       | vertical timeline  | 2-col            | 3+3 horizontal   | 3+3 horizontal   |
| Integrations  | stack + scroll-x   | 2-col            | 2-col            | 2-col            |
| BitrixGPT     | stack              | 2-col features   | 2-col header     | 2-col header     |
| Tariffs       | 1-col              | 2×2              | 4-col            | 4-col            |
| FAQ           | full               | max-w-5xl        | max-w-5xl        | max-w-5xl        |
| Websites      | stack              | 2-col formats    | 2-col            | 2-col            |
| Contact       | stack              | stack            | 2-col            | 2-col            |
| Footer        | stack              | 2-col            | 4-col            | 4-col            |

---

## Улучшения V3 vs V2

| Область             | V2                              | V3                                              |
|---------------------|---------------------------------|-------------------------------------------------|
| Hero Dashboard      | Статичный, simple               | Animated counters + bar animations              |
| CompetenceRibbon    | Встроен в Hero, lucide icons    | Отдельный блок, реальные SVG из /assets/icons/  |
| Process             | Простой grid без коннекторов    | Timeline с connecting lines                      |
| Integrations        | 2 ряда иконок                   | Орбитальный SVG декор + hover effects на иконках |
| WhyUs               | 4 базовых карточки              | Hover lift + декоративный gradient accent        |
| Scroll-Reveal       | Отсутствует                     | IntersectionObserver на всех секциях             |
| Icon system         | lucide-react inline             | Унифицированный `<Icon>` атом из /assets/icons/  |
| CSS Structure       | Inline styles                   | Все через Tailwind + CSS custom utilities        |
