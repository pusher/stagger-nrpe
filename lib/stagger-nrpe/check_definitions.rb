class CheckDefinitions

  def initialize
    @simple_definitions = {}
  end

  def define(name, metric_names, &block)
    raise "Already defined #{name}" if @simple_definitions[name]

    @simple_definitions[name] = { metrics: [metric_names].flatten, block: block }
  end

  def get(name)
    @simple_definitions[name]
  end

  def count
    @simple_definitions.size
  end

end

