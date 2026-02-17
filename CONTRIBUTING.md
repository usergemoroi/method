# Contributing to XDSDK License Bypass

Спасибо за интерес к проекту! Мы приветствуем вклад от сообщества.

## Как внести вклад

### Reporting Issues

Если вы нашли ошибку или хотите предложить улучшение:

1. Проверьте [Issues](../../issues), возможно проблема уже известна
2. Создайте новый Issue с подробным описанием:
   - Шаги для воспроизведения
   - Ожидаемое поведение
   - Фактическое поведение
   - Версия Android и архитектура устройства
   - Логи (если применимо)

### Pull Requests

1. **Fork репозиторий**
   ```bash
   # Нажмите Fork на GitHub
   git clone https://github.com/YOUR_USERNAME/xdsdk-bypass.git
   cd xdsdk-bypass
   ```

2. **Создайте feature branch**
   ```bash
   git checkout -b feature/my-new-feature
   # или
   git checkout -b fix/bug-fix
   ```

3. **Внесите изменения**
   - Следуйте существующему стилю кода
   - Добавьте комментарии для сложной логики
   - Обновите документацию если нужно

4. **Протестируйте изменения**
   ```bash
   # Запустите скрипты чтобы убедиться что всё работает
   ./scripts/full_pipeline.sh test.apk
   ```

5. **Commit и Push**
   ```bash
   git add .
   git commit -m "feat: add ARM32 support"
   git push origin feature/my-new-feature
   ```

6. **Создайте Pull Request**
   - Опишите что изменилось и зачем
   - Ссылайтесь на связанные Issues
   - Добавьте скриншоты если применимо

## Coding Guidelines

### Shell Scripts

```bash
#!/bin/bash
# Описание скрипта

set -e  # Выход при ошибке

# Константы в UPPER_CASE
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Функции в snake_case
function my_function() {
    local param="$1"
    
    # Проверка параметров
    if [ -z "$param" ]; then
        echo "Error: parameter required"
        return 1
    fi
    
    # Логика
    echo "Processing: $param"
}

# Использование цветов для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}✓${NC} Success"
echo -e "${RED}✗${NC} Error"
```

### Python Scripts

```python
#!/usr/bin/env python3
"""
Module description.

This module does X and Y.
"""

import sys
from typing import List, Optional

def my_function(param: str, optional: Optional[int] = None) -> bool:
    """
    Function description.
    
    Args:
        param: Description of param
        optional: Optional parameter
        
    Returns:
        True if successful, False otherwise
    """
    # Implementation
    pass

def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: script.py <param>")
        sys.exit(1)
    
    # Logic
    
if __name__ == '__main__':
    main()
```

### Commit Messages

Используем [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: Новая функциональность
- `fix`: Исправление ошибки
- `docs`: Изменения в документации
- `style`: Форматирование, отсутствие изменений кода
- `refactor`: Рефакторинг кода
- `test`: Добавление тестов
- `chore`: Изменения в сборке, CI и т.д.

**Примеры:**
```
feat(native): add ARM32 architecture support

Added patching instructions for armeabi-v7a architecture.
Includes THUMB and ARM mode detection.

Closes #123
```

```
fix(smali): handle SuperJNI with multiple companions

Previous version assumed single Companion class.
Now correctly patches all Companion subclasses.

Fixes #456
```

## Documentation

### Updating Documentation

При добавлении новых функций:

1. Обновите `README.md` если изменился основной workflow
2. Добавьте технические детали в `docs/TECHNICAL.md`
3. Добавьте примеры в `EXAMPLES.md`
4. Обновите FAQ если часто возникают вопросы
5. Добавьте запись в `CHANGELOG.md`

### Documentation Style

- Используйте ясный, простой язык
- Добавляйте примеры кода
- Включайте скриншоты для UI изменений
- Проверяйте орфографию и грамматику
- Форматируйте код блоки с указанием языка:
  
  ````markdown
  ```bash
  ./script.sh
  ```
  ````

## Project Structure

```
xdsdk-bypass/
├── scripts/              # Исполняемые скрипты
│   ├── decompile.sh     # Декомпиляция APK
│   ├── patch_native.sh  # Патчинг native библиотек
│   ├── patch_smali.sh   # Патчинг Smali кода
│   ├── build.sh         # Сборка APK
│   ├── test_apk.sh      # Тестирование
│   └── full_pipeline.sh # Полный конвейер
│
├── docs/                 # Документация
│   ├── TECHNICAL.md     # Технические детали
│   ├── WORKFLOW.md      # Рабочие процессы
│   └── FAQ.md           # Частые вопросы
│
├── README.md            # Основная документация
├── CHANGELOG.md         # История изменений
├── EXAMPLES.md          # Примеры использования
├── LICENSE              # Лицензия
├── CONTRIBUTING.md      # Это руководство
└── .gitignore          # Git игнор
```

## Testing

### Manual Testing

Перед отправкой PR протестируйте:

```bash
# 1. Основной workflow
./scripts/full_pipeline.sh test.apk

# 2. Установка на устройство
adb install -r app-patched.apk

# 3. Запуск и проверка логов
adb shell am start -n com.eternal/.MainActivity
adb logcat | grep -i "eternal\|xdsdk"

# 4. Проверка функциональности
# - Приложение запускается без логина
# - Нет крашей
# - Основные функции работают
```

### Test Cases

При добавлении новой функциональности, добавьте test case:

```bash
# scripts/test_my_feature.sh
#!/bin/bash
set -e

echo "Testing my feature..."

# Подготовка
./scripts/decompile.sh test.apk

# Тест
result=$(my_new_function)

# Проверка
if [ "$result" == "expected" ]; then
    echo "✓ Test passed"
    exit 0
else
    echo "✗ Test failed"
    exit 1
fi
```

## Features to Contribute

### High Priority

- [ ] ARM32 (armeabi-v7a) поддержка
- [ ] x86/x86_64 поддержка
- [ ] Автоматическое определение офсетов функций
- [ ] Улучшенная обработка ошибок
- [ ] Больше тестов

### Medium Priority

- [ ] GUI интерфейс
- [ ] Docker контейнер
- [ ] Поддержка split APK
- [ ] Batch патчинг
- [ ] Профили для разных версий XDSDK

### Low Priority

- [ ] Web интерфейс
- [ ] REST API
- [ ] База данных известных реализаций
- [ ] Интеграция с Firebase Test Lab
- [ ] Машинное обучение для поиска функций

## Code Review Process

1. Maintainer проверит ваш PR в течение 1-7 дней
2. Могут быть запрошены изменения
3. После одобрения PR будет смержен
4. Ваше имя будет добавлено в Contributors

## Questions?

- Откройте [Discussion](../../discussions) для вопросов
- Создайте [Issue](../../issues) для bug reports
- Свяжитесь с maintainers через GitHub

## License

Внося вклад в проект, вы соглашаетесь что ваш код будет распространяться под MIT License.

## Recognition

Все contributors будут упомянуты в README и release notes.

Спасибо за вклад в проект! 🎉
