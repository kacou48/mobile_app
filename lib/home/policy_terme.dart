import 'package:flutter/material.dart';
import 'package:tadiago/components/costum_app_bar.dart';

// class PolicyTerme extends StatelessWidget {
//   const PolicyTerme({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(
//         title: "Politique de confidentialité",
//       ),
//       body: Container(),
//     );
//   }
// }

class PolicyTerme extends StatelessWidget {
  const PolicyTerme({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Politique de Confidentialité',
      //       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      // ),
      appBar: CustomAppBar(
        title: "Politique de confidentialité",
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mise à jour : 10 Juin 2024',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600])),
            SizedBox(height: 10),
            Text('Politique de Confidentialité',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(
                'Engagement envers votre vie privée et protection de vos données personnelles',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            _buildSection("Quelles informations collectons-nous ?",
                "Nous collectons des informations personnelles lorsque vous vous inscrivez sur notre site..."),
            _buildSection("Comment utilisons-nous vos informations ?",
                "Les informations que nous collectons sont essentielles pour le bon fonctionnement de notre plateforme..."),
            _buildSection("Partageons-nous vos informations avec des tiers ?",
                "Nous nous engageons à protéger votre vie privée et à ne pas partager vos informations personnelles..."),
            _buildSection("Comment protégeons-nous vos données ?",
                "La sécurité de vos données est une priorité pour nous. Nous avons mis en place des mesures de sécurité techniques et organisationnelles..."),
            _buildSection("Quels sont vos droits concernant vos données ?",
                "En tant qu'utilisateur, vous disposez de droits concernant vos données personnelles. Vous avez le droit d'accéder à vos informations..."),
            _buildSection(
                "Comment contacter notre équipe de protection des données ?",
                "Si vous avez des questions ou des préoccupations concernant notre politique de confidentialité..."),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 5),
          Text(content,
              style: TextStyle(fontSize: 14, color: Colors.grey[800])),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
