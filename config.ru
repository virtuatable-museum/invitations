require 'bundler'
Bundler.require(ENV['RACK_ENV'].to_sym || :development)

service = Arkaan::Utils::MicroService.instance
  .register_as('invitations')
  .from_location(__FILE__)
  .in_standard_mode

application = Arkaan::OAuth::Application.find_or_create_by(name: 'invitations', premium: true).save

map(service.path) { run Controllers::Invitations.new }
