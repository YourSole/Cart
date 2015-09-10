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
use lib File::Spec->catdir( 't', 'lib' );

use TestApp;

eval { use Dancer2::Plugin::DBIC; };
if ($@) {
    plan skip_all =>
        'Dancer2::Plugin::DBIC required for these test';
}

my (undef, $dbfile) = tempfile(SUFFIX => '.db');

t::lib::TestApp::set plugins => {
    DBIC => {
        foo => {
            dsn =>  "dbi:SQLite:dbname=$dbfile",
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

"INSERT INTO PRODUCT values (1,'SU03','Product1','10.00','description of the product')",

);

$dbh->do($_) for @sql;

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

subtest 'adding un existing product' => sub {
    my $res = $test->request( GET '/cart/add_product/SU00');
    like(
        $res->content,qr/Product doesn't exists/,'Get content for /cart/add_product/SU03'
    );
};


subtest 'adding existing product' => sub {
    my $res = $test->request( GET '/cart/add_product/SU03');
    like(
        $res->content,qr/SU03/,'Get content for /cart/add_product/SU03'
    );
};


unlink $dbfile;

done_testing;
