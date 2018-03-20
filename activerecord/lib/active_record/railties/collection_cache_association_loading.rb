# frozen_string_literal: true

module ActiveRecord
  module Railties # :nodoc:
    module CollectionCacheAssociationLoading #:nodoc:
      def defer_preloading(collection)
        collection.defer_preloading! if collection.is_a?(ActiveRecord::Relation) && !collection.loaded?
      end

      def collection_from_options
        defer_preloading(@options[:collection]) if @options[:cached]
        super
      end

      def collection_from_object
        defer_preloading(@object) if @options[:cached]
        super
      end
    end
  end
end
