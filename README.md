# Team Tasks Manager — Практична робота 11 (Частина 3)

Комплексний мережевий Flutter-додаток (Варіант 1: **Менеджер задач з командами**), побудований з використанням чистої архітектури, JWT-авторизації, кешування та повноцінного offline-режиму.

## Технічний стек
- **Мережа:** `dio` (з `AuthInterceptor`, `RetryInterceptor`, `LoggingInterceptor`)
- **State Management:** `provider`
- **Локальне кешування:** `hive` & `hive_flutter`
- **Безпечне зберігання токенів:** `flutter_secure_storage`
- **Контроль з'єднання:** `connectivity_plus`

## Реалізований функціонал
1. **Авторизація (ReqRes API):**
   - Вхід (`POST /api/login`) та реєстрація (`POST /api/register`).
   - Збереження JWT у `flutter_secure_storage`, автоматичний вхід (auto-login) при перезапуску додатку.
   - Автоматичне підставлення `Bearer` токена та обробка `401 Unauthorized` (refresh flow) у `AuthInterceptor`.
2. **Управління задачами (JSONPlaceholder `/todos`):**
   - Повний CRUD: перегляд, створення, редагування, зміна статусу виконання, видалення.
   - Прив'язка кожної задачі до учасника команди (`userId`).
   - Фільтрація задач (**All** / **Active** / **Completed**) та пошук за назвою.
   - Динамічна статистика виконаних та активних задач в `AppBar`.
3. **Offline-режим:**
   - Кешування відповідей у Hive.
   - Автоматичний перехід на кеш при втраті з'єднання та відображення банера `OfflineBanner`.

## Інструкція із запуску (Setup)
```bash
git clone <URL_ВАШОГО_РЕПОЗИТОРІЮ>
cd task_manager_pr11
flutter pub get
flutter run
Тестові дані для входу (ReqRes)
Email: eve.holt@reqres.in

Password: cityslicka
