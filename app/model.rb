# Compass::Model

module Compass
  module Model
    module Constants
      WGS84_SRID = 4326
      DEGREE_TO_METERS_CONVERSION_FACTOR = 111120
      MILE_IN_METERS = 1609.34
    end

    module Helper
      def self.recordset_as_list(recordset, geometry_column)
        locations = []
        recordset.each do |record|
          l = {}
          record.attributes.each do |c,v|
            l[c] = v unless c.eql?(geometry_column)
          end
          l[:geometry] = record[geometry_column]
          locations << l
        end
        locations
      end

      def self.recordset_as_feature_hash(recordset, geometry_column)
        feature_collection = {:type => "FeatureCollection", :features => []}
        recordset.each do |record|
          f = {:type => "Feature", :geometry => record[geometry_column], :properties => {}}
          record.attributes.each do |c,v|
            f[:properties][c] = v unless c.eql?(geometry_column)
          end
          feature_collection[:features] << f
        end
        feature_collection
      end
    end

    module LayerCompassExtension
      extend ActiveSupport::Concern
      included do
        def self.select_geometries_on_ratio_distance(lng, lat, geometry_column, distance, distance_unit = :miles, columns = nil)
          location_wkt = "POINT(#{lng.to_s} #{lat.to_s})"
          raise 'Unit must be in miles' unless distance_unit.eql?(:miles)
          ratio_distance = distance * Compass::Model::Constants::MILE_IN_METERS # TODO: change to if-clause for different distance units
          columns_query = ""
          if columns.is_a?(Array)
            columns_query = columns.join(",")
            columns_query << "#{columns_query.empty? ? '' : ','}#{geometry_column.to_s}" if columns.find_index(geometry_column.to_s).nil?
          elsif columns.is_a?(Hash)
            columns.each do |c,v|
              columns_query << "," unless columns_query.empty?
              columns_query << "#{c.to_s} AS #{v.to_s}"
            end
            columns_query << "#{columns_query.empty? ? '' : ','}#{geometry_column.to_s}"
          else
            columns_query = "*"
          end
          compass_query = "(ST_Distance(ST_GeomFromText('#{location_wkt}', #{Compass::Model::Constants::WGS84_SRID}), #{geometry_column}) * #{Compass::Model::Constants::DEGREE_TO_METERS_CONVERSION_FACTOR}) <= #{ratio_distance}"
          self.select(columns_query).where(compass_query)
        end
      end
    end

    class Factory
      def self.create_activerecord_layer_model(table_name, geometry_column)
        klass = Class.new(ActiveRecord::Base) do
          RGeo::ActiveRecord::GeometryMixin.set_json_generator(:geojson)
          include Compass::Model::LayerCompassExtension
          def self.model_name
            ActiveModel::Name.new(self, nil, table_name)
          end
          self.table_name = table_name
          set_rgeo_factory_for_column(geometry_column, RGeo::Geographic.spherical_factory(:srid => 4326))
        end
      end
    end

    class ModelProperties
      attr_reader :klass, :table_name, :geometry_column, :columns

      def initialize(klass, table_name, geometry_column, columns = nil)
        @klass = klass
        @table_name = table_name
        @geometry_column = geometry_column
        @columns = columns
      end
    end

    class Manager
      @@manager = {}

      def self.create_model(resource, table_name, geometry_column, columns = nil)
        raise "Model for '#{resource}' already exists" if @@manager.key?(resource)
        klass = Compass::Model::Factory.create_activerecord_layer_model(table_name, geometry_column)
        @@manager[resource] = Compass::Model::ModelProperties.new(klass, table_name, geometry_column, columns)
      end

      def self.model(resource)
        @@manager[resource]
      end
    end
  end
end
