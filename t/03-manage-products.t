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

use TestApp;

eval { use Dancer2::Plugin::DBIC; };
if ($@) {
    plan skip_all =>
        'Dancer2::Plugin::DBIC required for these test';
}

my (undef, $dbfile) = tempfile(SUFFIX => '.db');

t::lib::TestApp::set plugins => {
    ECommerce => {
      cart_result_name => 'Cart',
      cart_product_result_name => 'CartProduct',
      product_result_name => 'Product',
    },
    DBIC => {
        foo => {
            dsn =>  "dbi:SQLite:dbname=$dbfile",
            schema_class => "Test::Schema"
        }
    }
};

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile");

my @sql = (
"CREATE TABLE 'cart' (
  'id'  INTEGER PRIMARY KEY AUTOINCREMENT,
  'name'  TEXT NOT NULL,
  'session' TEXT NOT NULL,
  'user_id' INTEGER
);",

"CREATE TABLE 'product' (
  'id'  INTEGER,
  'sku' TEXT NOT NULL,
  'name'  TEXT NOT NULL,
  'price' NUMERIC NOT NULL,
  'description' TEXT NOT NULL,
  PRIMARY KEY(sku)
);",
"CREATE TABLE 'cart_products' (
  'cart_id' INTEGER NOT NULL,
  'product_id'  INTEGER NOT NULL,
  'price' NUMERIC NOT NULL,
  'quantity'  INTEGER NOT NULL
);",

"INSERT INTO PRODUCT values (1,'SU03','Product1','10.00','description of the product1')",
"INSERT INTO PRODUCT values (2,'SU04','Product2','10.00','description of the product2')",

);

$dbh->do($_) for @sql;

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);
use Data::Dumper;

my $jar = HTTP::Cookies->new;
my $site = "http://localhost";

subtest 'adding un existing product' => sub {
  my $req = GET $site . '/cart/add_product/SU00'; 
  my $res = $test->request( $req );
  like(
      $res->content, qr/Product doesn't exists/,'Get content for /cart/add_product/SU03'
  );
  $jar->extract_cookies($res);
};


subtest 'adding existing product' => sub {
  my $req = GET $site . '/cart/add_product/SU03';
  $jar->add_cookie_header($req);
  my $res = $test->request( $req );
  like(
      $res->content, qr/SU03/,'Get content for /cart/add_product/SU03'
  );
};

subtest 'getting products' => sub {
  my $req = GET $site . '/cart/products/';
   $jar->add_cookie_header($req);
  my $res = $test->request( $req );
  like(
    $res->content,qr/Product1/, 'Get an array of products with their info' 
  );
};

#unlink $dbfile;

done_testing;
