import 'dart:math';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/models.dart';

class UserLevelAvatar extends StatelessWidget {
  const UserLevelAvatar({
    super.key,
    required this.user,
    required this.radius,
  });

  final Usuario user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final progress = user.exp / max(1, user.expTotalNivel);
    return SizedBox(
      width: (radius + 6) * 2,
      height: (radius + 6) * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: AppColors.roxoProfundo,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.verdeLima,
              ),
            ),
          ),
          CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.fundoCard,
            child: CircleAvatar(
              radius: radius - 4,
              backgroundImage: AssetImage(
                "assets/avatares/${user.imagemPerfil}",
              ),
              onBackgroundImageError: (_, __) {},
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.roxoProfundo,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fundoEscuro, width: 2),
              ),
              child: Text(
                user.nivel.toString(),
                style: const TextStyle(
                  fontFamily: 'Jersey 10',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}