# Hue Chroma Luminance Color Space

The HLS colorspace is more adapted to human visual perception than the RGB rainbow, which is suited to
computer representations. For instance, the human eye has five times more receptors for luminance than for
colour.

The colorspace was introduced by [Sarifuddin and Missaoui](https://pdfs.semanticscholar.org/206c/a4c4bb4a5b6c7b614b8a8f4461c0c6b87710.pdf?_ga=2.9335922.611436885.1505557968-1463367387.1505557968)
and is also described on [the HCL website](http://hclwizard.org/why-hcl/).

The algorithms here are taken from [chroma.js](https://github.com/gka/chroma.js).

Currently, only the RGB <-> HCL algorithms are implemented.

# Usage
```
use v6.*;
use Colorspace::HCL;

for
    [0xd2, 0x69, 0x1d], # almost Chocolate, CSS3
    [210, 105, 29], # same but in decimal
    '#d2691d', # in html notation
    [0.823529, 0.411765, 0.113725] #same normalized to unity
    # note that signature 1,1,1 could be ambiguous, so normalised to unity must be real
    # max 255 form must be integers
   {
        say .&rgb-to-hcl
   }
# 57 68 56
# 57 68 56
# 57 68 56
# 57 68 56

say hcl-2-rgb( 57, 68, 56 ); # default output format is html
# '#d2691d'
for <html trip-hex trip-dec trip-norm> {
    say hcl-to-rgb( 57, 68, 56, :form($_) ); # default output format is html
}
# '#d2691e'
# [ 210, 105, 29]
# [ 0.823529, 0.411765, 0.113725 ]
```
