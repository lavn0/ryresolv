require 'minitest/autorun'
require 'yaml'
require "coverage"
require_relative "../lib/ryresolv/ypath.rb"

class TestYPath < Minitest::Test

  def setup
    Coverage.start
    load "lib/ryresolv/ypath.rb"
  end

  def teardown
    Coverage.result.each do |key, val|
      puts "untested lines -> " + val.map.with_index { |val, idx| val == 0 ? "#{key}:#{idx}" : nil }.compact.join(" ")
      puts "test coverage -> #{key} (#{val.count { |e| e != nil && e != 0 }}/#{val.count { |e| e != nil }})"
    end
  end

  def assert_path_segments( path, segments, msg = nil )
    Syck::YPath.each_path( path ) { |choice|
      assert_equal( segments.shift, choice.segments, msg )
    }
    assert_equal( 0, segments.length, "Some segments leftover: #{ segments.inspect }" )
  end

  def assert_path_segments_predicates( path, ypath_array, msg = nil )
    Syck::YPath.each_path( path ) { |choice|
      assert_equal( ypath_array.first[0], choice.segments, msg )
      assert_equal( ypath_array.shift[1], choice.predicates, msg )
    }
    assert_equal( 0, ypath_array.length, "Some ypath_array leftover: #{ ypath_array.inspect }" )
  end

  def test_ypath
    assert_path_segments_predicates(
      "/",
      [ [ ["/"],
          [nil]] ]
    )
    assert_path_segments_predicates(
      "//",
      [ [ ["/"],
          [nil] ] ]
    )
    assert_path_segments_predicates(
      "/one[1]",
      [ [ ["one"],
          ["1"  ]] ]
    )
    assert_path_segments_predicates(
      "/one[abc]",
      [ [ ["one"],
          ["abc"]] ]
    )
    assert_path_segments_predicates(
      "/one/",
      [ [ ["one", "/"],
          [nil,   nil] ] ]
    )
    assert_path_segments_predicates(
      "/one/[1]",
      [ [ ["one", "/"],
          [nil,   "1"] ] ]
    )
    assert_path_segments_predicates(
      "one",
      [ [ ["one"],
          [nil  ] ] ]
    )
    assert_path_segments_predicates(
      "one[1]",
      [ [ ["one"],
          ["1"  ] ] ]
    )
    assert_path_segments_predicates(
      "one[abc]",
      [ [ ["one"],
          ["abc"]] ]
    )

    assert_path_segments(
      "/*/((one|three)/name|place)|//place",
      [ ["*", "one", "name"],
        ["*", "three", "name"],
        ["*", "place"],
        ["/", "place"] ]
    )
    assert_path_segments(
      "//one/./two/../three",
      [ ["/", "one", ".", "two", "..", "three"] ]
    )
    assert_path_segments(
      "/one/*/two//three",
      [ ["one", "*", "two", "/", "three"] ]
    )
  end

end
