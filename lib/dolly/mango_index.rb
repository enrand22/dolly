# frozen_string_literal: true

require 'forwardable'
require 'dolly/document'

module Dolly
  class MangoIndex
    class << self
      extend Forwardable

      ALL_DOCS = '_all_docs'
      DESIGN = '_index'
      ROWS_KEY = :rows
      DESIGN_PREFIX = '_design/'

      def_delegators :connection, :get, :post

      def all
        get(DESIGN)[:indexes]
      end

      def create(name, fields, type = 'json')
        post(DESIGN, build_index_structure(name, fields, type))
      end

      def find_by_fields(fields)
        rows = get(ALL_DOCS, key: key_from_fields(fields))[ROWS_KEY]
        (rows && rows.any?).tap do |result|
          unless result
            message = "Index #{key_from_fields(fields)} not found"
            if defined?(Rails.logger)
              Rails.logger.info(message)
            else
              puts message
            end
          end
        end
      end

      def delete_all
        all.each do |index_doc|
          next if index_doc[:ddoc].nil?
          delete(index_doc)
        end
      end

      def delete(index_doc)
        resource = "#{DESIGN}/#{index_doc[:ddoc]}/json/#{index_doc[:name]}"
        connection.delete(resource, escape: false)
      end

      private

      def connection
        @connection ||= Dolly::Document.connection
      end

      def build_index_structure(name, fields, type)
        {
          ddoc: key_from_fields(fields).gsub(DESIGN_PREFIX, ''),
          index: {
            fields: fields
          },
          name: name,
          type: type
        }
      end

      def key_from_fields(fields)
        "#{DESIGN_PREFIX}index_#{fields.join('_')}"
      end
    end
  end
end
