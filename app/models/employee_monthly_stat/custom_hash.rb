class EmployeeMonthlyStat::CustomHash
  attr_accessor :data

  def initialize
    @data = Hash.new

    User.all.each do |employee|
      next if employee.role == "admin"
      @data[employee.id] = Hash.new(0)
    end
  end

  def [](id)
    @data[id]
  end

  def any?
    @data.values.each do |content|
      return true if content.any?
    end
    return false
  end

  def each(&block)
    @data.sort.reverse.each &block
  end

  def to_json(*options)
    @data.to_json
  end
end
