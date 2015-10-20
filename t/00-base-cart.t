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
);

$dbh->do($_) for @sql;

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

subtest 'root' => sub {
    my $res = $test->request( GET '/' );
    like(
        $res->content,qr/Hello World/,'Get content for /'
    );
};

unlink $dbfile;

done_testing;

