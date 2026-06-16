import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:skyride/Screens/profile/aichat.dart';
import 'package:skyride/Screens/profile/edit.dart';
import 'package:skyride/Screens/profile/notification.dart';
import 'package:skyride/Screens/profile/security.dart';
import 'package:skyride/Screens/profile/view.dart';
import 'package:skyride/auth/login.dart';
import 'package:skyride/services/skyride_api.dart';
import 'package:skyride/database/session_helper.dart';
import 'package:skyride/navigation/navigation.dart';
import 'package:skyride/theme/app_theme.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await SessionHelper.getCurrentUser();
    if (mounted) setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppTheme.profileAppBar("Profile"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            ProfilePic(imagePath: _user?['image'] as String?),
            if (_user != null) ...[
              const SizedBox(height: 8),
              Text(
                _user!['username'] as String? ?? '',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                _user!['email'] as String? ?? '',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
            const SizedBox(height: 20),
            ProfileMenu(
              text: "My Account",
              icon: Icons.account_circle,
              press: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => ViewAccountScreen()));
                _loadUser();
              },
            ),
            ProfileMenu(
              text: "Edit Account",
              icon: Icons.manage_accounts,
              press: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateAccountScreen()));
                _loadUser();
              },
            ),
            ProfileMenu(
              text: "Settings",
              icon: Icons.settings,
              press: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
              },
            ),
            ProfileMenu(
              text: "Help Center",
              icon: Icons.help_outline,
              press: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
              },
            ),
            ProfileMenu(
              text: "Contact Us",
              icon: Icons.contact_mail,
              press: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen()));
              },
            ),
            ProfileMenu(
              text: "Switch Account",
              icon: Icons.swap_horiz,
              press: () => _switchAccount(context),
            ),
            ProfileMenu(
              text: "Delete My Account",
              icon: Icons.delete_forever,
              isDestructive: true,
              press: () => _deleteAccount(context),
            ),
            ProfileMenu(
              text: "Log Out",
              icon: Icons.logout,
              press: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePic extends StatelessWidget {
  final String? imagePath;

  const ProfilePic({super.key, this.imagePath});

  @override
  Widget build(BuildContext context) {
    ImageProvider image;
    if (imagePath != null && imagePath!.isNotEmpty) {
      image = NetworkImage(imagePath!);
    } else {
      image = const AssetImage("assets/images/user1.jpg");
    }

    return SizedBox(
      height: 115,
      width: 115,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(backgroundImage: image),
          Positioned(
            right: -16,
            bottom: 0,
            child: SizedBox(
              height: 36,
              width: 36,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                    side: const BorderSide(color: Colors.white),
                  ),
                  backgroundColor: AppTheme.cardBackground,
                ),
                onPressed: () {},
                child: SvgPicture.string(cameraIcon),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ProfileMenu extends StatelessWidget {
  const ProfileMenu({
    super.key,
    required this.text,
    this.svgIcon,
    this.icon,
    this.press,
    this.isDestructive = false,
  });

  final String text;
  final String? svgIcon;
  final IconData? icon;
  final VoidCallback? press;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : AppTheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: AppTheme.cardBackground,
        ),
        onPressed: press,
        child: Row(
          children: [
            if (svgIcon != null)
              SvgPicture.asset(
                svgIcon!,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                width: 22,
              )
            else if (icon != null)
              Icon(icon, color: color, size: 22),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: isDestructive ? Colors.red : AppTheme.textSecondary),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDestructive ? Colors.red : AppTheme.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _switchAccount(BuildContext context) async {
  final accounts = await SessionHelper.getQuickSwitchAccounts();
  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Switch Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Select an account to continue.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: accounts.length,
              itemBuilder: (_, i) {
                final acc = accounts[i];
                final role = acc['role'] as String? ?? 'user';
                String roleLabel = role == 'machanic' ? 'Mechanic' : role == 'fuelpump' ? 'Fuel Pump' : 'User';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withOpacity(0.15),
                    child: Icon(
                      role == 'machanic' ? Icons.build : role == 'fuelpump' ? Icons.local_gas_station : Icons.person,
                      color: AppTheme.primary,
                    ),
                  ),
                  title: Text(acc['username'] as String? ?? ''),
                  subtitle: Text('$roleLabel • ${acc['email']}'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final ok = await SessionHelper.switchAccount(
                      acc['email'] as String,
                      acc['password'] as String,
                    );
                    if (ok && context.mounted) {
                      Fluttertoast.showToast(msg: 'Switched to ${acc['username']}');
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => Navigationbar(sessionKey: acc['id'] as String)),
                        (route) => false,
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _logout(BuildContext context) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Logout', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (shouldLogout == true) {
    await SessionHelper.clearSession();
    Fluttertoast.showToast(
      msg: "Logged out successfully.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    }
  }
}

Future<void> _deleteAccount(BuildContext context) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Account'),
      content: const Text(
        'Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be lost.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  if (shouldDelete == true) {
    final userId = await SessionHelper.getCurrentUserId();
    if (userId != null) {
      await SkyRideApi.instance.deleteAccount(userId);
    }
    await SessionHelper.clearSession();

    Fluttertoast.showToast(
      msg: "Account deleted successfully.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    }
  }
}

const cameraIcon =
    '''<svg width="20" height="16" viewBox="0 0 20 16" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M10 12.0152C8.49151 12.0152 7.26415 10.8137 7.26415 9.33902C7.26415 7.86342 8.49151 6.6619 10 6.6619C11.5085 6.6619 12.7358 7.86342 12.7358 9.33902C12.7358 10.8137 11.5085 12.0152 10 12.0152ZM10 5.55543C7.86698 5.55543 6.13208 7.25251 6.13208 9.33902C6.13208 11.4246 7.86698 13.1217 10 13.1217C12.133 13.1217 13.8679 11.4246 13.8679 9.33902C13.8679 7.25251 12.133 5.55543 10 5.55543ZM18.8679 13.3967C18.8679 14.2226 18.1811 14.8935 17.3368 14.8935H2.66321C1.81887 14.8935 1.13208 14.2226 1.13208 13.3967V5.42346C1.13208 4.59845 1.81887 3.92664 2.66321 3.92664H4.75C5.42453 3.92664 6.03396 3.50952 6.26604 2.88753L6.81321 1.41746C6.88113 1.23198 7.06415 1.10739 7.26604 1.10739H12.734C12.9358 1.10739 13.1189 1.23198 13.1877 1.41839L13.734 2.88845C13.966 3.50952 14.5755 3.92664 15.25 3.92664H17.3368C18.1811 3.92664 18.8679 4.59845 18.8679 5.42346V13.3967ZM17.3368 2.82016H15.25C15.0491 2.82016 14.867 2.69466 14.7972 2.50917L14.2519 1.04003C14.0217 0.418041 13.4113 0 12.734 0H7.26604C6.58868 0 5.9783 0.418041 5.74906 1.0391L5.20283 2.50825C5.13302 2.69466 4.95094 2.82016 4.75 2.82016H2.66321C1.19434 2.82016 0 3.98846 0 5.42346V13.3967C0 14.8326 1.19434 16 2.66321 16H17.3368C18.8057 16 20 14.8326 20 13.3967V5.42346C20 3.98846 18.8057 2.82016 17.3368 2.82016Z" fill="#757575"/>
</svg>
''';
