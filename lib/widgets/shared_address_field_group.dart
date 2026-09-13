// lib/widgets/shared_address_field_group.dart
//
// STRUCTURED ADDRESS PASS: shared six-field address input — Address Line 1,
// Address Line 2, City, State/Province, Country, ZIP/Postal Code — used by
// step_customers.dart (Customer Address) and step_templates.dart (Business
// Address + Sender Address), replacing the old single free-text Address
// field on all three. All six fields are stacked full-width (no side-by-
// side pairing), matching this app's existing single-column field layout.
// Built on SharedSheetField/sharedFieldCounter (shared_sheet_field.dart) so
// every address field gets the exact same styling, character counter,
// "(Optional)" label suffix and keyboard-avoidance auto-scroll as every
// other field on these sheets.
//
// See lib/models/address_info.dart for the AddressInfo value type these
// controllers read into via toAddressInfo().

import 'package:flutter/material.dart';

import 'shared_sheet_field.dart';
import '../models/address_info.dart';

/// Bundles the six TextEditingControllers for one address (Business,
/// Sender, or Customer). Owned/disposed by the host sheet's State object,
/// the same way every other controller on that sheet already is.
class AddressFieldControllers {
  final TextEditingController line1;
  final TextEditingController line2;
  final TextEditingController city;
  final TextEditingController state;
  final TextEditingController country;
  final TextEditingController postalCode;

  AddressFieldControllers({
    required this.line1,
    required this.line2,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
  });

  /// Seeds all six controllers from an existing AddressInfo (or blank
  /// fields if [initial] is null).
  factory AddressFieldControllers.seeded(AddressInfo? initial) {
    final a = initial ?? AddressInfo();
    return AddressFieldControllers(
      line1: TextEditingController(text: a.line1),
      line2: TextEditingController(text: a.line2),
      city: TextEditingController(text: a.city),
      state: TextEditingController(text: a.state),
      country: TextEditingController(text: a.country),
      postalCode: TextEditingController(text: a.postalCode),
    );
  }

  /// Reads the current text of all six controllers back into an
  /// AddressInfo — call this in the host sheet's _save().
  AddressInfo toAddressInfo() => AddressInfo(
        line1: line1.text.trim(),
        line2: line2.text.trim(),
        city: city.text.trim(),
        state: state.text.trim(),
        country: country.text.trim(),
        postalCode: postalCode.text.trim(),
      );

  List<TextEditingController> get all =>
      [line1, line2, city, state, country, postalCode];

  void addListenerToAll(VoidCallback listener) {
    for (final c in all) {
      c.addListener(listener);
    }
  }

  void dispose() {
    for (final c in all) {
      c.dispose();
    }
  }
}

class AddressFieldGroup extends StatelessWidget {
  final AddressFieldControllers controllers;
  final Color accent;

  const AddressFieldGroup({
    super.key,
    required this.controllers,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SharedSheetField(
          ctrl: controllers.line1,
          label: 'Address Line 1',
          hint: 'e.g. 123 Commerce Ave',
          icon: Icons.location_on_rounded,
          max: 60,
          accent: accent,
        ),
        sharedFieldCounter(context, controllers.line1.text.length, 60),
        const SizedBox(height: 12),
        SharedSheetField(
          ctrl: controllers.line2,
          label: 'Address Line 2',
          hint: 'e.g. Suite 4 / Apt 2B',
          icon: Icons.location_on_outlined,
          max: 60,
          accent: accent,
        ),
        sharedFieldCounter(context, controllers.line2.text.length, 60),
        const SizedBox(height: 12),
        SharedSheetField(
          ctrl: controllers.city,
          label: 'City',
          hint: 'e.g. Auckland',
          icon: Icons.location_city_rounded,
          max: 40,
          accent: accent,
        ),
        sharedFieldCounter(context, controllers.city.text.length, 40),
        const SizedBox(height: 12),
        SharedSheetField(
          ctrl: controllers.state,
          label: 'State / Province',
          hint: 'e.g. Auckland',
          icon: Icons.map_outlined,
          max: 40,
          accent: accent,
        ),
        sharedFieldCounter(context, controllers.state.text.length, 40),
        const SizedBox(height: 12),
        SharedSheetField(
          ctrl: controllers.country,
          label: 'Country',
          hint: 'e.g. New Zealand',
          icon: Icons.public_rounded,
          max: 40,
          accent: accent,
        ),
        sharedFieldCounter(context, controllers.country.text.length, 40),
        const SizedBox(height: 12),
        SharedSheetField(
          ctrl: controllers.postalCode,
          label: 'ZIP / Postal Code',
          hint: 'e.g. 1010',
          icon: Icons.markunread_mailbox_outlined,
          max: 16,
          accent: accent,
        ),
        sharedFieldCounter(context, controllers.postalCode.text.length, 16),
      ],
    );
  }
}