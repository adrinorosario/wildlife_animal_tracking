import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wildlife_tracker/theme_colors.dart';
import 'package:intl/intl.dart';

class AlertNotifications extends StatefulWidget {
  const AlertNotifications({super.key});

  @override
  _AlertNotificationsState createState() => _AlertNotificationsState();
}

class _AlertNotificationsState extends State<AlertNotifications> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SavannahColors.beigeLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "RECENT SIGHTINGS",
          style: TextStyle(
            letterSpacing: 2.0,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: SavannahColors.textBlack,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('animal_sightings')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: SavannahColors.greenOlive,
              ),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      "Error loading sightings",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red[300],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: SavannahColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pets_rounded,
                    size: 64,
                    color: SavannahColors.orangeSand.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No sightings yet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: SavannahColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Add a pin on the map to report\na wildlife sighting.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: SavannahColors.textGrey,
                    ),
                  ),
                ],
              ),
            );
          }

          // Data state
          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _SightingCard(data: data);
            },
          );
        },
      ),
    );
  }
}

class _SightingCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _SightingCard({required this.data});

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Just now";
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  Color _statusColor(String pinType) {
    switch (pinType.toLowerCase()) {
      case 'injured animal':
        return SavannahColors.orangeCaramel;
      case 'animal sighting':
        return SavannahColors.greenOlive;
      case 'displaced animal':
        return SavannahColors.orangeSand;
      case 'lost in urban area':
        return const Color(0xFF8B7355);
      default:
        return SavannahColors.greenOlive;
    }
  }

  IconData _statusIcon(String pinType) {
    switch (pinType.toLowerCase()) {
      case 'injured animal':
        return Icons.healing_rounded;
      case 'animal sighting':
        return Icons.visibility_rounded;
      case 'displaced animal':
        return Icons.swap_horiz_rounded;
      case 'lost in urban area':
        return Icons.location_city_rounded;
      default:
        return Icons.pets_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl'] as String? ?? '';
    final species = data['species'] as String? ?? 'Unknown';
    final pinType = data['pinType'] as String? ?? 'Animal sighting';
    final latitude = data['latitude'] as num? ?? 0.0;
    final longitude = data['longitude'] as num? ?? 0.0;
    final sirenActive = data['sirenActive'] as bool? ?? false;
    final timestamp = data['timestamp'] as Timestamp?;

    final statusColor = _statusColor(pinType);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          if (imageUrl.isNotEmpty)
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: SavannahColors.beigeDark,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: SavannahColors.greenOlive,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: SavannahColors.beigeDark,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 40,
                        color: SavannahColors.textGrey,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Content section
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Species name & siren badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        species,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: SavannahColors.textBlack,
                        ),
                      ),
                    ),
                    if (sirenActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: Colors.red,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "SIREN",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.red,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(pinType), size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        pinType,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Location & timestamp
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: SavannahColors.textGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${(latitude as double).toStringAsFixed(4)}, ${(longitude as double).toStringAsFixed(4)}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: SavannahColors.textGrey,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: SavannahColors.textGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: SavannahColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
