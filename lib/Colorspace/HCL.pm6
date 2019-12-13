use v6.*;
unit module HCL;

constant Xn = 0.950470;
constant Yn = 1;
constant Zn = 1.088830;
constant T0 = 4 / 29;
constant T1 = 6 / 29;
constant T2 = 3 * T1 * T1;
constant T3 = T1 ** 3;

multi sub hcl-to-rgb( $h, $c, $l,
        Str :$form where { $form ~~ any < html trip-int trip-norm  > } = 'html' )
        is export
    {
        my &clean = -> $v, $lim { max( 0, min($lim, $v.round(1))) }
        my &conv = -> $v { $v > T1 ?? ($v ** 3) !! T2 * ( $v - T0 ) }
        my &adjust = -> $v { $v <= 0.00304 ?? 12.92 * $v !! ( 1.055 * exp(1 / 2.4, $v) - 0.055) }

        my $rh = $h * pi / 180;
        my $a = cos($rh) * $c;
        my $bx = sin($rh) * $c;
        my $u = ( $l + 16) / 116;
        my $x = &conv( $u+$a/500 ) * Xn;
        my $y = &conv( $u ) * Yn;
        my $z = &conv( $u - $bx/200) * Zn;
        my $r = &clean( 255 * &adjust(3.2404542 * $x - 1.5371385 * $y - 0.4985314 * $z) , 255 );
        my $g = &clean( 255 * &adjust( -0.969266 * $x + 1.8760108 * $y + 0.041556 * $z ), 255 );
        my $b = &clean( 255 * &adjust( 0.0556434 * $x - 0.2040259 * $y + 1.0572252 * $z ) , 255 );

        given $form {
            when 'html' { '#' ~ ($r, $g , $b).map( { .fmt("%x") }) .join }
            when 'trip-norm' { ( $r, $g , $b ).map( { ( $_ / 255 ).round(0.000001) } ) }
            default { [ $r, $g , $b] }
        }
    }

multi sub hcl-to-rgb( $h where $h ~~ NaN, $c, $l, :$form where { $form ~~ any < html trip-int trip-norm  > } = 'html'  )
    {
        if $form eq 'html' { '#ffffff' }
        else { [ 0, 0, 0 ] }
    }

subset Col of Int where 0 <= * <= 255;

multi sub rgb-to-hcl( *@trip where { $_.all ~~ Col and .elems == 3 } )
        is export
    {
        my &rgb_xyz = -> $t is copy { ( $t /= 255 ) <= 0.04045 ?? $t / 12.92 !! exp( 2.4,  ($t + 0.055)/ 1.055 ) }
        my &xyz_lab = -> $t { $t > T3 ?? exp(1/3, $t ) !! T0 + $t / T2 }

        # rgb -> xyz
        my @rgb = @trip>>.&rgb_xyz;
        my ( $x, $y, $z ) = ( 
                ((0.4124564 * @rgb[0] + 0.3575761 * @rgb[1] + 0.1804375 * @rgb[2]) / Xn ),
                ((0.2126729 * @rgb[0] + 0.7151522 * @rgb[1] + 0.0721750 * @rgb[2]) / Yn ),
                ((0.0193339 * @rgb[0] + 0.1191920 * @rgb[1] + 0.9503041 * @rgb[2]) / Zn )
                )>>.&xyz_lab;
        # xyz -> lab
        my $l = 116 * $y - 16;
        $l = 0 if $l < 0;
        my $a = 500 * ($x -$y);
        my $b = 200 * ($y - $z);
        # lab -> hcl
        my $c = sqrt( $a * $a + $b * $b);
        my $h = ( atan2( $b, $a) * 180 / pi + 360 ) % 360;
        $h = NaN if $c < 0.00001;
        [ $h.round(1), $c.round(1), $l.round(1) ]
    }

multi sub rgb-to-hcl( Str $s where $s ~~ m/^ '#' $<r>=(<xdigit>**2) $<g>=(<xdigit>**2) $<b>=(<xdigit>**2) $ /)
    {
        &rgb-to-hcl( +"0x$<r>", +"0x$<g>", +"0x$<b>")
    }

multi sub rgb-to-hcl( $r where 0 <= $r <= 1.0, $g where 0 <= $g <= 1.0, $b where 0 <= 1.0 )
        is export
    {
        &rgb-to-hcl( ($r * 255).Int, ($g * 255).Int, ($b *255).Int  )
    }

