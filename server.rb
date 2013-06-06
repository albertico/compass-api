require 'rubygems'
require 'bundler/setup'
require 'goliath'
require 'grape'
require 'em-synchrony/activerecord'
require 'activerecord-postgis-adapter'
require 'rgeo'
require 'rgeo-activerecord'
require 'rgeo-geojson'
require 'yaml'
require 'erb'
require File.expand_path(File.join(File.dirname(__FILE__), '.', 'config', 'application'))
require File.expand_path(File.join(File.dirname(__FILE__), '.', 'app', 'model'))
require File.expand_path(File.join(File.dirname(__FILE__), '.', 'app', 'api'))

module Compass
  class Server < Goliath::API
    @api = nil

    def initialize()
      @api = Compass::API::Factory.create_api(API_CONFIG, "1")
    end

    def response(env)
      @api.call(env)
    end
  end
end
