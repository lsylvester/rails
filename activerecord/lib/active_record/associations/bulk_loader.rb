# frozen_string_literal: true

module ActiveRecord
  module Associations
    class BulkLoader
      def initialize(records, associations, path=[])
        @records = records
        @associations = associations
        @path = path
        @preloader = Preloader.new
      end

      def loads?(association)
        associations_for_path = @path.inject(@associations){ |result, a| result.grep(Hash).map{ |h| h[a]}.compact }
        associations_for_path.include?(association) || associations_for_path.grep(Hash).any?{ |h| h.key?(association)}
      end

      def load(association)
        @preloader.preload(@records, @path.reverse.inject(association){ |result, a| {a => result} }).tap do |preloaders|
          bulk_loader = BulkLoader.new(@records, @associations, @path + [association])
          preloaders.first.preloaded_records.each do |record|
            record.bulk_loader = bulk_loader
          end
        end
      end
    end
  end
end
