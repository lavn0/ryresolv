require 'minitest/autorun'
require 'yaml'
require "coverage"
require_relative "../lib/ryresolv/ypath.rb"
require_relative "../lib/ryresolv/yresolv.rb"

class TestYResolv < Minitest::Test

  def setup
    Coverage.start
    load "lib/ryresolv/yresolv.rb"
  end

  def teardown
    Coverage.result.each do |key, val|
      puts "untested lines -> " + val.map.with_index { |val, idx| val == 0 ? "#{key}:#{idx}" : nil }.compact.join(" ")
      puts "test coverage -> #{key} (#{val.count { |e| e != nil && e != 0 }}/#{val.count { |e| e != nil }})"
    end
  end

  def test_yresolv
    yaml = YAML.load(File.read('test/resource/aws_lambda_template.yaml'))
    yaml.extend YRESOLV

    # test) simple root
    assert_equal(1, yaml.select("/AWSTemplateFormatVersion").length)
    assert_equal("2010-09-09", yaml.select("/AWSTemplateFormatVersion")[0])

    # test) simple path
    assert_equal(1, yaml.select("/Parameters/ExistingVPC/Type").length)
    assert_equal("AWS::EC2::VPC::Id", yaml.select("/Parameters/ExistingVPC/Type")[0])

    # test) simple descendants
    assert_equal(3, yaml.select("/Parameters//Type").length)
    assert_equal("List<AWS::EC2::SecurityGroup::Id>", yaml.select("/Parameters//Type")[0])
    assert_equal("AWS::EC2::VPC::Id", yaml.select("/Parameters//Type")[1])
    assert_equal("String", yaml.select("/Parameters//Type")[2])

    # test) "."
    assert_equal("AWS::EC2::VPC::Id", yaml.select("/Parameters/./ExistingVPC/Type")[0])

    # test) ".."
    assert_equal(10, yaml.select("/Parameters/../Mappings//HVM64").length)
    assert_equal("ami-0ff8a91507f77f867", yaml.select("/Parameters/../Mappings//HVM64")[0])
    assert_equal("ami-a0cfeed8",          yaml.select("/Parameters/../Mappings//HVM64")[1])
    assert_equal("ami-0bdb828fd58c52235", yaml.select("/Parameters/../Mappings//HVM64")[2])
    assert_equal("ami-047bb4163c506cd98", yaml.select("/Parameters/../Mappings//HVM64")[3])
    assert_equal("ami-0233214e13e500f77", yaml.select("/Parameters/../Mappings//HVM64")[4])
    assert_equal("ami-06cd52961ce9f0d85", yaml.select("/Parameters/../Mappings//HVM64")[5])
    assert_equal("ami-08569b978cc4dfa10", yaml.select("/Parameters/../Mappings//HVM64")[6])
    assert_equal("ami-09b42976632b27e9b", yaml.select("/Parameters/../Mappings//HVM64")[7])
    assert_equal("ami-07b14488da8ea02a0", yaml.select("/Parameters/../Mappings//HVM64")[8])
    assert_equal("ami-0a4eaf6c4454eda75", yaml.select("/Parameters/../Mappings//HVM64")[9])

    # test) "*"
    assert_equal(10, yaml.select("/Mappings/AWSRegionArch2AMI/*/HVM64").length)
    # assert_equal(20, yaml.select("/Mappings/AWSRegionArch2AMI/*/*/*").length)


    # assert_equal("HVM64", yaml.select("//*[.=HVM64]")[0])
  end

  # def test_yaml_middle
  #   yamlStr = File.read('test/resource/aws_lambda_template.yaml')
  #   parser = Psych::Parser.new Psych::TreeBuilder.new
  #   parser.parse(yamlStr)

  #   puts "11: #{parser.handler.root.children[0].class}" # Document
  #   puts "11: #{parser.handler.root.children[0].children[0].class}" # Mapping
  #   puts "11: #{parser.handler.root.children[0].children[0].children[0].class}" # Mapping
  #   puts "11: #{parser.handler.root.children[0].children[0].children[0].value}" # 'hoge' (root key)
  #   puts "11: #{parser.handler.root.children[0].children[0].children[1].class}" # Mapping

  #   yaml = parser.handler.root.children[0].children[0]
  #   yaml.extend YRESOLVNODE
  #   results = yaml.select("/hoge/fuga")
  #   assert_equal("piyo", results[0])
  # end

end
