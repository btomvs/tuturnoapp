import 'package:flutter/material.dart';
import 'package:tuturnoapp/core/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [fondo(size), logoLogin(), cuadroLogin(context)],
        ),
      ),
    );
  }

  SingleChildScrollView cuadroLogin(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 550),
          Container(
            padding: EdgeInsets.all(20),
            margin: EdgeInsets.symmetric(horizontal: 30),
            width: double.infinity,
            //height: 400,
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
              children: [
                const SizedBox(height: 5),
                Text(
                  'Turno',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: AppColors.claro),
                ),
                const SizedBox(height: 30),

                const SizedBox(height: 30),
              ],
            ),
            
          ),
        ],
      ),
    );
  }

  Container logoLogin() {
    return Container(
      margin: EdgeInsets.only(top: 100),
      width: double.infinity,
      child: Icon(Icons.account_circle, size: 100, color: AppColors.claro),
    );
  }

  Container fondo(Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 1,
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
