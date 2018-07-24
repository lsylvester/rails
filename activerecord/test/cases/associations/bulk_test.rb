# frozen_string_literal: true

require "cases/helper"
require "models/author"
require "models/post"
require "models/comment"

class BulkAssociationsTest < ActiveRecord::TestCase
  fixtures :posts, :comments, :authors

  test "bulk loading single has_many association" do
    posts = Post.bulk_load(:comments)

    assert_queries(1) do
      posts.load
    end

    assert_queries(1) do
      posts.first.comments.to_a
      posts.second.comments.to_a
    end
  end

  test "bulk loading nested association" do
    authors = Author.bulk_load(posts: :comments)

    assert_queries(1) do
      authors.load
    end

    assert_queries(1) do
      authors.first.posts.to_a
      authors.second.posts.to_a
    end

    assert_queries(1) do
      authors.first.posts.first.comments.to_a
      authors.second.posts.first.comments.to_a
    end

  end

  test "singular assoication bulk loading" do
    posts = Post.bulk_load(:author)

    assert_queries(1) do
      posts.load
    end

    assert_queries(1) do
      posts.first.author
      posts.second.author
    end
  end
end
