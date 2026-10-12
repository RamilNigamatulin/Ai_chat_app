# Инструкция по установке

## Системные требования

### Общие требования
- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.47 или выше (канал stable)
- Dart SDK ^3.6.0 (входит в состав Flutter SDK)
- Git
- VS Code или Android Studio (рекомендуется)

### Поддерживаемые платформы проекта
Данный репозиторий содержит конфигурации только для двух платформ:
- **Android** (`android/`)
- **Windows** (`windows/`)

Директорий `ios/` и `linux/` в проекте нет, поэтому сборка под iOS и Linux в текущей версии не поддерживается.

### Windows
- Windows 10 или выше
- Visual Studio 2022 (рекомендуется) с workload **Desktop development with C++**
- Windows 10 SDK

### Android
- Android Studio
- Android SDK
- Java Development Kit (JDK) 17 — проект использует `sourceCompatibility`/`jvmTarget` = Java 17

## Установка

1. Клонируйте репозиторий:
```bash
git clone https://github.com/neuro-fill/AIChatFlutter.git
cd AIChatFlutter
```

2. Установите Flutter SDK:
   - Скачайте Flutter SDK с [официального сайта](https://flutter.dev/docs/get-started/install)
   - Добавьте Flutter в PATH
   - Запустите `flutter doctor` и следуйте инструкциям для установки недостающих компонентов

3. Настройка VSCode:
   - Установите расширения Flutter и Dart
   - Настройте форматирование кода (рекомендуется использовать dart format)
   - Убедитесь, что в настройках включена поддержка Flutter

4. Создайте файл `.env` (обязателен: он включён в `pubspec.yaml` как asset, без него сборка завершится ошибкой):
```bash
cp .env.example .env
```
   Содержимое можно оставить шаблонным — API ключ и провайдер вводятся в приложении на странице «Настройки» (см. раздел [Конфигурация](#конфигурация)).

5. Установите зависимости проекта:
```bash
flutter pub get
```

6. (Необязательно) Запустите тесты для проверки:
```bash
flutter test
```

## Настройка окружения для сборки

### Windows
1. Установите Visual Studio с компонентами для разработки на C++:
   - Desktop development with C++
   - Windows 10 SDK
   - Visual C++ tools for CMake
   
2. Включите режим разработчика в Windows:
   - Настройки > Обновление и безопасность > Для разработчиков
   - Включите "Режим разработчика"

3. Проверьте настройку Flutter для Windows:
```bash
flutter config --enable-windows-desktop
flutter doctor -v
```

### Android
1. Установите Android Studio:
   - Скачайте и установите [Android Studio](https://developer.android.com/studio)
   - Запустите Android Studio и пройдите начальную настройку
   - Установите Android SDK через SDK Manager
   - В SDK Manager установите:
     - Android SDK Build-Tools
     - Android SDK Command-line Tools
     - Android SDK Platform-Tools

2. Настройте Android Studio:
   - Установите Flutter и Dart плагины
   - Настройте Android SDK
   - Создайте и настройте Android эмулятор

3. Настройте подписывание APK (для release-сборки) — **необязательно**:
   - В текущей конфигурации `android/app/build.gradle.kts` release-сборка подписывается **debug-ключом** (чтобы `flutter run --release` работал сразу). Для публикации в сторах настройте собственную подпись:
   - Создайте keystore для подписи релизной версии:
      ```bash
      keytool -genkey -v -keystore android/app/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
      ```
   - Создайте файл `android/key.properties` со следующим содержимым:
      ```properties
      storePassword=<пароль от keystore>
      keyPassword=<пароль от ключа>
      keyAlias=upload
      storeFile=app/upload-keystore.jks
      ```
   - Добавьте `key.properties` в `.gitignore` (уже добавлен в `android/.gitignore`)
   - Подключите keystore в `android/app/build.gradle.kts` (Kotlin DSL): загрузите `key.properties` и замените `signingConfig = signingConfigs.getByName("debug")` в блоке `release` на конфигурацию с `upload-keystore.jks` по [официальной инструкции Flutter](https://docs.flutter.dev/deployment/android#sign-the-app)

4. Проверьте настройку Flutter для Android:
```bash
flutter doctor -v
```

## Сборка приложения

### Android
1. Debug версия (для тестирования):
```bash
flutter build apk --debug
```
2. Release версия (для публикации):
```bash
flutter build apk --release
```
3. Split APKs по архитектуре (оптимизированный размер):
```bash
flutter build apk --split-per-abi
```

### Windows
1. Debug версия (для тестирования):
```bash
flutter build windows --debug
```
2. Release версия (для публикации):
```bash
flutter build windows --release
```

## Расположение сбилденных файлов

### Android
- Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`
- Release APK: `build/app/outputs/flutter-apk/app-release.apk`
- Split APKs:
  - `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
  - `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
  - `build/app/outputs/flutter-apk/app-x86_64-release.apk`

### Windows
- Debug: `build/windows/x64/runner/Debug/`
- Release: `build/windows/x64/runner/Release/`

## Запуск приложения в desktop режиме для отладки

### Windows
1. Убедитесь, что установлены все необходимые компоненты:
   - Visual Studio с поддержкой C++
   - Windows 10 SDK
2. Включите поддержку Windows desktop:
```bash
flutter config --enable-windows-desktop
```
3. Запустите приложение:
```bash
flutter run -d windows
```

## Запуск приложения в Android эмуляторе

1. Создание эмулятора:
   - Откройте Android Studio
   - Перейдите в Device Manager (Tools > Device Manager)
   - Нажмите "Create Device"
   - Выберите тип устройства (например, Pixel 6)
   - Выберите образ системы (рекомендуется API 33 или новее)
   - Задайте имя эмулятора и нажмите "Finish"

2. Запуск эмулятора:
   - В Device Manager нажмите ▶️ рядом с созданным эмулятором
   - Или через командную строку:
     ```bash
     emulator -avd имя_эмулятора
     ```

3. Запуск приложения:
   - Убедитесь, что эмулятор запущен
   - Выполните команду:
     ```bash
     flutter run
     ```
   - Если нужно указать конкретный эмулятор:
     ```bash
     flutter run -d имя_эмулятора
     ```

4. Горячие клавиши:
   - R - Перезагрузить приложение
   - r - Hot reload (быстрая перезагрузка изменений)
   - q - Выйти из режима разработки

## Конфигурация

Конфигурация имеет два уровня (подробнее см. раздел «Конфигурация» в [README.md](README.md)):

1. Создайте файл `.env` на основе `.env.example` (файл обязателен для сборки, но значения могут быть шаблонными):
```bash
cp .env.example .env
```

2. Значения по умолчанию в `.env` (необязательно менять):
```
OPENROUTER_API_KEY=your_api_key_here
BASE_URL=https://openrouter.ai/api/v1
MAX_TOKENS=1000
TEMPERATURE=0.7
```

3. Основной способ настройки — страница **«Настройки»** в приложении (без перезапуска):
   - Провайдер API: OpenRouter.ai или VseGPT.ru
   - API ключ (вводится вместо значения из `.env`)
   - Максимальное количество токенов
   - Температура генерации (0.0 - 2.0)

   Настройки сохраняются в `SharedPreferences` и имеют приоритет над `.env`.

## Проверка установки

1. Проверьте статус Flutter:
```bash
flutter doctor
```

2. Запустите тесты:
```bash
flutter test
```
   Ожидаемый результат: `test/navigation_test.dart` проходит (тест `widget_test.dart` — устаревший шаблонный и завершается ошибкой, на работу приложения не влияет).

3. Запустите приложение для проверки:
```bash
flutter run
```

Если все установлено правильно, приложение должно запуститься на выбранном устройстве (эмулятор Android или Windows).
