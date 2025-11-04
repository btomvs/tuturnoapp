import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ----- Paleta de Colores -----
import 'package:tuturnoapp/core/app_colors.dart';

// ----- Widgets -----
import 'package:tuturnoapp/widgets/avatar.dart';
import 'package:tuturnoapp/widgets/boton_float.dart';
import 'package:tuturnoapp/widgets/bienvenido.dart';
import 'package:tuturnoapp/widgets/boton_entrada.dart';
import 'package:tuturnoapp/widgets/reloj.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  final _picker = ImagePicker();

  Future<void> tomarFoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> elegirGaleria() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) setState(() => _image = File(picked.path));
  }

  void elegirFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.oscuro,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.claro,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.claro,
              ),
              title: const Text(
                'Tomar foto',
                style: TextStyle(color: AppColors.claro),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await tomarFoto();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.claro,
              ),
              title: const Text(
                'Elegir de la galería',
                style: TextStyle(color: AppColors.claro),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await elegirGaleria();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      floatingActionButton: BotonFloatAuth(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // ----- Posicion Fondo -----
            fondo(size),
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: AvatarPicker(
                  radius: 60,
                  imageFile: _image,
                  onTap: elegirFoto,
                  backgroundColor: AppColors.claro,
                  iconColor: AppColors.oscuro,
                  showEditBadge: true,
                  editBadgeColor: AppColors.primary,
                  editIconColor: AppColors.claro,
                ),
              ),
            ),

            // ----- Bienvenido -----
            Positioned(
              top: 200,
              left: 0,
              right: 0,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: const Bienvenido(),
                ),
              ),
            ),

            // ----- Reloj -----
            Positioned(
              left: 16,
              right: 16,
              bottom: 500,
              child: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snap) {
                  final u = snap.data;
                  if (u == null) return const SizedBox.shrink();
                  return Center(child: RelojJornada(uid: u.uid));
                },
              ),
            ),

            // ----- Boton Entrada -----
            Positioned(
              left: 16,
              right: 16,
              bottom: 150,
              child: SafeArea(
                top: false,
                child: BotonEntrada(
                  onDone: (tipo, ok, error) {
                    debugPrint('Marcaje $tipo => ok=$ok ${error ?? ""}');
                  },
                ),
              ),
            ),

            // ----- Posicion Cuadro Turno -----
            Positioned(
              bottom: 350,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: cuadroHorario(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----- Cuadro Turno -----
  Widget cuadroHorario(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 30),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.oscuro,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Turno',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppColors.claro),
          ),
        ],
      ),
    );
  }

  // ----- Fondo -----
  Widget fondo(Size size) {
    return Container(
      width: double.infinity,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.claro],
        ),
      ),
    );
  }
}
