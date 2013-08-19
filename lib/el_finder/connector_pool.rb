module ElFinder

  # Represents ElFinder connector on Rails side.
  class ConnectorPool

    #
    def initialize(options)

      raise(ArgumentError, "Missing required :roots option") unless options.key?(:roots)

      @pool = {}

      options[:roots].each_with_index do |current_root, index|

        options = options.merge(current_root)
        options[:index] = index

        connector = ElFinder::Connector.new(options)

        @pool[connector.volume_id] = connector
      end

      puts "========= Init Pool =============="
      puts "pool size = #{@pool.size}"
      puts @pool.inspect
      puts "+================================+"

    end #

    def connector(connector_id)
      (connector_id.blank? || !@pool.has_key?(connector_id)) ? @pool[@pool.keys.first] : @pool[connector_id]
    end

    def tree
      tree = []
      @pool.values.each do |connector|
        tree << connector.tree
      end
      tree
    end

  end

end