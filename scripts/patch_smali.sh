#!/bin/bash
# Патчинг Smali кода для обхода проверок лицензии

set -e

DECOMPILED_DIR="${1:-decompiled}"

if [ ! -d "$DECOMPILED_DIR" ]; then
    echo "Error: Decompiled directory not found: $DECOMPILED_DIR"
    exit 1
fi

echo "Patching Smali code in: $DECOMPILED_DIR"

# Найти SuperJNI класс
SUPERJNI_FILE=$(find "$DECOMPILED_DIR" -path "*/com/eternal/xdsdk/SuperJNI*.smali" | head -1)
LOGIN_ACTIVITY=$(find "$DECOMPILED_DIR" -path "*/com/eternal/xdsdk/LoginActivity*.smali" | head -1)

if [ -z "$SUPERJNI_FILE" ]; then
    echo "⚠ SuperJNI.smali not found, searching all smali files..."
    find "$DECOMPILED_DIR" -name "*.smali" -exec grep -l "SuperJNI" {} \; | head -5
else
    echo "✓ Found SuperJNI: $SUPERJNI_FILE"
    
    # Создать патч для метода check
    echo "Patching check() method..."
    
    # Создаем Python скрипт для патчинга Smali
    python3 << PYTHON_EOF
import re
import os

superjni_file = "$SUPERJNI_FILE"

with open(superjni_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Патчинг метода check - заставляем всегда возвращать true
# Ищем метод check и заменяем его тело

check_pattern = r'(\.method\s+(?:public\s+)?(?:static\s+)?check\([^\)]*\)[^\n]*\n)(.*?)(\.end method)'
def replace_check(match):
    method_header = match.group(1)
    method_end = match.group(3)
    
    # Новое тело метода - просто возвращаем true (1)
    new_body = """    .locals 1
    
    # License check bypassed - always return true
    const/4 v0, 0x1
    return v0
    
"""
    return method_header + new_body + method_end

content = re.sub(check_pattern, replace_check, content, flags=re.DOTALL)

# Патчинг метода licence
licence_pattern = r'(\.method\s+(?:public\s+)?(?:static\s+)?licence\([^\)]*\)[^\n]*\n)(.*?)(\.end method)'
def replace_licence(match):
    method_header = match.group(1)
    method_end = match.group(3)
    
    new_body = """    .locals 1
    
    # License check bypassed - always return true
    const/4 v0, 0x1
    return v0
    
"""
    return method_header + new_body + method_end

content = re.sub(licence_pattern, replace_licence, content, flags=re.DOTALL)

# Сохраняем изменения
with open(superjni_file, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"✓ Patched SuperJNI methods in {superjni_file}")
PYTHON_EOF

fi

if [ -z "$LOGIN_ACTIVITY" ]; then
    echo "⚠ LoginActivity.smali not found"
else
    echo "✓ Found LoginActivity: $LOGIN_ACTIVITY"
    
    # Патчинг LoginActivity - автоматический переход в MainActivity
    python3 << PYTHON_EOF
import re
import os

login_file = "$LOGIN_ACTIVITY"

with open(login_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Находим метод onCreate и модифицируем его
oncreate_pattern = r'(\.method\s+(?:protected\s+)?onCreate\(Landroid/os/Bundle;\)V\n)(.*?)(\.end method)'

def replace_oncreate(match):
    method_header = match.group(1)
    original_body = match.group(2)
    method_end = match.group(3)
    
    # Извлекаем количество locals
    locals_match = re.search(r'\.locals\s+(\d+)', original_body)
    locals_count = int(locals_match.group(1)) if locals_match else 2
    
    # Увеличиваем на 1 для Intent
    locals_count = max(locals_count, 3)
    
    # Новое тело: вызываем super.onCreate, затем сразу переходим в MainActivity
    new_body = f"""    .locals {locals_count}
    
    # Call super.onCreate
    .line 1
    invoke-super {{p0, p1}}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V
    
    # Skip login - go directly to MainActivity
    new-instance v0, Landroid/content/Intent;
    
    const-class v1, Lcom/eternal/MainActivity;
    
    invoke-direct {{v0, p0, v1}}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V
    
    invoke-virtual {{p0, v0}}, Landroid/app/Activity;->startActivity(Landroid/content/Intent;)V
    
    invoke-virtual {{p0}}, Landroid/app/Activity;->finish()V
    
    return-void
    
"""
    return method_header + new_body + method_end

content = re.sub(oncreate_pattern, replace_oncreate, content, flags=re.DOTALL)

with open(login_file, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"✓ Patched LoginActivity onCreate in {login_file}")
PYTHON_EOF

fi

# Патчинг AndroidManifest.xml - изменить MAIN activity
MANIFEST="$DECOMPILED_DIR/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
    echo "Patching AndroidManifest.xml..."
    
    # Создаем бэкап
    cp "$MANIFEST" "$MANIFEST.bak"
    
    python3 << PYTHON_EOF
import re

manifest_file = "$MANIFEST"

with open(manifest_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Находим LoginActivity и удаляем из него MAIN intent-filter
# или перемещаем MAIN intent-filter в MainActivity

# Подход: найти LoginActivity и убрать из него категорию LAUNCHER
content = re.sub(
    r'(<activity[^>]*android:name="\.LoginActivity"[^>]*>.*?)'
    r'(<intent-filter>.*?<action android:name="android\.intent\.action\.MAIN"\s*/?>.*?'
    r'<category android:name="android\.intent\.category\.LAUNCHER"\s*/?>.*?</intent-filter>)'
    r'(.*?</activity>)',
    r'\1<!-- LAUNCHER intent-filter removed by patch -->\3',
    content,
    flags=re.DOTALL
)

# Добавляем MAIN intent-filter в MainActivity если его там нет
if 'MainActivity' in content and 'action.MAIN' not in re.search(
    r'<activity[^>]*android:name="[^"]*MainActivity"[^>]*>.*?</activity>',
    content,
    re.DOTALL
).group(0) if re.search(r'<activity[^>]*android:name="[^"]*MainActivity"[^>]*>', content) else '':
    
    # Найти MainActivity и добавить intent-filter
    def add_intent_filter(match):
        activity_tag = match.group(0)
        if '<intent-filter>' not in activity_tag:
            # Вставляем intent-filter перед закрывающим тегом
            intent_filter = '''
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>'''
            activity_tag = activity_tag.replace('</activity>', intent_filter)
        return activity_tag
    
    content = re.sub(
        r'<activity[^>]*android:name="[^"]*MainActivity"[^>]*>.*?</activity>',
        add_intent_filter,
        content,
        flags=re.DOTALL
    )

with open(manifest_file, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"✓ Patched AndroidManifest.xml")
PYTHON_EOF

else
    echo "⚠ AndroidManifest.xml not found"
fi

echo ""
echo "✓ Smali patching completed"
echo "Modified files:"
[ -n "$SUPERJNI_FILE" ] && echo "  - $SUPERJNI_FILE"
[ -n "$LOGIN_ACTIVITY" ] && echo "  - $LOGIN_ACTIVITY"
[ -f "$MANIFEST" ] && echo "  - $MANIFEST"
