require "cases/helper"
require "models/book"
require "models/author"

class DeferedPreloadingTest < ActiveRecord::TestCase
  fixtures :books

  test "defered preloading" do
    @books = Book.preload(:author).defer_preloading!
    @books[0].exclude_from_preloading

    assert !@books[0].association(:author).loaded?
    assert @books[1].association(:author).loaded?
  end
end
