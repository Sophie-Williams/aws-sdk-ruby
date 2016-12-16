module AwsSdkCodeGenerator
  module Dsl
    class Method

      include Dsl::CodeObject

      # @option options [Symbol] :access (:public)
      # @option options [String, nil] :docstring (nil)
      def initialize(name, options = {}, &block)
        @name = name.to_s
        @access = options.fetch(:access, :public)
        @code_objects = []
        @params = []
        @option_tags = []
        @return_tags = []
        @aliases = []
        @docstring = Dsl::Docstring.new(options.fetch(:docstring, nil))
        @api_private = options.fetch(:api_private, false)
        yield(self) if block
      end

      attr_reader :name

      attr_reader :access

      attr_reader :aliases

      def param(name, options = {})
        @params << Param.new(name, options)
      end

      def option(options)
        @option_tags << OptionTag.new(options)
      end

      def returns(type, options = {})
        @return_tags << ReturnTag.new(options.merge(type:type))
      end

      def add(*code_objects)
        @code_objects.concat(code_objects)
      end

      def code(code = nil, &block)
        @code_objects << CodeLiteral.new(code, &block)
      end

      def empty?
        @code_objects.empty?
      end

      def docstring(docstring = nil, &block)
        @docstring.append(docstring)
        yield(@docstring) if block
        @docstring
      end

      def block_param
        @params << BlockParam.new
      end

      def alias_as(other_name)
        @aliases << other_name.to_s
      end

      def lines
        code = []
        code.concat(yard_docs)
        code << method_signature
        code << method_body
        code << method_end
        code.concat(@aliases.map { |a| "alias :#{a} :#{@name}" })
        code
      end

      private

      def yard_docs
        docs = []
        docs.concat(@docstring.lines)
        tags = []
        tags.concat(ParamList.new(@params).tags)
        tags.concat(@option_tags)
        tags.concat(@return_tags)
        tags << "# @api private" if @api_private
        tags.each.with_index do |tag, n|
          docs.concat(tag.lines.to_a)
        end
        docs.compact
      end

      def method_signature
        "def #{@name}#{ParamList.new(@params).signature}"
      end

      def method_body
        @code_objects.inject([]) do |lines, code_obj|
          lines.concat(code_obj.lines)
        end
      end

      def method_end
        "end"
      end

    end
  end
end