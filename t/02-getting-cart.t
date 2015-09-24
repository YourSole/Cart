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
        'Dancer2::Plugin::DBIC required for this test';
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
"CREATE TABLE 'ec_cart' (
  'id'  INTEGER PRIMARY KEY AUTOINCREMENT,
  'name'  TEXT NOT NULL,
  'session' TEXT NOT NULL,
  'user_id' INTEGER
);",
);

$dbh->do($_) for @sql;

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

subtest 'getting a cart by default' => sub {
    my $res = $test->request( GET '/cart/new/' );
    like(
        $res->content,qr/main/,'Get content for /cart/new'
    );
};

subtest 'getting a cart by cart_name' => sub {
    my $res = $test->request( GET '/cart/new/foo' );
    like(
        $res->content,qr/foo/,'Get content for /cart/new/foo '
    );
};


unlink $dbfile;

done_testing;
