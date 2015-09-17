package t::lib::TestApp;

use Dancer2;
use Dancer2::Plugin::DBIC qw(schema resultset);
use Dancer2::Plugin::ECommerce;
use Data::Dumper;

get '/' => sub {
  'Hello World'
};

get '/cart/new/:cart_new?' => sub {
  my ($cart_name) = param('cart_new'); 
  my $cart = cart($cart_name); 
  $cart->{'name'};
};

post '/cart/add_product' => sub {
  my $product = { sku => param('sku'), quantity => param('quantity') };
  my $res = cart_add($product);
  $res->{error} ? $res->{error} : Dumper($res);
};

get '/cart/products' => sub {
  Dumper(products);
};

1;
