# frozen_string_literal: true

module ActiveRecord
  module Associations
    class BulkLoader
      def initialize(records, associations)
        @records = records
        @associations = associations
        @preloader = Preloader.new
      end

      def loads?(association)
        @associations.include?(association)
      end

      def load(association)
        @preloader.preload(@records, association)
      end
    end
  end
end
