# frozen_string_literal: true

require_relative '../types'
require_relative '../schema'

module RapiTapir
  module DSL
    # Type resolution methods for enhanced endpoint DSL
    module TypeResolution
      PRIMITIVE_TYPE_MAP = {
        string: -> { Types.string },
        integer: -> { Types.integer },
        float: -> { Types.float },
        boolean: -> { Types.boolean },
        date: -> { Types.date },
        datetime: -> { Types.datetime },
        uuid: -> { Types.uuid },
        email: -> { Types.email }
      }.freeze

      private

      def resolve_type(type_def)
        case type_def
        when Symbol
          create_primitive_type(type_def)
        when Hash, Array
          Schema.from_definition(type_def)
        else
          # For classes and already resolved types, return as-is
          type_def
        end
      end

      def create_primitive_type(symbol)
        type_creator = PRIMITIVE_TYPE_MAP[symbol]
        raise ArgumentError, "Unknown primitive type: #{symbol}" unless type_creator

        type_creator.call
      end
    end
  end
end
