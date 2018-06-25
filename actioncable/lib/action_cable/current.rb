# frozen_string_literal: true

module ActionCable
  class Current < ActiveSupport::CurrentAttributes
    attribute :connection
  end
end
