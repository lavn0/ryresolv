require_relative "ypath.rb"

module YRESOLVNODE
  attr_accessor :parent

  def select( ypath_str )
    matches = match_path( ypath_str )
    if matches
      result = []
      matches.each { |m|
        result.push m.last
      }
      result
    end
  end

  # basenode.rb
  def match_path( ypath_str )
    matches = []
    ::Syck::YPath.each_path( ypath_str ) do |ypath|
      seg = match_segment( ypath, 0)
      matches += seg if seg
    end
    matches.uniq
  end

  # basenode.rb
  def match_segment( ypath, depth )
    if self.is_a? Psych::Nodes::Document
      v = self.children[0]
      v.extend YRESOLVNODE
      return v.match_segment(ypath, depth)
    end

    deep_nodes = []
    seg = ypath.segments[ depth ]

    # puts "1: ypath.fullpath=#{ypath.fullpath}, seg=#{seg}"
    if seg == "/"
      unless self.is_a? Psych::Nodes::Scalar
        idx = -1
        self.children.each_slice(2) do |key, value|
          idx += 1
          if self.is_a? Psych::Nodes::Mapping
            # puts "xxx::: #{seg}, #{key.transform}, #{value.class}"
            match_init = [key.transform, value]
            value.extend YRESOLVNODE
            value.parent = self
            match_deep = value.match_segment( ypath, depth )
          else
            match_init = [idx, value]
            value.extend YRESOLVNODE
            value.parent = self
            match_deep = value.match_segment( ypath, depth )
          end
          if match_deep
            match_deep.each { |m|
              deep_nodes.push( match_init + m )
            }
          end
        end
      end
      depth += 1
      seg = ypath.segments[ depth ]
    end

    this = self
    match_nodes =
      case seg
      when "."
        # puts "2-1: "
        [[nil, this]]
      when ".."
        this = parent
        parent = this.parent
        # puts "2-2: "
        [["..", this]]
      when "*"
        # puts "2-3: #{this.class}"
        if this.is_a? Enumerable
          idx = -1
          this.children.collect { |h|
            idx += 1
            if Psych::Nodes::Mapping === this
              [h[0].transform, h[1]]
            else
              [idx, h]
            end
          }
        end
      else
        if seg =~ /^"(.*)"$/
          seg = $1
        elsif seg =~ /^'(.*)'$/
          seg = $1
        end
        # puts "2-6: seg=#{seg}, depth=#{depth}"
        if ( v = at( seg ) )
          # puts "2-7: seg=#{seg}, v=#{v.class}"
          [[ seg, v ]]
        elsif
          # puts "2-8: nil"
          nil
        end
        # puts "exit"
      end
    return deep_nodes unless match_nodes
    pred = ypath.predicates[ depth ]

    if pred
      case pred
      when /^\.=/
        pred = $'   # '
        match_nodes.reject! { |n|
          n.last != pred
        }
      else
        match_nodes.reject! { |n|
          n.last.at( pred ).nil?
        }
      end
    end
    return match_nodes + deep_nodes unless ypath.segments.length > depth + 1

    deep_nodes = []
    # puts "2-9: #{match_nodes.length}"
    match_nodes.each { |n|
      if n[1].is_a? Psych::Nodes::Mapping
        # puts "2-10: "
        n[1].extend YRESOLVNODE
        n[1].parent = this if n[1].parent == nil
        match_deep = n[1].match_segment( ypath, depth + 1 )
        if match_deep
          match_deep.each { |m|
            deep_nodes.push( n + m )
          }
        end
      else
        deep_nodes = []
      end
    }
    deep_nodes = nil if deep_nodes.length == 0
    deep_nodes
  end

  def at( seg )
    this = self
    if this.is_a? Psych::Nodes::Document
      this = this.children[0] # Psych::Nodes::Mapping
    end

    if this.is_a? Psych::Nodes::Mapping
      this.children.each_slice(2) do |key, value|
        if key.value == seg
          return value
        end
      end
    elsif Array === this and seg =~ /\A\d+\Z/ and this[seg.to_i]
      self[seg.to_i]
    end
  end

end
