class Distribution
  attr_accessor :n, :sum_x, :sum_x2, :min, :max

  def self.from_json(json)
    list = :n, :sum_x, :sum_x2, :min, :max
    if json.class == Hash
      d=Distribution.new
      list.each{|v| d.send("#{v.to_s}=",json[v.to_s.capitalize])}
      return d
    else
      return json
    end
  end

  def initialize
    @n, @sum_x, @sum_x2, @min, @max = 0, 0, 0, nil, nil
  end

  def mean
    @n > 0 ? @sum_x.to_f / @n : nil
  end

  def to_f
    mean
  end
end