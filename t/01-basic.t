use Test;

use-ok 'Colorspace::HCL';

use Colorspace::HCL;

my $rv;
lives-ok { $rv = rgb-to-hcl(210, 105, 29) }, 'basic function lives';
dd $rv;
is-deeply $rv, [ 57, 68, 56] , 'correct HCL value';
dd rgb-to-hcl(210/255, 105/255, 29/255);
is rgb-to-hcl(210/255, 105/255, 29/255), $rv, 'function returns if normed parameters';
is rgb-to-hcl('#d2691e'), $rv, 'string ok';
throws-like { rgb-to-hcl(260,20,20) }, Exception, message => /'rgb-to-hcl can only take'/, 'parameter too large';
throws-like { rgb-to-hcl(10,-20,40) }, Exception, message => /'rgb-to-hcl can only take'/, 'parameter negative';
throws-like { rgb-to-hcl(1.1, 0.4,0.5) }, Exception, message => /'rgb-to-hcl can only take'/, 'real over 1';
throws-like { rgb-to-hcl('d2ef01') }, Exception, message => /'rgb-to-hcl can only take'/, 'invalid html definition';
lives-ok { $rv = hcl-to-rgb(57, 68, 56) }, 'to rgb lives';
is $rv, '#d2691d', 'correct html';
like hcl-to-rgb( 57, 68, 56 ), /^ '#' $<r>=(<xdigit>**2) $<g>=(<xdigit>**2) $<b>=(<xdigit>**2) $ /, 'html format';
is-deeply hcl-to-rgb( 57, 68, 56 , :form<trip-int>), [210, 105, 29], 'integer response';
is-deeply hcl-to-rgb( 57, 68, 56 , :form<trip-norm>), (0.823529, 0.411765, 0.113725), 'normed response';

done-testing;
