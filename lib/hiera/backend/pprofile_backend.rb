class Hiera
  module Backend
    class Pprofile_backend
      def initialize(cache=nil)
        require 'yaml'
        require 'rubygems'
        require 'uri'
        begin
          require 'puppet'
          # This is needed when we run from hiera cli
          Puppet.initialize_settings unless Puppet[:confdir]
          require 'puppet/util/puppetdb'
          @host = Puppet::Util::Puppetdb.server
          @port = Puppet::Util::Puppetdb.port
        rescue
          @host = 'puppetdb'
          @port = 443
        end
        Hiera.debug("Hiera Pprofile backend starting")

        @cache = cache || Filecache.new
      end

      # Execute a PuppetDB query - from puppetdbquery module
      #
      # @param endpoint [Symbol] :resources, :facts or :nodes
      # @param query [Array] query to execute
      # @return [Array] the results of the query
      def query(endpoint, query=nil, http=nil, version=:v2)
        require 'json'
    
        unless http then
          require 'puppet/network/http_pool'
          http = Puppet::Network::HttpPool.http_instance(@host, @port, use_ssl=true)
        end
        headers = { "Accept" => "application/json" }
    
        uri = "/#{version.to_s}/#{endpoint.to_s}"
        uri += URI.escape "?query=#{query.to_json}" unless query.nil? or query.empty?
    
        resp = http.get(uri, headers)
        raise RuntimeError, "PuppetDB query error: [#{resp.code}] #{resp.msg}, query: #{query.to_json}" unless resp.kind_of?(Net::HTTPSuccess)
        return JSON.parse(resp.body)
      end
      
      

      def lookup(key, scope, order_override, resolution_type)
        answer = nil

        Hiera.debug("Looking up #{key} in Pprofile backend")

        q = ['and', ['=', 'type', 'Class'], ['~', 'title','Profile'], ['=', 'certname',scope['clientcert']]]
        if Config.include?(:hierarchy)
          hierarchy = [Config[:hierarchy]].flatten
        end
        result = query(:resources,q)
        hierarchy = hierarchy.concat(result.collect { |x| x['title'].gsub(/Profile::/,'').downcase })
        Hiera.debug("Hierarchy: #{hierarchy.inspect}")
        Backend.datasources(scope, order_override,hierarchy) do |source|
          Hiera.debug("Looking for data source #{source}")
          yamlfile = Backend.datafile(:pprofile, scope, source, "yaml") || next

          next unless file_exists?(yamlfile)

          data = @cache.read_file(yamlfile, Hash) do |data|
            YAML.load(data) || {}
          end

          next if data.empty?
          next unless data.include?(key)

          # Extra logging that we found the key. This can be outputted
          # multiple times if the resolution type is array or hash but that
          # should be expected as the logging will then tell the user ALL the
          # places where the key is found.
          Hiera.debug("Found #{key} in #{source}")

          # for array resolution we just append to the array whatever
          # we find, we then goes onto the next file and keep adding to
          # the array
          #
          # for priority searches we break after the first found data item
          new_answer = Backend.parse_answer(data[key], scope)
          case resolution_type
          when :array
            raise Exception, "Hiera type mismatch: expected Array and got #{new_answer.class}" unless new_answer.kind_of? Array or new_answer.kind_of? String
            answer ||= []
            answer << new_answer
          when :hash
            raise Exception, "Hiera type mismatch: expected Hash and got #{new_answer.class}" unless new_answer.kind_of? Hash
            answer ||= {}
            answer = Backend.merge_answer(new_answer,answer)
          else
            answer = new_answer
            break
          end
        end

        return answer
      end

      private

      def file_exists?(path)
        File.exist? path
      end
    end
  end
end
