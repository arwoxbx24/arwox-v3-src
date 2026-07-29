# ARWOX Landing — технический промт, цвета, градиенты, UI-правила

## Базовая концепция
Развивать утверждённый светлый вариант ARWOX: светлый SaaS/Bitrix-style, бело-голубая основа, лазурные и синие градиенты, умеренные салатовые акценты, мягкие glass-card блоки, аккуратные тени. Не уходить в чёрный hero. Тёмные секции использовать только для AI/интеграций и футера; фон там тёмно-синий, не чёрный.

## Главная композиция
1. Шапка: светлая glass-панель, логотип ARWOX слева, навигация, телефон, CTA справа.
2. Hero: слева оффер «Внедрим Битрикс24 от анализа до результата», справа крупный CRM Dashboard.
3. Бейджи компетенций: четыре крупные карточки в едином стиле: Битрикс24 бизнес-партнёр, CRM и интеграции с 1С, телефония и коммуникации, компетенция внедрение и интеграция.
4. Блок «Что меняется после внедрения»: не дублировать заголовок два раза. Комбинировать так: сначала 3 короткие карточки результата, ниже — 3 детальных сценария.
5. Далее: кейс клиента, преимущества, процесс внедрения, интеграции, BitrixGPT, тарифы, FAQ, разработка сайтов, CTA-форма, футер.

## Цветовые токены
- --color-bg: #F6FAFF;
- --color-surface: #FFFFFF;
- --color-surface-soft: #EEF6FF;
- --color-text: #071A3F;
- --color-text-muted: #4B638A;
- --color-primary: #006DFF;
- --color-primary-dark: #0059D6;
- --color-cyan: #00B7FF;
- --color-azure: #2BCBFF;
- --color-violet: #8B5CF6;
- --color-lime: #84CC16;
- --color-green: #22C55E;
- --color-border: #D9E8FF;
- --color-dark-blue: #061A3D;
- --color-dark-blue-2: #082A5A;

## Градиенты
Hero background:
linear-gradient(135deg, #F8FBFF 0%, #EEF7FF 42%, #E7F4FF 100%)
+ radial-gradient(circle at 85% 45%, rgba(0, 109, 255, 0.18), transparent 36%)
+ radial-gradient(circle at 15% 35%, rgba(43, 203, 255, 0.16), transparent 32%)

Primary CTA:
linear-gradient(135deg, #006DFF 0%, #1677FF 52%, #8B5CF6 100%)

Text gradient for Bitrix24:
linear-gradient(90deg, #006DFF 0%, #00B7FF 48%, #8B5CF6 100%)

Competence icon gradient:
linear-gradient(135deg, #00B7FF 0%, #006DFF 55%, #8B5CF6 100%)

Green CRM accent:
linear-gradient(135deg, #22C55E 0%, #84CC16 60%, #2BCBFF 100%)

Dark AI / Integration section:
linear-gradient(135deg, #061A3D 0%, #082A5A 55%, #0A3470 100%)
+ radial-gradient(circle at 75% 30%, rgba(43,203,255,0.24), transparent 35%)
+ radial-gradient(circle at 20% 70%, rgba(139,92,246,0.20), transparent 30%)

Footer:
linear-gradient(135deg, #061A3D 0%, #082A5A 100%)

## Радиусы и тени
- Header radius: 26–34px.
- Large cards radius: 28–34px.
- Medium cards radius: 20–24px.
- Icon cards radius: 16–20px.
- Light card shadow: 0 18px 55px rgba(0, 75, 160, 0.10).
- Dashboard shadow: 0 28px 80px rgba(0, 92, 180, 0.20).
- CTA shadow: 0 18px 36px rgba(0, 109, 255, 0.24).

## Типографика
- Font: Inter / Manrope / SF Pro Display.
- H1 desktop: 64–76px, weight 800–900, line-height 1.05.
- H2 desktop: 40–52px, weight 800.
- Card title: 18–24px, weight 700.
- Body: 15–18px, line-height 1.5–1.65.
- Small labels: 11–13px, uppercase, letter spacing 0.08em.

## UX и ограничения
- Не вытягивать макет вертикально искусственно. Лучше увеличивать длину за счёт дополнительных блоков, а не растягивания карточек.
- Не дублировать заголовки и одинаковые текстовые блоки.
- Не добавлять адрес в шапку. Адрес только в контактах/футере.
- Не использовать чёрный фон. Для тёмных зон — глубокий приятный синий.
- Сохранять один главный CTA на первом экране.
- Не мутировать логотип и текст ARWOX.
- Избегать искажений: ровные карточки, одинаковые отступы, одинаковые радиусы, единая сетка.
- Все CTA и интерактивные элементы должны иметь hover/focus states при верстке.

## Состав ассетов в архиве
- `01_source_mockups` — исходные PNG-макеты.
- `02_png_blocks` — крупные блоки лендинга отдельными PNG.
- `03_png_elements_cards` — карточки/элементы, вырезанные из макетов.
- `04_svg_icons` — реконструированный набор SVG-иконок в стиле макета.
- `05_docs` — промт, текстовка, манифест.
- `06_previews` — общий склеенный preview из 4 частей.
