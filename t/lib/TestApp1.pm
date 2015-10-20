package t::lib::TestApp1;

use Dancer2;
use Dancer2::Plugin::Cart;


hook 'plugin.cart.validate_shipping_params' => sub {
  my ($params) = @_;

  if( $params->{ship_mode} ){
    my $ec_cart = session->read('ec_cart');
    delete $ec_cart->{shipping}->{error};
    $ec_cart->{shipping} = $params;
    session->write('ec_cart', $ec_cart );
  }
  else{
    my $ec_cart = session->read('ec_cart');
    $ec_cart->{shipping}->{error} = "shipmode not selected";
    session->write('ec_cart', $ec_cart );
  }
};


1;
