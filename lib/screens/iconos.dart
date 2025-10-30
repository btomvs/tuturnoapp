// lib/screens/iconos_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IconosScreen extends StatefulWidget {
  const IconosScreen({super.key});
  @override
  State<IconosScreen> createState() => _IconosScreenState();
}

class _IconosScreenState extends State<IconosScreen> {
  final _q = TextEditingController();
  IconData? _seleccionado;

  // ===========================
  // 🔹 SINÓNIMOS ES → EN (buscador)
  // ===========================
  static const Map<String, List<String>> _syn = {
    'lupa': ['search'],
    'buscar': ['search'],
    'engranaje': ['settings', 'tune'],
    'ajuste': ['settings', 'tune'],
    'basura': ['delete', 'trash', 'remove'],
    'borrar': ['delete', 'remove'],
    'usuario': ['person', 'account', 'face'],
    'perfil': ['person', 'account'],
    'correo': ['mail', 'email'],
    'mensaje': ['message', 'chat', 'sms'],
    'compartir': ['share', 'send'],
    'guardar': ['save', 'bookmark'],
    'casa': ['home'],
    'inicio': ['home'],
    'ubicacion': ['location', 'place', 'pin', 'map', 'gps'],
    'telefono': ['phone', 'call'],
    'camara': ['camera', 'photo'],
    'imagen': ['image', 'photo', 'picture'],
    'campana': ['notifications'],
    'calendario': ['calendar', 'event', 'schedule'],
    'alarma': ['alarm', 'timer'],
    'descargar': ['download'],
    'subir': ['upload', 'file_upload'],
    'estrella': ['star', 'grade'],
    'ojo': ['visibility', 'preview'],
    'candado': ['lock'],
    'menu': ['menu'],
    'filtro': ['filter', 'tune'],
    'reloj': ['schedule', 'access_time'],
    'ubicación': ['location', 'place', 'pin', 'map', 'gps'],
  };

