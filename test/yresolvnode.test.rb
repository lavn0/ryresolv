require 'minitest/autorun'
require 'yaml'
require "coverage"
require_relative "../lib/ryresolv/ypath.rb"
require_relative "../lib/ryresolv/yresolvnode.rb"

class TestYResolv < Minitest::Test

  def setup
    Coverage.start
    load "lib/ryresolv/yresolvnode.rb"
  end

  def teardown
    Coverage.result.each do |key, val|
      puts "untested lines -> " + val.map.with_index { |val, idx| val == 0 ? "#{key}:#{idx}" : nil }.compact.join(" ")
      puts "test coverage -> #{key} (#{val.count { |e| e != nil && e != 0 }}/#{val.count { |e| e != nil }})"
    end
  end

  def test_yresolvnode
    yamlStr = File.read('test/resource/aws_lambda_template.yaml')
    parser = Psych::Parser.new Psych::TreeBuilder.new
    parser.parse(yamlStr)
    yaml = parser.handler.root.children[0]
    yaml.extend YRESOLVNODE

    # # test):::
    # ::Syck::YPath.each_path( "/Parameters//Test" ) do |ypath|
    #   # assert_equal("Scalar", yaml.match_segment(ypath, 0).last.class)
    # end

    # test) simple root
    assert_equal(1, yaml.select("/AWSTemplateFormatVersion").length)
    assert_equal("2010-09-09", yaml.select("/AWSTemplateFormatVersion")[0].value)

    # test) simple path
    assert_equal(1, yaml.select("/Parameters/ExistingVPC/Type").length)
    assert_equal("AWS::EC2::VPC::Id", yaml.select("/Parameters/ExistingVPC/Type")[0].value)

    # test) simple descendants
    assert_equal(4, yaml.select("/Parameters//Type").length)
    assert_equal("List<AWS::EC2::SecurityGroup::Id>", yaml.select("/Parameters//Type")[0].value)
    assert_equal("AWS::EC2::VPC::Id", yaml.select("/Parameters//Type")[1].value)
    assert_equal("String", yaml.select("/Parameters//Type")[2].value)

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
    assert_equal(Array, yaml.select("/AWSTemplateFormatVersion")[0].class)
    yaml.select("/AWSTemplateFormatVersion")[0].each_slice(2) do |key, value|
      assert_equal("AWSTemplateFormatVersion", key)
      assert_equal("2010-09-09", value)
    end
    result = yaml.select("/Parameters/*/Type")
    result = yaml.select("/Parameters/ExistingSecurityGroups/Type")
    assert_equal(Array, result.class)
    assert_equal(1, result.length)
    result.each { |v|
      assert_equal("2010-09-09", v.value)
    }
  end

  def test_at()
    yamlStr = File.read('test/resource/aws_lambda_template.yaml')
    parser = Psych::Parser.new Psych::TreeBuilder.new
    parser.parse(yamlStr)
    yaml = parser.handler.root.children[0]
    yaml.extend YRESOLVNODE

    assert_instance_of(Psych::Nodes::Document, yaml)
    assert_instance_of(Psych::Nodes::Mapping, yaml.children[0])

    yaml.children[0].extend YRESOLVNODE
    assert_instance_of(Psych::Nodes::Scalar, yaml.children[0].children[1])
    assert_equal("Parameters", yaml.children[0].children[2].value)
    assert_equal(yaml.children[0].children[3], yaml.children[0].at("Parameters"))
    assert_equal(yaml.children[0].children[3], yaml.at("Parameters"))
  end

end
