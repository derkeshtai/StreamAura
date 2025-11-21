# StreamAura

Webcams del mundo + Radio + Momentos compartidos. Una app para Android, iOS y Web.

## Concepto

StreamAura permite combinar webcams en vivo de todo el mundo con estaciones de radio, musica ambiental o ruido blanco, creando experiencias unicas. Los usuarios pueden capturar y compartir "momentos" - esas combinaciones perfectas donde la vista y el audio crean algo especial.

## Caracteristicas

- **Webcams en vivo**: Ciudades, naturaleza, volcanes, auroras boreales
- **Audio**: Radio, musica ambiental, ruido blanco, sonidos para dormir
- **Frases inspiradoras**: Superpuestas sobre el video con fuente/color personalizable
- **Momentos compartidos**: Captura y comparte combinaciones perfectas
- **Favoritos**: Guarda tus webcams, estaciones y momentos preferidos
- **Sincronizacion**: Tus favoritos en todos tus dispositivos

## Tecnologias

- **Flutter** - App multiplataforma (Android, iOS, Web)
- **Firebase Hosting** - Web app
- **Cloud Firestore** - Base de datos
- **Firebase Auth** - Autenticacion
- **Firebase Analytics** - Metricas

## Configuracion

### Requisitos previos

1. [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.2.0+)
2. [Android Studio](https://developer.android.com/studio) o [VS Code](https://code.visualstudio.com/)
3. [Firebase CLI](https://firebase.google.com/docs/cli)
4. Cuenta de Firebase

### Instalacion

1. **Clona el repositorio**
   ```bash
   git clone https://github.com/tu-usuario/streamaura.git
   cd streamaura
   ```

2. **Crea el proyecto Flutter** (si no existe)
   ```bash
   flutter create . --org com.tuempresa
   ```

3. **Instala dependencias**
   ```bash
   flutter pub get
   ```

4. **Configura Firebase**
   ```bash
   # Instala FlutterFire CLI
   dart pub global activate flutterfire_cli

   # Configura Firebase (esto genera firebase_options.dart)
   flutterfire configure
   ```

5. **Actualiza main.dart**
   - Descomenta las lineas de Firebase en `lib/main.dart`

6. **Ejecuta la app**
   ```bash
   # Android/iOS
   flutter run

   # Web
   flutter run -d chrome
   ```

### Configurar Firebase Hosting (Web)

```bash
# Login a Firebase
firebase login

# Inicializa hosting (selecciona public como directorio)
firebase init hosting

# Build web
flutter build web

# Copia build a public
cp -r build/web/* public/

# Despliega
firebase deploy --only hosting
```

## Estructura del proyecto

```
lib/
├── main.dart              # Punto de entrada
├── models/                # Modelos de datos
│   ├── webcam.dart
│   ├── radio_station.dart
│   ├── momento.dart
│   ├── quote.dart
│   └── favorito.dart
├── services/              # Logica de negocio
│   ├── firebase_service.dart
│   ├── audio_service.dart
│   ├── rss_service.dart
│   └── momento_service.dart
├── providers/             # Estado de la app
│   └── app_state.dart
├── screens/               # Pantallas
│   ├── home_screen.dart
│   ├── player_screen.dart
│   ├── momentos_screen.dart
│   └── favoritos_screen.dart
└── widgets/               # Componentes reutilizables
```

## Firestore - Estructura de datos

```
webcams/
  {webcamId}/
    name: string
    url: string
    thumbnailUrl: string?
    country: string?
    isYoutube: boolean
    tags: string[]

stations/
  {stationId}/
    name: string
    streamUrl: string
    imageUrl: string?
    type: "radio" | "whiteNoise" | "nature" | "ambient" | "music"
    genre: string?

momentos/
  {momentoId}/
    title: string
    webcamId: string
    webcamUrl: string
    audioId: string
    audioUrl: string
    videoTimestamp: string?
    audioOffsetSeconds: number?
    quoteText: string?
    creatorId: string
    likes: number
    createdAt: timestamp

favoritos/
  {favoritoId}/
    userId: string
    itemId: string
    type: "webcam" | "radioStation" | "quote" | "momento"
    createdAt: timestamp

quotes/
  {quoteId}/
    text: string
    author: string?
    category: string
```

## Agregar contenido

Para agregar webcams, estaciones, etc., puedes:

1. **Firebase Console**: Agregar documentos manualmente
2. **Cloud Functions**: Crear funciones que importen RSS automaticamente
3. **Admin panel**: Crear una interfaz web de administracion

## Licencia

MIT