  // ============================================================
  // 🔹 MAPA DE ÍCONOS — Pega aquí *todas* las entradas que quieras
  //    (todo queda en este mismo archivo).
  //
  //  ⚠️ Este bloque trae un subconjunto grande inicial para que funcione ya.
  //  Para tener TODOS, pega el resto de entradas aquí con el mismo formato:
  //    'nombre_icono': IconData(0xEEEE, fontFamily: 'MaterialIcons'),
  // ============================================================
  static const Map<String, IconData> kAllMaterialIcons = {
    // --- búsqueda / lupa
    'search': IconData(0xe8b6, fontFamily: 'MaterialIcons'),
    'manage_search': IconData(0xf02f1, fontFamily: 'MaterialIcons'),
    'saved_search': IconData(0xea11, fontFamily: 'MaterialIcons'),
    'search_off': IconData(0xea76, fontFamily: 'MaterialIcons'),

    // --- ajustes / engranaje
    'settings': IconData(0xe8b8, fontFamily: 'MaterialIcons'),
    'settings_applications': IconData(0xe8b9, fontFamily: 'MaterialIcons'),
    'build': IconData(0xe869, fontFamily: 'MaterialIcons'),
    'tune': IconData(0xe429, fontFamily: 'MaterialIcons'),

    // --- navegación / menú
    'home': IconData(0xe88a, fontFamily: 'MaterialIcons'),
    'home_filled': IconData(0xe9b2, fontFamily: 'MaterialIcons'),
    'dashboard': IconData(0xe871, fontFamily: 'MaterialIcons'),
    'menu': IconData(0xe5d2, fontFamily: 'MaterialIcons'),
    'more_vert': IconData(0xe5d4, fontFamily: 'MaterialIcons'),
    'more_horiz': IconData(0xe5d3, fontFamily: 'MaterialIcons'),
    'apps': IconData(0xe5c3, fontFamily: 'MaterialIcons'),

    // --- usuario / cuenta
    'person': IconData(0xe7fd, fontFamily: 'MaterialIcons'),
    'person_outline': IconData(0xe7ff, fontFamily: 'MaterialIcons'),
    'account_circle': IconData(0xe853, fontFamily: 'MaterialIcons'),
    'group': IconData(0xe7ef, fontFamily: 'MaterialIcons'),
    'face': IconData(0xe87c, fontFamily: 'MaterialIcons'),

    // --- comunicación
    'call': IconData(0xe0b0, fontFamily: 'MaterialIcons'),
    'phone': IconData(0xe0cd, fontFamily: 'MaterialIcons'),
    'email': IconData(0xe0be, fontFamily: 'MaterialIcons'),
    'mail': IconData(0xe158, fontFamily: 'MaterialIcons'),
    'chat': IconData(0xe0b7, fontFamily: 'MaterialIcons'),
    'message': IconData(0xe0c9, fontFamily: 'MaterialIcons'),
    'forum': IconData(0xe0bf, fontFamily: 'MaterialIcons'),
    'sms': IconData(0xe625, fontFamily: 'MaterialIcons'),
    'send': IconData(0xe163, fontFamily: 'MaterialIcons'),

    // --- archivos
    'folder': IconData(0xe2c7, fontFamily: 'MaterialIcons'),
    'create_new_folder': IconData(0xe2cc, fontFamily: 'MaterialIcons'),
    'folder_open': IconData(0xe2c8, fontFamily: 'MaterialIcons'),
    'attach_file': IconData(0xe226, fontFamily: 'MaterialIcons'),
    'description': IconData(0xe873, fontFamily: 'MaterialIcons'),
    'file_download': IconData(0xe2c4, fontFamily: 'MaterialIcons'),
    'file_upload': IconData(0xe2c6, fontFamily: 'MaterialIcons'),
    'cloud': IconData(0xe2bd, fontFamily: 'MaterialIcons'),
    'cloud_download': IconData(0xe2bf, fontFamily: 'MaterialIcons'),
    'cloud_upload': IconData(0xe2c3, fontFamily: 'MaterialIcons'),

    // --- acciones
    'add': IconData(0xe145, fontFamily: 'MaterialIcons'),
    'add_circle': IconData(0xe147, fontFamily: 'MaterialIcons'),
    'add_box': IconData(0xe146, fontFamily: 'MaterialIcons'),
    'remove': IconData(0xe15b, fontFamily: 'MaterialIcons'),
    'close': IconData(0xe5cd, fontFamily: 'MaterialIcons'),
    'done': IconData(0xe876, fontFamily: 'MaterialIcons'),
    'check': IconData(0xe5ca, fontFamily: 'MaterialIcons'),
    'edit': IconData(0xe3c9, fontFamily: 'MaterialIcons'),
    'mode_edit': IconData(0xe254, fontFamily: 'MaterialIcons'),
    'delete': IconData(0xe872, fontFamily: 'MaterialIcons'),
    'delete_forever': IconData(0xe92b, fontFamily: 'MaterialIcons'),
    'save': IconData(0xe161, fontFamily: 'MaterialIcons'),
    'share': IconData(0xe80d, fontFamily: 'MaterialIcons'),
    'favorite': IconData(0xe87d, fontFamily: 'MaterialIcons'),
    'favorite_border': IconData(0xe87e, fontFamily: 'MaterialIcons'),
    'star': IconData(0xe838, fontFamily: 'MaterialIcons'),
    'star_border': IconData(0xe83a, fontFamily: 'MaterialIcons'),
    'visibility': IconData(0xe8f4, fontFamily: 'MaterialIcons'),
    'visibility_off': IconData(0xe8f5, fontFamily: 'MaterialIcons'),
    'refresh': IconData(0xe5d5, fontFamily: 'MaterialIcons'),
    'autorenew': IconData(0xe863, fontFamily: 'MaterialIcons'),
    'download': IconData(0xf0903, fontFamily: 'MaterialIcons'),
    'upload': IconData(0xf0909, fontFamily: 'MaterialIcons'),

    // --- multimedia
    'photo': IconData(0xe410, fontFamily: 'MaterialIcons'),
    'image': IconData(0xe3f4, fontFamily: 'MaterialIcons'),
    'camera_alt': IconData(0xe3b0, fontFamily: 'MaterialIcons'),
    'videocam': IconData(0xe04b, fontFamily: 'MaterialIcons'),
    'mic': IconData(0xe029, fontFamily: 'MaterialIcons'),
    'play_arrow': IconData(0xe037, fontFamily: 'MaterialIcons'),
    'pause': IconData(0xe034, fontFamily: 'MaterialIcons'),
    'stop': IconData(0xe047, fontFamily: 'MaterialIcons'),
    'music_note': IconData(0xe405, fontFamily: 'MaterialIcons'),
    'volume_up': IconData(0xe050, fontFamily: 'MaterialIcons'),

    // --- ubicación / mapas
    'place': IconData(0xe55f, fontFamily: 'MaterialIcons'),
    'location_on': IconData(0xe0c8, fontFamily: 'MaterialIcons'),
    'map': IconData(0xe55b, fontFamily: 'MaterialIcons'),
    'pin_drop': IconData(0xe55e, fontFamily: 'MaterialIcons'),
    'my_location': IconData(0xe55c, fontFamily: 'MaterialIcons'),
    'navigation': IconData(0xe55d, fontFamily: 'MaterialIcons'),
    'near_me': IconData(0xe569, fontFamily: 'MaterialIcons'),

    // --- tiempo / fecha
    'schedule': IconData(0xe8b5, fontFamily: 'MaterialIcons'),
    'alarm': IconData(0xe855, fontFamily: 'MaterialIcons'),
    'timer': IconData(0xe425, fontFamily: 'MaterialIcons'),
    'calendar_today': IconData(0xe935, fontFamily: 'MaterialIcons'),
    'event': IconData(0xe878, fontFamily: 'MaterialIcons'),

    // --- dispositivos / conectividad
    'wifi': IconData(0xe63e, fontFamily: 'MaterialIcons'),
    'bluetooth': IconData(0xe1a7, fontFamily: 'MaterialIcons'),
    'battery_full': IconData(0xe1a4, fontFamily: 'MaterialIcons'),
    'flash_on': IconData(0xe3e7, fontFamily: 'MaterialIcons'),
    'flashlight_on': IconData(0xf00b0, fontFamily: 'MaterialIcons'),
    'qr_code': IconData(0xef6b, fontFamily: 'MaterialIcons'),

    // --- seguridad
    'lock': IconData(0xe897, fontFamily: 'MaterialIcons'),
    'lock_open': IconData(0xe898, fontFamily: 'MaterialIcons'),
    'vpn_key': IconData(0xe0da, fontFamily: 'MaterialIcons'),
    'shield': IconData(0xea18, fontFamily: 'MaterialIcons'),
    'fingerprint': IconData(0xe90d, fontFamily: 'MaterialIcons'),

    // --- notificaciones
    'notifications': IconData(0xe7f4, fontFamily: 'MaterialIcons'),
    'notifications_active': IconData(0xe7f7, fontFamily: 'MaterialIcons'),
    'notifications_off': IconData(0xe7f6, fontFamily: 'MaterialIcons'),

    // --- indicadores
    'warning': IconData(0xe002, fontFamily: 'MaterialIcons'),
    'error': IconData(0xe000, fontFamily: 'MaterialIcons'),
    'info': IconData(0xe88e, fontFamily: 'MaterialIcons'),
    'help': IconData(0xe887, fontFamily: 'MaterialIcons'),

    // --- tablas / listas
    'table_chart': IconData(0xe265, fontFamily: 'MaterialIcons'),
    'list': IconData(0xe896, fontFamily: 'MaterialIcons'),
    'reorder': IconData(0xe8fe, fontFamily: 'MaterialIcons'),
    'filter_list': IconData(0xe152, fontFamily: 'MaterialIcons'),
    'sort': IconData(0xe164, fontFamily: 'MaterialIcons'),

    // --- e-commerce
    'shopping_cart': IconData(0xe8cc, fontFamily: 'MaterialIcons'),
    'shopping_bag': IconData(0xf1cc, fontFamily: 'MaterialIcons'),
    'payment': IconData(0xe8a1, fontFamily: 'MaterialIcons'),
    'attach_money': IconData(0xe227, fontFamily: 'MaterialIcons'),

    // --- transporte
    'directions_car': IconData(0xe531, fontFamily: 'MaterialIcons'),
    'local_shipping': IconData(0xe558, fontFamily: 'MaterialIcons'),

    // --- salud
    'healing': IconData(0xe3f3, fontFamily: 'MaterialIcons'),
    'medication': IconData(0xf05a, fontFamily: 'MaterialIcons'),
    'monitor_heart': IconData(0xf6dc, fontFamily: 'MaterialIcons'),

    // 👇👇👇 Añade aquí más entradas para tener “todos” en este mismo archivo
    // 'icon_name': IconData(0xCODEPOINT, fontFamily: 'MaterialIcons'),
  };

