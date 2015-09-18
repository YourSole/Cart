#!perl
use Test::More;

BEGIN {
    $ENV{PATH} = '/bin:/usr/bin';
    use_ok( 'Dancer2::Plugin::ECommerce::Cart' ) || print "Not found!
";
}

done_testing;
