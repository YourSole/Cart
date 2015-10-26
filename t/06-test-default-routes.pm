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
use Data::Dumper;

use lib File::Spec->catdir( 't', 'lib' );

use TestApp1;
eval { use Dancer2::Plugin::DBIC; };
if ($@) {
    plan skip_all =>
        'Dancer2::Plugin::DBIC required for this test';
}

my (undef, $dbfile) = tempfile(SUFFIX => '.db');

t::lib::TestApp1::set plugins => {
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
  'status'  INTEGER NOT NULL DEFAULT '0',
  'log' TEXT
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
"INSERT INTO EC_PRODUCT values ('SU10','Product4','13.00','description of the product4')",

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
  $jar->extract_cookies($res);
};

subtest 'Add product' => sub {
  my $req = POST $site . '/cart/add', [ 'ec_sku' => "SU03", 'ec_quantity' => '1' ];
  $jar->add_cookie_header($req);
  my $res = $test->request( $req );
  is(
    $res->{_rc}, '302','Get content /cart'
  );
  like(
    $res->headers->{location}, qr/cart/, 'Redirect to /cart'
  );

  $req = GET $site . '/cart';
  $jar->add_cookie_header($req);
  $res = $test->request( $req );
  like(
    $res->content, qr/SU03/, 'Cart has SU03'
  );  

  $req = POST $site . '/cart/add', [ 'ec_sku' => "SU03", 'ec_quantity' => '1' ];
  $jar->add_cookie_header($req);
  $res = $test->request( $req );
  $req = GET $site . '/cart';
  $jar->add_cookie_header($req);
  $res = $test->request( $req );
  like(
    $res->content, qr/>2</, 'Cart has SU03 with 2 items'
  );
};

subtest "hooks add product" => sub {
  my $req = POST $site . '/cart/add', [ 'ec_sku' => "SU01", 'ec_quantity' => '1' ];
  $jar->add_cookie_header($req);
  my $res = $test->request( $req );
  $req = GET $site . '/cart';
  $jar->add_cookie_header($req);
  $res = $test->request( $req );
  like(
    $res->content, qr/>SUNN</, 'Cart has SUNN'
  );
  like(
    $res->content, qr/<td>-1<\/td>/, 'Cart has SUNN with price -1'
  );
};

subtest 'Products sort and filtered' => sub {
  my $req = GET $site .'/products';
  $jar->add_cookie_header( $req );
  my $res = $test->request ( $req );
  is(
    $res->{_rc}, '200','Get content /products'
  );
  unlike(
    $res->content, qr/SU10/, 'SU10 has been excluded'
  );
};

subtest 'Shipping info' => sub {
  my $req = GET $site.'/cart/shipping';
  $jar->add_cookie_header( $req );
  my $res = $test->request ( $req );
  is(
    $res->{_rc}, '200','Get content /cart/shipping'
  );

  $req = POST $site.'/cart/shipping'; 
  $jar->add_cookie_header( $req );
  $res = $test->request ( $req ); 
  is( $res->{_rc}, '302','Redirect to get /cart/shipping');
  like(
    $res->request->uri, qr/shipping/, 'Validates redirects location to shipping'
  );

  $req = POST $site.'/cart/shipping', [ 'ship_mode' => "2" ];
  $jar->add_cookie_header( $req );
  $res = $test->request ( $req );
  is(
    $res->{_rc}, '302','Validation redirects to Billing Info'
  );
  like(
    $res->headers->{location}, qr/billing/, 'Validates redirects location to billing info'
  );
};


subtest 'Billing info' => sub {
  my $req = GET $site.'/cart/billing';
  $jar->add_cookie_header( $req );
  my $res = $test->request ( $req );
  is(
    $res->{_rc}, '200','Get content /cart/billing'
  );

  $req = POST $site.'/cart/billing', [ 'billing_name' => "1" ];
  $jar->add_cookie_header( $req );
  $res = $test->request ( $req );
  is(
    $res->{_rc}, '302','Validation redirects to Billing Info'
  );
  like(
    $res->headers->{location}, qr/review/, 'Validates redirects location to review'
  );
};

subtest 'Review info' => sub {
  my $req = GET $site.'/cart/review';
  $jar->add_cookie_header( $req );
  my $res = $test->request ( $req );
  is(
    $res->{_rc}, '200','Get content /cart/review'
  );
};

subtest 'Place Order' => sub {
  my $req = POST $site.'/cart/checkout';
  $jar->add_cookie_header( $req );
  my $res = $test->request ( $req );
  is(
    $res->{_rc}, '302','Checkout process'
  );

};

subtest 'Receipt' => sub {
  my $req = GET $site.'/cart/receipt';
  $jar->add_cookie_header( $req );
  my $res = $test->request ( $req );
  is(
    $res->{_rc}, '200','Get content /cart/receipt'
  );

};

unlink $dbfile;
done_testing();
