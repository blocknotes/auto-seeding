module AutoSeeding
  # From activesupport
  def self._deep_merge( hash, other_hash, &block )
    _deep_merge!( hash.dup, other_hash, &block )
  end

  # From activesupport
  def self._deep_merge!( hash, other_hash, &block )
    other_hash.each_pair do |current_key, other_value|
      this_value = hash[current_key]

      hash[current_key] = if this_value.is_a?(Hash) && other_value.is_a?(Hash)
        _deep_merge( this_value, other_value, &block )
      else
        if block_given? && key?(current_key)
          block.call(current_key, this_value, other_value)
        else
          other_value
        end
      end
    end

    hash
  end
end
