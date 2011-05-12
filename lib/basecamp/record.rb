module Basecamp; class Record
  attr_reader :type

  def initialize(type, hash)
    @type, @hash = type, hash
  end

  def [](name)
    name = dashify(name)

    case @hash[name]
    when Hash then 
      @hash[name] = if (@hash[name].keys.length == 1 && @hash[name].values.first.is_a?(Array))
        @hash[name].values.first.map { |v| Record.new(@hash[name].keys.first, v) }
      else
        Record.new(name, @hash[name])
      end
    else
      @hash[name]
    end
  end

  def id
    @hash['id']
  end

  def attributes
    @hash.keys
  end

  def respond_to?(sym)
    super || @hash.has_key?(dashify(sym))
  end

  def method_missing(sym, *args)
    if args.empty? && !block_given? && respond_to?(sym)
      self[sym]
    else
      super
    end
  end

  def to_s
    "\#<Record(#{@type}) #{@hash.inspect[1..-2]}>"
  end

  def inspect
    to_s
  end

  private

    def dashify(name)
      name.to_s.tr("_", "-")
    end
end; end