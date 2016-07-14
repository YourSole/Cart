# NAME

Dancer2::Plugin::Cart - Ecommerce Cart Plugin for Dancer2

# VERSION 

Version 0.000001

# DESCRIPTION

This plugin provides a easy way to manage a shopping cart in dancer2.  All the information and data structure of the plugin will be manage by the session, so a good idea is to use a plugin in order to store the session data in the database.  

It was designed to be used on new or existing database, providing a lot of hooks in order to fit customizable solutions.

By default, the plugin is going to search default templates on the views directory, if the view doesn't exists, the plugin will render and inline templates provided by the plugin.

An script file has been added in order to generate the template views of each stage of a checkout, and the user will be able to adapt it to their needs.

The script is create_cart_views and needs to be run on the root directory of the dancer2 app.  The default views assume that you are using "Template Toolkit" as the template engine, because the default template "Simple" just render scalars.


# SYNOPSIS

1. In order to use the plugin, you need to configure at least some products.
	
  plugins:
	  Cart:
  	  product_list:
    	  - ec_sku: 'SU01'
      	  ec_price: 15
	      - ec_sku: 'SU02'
  	      ec_price: 20
    
2. use the library

    On your app.pm add:

    use Dancer2::Plugin2::Cart;


##Configuration Options: 

    * products_view_template
    * cart_view_template
    * cart_receipt_template
    * cart_checkout_template
    * shipping_view_template
    * billing_view_template
    * review_view_template
    * receipt_view_template
    * default_routes
    * excluded_routes 

##Keywords:

    * products
    * cart
    * cart_add
    * cart_add_item
    * cart_items
    * clear_cart
    * subtotal
    * billing
    * shipping
    * checkout
    * close_cart
    * adjustments

##Hooks:

    * before_cart
    * after_cart
    * validate_cart_add_params
    * before_cart_add
    * after_cart_add
    * before_cart_add_item
    * after_cart_add_item
    * validate_shipping_params
    * before_shipping
    * after_shipping
    * validate_billing_params
    * before_billing
    * after_billing
    * validate_checkout_params
    * before_checkout
    * checkout
    * after_checkout
    * before_close_cart
    * after_close_cart
    * before_clear_cart
    * after_clear_cart
    * before_item_subtotal
    * after_item_subtotal
    * before_subtotal
    * after_subtotal
    * adjustments




# BUGS
Please use GitHub issue tracker 
[here](https://github.com/YourSole/Cart).


#AUTHORS

## CORE DEVELOPERS

Andrew Baerg
Ruben Amortegui`

# AUTHOR

YourSole Core Developers

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ruben Amortegui.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

