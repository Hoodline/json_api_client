module JsonApiClient
  module Query
    class Requestor
      extend Forwardable

      def initialize(klass)
        @klass = klass
      end

      # expects a record
      def create(record, options = {})
        request(:post, klass.path(record.attributes), {
          data: record.as_json_api
        }, options)
      end

      def update(record, options = {})
        request(:patch, resource_path(record.attributes), {
          data: record.as_json_api
        }, options)
      end

      def get(params = {}, options = {})
        path = resource_path(params)
        params.delete(klass.primary_key)
        request(:get, path, params, options)
      end

      def destroy(record, options = {})
        request(:delete, resource_path(record.attributes), {}, options)
      end

      def linked(path, options = {})
        request(:get, path, {}, options)
      end

      def custom(method_name, options, params)
        path = resource_path(params)
        params.delete(klass.primary_key)
        path = File.join(path, method_name.to_s)

        request_options = options ? options.dup : {}
        request_method = request_options.delete(:request_method) || :get

        request(request_method, path, params, request_options)
      end

      protected

      attr_reader :klass
      def_delegators :klass, :connection

      def resource_path(parameters)
        if resource_id = parameters[klass.primary_key]
          File.join(klass.path(parameters), encoded(resource_id))
        else
          klass.path(parameters)
        end
      end

      def encoded(part)
        Addressable::URI.encode_component(part, Addressable::URI::CharacterClasses::UNRESERVED)
      end

      def request(type, path, params, options = {})
        klass.parser.parse(klass, connection.run(type, path, params, klass.custom_headers, options))
      end

    end
  end
end
