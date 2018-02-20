# frozen_string_literal: true

require 'active_support/cache_keys'

module ActionView
  module CollectionCaching # :nodoc:
    extend ActiveSupport::Concern

    included do
      # Fallback cache store if Action View is used without Rails.
      # Otherwise overridden in Railtie to use Rails.cache.
      mattr_accessor :collection_cache, default: ActiveSupport::Cache::MemoryStore.new
    end

    private
      def cache_collection_render(instrumentation_payload)
        return yield unless @options[:cached]
        cache_keys = expanded_cache_keys

        cached_partials  = collection_cache.read_multi(*cache_keys.expanded)
        instrumentation_payload[:cache_hits] = cached_partials.size

        @collection = cache_keys.missed_members_for_hits(cached_partials)
        rendered_partials = @collection.empty? ? [] : yield

        index = 0
        fetch_or_cache_partial(cached_partials, order_by: cache_keys.each) do
          rendered_partials[index].tap { index += 1 }
        end
      end

      def expanded_cache_keys
        cache_keys = if @collection.is_a?(ActiveSupport::CacheKeys)
          @collection
        else
          ActiveSupport::CacheKeys.new(@collection)
        end

        seed = callable_cache_key? ? @options[:cached] : ->(i) { i }

        cache_keys.expand do |item|
          expanded_cache_key(seed.call(item))
        end
        cache_keys
      end

      def callable_cache_key?
        @options[:cached].respond_to?(:call)
      end

      def expanded_cache_key(key)
        key = @view.combined_fragment_cache_key(@view.cache_fragment_name(key, virtual_path: @template.virtual_path))
        key.frozen? ? key.dup : key # #read_multi & #write may require mutability, Dalli 2.6.0.
      end

      def fetch_or_cache_partial(cached_partials, order_by:)
        order_by.map do |cache_key|
          cached_partials.fetch(cache_key) do
            yield.tap do |rendered_partial|
              collection_cache.write(cache_key, rendered_partial)
            end
          end
        end
      end
  end
end
