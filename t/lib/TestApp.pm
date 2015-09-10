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

get '/cart/add_product/:product' => sub {
  my $product = param ('product');
  my $res = cart_add($product);
  $res->{error}? $res->{error} : $res->{sku};
};



1;
