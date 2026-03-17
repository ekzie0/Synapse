<!-- ЛОГО и заголовок -->
<div align="center">

# SYNAPSE

  <img src="https://github.com/ekzie0/Synapse/blob/main/docs/synapse_logo_without_text_white.svg" alt="Synapse_Logo_White" width="300">

  ### Ваш персональный Obsidian в кармане

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Go](https://img.shields.io/badge/Go-00ADD8?style=for-the-badge&logo=go&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)

*Мобильное приложение для заметок с графом связей и локальной синхронизацией*

[📱 Особенности](#-особенности) • [🚀 Быстрый старт](#-быстрый-старт) • [📸 Скриншоты](#-скриншоты) • [🏗️ Архитектура](#%EF%B8%8F-архитектура) • [🎓 Для диплома](#-для-диплома)

</div>

---

## 📱 **Особенности**

| Функция | Описание | Статус |
|---------|----------|--------|
| **📝 Умный редактор** | Markdown + [[вики-ссылки]] как в Obsidian | 🔄 В разработке |
| **🕸️ Граф знаний** | Визуализация связей между заметками | 🔄 В разработке |
| **🔗 Авто-линковка** | AI предлагает связи между заметками | 🔄 В разработке |
| **📡 Локальная синхронизация** | P2P между телефоном и компьютером | 🔄 В разработке |
| **💾 Файловый бэкап** | Экспорт/импорт через JSON | 🔄 В разработке |
| **🌐 Кроссплатформенность** | Android, iOS, Web, Windows | 🔄 В разработке |

---

## 🚀 **Быстрый старт**

### **Для пользователей:**
1. **Скачайте APK** из [Releases](https://github.com/ваш-username/Synapse/releases)
2. **Установите** на Android устройство
3. **Начните создавать** заметки с [[вики-ссылками]]

### **Для разработчиков:**
```bash
# 1. Клонируйте репозиторий
git clone https://github.com/ваш-username/Synapse.git
cd Synapse

# 2. Запустите flutter приложение
cd client
flutter pub get
flutter run

# 3. Запустите Go сервер (опционально)
cd ../server
go run cmd/api/main.go
```

**Системные требования:**
- Flutter 3.0+ 
- Android SDK 34+ (для сборки)
- Go 1.21+ (для сервера)

---

## 📸 **Скриншоты**

<div align="center">

| Редактор заметок | Граф связей | Синхронизация |
|:---:|:---:|:---:|
| ![Editor](https://via.placeholder.com/300x600/3a86ff/ffffff?text=Редактор+с+[[ссылками]]) | ![Graph](https://via.placeholder.com/300x600/8338ec/ffffff?text=Граф+знаний) | ![Sync](https://via.placeholder.com/300x600/ff006e/ffffff?text=P2P+Синхронизация) |
| *Редактор с [[вики-ссылками]]* | *Визуализация связей* | *Локальная синхронизация* |

В РАЗРАБОТКЕ

</div>

## 🏗️ **Архитектура**

```mermaid
graph TB
    subgraph "Мобильное устройство"
        A[Flutter UI] --> B[Локальная БД]
        B --> C[Синхронизатор]
    end
    
    subgraph "Локальная сеть"
        C --> D{WiFi P2P}
        D --> E[Go сервер на ПК]
    end
    
    subgraph "Резервное копирование"
        C --> F[Экспорт в JSON]
        F --> G[Облако/Флешка]
        G --> H[Импорт на ПК]
    end
    
    E --> I[(База данных<br/>на ПК)]
    
    style A fill:#3a86ff
    style E fill:#8338ec
    style F fill:#ff006e
```

**Ключевые компоненты:**
- **Frontend**: Flutter (Dart) - кроссплатформенный UI
- **Backend**: Go - легковесный сервер синхронизации
- **База данных**: SQLite (мобильное) + PostgreSQL (опционально на ПК)
- **Синхронизация**: WebSocket (real-time) + HTTP REST (бэкап)

---

## 🎓 **Для диплома**

### **Научная новизна:**
1. **Двойная синхронизация** - P2P + файловый бэкап
2. **Локальность данных** - полная конфиденциальность
3. **Гибридный подход** - мобильное приложение + десктоп сервер

### **Демонстрация:**
```
1. Создание заметки на телефоне
   ↓
2. Автоматическая синхронизация с ПК
   ↓  
3. Визуализация в графе знаний
   ↓
4. Файловый экспорт как запасной вариант
```

### **Технический стек:**
```yaml
frontend:
  framework: Flutter 3.0
  state_management: Provider
  database: Hive/SQLite
  graph_visualization: GraphView

backend:
  language: Go 1.21
  protocols: WebSocket, HTTP REST
  database: SQLite/PostgreSQL
  p2p: LAN discovery

devops:
  ci_cd: GitHub Actions
  build: Flutter APK + Go binary
  docs: OpenAPI 3.0

