require 'minitest/autorun'
require 'yaml'
require "coverage"
require_relative "../lib/ryresolv/ypath.rb"

class TestYPath < Minitest::Test

  def assert_path_segments( path, segments, msg = nil )
    Syck::YPath.each_path( path ) { |choice|
      assert_equal( choice.segments, segments.shift, msg )
    }
    assert_equal( segments.length, 0, "Some segments leftover: #{ segments.inspect }" )
  end

  def test_ypath
    assert_path_segments( "/*/((one|three)/name|place)|//place",
      [ ["*", "one", "name"],
        ["*", "three", "name"],
        ["*", "place"],
        ["/", "place"] ]
    )
    assert_path_segments( "//one/./two/../three",
      [ ["/", "one", ".", "two", "..", "three"] ]
    )
    assert_path_segments( "/one/*/two//three",
      [ ["one", "*", "two", "/", "three"] ]
    )
  end

end
