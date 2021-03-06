require 'neo4j/has_n/class_methods'
require 'neo4j/has_n/decl_relationship_dsl'
require 'neo4j/has_n/mapping'

module Neo4j
  module HasN

    # The object created by a has_n or has_one Neo4j::NodeMixin class method which enables creating and traversal of nodes.
    #
    # Includes the Enumerable and WillPaginate mixins.
    # The Neo4j::Mapping::ClassMethods::Relationship#has_n and Neo4j::Mapping::ClassMethods::Relationship#one
    # methods returns an object of this type.
    #
    # ==== See Also
    # Neo4j::HasN::ClassMethods
    #
    class Mapping
      include Enumerable
      include WillPaginate::Finders::Base
      
      include ToJava

      def initialize(node, dsl) # :nodoc:
        @node = node
        @dsl = dsl
      end

      def to_s
        "HasN::Mapping [#{@dsl.dir}, id: #{@node.neo_id} type: #{@dsl && @dsl.rel_type} dsl:#{@dsl}]"
      end

      def size
        self.to_a.size
      end

      alias_method :length, :size


      def [](index)
        i = 0
        each{|x| return x if i == index; i += 1}
        nil # out of index
      end

      # Pretend we are an array - this is necessarily for Rails actionpack/actionview/formhelper to work with this
      def is_a?(type)
        # ActionView requires this for nested attributes to work
        return true if Array == type
        super
      end

      # Required by the Enumerable mixin.
      def each(&block)
        @dsl.each_node(@node, &block)
      end

      # returns none wrapped nodes, you may get better performance using this method
      def _each(&block)
        @dsl._each_node(@node, &block)
      end

      # Returns an real ruby array.
      def to_ary
        self.to_a
      end

      def wp_query(options, pager, args, &block) #:nodoc:
         page     = pager.current_page || 1
         to       = pager.per_page * page
         from     = to - pager.per_page
         i        = 0
         res      = []
         _each do |node|
           res << node.wrapper if i >= from
           i += 1
           break if i >= to
         end
         pager.replace res
         pager.total_entries ||= self.size  # TODO, this could be very slow to do
       end

      # Returns true if there are no node in this type of relationship
      def empty?
        first == nil
      end


      # Creates a relationship instance between this and the other node.
      # Returns the relationship object
      def new(other)
        @dsl.create_relationship_to(@node, other)
      end


      # Creates a relationship between this and the other node.
      #
      # ==== Example
      # 
      #   n1 = Node.new # Node has declared having a friend type of relationship
      #   n2 = Node.new
      #   n3 = Node.new
      #
      #   n1 << n2 << n3
      #
      # ==== Returns
      # self
      #
      def <<(other)
        @dsl.create_relationship_to(@node, other)
        self
      end
    end

  end
end
