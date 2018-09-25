require 'bundler'
Bundler.require :test

require 'arkaan/specs'

ENV['RACK_ENV'] = 'test'
ENV['APP_KEY'] = 'random_key'

service = Arkaan::Utils::MicroService.instance
  .register_as('invitations')
  .from_location(__FILE__)
  .in_test_mode

Arkaan::Specs.include_shared_examples
