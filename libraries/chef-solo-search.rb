# Add search functionality for solo data bags.
if Gem::Version.new(Chef::VERSION) < Gem::Version.new('0.10.4.rc.3')
  raise "Please upgrade Chef!"
end
if Chef::Config[:solo]
  class Chef
    class Search
      class Query

        attr_accessor :rest

        def initialize(url=nil)
          Chef::Log.info("Searches will be performed locally on data_bags. Wildcards are not supported.")
          Chef::Log.info(Chef::Config[:data_bag_path])
          #@rest = Chef::REST.new(url ||Chef::Config[:search_url])
        end

        # Override Search to request locally.
        def search(type, query="*:*", sort='X_CHEF_id_CHEF_X asc', start=0, rows=1000, &block)
          raise ArgumentError, "Type must be a string or a symbol!" unless (type.kind_of?(String) || type.kind_of?(Symbol))

          response = bag_query(type, query)
          if block
            response["rows"].each { |o| block.call(o) unless o.nil?}
            unless (response["start"] + response["rows"].length) >= response["total"]
              nstart = response["start"] + rows
              search(type, query, sort, nstart, rows, &block)
            end
            true
          else
            [ response["rows"], response["start"], response["total"] ]
          end
        end

        def list_indexes
          #response = @rest.get_rest("search")
        end

        private
          # Search bag files.  
          # TODO Add current node if type node.
          # TODO Sort
          def bag_query(bag, query="*:*")
            rows = []
            Chef::Log.info("Bag %s" % [bag.to_s])
            # TODO - Apparently Vagrant 0.8 is setting this to an array.
            Chef::Config[:data_bag_path] = Chef::Config[:data_bag_path].first
            Chef::Log.info("Data bag path %s" % [Chef::Config[:data_bag_path]])
            Chef::DataBag.load(bag.to_s).each do |bag_item|
              if (query == '*:*' || item_query_match(query, bag_item[1]))
                rows << bag_item[1]
              end
            end
            return {'rows' => rows, 'start' => 0, 'total' => rows.length} 
          end
          # Check if bag_item matches given query.
          # TODO - Support wildcards.
          def item_query_match(query, bag_item)
            Chef::Log.info("Query: %s" % [query.to_s])
            logic = Array.new
            query.split(' ').each do |fragment|
              if fragment.include?(':')
                key, value = fragment.split(':')
                logic << (bag_item.has_key?(key) and bag_item[key].include?(value)).to_s
              else
                # TODO - Verify allowed operators and order of operations.
                logic << fragment.downcase
              end
            end
            Chef::Log.info("Query logic: %s" % [logic.join(' ')])
            Chef::Log.info(bag_item.to_json)
            return eval(logic.join(' '))
          end
      end
    end
  end

  # Hijack node save, since there is no where to save.
  class Chef
    class Node
      def save
        Chef::Log.warn("Chef solo cannot save node data as there is no Chef server.")
      end
    end
  end
end
