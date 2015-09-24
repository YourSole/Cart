#perl

use strict;
use warnings;
use Test::More;
use Plack::Test;
use Dancer2;
use Dancer2::Plugin::DBIC;
use HTTP::Request::Common;
use File::Temp qw(tempfile);
use DBI;
use File::Spec;
use HTTP::Cookies;

use lib File::Spec->catdir( 't', 'lib' );

use TestApp1;
eval { use Dancer2::Plugin::DBIC; };
if ($@) {
    plan skip_all =>
        'Dancer2::Plugin::DBIC required for this test';
}

my (undef, $dbfile) = tempfile(SUFFIX => '.db');

t::lib::TestApp1::set plugins => {
    'ECommerce::Cart' => {
      product_name => 'EcProduct'
    },
    DBIC => {
        foo => {
            dsn =>  "dbi:SQLite:dbname=$dbfile",
            schema_class => "Test::Schema"
        },
        default => {
            dsn =>  "dbi:SQLite:dbname=$dbfile",
            schema_class => "Test::Schema"
        }
    }
};


my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile");

my @sql = (
"CREATE TABLE 'ec_product' (
  'sku' TEXT NOT NULL,
  'name'  TEXT NOT NULL,
  'price' NUMERIC NOT NULL,
  'description' TEXT NOT NULL,
  PRIMARY KEY(sku)
);",


"CREATE TABLE 'ec_cart' (
  'id'  INTEGER PRIMARY KEY AUTOINCREMENT,
  'name'  TEXT NOT NULL,
  'session' TEXT NOT NULL,
  'user_id' INTEGER
);",


"CREATE TABLE 'ec_cart_product' (
  'cart_id' INTEGER NOT NULL,
  'sku'  TEXT NOT NULL,
  'price' NUMERIC NOT NULL,
  'quantity'  INTEGER NOT NULL
);",

"INSERT INTO EC_PRODUCT values ('SU03','Product1','10.00','description of the product1')",
"INSERT INTO EC_PRODUCT values ('SU04','Product2','11.00','description of the product2')",
"INSERT INTO EC_PRODUCT values ('SU05','Product3','12.00','description of the product3')",

);


$dbh->do($_) for @sql;


my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

my $site = "http://localhost";

my $jar = HTTP::Cookies->new;


subtest 'list products' => sub {
  my $req = GET $site . '/products';
  my $res = $test->request( $req );
  like(
    $res->content, qr/SU03/,'Get content /products'
  );
  like(
    $res->content, qr/SU04/,'Get content /products'
  );
  like(
    $res->content, qr/SU05/,'Get content /products'
  );

};

subtest 'Add product' => sub {
  my $req = POST $site . '/cart/add', [ 'sku' => "SU03", 'quantity' => '1' ];
  my $res = $test->request( $req );
  is(
    $res->{_rc}, '302','Get content /cart'
  );
  like(
    $res->headers->{location}, qr/cart/, 'Redirect to /cart'
  );
  $jar->extract_cookies($res);

  $req = GET $site . '/cart';
  $jar->add_cookie_header($req);
  $res = $test->request( $req );
  like(
    $res->content, qr/SU03/, 'Cart info'
  );  

  $req = POST $site . '/cart/add', [ 'sku' => "SU03", 'quantity' => '1' ];
  $jar->add_cookie_header($req);
  $res = $test->request( $req );


  $req = GET $site . '/cart';
  $jar->add_cookie_header($req);
  $res = $test->request( $req );
  like(
    $res->content, qr/>2</, 'Cart info'
  ); 
  
};



unlink $dbfile;
done_testing();