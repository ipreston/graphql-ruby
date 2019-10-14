# frozen_string_literal: true
require "graphql/pagination/connection"

module GraphQL
  module Pagination
    class ArrayConnection < Pagination::Connection
      def nodes
        load_nodes
        @nodes
      end

      def has_previous_page
        load_nodes
        @has_previous_page
      end

      def has_next_page
        load_nodes
        @has_next_page
      end

      def cursor_for(item)
        idx = items.find_index(item) + 1
        context.schema.cursor_encoder.encode(idx.to_s)
      end

      private

      def index_from_cursor(cursor)
        decode(cursor).to_i
      end

      # Populate all the pagination info _once_,
      # It doesn't do anything on subsequent calls.
      def load_nodes
        @nodes ||= begin
          sliced_nodes = if before && after
            items[index_from_cursor(after)..index_from_cursor(before)-1] || []
          elsif before
            items[0..index_from_cursor(before)-2] || []
          elsif after
            items[index_from_cursor(after)..-1] || []
          else
            items
          end

          @has_previous_page = if last
            # There are items preceding the ones in this result
            sliced_nodes.count > last
          elsif after
            # We've paginated into the Array a bit, there are some behind us
            index_from_cursor(after) > 0
          else
            false
          end

          @has_next_page = if first
            # There are more items after these items
            sliced_nodes.count > first
          elsif before
            # The original array is longer than the `before` index
            index_from_cursor(before) < items.length
          else
            false
          end

          limited_nodes = sliced_nodes

          limited_nodes = limited_nodes.first(first) if first
          limited_nodes = limited_nodes.last(last) if last
          limited_nodes = limited_nodes.first(max_page_size) if max_page_size && !first && !last

          limited_nodes
        end
      end
    end
  end
end