  late List<MapEntry<String, IconData>> _view =
      kAllMaterialIcons.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

  @override
  void initState() {
    super.initState();
    _q.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final raw = _q.text.trim().toLowerCase();
    if (raw.isEmpty) {
      setState(() {
        _view = kAllMaterialIcons.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
      });
      return;
    }
    final terms = <String>{raw, ...(_syn[raw] ?? const [])};
    bool matches(String name) => terms.any((t) => name.contains(t));
    setState(() {
      _view =
          kAllMaterialIcons.entries
              .where((e) => matches(e.key.toLowerCase()))
              .toList()
            ..sort((a, b) => a.key.compareTo(b.key));
    });
  }

  Future<void> _copiarInfo() async {
    if (_seleccionado == null) return;
    final family = _seleccionado!.fontFamily ?? 'MaterialIcons';
    final code = _seleccionado!.codePoint;
    await Clipboard.setData(ClipboardData(text: '$family U+$code'));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copiado al portapapeles')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Iconos (Material) • ${_view.length} íconos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _q,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Busca: "lupa", "engranaje", "delete", "home", …',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final cross = w >= 1200
                    ? 12
                    : w >= 1000
                    ? 10
                    : w >= 800
                    ? 8
                    : w >= 600
                    ? 6
                    : w >= 400
                    ? 5
                    : 4;
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cross,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: _view.length,
                  itemBuilder: (context, i) {
                    final e = _view[i];
                    final name = e.key;
                    final icon = e.value;
                    final selected = _seleccionado == icon;

                    return Material(
                      color: selected
                          ? theme.colorScheme.primary.withOpacity(0.12)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _seleccionado = icon),
                        onLongPress: _copiarInfo,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, size: 28),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
