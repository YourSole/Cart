#perl

use strict;
use warnings;
use Test::More;
use Plack::Test;
use Dancer2;
use HTTP::Request::Common;
use File::Temp qw(tempfile);
use DBI;
use File::Spec;
use HTTP::Cookies;

use lib File::Spec->catdir( 't', 'lib' );

use TestApp;

eval { use Dancer2::Plugin::DBIC; };
if ($@) {
    plan skip_all =>
        'Dancer2::Plugin::DBIC required for this test';
}

my (undef, $dbfile) = tempfile(SUFFIX => '.db');
my (undef, $dbfile2) = tempfile(SUFFIX => '.db');

t::lib::TestApp::set plugins => {
    'Cart' => {
      cart_name => 'EcCart',
      cart_product_name => 'EcCartProduct',
      product_name => 'EcProduct',
    },
    DBIC => {
        default => {
            dsn =>  "dbi:SQLite:dbname=$dbfile",
            schema_class => "Test::Schema"
        },
        foo => {
            dsn =>  "dbi:SQLite:dbname=$dbfile",
            schema_class => "Test::Schema"
        },
        bar => {
            dsn =>  "dbi:SQLite:dbname=$dbfile2",
            schema_class => "Test::Schema"
        }
    }
};

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile");
my $dbh2 = DBI->connect("dbi:SQLite:dbname=$dbfile2");

my @sql = (
"CREATE TABLE 'ec_cart' (
  'id'  INTEGER PRIMARY KEY AUTOINCREMENT,
  'name'  TEXT NOT NULL,
  'session' TEXT NOT NULL,
  'status'  INTEGER NOT NULL DEFAULT '0',
  'log' TEXT
);",

"CREATE TABLE 'ec_product' (
  'sku' TEXT NOT NULL,
  'name'  TEXT NOT NULL,
  'price' NUMERIC NOT NULL,
  'description' TEXT NOT NULL,
  PRIMARY KEY(sku)
);",

"CREATE TABLE 'ec_cart_product' (
  'cart_id' INTEGER NOT NULL,
  'sku'  TEXT NOT NULL,
  'price' NUMERIC NOT NULL,
  'quantity'  INTEGER NOT NULL
);",

"INSERT INTO EC_PRODUCT values ('SU03','Product1','10.00','description of the product1')",
"INSERT INTO EC_PRODUCT values ('SU04','Product2','10.00','description of the product2')",

);

$dbh->do($_) for @sql;
$dbh2->do($_) for @sql;

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

my $jar = HTTP::Cookies->new;
my $site = "http://localhost";


subtest 'Adding products to default schema' =>sub {
  my $req = POST $site . '/cart/add_product', [ 'ec_sku' => "SU03", 'ec_quantity' => '7' ];
  my $res = $test->request( $req );
  $jar->extract_cookies( $res );
  like(
      $res->content, qr/SU03/,'Get content for /cart/add_product/SU03'
  );
  $req = GET $site . '/cart/foo';
  $jar->add_cookie_header( $req );
  $res = $test->request( $req );
  like(
    $res->content, qr/'ec_quantity' => 7/,'Get content /cart/foo'
  );
  
};



subtest 'Adding products to bar and cheking foo and bar schemas' =>sub {
  my $req = POST $site . '/cart/add_product_bar', [ 'ec_sku' => "SU04", 'ec_quantity' => '1' ];
  $jar->add_cookie_header( $req );
  my $res = $test->request( $req );
  like(
      $res->content, qr/SU04/,'Get content for /cart/add_product_bar/SU04'
  );
  
  $req = GET $site . '/cart/foo';
  $jar->add_cookie_header( $req );
  $res = $test->request( $req );
  like(
    $res->content, qr/'ec_quantity' => 7/,'Get content /cart/foo'
  );

  $req = GET $site . '/cart/bar';
  $jar->add_cookie_header( $req );
  $res = $test->request( $req );
  like(
    $res->content, qr/'ec_quantity' => 1/,'Get content /cart/bar'
  );
};


subtest 'Clear cart' => sub {
  my $req = GET $site . '/cart/clear_cart/bar';
  $jar->add_cookie_header( $req );
  my $res = $test->request( $req );
  like(
      $res->content, qr/\[\]/,'Get content for /cart/clear_cart'
  );
  
  $req = GET $site . '/cart/foo';
  $jar->add_cookie_header( $req );
  $res = $test->request( $req );
  like(
    $res->content, qr/'ec_quantity' => 7/,'Get content /cart/foo'
  );

};


unlink $dbfile;
unlink $dbfile2;

done_testing();

