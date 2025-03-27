import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tadiago/config/themes.dart';
import 'package:tadiago/utils/color.dart';

class Upside extends StatelessWidget {
  final String imgUrl;

  const Upside({
    super.key,
    required this.imgUrl,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Stack(
      children: [
        // Background image
        Container(
          width: size.width,
          height: size.height * 0.4,
          decoration: BoxDecoration(
            color: Colors.white,
            image: DecorationImage(
              image: AssetImage(imgUrl),
              fit: BoxFit.cover, // Occupe toute la largeur
              alignment: Alignment.topCenter, // Place l'image en haut
            ),
          ),
        ),
        // Icon button (overlay on the image)
        //iconButton(context),
      ],
    );
  }
}

class PageTitleBar extends StatelessWidget {
  final String title;
  const PageTitleBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 280.0),
      child: Container(
        width: double.infinity,
        //height: MediaQuery.of(context).size.height * 0.6,
        height: MediaQuery.of(context).size.height / 4,
        decoration: const BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(50),
              topRight: Radius.circular(50),
            )),
        child: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall,
          ),
        ),
      ),
    );
  }
}

// class RoudedInputFied extends StatelessWidget {
//   final String? hintText;
//   final IconData icon;
//   final TextEditingController? controller;
//   final String? Function(String?)? validator;
//   final TextInputType textInputType;

//   const RoudedInputFied({
//     super.key,
//     this.hintText,
//     this.icon = Icons.person,
//     this.controller,
//     this.validator,
//     this.textInputType = TextInputType.text,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return TextFieldContainer(
//       child: TextFormField(
//         controller: controller,
//         keyboardType: textInputType,
//         validator: validator,
//         cursorColor: Colors.grey,
//         decoration: InputDecoration(
//           icon: Icon(
//             icon,
//             color: redColor,
//           ),
//           hintText: hintText,
//           hintStyle: const TextStyle(fontFamily: 'OpenSans'),
//           border: InputBorder.none,
//           errorStyle: const TextStyle(height: 0),
//         ),
//       ),
//     );
//   }
// }

// class TextFieldContainer extends StatelessWidget {
//   final Widget? child;
//   const TextFieldContainer({super.key, this.child});

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.of(context).size;
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 10),
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
//       width: size.width * 0.8,
//       decoration: BoxDecoration(
//         color: kPrimaryLightColor,
//         borderRadius: BorderRadius.circular(29),
//       ),
//       child: child,
//     );
//   }
// }

class RoudedInputFied extends StatelessWidget {
  final String? hintText;
  final IconData icon;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType textInputType;

  const RoudedInputFied({
    super.key,
    this.hintText,
    this.icon = Icons.person,
    this.controller,
    this.validator,
    this.textInputType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFieldContainer(
      child: TextFormField(
        controller: controller,
        keyboardType: textInputType,
        validator: validator,
        cursorColor: Colors.blueGrey[700],
        style: const TextStyle(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          icon: Icon(
            icon,
            color: redColor,
          ),
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: 'Regular',
            fontSize: 14,
            color: Colors.black54,
          ),
          border: InputBorder.none,
          errorStyle: const TextStyle(height: 0),
        ),
      ),
    );
  }
}

class TextFieldContainer extends StatelessWidget {
  final Widget? child;

  const TextFieldContainer({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      width: MediaQuery.of(context).size.width * 0.75,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: child,
    );
  }
}

class RoudedPasswordFied extends StatefulWidget {
  final String placeholder;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const RoudedPasswordFied({
    super.key,
    required this.placeholder,
    this.controller,
    this.validator,
  });

  @override
  State<RoudedPasswordFied> createState() => _RoudedPasswordFiedState();
}

class _RoudedPasswordFiedState extends State<RoudedPasswordFied> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFieldContainer(
      child: TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        obscureText: _obscureText,
        cursorColor: Colors.blueGrey[700],
        decoration: InputDecoration(
          icon: Icon(
            Icons.lock,
            color: redColor,
          ),
          hintText: widget.placeholder,
          hintStyle: const TextStyle(fontFamily: 'Regular'),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility : Icons.visibility_off,
              color: redColor,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
          border: InputBorder.none,
          errorStyle: const TextStyle(height: 0),
        ),
      ),
    );
  }
}

class RoundedDropdownField extends StatelessWidget {
  final String? hintText;
  final IconData icon;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;
  final String? initialValue;
  const RoundedDropdownField({
    super.key,
    this.hintText,
    this.icon = Icons.person,
    required this.items,
    required this.onChanged,
    this.validator,
    this.initialValue,
    //required this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return TextFieldContainer(
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          icon: Icon(
            icon,
            color: redColor,
          ),
          hintText: hintText,
          hintStyle: const TextStyle(fontFamily: 'Reguar'),
          border: InputBorder.none,
        ),
        items: items
            .map((String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(fontFamily: 'Regular'),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        validator: validator,
        value: initialValue,
      ),
    );
  }
}

class RoudedButton extends StatelessWidget {
  final String text;
  final Color? textColor;
  final Function()? press;
  final bool isGoogleButton;

  const RoudedButton({
    super.key,
    this.press,
    this.textColor = Colors.white,
    required this.text,
    this.isGoogleButton = false, // Par défaut, ce n'est pas un bouton Google
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: size.width * 0.8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(29),
        child: newElevatedButton(),
      ),
    );
  }

  Widget newElevatedButton() {
    return ElevatedButton(
      onPressed: press,
      style: ElevatedButton.styleFrom(
        backgroundColor: isGoogleButton ? Colors.white : redColor,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        textStyle: const TextStyle(
          letterSpacing: 2,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Bold',
        ),
        side: isGoogleButton
            ? const BorderSide(color: Colors.grey) // Bordure grise pour Google
            : null,
        elevation: isGoogleButton ? 3 : 6, // Légère différence pour Google
      ),
      child: isGoogleButton
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons
                      .google, // Icône Google via font_awesome_flutter
                  color: redColor, // Couleur rouge pour Google
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.black, // Texte noir pour le bouton Google
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Text(
              text,
              style: TextStyle(color: textColor, fontSize: 16),
            ),
    );
  }
}

class UnderPart extends StatelessWidget {
  final String title;
  final String navigatorText;
  final Function() onTap;

  const UnderPart({
    super.key,
    required this.navigatorText,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyText,
        ),
        SizedBox(
          width: 20,
        ),
        InkWell(
          onTap: () {
            onTap();
          },
          child: Text(
            navigatorText,
            style: const TextStyle(
              color: kPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Regular',
            ),
          ),
        )
      ],
    );
  }
}
