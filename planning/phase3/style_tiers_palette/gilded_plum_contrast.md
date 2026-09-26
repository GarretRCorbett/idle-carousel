# Gilded Plum contrast measurements

Text contrast uses WCAG linear sRGB luminance. Kenney face sampled at texture center, multiplied by tint. Opaque panels.

Button normal: text #292333 / face #bda060 = 6.03:1

Button hover: text #292333 / face #bfa46b = 6.35:1

Button pressed: text #292333 / face #c2a976 = 6.68:1

Button disabled: text #c6bdd0 / face #453f50 = 5.57:1

BlueButton normal: text #fff4dc / face #604a7e = 6.92:1

BlueButton hover: text #fff4dc / face #584474 = 7.69:1

BlueButton pressed: text #fff4dc / face #503e6a = 8.55:1

BlueButton disabled: text #c6bdd0 / face #453f50 = 5.57:1

CrankButton normal: text #fff4dc / face #833648 = 7.43:1

CrankButton hover: text #fff4dc / face #783242 = 8.22:1

CrankButton pressed: text #fff4dc / face #6e2e3c = 9.10:1

CrankButton disabled: text #c6bdd0 / face #453f50 = 5.57:1

body / panel: 12.76:1

muted / panel: 7.69:1

gold / panel: 7.45:1

## Tier sanity check

| Tier | Tint | Darker outline C | Deuteranopia | Protanopia |
|---|---|---|---|---|
| Grey | #99999e | #313133 | #98999e | #989a9e |
| Green | #9ee659 | #33491d | #e5d064 | #efd549 |
| Yellow | #ffe04d | #524818 | #fee555 | #f6db36 |
| Orange | #ff942e | #522f0f | #ceb82e | #b4a01a |
| Red | #f24038 | #4e1412 | #a29230 | #766b35 |
| Charcoal | #33333b | #101013 | #31333a | #31343b |

Green/Yellow luminance separation: deuteranopia 1.23:1; protanopia 1.06:1. They remain confusable.
