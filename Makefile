# make app icon
app_icon:
	flutter pub pub run flutter_launcher_icons:main

# scan for localization strings
gen_arb:
	flutter pub pub run intl_translation:extract_to_arb --output-dir=lib/l10n lib/intl.dart

# generate dart file from arb resources
gen_dart:
	flutter packages pub run intl_translation:generate_from_arb --output-dir=lib/l10n \
	--no-use-deferred-loading lib/intl.dart lib/l10n/intl_*.arb