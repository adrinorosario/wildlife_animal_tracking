import 'package:flutter/material.dart';
import 'package:wildlife_tracker/auth_services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wildlife_tracker/user_login.dart';
import 'dart:io';

class SavannahColors {
  static const Color beigeLight = Color(0xFFF6F1E1);
  static const Color beigeDark = Color(0xFFECE6D4);
  static const Color white = Color(0xFFFFFFFF);
  static const Color greenOlive = Color(0xFF4F5D2F);
  static const Color greenDeep = Color(0xFF3E4A24);
  static const Color orangeCaramel = Color(0xFFC88A3D);
  static const Color orangeSand = Color(0xFFE3B071);
  static const Color textBlack = Color(0xFF1F1F1F);
  static const Color textGrey = Color(0xFF4B4B4B);
}

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (selected != null) {
      setState(() {
        _profileImage = File(selected.path);
      });
    }
  }

  void _editName() {
    String currentName =
        authServices.value.currentUser?.displayName ?? "Ranger Smith";
    TextEditingController controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SavannahColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Edit Name",
          style: TextStyle(
            color: SavannahColors.textBlack,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: SavannahColors.greenOlive),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await authServices.value.updateUsername(
                  username: controller.text,
                );
                await authServices.value.currentUser?.reload();
                setState(() {});
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              "Save",
              style: TextStyle(
                color: SavannahColors.greenOlive,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = authServices.value.currentUser;
    final String displayName = user?.displayName ?? "Ranger Smith";
    final String photoUrl = user?.photoURL ?? "";

    return Scaffold(
      backgroundColor: SavannahColors.beigeLight,
      appBar: AppBar(
        backgroundColor: SavannahColors.beigeLight,
        title: const Text(
          "PROFILE",
          style: TextStyle(
            letterSpacing: 2.5,
            fontWeight: FontWeight.w900,
            color: SavannahColors.textBlack,
            fontSize: 14.0,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // --- USER INFO SECTION ---
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: SavannahColors.greenOlive,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (photoUrl.isNotEmpty
                                        ? NetworkImage(photoUrl)
                                        : null)
                                    as ImageProvider?,
                          child: (_profileImage == null && photoUrl.isEmpty)
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: SavannahColors.orangeCaramel,
                            child: Icon(
                              Icons.camera_alt,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _editName,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: SavannahColors.textBlack,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.edit,
                          size: 16,
                          color: SavannahColors.textGrey,
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    "PREMIUM PLAN",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: SavannahColors.orangeCaramel,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- STATS ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SavannahColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: SavannahColors.beigeDark),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem("24", "REPORTS"),
                  Container(
                    width: 1,
                    height: 40,
                    color: SavannahColors.beigeDark,
                  ),
                  _buildStatItem("1,250", "POINTS"),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- SETTINGS LIST ---
            _buildSettingsGroup([
              _buildSettingsTile(
                Icons.card_giftcard_rounded,
                "Claim Rewards",
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RewardsPage(),
                    ),
                  ); // REMOVED 'const'
                },
              ),
              _buildSettingsTile(
                Icons.notifications_none_rounded,
                "Notifications",
                () {},
              ),
              _buildSettingsTile(
                Icons.info_outline_rounded,
                "About Animap",
                () {},
              ),
              _buildSettingsTile(Icons.help_outline_rounded, "Support", () {}),
            ]),

            const SizedBox(height: 32),

            // --- SIGN OUT BUTTON ---
            TextButton.icon(
              onPressed: () async {
                await authServices.value.signOut();
                if (context.mounted) {
                  // This pushes the UserLogin page and removes all previous screens
                  // from the stack so the user can't "Go Back" into the app.
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => UserLogin(),
                    ), // No 'const'
                    (route) => false,
                  );
                }
              },
              icon: const Icon(
                Icons.logout_rounded,
                color: SavannahColors.orangeCaramel,
              ),
              label: const Text(
                "Sign Out",
                style: TextStyle(
                  color: SavannahColors.orangeCaramel,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: SavannahColors.greenDeep,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: SavannahColors.textGrey,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGroup(List<Widget> tiles) => Container(
    decoration: BoxDecoration(
      color: SavannahColors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: SavannahColors.beigeDark),
    ),
    child: Column(children: tiles),
  );

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: SavannahColors.greenOlive),
      title: Text(
        title,
        style: const TextStyle(
          color: SavannahColors.textBlack,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: SavannahColors.beigeDark,
      ),
      onTap: onTap,
    );
  }
}

// ... RewardsPage remains the same
// --- REWARDS PAGE (Placeholder content) ---

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> rewards = [
      {
        "name": "Netflix Gift Card",
        "points": "500 pts",
        "img":
            "https://upload.wikimedia.org/wikipedia/commons/0/08/Netflix_2015_logo.svg",
      },

      {
        "name": "Spotify Premium",
        "points": "300 pts",
        "img":
            "https://upload.wikimedia.org/wikipedia/commons/1/19/Spotify_logo_without_text.svg",
      },

      {
        "name": "Amazon Voucher",
        "points": "1000 pts",
        "img":
            "https://upload.wikimedia.org/wikipedia/commons/a/a9/Amazon_logo.svg",
      },
    ];

    return Scaffold(
      backgroundColor: SavannahColors.beigeLight,

      appBar: AppBar(
        title: const Text(
          "CLAIM REWARDS",
          style: TextStyle(
            letterSpacing: 2.0,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),

        centerTitle: true,

        backgroundColor: Colors.transparent,

        elevation: 0,
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(24),

        itemCount: rewards.length,

        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),

            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: SavannahColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SavannahColors.beigeDark),
            ),

            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: SavannahColors.beigeLight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.network(rewards[index]["img"]!),
                ),
              ),

              title: Text(
                rewards[index]["name"]!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SavannahColors.textBlack,
                ),
              ),

              subtitle: Text(
                rewards[index]["points"]!,
                style: const TextStyle(
                  color: SavannahColors.orangeCaramel,
                  fontWeight: FontWeight.bold,
                ),
              ),

              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SavannahColors.greenOlive,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                onPressed: () {},

                child: const Text("Claim"),
              ),
            ),
          );
        },
      ),
    );
  }
}
