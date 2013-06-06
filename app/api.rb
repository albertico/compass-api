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
      def self.create_api(api_resources, api_version)
        api_resources.each do |r|
          Compass::Model::Manager.create_model(r[:resource], r[:table_name], r[:geometry_column], r[:columns])
        end
        klass = Class.new(Grape::API) do
          prefix 'compass'
          version api_version, using: :param, parameter: 'v'
          format :json

          api_resources.each do |r|
            resource r[:resource] do
              params do
                optional :lnglat, type: String, lng_lat: true, desc: "Longitude and Latitude"
                optional :latlng, type: String, lat_lng: true, desc: "Latitude and Longitude"
                optional :dist, type: String, distance: true, desc: "Distance ratio"
              end
              get '/' do
                throw :error, status: 400, message: "must specify 'lnglat' or 'latlng' parameter" unless params[:lnglat] or params[:latlng]
                lnglat = params[:lnglat] ? params[:lnglat].split(',') : params[:latlng].split(',').reverse!
                d = (params[:dist] || 1).to_f
                m = Compass::Model::Manager.model(r[:resource]).klass
                g = Compass::Model::Manager.model(r[:resource]).geometry_column
                c = Compass::Model::Manager.model(r[:resource]).columns
                Compass::Model::Helper.recordset_as_list(m.select_geometries_on_ratio_distance(lnglat[0], lnglat[1], g, d, :miles, c), g)
              end

              params do
                optional :lnglat, type: String, lng_lat: true, desc: "Longitude and Latitude"
                optional :latlng, type: String, lat_lng: true, desc: "Latitude and Longitude"
                optional :dist, type: String, distance: true, desc: "Distance ratio"
              end
              get '/location' do
                throw :error, status: 400, message: "must specify 'lnglat' or 'latlng' parameter" unless params[:lnglat] or params[:latlng]
                lnglat = params[:lnglat] ? params[:lnglat].split(',') : params[:latlng].split(',').reverse!
                d = (params[:dist] || 1).to_f
                m = Compass::Model::Manager.model(r[:resource]).klass
                g = Compass::Model::Manager.model(r[:resource]).geometry_column
                c = Compass::Model::Manager.model(r[:resource]).columns
                Compass::Model::Helper.recordset_as_feature_hash(m.select_geometries_on_ratio_distance(lnglat[0], lnglat[1], g, d, :miles, c), g)
              end
            end
          end
        end
      end
    end
  end
end
