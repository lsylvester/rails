module ActiveRecord
  module DeferedPreloading

    attr_accessor :defered_preloader

    # Prevent preloading occuring for this record

    def exclude_from_preloading
      if @defered_preloader
        @defered_preloader.exclude(self)
        @defered_preloader = nil
      end
    end

    alias :mark_as_cache_hit :exclude_from_preloading
  end
end
