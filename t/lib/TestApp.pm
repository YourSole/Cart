package t::lib::TestApp;

use Dancer2;
use Dancer2::Plugin::DBIC qw(schema resultset);
get '/' => sub {
  'Hello World'
};

1;
