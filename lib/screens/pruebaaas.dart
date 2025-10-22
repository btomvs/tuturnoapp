import 'package:flutter/material.dart';

class PersonIconsGallery extends StatelessWidget {
  const PersonIconsGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <({String name, IconData icon})>[
      (name: 'person', icon: Icons.person),
      (name: 'person_outline', icon: Icons.person_outline),
      (name: 'person_2', icon: Icons.person_2),
      (name: 'person_3', icon: Icons.person_3),
      (name: 'person_4', icon: Icons.person_4),
      (name: 'person_add', icon: Icons.person_add),
      (name: 'person_remove', icon: Icons.person_remove),
      (name: 'person_off', icon: Icons.person_off),
      (name: 'person_pin', icon: Icons.person_pin),
      (name: 'person_search', icon: Icons.person_search),

      (name: 'people', icon: Icons.people),
      (name: 'people_alt', icon: Icons.people_alt),
      (name: 'people_outline', icon: Icons.people_outline),
      (name: 'group', icon: Icons.group),
      (name: 'group_add', icon: Icons.group_add),
      (name: 'supervisor_account', icon: Icons.supervisor_account),

      (name: 'account_circle', icon: Icons.account_circle),
      (name: 'account_box', icon: Icons.account_box),
      (name: 'manage_accounts', icon: Icons.manage_accounts),
      (name: 'admin_panel_settings', icon: Icons.admin_panel_settings),

      (name: 'face', icon: Icons.face),
      (name: 'face_2', icon: Icons.face_2),
      (name: 'face_3', icon: Icons.face_3),
      (name: 'face_4', icon: Icons.face_4),
      (name: 'face_5', icon: Icons.face_5),
      (name: 'face_6', icon: Icons.face_6),

      (name: 'man', icon: Icons.man),
      (name: 'woman', icon: Icons.woman),
      (name: 'boy', icon: Icons.boy),
      (name: 'girl', icon: Icons.girl),
      (name: 'pregnant_woman', icon: Icons.pregnant_woman),
      (name: 'elderly', icon: Icons.elderly),
      (name: 'elderly_woman', icon: Icons.elderly_woman),
      (name: 'transgender', icon: Icons.transgender),
      (name: 'wheelchair_pickup', icon: Icons.wheelchair_pickup),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Íconos de Persona (Material)')),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,              // cambia a 3 si quieres íconos más grandes
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: .9,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final it = items[i];
          return _IconTile(name: it.name, icon: it.icon);
        },
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final String name;
  final IconData icon;
  const _IconTile({required this.name, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
