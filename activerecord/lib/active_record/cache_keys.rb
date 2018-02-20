module ActiveRecord
  class CacheKeys < ActiveSupport::CacheKeys
    def initialize(collection)
      collection.skip_preloading!
      super
    end

    def missed_members_for_hits(hits)
      super.tap{ |values|
        @collection.preload_associations(values)
      }
    end
  end
end