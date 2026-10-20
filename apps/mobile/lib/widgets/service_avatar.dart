import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

IconData serviceIcon(ServiceType service) => switch (service) {
  ServiceType.boarding => Icons.night_shelter_outlined,
  ServiceType.grooming => Icons.content_cut,
  ServiceType.vetCheckup => Icons.medical_services_outlined,
  ServiceType.walk => Icons.directions_walk,
};

class ServiceAvatar extends StatelessWidget {
  const ServiceAvatar({super.key, required this.service, this.size = 44});

  final ServiceType service;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(size * 0.32)),
      child: Icon(serviceIcon(service), size: size * 0.5, color: scheme.onPrimaryContainer),
    );
  }
}
