"""Add translated strings to the app in one step.

Usage (from the project root):
    python3 tool/add_strings.py strings.json

strings.json maps each new key to its text in every language the app has, for example:
    {"thankYou": {"en": "Thank you!", "es": "¡Gracias!", "fr": "Merci !"}}

Updates every lib/l10n/app_<lang>.arb file and lib/l10n/translations.dart, then run
`fvm flutter gen-l10n`. Keys that already exist are left alone. To add a new language, add an
empty app_<lang>.arb with the same keys and include that language in each entry.
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib", "l10n")


def main(path):
    strings = json.load(open(path, encoding="utf-8"))
    arb_files = sorted(glob.glob(os.path.join(ROOT, "app_*.arb")))
    for arb in arb_files:
        lang = os.path.basename(arb)[len("app_"):-len(".arb")]
        raw = open(arb, encoding="utf-8").read()
        data = json.loads(raw)
        indent = 4 if "\n    \"" in raw else 2
        for key, values in strings.items():
            if lang not in values:
                sys.exit(f"Missing '{lang}' text for {key}")
            data.setdefault(key, values[lang])
        open(arb, "w", encoding="utf-8").write(json.dumps(data, ensure_ascii=False, indent=indent) + "\n")

    dart = os.path.join(ROOT, "translations.dart")
    s = open(dart, encoding="utf-8").read()
    for key in strings:
        if re.search(rf"\bString {key} = ERROR;", s):
            continue
        field = list(re.finditer(r"^  String \w+ = ERROR;\n", s, re.M))[-1]
        s = s[:field.end()] + f"  String {key} = ERROR;\n" + s[field.end():]
        init = list(re.finditer(r"^    \w+ =  ?AppLocalizations\.of\(context\)\?\.\w+ \?\? \w+;\n", s, re.M))[-1]
        s = s[:init.end()] + f"    {key} =  AppLocalizations.of(context)?.{key} ?? {key};\n" + s[init.end():]
        case = list(re.finditer(r'^      case "\w+": return \w+;\n', s, re.M))[-1]
        s = s[:case.end()] + f'      case "{key}": return {key};\n' + s[case.end():]
    open(dart, "w", encoding="utf-8").write(s)
    print("Added:", ", ".join(strings))


if __name__ == "__main__":
    main(sys.argv[1])
