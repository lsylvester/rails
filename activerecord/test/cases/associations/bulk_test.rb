# frozen_string_literal: true

require "cases/helper"
require "models/post"
require "models/comment"

class BulkAssociationsTest < ActiveRecord::TestCase
  fixtures :posts, :comments

  test "bulk loading" do
    posts = Post.bulk_load(:comments)

    assert_queries(1) do
      posts.load
    end

    assert_queries(1) do
      posts.first.comments.to_a
      posts.second.comments.to_a
    end

  end
end
