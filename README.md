# K в ряд — гра на Prolog з веб-інтерфейсом

Це логічна гра "K в ряд", реалізована з використанням **SWI-Prolog** як рушія для ігрової логіки, **Node.js** як сервера-посередника та **HTML/CSS/JavaScript** для графічного інтерфейсу.

## Технології:

- **SWI-Prolog** — логіка гри. з режимами AI (легкий, середній, складний).
- **Node.js + Express** — сервер, який приймає запити з фронтенду та викликає прологові предикати.
- **HTML + CSS + JS** — клієнтська частина гри (UI/UX).

## Встановлення:

### 1. Встановити SWI-Prolog

Скачати з [офіційного сайту](https://www.swi-prolog.org/Download.html) та переконатися, що команда `swipl` доступна у терміналі.

### 2. Клонувати репозиторій:

```bash
git clone https://github.com/cas08/prolog-k-in-row.git
cd prolog-k-in-row
```

## 3. Встановити залежності:
потрібно мати встановлений **Node.js** та пакет менеджер (напр. **npm**)
```bash
npm install
```
## 4. Запустити сервер:
```bash
npm run server
```
Сервер буде працювати на порту http://localhost:8080

## 6. Запустити клієнт
Відкрити файл index.html у браузері (можна через розширення Live Server або просто подвійним кліком).
