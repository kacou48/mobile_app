import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tadiago/accounts/providers/auth_providers.dart';
import 'package:tadiago/utils/color.dart';
//import 'package:tadiago/utils/constant.dart';

//myBaseUrl
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 30, bottom: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.topRight,
                colors: [
                  Color(0xffDC3545),
                  kPrimaryLightColor,
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: user?.imageUrl != null
                        ? NetworkImage(
                            '${user?.imageUrl}') //NetworkImage('$myBaseUrl${user?.imageUrl}')
                        : const AssetImage('assets/images/defaultProfile.png'),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  '${user?.name} ${user?.firstname}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Bold'),
                ),
                Text(
                  'Bon retour parmi nous',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Bold',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 2),
                children: [
                  _buildMenuItem(
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () => Navigator.pop(context),
                    conttext: context,
                  ),
                  _buildMenuItem(
                    icon: Icons.person_2_outlined,
                    title: 'Mon Profil',
                    onTap: () {
                      Navigator.pushNamed(context, '/tableau_de_bord',
                          arguments: {
                            'id': user?.id,
                          });
                    },
                    conttext: context,
                  ),
                  _buildMenuItem(
                    icon: Icons.message_outlined,
                    title: 'Mes Messages',
                    onTap: () {
                      Navigator.pushNamed(context, '/user_notification');
                    },
                    conttext: context,
                  ),
                  _buildMenuItem(
                    icon: Icons.favorite_border_outlined,
                    title: 'Favorites',
                    onTap: () {
                      Navigator.pushNamed(context, '/mes_preferences',
                          arguments: {
                            'id': user?.id,
                          });
                    },
                    conttext: context,
                  ),
                  // _buildMenuItem(
                  //   icon: Icons.ads_click_outlined,
                  //   title: 'Mes Annonces',
                  //   onTap: () => {
                  //     Navigator.pushNamed(context, '/mes_annones', arguments: {
                  //       'id': user?.id,
                  //     })
                  //   },
                  //   conttext: context,
                  // ),
                  _buildMenuItem(
                    icon: Icons.dashboard_customize,
                    title: 'Tableau de bord',
                    onTap: () {
                      Navigator.pushNamed(context, '/tableau_de_bord',
                          arguments: {
                            'id': user?.id,
                          });
                    },
                    conttext: context,
                  ),
                  _buildMenuItem(
                    icon: Icons.call_end_outlined,
                    title: 'Nous Contacter',
                    onTap: () {
                      Navigator.pushNamed(context, '/nous_contacter');
                    },
                    conttext: context,
                  ),
                  _buildMenuItem(
                    icon: Icons.policy_outlined,
                    title: 'Politique de Confidentialité',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/policy_terme',
                      );
                    },
                    conttext: context,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: FilledButton.icon(
              onPressed: () => _showLogoutDialog(context),
              style: FilledButton.styleFrom(
                  backgroundColor: redColor,
                  minimumSize: const Size(double.infinity, 40)),
              label: const Text('Se Deconnecter'),
              icon: const Icon(Icons.login),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required BuildContext conttext,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.black87,
      ),
      title: Text(
        title,
        style: TextStyle(color: Colors.black87),
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(
                'Deconnexion',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),
              content: const Text("Etre vous sure de vouloir vous deconecter?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Annuler',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: Colors.green,
                          ),
                    )),
                TextButton(
                    onPressed: () async {
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      await authProvider.logout(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: redColor,
                    ),
                    child: const Text(
                      'Confirmer',
                      style: TextStyle(color: Colors.white),
                    )),
              ],
            ));
  }
}
