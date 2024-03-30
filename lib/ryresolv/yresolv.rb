require_relative "ypath.rb"

module YRESOLV
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
    deep_nodes = []
    seg = ypath.segments[ depth ]

    if seg == "/"
      unless String === self
        idx = -1
        self.collect { |v|
          idx += 1
          if Hash === self
            match_init = [String === v[0] ? v[0] : v[0].transform, v[1]]
            v[1].extend YRESOLV
            v[1].parent = self
            match_deep = v[1].match_segment( ypath, depth )
          else
            match_init = [idx, v]
            v.extend YRESOLV
            v.parent = self
            match_deep = v.match_segment( ypath, depth )
          end
          if match_deep
            match_deep.each { |m|
              deep_nodes.push( match_init + m )
            }
          end
        }
      end
      depth += 1
      seg = ypath.segments[ depth ]
    end

    this = self
    match_nodes =
      case seg
      when "."
        [[nil, this]]
      when ".."
        this = parent
        parent = this.parent
        [["..", this]]
      when "*"
        if this.is_a? Enumerable
          idx = -1
          this.collect { |h|
            idx += 1
            if Hash === this
              [String === h[0] ? h[0] : h[0].transform, h[1]]
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
        if ( v = at( seg ) )
          [[ seg, v ]]
        end
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
    match_nodes.each { |n|
      if n[1].is_a? Hash
        n[1].extend YRESOLV
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
    warn "#{caller[0]}: at() is deprecated" if $VERBOSE
    if Hash === self
      self[seg]
    elsif Array === self and seg =~ /\A\d+\Z/ and self[seg.to_i]
      self[seg.to_i]
    end
  end

end
