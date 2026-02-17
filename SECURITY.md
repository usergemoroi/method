# Security Policy

## Использование инструмента безопасно?

Этот инструмент предназначен для **образовательных целей** и использования на **собственных приложениях**. 

### ⚠️ Важные предупреждения

1. **Keystore безопасность**
   - НЕ коммитьте keystore файлы в публичные репозитории
   - Используйте надежные пароли для production keystore
   - Храните backup keystore в безопасном месте
   - Используйте environment variables для паролей в CI/CD

2. **APK целостность**
   - Всегда проверяйте пропатченные APK на вирусы
   - Используйте только доверенные источники для исходных APK
   - Проверяйте подпись после патчинга

3. **Конфиденциальность**
   - Не включайте в патчи личные данные
   - Удаляйте отладочную информацию перед релизом
   - Проверяйте что не утекают API ключи

## Reporting Security Issues

Если вы обнаружили уязвимость безопасности:

### 🔒 Частные уязвимости

**НЕ создавайте публичный Issue!**

Отправьте приватное сообщение:
- Email: [security@example.com] (замените на реальный)
- GitHub Security Advisory: используйте функцию "Private vulnerability reporting"

Включите:
- Описание уязвимости
- Шаги для воспроизведения
- Потенциальное влияние
- Предложения по исправлению (опционально)

### 📢 Публичные проблемы

Для не-критичных проблем безопасности можно создать публичный Issue.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Security Best Practices

### Для пользователей инструмента

#### 1. Защита Keystore

```bash
# ❌ НЕ ДЕЛАЙТЕ ТАК
git add release.keystore
git commit -m "Add keystore"

# ✅ ПРАВИЛЬНО
# Добавьте в .gitignore
echo "*.keystore" >> .gitignore
echo "*.jks" >> .gitignore

# Используйте environment variables
export KEYSTORE_PASSWORD="your-secure-password"
./scripts/build.sh decompiled output.apk keystore.jks alias "$KEYSTORE_PASSWORD"
```

#### 2. Безопасная работа с паролями

```bash
# ❌ НЕ ДЕЛАЙТЕ ТАК
./build.sh decompiled out.apk key.jks alias password123

# ✅ ПРАВИЛЬНО - используйте переменные окружения
export KEY_PASS="$(read -sp 'Enter password: ' pwd; echo $pwd)"
./build.sh decompiled out.apk key.jks alias "$KEY_PASS"

# Или используйте конфиг файл (не в git)
source .env.local  # Добавлен в .gitignore
./build.sh decompiled out.apk key.jks alias "$KEYSTORE_PASSWORD"
```

#### 3. Проверка APK перед установкой

```bash
# Проверить подпись
apksigner verify --verbose app-patched.apk

# Проверить что не было добавлено лишнего
unzip -l app-patched.apk | grep -i "suspicious"

# Сканирование антивирусом
clamscan app-patched.apk

# Или используйте VirusTotal API
vt scan file app-patched.apk
```

#### 4. Безопасное хранение APK

```bash
# Шифрование APK для хранения
gpg --symmetric --cipher-algo AES256 app-patched.apk

# Расшифровка
gpg --decrypt app-patched.apk.gpg > app-patched.apk
```

### Для разработчиков

#### 1. Code Review

Перед мержем PR проверьте:
- Нет ли hardcoded паролей/ключей
- Нет ли потенциально опасных команд (rm -rf /)
- Валидируются ли входные данные
- Обрабатываются ли ошибки корректно

#### 2. Input Validation

```bash
# ✅ ПРАВИЛЬНО - проверка входных данных
validate_apk() {
    local apk="$1"
    
    # Проверка существования
    if [ ! -f "$apk" ]; then
        echo "Error: File not found"
        return 1
    fi
    
    # Проверка расширения
    if [[ ! "$apk" =~ \.apk$ ]]; then
        echo "Error: Not an APK file"
        return 1
    fi
    
    # Проверка что это действительно ZIP
    if ! file "$apk" | grep -q "Zip archive"; then
        echo "Error: Invalid APK format"
        return 1
    fi
    
    return 0
}
```

#### 3. Secure Temp Files

```bash
# ✅ ПРАВИЛЬНО - безопасные временные файлы
TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEMP_DIR'" EXIT

# Работа с временными файлами
cp app.apk "$TEMP_DIR/"
# ... обработка ...

# Автоматически удалится при выходе
```

#### 4. Prevent Command Injection

```bash
# ❌ НЕ ДЕЛАЙТЕ ТАК - уязвимо к инъекциям
eval "apktool d $USER_INPUT"

# ✅ ПРАВИЛЬНО
apktool d "$USER_INPUT"  # Кавычки защищают от инъекций

# Еще лучше - валидация
if [[ "$USER_INPUT" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    apktool d "$USER_INPUT"
else
    echo "Invalid input"
    exit 1
fi
```

## Security Checklist

Перед релизом пропатченного APK:

- [ ] Удалены все debug логи
- [ ] Нет hardcoded паролей/ключей
- [ ] APK подписан production keystore
- [ ] Проверен антивирусом
- [ ] Протестирован на реальном устройстве
- [ ] Нет лишних permissions в AndroidManifest
- [ ] ProGuard/R8 применен (если использовался)
- [ ] Нет чувствительных данных в strings.xml
- [ ] Версия обновлена в build.gradle/AndroidManifest

## Безопасность инфраструктуры

### GitHub Repository

```yaml
# .github/workflows/security.yml
name: Security Scan

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      # Сканирование секретов
      - name: GitGuardian scan
        uses: GitGuardian/ggshield-action@v1
        env:
          GITHUB_PUSH_BEFORE_SHA: ${{ github.event.before }}
          GITHUB_PUSH_BASE_SHA: ${{ github.event.base }}
          GITHUB_PULL_BASE_SHA: ${{ github.event.pull_request.base.sha }}
          GITHUB_DEFAULT_BRANCH: ${{ github.event.repository.default_branch }}
          GITGUARDIAN_API_KEY: ${{ secrets.GITGUARDIAN_API_KEY }}
      
      # Сканирование зависимостей
      - name: Run Snyk
        uses: snyk/actions/python@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

### Secrets Management

```bash
# Используйте GitHub Secrets для CI/CD
# Settings → Secrets and variables → Actions → New repository secret

# В workflow:
env:
  KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
  KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
```

## Известные ограничения безопасности

1. **Keystore в примерах**
   - Примеры используют простые пароли
   - В production используйте надежные пароли
   - Храните keystore отдельно от кода

2. **Root permissions**
   - Скрипты не требуют root
   - Не запускайте с sudo без необходимости
   - Проверяйте права доступа к файлам

3. **Network security**
   - mitmproxy примеры требуют установки сертификата
   - Не используйте на production устройствах
   - Удалите сертификат после тестирования

4. **Code signing**
   - Пропатченный APK имеет другую подпись
   - Play Store updates не будут работать
   - Требуется переустановка при обновлении

## Audit Log

### Version 1.0.0
- ✅ Code review completed
- ✅ No hardcoded secrets found
- ✅ Input validation implemented
- ✅ Secure temp file handling
- ✅ Documentation reviewed

## Resources

- [Android Security Best Practices](https://developer.android.com/topic/security/best-practices)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [APK Signature Scheme](https://source.android.com/security/apksigning)

## Contact

Для вопросов безопасности:
- Создайте Security Advisory на GitHub
- Или свяжитесь с maintainers напрямую

---

**Помните:** Безопасность - это процесс, а не продукт. Всегда будьте внимательны при работе с приложениями.