multi sub rgb-to-hcl( *@s )
    {
        fail "Got { @s.perl }\n" ~ q :to/USEAGE/;
                rgb-to-hcl can only take the following signatures:
            Int $r where 0 <= $r <= 255, Int $g where 0 <= $g <= 255, Int $b where 0 <= $b <= 255
            Str $s where $s ~~ m/^ '#' $<r>=(<xdigit>**2) $<g>=(<xdigit>**2) $<b>=(<xdigit>**2) $ /
            Rat $r where 0 <= $r <= 1.0, Rat $g where 0 <= $g <= 1.0, Rat $b where 0 <= 1.0
            USEAGE
    }

=begin pod

    from Maraca-render colors code.
    const N = [0.95047, 1, 1.08883];
    const T = [4 / 29, 6 / 29, 3 * (6 / 29) ** 2];
    const R = Math.PI / 180;

    const clean = (v, max) => Math.max(0, Math.min(max, Math.round(v)));

    export default (color = '', hex = false) => {
      if (!color) return null;

      const [h = 0, c = 0, l = 0, o = 100] = color
        .split(/\s+/)
        .filter(s => s)
        .map(s => (isNumber(s) ? parseFloat(s) : undefined));
      const r = h * R;
      const a = Math.cos(r) * c;
      const b = Math.sin(r) * c;

      const u = (l + 16) / 116;
      const [x, y, z] = [u + a / 500, u, u - b / 200].map(
        (v, i) => N[i] * (v > T[1] ? v ** 3 : T[2] * (v - T[0])),
      );

      const rgb = [
        3.2404542 * x - 1.5371385 * y - 0.4985314 * z,
        -0.969266 * x + 1.8760108 * y + 0.041556 * z,
        0.0556434 * x - 0.2040259 * y + 1.0572252 * z,
      ].map(v =>
        clean(
          255 * (v <= 0.00304 ? 12.92 * v : 1.055 * Math.pow(v, 1 / 2.4) - 0.055),
          255,
        ),
      );

      if (hex) return rgb.map(v => v.toString(16).padStart(2, '0')).join('');

      const alpha = clean(o, 100) * 0.01;

      return (
        (alpha === 1 ? 'rgb(' : 'rgba(') +
        rgb.join(', ') +
        (alpha === 1 ? ')' : ', ' + alpha + ')')
      );
    };


    for rgb => hcl

    from chroma.js
    These are the relevant parts.
    Chroma.js converts between RGB and a number of related colorspaces.
    So the path is rgb -> xyz -> lab -> lch -> hcl
    And then hcl -> lch -> lab -> xyz -> rgb
    This module goes directly between rgb <-> hcl

    0 <= r <= 255, 0 <= g <= 255, 0 <= b <= 255
    0 <= h < 360, 0 <= c < ~100, 0 <= l < ~100 ( c & l max values will depend on h; not all values in hcl map to rgb!

    Raku handles lists differently, so a single function taking a triplet and returning a triplet is needed.

    var labConstants = {
            // Corresponds roughly to RGB brighter/darker
            Kn: 18,

            // D65 standard referent
            Xn: 0.950470,
            Yn: 1,
            Zn: 1.088830,

            t0: 0.137931034,  // 4 / 29
            t1: 0.206896552,  // 6 / 29
            t2: 0.12841855,   // 3 * t1 * t1
            t3: 0.008856452,  // t1 * t1 * t1
        };

        var unpack$k = utils.unpack;
        var pow = Math.pow;

        var rgb2lab = function () {
            var args = [], len = arguments.length;
            while ( len-- ) args[ len ] = arguments[ len ];

            var ref = unpack$k(args, 'rgb');
            var r = ref[0];
            var g = ref[1];
            var b = ref[2];
            var ref$1 = rgb2xyz(r,g,b);
            var x = ref$1[0];
            var y = ref$1[1];
            var z = ref$1[2];
            var l = 116 * y - 16;
            return [l < 0 ? 0 : l, 500 * (x - y), 200 * (y - z)];
        };

        var rgb_xyz = function (r) {
            if ((r /= 255) <= 0.04045) { return r / 12.92; }
            return pow((r + 0.055) / 1.055, 2.4);
        };

        var xyz_lab = function (t) {
            if (t > labConstants.t3) { return pow(t, 1 / 3); }
            return t / labConstants.t2 + labConstants.t0;
        };

        var rgb2xyz = function (r,g,b) {
            r = rgb_xyz(r);
            g = rgb_xyz(g);
            b = rgb_xyz(b);
            var x = xyz_lab((0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / labConstants.Xn);
            var y = xyz_lab((0.2126729 * r + 0.7151522 * g + 0.0721750 * b) / labConstants.Yn);
            var z = xyz_lab((0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / labConstants.Zn);
            return [x,y,z];
        };

        var lab2lch = function () {
            var args = [], len = arguments.length;
            while ( len-- ) args[ len ] = arguments[ len ];

            var ref = unpack$n(args, 'lab');
            var l = ref[0];
            var a = ref[1];
            var b = ref[2];
            var c = sqrt$1(a * a + b * b);
            var h = (atan2(b, a) * RAD2DEG + 360) % 360;
            if (round$4(c*10000) === 0) { h = Number.NaN; }
            return [l, c, h];
        };


        var rgb2lab_1 = rgb2lab;

        var unpack$l = utils.unpack;
        var pow$1 = Math.pow;

        /*
         * L* [0..100]
         * a [-100..100]
         * b [-100..100]
         */
        var lab2rgb = function () {
            var args = [], len = arguments.length;
            while ( len-- ) args[ len ] = arguments[ len ];

            args = unpack$l(args, 'lab');
            var l = args[0];
            var a = args[1];
            var b = args[2];
            var x,y,z, r,g,b_;

            y = (l + 16) / 116;
            x = isNaN(a) ? y : y + a / 500;
            z = isNaN(b) ? y : y - b / 200;

            y = labConstants.Yn * lab_xyz(y);
            x = labConstants.Xn * lab_xyz(x);
            z = labConstants.Zn * lab_xyz(z);

            r = xyz_rgb(3.2404542 * x - 1.5371385 * y - 0.4985314 * z);  // D65 -> sRGB
            g = xyz_rgb(-0.9692660 * x + 1.8760108 * y + 0.0415560 * z);
            b_ = xyz_rgb(0.0556434 * x - 0.2040259 * y + 1.0572252 * z);

            return [r,g,b_,args.length > 3 ? args[3] : 1];
        };

        var xyz_rgb = function (r) {
            return 255 * (r <= 0.00304 ? 12.92 * r : 1.055 * pow$1(r, 1 / 2.4) - 0.055)
        };

        var lab_xyz = function (t) {
            return t > labConstants.t1 ? t * t * t : labConstants.t2 * (t - labConstants.t0)
        };

    var rgb2lch = function () {
            var args = [], len = arguments.length;
            while ( len-- ) args[ len ] = arguments[ len ];

            var ref = unpack$o(args, 'rgb');
            var r = ref[0];
            var g = ref[1];
            var b = ref[2];
            var ref$1 = rgb2lab_1(r,g,b);
            var l = ref$1[0];
            var a = ref$1[1];
            var b_ = ref$1[2];
            return lab2lch_1(l,a,b_);
        };

    var lch2lab = function () {
            var args = [], len = arguments.length;
            while ( len-- ) args[ len ] = arguments[ len ];

            /*
            Convert from a qualitative parameter h and a quantitative parameter l to a 24-bit pixel.
            These formulas were invented by David Dalrymple to obtain maximum contrast without going
            out of gamut if the parameters are in the range 0-1.
            A saturation multiplier was added by Gregor Aisch
            */
            var ref = unpack$p(args, 'lch');
            var l = ref[0];
            var c = ref[1];
            var h = ref[2];
            if (isNaN(h)) { h = 0; }
            h = h * DEG2RAD;
            return [l, cos$1(h) * c, sin(h) * c]
        };

     var lch2rgb = function () {
            var args = [], len = arguments.length;
            while ( len-- ) args[ len ] = arguments[ len ];

            args = unpack$q(args, 'lch');
            var l = args[0];
            var c = args[1];
            var h = args[2];
            var ref = lch2lab_1 (l,c,h);
            var L = ref[0];
            var a = ref[1];
            var b_ = ref[2];
            var ref$1 = lab2rgb_1 (L,a,b_);
            var r = ref$1[0];
            var g = ref$1[1];
            var b = ref$1[2];
            return [r, g, b, args.length > 3 ? args[3] : 1];
        };
=end pod

