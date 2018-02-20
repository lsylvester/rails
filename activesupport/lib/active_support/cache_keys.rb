# frozen_string_literal: true

module ActiveSupport
  class CacheKeys
    def initialize(collection)
      @collection = collection
    end

    delegate :size, to: :@collection

    def expanded
      @expanded.keys
    end

    def expand &block
      @expanded = @collection.each_with_object({}) do |item, hash|
        hash[yield(item)] = item
      end
    end

    def missed_members_for_hits(hits)
      @expanded.except(*hits.keys).values
    end

    def each
      @expanded.each_key
    end
  end
end