# Compass::API

module Compass
  module API
    class LngLat < Grape::Validations::Validator
      def validate_param!(attr_name, params)
        unless params[attr_name] =~ /^([-]?[\d]+[.][\d]+)[,]([-]?[\d]+[.][\d]+)$/
          throw :error, status: 400, message: "#{attr_name}: must be a valid coordinate [longitude,latitude]"
        end
        throw :error, status: 400, message: "#{attr_name}: conflicts with 'latlng'" if params[:latlng]
      end
    end

    class LatLng < Grape::Validations::Validator
      def validate_param!(attr_name, params)
        unless params[attr_name] =~ /^([-]?[\d]+[.][\d]+)[,]([-]?[\d]+[.][\d]+)$/
          throw :error, status: 400, message: "#{attr_name}: must be a valid coordinate [latitude,longitude]"
        end
        throw :error, status: 400, message: "#{attr_name}: conflicts with 'lnglat'" if params[:lnglat]
      end
    end

    class Distance < Grape::Validations::Validator
      def validate_param!(attr_name, params)
        unless params[attr_name] =~ /^([\d]+)([.][\d]+)?$/ and params[attr_name].to_f > 0
          throw :error, status: 400, message: "#{attr_name}: must consist of a number greater than 0"
        end
      end
    end

    class Factory
      def self.create_api(api_config, api_version)
        api_config.each do |api|
          Compass::Model::Manager.create_model(api[:resource], api[:table_name], api[:geometry_column], api[:columns])
        end
        klass = Class.new(Grape::API) do
          use Goliath::Rack::Params
          use Goliath::Rack::JSONP
          use Compass::Rack::CORS
          
          prefix 'compass'
          version api_version, using: :param, parameter: 'v'
          format :json

          api_config.each do |api|
            resource api[:resource] do
              # Define parameters on single block.
              api_parameters = Proc.new do
                optional :lnglat, type: String, lng_lat: true, desc: "Longitude and Latitude"
                optional :latlng, type: String, lat_lng: true, desc: "Latitude and Longitude"
                optional :dist, type: String, distance: true, desc: "Distance ratio"
                optional :callback, type: String, desc: "JSONP callback"
              end

              params(&api_parameters)
              get '/' do
                throw :error, status: 400, message: "must specify 'lnglat' or 'latlng' parameter" unless params[:lnglat] or params[:latlng]
                lnglat = params[:lnglat] ? params[:lnglat].split(',') : params[:latlng].split(',').reverse!
                d = (params[:dist] || 1).to_f
                m = Compass::Model::Manager.model(api[:resource]).klass
                g = Compass::Model::Manager.model(api[:resource]).geometry_column
                c = Compass::Model::Manager.model(api[:resource]).columns
                Compass::Model::Helper.recordset_as_list(m.select_geometries_on_ratio_distance(lnglat[0], lnglat[1], g, d, :miles, c), g)
              end

              params(&api_parameters)
              get '/feature' do
                throw :error, status: 400, message: "must specify 'lnglat' or 'latlng' parameter" unless params[:lnglat] or params[:latlng]
                lnglat = params[:lnglat] ? params[:lnglat].split(',') : params[:latlng].split(',').reverse!
                d = (params[:dist] || 1).to_f
                m = Compass::Model::Manager.model(api[:resource]).klass
                g = Compass::Model::Manager.model(api[:resource]).geometry_column
                c = Compass::Model::Manager.model(api[:resource]).columns
                Compass::Model::Helper.recordset_as_feature_hash(m.select_geometries_on_ratio_distance(lnglat[0], lnglat[1], g, d, :miles, c), g)
              end
            end
          end
        end
      end
    end
  end
end
